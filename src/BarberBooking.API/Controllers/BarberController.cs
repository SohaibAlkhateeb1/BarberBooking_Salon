using System.IdentityModel.Tokens.Jwt;
using BarberBooking.Application.DTOs.Auth;
using BarberBooking.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;

namespace BarberBooking.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class BarberController : ControllerBase
{
    private readonly IBarberAuthService _barberAuthService;

    public BarberController(IBarberAuthService barberAuthService)
    {
        _barberAuthService = barberAuthService;
    }

    [HttpPost("register")]
    [EnableRateLimiting("auth")]
    public async Task<ActionResult<AuthResponseDto>> Register([FromBody] RegisterBarberDto dto)
    {
        var result = await _barberAuthService.RegisterBarberAsync(dto);
        return Created(string.Empty, result);
    }

    [HttpGet("check-phone")]
    public async Task<IActionResult> CheckPhone([FromQuery] string phone)
    {
        if (string.IsNullOrWhiteSpace(phone))
            return BadRequest(new { message = "رقم الهاتف مطلوب" });

        var cleaned = phone.Replace(" ", "").Replace("-", "");
        var exists = await _barberAuthService.IsPhoneTakenAsync(cleaned);
        return Ok(new { available = !exists });
    }

    [HttpPost("login")]
    [EnableRateLimiting("auth")]
    public async Task<ActionResult<AuthResponseDto>> Login([FromBody] LoginDto dto)
    {
        var result = await _barberAuthService.LoginBarberAsync(dto);
        return Ok(result);
    }

    [HttpPost("refresh")]
    public async Task<ActionResult<AuthResponseDto>> Refresh([FromBody] RefreshTokenDto dto)
    {
        var result = await _barberAuthService.RefreshAsync(dto.RefreshToken);
        return Ok(result);
    }

    [HttpPost("logout")]
    [Authorize]
    public async Task<IActionResult> Logout([FromBody] RefreshTokenDto dto)
    {
        var jti = User.FindFirst(JwtRegisteredClaimNames.Jti)?.Value;
        await _barberAuthService.LogoutAsync(dto.RefreshToken, jti);
        return Ok(new { message = "تم تسجيل الخروج بنجاح" });
    }
}
