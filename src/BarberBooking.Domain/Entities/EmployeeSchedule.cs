namespace BarberBooking.Domain.Entities;

public class EmployeeSchedule : BaseEntity
{
    public Guid EmployeeId { get; set; }
    public string DayName { get; set; } = string.Empty;
    public bool IsOpen { get; set; }
    public TimeSpan OpenTime { get; set; }
    public TimeSpan CloseTime { get; set; }

    public BarberEmployee Employee { get; set; } = null!;
}
