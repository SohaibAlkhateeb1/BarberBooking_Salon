using System.IdentityModel.Tokens.Jwt;
using BarberBooking.Application.DTOs.Auth;
using BarberBooking.Application.Interfaces;
using BarberBooking.Domain.Entities;
using BarberBooking.Domain.Exceptions;
using BarberBooking.Infrastructure.Data;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.EntityFrameworkCore;

namespace BarberBooking.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly IAuthService _authService;
    private readonly ISmsService _smsService;
    private readonly BarberBookingDbContext _context;

    public AuthController(IAuthService authService, ISmsService smsService, BarberBookingDbContext context)
    {
        _authService = authService;
        _smsService = smsService;
        _context = context;
    }

    [HttpPost("register")]
    [EnableRateLimiting("auth")]
    public async Task<IActionResult> Register([FromBody] RegisterCustomerDto dto)
    {
        var result = await _authService.RegisterAsync(dto);
        return Created(string.Empty, new
        {
            verificationPending = true,
            message = "تم إنشاء طلب التحقق — الرمز سيتم إرساله خلال 24 ساعة أو أقل",
            phoneNumber = dto.PhoneNumber,
            role = result.Role
        });
    }

    [HttpPost("login")]
    [EnableRateLimiting("auth")]
    public async Task<ActionResult<AuthResponseDto>> Login([FromBody] LoginDto dto)
    {
        var result = await _authService.LoginAsync(dto);
        return Ok(result);
    }

    [HttpPost("refresh")]
    public async Task<ActionResult<AuthResponseDto>> Refresh([FromBody] RefreshTokenDto dto)
    {
        var result = await _authService.RefreshAsync(dto.RefreshToken);
        return Ok(result);
    }

    [HttpPost("logout")]
    [Authorize]
    public async Task<IActionResult> Logout([FromBody] RefreshTokenDto dto)
    {
        var jti = User.FindFirst(JwtRegisteredClaimNames.Jti)?.Value;
        await _authService.LogoutAsync(dto.RefreshToken, jti);
        return Ok(new { message = "تم تسجيل الخروج بنجاح" });
    }

    [HttpPost("send-otp")]
    [EnableRateLimiting("auth")]
    public async Task<IActionResult> SendOtp([FromBody] SendOtpDto dto)
    {
        var code = System.Security.Cryptography.RandomNumberGenerator.GetInt32(100000, 999999).ToString();

        var otp = new OtpCode
        {
            PhoneNumber = dto.PhoneNumber,
            Code = code,
            ExpiresAt = DateTime.UtcNow.AddHours(24),
            IsUsed = false,
            Purpose = dto.Purpose ?? "verify"
        };

        _context.OtpCodes.Add(otp);
        await _context.SaveChangesAsync();

        await _smsService.SendOtpAsync(dto.PhoneNumber, code);

        return Ok(new { message = "تم إرسال رمز التحقق" });
    }

    [HttpPost("verify-otp")]
    [EnableRateLimiting("auth")]
    public async Task<IActionResult> VerifyOtp([FromBody] VerifyOtpDto dto)
    {
        var purpose = dto.Purpose ?? "verify";
        var utcNow = DateTime.UtcNow;
        var localNow = utcNow.AddHours(3); // Palestine timezone UTC+3

        Console.WriteLine($"[VERIFY-OTP] Phone: {dto.PhoneNumber}, Code: {dto.Code}, Purpose: {purpose}, UtcNow: {utcNow}, LocalNow: {localNow}");

        var otp = await _context.OtpCodes
            .Where(o => o.PhoneNumber == dto.PhoneNumber
                && o.Code == dto.Code
                && o.Purpose == purpose
                && !o.IsUsed)
            .OrderByDescending(o => o.CreatedAt)
            .FirstOrDefaultAsync();

        Console.WriteLine($"[VERIFY-OTP] Found OTP (before expiry check): {otp != null}");

        if (otp != null)
        {
            Console.WriteLine($"[VERIFY-OTP] OTP ExpiresAt: {otp.ExpiresAt}, UtcNow: {utcNow}, Diff: {(otp.ExpiresAt - utcNow).TotalMinutes} min");

            if (otp.ExpiresAt <= utcNow)
            {
                Console.WriteLine($"[VERIFY-OTP] OTP EXPIRED - ExpiresAt <= UtcNow");
                otp = null;
            }
        }

        if (otp == null)
        {
            // Debug: check if any OTP exists for this phone
            var anyOtp = await _context.OtpCodes
                .Where(o => o.PhoneNumber == dto.PhoneNumber && o.Code == dto.Code)
                .OrderByDescending(o => o.CreatedAt)
                .FirstOrDefaultAsync();

            if (anyOtp != null)
            {
                Console.WriteLine($"[VERIFY-OTP] OTP exists but filtered out - Purpose: {anyOtp.Purpose}, IsUsed: {anyOtp.IsUsed}, ExpiresAt: {anyOtp.ExpiresAt}, UtcNow: {DateTime.UtcNow}");
            }
            else
            {
                Console.WriteLine($"[VERIFY-OTP] No OTP found at all for Phone: {dto.PhoneNumber}, Code: {dto.Code}");
            }

            throw new BadRequestException("رمز التحقق غير صحيح أو منتهي الصلاحية");
        }

        otp.IsUsed = true;

        if (purpose == "verify")
        {
            var user = await _context.Users
                .FirstOrDefaultAsync(u => u.PhoneNumber == dto.PhoneNumber);

            if (user != null)
            {
                user.IsPhoneVerified = true;
                user.PhoneVerificationStatus = "Verified";
                user.IsActive = true;
            }
        }

        await _context.SaveChangesAsync();

        return Ok(new { verified = true, message = "تم التحقق بنجاح" });
    }

    [HttpPost("forgot-password")]
    [EnableRateLimiting("auth")]
    public async Task<IActionResult> ForgotPassword([FromBody] ForgotPasswordDto dto)
    {
        var user = await _context.Users
            .FirstOrDefaultAsync(u => u.PhoneNumber == dto.PhoneNumber);

        if (user == null)
            return Ok(new { message = "إذا كان الرقم مسجلاً، ستتلقى رسالة تحقق" });

        var code = System.Security.Cryptography.RandomNumberGenerator.GetInt32(100000, 999999).ToString();

        var otp = new OtpCode
        {
            PhoneNumber = dto.PhoneNumber,
            Code = code,
            ExpiresAt = DateTime.UtcNow.AddHours(24),
            IsUsed = false,
            Purpose = "reset"
        };

        _context.OtpCodes.Add(otp);
        await _context.SaveChangesAsync();

        var admins = await _context.Users.Where(u => u.Role == "Admin").ToListAsync();
        foreach (var admin in admins)
        {
            _context.Notifications.Add(new Notification
            {
                UserId = admin.Id,
                Title = "طلب إعادة تعيين كلمة المرور",
                Message = $"الزبون {user.FullName} ({dto.PhoneNumber}) طلب إعادة تعيين كلمة المرور. الرمز: {code}",
                Type = "password_reset",
                IsRead = false
            });
        }
        await _context.SaveChangesAsync();

        await _smsService.SendOtpAsync(dto.PhoneNumber, code);

        return Ok(new { message = "إذا كان الرقم مسجلاً، ستتلقى رسالة تحقق" });
    }

    [HttpPost("reset-password")]
    [EnableRateLimiting("auth")]
    public async Task<IActionResult> ResetPassword([FromBody] ResetPasswordDto dto)
    {
        var utcNow = DateTime.UtcNow;
        Console.WriteLine($"[RESET-PASSWORD] Phone: {dto.PhoneNumber}, Code: {dto.Code}, UtcNow: {utcNow}");

        var otp = await _context.OtpCodes
            .Where(o => o.PhoneNumber == dto.PhoneNumber
                && o.Code == dto.Code
                && o.Purpose == "reset"
                && !o.IsUsed
                && o.ExpiresAt > utcNow)
            .OrderByDescending(o => o.CreatedAt)
            .FirstOrDefaultAsync();

        Console.WriteLine($"[RESET-PASSWORD] Found OTP: {otp != null}");

        if (otp == null)
        {
            var anyOtp = await _context.OtpCodes
                .Where(o => o.PhoneNumber == dto.PhoneNumber && o.Code == dto.Code)
                .OrderByDescending(o => o.CreatedAt)
                .FirstOrDefaultAsync();

            if (anyOtp != null)
            {
                Console.WriteLine($"[RESET-PASSWORD] OTP exists but filtered - Purpose: {anyOtp.Purpose}, IsUsed: {anyOtp.IsUsed}, ExpiresAt: {anyOtp.ExpiresAt}");
            }
            else
            {
                Console.WriteLine($"[RESET-PASSWORD] No OTP found for Phone: {dto.PhoneNumber}, Code: {dto.Code}");
            }

            throw new BadRequestException("رمز التحقق غير صحيح أو منتهي الصلاحية");
        }

        var user = await _context.Users
            .FirstOrDefaultAsync(u => u.PhoneNumber == dto.PhoneNumber);

        if (user == null)
            throw new BadRequestException("المستخدم غير موجود");

        user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(dto.NewPassword);
        otp.IsUsed = true;
        await _context.SaveChangesAsync();

        return Ok(new { message = "تم تغيير كلمة المرور بنجاح" });
    }

    [HttpGet("check-status")]
    [Authorize]
    public async Task<IActionResult> CheckStatus()
    {
        var sub = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value
                  ?? User.FindFirst("sub")?.Value;
        if (string.IsNullOrEmpty(sub))
            return Ok(new { isActive = false });

        var userId = Guid.Parse(sub);
        var user = await _context.Users.FindAsync(userId);
        if (user == null)
            return Ok(new { isActive = false });

        return Ok(new { isActive = user.IsActive });
    }

    [HttpPost("fcm-token")]
    [Authorize]
    public async Task<IActionResult> SaveFcmToken([FromBody] FcmTokenDto dto)
    {
        var userId = GetCurrentUserId();
        if (userId == Guid.Empty) return Unauthorized();

        var fcmService = HttpContext.RequestServices.GetRequiredService<BarberBooking.API.Services.IFirebasePushService>();
        await fcmService.SaveDeviceToken(userId, dto.Token, dto.Platform, dto.DeviceName);

        return Ok(new { message = "تم حفظ رمز الإشعارات" });
    }

    private Guid GetCurrentUserId()
    {
        var sub = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(sub)) return Guid.Empty;
        return Guid.Parse(sub);
    }
}
