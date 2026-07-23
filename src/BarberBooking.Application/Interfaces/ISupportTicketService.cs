using BarberBooking.Application.DTOs.Support;

namespace BarberBooking.Application.Interfaces;

public interface ISupportTicketService
{
    Task<TicketDto> CreateTicketAsync(Guid userId, CreateTicketDto dto, bool isBarber);
    Task<List<TicketDto>> GetUserTicketsAsync(Guid userId);
    Task<List<TicketDto>> GetBarberTicketsAsync(Guid barberProfileId);
    Task<TicketDto?> GetTicketDetailAsync(Guid ticketId, Guid userId);
    Task<TicketReplyDto> AddReplyAsync(Guid ticketId, Guid userId, ReplyTicketDto dto, string role);
    Task<bool> RateTicketAsync(Guid ticketId, Guid userId, RateTicketDto dto);
    Task<List<TicketDto>> GetAllTicketsAsync(string? status, string? priority, string? ticketType);
    Task<TicketDto?> AdminGetTicketDetailAsync(Guid ticketId);
    Task<TicketReplyDto> AdminReplyAsync(Guid ticketId, Guid adminId, ReplyTicketDto dto);
    Task<bool> UpdateTicketStatusAsync(Guid ticketId, UpdateTicketStatusDto dto);
    Task<string> GenerateTicketNumberAsync();
}
