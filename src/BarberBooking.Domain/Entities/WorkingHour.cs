namespace BarberBooking.Domain.Entities;

public class WorkingHour : BaseEntity
{
    public Guid BarberProfileId { get; set; }
    public string DayName { get; set; } = string.Empty;
    public bool IsOpen { get; set; }
    public TimeSpan OpenTime { get; set; }
    public TimeSpan CloseTime { get; set; }

    public BarberProfile BarberProfile { get; set; } = null!;
}
