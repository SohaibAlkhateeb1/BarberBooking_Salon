namespace BarberBooking.Application.DTOs.Customer;

public class UpdateProfileDto
{
    public string? FullName { get; set; }
    public string? PhoneNumber { get; set; }
    public string? Email { get; set; }
    public string? ProfileImageUrl { get; set; }
    public string? City { get; set; }
    public double? Latitude { get; set; }
    public double? Longitude { get; set; }
}

public class UploadImageDto
{
    public string? ImageBase64 { get; set; }
}
