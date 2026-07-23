namespace BarberBooking.Domain.Entities;

public class SupportTicket : BaseEntity
{
    public string TicketNumber { get; set; } = string.Empty;
    public Guid? UserId { get; set; }
    public Guid? BarberProfileId { get; set; }
    public string TicketType { get; set; } = string.Empty;
    public string Subject { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string Status { get; set; } = "Open";
    public string Priority { get; set; } = "Normal";
    public string? AttachmentUrl { get; set; }
    public Guid? RelatedBookingId { get; set; }
    public Guid? RelatedBarberId { get; set; }
    public string? AssignedTo { get; set; }
    public int? Rating { get; set; }
    public string? RatingComment { get; set; }
    public DateTime? ClosedAt { get; set; }
    public DateTime? LastReplyAt { get; set; }

    public User? User { get; set; }
    public BarberProfile? BarberProfile { get; set; }
    public Booking? RelatedBooking { get; set; }
    public BarberProfile? RelatedBarber { get; set; }
    public ICollection<TicketReply> Replies { get; set; } = new List<TicketReply>();
}
