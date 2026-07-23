using BarberBooking.Domain.Entities;

namespace BarberBooking.Domain.Entities;

public class PaymentRequest : BaseEntity
{
    public Guid BarberProfileId { get; set; }
    public string PaymentMethod { get; set; } = string.Empty;
    public decimal Amount { get; set; }
    public string PlanName { get; set; } = string.Empty;
    public bool IsYearly { get; set; }
    public string? ReceiptImageUrl { get; set; }
    public string Status { get; set; } = "pending";
    public string? AdminNotes { get; set; }
    public DateTime? ReviewedAt { get; set; }
    public Guid? ReviewedById { get; set; }
    public bool IsUpgrade { get; set; }
    public string? FromPlanName { get; set; }

    public BarberProfile BarberProfile { get; set; } = null!;
}
