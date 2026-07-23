namespace BarberBooking.Application.DTOs.Booking;

public class CreateBookingDto
{
    public Guid BarberProfileId { get; set; }
    public Guid BarberServiceId { get; set; }
    public List<Guid>? ServiceIds { get; set; }
    public Guid? EmployeeId { get; set; }
    public DateTime BookingDate { get; set; }
    public string BookingTime { get; set; } = string.Empty;
    public string? Notes { get; set; }
    public string? PromoCode { get; set; }
}

public class RescheduleDto
{
    public DateTime NewDate { get; set; }
    public string NewTime { get; set; } = string.Empty;
}

public class CancelDto
{
    public string? Reason { get; set; }
}

public class AddReviewDto
{
    public int Rating { get; set; }
    public string? Comment { get; set; }
}
