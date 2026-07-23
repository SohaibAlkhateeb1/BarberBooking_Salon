using System.Security.Claims;
using BarberBooking.Application.DTOs.Booking;
using BarberBooking.Domain.Entities;
using BarberBooking.Infrastructure.Data;
using BarberBooking.API.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace BarberBooking.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class BookingsController : ControllerBase
{
    private readonly BarberBookingDbContext _context;
    private readonly IFirebasePushService _fcm;

    public BookingsController(BarberBookingDbContext context, IFirebasePushService fcm)
    {
        _context = context;
        _fcm = fcm;
    }

    private Guid GetCurrentUserId()
    {
        var sub = User.FindFirst(ClaimTypes.NameIdentifier)?.Value
                  ?? User.FindFirst("sub")?.Value;
        if (string.IsNullOrEmpty(sub))
            throw new UnauthorizedAccessException("غير مصرح");
        return Guid.Parse(sub);
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateBookingDto dto)
    {
        var userId = GetCurrentUserId();

        // === Customer Behavior Checks ===

        // Check 1: Is customer blocked?
        var currentUser = await _context.Users.FindAsync(userId);
        if (currentUser != null && currentUser.IsBookingBlocked)
        {
            return StatusCode(403, new { message = $"تم حظرك من الحجز مؤقتاً. السبب: {currentUser.BlockReason ?? "عدم الحضور المتكرر"}" });
        }

        // Check 2: Does customer have an active booking?
        var hasActiveBooking = await _context.Bookings.AnyAsync(b =>
            b.CustomerId == userId &&
            (b.Status == "Pending" || b.Status == "Accepted" ||
             b.Status == "InProgress" || b.Status == "PaymentPending"));

        if (hasActiveBooking)
        {
            return BadRequest(new { message = "لديك حجز نشط حالياً. أكمله أو ألغيه قبل إنشاء حجز جديد" });
        }

        // === End Behavior Checks ===

        var barberProfile = await _context.BarberProfiles
            .Include(bp => bp.User)
            .FirstOrDefaultAsync(bp => bp.Id == dto.BarberProfileId);

        if (barberProfile == null)
            return NotFound(new { message = "الحلاق غير موجود" });

        var serviceIds = dto.ServiceIds?.Any() == true
            ? dto.ServiceIds
            : new List<Guid> { dto.BarberServiceId };

        var barberServices = await _context.BarberServices
            .Where(bs => serviceIds.Contains(bs.Id) && bs.BarberProfileId == dto.BarberProfileId)
            .ToListAsync();

        if (!barberServices.Any())
            return NotFound(new { message = "الخدمات غير موجودة" });

        if (!TimeSpan.TryParse(dto.BookingTime, out var bookingTime))
            return BadRequest(new { message = "صيغة الوقت غير صحيحة" });

        var bookingDate = dto.BookingDate.Kind == DateTimeKind.Utc
            ? dto.BookingDate
            : DateTime.SpecifyKind(dto.BookingDate, DateTimeKind.Utc);

        var totalPrice = barberServices.Sum(s => s.Price);
        var serviceNames = string.Join(" + ", barberServices.Select(s => s.Name));

        var booking = new Booking
        {
            CustomerId = userId,
            BarberProfileId = dto.BarberProfileId,
            BarberServiceId = barberServices.First().Id,
            EmployeeId = dto.EmployeeId,
            BookingDate = bookingDate,
            BookingTime = bookingTime,
            TotalPrice = totalPrice,
            FinalPrice = totalPrice,
            Status = "Pending",
            PaymentStatus = "Unpaid",
            PaymentMethod = "cash",
            Notes = dto.Notes,
            PromoCode = dto.PromoCode
        };

        _context.Bookings.Add(booking);
        await _context.SaveChangesAsync();

        var customer = await _context.Users.FindAsync(userId);

        _context.Notifications.Add(new Notification
        {
            UserId = barberProfile.UserId,
            Title = "طلب حجز جديد",
            Message = $"طلب موعد جديد من {customer?.FullName ?? "زبون"} — {serviceNames} يوم {bookingDate:yyyy-MM-dd} الساعة {bookingTime:hh\\:mm}",
            Type = "booking",
            IsRead = false,
            Data = booking.Id.ToString()
        });

        _context.Notifications.Add(new Notification
        {
            UserId = userId,
            Title = "تم إرسال طلب الحجز",
            Message = $"تم إرسال طلب حجز {serviceNames} مع {barberProfile.User.FullName} — بانتظار موافقة الحلاق",
            Type = "booking",
            IsRead = false,
            Data = booking.Id.ToString()
        });

        await _context.SaveChangesAsync();

        // Send FCM push notification to barber
        await _fcm.SendToBarber(
            barberProfile.UserId,
            "طلب حجز جديد 🔔",
            $"طلب موعد جديد من {customer?.FullName ?? "زبون"} — {serviceNames} يوم {bookingDate:yyyy-MM-dd} الساعة {bookingTime:hh\\:mm}",
            new Dictionary<string, string>
            {
                { "type", "booking_update" },
                { "bookingId", booking.Id.ToString() },
                { "action", "new_booking" }
            });

        // Send confirmation FCM to customer
        await _fcm.SendToUser(
            userId,
            "تم إرسال طلب الحجز ✅",
            $"تم إرسال طلب حجز {serviceNames} مع {barberProfile.User.FullName} — بانتظار موافقة الحلاق",
            new Dictionary<string, string>
            {
                { "type", "booking_update" },
                { "bookingId", booking.Id.ToString() },
                { "action", "booking_sent" }
            });

        return CreatedAtAction(nameof(GetById), new { id = booking.Id }, new
        {
            id = booking.Id,
            barberName = barberProfile.User.FullName,
            shopName = barberProfile.ShopName,
            serviceName = serviceNames,
            bookingDate = booking.BookingDate,
            bookingTime = booking.BookingTime.ToString(@"hh\:mm"),
            totalPrice = booking.TotalPrice,
            finalPrice = booking.FinalPrice,
            status = booking.Status,
            paymentStatus = booking.PaymentStatus
        });
    }

    [HttpGet("my")]
    public async Task<IActionResult> GetMyBookings([FromQuery] string? status)
    {
        var userId = GetCurrentUserId();

        var query = _context.Bookings
            .Include(b => b.BarberProfile)
                .ThenInclude(bp => bp.User)
            .Include(b => b.BarberService)
            .Include(b => b.Customer)
            .Include(b => b.Employee)
            .Where(b => b.CustomerId == userId)
            .AsQueryable();

        if (!string.IsNullOrEmpty(status))
            query = query.Where(b => b.Status == status);

        var bookings = await query.OrderByDescending(b => b.BookingDate).Select(b => new
        {
            id = b.Id,
            barberName = b.BarberProfile.User.FullName,
            shopName = b.BarberProfile.ShopName,
            shopLogoUrl = b.BarberProfile.ShopLogoUrl,
            serviceName = b.BarberService.Name,
            servicePrice = b.BarberService.Price,
            serviceDuration = b.BarberService.DurationInMinutes,
            bookingDate = b.BookingDate,
            bookingTime = b.BookingTime.ToString(@"hh\:mm"),
            totalPrice = b.TotalPrice,
            finalPrice = b.FinalPrice,
            status = b.Status,
            cancellationReason = b.CancellationReason,
            address = b.BarberProfile.Address,
            employeeName = b.Employee != null ? b.Employee.Name : null,
            averageRating = b.BarberProfile.Reviews.Any() ? b.BarberProfile.Reviews.Average(r => r.Rating) : 0.0,
            reviewCount = b.BarberProfile.Reviews.Count
        }).ToListAsync();

        return Ok(bookings);
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetById(Guid id)
    {
        var userId = GetCurrentUserId();

        var booking = await _context.Bookings
            .Include(b => b.BarberProfile)
                .ThenInclude(bp => bp.User)
            .Include(b => b.BarberService)
            .Include(b => b.Customer)
            .Include(b => b.Employee)
            .FirstOrDefaultAsync(b => b.Id == id && b.CustomerId == userId);

        if (booking == null)
            return NotFound(new { message = "الحجز غير موجود" });

        var hasReview = await _context.Reviews
            .AnyAsync(r => r.BarberProfileId == booking.BarberProfileId && r.CustomerId == userId);

        return Ok(new
        {
            id = booking.Id,
            bookingCode = $"BKG-{booking.Id.ToString()[..4].ToUpper()}",
            barberProfileId = booking.BarberProfileId,
            barberName = booking.BarberProfile.User.FullName,
            shopName = booking.BarberProfile.ShopName,
            shopAddress = booking.BarberProfile.Address,
            shopCity = booking.BarberProfile.City,
            serviceName = booking.BarberService.Name,
            servicePrice = booking.BarberService.Price,
            serviceDuration = booking.BarberService.DurationInMinutes,
            bookingDate = booking.BookingDate,
            bookingTime = booking.BookingTime.ToString(@"hh\:mm"),
            totalPrice = booking.TotalPrice,
            finalPrice = booking.FinalPrice,
            status = booking.Status,
            cancellationReason = booking.CancellationReason,
            notes = booking.Notes,
            paymentStatus = booking.PaymentStatus,
            employeeName = booking.Employee?.Name,
            createdAt = booking.CreatedAt,
            hasReview = hasReview
        });
    }

    [HttpPut("{id}/reschedule")]
    public async Task<IActionResult> Reschedule(Guid id, [FromBody] RescheduleDto dto)
    {
        if (dto == null)
            return BadRequest(new { message = "بيانات غير صحيحة" });

        var userId = GetCurrentUserId();

        var booking = await _context.Bookings
            .FirstOrDefaultAsync(b => b.Id == id && b.CustomerId == userId);

        if (booking == null)
            return NotFound(new { message = "الحجز غير موجود" });

        if (booking.Status != "Pending" && booking.Status != "Accepted")
            return BadRequest(new { message = "لا يمكن إعادة جدولة هذا الحجز" });

        if (booking.RescheduleCount >= 1)
            return BadRequest(new { message = "لقد استخدمت إعادة الجدولة بالفعل لهذا الحجز" });

        if (!TimeSpan.TryParse(dto.NewTime, out var newTime))
            return BadRequest(new { message = "صيغة الوقت غير صحيحة" });

        booking.BookingDate = DateTime.SpecifyKind(dto.NewDate.Date, DateTimeKind.Utc);
        booking.BookingTime = newTime;
        booking.RescheduleCount++;
        await _context.SaveChangesAsync();

        return Ok(new { message = "تم إعادة جدولة الحجز بنجاح" });
    }

    [HttpPut("{id}/cancel")]
    public async Task<IActionResult> Cancel(Guid id, [FromBody] CancelDto dto)
    {
        var userId = GetCurrentUserId();

        var booking = await _context.Bookings
            .Include(b => b.BarberProfile).ThenInclude(bp => bp.User)
            .Include(b => b.BarberService)
            .FirstOrDefaultAsync(b => b.Id == id && b.CustomerId == userId);

        if (booking == null)
            return NotFound(new { message = "الحجز غير موجود" });

        if (booking.Status == "InProgress" || booking.Status == "PaymentPending" || booking.Status == "Completed")
            return BadRequest(new { message = "لا يمكن إلغاء الحجز بعد بدء الخدمة" });

        if (booking.Status == "Cancelled" || booking.Status == "Rejected" || booking.Status == "Completed" || booking.Status == "NoShow" || booking.Status == "Expired")
            return BadRequest(new { message = "لا يمكن إلغاء هذا الحجز" });

        // === Daily cancellation limit check ===
        var user = await _context.Users.FindAsync(userId);
        if (user != null)
        {
            var today = DateTime.UtcNow.Date;

            // Reset counter if it's a new day
            if (user.LastCancelDate == null || user.LastCancelDate.Value.Date < today)
            {
                user.DailyCancelCount = 0;
                user.LastCancelDate = today;
            }

            if (user.DailyCancelCount >= 2)
            {
                return BadRequest(new { message = "لقد تجاوزت الحد المسموح لإلغاء الحجوزات اليوم. يرجى التواصل مع الحلاق" });
            }

            user.DailyCancelCount++;
            user.LastCancelDate = DateTime.UtcNow;
            await _context.SaveChangesAsync();
        }

        booking.Status = "Cancelled";
        booking.CancellationReason = dto.Reason;
        await _context.SaveChangesAsync();

        var customer = await _context.Users.FindAsync(userId);
        var serviceName = booking.BarberService?.Name ?? "خدمة";

        _context.Notifications.Add(new Notification
        {
            UserId = booking.BarberProfile.UserId,
            Title = "تم إلغاء الحجز",
            Message = $"قام {customer?.FullName ?? "زبون"} بإلغاء حجز {serviceName} يوم {booking.BookingDate:yyyy-MM-dd} الساعة {booking.BookingTime:hh\\:mm}{(dto.Reason != null ? $" - السبب: {dto.Reason}" : "")}",
            Type = "cancellation",
            IsRead = false,
            Data = booking.Id.ToString()
        });

        _context.Notifications.Add(new Notification
        {
            UserId = userId,
            Title = "تم إلغاء الحجز",
            Message = $"تم إلغاء حجز {serviceName} مع {booking.BarberProfile.User.FullName}",
            Type = "cancellation",
            IsRead = false,
            Data = booking.Id.ToString()
        });

        await _context.SaveChangesAsync();

        // Send FCM push notification to barber about cancellation
        await _fcm.SendToBarber(
            booking.BarberProfile.UserId,
            "تم إلغاء حجز ❌",
            $"قام {customer?.FullName ?? "زبون"} بإلغاء حجز {serviceName} يوم {booking.BookingDate:yyyy-MM-dd} الساعة {booking.BookingTime:hh\\:mm}",
            new Dictionary<string, string>
            {
                { "type", "booking_update" },
                { "bookingId", booking.Id.ToString() },
                { "action", "booking_cancelled" }
            });

        return Ok(new { message = "تم إلغاء الحجز بنجاح" });
    }

    [HttpPost("{id}/review")]
    public async Task<IActionResult> AddReview(Guid id, [FromBody] AddReviewDto dto)
    {
        var userId = GetCurrentUserId();

        var booking = await _context.Bookings
            .Include(b => b.BarberProfile)
            .FirstOrDefaultAsync(b => b.Id == id && b.CustomerId == userId);

        if (booking == null)
            return NotFound(new { message = "الحجز غير موجود" });

        if (booking.Status != "Completed")
            return BadRequest(new { message = "يمكنك تقييم الحجوزات المكتملة فقط" });

        var existingReview = await _context.Reviews
            .FirstOrDefaultAsync(r => r.BarberProfileId == booking.BarberProfileId && r.CustomerId == userId);

        if (existingReview != null)
            return BadRequest(new { message = "لقد قمت بتقييم هذا الحلاق بالفعل" });

        var review = new Review
        {
            CustomerId = userId,
            BarberProfileId = booking.BarberProfileId,
            Rating = dto.Rating,
            Comment = dto.Comment
        };

        _context.Reviews.Add(review);
        await _context.SaveChangesAsync();

        return Ok(new { message = "تم إضافة التقييم بنجاح" });
    }

    [HttpGet("available-slots")]
    public async Task<IActionResult> GetAvailableSlots(
        [FromQuery] Guid barberProfileId,
        [FromQuery] DateTime date,
        [FromQuery] Guid? employeeId = null,
        [FromQuery] string scope = "booking",
        [FromQuery] int durationInMinutes = 30)
    {
        var barber = await _context.BarberProfiles
            .Include(bp => bp.WorkingHours)
            .FirstOrDefaultAsync(bp => bp.Id == barberProfileId);

        if (barber == null)
            return NotFound(new { message = "الحلاق غير موجود" });

        var dayNameArabic = date.DayOfWeek switch
        {
            DayOfWeek.Saturday => "السبت",
            DayOfWeek.Sunday => "الأحد",
            DayOfWeek.Monday => "الاثنين",
            DayOfWeek.Tuesday => "الثلاثاء",
            DayOfWeek.Wednesday => "الأربعاء",
            DayOfWeek.Thursday => "الخميس",
            DayOfWeek.Friday => "الجمعة",
            _ => ""
        };

        var dateUtc = date.Kind == DateTimeKind.Utc
            ? date
            : DateTime.SpecifyKind(date.Date, DateTimeKind.Utc);

        // Collect bookable persons
        var persons = new List<(Guid id, string name, bool isOwner)>();

        // Owner (BarberProfile.UserId) — check shop's working hours
        var shopWorkingHour = barber.WorkingHours
            .FirstOrDefault(wh => wh.DayName == dayNameArabic && wh.IsOpen);

        if (scope == "profile")
        {
            // Profile screen: show ALL persons (owner + all active employees)
            if (shopWorkingHour != null)
                persons.Add((barber.UserId, barber.ShopName, true));

            var employees = await _context.BarberEmployees
                .Where(e => e.BarberProfileId == barberProfileId && e.IsActive)
                .Include(e => e.Schedules)
                .ToListAsync();

            foreach (var emp in employees)
            {
                var empSchedule = emp.Schedules
                    .FirstOrDefault(s => s.DayName == dayNameArabic && s.IsOpen);
                if (empSchedule != null)
                    persons.Add((emp.Id, emp.Name, false));
            }
        }
        else
        {
            // Booking flow: only the selected person
            if (employeeId == null)
            {
                if (shopWorkingHour != null)
                    persons.Add((barber.UserId, barber.ShopName, true));
            }
            else
            {
                var emp = await _context.BarberEmployees
                    .Include(e => e.Schedules)
                    .FirstOrDefaultAsync(e => e.Id == employeeId && e.BarberProfileId == barberProfileId && e.IsActive);

                if (emp != null)
                {
                    var empSchedule = emp.Schedules
                        .FirstOrDefault(s => s.DayName == dayNameArabic && s.IsOpen);
                    if (empSchedule != null)
                        persons.Add((emp.Id, emp.Name, false));
                }
            }
        }

        if (persons.Count == 0)
            return Ok(new { slots = new object[0], message = "لا يوجد موظفين متاحين في هذا اليوم" });

        // Get all bookings for these persons on this date (with service duration for overlap check)
        var personIds = persons.Select(p => p.id).ToList();
        var bookedSlots = await _context.Bookings
            .Include(b => b.BarberService)
            .Where(b => b.BarberProfileId == barberProfileId
                && b.BookingDate >= dateUtc
                && b.BookingDate < dateUtc.AddDays(1)
                && (b.Status == "Pending" || b.Status == "Accepted" || b.Status == "InProgress")
                && b.EmployeeId != null
                && personIds.Contains(b.EmployeeId.Value))
            .Select(b => new { b.EmployeeId, b.BookingTime, Duration = b.BarberService.DurationInMinutes })
            .ToListAsync();

        var bookedByPerson = bookedSlots
            .GroupBy(b => b.EmployeeId!.Value)
            .ToDictionary(g => g.Key, g => g.Select(x => (x.BookingTime, Duration: x.Duration)).ToList());

        // Also check owner bookings (EmployeeId = null for owner bookings)
        var ownerBookings = await _context.Bookings
            .Include(b => b.BarberService)
            .Where(b => b.BarberProfileId == barberProfileId
                && b.BookingDate >= dateUtc
                && b.BookingDate < dateUtc.AddDays(1)
                && (b.Status == "Pending" || b.Status == "Accepted" || b.Status == "InProgress")
                && b.EmployeeId == null)
            .Select(b => new { b.BookingTime, Duration = b.BarberService.DurationInMinutes })
            .ToListAsync();

        // Build owner booking ranges
        var ownerBookingRanges = ownerBookings.Select(x => (x.BookingTime, x.Duration)).ToList();

        // Generate time slots from the earliest open to the latest close
        var earliestOpen = persons.Min(p =>
        {
            if (p.isOwner) return shopWorkingHour!.OpenTime;
            var emp = persons.FirstOrDefault(x => x.id == p.id);
            return _context.EmployeeSchedules
                .Where(s => s.EmployeeId == p.id && s.DayName == dayNameArabic)
                .Select(s => s.OpenTime)
                .FirstOrDefault();
        });

        var latestClose = persons.Max(p =>
        {
            if (p.isOwner) return shopWorkingHour!.CloseTime;
            return _context.EmployeeSchedules
                .Where(s => s.EmployeeId == p.id && s.DayName == dayNameArabic)
                .Select(s => s.CloseTime)
                .FirstOrDefault();
        });

        var slots = new List<object>();
        var current = earliestOpen;
        while (current < latestClose)
        {
            var slotTime = current;
            bool anyAvailable = false;

            foreach (var person in persons)
            {
                // Check if this person is working at this time
                TimeSpan personOpen, personClose;
                if (person.isOwner)
                {
                    personOpen = shopWorkingHour!.OpenTime;
                    personClose = shopWorkingHour!.CloseTime;
                }
                else
                {
                    var sched = await _context.EmployeeSchedules
                        .Where(s => s.EmployeeId == person.id && s.DayName == dayNameArabic)
                        .Select(s => new { s.OpenTime, s.CloseTime })
                        .FirstOrDefaultAsync();
                    if (sched == null) continue;
                    personOpen = sched.OpenTime;
                    personClose = sched.CloseTime;
                }

                if (slotTime < personOpen || slotTime >= personClose)
                    continue;

                // Service must finish before person's closing time
                if (slotTime + TimeSpan.FromMinutes(durationInMinutes) > personClose)
                    continue;

                // Check if this person has a booking that overlaps this slot
                bool isBooked;
                if (person.isOwner)
                    isBooked = ownerBookingRanges.Any(r =>
                        slotTime >= r.BookingTime && slotTime < r.BookingTime + TimeSpan.FromMinutes(r.Duration));
                else
                    isBooked = bookedByPerson.TryGetValue(person.id, out var ranges) &&
                        ranges.Any(r => slotTime >= r.BookingTime && slotTime < r.BookingTime + TimeSpan.FromMinutes(r.Duration));

                if (!isBooked)
                {
                    anyAvailable = true;
                    break;
                }
            }

            slots.Add(new
            {
                time = current.ToString(@"hh\:mm"),
                period = current.TotalHours >= 12 ? "مساءً" : "صباحاً",
                isAvailable = anyAvailable
            });
            current = current.Add(TimeSpan.FromMinutes(30));
        }

        return Ok(new { slots });
    }
}
