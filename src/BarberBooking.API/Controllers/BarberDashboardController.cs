using System.IO;
using System.Security.Claims;
using BarberBooking.Application.DTOs.Barber;
using BarberBooking.Application.DTOs.Subscription;
using BarberBooking.Application.Interfaces;
using BarberBooking.Domain.Entities;
using BarberBooking.Infrastructure.Data;
using BarberBooking.API.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace BarberBooking.API.Controllers;

[ApiController]
[Route("api/barber/dashboard")]
[Authorize(Roles = "Barber")]
public class BarberDashboardController : ControllerBase
{
    private readonly BarberBookingDbContext _context;
    private readonly IFileStorageService _fileStorage;
    private readonly IFirebasePushService _fcm;

    public BarberDashboardController(BarberBookingDbContext context, IFileStorageService fileStorage, IFirebasePushService fcm)
    {
        _context = context;
        _fileStorage = fileStorage;
        _fcm = fcm;
    }

    private Guid GetCurrentUserId()
    {
        var sub = User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? User.FindFirst("sub")?.Value;
        if (string.IsNullOrEmpty(sub))
            throw new UnauthorizedAccessException("ط؛ظٹط± ظ…طµط±ط­");
        return Guid.Parse(sub);
    }

    private async Task<BarberProfile> GetBarberProfile()
    {
        var userId = GetCurrentUserId();
        var profile = await _context.BarberProfiles
            .FirstOrDefaultAsync(bp => bp.UserId == userId);
        if (profile == null)
            throw new KeyNotFoundException("ط§ظ„ط­ظ„ط§ظ‚ ط؛ظٹط± ظ…ظˆط¬ظˆط¯");
        return profile;
    }

    [HttpGet]
    public async Task<IActionResult> GetDashboard()
    {
        var profile = await GetBarberProfile();
        var today = DateTime.UtcNow.Date;
        var todayUtc = DateTime.SpecifyKind(today, DateTimeKind.Utc);

        var todayBookings = await _context.Bookings
            .Where(b => b.BarberProfileId == profile.Id
                && b.BookingDate >= todayUtc
                && b.BookingDate < todayUtc.AddDays(1))
            .ToListAsync();

        var todayRevenue = todayBookings
            .Where(b => b.Status == "Completed")
            .Sum(b => b.TotalPrice);

        var reviews = await _context.Reviews
            .Where(r => r.BarberProfileId == profile.Id)
            .ToListAsync();

        var averageRating = reviews.Any() ? reviews.Average(r => r.Rating) : 0.0;
        var reviewCount = reviews.Count;

        var activeClients = await _context.Bookings
            .Where(b => b.BarberProfileId == profile.Id && (b.Status == "Completed" || b.Status == "Upcoming"))
            .Select(b => b.CustomerId)
            .Distinct()
            .CountAsync();

        var recentBookings = await _context.Bookings
            .Include(b => b.Customer)
            .Include(b => b.BarberService)
            .Include(b => b.Employee)
            .Where(b => b.BarberProfileId == profile.Id)
            .OrderByDescending(b => b.BookingDate)
            .Take(5)
            .Select(b => new
            {
                id = b.Id,
                customerName = b.Customer.FullName,
                serviceName = b.BarberService.Name,
                bookingDate = b.BookingDate,
                bookingTime = b.BookingTime.ToString(@"hh\:mm"),
                totalPrice = b.TotalPrice,
                finalPrice = b.FinalPrice,
                status = b.Status,
                notes = b.Notes,
                employeeName = b.Employee != null ? b.Employee.Name : null
            })
            .ToListAsync();

        var weeklyRevenue = new List<object>();
        for (int i = 6; i >= 0; i--)
        {
            var day = today.AddDays(-i);
            var dayUtc = DateTime.SpecifyKind(day, DateTimeKind.Utc);
            var dayBookings = await _context.Bookings
                .Where(b => b.BarberProfileId == profile.Id
                    && b.BookingDate >= dayUtc
                    && b.BookingDate < dayUtc.AddDays(1)
                    && b.Status == "Completed")
                .SumAsync(b => b.TotalPrice);
            weeklyRevenue.Add(new { day = day.ToString("ddd"), revenue = dayBookings });
        }

        return Ok(new
        {
            shopName = profile.ShopName,
            todayBookingsCount = todayBookings.Count,
            todayRevenue = todayRevenue,
            averageRating = Math.Round(averageRating, 1),
            reviewCount = reviewCount,
            activeClients = activeClients,
            recentBookings = recentBookings,
            weeklyRevenue = weeklyRevenue
        });
    }

    [HttpGet("bookings")]
    public async Task<IActionResult> GetBookings([FromQuery] string? status, [FromQuery] string? date)
    {
        var profile = await GetBarberProfile();

        var query = _context.Bookings
            .Include(b => b.Customer)
            .Include(b => b.BarberService)
            .Include(b => b.Employee)
            .Where(b => b.BarberProfileId == profile.Id)
            .AsQueryable();

        if (!string.IsNullOrEmpty(status))
        {
            query = status.ToLower() switch
            {
                "today" => query.Where(b => b.BookingDate.Date == DateTime.UtcNow.Date),
                "pending" => query.Where(b => b.Status == "Pending"),
                "accepted" => query.Where(b => b.Status == "Accepted"),
                "inprogress" => query.Where(b => b.Status == "InProgress"),
                "paymentpending" => query.Where(b => b.Status == "PaymentPending"),
                "completed" => query.Where(b => b.Status == "Completed"),
                "cancelled" => query.Where(b => b.Status == "Cancelled"),
                "rejected" => query.Where(b => b.Status == "Rejected"),
                "noshow" => query.Where(b => b.Status == "NoShow"),
                "expired" => query.Where(b => b.Status == "Expired"),
                _ => query
            };
        }

        if (!string.IsNullOrEmpty(date) && DateTime.TryParse(date, out var filterDate))
        {
            var filterDateUtc = DateTime.SpecifyKind(filterDate.Date, DateTimeKind.Utc);
            query = query.Where(b => b.BookingDate >= filterDateUtc && b.BookingDate < filterDateUtc.AddDays(1));
        }

        var bookings = await query
            .Include(b => b.Employee)
            .OrderByDescending(b => b.BookingDate)
            .ThenBy(b => b.BookingTime)
            .Select(b => new
            {
                id = b.Id,
                customerName = b.Customer.FullName,
                customerPhone = b.Customer.PhoneNumber,
                serviceName = b.BarberService.Name,
                serviceDuration = b.BarberService.DurationInMinutes,
                servicePrice = b.BarberService.Price,
                bookingDate = b.BookingDate,
                bookingTime = b.BookingTime.ToString(@"hh\:mm"),
                totalPrice = b.TotalPrice,
                finalPrice = b.FinalPrice,
                status = b.Status,
                notes = b.Notes,
                paymentStatus = b.PaymentStatus,
                paymentMethod = b.PaymentMethod,
                promoCode = b.PromoCode,
                discountAmount = b.DiscountAmount,
                employeeId = b.EmployeeId,
                employeeName = b.Employee != null ? b.Employee.Name : null,
                createdAt = b.CreatedAt,
                startedAt = b.StartedAt,
                serviceCompletedAt = b.ServiceCompletedAt,
                serviceDurationMinutes = b.ServiceDurationMinutes
            })
            .ToListAsync();

        return Ok(bookings);
    }

    [HttpPut("bookings/{id}/accept")]
    public async Task<IActionResult> AcceptBooking(Guid id)
    {
        var profile = await GetBarberProfile();

        var booking = await _context.Bookings
            .Include(b => b.Customer)
            .Include(b => b.BarberService)
            .FirstOrDefaultAsync(b => b.Id == id && b.BarberProfileId == profile.Id);

        if (booking == null)
            return NotFound(new { message = "ط§ظ„ط­ط¬ط² ط؛ظٹط± ظ…ظˆط¬ظˆط¯" });

        if (booking.Status != "Pending")
            return BadRequest(new { message = "ظ„ط§ ظٹظ…ظƒظ† ظ‚ط¨ظˆظ„ ظ‡ط°ط§ ط§ظ„ط­ط¬ط²" });

        booking.Status = "Accepted";
        await _context.SaveChangesAsync();

        _context.Notifications.Add(new Notification
        {
            UserId = booking.CustomerId,
            Title = "طھظ… طھط£ظƒظٹط¯ ط§ظ„ظ…ظˆط¹ط¯",
            Message = $"طھظ… طھط£ظƒظٹط¯ ظ…ظˆط¹ط¯ظƒ â€” {booking.BarberService.Name} ظٹظˆظ… {booking.BookingDate:yyyy-MM-dd} ط§ظ„ط³ط§ط¹ط© {booking.BookingTime:hh\\:mm}",
            Type = "booking",
            IsRead = false,
            Data = booking.Id.ToString()
        });
        await _context.SaveChangesAsync();

        // Send FCM push notification to customer
        await _fcm.SendToUser(
            booking.CustomerId,
            "طھظ… طھط£ظƒظٹط¯ ظ…ظˆط¹ط¯ظƒ âœ…",
            $"طھظ… طھط£ظƒظٹط¯ ظ…ظˆط¹ط¯ظƒ â€” {booking.BarberService.Name} ظٹظˆظ… {booking.BookingDate:yyyy-MM-dd} ط§ظ„ط³ط§ط¹ط© {booking.BookingTime:hh\\:mm}",
            new Dictionary<string, string>
            {
                { "type", "booking_update" },
                { "bookingId", booking.Id.ToString() },
                { "action", "booking_accepted" }
            });

        return Ok(new { message = "طھظ… ظ‚ط¨ظˆظ„ ط§ظ„ط­ط¬ط²" });
    }

    [HttpPut("bookings/{id}/reject")]
    public async Task<IActionResult> RejectBooking(Guid id, [FromBody] RejectBookingDto dto)
    {
        var profile = await GetBarberProfile();

        var booking = await _context.Bookings
            .Include(b => b.Customer)
            .Include(b => b.BarberService)
            .FirstOrDefaultAsync(b => b.Id == id && b.BarberProfileId == profile.Id);

        if (booking == null)
            return NotFound(new { message = "ط§ظ„ط­ط¬ط² ط؛ظٹط± ظ…ظˆط¬ظˆط¯" });

        if (booking.Status != "Pending")
            return BadRequest(new { message = "ظ„ط§ ظٹظ…ظƒظ† ط±ظپط¶ ظ‡ط°ط§ ط§ظ„ط­ط¬ط²" });

        booking.Status = "Rejected";
        booking.CancellationReason = dto?.Reason ?? "طھظ… ط§ظ„ط±ظپط¶ ظ…ظ† ظ‚ط¨ظ„ ط§ظ„ط­ظ„ط§ظ‚";
        await _context.SaveChangesAsync();

        _context.Notifications.Add(new Notification
        {
            UserId = booking.CustomerId,
            Title = "طھظ… ط±ظپط¶ ط§ظ„ظ…ظˆط¹ط¯",
            Message = $"طھظ… ط±ظپط¶ ظ…ظˆط¹ط¯ظƒ â€” {booking.BarberService.Name}. ط§ظ„ط³ط¨ط¨: {booking.CancellationReason}",
            Type = "booking",
            IsRead = false,
            Data = booking.Id.ToString()
        });
        await _context.SaveChangesAsync();

        return Ok(new { message = "طھظ… ط±ظپط¶ ط§ظ„ط­ط¬ط²" });
    }

    [HttpPut("bookings/{id}/start")]
    public async Task<IActionResult> StartBooking(Guid id)
    {
        var profile = await GetBarberProfile();

        var booking = await _context.Bookings
            .Include(b => b.Customer)
            .Include(b => b.BarberService)
            .Include(b => b.BarberProfile)
            .FirstOrDefaultAsync(b => b.Id == id && b.BarberProfileId == profile.Id);

        if (booking == null)
            return NotFound(new { message = "ط§ظ„ط­ط¬ط² ط؛ظٹط± ظ…ظˆط¬ظˆط¯" });

        if (booking.Status != "Accepted")
            return BadRequest(new { message = "ظ„ط§ ظٹظ…ظƒظ† ط¨ط¯ط، ظ‡ط°ط§ ط§ظ„ط­ط¬ط²" });

        booking.Status = "InProgress";
        booking.StartedAt = DateTime.UtcNow;
        booking.ServiceDurationMinutes = booking.BarberService.DurationInMinutes;
        await _context.SaveChangesAsync();

        // In-app notification
        _context.Notifications.Add(new Notification
        {
            UserId = booking.CustomerId,
            Title = "ظ…ظˆط¹ط¯ظƒ ط§ظ„ط¢ظ†",
            Message = $"ط®ط¯ظ…طھظƒ ط¨ط¯ط£طھ ظپظٹ {booking.BarberProfile.ShopName}",
            Type = "booking",
            IsRead = false,
            Data = booking.Id.ToString()
        });
        await _context.SaveChangesAsync();

        // FCM push to customer
        try
        {
            await _fcm.SendToUser(
                booking.CustomerId,
                "ظ…ظˆط¹ط¯ظƒ ط§ظ„ط¢ظ†",
                $"ط®ط¯ظ…طھظƒ ط¨ط¯ط£طھ ظپظٹ {booking.BarberProfile.ShopName}",
                new Dictionary<string, string>
                {
                    { "type", "booking_update" },
                    { "bookingId", booking.Id.ToString() },
                    { "action", "service_started" }
                });
        }
        catch (Exception ex)
        {
            // Log but don't fail
        }

        return Ok(new { message = "طھظ… ط¨ط¯ط، ط§ظ„ط®dظ…ط©", startedAt = booking.StartedAt, durationMinutes = booking.ServiceDurationMinutes });
    }

    [HttpPut("bookings/{id}/request-payment")]
    public async Task<IActionResult> RequestPayment(Guid id)
    {
        var profile = await GetBarberProfile();

        var booking = await _context.Bookings
            .Include(b => b.Customer)
            .Include(b => b.BarberService)
            .FirstOrDefaultAsync(b => b.Id == id && b.BarberProfileId == profile.Id);

        if (booking == null)
            return NotFound(new { message = "ط§ظ„ط­ط¬ط² ط؛ظٹط± ظ…ظˆط¬ظˆط¯" });

        if (booking.Status != "InProgress")
            return BadRequest(new { message = "ظ„ط§ ظٹظ…ظƒظ† ط·ظ„ط¨ ط§ظ„ط¯ظپط¹ ظ„ظ‡ط°ط§ ط§ظ„ط­ط¬ط²" });

        booking.Status = "PaymentPending";
        booking.ServiceCompletedAt = DateTime.UtcNow;
        await _context.SaveChangesAsync();

        _context.Notifications.Add(new Notification
        {
            UserId = booking.CustomerId,
            Title = "ط¨ط§ظ†طھط¸ط§ط± ط§ظ„ط¯ظپط¹",
            Message = $"ط§ظ†طھظ‡طھ ط®ط¯ظ…ط© {booking.BarberService.Name}. ط§ظ„ظ…ط¨ظ„ط؛: {booking.FinalPrice}â‚ھ â€” ظٹط±ط¬ظ‰ ط¥طھظ…ط§ظ… ط§ظ„ط¯ظپط¹.",
            Type = "booking",
            IsRead = false,
            Data = booking.Id.ToString()
        });
        await _context.SaveChangesAsync();

        return Ok(new { message = "طھظ… ط·ظ„ط¨ ط§ظ„ط¯ظپط¹" });
    }

    [HttpPut("bookings/{id}/complete")]
    public async Task<IActionResult> CompleteBooking(Guid id)
    {
        var profile = await GetBarberProfile();

        var booking = await _context.Bookings
            .FirstOrDefaultAsync(b => b.Id == id && b.BarberProfileId == profile.Id);

        if (booking == null)
            return NotFound(new { message = "ط§ظ„ط­ط¬ط² ط؛ظٹط± ظ…ظˆط¬ظˆط¯" });

        if (booking.Status != "PaymentPending")
            return BadRequest(new { message = "ظ„ط§ ظٹظ…ظƒظ† ط¥ظƒظ…ط§ظ„ ظ‡ط°ط§ ط§ظ„ط­ط¬ط²" });

        booking.Status = "Completed";
        booking.PaymentStatus = "Paid";
        booking.PaidAt = DateTime.UtcNow;
        if (booking.ServiceCompletedAt == null)
            booking.ServiceCompletedAt = DateTime.UtcNow;
        await _context.SaveChangesAsync();

        return Ok(new { message = "طھظ… ط¥ظƒظ…ط§ظ„ ط§ظ„ط­ط¬ط²" });
    }

    [HttpPut("bookings/{id}/no-show")]
    public async Task<IActionResult> NoShowBooking(Guid id)
    {
        var profile = await GetBarberProfile();

        var booking = await _context.Bookings
            .Include(b => b.Customer)
            .Include(b => b.BarberService)
            .FirstOrDefaultAsync(b => b.Id == id && b.BarberProfileId == profile.Id);

        if (booking == null)
            return NotFound(new { message = "ط§ظ„ط­ط¬ط² ط؛ظٹط± ظ…ظˆط¬ظˆط¯" });

        if (booking.Status != "Accepted")
            return BadRequest(new { message = "ظ„ط§ ظٹظ…ظƒظ† طھط­ط¯ظٹط¯ ظ‡ط°ط§ ط§ظ„ط­ط¬ط² ظƒظ€ظ„ظ… ظٹط­ط¶ط±" });

        booking.Status = "NoShow";
        booking.NoShowAt = DateTime.UtcNow;
        booking.NoShowBarberId = profile.Id;

        var customer = booking.Customer;
        customer.NoShowCount++;

        string notificationTitle;
        string notificationMessage;

        if (customer.NoShowCount >= 2)
        {
            customer.IsBookingBlocked = true;
            customer.BookingBlockedAt = DateTime.UtcNow;
            customer.BlockReason = $"ط¹ط¯ظ… ط§ظ„ط­ط¶ظˆط± ط§ظ„ظ…طھظƒط±ط± ({customer.NoShowCount} ظ…ط±ط§طھ)";

            notificationTitle = "طھظ… ط­ط¸ط±ظƒ ظ…ظ† ط§ظ„ط­ط¬ط²";
            notificationMessage = $"طھظ… ط­ط¸ط±ظƒ ظ…ظ† ط¥ظ†ط´ط§ط، ط­ط¬ظˆط²ط§طھ ط¬ط¯ظٹط¯ط© ط¨ط³ط¨ط¨ ط¹ط¯ظ… ط§ظ„ط­ط¶ظˆط± ط§ظ„ظ…طھظƒط±ط± ({customer.NoShowCount} ظ…ط±ط§طھ). طھظˆط§طµظ„ ظ…ط¹ ط§ظ„ط­ظ„ط§ظ‚ ط£ظˆ ط§ظ„ط¯ط¹ظ… ط§ظ„ظپظ†ظٹ ظ„ظپظƒ ط§ظ„ط­ط¸ط±.";
        }
        else
        {
            notificationTitle = "طھظ†ط¨ظٹظ‡: ط¹ط¯ظ… ط§ظ„ط­ط¶ظˆط±";
            notificationMessage = $"ظ„ظ… طھط­ط¶ط± ظ„ظ„ظ…ظˆط¹ط¯ â€” {booking.BarberService.Name} ظٹظˆظ… {booking.BookingDate:yyyy-MM-dd}. طھظ†ط¨ظٹظ‡: طھظƒط±ط§ط± ط¹ط¯ظ… ط§ظ„ط­ط¶ظˆط± ظ‚ط¯ ظٹط¤ط¯ظٹ ط¥ظ„ظ‰ ط¥ظٹظ‚ط§ظپ ط§ظ„ط­ط¬ط².";
        }

        await _context.SaveChangesAsync();

        _context.Notifications.Add(new Notification
        {
            UserId = booking.CustomerId,
            Title = notificationTitle,
            Message = notificationMessage,
            Type = "booking",
            IsRead = false,
            Data = booking.Id.ToString()
        });
        await _context.SaveChangesAsync();

        return Ok(new
        {
            message = "طھظ… طھط­ط¯ظٹط¯ ط§ظ„ط­ط¬ط² ظƒظ„ظ… ظٹط­ط¶ط±",
            noShowCount = customer.NoShowCount,
            isBlocked = customer.IsBookingBlocked
        });
    }

    [HttpGet("bookings/{id}")]
    public async Task<IActionResult> GetBookingDetail(Guid id)
    {
        var profile = await GetBarberProfile();

        var booking = await _context.Bookings
            .Include(b => b.Customer)
            .Include(b => b.BarberService)
            .Include(b => b.Employee)
            .FirstOrDefaultAsync(b => b.Id == id && b.BarberProfileId == profile.Id);

        if (booking == null)
            return NotFound(new { message = "ط§ظ„ط­ط¬ط² ط؛ظٹط± ظ…ظˆط¬ظˆط¯" });

        return Ok(new
        {
            id = booking.Id,
            customerName = booking.Customer.FullName,
            customerPhone = booking.Customer.PhoneNumber,
            serviceName = booking.BarberService.Name,
            serviceDuration = booking.BarberService.DurationInMinutes,
            servicePrice = booking.BarberService.Price,
            bookingDate = booking.BookingDate,
            bookingTime = booking.BookingTime.ToString(@"hh\:mm"),
            totalPrice = booking.TotalPrice,
            finalPrice = booking.FinalPrice,
            status = booking.Status,
            notes = booking.Notes,
            cancellationReason = booking.CancellationReason,
            paymentStatus = booking.PaymentStatus,
            paymentMethod = booking.PaymentMethod,
            promoCode = booking.PromoCode,
            discountAmount = booking.DiscountAmount,
            employeeId = booking.EmployeeId,
            employeeName = booking.Employee?.Name,
            createdAt = booking.CreatedAt
        });
    }

    [HttpPut("bookings/{id}/reschedule")]
    public async Task<IActionResult> RescheduleBooking(Guid id, [FromBody] BarberRescheduleDto dto)
    {
        var profile = await GetBarberProfile();

        var booking = await _context.Bookings
            .FirstOrDefaultAsync(b => b.Id == id && b.BarberProfileId == profile.Id);

        if (booking == null)
            return NotFound(new { message = "ط§ظ„ط­ط¬ط² ط؛ظٹط± ظ…ظˆط¬ظˆط¯" });

        if (booking.Status != "Upcoming")
            return BadRequest(new { message = "ظ„ط§ ظٹظ…ظƒظ† طھط¹ط¯ظٹظ„ ظ‡ط°ط§ ط§ظ„ط­ط¬ط²" });

        if (!TimeSpan.TryParse(dto.NewTime, out var newTime))
            return BadRequest(new { message = "طµظٹط؛ط© ط§ظ„ظˆظ‚طھ ط؛ظٹط± طµط­ظٹط­ط©" });

        var newDate = dto.NewDate.Kind == DateTimeKind.Utc
            ? dto.NewDate
            : DateTime.SpecifyKind(dto.NewDate, DateTimeKind.Utc);

        booking.BookingDate = newDate;
        booking.BookingTime = newTime;
        await _context.SaveChangesAsync();

        return Ok(new { message = "طھظ… طھط¹ط¯ظٹظ„ ط§ظ„ظ…ظˆط¹ط¯ ط¨ظ†ط¬ط§ط­" });
    }

    [HttpGet("customers/blocked")]
    public async Task<IActionResult> GetBlockedCustomers()
    {
        var profile = await GetBarberProfile();

        var blockedCustomerIds = await _context.Bookings
            .Where(b => b.NoShowBarberId == profile.Id && b.Status == "NoShow")
            .Select(b => b.CustomerId)
            .Distinct()
            .ToListAsync();

        var customers = await _context.Users
            .Where(u => blockedCustomerIds.Contains(u.Id) && u.IsBookingBlocked)
            .Select(u => new
            {
                id = u.Id,
                fullName = u.FullName,
                phoneNumber = u.PhoneNumber,
                noShowCount = u.NoShowCount,
                blockReason = u.BlockReason,
                bookingBlockedAt = u.BookingBlockedAt
            })
            .ToListAsync();

        return Ok(customers);
    }

    [HttpPut("customers/{id}/unblock")]
    public async Task<IActionResult> UnblockCustomer(Guid id)
    {
        var profile = await GetBarberProfile();

        var hasNoShow = await _context.Bookings.AnyAsync(b =>
            b.CustomerId == id &&
            b.NoShowBarberId == profile.Id &&
            b.Status == "NoShow");

        if (!hasNoShow)
            return Forbid("ظ„ط§ ظٹظ…ظƒظ†ظƒ ظپظƒ ط­ط¸ط± ط¹ظ…ظٹظ„ ظ„ظ… طھط­ط¯ط« ظ…ط¹ظ‡ ظ…ط´ظƒظ„ط©");

        var customer = await _context.Users.FindAsync(id);
        if (customer == null)
            return NotFound(new { message = "ط§ظ„ط¹ظ…ظٹظ„ ط؛ظٹط± ظ…ظˆط¬ظˆط¯" });

        if (!customer.IsBookingBlocked)
            return BadRequest(new { message = "ط§ظ„ط¹ظ…ظٹظ„ ط؛ظٹط± ظ…ط­ط¸ظˆط±" });

        customer.NoShowCount = 0;
        customer.IsBookingBlocked = false;
        customer.BookingBlockedAt = null;
        customer.BlockReason = null;

        _context.Notifications.Add(new Notification
        {
            UserId = customer.Id,
            Title = "طھظ… ظپظƒ ط­ط¸ط±ظƒ ظ…ظ† ط§ظ„ط­ط¬ط²",
            Message = $"ظ‚ط§ظ… ط§ظ„ط­ظ„ط§ظ‚ {profile.ShopName} ط¨ظپظƒ ط­ط¸ط±ظƒ. ظٹظ…ظƒظ†ظƒ ط§ظ„ط¢ظ† ط¥ظ†ط´ط§ط، ط­ط¬ظˆط²ط§طھ ط¬ط¯ظٹط¯ط©.",
            Type = "booking",
            IsRead = false
        });

        await _context.SaveChangesAsync();

        return Ok(new { message = "طھظ… ظپظƒ ط­ط¸ط± ط§ظ„ط¹ظ…ظٹظ„ ط¨ظ†ط¬ط§ط­" });
    }

    [HttpGet("services")]
    public async Task<IActionResult> GetServices()
    {
        var profile = await GetBarberProfile();

        var services = await _context.BarberServices
            .Where(s => s.BarberProfileId == profile.Id)
            .Select(s => new
            {
                id = s.Id,
                name = s.Name,
                price = s.Price,
                durationInMinutes = s.DurationInMinutes
            })
            .ToListAsync();

        return Ok(services);
    }

    [HttpPost("services")]
    public async Task<IActionResult> AddService([FromBody] CreateServiceDto dto)
    {
        var profile = await GetBarberProfile();

        var service = new BarberService
        {
            BarberProfileId = profile.Id,
            Name = dto.Name,
            Price = dto.Price,
            DurationInMinutes = dto.DurationInMinutes
        };

        _context.BarberServices.Add(service);
        await _context.SaveChangesAsync();

        return Ok(new
        {
            id = service.Id,
            name = service.Name,
            price = service.Price,
            durationInMinutes = service.DurationInMinutes
        });
    }

    [HttpPut("services/{id}")]
    public async Task<IActionResult> UpdateService(Guid id, [FromBody] CreateServiceDto dto)
    {
        var profile = await GetBarberProfile();

        var service = await _context.BarberServices
            .FirstOrDefaultAsync(s => s.Id == id && s.BarberProfileId == profile.Id);

        if (service == null)
            return NotFound(new { message = "ط§ظ„ط®ط¯ظ…ط© ط؛ظٹط± ظ…ظˆط¬ظˆط¯ط©" });

        service.Name = dto.Name;
        service.Price = dto.Price;
        service.DurationInMinutes = dto.DurationInMinutes;
        await _context.SaveChangesAsync();

        return Ok(new { message = "طھظ… طھط­ط¯ظٹط« ط§ظ„ط®ط¯ظ…ط© ط¨ظ†ط¬ط§ط­" });
    }

    [HttpDelete("services/{id}")]
    public async Task<IActionResult> DeleteService(Guid id)
    {
        var profile = await GetBarberProfile();

        var service = await _context.BarberServices
            .FirstOrDefaultAsync(s => s.Id == id && s.BarberProfileId == profile.Id);

        if (service == null)
            return NotFound(new { message = "ط§ظ„ط®ط¯ظ…ط© ط؛ظٹط± ظ…ظˆط¬ظˆط¯ط©" });

        _context.BarberServices.Remove(service);
        await _context.SaveChangesAsync();

        return Ok(new { message = "طھظ… ط­ط°ظپ ط§ظ„ط®ط¯ظ…ط© ط¨ظ†ط¬ط§ط­" });
    }

    [HttpGet("schedule")]
    public async Task<IActionResult> GetSchedule()
    {
        var profile = await GetBarberProfile();

        var schedule = await _context.WorkingHours
            .Where(wh => wh.BarberProfileId == profile.Id)
            .OrderBy(wh => wh.DayName)
            .Select(wh => new
            {
                dayName = wh.DayName,
                isOpen = wh.IsOpen,
                openTime = wh.OpenTime.ToString(@"hh\:mm"),
                closeTime = wh.CloseTime.ToString(@"hh\:mm")
            })
            .ToListAsync();

        return Ok(schedule);
    }

    [HttpPut("schedule")]
    public async Task<IActionResult> UpdateSchedule([FromBody] List<UpdateScheduleDto> dto)
    {
        var profile = await GetBarberProfile();

        var existingSchedule = await _context.WorkingHours
            .Where(wh => wh.BarberProfileId == profile.Id)
            .ToListAsync();

        foreach (var item in dto)
        {
            var existing = existingSchedule.FirstOrDefault(wh => wh.DayName == item.DayName);
            if (existing != null)
            {
                existing.IsOpen = item.IsOpen;
                if (TimeSpan.TryParse(item.OpenTime, out var openTime))
                    existing.OpenTime = openTime;
                if (TimeSpan.TryParse(item.CloseTime, out var closeTime))
                    existing.CloseTime = closeTime;
            }
        }

        await _context.SaveChangesAsync();
        return Ok(new { message = "طھظ… طھط­ط¯ظٹط« ط¬ط¯ظˆظ„ ط§ظ„ط¹ظ…ظ„ ط¨ظ†ط¬ط§ط­" });
    }

    [HttpGet("available-slots")]
    public async Task<IActionResult> GetAvailableSlots([FromQuery] DateTime date)
    {
        var profile = await GetBarberProfile();

        var dayNameArabic = date.DayOfWeek switch
        {
            DayOfWeek.Saturday => "ط§ظ„ط³ط¨طھ",
            DayOfWeek.Sunday => "ط§ظ„ط£ط­ط¯",
            DayOfWeek.Monday => "ط§ظ„ط§ط«ظ†ظٹظ†",
            DayOfWeek.Tuesday => "ط§ظ„ط«ظ„ط§ط«ط§ط،",
            DayOfWeek.Wednesday => "ط§ظ„ط£ط±ط¨ط¹ط§ط،",
            DayOfWeek.Thursday => "ط§ظ„ط®ظ…ظٹط³",
            DayOfWeek.Friday => "ط§ظ„ط¬ظ…ط¹ط©",
            _ => ""
        };

        var workingHour = await _context.WorkingHours
            .FirstOrDefaultAsync(wh => wh.BarberProfileId == profile.Id && wh.DayName == dayNameArabic && wh.IsOpen);

        if (workingHour == null)
            return Ok(new { slots = new object[0] });

        var dateUtc = date.Kind == DateTimeKind.Utc
            ? date
            : DateTime.SpecifyKind(date.Date, DateTimeKind.Utc);

        var bookedTimes = await _context.Bookings
            .Where(b => b.BarberProfileId == profile.Id
                && b.BookingDate >= dateUtc
                && b.BookingDate < dateUtc.AddDays(1)
                && b.Status == "Upcoming")
            .Select(b => b.BookingTime)
            .ToListAsync();

        var slots = new List<object>();
        var current = workingHour.OpenTime;
        while (current < workingHour.CloseTime)
        {
            var isBooked = bookedTimes.Any(bt => bt == current);
            slots.Add(new
            {
                time = current.ToString(@"hh\:mm"),
                period = current.TotalHours >= 12 ? "ظ…ط³ط§ط،ظ‹" : "طµط¨ط§ط­ط§ظ‹",
                isAvailable = !isBooked
            });
            current = current.Add(TimeSpan.FromMinutes(30));
        }

        return Ok(new { slots });
    }

    [HttpGet("profile")]
    public async Task<IActionResult> GetBarberProfileInfo()
    {
        var profile = await GetBarberProfile();
        var user = await _context.Users.FindAsync(profile.UserId);

        return Ok(new
        {
            shopName = profile.ShopName,
            shopDescription = profile.ShopDescription,
            shopLogoUrl = profile.ShopLogoUrl,
            coverImageUrl = profile.CoverImageUrl,
            city = profile.City,
            address = profile.Address,
            latitude = profile.Latitude,
            longitude = profile.Longitude,
            whatsappNumber = profile.WhatsAppNumber,
            instagramHandle = profile.InstagramHandle,
            tiktokHandle = profile.TikTokHandle,
            ownerName = user?.FullName ?? "",
            phoneNumber = user?.PhoneNumber ?? "",
            email = user?.Email,
            profileImageUrl = user?.ProfileImageUrl
        });
    }

    [HttpPut("profile")]
    [DisableRequestSizeLimit]
    public async Task<IActionResult> UpdateBarberProfile()
    {
        try
        {
            var profile = await GetBarberProfile();
            var user = await _context.Users.FindAsync(profile.UserId);
            if (user == null) return NotFound(new { message = "ط§ظ„ظ…ط³طھط®ط¯ظ… ط؛ظٹط± ظ…ظˆط¬ظˆط¯" });

            using var reader = new StreamReader(Request.Body);
            var body = await reader.ReadToEndAsync();

            if (string.IsNullOrEmpty(body))
                return BadRequest(new { message = "ط§ظ„ط¨ظٹط§ظ†ط§طھ ظ…ط·ظ„ظˆط¨ط©" });

            using var doc = System.Text.Json.JsonDocument.Parse(body);
            var root = doc.RootElement;

            if (root.TryGetProperty("shopName", out var shopNameProp))
                profile.ShopName = shopNameProp.GetString() ?? profile.ShopName;
            if (root.TryGetProperty("shopDescription", out var descProp))
                profile.ShopDescription = descProp.GetString();
            if (root.TryGetProperty("city", out var cityProp))
                profile.City = cityProp.GetString() ?? profile.City;
            if (root.TryGetProperty("address", out var addrProp))
                profile.Address = addrProp.GetString() ?? profile.Address;
            if (root.TryGetProperty("latitude", out var latProp) && latProp.TryGetDouble(out var lat))
                profile.Latitude = lat;
            if (root.TryGetProperty("longitude", out var lngProp) && lngProp.TryGetDouble(out var lng))
                profile.Longitude = lng;
            if (root.TryGetProperty("whatsappNumber", out var waProp))
                profile.WhatsAppNumber = waProp.GetString();
            if (root.TryGetProperty("instagramHandle", out var igProp))
                profile.InstagramHandle = igProp.GetString();
            if (root.TryGetProperty("tiktokHandle", out var ttProp))
                profile.TikTokHandle = ttProp.GetString();
            if (root.TryGetProperty("ownerName", out var nameProp))
                user.FullName = nameProp.GetString() ?? user.FullName;
            if (root.TryGetProperty("email", out var emailProp))
                user.Email = emailProp.GetString();
            if (root.TryGetProperty("shopLogoUrl", out var logoProp))
                profile.ShopLogoUrl = logoProp.GetString();
            if (root.TryGetProperty("coverImageUrl", out var coverProp))
                profile.CoverImageUrl = coverProp.GetString();
            if (root.TryGetProperty("profileImageUrl", out var pImgProp))
                user.ProfileImageUrl = pImgProp.GetString();

            profile.UpdatedAt = DateTime.UtcNow;
            user.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            return Ok(new { message = "طھظ… طھط­ط¯ظٹط« ط§ظ„ظ…ظ„ظپ ط§ظ„ط´ط®طµظٹ ط¨ظ†ط¬ط§ط­" });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = $"ط®ط·ط£: {ex.Message}" });
        }
    }

    [HttpPost("upload-image")]
    [DisableRequestSizeLimit]
    public async Task<IActionResult> UploadBarberImage()
    {
        try
        {
            var profile = await GetBarberProfile();
            var user = await _context.Users.FindAsync(profile.UserId);
            if (user == null) return NotFound(new { message = "ط§ظ„ظ…ط³طھط®ط¯ظ… ط؛ظٹط± ظ…ظˆط¬ظˆط¯" });

            using var reader = new StreamReader(Request.Body);
            var body = await reader.ReadToEndAsync();

            if (string.IsNullOrEmpty(body))
                return BadRequest(new { message = "ط§ظ„طµظˆط±ط© ظ…ط·ظ„ظˆط¨ط©" });

            using var doc = System.Text.Json.JsonDocument.Parse(body);
            var root = doc.RootElement;

            string? imageBase64 = null;
            string? imageType = null;

            if (root.TryGetProperty("imageBase64", out var imgProp))
                imageBase64 = imgProp.GetString();
            if (root.TryGetProperty("imageType", out var typeProp))
                imageType = typeProp.GetString();

            if (string.IsNullOrEmpty(imageBase64))
                return BadRequest(new { message = "ط§ظ„طµظˆط±ط© ظ…ط·ظ„ظˆط¨ط©" });

            var folder = imageType switch
            {
                "cover" => "covers",
                "shopLogo" => "logos",
                _ => "profiles"
            };

            var imageUrl = await _fileStorage.SaveImageAsync(imageBase64, folder);

            switch (imageType)
            {
                case "cover":
                    if (!string.IsNullOrEmpty(profile.CoverImageUrl))
                        await _fileStorage.DeleteImageAsync(profile.CoverImageUrl);
                    profile.CoverImageUrl = imageUrl;
                    break;
                case "shopLogo":
                    if (!string.IsNullOrEmpty(profile.ShopLogoUrl))
                        await _fileStorage.DeleteImageAsync(profile.ShopLogoUrl);
                    profile.ShopLogoUrl = imageUrl;
                    break;
                case "profile":
                default:
                    if (!string.IsNullOrEmpty(user.ProfileImageUrl))
                        await _fileStorage.DeleteImageAsync(user.ProfileImageUrl);
                    user.ProfileImageUrl = imageUrl;
                    break;
            }

            profile.UpdatedAt = DateTime.UtcNow;
            user.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            return Ok(new
            {
                message = "طھظ… ط±ظپط¹ ط§ظ„طµظˆط±ط© ط¨ظ†ط¬ط§ط­",
                profileImageUrl = user.ProfileImageUrl,
                shopLogoUrl = profile.ShopLogoUrl,
                coverImageUrl = profile.CoverImageUrl
            });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = $"ط®ط·ط£: {ex.Message}" });
        }
    }

    [HttpGet("reviews")]
    public async Task<IActionResult> GetBarberReviews()
    {
        var profile = await GetBarberProfile();

        var reviews = await _context.Reviews
            .Where(r => r.BarberProfileId == profile.Id)
            .Include(r => r.Customer)
            .OrderByDescending(r => r.CreatedAt)
            .Select(r => new
            {
                id = r.Id,
                customerName = r.Customer.FullName,
                rating = r.Rating,
                comment = r.Comment,
                createdAt = r.CreatedAt
            })
            .ToListAsync();

        var avgRating = reviews.Any() ? Math.Round(reviews.Average(r => r.rating), 1) : 0.0;

        return Ok(new
        {
            averageRating = avgRating,
                reviewCount = reviews.Count,
                reviews = reviews
            });
    }

    // ==================== EMPLOYEE ENDPOINTS ====================

    [HttpGet("employees")]
    public async Task<IActionResult> GetEmployees()
    {
        var profile = await GetBarberProfile();

        var employees = await _context.BarberEmployees
            .Where(e => e.BarberProfileId == profile.Id)
            .OrderBy(e => e.Name)
            .Select(e => new EmployeeDto
            {
                Id = e.Id,
                Name = e.Name,
                PhoneNumber = e.PhoneNumber,
                ProfileImageUrl = e.ProfileImageUrl,
                IsActive = e.IsActive,
                CreatedAt = e.CreatedAt
            })
            .ToListAsync();

        return Ok(employees);
    }

    [HttpGet("employees/{id}")]
    public async Task<IActionResult> GetEmployee(Guid id)
    {
        var profile = await GetBarberProfile();

        var employee = await _context.BarberEmployees
            .Where(e => e.Id == id && e.BarberProfileId == profile.Id)
            .Select(e => new EmployeeDto
            {
                Id = e.Id,
                Name = e.Name,
                PhoneNumber = e.PhoneNumber,
                ProfileImageUrl = e.ProfileImageUrl,
                IsActive = e.IsActive,
                CreatedAt = e.CreatedAt
            })
            .FirstOrDefaultAsync();

        if (employee == null)
            return NotFound(new { message = "ط§ظ„ظ…ظˆط¸ظپ ط؛ظٹط± ظ…ظˆط¬ظˆط¯" });

        return Ok(employee);
    }

    [HttpPost("employees")]
    public async Task<IActionResult> CreateEmployee([FromBody] CreateEmployeeRequestDto dto)
    {
        var profile = await GetBarberProfile();

        var subscriptionService = HttpContext.RequestServices.GetRequiredService<ISubscriptionService>();
        var canAdd = await subscriptionService.CanAddEmployeeAsync(profile.Id);
        if (!canAdd)
            return BadRequest(new { message = "ط®ط·طھظƒ ط§ظ„ط­ط§ظ„ظٹط© ظ„ط§ طھط³ظ…ط­ ط¨ط¥ط¶ط§ظپط© ظ…ظˆط¸ظپظٹظ†. ظ‚ظ… ط¨ط§ظ„طھط±ظ‚ظٹط© ظ„ط®ط·ط© ط£ط¹ظ„ظ‰." });

        var employee = new BarberEmployee
        {
            BarberProfileId = profile.Id,
            Name = dto.Name,
            PhoneNumber = dto.PhoneNumber,
            ProfileImageUrl = dto.ProfileImageUrl,
            IsActive = true
        };

        _context.BarberEmployees.Add(employee);
        await _context.SaveChangesAsync();

        // Auto-create schedule from shop's working hours
        var shopHours = await _context.WorkingHours
            .Where(wh => wh.BarberProfileId == profile.Id)
            .ToListAsync();

        var defaultDays = new[] { "ط§ظ„ط³ط¨طھ", "ط§ظ„ط£ط­ط¯", "ط§ظ„ط§ط«ظ†ظٹظ†", "ط§ظ„ط«ظ„ط§ط«ط§ط،", "ط§ظ„ط£ط±ط¨ط¹ط§ط،", "ط§ظ„ط®ظ…ظٹط³", "ط§ظ„ط¬ظ…ط¹ط©" };
        foreach (var day in defaultDays)
        {
            var shopDay = shopHours.FirstOrDefault(wh => wh.DayName == day);
            _context.EmployeeSchedules.Add(new EmployeeSchedule
            {
                EmployeeId = employee.Id,
                DayName = day,
                IsOpen = shopDay?.IsOpen ?? false,
                OpenTime = shopDay?.OpenTime ?? TimeSpan.FromHours(9),
                CloseTime = shopDay?.CloseTime ?? TimeSpan.FromHours(17),
            });
        }
        await _context.SaveChangesAsync();

        return Ok(new EmployeeDto
        {
            Id = employee.Id,
            Name = employee.Name,
            PhoneNumber = employee.PhoneNumber,
            ProfileImageUrl = employee.ProfileImageUrl,
            IsActive = employee.IsActive,
            CreatedAt = employee.CreatedAt
        });
    }

    [HttpPut("employees/{id}")]
    public async Task<IActionResult> UpdateEmployee(Guid id, [FromBody] UpdateEmployeeRequestDto dto)
    {
        var profile = await GetBarberProfile();

        var employee = await _context.BarberEmployees
            .FirstOrDefaultAsync(e => e.Id == id && e.BarberProfileId == profile.Id);

        if (employee == null)
            return NotFound(new { message = "ط§ظ„ظ…ظˆط¸ظپ ط؛ظٹط± ظ…ظˆط¬ظˆط¯" });

        if (dto.Name != null) employee.Name = dto.Name;
        if (dto.PhoneNumber != null) employee.PhoneNumber = dto.PhoneNumber;
        if (dto.ProfileImageUrl != null) employee.ProfileImageUrl = dto.ProfileImageUrl;
        if (dto.IsActive.HasValue) employee.IsActive = dto.IsActive.Value;

        await _context.SaveChangesAsync();

        return Ok(new { message = "طھظ… طھط­ط¯ظٹط« ط¨ظٹط§ظ†ط§طھ ط§ظ„ظ…ظˆط¸ظپ ط¨ظ†ط¬ط§ط­" });
    }

    [HttpPut("employees/{id}/toggle")]
    public async Task<IActionResult> ToggleEmployee(Guid id)
    {
        var profile = await GetBarberProfile();

        var employee = await _context.BarberEmployees
            .FirstOrDefaultAsync(e => e.Id == id && e.BarberProfileId == profile.Id);

        if (employee == null)
            return NotFound(new { message = "ط§ظ„ظ…ظˆط¸ظپ ط؛ظٹط± ظ…ظˆط¬ظˆط¯" });

        employee.IsActive = !employee.IsActive;
        await _context.SaveChangesAsync();

        return Ok(new
        {
            id = employee.Id,
            isActive = employee.IsActive,
            message = employee.IsActive ? "طھظ… طھظپط¹ظٹظ„ ط§ظ„ظ…ظˆط¸ظپ" : "طھظ… طھط¹ط·ظٹظ„ ط§ظ„ظ…ظˆط¸ظپ"
        });
    }

    [HttpDelete("employees/{id}")]
    public async Task<IActionResult> DeleteEmployee(Guid id)
    {
        var profile = await GetBarberProfile();

        var employee = await _context.BarberEmployees
            .FirstOrDefaultAsync(e => e.Id == id && e.BarberProfileId == profile.Id);

        if (employee == null)
            return NotFound(new { message = "ط§ظ„ظ…ظˆط¸ظپ ط؛ظٹط± ظ…ظˆط¬ظˆط¯" });

        _context.BarberEmployees.Remove(employee);
        await _context.SaveChangesAsync();

        return Ok(new { message = "طھظ… ط­ط°ظپ ط§ظ„ظ…ظˆط¸ظپ ط¨ظ†ط¬ط§ط­" });
    }

    [HttpGet("employees/{id}/schedule")]
    public async Task<IActionResult> GetEmployeeSchedule(Guid id)
    {
        var profile = await GetBarberProfile();

        var employee = await _context.BarberEmployees
            .FirstOrDefaultAsync(e => e.Id == id && e.BarberProfileId == profile.Id);

        if (employee == null)
            return NotFound(new { message = "ط§ظ„ظ…ظˆط¸ظپ ط؛ظٹط± ظ…ظˆط¬ظˆط¯" });

        var schedules = await _context.EmployeeSchedules
            .Where(s => s.EmployeeId == id)
            .OrderBy(s => s.DayName)
            .Select(s => new
            {
                id = s.Id,
                dayName = s.DayName,
                isOpen = s.IsOpen,
                openTime = s.OpenTime.ToString(@"hh\:mm"),
                closeTime = s.CloseTime.ToString(@"hh\:mm"),
            })
            .ToListAsync();

        return Ok(new { employeeId = id, employeeName = employee.Name, schedules });
    }

    [HttpPut("employees/{id}/schedule")]
    public async Task<IActionResult> UpdateEmployeeSchedule(Guid id, [FromBody] UpdateEmployeeScheduleDto dto)
    {
        var profile = await GetBarberProfile();

        var employee = await _context.BarberEmployees
            .FirstOrDefaultAsync(e => e.Id == id && e.BarberProfileId == profile.Id);

        if (employee == null)
            return NotFound(new { message = "ط§ظ„ظ…ظˆط¸ظپ ط؛ظٹط± ظ…ظˆط¬ظˆط¯" });

        foreach (var day in dto.Days)
        {
            var existing = await _context.EmployeeSchedules
                .FirstOrDefaultAsync(s => s.EmployeeId == id && s.DayName == day.DayName);

            if (existing != null)
            {
                existing.IsOpen = day.IsOpen;
                existing.OpenTime = TimeSpan.Parse(day.OpenTime);
                existing.CloseTime = TimeSpan.Parse(day.CloseTime);
            }
            else
            {
                _context.EmployeeSchedules.Add(new EmployeeSchedule
                {
                    EmployeeId = id,
                    DayName = day.DayName,
                    IsOpen = day.IsOpen,
                    OpenTime = TimeSpan.Parse(day.OpenTime),
                    CloseTime = TimeSpan.Parse(day.CloseTime),
                });
            }
        }

        await _context.SaveChangesAsync();

        return Ok(new { message = "طھظ… طھط­ط¯ظٹط« ط¬ط¯ظˆظ„ ط§ظ„ط¯ظˆط§ظ… ط¨ظ†ط¬ط§ط­" });
    }

    [HttpGet("employees/{id}/services")]
    public async Task<IActionResult> GetEmployeeServices(Guid id)
    {
        var profile = await GetBarberProfile();

        var employee = await _context.BarberEmployees
            .FirstOrDefaultAsync(e => e.Id == id && e.BarberProfileId == profile.Id);

        if (employee == null)
            return NotFound(new { message = "ط§ظ„ظ…ظˆط¸ظپ ط؛ظٹط± ظ…ظˆط¬ظˆط¯" });

        var allServices = await _context.BarberServices
            .Where(s => s.BarberProfileId == profile.Id)
            .Select(s => new { s.Id, s.Name, s.Price, s.DurationInMinutes })
            .ToListAsync();

        var assignedIds = await _context.EmployeeServices
            .Where(es => es.EmployeeId == id)
            .Select(es => es.BarberServiceId)
            .ToListAsync();

        var assignedSet = assignedIds.ToHashSet();

        var services = allServices.Select(s => new EmployeeServiceItemDto
        {
            ServiceId = s.Id,
            ServiceName = s.Name,
            Price = s.Price,
            DurationMinutes = s.DurationInMinutes,
            IsAssigned = assignedSet.Contains(s.Id)
        }).ToList();

        return Ok(new EmployeeServicesDto
        {
            EmployeeId = id,
            EmployeeName = employee.Name,
            AllServices = services
        });
    }

    [HttpPut("employees/{id}/services")]
    public async Task<IActionResult> UpdateEmployeeServices(Guid id, [FromBody] UpdateEmployeeServicesDto dto)
    {
        var profile = await GetBarberProfile();

        var employee = await _context.BarberEmployees
            .FirstOrDefaultAsync(e => e.Id == id && e.BarberProfileId == profile.Id);

        if (employee == null)
            return NotFound(new { message = "ط§ظ„ظ…ظˆط¸ظپ ط؛ظٹط± ظ…ظˆط¬ظˆط¯" });

        var existing = await _context.EmployeeServices
            .Where(es => es.EmployeeId == id)
            .ToListAsync();

        _context.EmployeeServices.RemoveRange(existing);

        foreach (var serviceId in dto.ServiceIds)
        {
            _context.EmployeeServices.Add(new EmployeeService
            {
                EmployeeId = id,
                BarberServiceId = serviceId
            });
        }

        await _context.SaveChangesAsync();

        return Ok(new { message = "طھظ… طھط­ط¯ظٹط« ط®ط¯ظ…ط§طھ ط§ظ„ظ…ظˆط¸ظپ ط¨ظ†ط¬ط§ط­" });
    }

    // ==================== ANALYTICS ENDPOINTS ====================

    [HttpGet("analytics")]
    public async Task<IActionResult> GetAnalytics([FromQuery] string? period)
    {
        var profile = await GetBarberProfile();

        var subscriptionService = HttpContext.RequestServices.GetRequiredService<ISubscriptionService>();
        var canUse = await subscriptionService.CanUseAnalyticsAsync(profile.Id);
        if (!canUse)
            return BadRequest(new { message = "ظٹط¬ط¨ ط§ظ„ط§ط´طھط±ط§ظƒ ظپظٹ ط®ط·ط© ط§ظ„ط§ط­طھط±ط§ظپظٹط© ط£ظˆ ط§ظ„ظ…ظ…ظٹط²ط© ظ„ط¹ط±ط¶ ط§ظ„طھط­ظ„ظٹظ„ط§طھ" });

        var currentSubscription = await subscriptionService.GetCurrentSubscriptionAsync(profile.Id);
        var isAdvanced = currentSubscription?.AnalyticsLevel == "advanced";

        var allBookings = await _context.Bookings
            .Where(b => b.BarberProfileId == profile.Id)
            .ToListAsync();

        var completedBookings = allBookings.Where(b => b.Status == "Completed").ToList();
        var totalRevenue = completedBookings.Sum(b => (decimal)b.TotalPrice);

        var services = await _context.BarberServices
            .Where(s => s.BarberProfileId == profile.Id)
            .ToListAsync();

        var reviews = await _context.Reviews
            .Where(r => r.BarberProfileId == profile.Id)
            .ToListAsync();
        var averageRating = reviews.Any() ? Math.Round(reviews.Average(r => r.Rating), 1) : 0.0;

        var uniqueCustomerIds = allBookings.Select(b => b.CustomerId).Distinct().ToList();
        var totalCustomers = uniqueCustomerIds.Count;

        // Bookings by day (Saturday=0 to Friday=6)
        var bookingsByDay = new int[7];
        foreach (var b in completedBookings)
        {
            var localDate = b.BookingDate.Date;
            var dayIndex = ((int)localDate.DayOfWeek + 1) % 7;
            bookingsByDay[dayIndex]++;
        }

        // Top services
        var topServices = services.Select(s => new
        {
            name = s.Name,
            count = completedBookings.Count(b => b.BarberServiceId == s.Id)
        }).OrderByDescending(s => s.count).Take(5).ToList();

        var result = new
        {
            analyticsLevel = currentSubscription?.AnalyticsLevel ?? "none",
            totalBookings = allBookings.Count,
            totalRevenue = totalRevenue,
            averageRating = averageRating,
            totalCustomers = totalCustomers,
            bookingsByDay = bookingsByDay,
            topServices = topServices
        };

        if (isAdvanced)
        {
            var peakHours = completedBookings
                .GroupBy(b => b.BookingTime.Hours)
                .Select(g => new { hour = g.Key, count = g.Count() })
                .OrderByDescending(x => x.count)
                .Take(5)
                .ToList();

            var customerBookingCounts = allBookings
                .GroupBy(b => b.CustomerId)
                .ToDictionary(g => g.Key, g => g.Count());

            var newCustomers = allBookings
                .Where(b => (DateTime.UtcNow - b.CreatedAt).TotalDays <= 30)
                .Select(b => b.CustomerId).Distinct().Count();

            var returningCustomers = customerBookingCounts.Count(kv => kv.Value > 1);
            var returnRate = totalCustomers > 0
                ? Math.Round((double)returningCustomers / totalCustomers * 100, 1)
                : 0.0;

            var retentionRate = returnRate;

            var servicePerformance = services.Select(s => new
            {
                name = s.Name,
                bookings = completedBookings.Count(b => b.BarberServiceId == s.Id),
                revenue = completedBookings.Where(b => b.BarberServiceId == s.Id).Sum(b => (decimal)b.TotalPrice)
            }).OrderByDescending(s => s.bookings).ToList();

            var advancedResult = new
            {
                analyticsLevel = "advanced",
                totalBookings = result.totalBookings,
                totalRevenue = result.totalRevenue,
                averageRating = result.averageRating,
                totalCustomers = result.totalCustomers,
                bookingsByDay = result.bookingsByDay,
                topServices = result.topServices,
                peakHours = peakHours,
                newCustomers = newCustomers,
                returningCustomers = returningCustomers,
                returnRate = returnRate,
                servicePerformance = servicePerformance,
                retentionRate = retentionRate
            };

            return Ok(advancedResult);
        }

        return Ok(result);
    }
}

