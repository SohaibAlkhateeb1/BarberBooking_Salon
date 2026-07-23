namespace BarberBooking.Application.DTOs.Auth;

public class SendOtpDto
{
    public string PhoneNumber { get; set; } = string.Empty;
    public string? Purpose { get; set; }
}

public class VerifyOtpDto
{
    public string PhoneNumber { get; set; } = string.Empty;
    public string Code { get; set; } = string.Empty;
    public string? Purpose { get; set; }
}

public class ForgotPasswordDto
{
    public string PhoneNumber { get; set; } = string.Empty;
}

public class ResetPasswordDto
{
    public string PhoneNumber { get; set; } = string.Empty;
    public string Code { get; set; } = string.Empty;
    public string NewPassword { get; set; } = string.Empty;
}

public class RefreshTokenDto
{
    public string RefreshToken { get; set; } = string.Empty;
}
