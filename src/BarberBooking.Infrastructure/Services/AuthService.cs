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

public class AuthService : IAuthService
{
    private readonly BarberBookingDbContext _context;
    private readonly JwtSettings _jwtSettings;

    public AuthService(BarberBookingDbContext context, IOptions<JwtSettings> jwtSettings)
    {
        _context = context;
        _jwtSettings = jwtSettings.Value;
    }

    public async Task<AuthResponseDto> RegisterAsync(RegisterCustomerDto dto)
    {
        var existingUser = await _context.Users
            .AnyAsync(u => u.PhoneNumber == dto.PhoneNumber);

        if (existingUser)
            throw new ConflictException("رقم الهاتف مسجل بالفعل");

        var user = new User
        {
            FullName = dto.FullName,
            PhoneNumber = dto.PhoneNumber,
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(dto.Password),
            Email = dto.Email,
            ProfileImageUrl = dto.ProfileImageUrl,
            Role = "Customer",
            IsActive = false,
            IsPhoneVerified = false,
            PhoneVerificationStatus = "Pending"
        };

        _context.Users.Add(user);
        await _context.SaveChangesAsync();

        return await GenerateAuthResponseAsync(user);
    }

    public async Task<AuthResponseDto> LoginAsync(LoginDto dto)
    {
        var user = await _context.Users
            .FirstOrDefaultAsync(u => u.PhoneNumber == dto.PhoneNumber);

        if (user == null)
            throw new BadRequestException("رقم الهاتف أو كلمة المرور غير صحيحة");

        if (!user.IsActive)
            throw new BadRequestException("الحساب معطّل");

        // For customers, check phone verification
        if (user.Role == "Customer" && !user.IsPhoneVerified)
            throw new BadRequestException("رقم الهاتف غير متحقق. الرجاء الانتظار حتى يتحقق الإدارة من حسابك");

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
}
