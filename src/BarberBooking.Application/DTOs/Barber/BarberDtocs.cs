namespace BarberBooking.Application.DTOs.Barber;

public class RejectBookingDto
{
    public string? Reason { get; set; }
}

public class BarberRescheduleDto
{
    public DateTime NewDate { get; set; }
    public string NewTime { get; set; } = string.Empty;
}

public class CreateServiceDto
{
    public string Name { get; set; } = string.Empty;
    public decimal Price { get; set; }
    public int DurationInMinutes { get; set; }
}

public class UpdateScheduleDto
{
    public string DayName { get; set; } = string.Empty;
    public bool IsOpen { get; set; }
    public string OpenTime { get; set; } = string.Empty;
    public string CloseTime { get; set; } = string.Empty;
}
