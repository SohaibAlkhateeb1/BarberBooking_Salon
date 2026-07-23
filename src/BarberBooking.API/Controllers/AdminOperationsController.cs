using System.Security.Claims;
using BarberBooking.API.Services;
using BarberBooking.Infrastructure.Data;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace BarberBooking.API.Controllers;

[ApiController]
[Route("api/admin/operations")]
[Authorize(Roles = "Admin")]
public class AdminOperationsController : ControllerBase
{
    private readonly BarberBookingDbContext _context;
    private readonly IAuditLogService _auditLog;
    private readonly IAutoAlertService _autoAlert;

    public AdminOperationsController(
        BarberBookingDbContext context,
        IAuditLogService auditLog,
        IAutoAlertService autoAlert)
    {
        _context = context;
        _auditLog = auditLog;
        _autoAlert = autoAlert;
    }

    private string GetAdminId() => User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? User.FindFirst("sub")?.Value ?? "";
    private string GetAdminName() => User.FindFirst("FullName")?.Value ?? "Admin";

    // ========== COUNTS ==========

    [HttpGet("counts")]
    public async Task<IActionResult> GetCounts()
    {
        var pendingTickets = await _context.SupportTickets.CountAsync(t => t.Status == "New" || t.Status == "Open");
        var pendingComplaints = await _context.SupportTickets.CountAsync(t => t.TicketType == "Complaint" && (t.Status == "New" || t.Status == "Open"));
        var pendingResets = await _context.Notifications.CountAsync(n => n.Type == "password_reset" && !n.IsRead);
        var pendingVerifications = await _context.Users.CountAsync(u => u.Role == "Customer" && u.PhoneVerificationStatus == "Pending");
        var newAlerts = await _context.SystemAlerts.CountAsync(a => a.Status == "New");
        var criticalAlerts = await _context.SystemAlerts.CountAsync(a => a.Severity == "Critical" && a.Status != "Resolved");
        var totalAlerts = await _context.SystemAlerts.CountAsync(a => a.Status != "Resolved");

        // Subscriptions: new subscriptions (last 24h) + cancel_pending
        var oneDayAgo = DateTime.UtcNow.AddHours(-24);
        var newSubscriptions = await _context.BarberSubscriptions
            .CountAsync(s => s.CreatedAt >= oneDayAgo && s.Status == "active");
        var cancelPendingSubscriptions = await _context.BarberSubscriptions
            .CountAsync(s => s.Status == "cancel_pending");

        // Payment requests: pending
        var pendingPayments = await _context.PaymentRequests
            .CountAsync(p => p.Status == "pending");

        return Ok(new
        {
            pendingActions = new
            {
                tickets = pendingTickets,
                passwordResets = pendingResets,
                verifications = pendingVerifications,
                complaints = pendingComplaints,
                total = pendingTickets + pendingResets + pendingVerifications
            },
            alerts = new
            {
                @new = newAlerts,
                critical = criticalAlerts,
                total = totalAlerts
            },
            subscriptions = new
            {
                @new = newSubscriptions,
                cancelPending = cancelPendingSubscriptions,
                total = newSubscriptions + cancelPendingSubscriptions
            },
            payments = new
            {
                pending = pendingPayments
            },
            unreadNotifications = pendingResets + pendingVerifications + newAlerts + pendingPayments
        });
    }

    // ========== RECENT ACTIVITY (Bell) ==========

    [HttpGet("recent")]
    public async Task<IActionResult> GetRecentActivity()
    {
        var recentTickets = await _context.SupportTickets
            .OrderByDescending(t => t.CreatedAt)
            .Take(3)
            .Select(t => new
            {
                type = "ticket",
                title = $"تذكرة دعم #{t.TicketNumber}",
                subtitle = t.Subject,
                status = t.Status,
                icon = "headphones",
                color = t.Priority == "Urgent" ? "red" : t.Priority == "High" ? "orange" : "blue",
                createdAt = t.CreatedAt
            })
            .ToListAsync();

        var recentAlerts = await _context.SystemAlerts
            .OrderByDescending(a => a.CreatedAt)
            .Take(3)
            .Select(a => new
            {
                type = "alert",
                title = a.Title,
                subtitle = a.Message,
                status = a.Status,
                icon = "alert-triangle",
                color = a.Severity == "Critical" ? "red" : a.Severity == "Warning" ? "orange" : "blue",
                createdAt = a.CreatedAt
            })
            .ToListAsync();

        var recentResets = await _context.Notifications
            .Where(n => n.Type == "password_reset")
            .OrderByDescending(n => n.CreatedAt)
            .Take(3)
            .Select(n => new
            {
                type = "password_reset",
                title = "طلب إعادة كلمة مرور",
                subtitle = n.Message,
                status = n.IsRead ? "Read" : "New",
                icon = "key-round",
                color = "purple",
                createdAt = n.CreatedAt
            })
            .ToListAsync();

        var all = recentTickets.Cast<object>()
            .Union(recentAlerts.Cast<object>())
            .Union(recentResets.Cast<object>())
            .OrderByDescending(x => ((dynamic)x).createdAt)
            .Take(10)
            .ToList();

        return Ok(all);
    }

    // ========== SYSTEM ALERTS ==========

    [HttpGet("alerts")]
    public async Task<IActionResult> GetAlerts(
        [FromQuery] string? status,
        [FromQuery] string? severity,
        [FromQuery] string? category,
        [FromQuery] string? priority,
        [FromQuery] string? search)
    {
        var query = _context.SystemAlerts
            .Include(a => a.TargetUser)
            .AsQueryable();

        if (!string.IsNullOrEmpty(status)) query = query.Where(a => a.Status == status);
        if (!string.IsNullOrEmpty(severity)) query = query.Where(a => a.Severity == severity);
        if (!string.IsNullOrEmpty(category)) query = query.Where(a => a.Category == category);
        if (!string.IsNullOrEmpty(priority)) query = query.Where(a => a.Priority == priority);
        if (!string.IsNullOrEmpty(search)) query = query.Where(a => a.Title.Contains(search) || a.Message.Contains(search));

        var alerts = await query
            .OrderByDescending(a => a.CreatedAt)
            .Select(a => new
            {
                id = a.Id,
                title = a.Title,
                message = a.Message,
                severity = a.Severity,
                category = a.Category,
                status = a.Status,
                priority = a.Priority,
                source = a.Source,
                isAutoGenerated = a.IsAutoGenerated,
                readAt = a.ReadAt,
                createdBy = a.CreatedBy,
                relatedEntityType = a.RelatedEntityType,
                relatedEntityId = a.RelatedEntityId,
                targetUserId = a.TargetUserId,
                targetUserType = a.TargetUserType,
                targetUserName = a.TargetUser != null ? a.TargetUser.FullName : null,
                createdAt = a.CreatedAt
            })
            .ToListAsync();

        return Ok(alerts);
    }

    [HttpGet("alerts/{id}")]
    public async Task<IActionResult> GetAlert(Guid id)
    {
        var alert = await _context.SystemAlerts
            .Include(a => a.TargetUser)
            .FirstOrDefaultAsync(a => a.Id == id);

        if (alert == null) return NotFound();

        return Ok(new
        {
            id = alert.Id,
            title = alert.Title,
            message = alert.Message,
            severity = alert.Severity,
            category = alert.Category,
            status = alert.Status,
            priority = alert.Priority,
            source = alert.Source,
            isAutoGenerated = alert.IsAutoGenerated,
            readAt = alert.ReadAt,
            createdBy = alert.CreatedBy,
            relatedEntityType = alert.RelatedEntityType,
            relatedEntityId = alert.RelatedEntityId,
            targetUserId = alert.TargetUserId,
            targetUserType = alert.TargetUserType,
            targetUserName = alert.TargetUser?.FullName,
            createdAt = alert.CreatedAt
        });
    }

    [HttpPost("alerts")]
    public async Task<IActionResult> CreateAlert([FromBody] CreateAlertDto dto)
    {
        var alert = new Domain.Entities.SystemAlert
        {
            Title = dto.Title,
            Message = dto.Message,
            Severity = dto.Severity ?? "Info",
            Category = dto.Category ?? "Custom",
            Priority = dto.Priority ?? "Medium",
            Source = "Admin",
            IsAutoGenerated = false,
            TargetUserId = dto.TargetUserId,
            TargetUserType = dto.TargetUserType,
            CreatedBy = GetAdminName()
        };

        _context.SystemAlerts.Add(alert);
        await _context.SaveChangesAsync();

        await _auditLog.LogAsync("CreatedAlert", "SystemAlert", alert.Id, GetAdminId(), GetAdminName(), $"Created alert: {dto.Title}");

        return Ok(new { id = alert.Id, message = "تم إنشاء التنبيه" });
    }

    [HttpPut("alerts/{id}/status")]
    public async Task<IActionResult> UpdateAlertStatus(Guid id, [FromBody] UpdateStatusDto dto)
    {
        var alert = await _context.SystemAlerts.FindAsync(id);
        if (alert == null) return NotFound();

        var oldStatus = alert.Status;
        alert.Status = dto.Status;

        if (dto.Status == "Viewed" && alert.ReadAt == null)
            alert.ReadAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();
        await _auditLog.LogAsync("UpdatedAlertStatus", "SystemAlert", id, GetAdminId(), GetAdminName(), $"Changed status from {oldStatus} to {dto.Status}");

        return Ok(new { message = "تم تحديث الحالة" });
    }

    [HttpDelete("alerts/{id}")]
    public async Task<IActionResult> DeleteAlert(Guid id)
    {
        var alert = await _context.SystemAlerts.FindAsync(id);
        if (alert == null) return NotFound();

        _context.SystemAlerts.Remove(alert);
        await _context.SaveChangesAsync();

        await _auditLog.LogAsync("DeletedAlert", "SystemAlert", id, GetAdminId(), GetAdminName(), $"Deleted alert: {alert.Title}");

        return Ok(new { message = "تم حذف التنبيه" });
    }

    // ========== AUDIT LOG ==========

    [HttpGet("audit-log")]
    public async Task<IActionResult> GetAuditLog(
        [FromQuery] string? action,
        [FromQuery] string? entityType,
        [FromQuery] string? adminId,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20)
    {
        var query = _context.AuditLogs.AsQueryable();

        if (!string.IsNullOrEmpty(action)) query = query.Where(l => l.Action.Contains(action));
        if (!string.IsNullOrEmpty(entityType)) query = query.Where(l => l.EntityType == entityType);
        if (!string.IsNullOrEmpty(adminId)) query = query.Where(l => l.AdminId == adminId);

        var totalCount = await query.CountAsync();
        var logs = await query
            .OrderByDescending(l => l.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(l => new
            {
                id = l.Id,
                action = l.Action,
                entityType = l.EntityType,
                entityId = l.EntityId,
                adminId = l.AdminId,
                adminName = l.AdminName,
                details = l.Details,
                oldValue = l.OldValue,
                newValue = l.NewValue,
                createdAt = l.CreatedAt
            })
            .ToListAsync();

        return Ok(new { logs, totalCount, page, pageSize });
    }

    // ========== ACTIVITY TIMELINE ==========

    [HttpGet("timeline/{entityType}/{entityId}")]
    public async Task<IActionResult> GetTimeline(string entityType, Guid entityId)
    {
        var events = new List<object>();

        if (entityType == "ticket")
        {
            var ticket = await _context.SupportTickets.FindAsync(entityId);
            if (ticket == null) return NotFound();

            events.Add(new { time = ticket.CreatedAt, action = "تم إنشاء التذكرة", icon = "ticket", color = "blue", by = "Customer" });

            if (ticket.LastReplyAt.HasValue)
                events.Add(new { time = ticket.LastReplyAt.Value, action = "آخر رد", icon = "message", color = "green", by = "Admin" });

            if (ticket.ClosedAt.HasValue)
                events.Add(new { time = ticket.ClosedAt.Value, action = "تم إغلاق التذكرة", icon = "check-circle", color = "gray", by = "System" });

            var replies = await _context.TicketReplies
                .Where(r => r.SupportTicketId == entityId)
                .OrderBy(r => r.CreatedAt)
                .ToListAsync();

            foreach (var reply in replies)
            {
                events.Add(new { time = reply.CreatedAt, action = $"رد من {reply.SenderRole}: {reply.Message}", icon = "message-square", color = reply.SenderRole == "Admin" ? "green" : "blue", by = reply.SenderRole });
            }
        }

        var auditLogs = await _context.AuditLogs
            .Where(l => l.EntityType == entityType && l.EntityId == entityId)
            .OrderBy(l => l.CreatedAt)
            .ToListAsync();

        foreach (var log in auditLogs)
        {
            events.Add(new { time = log.CreatedAt, action = log.Details ?? log.Action, icon = "shield", color = "purple", by = log.AdminName });
        }

        var sorted = events.OrderBy(e => ((dynamic)e).time).ToList();
        return Ok(sorted);
    }

    // ========== TICKETS (from Support) ==========

    [HttpGet("tickets")]
    public async Task<IActionResult> GetTickets(
        [FromQuery] string? status,
        [FromQuery] string? priority,
        [FromQuery] string? ticketType,
        [FromQuery] string? role)
    {
        var query = _context.SupportTickets
            .Include(t => t.User)
            .Include(t => t.BarberProfile)
            .ThenInclude(bp => bp.User)
            .AsQueryable();

        if (!string.IsNullOrEmpty(status)) query = query.Where(t => t.Status == status);
        if (!string.IsNullOrEmpty(priority)) query = query.Where(t => t.Priority == priority);
        if (!string.IsNullOrEmpty(ticketType)) query = query.Where(t => t.TicketType == ticketType);

        var tickets = await query
            .OrderByDescending(t => t.CreatedAt)
            .Select(t => new
            {
                id = t.Id,
                ticketNumber = t.TicketNumber,
                ticketType = t.TicketType,
                subject = t.Subject,
                description = t.Description,
                status = t.Status,
                priority = t.Priority,
                userName = t.User != null ? t.User.FullName : null,
                userPhone = t.User != null ? t.User.PhoneNumber : null,
                userRole = t.User != null ? t.User.Role : null,
                barberName = t.BarberProfile != null && t.BarberProfile.User != null ? t.BarberProfile.User.FullName : null,
                shopName = t.BarberProfile != null ? t.BarberProfile.ShopName : null,
                createdAt = t.CreatedAt,
                lastReplyAt = t.LastReplyAt
            })
            .ToListAsync();

        if (!string.IsNullOrEmpty(role))
        {
            if (role == "Customer") tickets = tickets.Where(t => t.userRole == "Customer").ToList();
            else if (role == "Barber") tickets = tickets.Where(t => t.userRole == "Barber").ToList();
        }

        return Ok(tickets);
    }

    // ========== VERIFICATIONS ==========

    [HttpGet("verifications")]
    public async Task<IActionResult> GetVerifications(
        [FromQuery] string? status,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20)
    {
        var query = _context.Users
            .Where(u => u.Role == "Customer")
            .AsQueryable();

        if (!string.IsNullOrEmpty(status)) query = query.Where(u => u.PhoneVerificationStatus == status);

        var totalCount = await query.CountAsync();
        var users = await query
            .OrderByDescending(u => u.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(u => new
            {
                id = u.Id,
                fullName = u.FullName,
                phoneNumber = u.PhoneNumber,
                email = u.Email,
                city = u.City,
                isPhoneVerified = u.IsPhoneVerified,
                phoneVerificationStatus = u.PhoneVerificationStatus,
                isActive = u.IsActive,
                createdAt = u.CreatedAt
            })
            .ToListAsync();

        return Ok(new { customers = users, totalCount });
    }

    [HttpGet("verifications/pending-count")]
    public async Task<IActionResult> GetPendingVerificationCount()
    {
        var count = await _context.Users.CountAsync(u => u.Role == "Customer" && u.PhoneVerificationStatus == "Pending");
        return Ok(new { count });
    }

    [HttpPost("verifications/{id}/send-otp")]
    public async Task<IActionResult> SendVerificationOtp(Guid id)
    {
        var user = await _context.Users.FindAsync(id);
        if (user == null) return NotFound(new { message = "المستخدم غير موجود" });

        var otp = new Random().Next(100000, 999999).ToString();
        _context.OtpCodes.Add(new Domain.Entities.OtpCode
        {
            PhoneNumber = user.PhoneNumber,
            Code = otp,
            ExpiresAt = DateTime.UtcNow.AddHours(24),
            IsUsed = false,
            Purpose = "verify"
        });

        await _context.SaveChangesAsync();

        await _auditLog.LogAsync("GeneratedVerificationOtp", "User", id, GetAdminId(), GetAdminName(), $"Generated OTP for {user.FullName}. Code: {otp}");

        return Ok(new { message = $"تم توليد الرمز للزبون {user.FullName}. انسخ الكود وأرسله عبر واتساب على الرقم {user.PhoneNumber}", code = otp });
    }

    [HttpPost("verifications/{id}/reject")]
    public async Task<IActionResult> RejectVerification(Guid id, [FromBody] RejectDto? dto)
    {
        var user = await _context.Users.FindAsync(id);
        if (user == null) return NotFound(new { message = "المستخدم غير موجود" });

        user.PhoneVerificationStatus = "Rejected";
        await _context.SaveChangesAsync();

        await _auditLog.LogAsync("RejectedVerification", "User", id, GetAdminId(), GetAdminName(), $"Rejected verification for {user.FullName}. Reason: {dto?.Reason}");

        return Ok(new { message = "تم رفض التحقق" });
    }

    // ========== PASSWORD RESETS ==========

    [HttpGet("password-resets")]
    public async Task<IActionResult> GetPasswordResets(
        [FromQuery] string? status,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20)
    {
        var query = _context.Notifications
            .Where(n => n.Type == "password_reset")
            .AsQueryable();

        if (status == "pending") query = query.Where(n => !n.IsRead);
        else if (status == "completed") query = query.Where(n => n.IsRead);

        var totalCount = await query.CountAsync();
        var notifications = await query
            .OrderByDescending(n => n.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(n => new
            {
                id = n.Id,
                title = n.Title,
                message = n.Message,
                isRead = n.IsRead,
                createdAt = n.CreatedAt
            })
            .ToListAsync();

        return Ok(new { notifications, totalCount });
    }

    [HttpPost("password-resets/{id}/mark-read")]
    public async Task<IActionResult> MarkPasswordResetRead(Guid id)
    {
        var notification = await _context.Notifications.FindAsync(id);
        if (notification == null) return NotFound();

        notification.IsRead = true;
        await _context.SaveChangesAsync();

        await _auditLog.LogAsync("MarkedPasswordResetRead", "Notification", id, GetAdminId(), GetAdminName());

        return Ok(new { message = "تم التحديد كمقروء" });
    }

    [HttpPost("password-resets/mark-all-read")]
    public async Task<IActionResult> MarkAllPasswordResetsRead()
    {
        var unread = await _context.Notifications
            .Where(n => n.Type == "password_reset" && !n.IsRead)
            .ToListAsync();

        foreach (var n in unread) n.IsRead = true;
        await _context.SaveChangesAsync();

        await _auditLog.LogAsync("MarkedAllPasswordResetsRead", "Notification", null, GetAdminId(), GetAdminName(), $"Marked {unread.Count} as read");

        return Ok(new { message = "تم تحديد الكل كمقروء" });
    }

    // ========== CREATE ALERT FOR COMPLAINT ==========

    [HttpPost("alerts/from-complaint")]
    public async Task<IActionResult> CreateComplaintAlert([FromBody] ComplaintAlertDto dto)
    {
        await _autoAlert.CreateAlertAsync(
            title: dto.Title,
            message: dto.Message,
            severity: dto.Priority == "Critical" ? "Critical" : dto.Priority == "High" ? "Warning" : "Info",
            category: "Custom",
            source: dto.Source ?? "Customer",
            priority: dto.Priority ?? "High",
            targetUserId: dto.TargetUserId,
            targetType: dto.TargetUserType,
            relatedEntityType: "SupportTicket",
            relatedEntityId: dto.TicketId,
            createdBy: dto.Source ?? "Customer"
        );

        return Ok(new { message = "تم إنشاء التنبيه" });
    }
}

// ========== DTOs ==========

public class CreateAlertDto
{
    public string Title { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public string? Severity { get; set; }
    public string? Category { get; set; }
    public string? Priority { get; set; }
    public Guid? TargetUserId { get; set; }
    public string? TargetUserType { get; set; }
}

public class UpdateStatusDto
{
    public string Status { get; set; } = string.Empty;
}

public class RejectDto
{
    public string? Reason { get; set; }
}

public class ComplaintAlertDto
{
    public string Title { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public string? Priority { get; set; }
    public string? Source { get; set; }
    public Guid? TargetUserId { get; set; }
    public string? TargetUserType { get; set; }
    public Guid? TicketId { get; set; }
}
