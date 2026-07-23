namespace BarberBooking.Application.DTOs.Support;

public class CreateTicketDto
{
    public string TicketType { get; set; } = string.Empty;
    public string Subject { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string? AttachmentUrl { get; set; }
    public string? RelatedBookingId { get; set; }
    public string? RelatedBarberId { get; set; }
}

public class ReplyTicketDto
{
    public string Message { get; set; } = string.Empty;
    public string? AttachmentUrl { get; set; }
}

public class UpdateTicketStatusDto
{
    public string Status { get; set; } = string.Empty;
    public string? AssignedTo { get; set; }
}

public class RateTicketDto
{
    public int Rating { get; set; }
    public string? Comment { get; set; }
}

public class TicketDto
{
    public Guid Id { get; set; }
    public string TicketNumber { get; set; } = string.Empty;
    public string TicketType { get; set; } = string.Empty;
    public string Subject { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public string Priority { get; set; } = string.Empty;
    public string? AttachmentUrl { get; set; }
    public string? UserName { get; set; }
    public string? UserPhone { get; set; }
    public string UserRole { get; set; } = string.Empty;
    public string? SubscriptionPlan { get; set; }
    public string? BarberName { get; set; }
    public string? ShopName { get; set; }
    public string? AssignedTo { get; set; }
    public int? Rating { get; set; }
    public string? RatingComment { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? LastReplyAt { get; set; }
    public DateTime? ClosedAt { get; set; }
    public List<TicketReplyDto> Replies { get; set; } = new();
}

public class TicketReplyDto
{
    public Guid Id { get; set; }
    public string SenderRole { get; set; } = string.Empty;
    public string SenderName { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public string? AttachmentUrl { get; set; }
    public DateTime CreatedAt { get; set; }
}
