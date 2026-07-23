using System.Globalization;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using BarberBooking.Application.DTOs.Auth;
using BarberBooking.Application.Interfaces;
using BarberBooking.Domain.Entities;
using BarberBooking.Domain.Exceptions;
using BarberBooking.Infrastructure.Data;
using BarberBooking.Infrastructure.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;

namespace BarberBooking.Infrastructure.Services;

public class BarberAuthService : IBarberAuthService
{
    private readonly BarberBookingDbContext _context;
    private readonly JwtSettings _jwtSettings;

    public BarberAuthService(BarberBookingDbContext context, IOptions<JwtSettings> jwtSettings)
    {
        _context = context;
        _jwtSettings = jwtSettings.Value;
    }

    public async Task<bool> IsPhoneTakenAsync(string phone)
    {
        var user = await _context.Users.FirstOrDefaultAsync(u => u.PhoneNumber == phone);
        if (user == null) return false;
        return user.IsActive;
    }

    public async Task<AuthResponseDto> RegisterBarberAsync(RegisterBarberDto dto)
    {
        var existingUser = await _context.Users
            .FirstOrDefaultAsync(u => u.PhoneNumber == dto.PhoneNumber);

        if (existingUser != null && existingUser.IsActive)
            throw new ConflictException("رقم الهاتف مسجل بالفعل");

        if (existingUser != null && !existingUser.IsActive)
        {
            var oldProfile = await _context.BarberProfiles.FirstOrDefaultAsync(bp => bp.UserId == existingUser.Id);
            if (oldProfile != null)
            {
                var oldServices = await _context.BarberServices.Where(s => s.BarberProfileId == oldProfile.Id).ToListAsync();
                _context.BarberServices.RemoveRange(oldServices);

                var oldHours = await _context.WorkingHours.Where(w => w.BarberProfileId == oldProfile.Id).ToListAsync();
                _context.WorkingHours.RemoveRange(oldHours);

                _context.BarberProfiles.Remove(oldProfile);
                _context.Users.Remove(existingUser);
                await _context.SaveChangesAsync();
            }
            else
            {
                _context.Users.Remove(existingUser);
                await _context.SaveChangesAsync();
            }
        }

        var user2 = new User
        {
            FullName = dto.FullName,
            PhoneNumber = dto.PhoneNumber,
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(dto.Password),
            ProfileImageUrl = dto.ProfileImageUrl,
            Role = "Barber",
            IsActive = false
        };

        _context.Users.Add(user2);
        await _context.SaveChangesAsync();

        var barberProfile = new BarberProfile
        {
            UserId = user2.Id,
            ShopName = dto.ShopName,
            ShopDescription = dto.ShopDescription,
            ShopLogoUrl = dto.ShopLogoUrl,
            City = dto.City,
            Address = dto.Address,
            Latitude = dto.Latitude,
            Longitude = dto.Longitude,
            SubscriptionPlan = dto.SubscriptionPlan,
            IsYearly = dto.IsYearly
        };

        _context.BarberProfiles.Add(barberProfile);
        await _context.SaveChangesAsync();

        foreach (var service in dto.Services)
        {
            _context.BarberServices.Add(new BarberService
            {
                BarberProfileId = barberProfile.Id,
                Name = service.Name,
                Price = service.Price,
                DurationInMinutes = service.DurationInMinutes
            });
        }

        foreach (var wh in dto.WorkingHours)
        {
            _context.WorkingHours.Add(new WorkingHour
            {
                BarberProfileId = barberProfile.Id,
                DayName = wh.DayName,
                IsOpen = wh.IsOpen,
                OpenTime = ParseTime(wh.OpenTime),
                CloseTime = ParseTime(wh.CloseTime)
            });
        }

        await _context.SaveChangesAsync();

        return await GenerateAuthResponseAsync(user2);
    }

    public async Task<AuthResponseDto> LoginBarberAsync(LoginDto dto)
    {
        var user = await _context.Users
            .FirstOrDefaultAsync(u => u.PhoneNumber == dto.PhoneNumber && u.Role == "Barber");

        if (user == null)
            throw new BadRequestException("رقم الهاتف أو كلمة المرور غير صحيحة");

        if (!user.IsActive)
            throw new BadRequestException("الحساب معطّل");

        if (!BCrypt.Net.BCrypt.Verify(dto.Password, user.PasswordHash))
            throw new BadRequestException("رقم الهاتف أو كلمة المرور غير صحيحة");

        return await GenerateAuthResponseAsync(user);
    }

    public async Task<AuthResponseDto> RefreshAsync(string refreshToken)
    {
        var token = await _context.RefreshTokens
            .FirstOrDefaultAsync(rt => rt.Token == refreshToken && !rt.IsRevoked);

        if (token == null || token.ExpiresAt < DateTime.UtcNow)
            throw new BadRequestException("Refresh Token غير صالح أو منتهي الصلاحية");

        var user = await _context.Users.FindAsync(token.UserId);
        if (user == null || !user.IsActive)
            throw new BadRequestException("المستخدم غير موجود أو معطّل");

        // Revoke old refresh token
        token.IsRevoked = true;
        await _context.SaveChangesAsync();

        return await GenerateAuthResponseAsync(user);
    }

    public async Task LogoutAsync(string refreshToken, string jti)
    {
        // Revoke refresh token
        if (!string.IsNullOrEmpty(refreshToken))
        {
            var token = await _context.RefreshTokens
                .FirstOrDefaultAsync(rt => rt.Token == refreshToken);
            if (token != null)
            {
                token.IsRevoked = true;
            }
        }

        // Blacklist JWT
        if (!string.IsNullOrEmpty(jti))
        {
            _context.RevokedTokens.Add(new RevokedToken
            {
                Jti = jti,
                ExpiresAt = DateTime.UtcNow.AddMinutes(_jwtSettings.ExpirationInMinutes)
            });
        }

        await _context.SaveChangesAsync();
    }

    private async Task<AuthResponseDto> GenerateAuthResponseAsync(User user)
    {
        var (jwtToken, jti) = GenerateJwtToken(user);
        var refreshToken = await GenerateRefreshTokenAsync(user.Id);

        return new AuthResponseDto
        {
            Token = jwtToken,
            Expiration = DateTime.UtcNow.AddMinutes(_jwtSettings.ExpirationInMinutes),
            RefreshToken = refreshToken.Token,
            RefreshTokenExpiration = refreshToken.ExpiresAt,
            FullName = user.FullName,
            PhoneNumber = user.PhoneNumber,
            Role = user.Role
        };
    }

    private (string token, string jti) GenerateJwtToken(User user)
    {
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_jwtSettings.Secret));
        var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);
        var jti = Guid.NewGuid().ToString();

        var claims = new[]
        {
            new Claim(JwtRegisteredClaimNames.Sub, user.Id.ToString()),
            new Claim(JwtRegisteredClaimNames.Jti, jti),
            new Claim("fullName", user.FullName),
            new Claim("phoneNumber", user.PhoneNumber),
            new Claim("role", user.Role)
        };

        var token = new JwtSecurityToken(
            issuer: _jwtSettings.Issuer,
            audience: _jwtSettings.Audience,
            claims: claims,
            expires: DateTime.UtcNow.AddMinutes(_jwtSettings.ExpirationInMinutes),
            signingCredentials: credentials);

        return (new JwtSecurityTokenHandler().WriteToken(token), jti);
    }

    private async Task<RefreshToken> GenerateRefreshTokenAsync(Guid userId)
    {
        var refreshToken = new RefreshToken
        {
            UserId = userId,
            Token = Convert.ToBase64String(RandomNumberGenerator.GetBytes(64)),
            ExpiresAt = DateTime.UtcNow.AddDays(7),
            IsRevoked = false
        };

        _context.RefreshTokens.Add(refreshToken);
        await _context.SaveChangesAsync();

        return refreshToken;
    }

    private static TimeSpan ParseTime(string time)
    {
        if (string.IsNullOrWhiteSpace(time))
            return TimeSpan.FromHours(9);

        var cleaned = time.Trim();

        if (TimeSpan.TryParseExact(cleaned, new[] { @"hh\:mm tt", @"h\:mm tt", @"hh\:mm", @"h\:mm" },
            CultureInfo.InvariantCulture, out var result))
            return result;

        if (TimeSpan.TryParse(cleaned, CultureInfo.InvariantCulture, out var parsed))
            return parsed;

        if (cleaned.Contains("AM", StringComparison.OrdinalIgnoreCase) || cleaned.Contains("PM", StringComparison.OrdinalIgnoreCase))
        {
            var isPm = cleaned.Contains("PM", StringComparison.OrdinalIgnoreCase);
            var numStr = cleaned.Replace("AM", "").Replace("PM", "").Replace("am", "").Replace("pm", "").Trim();
            if (TimeSpan.TryParse(numStr, CultureInfo.InvariantCulture, out var t))
            {
                if (isPm && t.Hours < 12)
                    t = t.Add(TimeSpan.FromHours(12));
                return t;
            }
        }

        return TimeSpan.FromHours(9);
    }
}
