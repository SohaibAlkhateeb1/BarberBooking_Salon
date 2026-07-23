using BarberBooking.Application.DTOs.Support;
using BarberBooking.Application.Interfaces;
using BarberBooking.Domain.Entities;
using BarberBooking.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace BarberBooking.API.Services;

public class SupportTicketService : ISupportTicketService
{
    private readonly BarberBookingDbContext _context;

    public SupportTicketService(BarberBookingDbContext context)
    {
        _context = context;
    }

    public async Task<string> GenerateTicketNumberAsync()
    {
        var lastTicket = await _context.SupportTickets
            .OrderByDescending(t => t.CreatedAt)
            .FirstOrDefaultAsync();

        if (lastTicket == null)
            return "#1001";

        var lastNumber = int.Parse(lastTicket.TicketNumber.Replace("#", ""));
        return $"#{lastNumber + 1}";
    }

    private async Task<(string role, string? plan)> GetUserRoleAndPlanAsync(Guid userId)
    {
        var user = await _context.Users.FindAsync(userId);
        if (user == null) return ("Customer", null);

        if (user.Role == "Barber")
        {
            var barberProfile = await _context.BarberProfiles.FirstOrDefaultAsync(bp => bp.UserId == userId);
            if (barberProfile != null)
            {
                var activeSub = await _context.BarberSubscriptions
                    .Where(s => s.BarberProfileId == barberProfile.Id && s.Status == "active" && s.EndDate > DateTime.UtcNow)
                    .OrderByDescending(s => s.EndDate)
                    .FirstOrDefaultAsync();
                if (activeSub != null)
                {
                    var plan = await _context.SubscriptionPlans.FindAsync(activeSub.SubscriptionPlanId);
                    return ("Barber", plan?.Name);
                }
            }
            return ("Barber", null);
        }
        return ("Customer", null);
    }

    public async Task<TicketDto> CreateTicketAsync(Guid userId, CreateTicketDto dto, bool isBarber)
    {
        var user = await _context.Users.FindAsync(userId);
        if (user == null)
            throw new Exception("User not found");

        var ticketNumber = await GenerateTicketNumberAsync();
        var priority = "Normal";

        if (isBarber)
        {
            var barberProfile = await _context.BarberProfiles
                .FirstOrDefaultAsync(bp => bp.UserId == userId);

            if (barberProfile != null)
            {
                var activeSub = await _context.BarberSubscriptions
                    .Where(s => s.BarberProfileId == barberProfile.Id
                        && s.Status == "active"
                        && s.EndDate > DateTime.UtcNow)
                    .OrderByDescending(s => s.EndDate)
                    .FirstOrDefaultAsync();

                if (activeSub != null)
                {
                    var plan = await _context.SubscriptionPlans.FindAsync(activeSub.SubscriptionPlanId);
                    if (plan != null)
                    {
                        var planName = plan.Name.ToLower();
                        if (planName.Contains("premium"))
                            priority = "Urgent";
                        else if (planName.Contains("pro"))
                            priority = "High";
                    }
                }
            }
        }

        Guid? relatedBarberId = null;
        if (!string.IsNullOrEmpty(dto.RelatedBarberId))
            relatedBarberId = Guid.Parse(dto.RelatedBarberId);

        Guid? relatedBookingId = null;
        if (!string.IsNullOrEmpty(dto.RelatedBookingId))
            relatedBookingId = Guid.Parse(dto.RelatedBookingId);

        var ticket = new SupportTicket
        {
            Id = Guid.NewGuid(),
            TicketNumber = ticketNumber,
            UserId = userId,
            TicketType = dto.TicketType,
            Subject = dto.Subject,
            Description = dto.Description,
            Status = "Open",
            Priority = priority,
            AttachmentUrl = dto.AttachmentUrl,
            RelatedBookingId = relatedBookingId,
            RelatedBarberId = relatedBarberId,
        };

        _context.SupportTickets.Add(ticket);
        await _context.SaveChangesAsync();

        var (userRole, userPlan) = await GetUserRoleAndPlanAsync(userId);
        return MapToDto(ticket, user.FullName, null, null, user.PhoneNumber, userRole, userPlan);
    }

    public async Task<List<TicketDto>> GetUserTicketsAsync(Guid userId)
    {
        var tickets = await _context.SupportTickets
            .Where(t => t.UserId == userId)
            .OrderByDescending(t => t.CreatedAt)
            .ToListAsync();

        var (userRole, userPlan) = await GetUserRoleAndPlanAsync(userId);
        var result = new List<TicketDto>();
        foreach (var t in tickets)
        {
            var user = t.UserId.HasValue ? await _context.Users.FindAsync(t.UserId.Value) : null;
            result.Add(MapToDto(t, user?.FullName, null, null, user?.PhoneNumber, userRole, userPlan));
        }
        return result;
    }

    public async Task<List<TicketDto>> GetBarberTicketsAsync(Guid barberProfileId)
    {
        var tickets = await _context.SupportTickets
            .Where(t => t.BarberProfileId == barberProfileId || t.UserId == _context.BarberProfiles.Where(bp => bp.Id == barberProfileId).Select(bp => bp.UserId).FirstOrDefault())
            .OrderByDescending(t => t.CreatedAt)
            .ToListAsync();

        var result = new List<TicketDto>();
        foreach (var t in tickets)
        {
            var user = t.UserId.HasValue ? await _context.Users.FindAsync(t.UserId.Value) : null;
            result.Add(MapToDto(t, user?.FullName, null, null, user?.PhoneNumber));
        }
        return result;
    }

    public async Task<TicketDto?> GetTicketDetailAsync(Guid ticketId, Guid userId)
    {
        var ticket = await _context.SupportTickets.FindAsync(ticketId);
        if (ticket == null || ticket.UserId != userId)
            return null;

        var user = ticket.UserId.HasValue ? await _context.Users.FindAsync(ticket.UserId.Value) : null;

        var replies = await _context.TicketReplies
            .Where(r => r.SupportTicketId == ticketId)
            .OrderBy(r => r.CreatedAt)
            .ToListAsync();

        var dto = MapToDto(ticket, user?.FullName, null, null, user?.PhoneNumber, user?.Role ?? "Customer", null);
        dto.Replies = replies.Select(r => new TicketReplyDto
        {
            Id = r.Id,
            SenderRole = r.SenderRole,
            SenderName = r.SenderRole == "Admin" ? "فريق الدعم" : (user?.FullName ?? ""),
            Message = r.Message,
            AttachmentUrl = r.AttachmentUrl,
            CreatedAt = r.CreatedAt,
        }).ToList();

        return dto;
    }

    public async Task<TicketReplyDto> AddReplyAsync(Guid ticketId, Guid userId, ReplyTicketDto dto, string role)
    {
        var ticket = await _context.SupportTickets.FindAsync(ticketId);
        if (ticket == null)
            throw new Exception("Ticket not found");

        var reply = new TicketReply
        {
            Id = Guid.NewGuid(),
            SupportTicketId = ticketId,
            SenderId = userId,
            SenderRole = role,
            Message = dto.Message,
            AttachmentUrl = dto.AttachmentUrl,
        };

        ticket.LastReplyAt = DateTime.UtcNow;
        if (ticket.Status == "Open")
            ticket.Status = "In Progress";

        _context.TicketReplies.Add(reply);
        await _context.SaveChangesAsync();

        return new TicketReplyDto
        {
            Id = reply.Id,
            SenderRole = reply.SenderRole,
            SenderName = reply.SenderRole == "Admin" ? "فريق الدعم" : (await _context.Users.FindAsync(userId))?.FullName ?? "",
            Message = reply.Message,
            AttachmentUrl = reply.AttachmentUrl,
            CreatedAt = reply.CreatedAt,
        };
    }

    public async Task<bool> RateTicketAsync(Guid ticketId, Guid userId, RateTicketDto dto)
    {
        var ticket = await _context.SupportTickets.FindAsync(ticketId);
        if (ticket == null || ticket.UserId != userId || ticket.Status != "Closed")
            return false;

        ticket.Rating = dto.Rating;
        ticket.RatingComment = dto.Comment;
        await _context.SaveChangesAsync();
        return true;
    }

    public async Task<List<TicketDto>> GetAllTicketsAsync(string? status, string? priority, string? ticketType)
    {
        var query = _context.SupportTickets.AsQueryable();

        if (!string.IsNullOrEmpty(status))
            query = query.Where(t => t.Status == status);
        if (!string.IsNullOrEmpty(priority))
            query = query.Where(t => t.Priority == priority);
        if (!string.IsNullOrEmpty(ticketType))
            query = query.Where(t => t.TicketType == ticketType);

        var tickets = await query
            .OrderByDescending(t => t.Priority == "Urgent" ? 1 : t.Priority == "High" ? 2 : 3)
            .ThenByDescending(t => t.CreatedAt)
            .ToListAsync();

        var result = new List<TicketDto>();
        foreach (var t in tickets)
        {
            var user = t.UserId.HasValue ? await _context.Users.FindAsync(t.UserId.Value) : null;
            var barber = t.RelatedBarberId.HasValue
                ? await _context.BarberProfiles.Include(bp => bp.User).FirstOrDefaultAsync(bp => bp.Id == t.RelatedBarberId.Value)
                : null;

            string userRole = "Customer";
            string? userPlan = null;
            if (user != null && user.Role == "Barber")
            {
                userRole = "Barber";
                var bp = await _context.BarberProfiles.FirstOrDefaultAsync(p => p.UserId == user.Id);
                if (bp != null)
                {
                    var sub = await _context.BarberSubscriptions
                        .Where(s => s.BarberProfileId == bp.Id && s.Status == "active" && s.EndDate > DateTime.UtcNow)
                        .OrderByDescending(s => s.EndDate)
                        .FirstOrDefaultAsync();
                    if (sub != null)
                    {
                        var plan = await _context.SubscriptionPlans.FindAsync(sub.SubscriptionPlanId);
                        userPlan = plan?.Name;
                    }
                }
            }

            result.Add(MapToDto(t, user?.FullName, barber?.User?.FullName, barber?.ShopName, user?.PhoneNumber, userRole, userPlan));
        }
        return result;
    }

    public async Task<TicketDto?> AdminGetTicketDetailAsync(Guid ticketId)
    {
        var ticket = await _context.SupportTickets.FindAsync(ticketId);
        if (ticket == null) return null;

        var user = ticket.UserId.HasValue ? await _context.Users.FindAsync(ticket.UserId.Value) : null;
        var barber = ticket.RelatedBarberId.HasValue
            ? await _context.BarberProfiles.Include(bp => bp.User).FirstOrDefaultAsync(bp => bp.Id == ticket.RelatedBarberId.Value)
            : null;

        string userRole = "Customer";
        string? userPlan = null;
        if (user != null && user.Role == "Barber")
        {
            userRole = "Barber";
            var bp = await _context.BarberProfiles.FirstOrDefaultAsync(p => p.UserId == user.Id);
            if (bp != null)
            {
                var sub = await _context.BarberSubscriptions
                    .Where(s => s.BarberProfileId == bp.Id && s.Status == "active" && s.EndDate > DateTime.UtcNow)
                    .OrderByDescending(s => s.EndDate)
                    .FirstOrDefaultAsync();
                if (sub != null)
                {
                    var plan = await _context.SubscriptionPlans.FindAsync(sub.SubscriptionPlanId);
                    userPlan = plan?.Name;
                }
            }
        }

        var replies = await _context.TicketReplies
            .Where(r => r.SupportTicketId == ticketId)
            .OrderBy(r => r.CreatedAt)
            .ToListAsync();

        var dto = MapToDto(ticket, user?.FullName, barber?.User?.FullName, barber?.ShopName, user?.PhoneNumber, userRole, userPlan);
        dto.Replies = replies.Select(r => new TicketReplyDto
        {
            Id = r.Id,
            SenderRole = r.SenderRole,
            SenderName = r.SenderRole == "Admin" ? "فريق الدعم" : (r.SenderId == ticket.UserId ? user?.FullName ?? "" : "فريق الدعم"),
            Message = r.Message,
            AttachmentUrl = r.AttachmentUrl,
            CreatedAt = r.CreatedAt,
        }).ToList();

        return dto;
    }

    public async Task<TicketReplyDto> AdminReplyAsync(Guid ticketId, Guid adminId, ReplyTicketDto dto)
    {
        var ticket = await _context.SupportTickets.FindAsync(ticketId);
        if (ticket == null)
            throw new Exception("Ticket not found");

        var reply = new TicketReply
        {
            Id = Guid.NewGuid(),
            SupportTicketId = ticketId,
            SenderId = adminId,
            SenderRole = "Admin",
            Message = dto.Message,
            AttachmentUrl = dto.AttachmentUrl,
        };

        ticket.LastReplyAt = DateTime.UtcNow;
        if (ticket.Status == "Open")
            ticket.Status = "In Progress";

        _context.TicketReplies.Add(reply);
        await _context.SaveChangesAsync();

        return new TicketReplyDto
        {
            Id = reply.Id,
            SenderRole = "Admin",
            SenderName = "فريق الدعم",
            Message = reply.Message,
            AttachmentUrl = reply.AttachmentUrl,
            CreatedAt = reply.CreatedAt,
        };
    }

    public async Task<bool> UpdateTicketStatusAsync(Guid ticketId, UpdateTicketStatusDto dto)
    {
        var ticket = await _context.SupportTickets.FindAsync(ticketId);
        if (ticket == null) return false;

        ticket.Status = dto.Status;
        if (dto.AssignedTo != null)
            ticket.AssignedTo = dto.AssignedTo;
        if (dto.Status == "Closed")
            ticket.ClosedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();
        return true;
    }

    private TicketDto MapToDto(SupportTicket t, string? userName, string? barberName, string? shopName, string? userPhone = null, string userRole = "Customer", string? subscriptionPlan = null)
    {
        return new TicketDto
        {
            Id = t.Id,
            TicketNumber = t.TicketNumber,
            TicketType = t.TicketType,
            Subject = t.Subject,
            Description = t.Description,
            Status = t.Status,
            Priority = t.Priority,
            AttachmentUrl = t.AttachmentUrl,
            UserName = userName,
            UserPhone = userPhone,
            UserRole = userRole,
            SubscriptionPlan = subscriptionPlan,
            BarberName = barberName,
            ShopName = shopName,
            AssignedTo = t.AssignedTo,
            Rating = t.Rating,
            RatingComment = t.RatingComment,
            CreatedAt = t.CreatedAt,
            LastReplyAt = t.LastReplyAt,
            ClosedAt = t.ClosedAt,
        };
    }
}
