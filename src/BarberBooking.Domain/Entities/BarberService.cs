namespace BarberBooking.Domain.Entities;

public class BarberService : BaseEntity
{
    public Guid BarberProfileId { get; set; }
    public string Name { get; set; } = string.Empty;
    public decimal Price { get; set; }
    public int DurationInMinutes { get; set; }

    public BarberProfile BarberProfile { get; set; } = null!;
}
