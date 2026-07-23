using BarberBooking.Application.DTOs.Auth;

namespace BarberBooking.Application.Interfaces;

public interface IBarberAuthService
{
    Task<AuthResponseDto> RegisterBarberAsync(RegisterBarberDto dto);
    Task<AuthResponseDto> LoginBarberAsync(LoginDto dto);
    Task<AuthResponseDto> RefreshAsync(string refreshToken);
    Task LogoutAsync(string refreshToken, string jti);
    Task<bool> IsPhoneTakenAsync(string phone);
}
