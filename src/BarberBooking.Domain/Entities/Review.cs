namespace BarberBooking.Domain.Entities;

public class Review : BaseEntity
{
    public Guid CustomerId { get; set; }
    public Guid BarberProfileId { get; set; }
    public int Rating { get; set; }
    public string? Comment { get; set; }

    public User Customer { get; set; } = null!;
    public BarberProfile BarberProfile { get; set; } = null!;
}
