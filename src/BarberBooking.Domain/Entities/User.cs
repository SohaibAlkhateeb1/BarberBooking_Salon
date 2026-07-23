namespace BarberBooking.Domain.Entities;

public class User : BaseEntity
{
    public string FullName { get; set; } = string.Empty;
    public string PhoneNumber { get; set; } = string.Empty;
    public string PasswordHash { get; set; } = string.Empty;
    public string? Email { get; set; }
    public string? ProfileImageUrl { get; set; }
    public string? City { get; set; }
    public double? Latitude { get; set; }
    public double? Longitude { get; set; }
    public string Role { get; set; } = "Customer";
    public bool IsActive { get; set; } = true;
    public bool IsPhoneVerified { get; set; } = false;
    public string PhoneVerificationStatus { get; set; } = "Pending"; // Pending, Verified, Rejected

    // Booking behavior tracking
    public int NoShowCount { get; set; } = 0;
    public bool IsBookingBlocked { get; set; } = false;
    public DateTime? BookingBlockedAt { get; set; }
    public string? BlockReason { get; set; }

    // Cancellation tracking
    public int DailyCancelCount { get; set; } = 0;
    public DateTime? LastCancelDate { get; set; }

    public BarberProfile? BarberProfile { get; set; }
}
