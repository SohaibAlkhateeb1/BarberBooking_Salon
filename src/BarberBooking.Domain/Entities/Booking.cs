namespace BarberBooking.Domain.Entities;

public class Booking : BaseEntity
{
    public Guid CustomerId { get; set; }
    public Guid BarberProfileId { get; set; }
    public Guid BarberServiceId { get; set; }
    public Guid? EmployeeId { get; set; }
    public DateTime BookingDate { get; set; }
    public TimeSpan BookingTime { get; set; }
    public decimal TotalPrice { get; set; }
    public string Status { get; set; } = "Upcoming";
    public string? CancellationReason { get; set; }
    public string? Notes { get; set; }
    public string? PromoCode { get; set; }
    public decimal? DiscountAmount { get; set; }
    public decimal FinalPrice { get; set; }
    public string PaymentStatus { get; set; } = "Unpaid";
    public string PaymentMethod { get; set; } = "cash";
    public DateTime? PaidAt { get; set; }

    // Reschedule tracking
    public int RescheduleCount { get; set; } = 0;

    // No-show tracking
    public DateTime? NoShowAt { get; set; }
    public Guid? NoShowBarberId { get; set; }

    // Service timer tracking
    public DateTime? StartedAt { get; set; }
    public DateTime? ServiceCompletedAt { get; set; }
    public int ServiceDurationMinutes { get; set; } = 30;

    public User Customer { get; set; } = null!;
    public BarberProfile BarberProfile { get; set; } = null!;
    public BarberService BarberService { get; set; } = null!;
    public BarberEmployee? Employee { get; set; }
}
