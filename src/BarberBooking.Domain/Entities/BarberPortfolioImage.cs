namespace BarberBooking.Domain.Entities;

public class BarberPortfolioImage : BaseEntity
{
    public Guid BarberProfileId { get; set; }
    public string ImageUrl { get; set; } = string.Empty;
    public string? Caption { get; set; }
    public int SortOrder { get; set; }

    public BarberProfile BarberProfile { get; set; } = null!;
}
