namespace BarberBooking.Domain.Entities;

public class UserDevice : BaseEntity
{
    public Guid UserId { get; set; }
    public string FcmToken { get; set; } = string.Empty;
    public string Platform { get; set; } = string.Empty; // android, ios, web
    public string? DeviceName { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTime? LastUsedAt { get; set; }

    public User User { get; set; } = null!;
}
