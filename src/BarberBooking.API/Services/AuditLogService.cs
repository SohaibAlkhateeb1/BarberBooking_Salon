using BarberBooking.Domain.Entities;
using BarberBooking.Infrastructure.Data;

namespace BarberBooking.API.Services;

public interface IAuditLogService
{
    Task LogAsync(string action, string entityType, Guid? entityId, string adminId, string adminName, string? details = null, string? oldValue = null, string? newValue = null);
}

public class AuditLogService : IAuditLogService
{
    private readonly BarberBookingDbContext _context;

    public AuditLogService(BarberBookingDbContext context)
    {
        _context = context;
    }

    public async Task LogAsync(string action, string entityType, Guid? entityId, string adminId, string adminName, string? details = null, string? oldValue = null, string? newValue = null)
    {
        var log = new AuditLog
        {
            Action = action,
            EntityType = entityType,
            EntityId = entityId,
            AdminId = adminId,
            AdminName = adminName,
            Details = details,
            OldValue = oldValue,
            NewValue = newValue
        };

        _context.AuditLogs.Add(log);
        await _context.SaveChangesAsync();
    }
}
