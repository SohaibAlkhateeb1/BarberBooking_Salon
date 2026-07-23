namespace BarberBooking.Domain.Entities;

public class TicketReply : BaseEntity
{
    public Guid SupportTicketId { get; set; }
    public Guid SenderId { get; set; }
    public string SenderRole { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public string? AttachmentUrl { get; set; }

    public SupportTicket SupportTicket { get; set; } = null!;
    public User Sender { get; set; } = null!;
}
