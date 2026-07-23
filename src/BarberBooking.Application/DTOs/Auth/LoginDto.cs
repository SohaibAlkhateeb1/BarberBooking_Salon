namespace BarberBooking.Application.DTOs.Auth;

public class LoginDto
{
    public string PhoneNumber { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
}
