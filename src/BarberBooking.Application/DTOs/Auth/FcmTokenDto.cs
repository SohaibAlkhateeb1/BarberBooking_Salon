namespace BarberBooking.Application.DTOs.Auth;

public class FcmTokenDto
{
    public string Token { get; set; } = string.Empty;
    public string Platform { get; set; } = "android";
    public string? DeviceName { get; set; }
}
