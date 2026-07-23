namespace BarberBooking.Domain.Entities;

public class Favorite : BaseEntity
{
    public Guid UserId { get; set; }
    public Guid BarberProfileId { get; set; }

    public User User { get; set; } = null!;
    public BarberProfile BarberProfile { get; set; } = null!;
}
