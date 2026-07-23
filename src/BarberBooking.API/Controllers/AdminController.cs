using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using BarberBooking.Application.DTOs.Subscription;
using BarberBooking.Application.DTOs.Payment;
using BarberBooking.Application.Interfaces;
using BarberBooking.Domain.Entities;
using BarberBooking.Infrastructure.Data;
using BarberBooking.Infrastructure.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;

namespace BarberBooking.API.Controllers;

[ApiController]
[Authorize(Roles = "Admin")]
[Route("api/admin")]
public class AdminController : ControllerBase
{
    private readonly BarberBookingDbContext _context;
    private readonly JwtSettings _jwtSettings;
    private readonly ISubscriptionService _subscriptionService;
    private readonly IPaymentRequestService _paymentRequestService;
    private readonly ISmsService _smsService;

    public AdminController(
        BarberBookingDbContext context,
        Microsoft.Extensions.Options.IOptions<JwtSettings> jwtSettings,
        ISubscriptionService subscriptionService,
        IPaymentRequestService paymentRequestService,
        ISmsService smsService)
    {
        _context = context;
        _jwtSettings = jwtSettings.Value;
        _subscriptionService = subscriptionService;
        _paymentRequestService = paymentRequestService;
        _smsService = smsService;
    }

    [HttpPost("login")]
    [AllowAnonymous]
    public async Task<IActionResult> Login([FromBody] BarberBooking.Application.DTOs.Auth.LoginDto dto)
    {
        var user = await _context.Users
            .FirstOrDefaultAsync(u => u.PhoneNumber == dto.PhoneNumber && u.Role == "Admin");

        if (user == null || !user.IsActive)
            return BadRequest(new { message = "رقم الهاتف أو كلمة المرور غير صحيحة" });

        if (!BCrypt.Net.BCrypt.Verify(dto.Password, user.PasswordHash))
            return BadRequest(new { message = "رقم الهاتف أو كلمة المرور غير صحيحة" });

        var claims = new List<Claim>
        {
            new(ClaimTypes.NameIdentifier, user.Id.ToString()),
            new(ClaimTypes.Role, "Admin"),
            new("fullName", user.FullName),
            new(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
        };

        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_jwtSettings.Secret));
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var token = new JwtSecurityToken(
            issuer: _jwtSettings.Issuer,
            audience: _jwtSettings.Audience,
            claims: claims,
            expires: DateTime.UtcNow.AddMinutes(_jwtSettings.ExpirationInMinutes),
            signingCredentials: creds
        );

        return Ok(new
        {
            token = new JwtSecurityTokenHandler().WriteToken(token),
            expiration = token.ValidTo,
            role = "Admin",
            fullName = user.FullName,
            userId = user.Id.ToString()
        });
    }

    [HttpGet("dashboard")]
    public async Task<IActionResult> GetDashboard()
    {
        var totalBarbers = await _context.BarberProfiles.CountAsync();
        var totalCustomers = await _context.Users.CountAsync(u => u.Role == "Customer");
        var totalBookings = await _context.Bookings.CountAsync();
        var activeBookings = await _context.Bookings.CountAsync(b => b.Status == "Upcoming");
        var completedBookings = await _context.Bookings.CountAsync(b => b.Status == "Completed");
        var cancelledBookings = await _context.Bookings.CountAsync(b => b.Status == "Cancelled");

        var totalRevenue = await _context.Bookings
            .Where(b => b.Status == "Completed")
            .SumAsync(b => b.FinalPrice);

        var todayBookings = await _context.Bookings
            .CountAsync(b => b.BookingDate.Date == DateTime.UtcNow.Date);

        var activeSubscriptions = await _context.BarberSubscriptions
            .CountAsync(s => s.Status == "active" && s.EndDate > DateTime.UtcNow);

        var monthlyRevenue = await _context.Bookings
            .Where(b => b.Status == "Completed"
                && b.BookingDate >= DateTime.UtcNow.AddMonths(-1))
            .SumAsync(b => b.FinalPrice);

        var topBarbers = await _context.Bookings
            .Include(b => b.BarberProfile)
                .ThenInclude(bp => bp.User)
            .Where(b => b.Status == "Completed")
            .GroupBy(b => b.BarberProfileId)
            .Select(g => new
            {
                barberName = g.First().BarberProfile.User.FullName,
                shopName = g.First().BarberProfile.ShopName,
                bookingCount = g.Count(),
                revenue = g.Sum(b => b.FinalPrice)
            })
            .OrderByDescending(b => b.bookingCount)
            .Take(5)
            .ToListAsync();

        var recentBookings = await _context.Bookings
            .Include(b => b.Customer)
            .Include(b => b.BarberProfile)
                .ThenInclude(bp => bp.User)
            .Include(b => b.BarberService)
            .OrderByDescending(b => b.CreatedAt)
            .Take(10)
            .Select(b => new
            {
                id = b.Id,
                customerName = b.Customer.FullName,
                barberName = b.BarberProfile.User.FullName,
                shopName = b.BarberProfile.ShopName,
                serviceName = b.BarberService.Name,
                bookingDate = b.BookingDate,
                totalPrice = b.TotalPrice,
                finalPrice = b.FinalPrice,
                status = b.Status,
                paymentStatus = b.PaymentStatus
            })
            .ToListAsync();

        var cityStats = await _context.BarberProfiles
            .GroupBy(bp => bp.City)
            .Select(g => new
            {
                city = g.Key,
                count = g.Count()
            })
            .ToListAsync();

        return Ok(new
        {
            totalBarbers,
            totalCustomers,
            totalBookings,
            activeBookings,
            completedBookings,
            cancelledBookings,
            totalRevenue,
            todayBookings,
            activeSubscriptions,
            monthlyRevenue,
            topBarbers,
            recentBookings,
            cityStats
        });
    }

    [HttpGet("barbers")]
    public async Task<IActionResult> GetBarbers([FromQuery] int page = 1, [FromQuery] int pageSize = 20)
    {
        var query = _context.BarberProfiles
            .Include(bp => bp.User)
            .Include(bp => bp.Reviews)
            .OrderByDescending(bp => bp.CreatedAt);

        var totalCount = await query.CountAsync();
        var barbers = await query
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(bp => new
            {
                id = bp.Id,
                shopName = bp.ShopName,
                ownerName = bp.User.FullName,
                phoneNumber = bp.User.PhoneNumber,
                city = bp.City,
                address = bp.Address,
                subscriptionPlan = bp.SubscriptionPlan,
                averageRating = bp.Reviews.Any() ? Math.Round(bp.Reviews.Average(r => r.Rating), 1) : 0.0,
                reviewCount = bp.Reviews.Count,
                isUserActive = bp.User.IsActive,
                createdAt = bp.CreatedAt
            })
            .ToListAsync();

        return Ok(new { barbers, totalCount, page, pageSize });
    }

    [HttpGet("barbers/{id}")]
    public async Task<IActionResult> GetBarberDetail(Guid id)
    {
        var barber = await _context.BarberProfiles
            .Include(bp => bp.User)
            .Include(bp => bp.Services)
            .Include(bp => bp.Reviews)
                .ThenInclude(r => r.Customer)
            .Include(bp => bp.Bookings)
            .FirstOrDefaultAsync(bp => bp.Id == id);

        if (barber == null)
            return NotFound(new { message = "الحلاق غير موجود" });

        return Ok(new
        {
            id = barber.Id,
            shopName = barber.ShopName,
            shopDescription = barber.ShopDescription,
            ownerName = barber.User.FullName,
            phoneNumber = barber.User.PhoneNumber,
            email = barber.User.Email,
            city = barber.City,
            address = barber.Address,
            latitude = barber.Latitude,
            longitude = barber.Longitude,
            subscriptionPlan = barber.SubscriptionPlan,
            isUserActive = barber.User.IsActive,
            services = barber.Services.Select(s => new
            {
                id = s.Id,
                name = s.Name,
                price = s.Price,
                durationInMinutes = s.DurationInMinutes
            }),
            reviews = barber.Reviews.Select(r => new
            {
                id = r.Id,
                customerName = r.Customer.FullName,
                rating = r.Rating,
                comment = r.Comment,
                createdAt = r.CreatedAt
            }),
            totalBookings = barber.Bookings.Count,
            totalRevenue = barber.Bookings
                .Where(b => b.Status == "Completed")
                .Sum(b => b.FinalPrice),
            createdAt = barber.CreatedAt
        });
    }

    [HttpPut("barbers/{id}/toggle-active")]
    public async Task<IActionResult> ToggleBarberActive(Guid id)
    {
        var barber = await _context.BarberProfiles
            .Include(bp => bp.User)
            .FirstOrDefaultAsync(bp => bp.Id == id);

        if (barber == null)
            return NotFound(new { message = "الحلاق غير موجود" });

        barber.User.IsActive = !barber.User.IsActive;
        await _context.SaveChangesAsync();

        return Ok(new
        {
            message = barber.User.IsActive ? "تم تفعيل الحلاق" : "تم تعطيل الحلاق",
            isActive = barber.User.IsActive
        });
    }

    [HttpGet("customers")]
    public async Task<IActionResult> GetCustomers([FromQuery] int page = 1, [FromQuery] int pageSize = 20)
    {
        var query = _context.Users
            .Where(u => u.Role == "Customer")
            .OrderByDescending(u => u.CreatedAt);

        var totalCount = await query.CountAsync();
        var customers = await query
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(u => new
            {
                id = u.Id,
                fullName = u.FullName,
                phoneNumber = u.PhoneNumber,
                email = u.Email,
                city = u.City,
                isActive = u.IsActive,
                noShowCount = u.NoShowCount,
                isBookingBlocked = u.IsBookingBlocked,
                blockReason = u.BlockReason,
                dailyCancelCount = u.DailyCancelCount,
                createdAt = u.CreatedAt
            })
            .ToListAsync();

        // Get booking counts separately
        var customerIds = customers.Select(c => c.id).ToList();
        var bookingCounts = await _context.Bookings
            .Where(b => customerIds.Contains(b.CustomerId))
            .GroupBy(b => b.CustomerId)
            .Select(g => new { customerId = g.Key, count = g.Count() })
            .ToListAsync();

        var customersWithBookings = customers.Select(c => new
        {
            c.id,
            c.fullName,
            c.phoneNumber,
            c.email,
            c.city,
            c.isActive,
            c.noShowCount,
            c.isBookingBlocked,
            c.blockReason,
            c.dailyCancelCount,
            totalBookings = bookingCounts.FirstOrDefault(bc => bc.customerId == c.id)?.count ?? 0,
            c.createdAt
        });

        return Ok(new { customers = customersWithBookings, totalCount, page, pageSize });
    }

    [HttpGet("stats/revenue")]
    public async Task<IActionResult> GetRevenueStats([FromQuery] int months = 6)
    {
        var startDate = DateTime.UtcNow.AddMonths(-months);

        var monthlyData = await _context.Bookings
            .Where(b => b.Status == "Completed" && b.BookingDate >= startDate)
            .GroupBy(b => new { b.BookingDate.Year, b.BookingDate.Month })
            .Select(g => new
            {
                year = g.Key.Year,
                month = g.Key.Month,
                revenue = g.Sum(b => b.FinalPrice),
                bookingCount = g.Count()
            })
            .OrderBy(x => x.year)
            .ThenBy(x => x.month)
            .ToListAsync();

        return Ok(monthlyData);
    }

    [HttpGet("stats/bookings")]
    public async Task<IActionResult> GetBookingStats()
    {
        var today = DateTime.UtcNow.Date;
        var thisWeek = today.AddDays(-(int)today.DayOfWeek);
        var thisMonth = new DateTime(today.Year, today.Month, 1);

        var todayCount = await _context.Bookings
            .CountAsync(b => b.BookingDate.Date == today);

        var weekCount = await _context.Bookings
            .CountAsync(b => b.BookingDate >= thisWeek);

        var monthCount = await _context.Bookings
            .CountAsync(b => b.BookingDate >= thisMonth);

        var statusBreakdown = await _context.Bookings
            .GroupBy(b => b.Status)
            .Select(g => new
            {
                status = g.Key,
                count = g.Count()
            })
            .ToListAsync();

        return Ok(new
        {
            today = todayCount,
            thisWeek = weekCount,
            thisMonth = monthCount,
            statusBreakdown
        });
    }

    [HttpGet("bookings")]
    public async Task<IActionResult> GetBookings([FromQuery] int page = 1, [FromQuery] int pageSize = 20, [FromQuery] string? status = null)
    {
        var query = _context.Bookings
            .Include(b => b.Customer)
            .Include(b => b.BarberProfile)
                .ThenInclude(bp => bp.User)
            .Include(b => b.BarberService)
            .AsQueryable();

        if (!string.IsNullOrEmpty(status))
            query = query.Where(b => b.Status == status);

        var totalCount = await query.CountAsync();
        var bookings = await query
            .OrderByDescending(b => b.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(b => new
            {
                id = b.Id,
                customerName = b.Customer.FullName,
                customerPhone = b.Customer.PhoneNumber,
                barberName = b.BarberProfile.User.FullName,
                shopName = b.BarberProfile.ShopName,
                serviceName = b.BarberService.Name,
                bookingDate = b.BookingDate,
                totalPrice = b.TotalPrice,
                finalPrice = b.FinalPrice,
                status = b.Status,
                paymentStatus = b.PaymentStatus,
                paymentMethod = b.PaymentMethod,
                createdAt = b.CreatedAt
            })
            .ToListAsync();

        return Ok(new { bookings, totalCount, page, pageSize });
    }

    // ===== SUBSCRIPTION MANAGEMENT =====

    [HttpGet("subscriptions")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> GetSubscriptions(
        [FromQuery] string? status = null,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20)
    {
        var subscriptions = await _subscriptionService.GetAllSubscriptionsAsync(status, page, pageSize);
        return Ok(subscriptions);
    }

    [HttpGet("subscriptions/{id}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> GetSubscriptionDetail(Guid id)
    {
        var subscription = await _subscriptionService.GetSubscriptionByIdAsync(id);
        if (subscription == null)
            return NotFound(new { message = "الاشتراك غير موجود" });
        return Ok(subscription);
    }

    [HttpGet("subscriptions/stats")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> GetSubscriptionStats()
    {
        var stats = await _subscriptionService.GetStatsAsync();
        return Ok(stats);
    }

    [HttpPost("subscriptions/{id}/extend")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> ExtendSubscription(Guid id, [FromBody] ExtendSubscriptionDto dto)
    {
        try
        {
            var adminName = User.FindFirst("fullName")?.Value ?? "Admin";
            await _subscriptionService.ExtendSubscriptionAsync(id, dto.Days, adminName);
            return Ok(new { message = $"تم تمديد الاشتراك {dto.Days} يوم" });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost("barbers/{id}/change-plan")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> ForceChangePlan(Guid id, [FromBody] ForceChangePlanDto dto)
    {
        try
        {
            var adminName = User.FindFirst("fullName")?.Value ?? "Admin";
            await _subscriptionService.ForceChangePlanAsync(id, dto.PlanId, adminName);
            return Ok(new { message = "تم تغيير الخطة بنجاح" });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpGet("subscription-plans")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> GetSubscriptionPlans()
    {
        var plans = await _subscriptionService.GetPlansAsync();
        return Ok(plans);
    }

    [HttpPut("subscription-plans/{id}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> UpdateSubscriptionPlan(Guid id, [FromBody] UpdatePlanDto dto)
    {
        var plan = await _context.SubscriptionPlans.FindAsync(id);
        if (plan == null)
            return NotFound(new { message = "الخطة غير موجودة" });

        if (dto.MonthlyPrice.HasValue) plan.MonthlyPrice = dto.MonthlyPrice.Value;
        if (dto.YearlyPrice.HasValue) plan.YearlyPrice = dto.YearlyPrice.Value;
        if (dto.MaxServices.HasValue) plan.MaxServices = dto.MaxServices.Value;
        if (dto.MaxPhotos.HasValue) plan.MaxPhotos = dto.MaxPhotos.Value;
        if (dto.MaxBookingsPerMonth.HasValue) plan.MaxBookingsPerMonth = dto.MaxBookingsPerMonth.Value;
        if (dto.MaxEmployees.HasValue) plan.MaxEmployees = dto.MaxEmployees.Value;
        if (!string.IsNullOrEmpty(dto.AnalyticsLevel)) plan.AnalyticsLevel = dto.AnalyticsLevel;
        if (dto.HasPromoCodes.HasValue) plan.HasPromoCodes = dto.HasPromoCodes.Value;
        if (dto.HasPrioritySupport.HasValue) plan.HasPrioritySupport = dto.HasPrioritySupport.Value;
        if (dto.IsActive.HasValue) plan.IsActive = dto.IsActive.Value;

        await _context.SaveChangesAsync();
        return Ok(new { message = "تم تحديث الخطة بنجاح" });
    }

    // ===== PAYMENT REQUESTS =====

    [HttpGet("payments")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> GetAllPaymentRequests([FromQuery] string? status)
    {
        var requests = await _paymentRequestService.GetAllPaymentRequestsAsync(status);
        return Ok(requests);
    }

    [HttpGet("payments/pending-count")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> GetPendingPaymentCount()
    {
        var count = await _paymentRequestService.GetPendingPaymentRequestsCountAsync();
        return Ok(new { count });
    }

    [HttpPost("payments/{id}/review")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> ReviewPaymentRequest(Guid id, [FromBody] ReviewPaymentRequestDto dto)
    {
        try
        {
            var adminIdStr = User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? User.FindFirst("sub")?.Value;
            if (string.IsNullOrEmpty(adminIdStr))
                return Unauthorized();
            var adminId = Guid.Parse(adminIdStr);

            if (string.IsNullOrEmpty(dto.Status) || (dto.Status != "approved" && dto.Status != "rejected"))
                return BadRequest(new { message = "الحالة يجب أن تكون approved أو rejected" });

            var result = await _paymentRequestService.ReviewPaymentRequestAsync(id, dto, adminId);
            var message = dto.Status == "approved" ? "تم قبول الطلب وتفعيل الحساب" : "تم رفض الطلب";
            return Ok(new { message, paymentRequest = result });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }
    // ===== CUSTOMER PHONE VERIFICATION =====

    [HttpGet("customer-verifications")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> GetCustomerVerifications(
        [FromQuery] string? status = null,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20)
    {
        var query = _context.Users
            .Where(u => u.Role == "Customer")
            .AsQueryable();

        if (!string.IsNullOrEmpty(status))
            query = query.Where(u => u.PhoneVerificationStatus == status);

        var totalCount = await query.CountAsync();
        var customers = await query
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
                profileImageUrl = u.ProfileImageUrl,
                phoneVerificationStatus = u.PhoneVerificationStatus,
                isActive = u.IsActive,
                createdAt = u.CreatedAt
            })
            .ToListAsync();

        return Ok(new { customers, totalCount, page, pageSize });
    }

    [HttpGet("customer-verifications/{id}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> GetCustomerVerificationDetail(Guid id)
    {
        var customer = await _context.Users
            .FirstOrDefaultAsync(u => u.Id == id && u.Role == "Customer");

        if (customer == null)
            return NotFound(new { message = "الزبون غير موجود" });

        return Ok(new
        {
            id = customer.Id,
            fullName = customer.FullName,
            phoneNumber = customer.PhoneNumber,
            email = customer.Email,
            city = customer.City,
            profileImageUrl = customer.ProfileImageUrl,
            phoneVerificationStatus = customer.PhoneVerificationStatus,
            isActive = customer.IsActive,
            createdAt = customer.CreatedAt
        });
    }

    [HttpPost("customer-verifications/{id}/send-otp")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> SendCustomerVerificationOtp(Guid id)
    {
        var customer = await _context.Users
            .FirstOrDefaultAsync(u => u.Id == id && u.Role == "Customer");

        if (customer == null)
            return NotFound(new { message = "الزبون غير موجود" });

        var code = System.Security.Cryptography.RandomNumberGenerator.GetInt32(100000, 999999).ToString();

        var otp = new OtpCode
        {
            PhoneNumber = customer.PhoneNumber,
            Code = code,
            ExpiresAt = DateTime.UtcNow.AddHours(24),
            IsUsed = false,
            Purpose = "verify"
        };

        _context.OtpCodes.Add(otp);
        await _context.SaveChangesAsync();

        await _smsService.SendOtpAsync(customer.PhoneNumber, code);

        return Ok(new
        {
            message = $"تم إرسال رمز التحقق {code} على واتساب {customer.PhoneNumber}",
            code = code
        });
    }

    [HttpPost("customer-verifications/{id}/verify")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> VerifyCustomerPhone(Guid id, [FromBody] VerifyCustomerPhoneDto dto)
    {
        var customer = await _context.Users
            .FirstOrDefaultAsync(u => u.Id == id && u.Role == "Customer");

        if (customer == null)
            return NotFound(new { message = "الزبون غير موجود" });

        var otp = await _context.OtpCodes
            .Where(o => o.PhoneNumber == customer.PhoneNumber
                && o.Code == dto.Code
                && o.Purpose == "verify"
                && !o.IsUsed
                && o.ExpiresAt > DateTime.UtcNow)
            .OrderByDescending(o => o.CreatedAt)
            .FirstOrDefaultAsync();

        if (otp == null)
            return BadRequest(new { message = "الرمز غير صحيح أو منتهي الصلاحية" });

        otp.IsUsed = true;
        customer.IsPhoneVerified = true;
        customer.PhoneVerificationStatus = "Verified";
        customer.IsActive = true;
        await _context.SaveChangesAsync();

        return Ok(new { message = "تم التحقق من رقم الهاتف بنجاح" });
    }

    [HttpPost("customer-verifications/{id}/reject")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> RejectCustomerVerification(Guid id, [FromBody] RejectCustomerVerificationDto dto)
    {
        var customer = await _context.Users
            .FirstOrDefaultAsync(u => u.Id == id && u.Role == "Customer");

        if (customer == null)
            return NotFound(new { message = "الزبون غير موجود" });

        customer.PhoneVerificationStatus = "Rejected";
        await _context.SaveChangesAsync();

        return Ok(new { message = "تم رفض طلب التحقق" });
    }

    [HttpGet("customer-verifications/pending-count")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> GetPendingCustomerVerificationCount()
    {
        var count = await _context.Users
            .CountAsync(u => u.Role == "Customer" && u.PhoneVerificationStatus == "Pending");
        return Ok(new { count });
    }

    // ===== ADMIN PASSWORD RESET =====

    [HttpGet("password-resets")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> GetPasswordResetUsers(
        [FromQuery] string? role = null,
        [FromQuery] string? search = null,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20)
    {
        var query = _context.Users.AsQueryable();

        if (!string.IsNullOrEmpty(role))
            query = query.Where(u => u.Role == role);

        if (!string.IsNullOrEmpty(search))
            query = query.Where(u => u.FullName.Contains(search) || u.PhoneNumber.Contains(search));

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
                role = u.Role,
                isActive = u.IsActive,
                createdAt = u.CreatedAt
            })
            .ToListAsync();

        return Ok(new { users, totalCount, page, pageSize });
    }

    [HttpPost("password-resets/{id}/send-otp")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> SendPasswordResetOtp(Guid id)
    {
        var user = await _context.Users
            .FirstOrDefaultAsync(u => u.Id == id);

        if (user == null)
            return NotFound(new { message = "المستخدم غير موجود" });

        var code = System.Security.Cryptography.RandomNumberGenerator.GetInt32(100000, 999999).ToString();

        var otp = new OtpCode
        {
            PhoneNumber = user.PhoneNumber,
            Code = code,
            ExpiresAt = DateTime.UtcNow.AddHours(24),
            IsUsed = false,
            Purpose = "reset"
        };

        _context.OtpCodes.Add(otp);
        await _context.SaveChangesAsync();

        await _smsService.SendOtpAsync(user.PhoneNumber, code);

        return Ok(new
        {
            message = $"تم إرسال رمز إعادة تعيين كلمة المرور {code} على واتساب {user.PhoneNumber}",
            code = code
        });
    }

    [HttpGet("password-reset-notifications")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> GetPasswordResetNotifications()
    {
        var adminId = Guid.Parse(User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value!);
        var count = await _context.Notifications
            .CountAsync(n => n.UserId == adminId && n.Type == "password_reset" && !n.IsRead);
        return Ok(new { count });
    }

    [HttpGet("password-reset-requests")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> GetPasswordResetRequests()
    {
        var adminId = Guid.Parse(User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value!);
        var notifications = await _context.Notifications
            .Where(n => n.UserId == adminId && n.Type == "password_reset")
            .OrderByDescending(n => n.CreatedAt)
            .Take(50)
            .Select(n => new
            {
                id = n.Id,
                title = n.Title,
                message = n.Message,
                isRead = n.IsRead,
                createdAt = n.CreatedAt
            })
            .ToListAsync();

        return Ok(new { notifications });
    }

    [HttpPost("password-reset-requests/{id}/mark-read")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> MarkPasswordResetRequestRead(Guid id)
    {
        var adminId = Guid.Parse(User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value!);
        var notification = await _context.Notifications
            .FirstOrDefaultAsync(n => n.Id == id && n.UserId == adminId);

        if (notification != null)
        {
            notification.IsRead = true;
            await _context.SaveChangesAsync();
        }

        return Ok(new { message = "تم تعليم الإشعار كمقروء" });
    }

    [HttpPost("password-reset-notifications/mark-read")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> MarkPasswordResetNotificationsRead()
    {
        var adminId = Guid.Parse(User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value!);
        var notifications = await _context.Notifications
            .Where(n => n.UserId == adminId && n.Type == "password_reset" && !n.IsRead)
            .ToListAsync();

        foreach (var n in notifications)
            n.IsRead = true;

        await _context.SaveChangesAsync();
        return Ok(new { message = "تم تعليم الإشعارات كمقروءة" });
    }

    // ===== CUSTOMER BLOCK MANAGEMENT =====

    [HttpGet("customers/blocked")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> GetBlockedCustomers()
    {
        var customers = await _context.Users
            .Where(u => u.Role == "Customer" && u.IsBookingBlocked)
            .Select(u => new
            {
                id = u.Id,
                fullName = u.FullName,
                phoneNumber = u.PhoneNumber,
                noShowCount = u.NoShowCount,
                isBookingBlocked = u.IsBookingBlocked,
                bookingBlockedAt = u.BookingBlockedAt,
                blockReason = u.BlockReason
            })
            .ToListAsync();

        return Ok(new { customers });
    }

    [HttpPut("customers/{id}/unblock")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> UnblockCustomer(Guid id)
    {
        var customer = await _context.Users.FindAsync(id);
        if (customer == null)
            return NotFound(new { message = "العميل غير موجود" });

        if (!customer.IsBookingBlocked)
            return BadRequest(new { message = "العميل غير محظور" });

        customer.NoShowCount = 0;
        customer.IsBookingBlocked = false;
        customer.BookingBlockedAt = null;
        customer.BlockReason = null;

        _context.Notifications.Add(new Notification
        {
            UserId = customer.Id,
            Title = "تم فك حظرك من الحجز",
            Message = "قام المدير بفك حظرك. يمكنك الآن إنشاء حجوزات جديدة.",
            Type = "booking",
            IsRead = false
        });

        await _context.SaveChangesAsync();

        return Ok(new { message = "تم فك حظر العميل بنجاح" });
    }
}

public class ExtendSubscriptionDto
{
    public int Days { get; set; }
}

public class ForceChangePlanDto
{
    public Guid PlanId { get; set; }
}

public class UpdatePlanDto
{
    public decimal? MonthlyPrice { get; set; }
    public decimal? YearlyPrice { get; set; }
    public int? MaxServices { get; set; }
    public int? MaxPhotos { get; set; }
    public int? MaxBookingsPerMonth { get; set; }
    public int? MaxEmployees { get; set; }
    public string? AnalyticsLevel { get; set; }
    public bool? HasPromoCodes { get; set; }
    public bool? HasPrioritySupport { get; set; }
    public bool? IsActive { get; set; }
}

public class VerifyCustomerPhoneDto
{
    public string Code { get; set; } = string.Empty;
}

public class RejectCustomerVerificationDto
{
    public string? Reason { get; set; }
}
