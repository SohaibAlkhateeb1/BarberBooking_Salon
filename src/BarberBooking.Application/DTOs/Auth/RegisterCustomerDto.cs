namespace BarberBooking.Application.DTOs.Auth;

public class RegisterCustomerDto
{
    public string FullName { get; set; } = string.Empty;
    public string PhoneNumber { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
    public string? Email { get; set; }
    public string? ProfileImageUrl { get; set; }
    public bool AcceptTerms { get; set; }
}
