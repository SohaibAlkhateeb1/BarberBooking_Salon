namespace BarberBooking.Application.DTOs.Payment;

public class CreatePaymentRequestDto
{
    public string PaymentMethod { get; set; } = string.Empty;
    public string? ReceiptImageUrl { get; set; }
    public bool IsUpgrade { get; set; }
    public string? FromPlanName { get; set; }
    public string? PlanName { get; set; }
    public decimal? Amount { get; set; }
    public bool IsYearly { get; set; }
}

public class PaymentRequestDto
{
    public Guid Id { get; set; }
    public string PaymentMethod { get; set; } = string.Empty;
    public decimal Amount { get; set; }
    public string PlanName { get; set; } = string.Empty;
    public bool IsYearly { get; set; }
    public string? ReceiptImageUrl { get; set; }
    public string Status { get; set; } = string.Empty;
    public string? AdminNotes { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? ReviewedAt { get; set; }
    public bool IsUpgrade { get; set; }
    public string? FromPlanName { get; set; }
}

public class ReviewPaymentRequestDto
{
    public string Status { get; set; } = string.Empty;
    public string? AdminNotes { get; set; }
}

public class PaymentRequestWithBarberDto : PaymentRequestDto
{
    public string BarberName { get; set; } = string.Empty;
    public string ShopName { get; set; } = string.Empty;
    public string PhoneNumber { get; set; } = string.Empty;
}
