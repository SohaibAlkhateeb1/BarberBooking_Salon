using BarberBooking.Application.DTOs.Subscription;
using BarberBooking.Application.Interfaces;
using BarberBooking.Domain.Entities;
using BarberBooking.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace BarberBooking.API.Services;

public class SubscriptionService : ISubscriptionService
{
    private readonly BarberBookingDbContext _context;

    public SubscriptionService(BarberBookingDbContext context)
    {
        _context = context;
    }

    public async Task<List<SubscriptionPlanDto>> GetPlansAsync()
    {
        return await _context.SubscriptionPlans
            .Where(p => p.IsActive)
            .OrderBy(p => p.MonthlyPrice)
            .Select(p => new SubscriptionPlanDto
            {
                Id = p.Id,
                Name = p.Name,
                NameArabic = p.NameArabic,
                Description = p.Description,
                MonthlyPrice = p.MonthlyPrice,
                YearlyPrice = p.YearlyPrice,
                MaxServices = p.MaxServices,
                MaxPhotos = p.MaxPhotos,
                MaxBookingsPerMonth = p.MaxBookingsPerMonth,
                MaxEmployees = p.MaxEmployees,
                AnalyticsLevel = p.AnalyticsLevel,
                HasPromoCodes = p.HasPromoCodes,
                HasPrioritySupport = p.HasPrioritySupport,
                IsActive = p.IsActive
            })
            .ToListAsync();
    }

    public async Task<SubscriptionPlanDto?> GetPlanByIdAsync(Guid planId)
    {
        var plan = await _context.SubscriptionPlans.FindAsync(planId);
        if (plan == null) return null;

        return new SubscriptionPlanDto
        {
            Id = plan.Id,
            Name = plan.Name,
            NameArabic = plan.NameArabic,
            Description = plan.Description,
            MonthlyPrice = plan.MonthlyPrice,
            YearlyPrice = plan.YearlyPrice,
            MaxServices = plan.MaxServices,
            MaxPhotos = plan.MaxPhotos,
            MaxBookingsPerMonth = plan.MaxBookingsPerMonth,
            MaxEmployees = plan.MaxEmployees,
            AnalyticsLevel = plan.AnalyticsLevel,
            HasPromoCodes = plan.HasPromoCodes,
            HasPrioritySupport = plan.HasPrioritySupport,
            IsActive = plan.IsActive
        };
    }

    public async Task<SubscriptionPlanDto?> GetPlanByNameAsync(string name)
    {
        var plan = await _context.SubscriptionPlans
            .FirstOrDefaultAsync(p => p.Name.ToLower() == name.ToLower());
        if (plan == null) return null;

        return await GetPlanByIdAsync(plan.Id);
    }

    public async Task<CurrentSubscriptionDto?> GetCurrentSubscriptionAsync(Guid barberId)
    {
        var barber = await _context.BarberProfiles
            .FirstOrDefaultAsync(bp => bp.Id == barberId);
        if (barber == null) return null;

        var subscription = await _context.BarberSubscriptions
            .Include(bs => bs.SubscriptionPlan)
            .Where(bs => bs.BarberProfileId == barberId && (bs.Status == "active" || bs.Status == "cancel_pending" || bs.Status == "expired"))
            .OrderByDescending(bs => bs.CreatedAt)
            .FirstOrDefaultAsync();

        if (subscription == null)
        {
            var plan = await _context.SubscriptionPlans
                .FirstOrDefaultAsync(p => p.Name.ToLower() == barber.SubscriptionPlan.ToLower());
            if (plan == null) return null;

            return new CurrentSubscriptionDto
            {
                SubscriptionId = Guid.Empty,
                PlanId = plan.Id,
                PlanName = plan.Name,
                PlanNameArabic = plan.NameArabic,
                AmountPaid = 0,
                PaymentMethod = "",
                Status = "none",
                IsYearly = false,
                StartDate = barber.CreatedAt,
                EndDate = DateTime.MaxValue,
                MaxServices = plan.MaxServices,
                MaxPhotos = plan.MaxPhotos,
                MaxBookingsPerMonth = plan.MaxBookingsPerMonth,
                MaxEmployees = plan.MaxEmployees,
                AnalyticsLevel = plan.AnalyticsLevel,
                HasPromoCodes = plan.HasPromoCodes,
                HasPrioritySupport = plan.HasPrioritySupport,
                CurrentServicesCount = await _context.BarberServices.CountAsync(s => s.BarberProfileId == barberId),
                CurrentPhotosCount = await _context.PortfolioImages.CountAsync(p => p.BarberProfileId == barberId),
                CurrentBookingsCount = await GetMonthlyBookingCountAsync(barberId),
                CurrentEmployeesCount = await _context.BarberEmployees.CountAsync(e => e.BarberProfileId == barberId && e.IsActive)
            };
        }

        var bookingCount = await GetMonthlyBookingCountAsync(barberId);
        var limit = subscription.SubscriptionPlan.MaxBookingsPerMonth;
        var bookingStatus = "normal";
        if (limit > 0)
        {
            if (bookingCount >= limit) bookingStatus = "limit_reached";
            else if (bookingCount >= limit * 0.8) bookingStatus = "warning";
        }

        var now = DateTime.UtcNow;
        var daysRemaining = (subscription.EndDate - now).Days;
        var isExpired = subscription.Status == "expired" || (subscription.Status == "cancel_pending" && subscription.EndDate < now);
        var isExpiringSoon = !isExpired && daysRemaining <= 7 && daysRemaining > 0;

        return new CurrentSubscriptionDto
        {
            SubscriptionId = subscription.Id,
            PlanId = subscription.SubscriptionPlanId,
            PlanName = subscription.SubscriptionPlan.Name,
            PlanNameArabic = subscription.SubscriptionPlan.NameArabic,
            AmountPaid = subscription.AmountPaid,
            PaymentMethod = subscription.PaymentMethod,
            Status = subscription.Status,
            IsYearly = subscription.IsYearly,
            StartDate = subscription.StartDate,
            EndDate = subscription.EndDate,
            MaxServices = subscription.SubscriptionPlan.MaxServices,
            MaxPhotos = subscription.SubscriptionPlan.MaxPhotos,
            MaxBookingsPerMonth = subscription.SubscriptionPlan.MaxBookingsPerMonth,
            MaxEmployees = subscription.SubscriptionPlan.MaxEmployees,
            AnalyticsLevel = subscription.SubscriptionPlan.AnalyticsLevel,
            HasPromoCodes = subscription.SubscriptionPlan.HasPromoCodes,
            HasPrioritySupport = subscription.SubscriptionPlan.HasPrioritySupport,
            CurrentServicesCount = await _context.BarberServices.CountAsync(s => s.BarberProfileId == barberId),
            CurrentPhotosCount = await _context.PortfolioImages.CountAsync(p => p.BarberProfileId == barberId),
            CurrentBookingsCount = bookingCount,
            CurrentEmployeesCount = await _context.BarberEmployees.CountAsync(e => e.BarberProfileId == barberId && e.IsActive),
            BookingLimitStatus = bookingStatus
        };
    }

    public async Task<CurrentSubscriptionDto> SubscribeAsync(Guid barberId, SubscribeRequestDto request)
    {
        var barber = await _context.BarberProfiles
            .FirstOrDefaultAsync(bp => bp.Id == barberId);
        if (barber == null)
            throw new InvalidOperationException("الحلاق غير موجود");

        var plan = await _context.SubscriptionPlans.FindAsync(request.PlanId);
        if (plan == null)
            throw new InvalidOperationException("الخطة غير موجودة");

        var existingActive = await _context.BarberSubscriptions
            .FirstOrDefaultAsync(bs => bs.BarberProfileId == barberId && bs.Status == "active" && bs.EndDate > DateTime.UtcNow);
        if (existingActive != null)
            throw new InvalidOperationException("لديك اشتراك نشط بالفعل");

        var expiredSub = await _context.BarberSubscriptions
            .FirstOrDefaultAsync(bs => bs.BarberProfileId == barberId && (bs.Status == "expired" || bs.Status == "cancel_pending"));

        if (expiredSub != null)
        {
            expiredSub.Status = "expired";
        }

        var amount = request.IsYearly ? plan.YearlyPrice : plan.MonthlyPrice;
        var endDate = request.IsYearly
            ? DateTime.UtcNow.AddYears(1)
            : DateTime.UtcNow.AddMonths(1);

        var subscription = new BarberSubscription
        {
            BarberProfileId = barberId,
            SubscriptionPlanId = request.PlanId,
            StartDate = DateTime.UtcNow,
            EndDate = endDate,
            IsYearly = request.IsYearly,
            AmountPaid = amount,
            PaymentMethod = "cash",
            Status = "active"
        };

        _context.BarberSubscriptions.Add(subscription);

        barber.SubscriptionPlan = plan.Name;
        barber.IsYearly = request.IsYearly;

        var history = new SubscriptionHistory
        {
            BarberSubscriptionId = subscription.Id,
            BarberProfileId = barberId,
            Action = "created",
            NewPlanId = request.PlanId,
            AmountPaid = amount,
            PaymentMethod = "cash",
            Notes = request.IsYearly ? "اشتراك سنوي" : "اشتراك شهري"
        };
        _context.SubscriptionHistories.Add(history);

        await _context.SaveChangesAsync();

        return await GetCurrentSubscriptionAsync(barberId) ?? throw new InvalidOperationException("خطأ في إنشاء الاشتراك");
    }

    public async Task<CurrentSubscriptionDto> UpgradeAsync(Guid barberId, UpgradeRequestDto request)
    {
        var barber = await _context.BarberProfiles
            .FirstOrDefaultAsync(bp => bp.Id == barberId);
        if (barber == null)
            throw new InvalidOperationException("الحلاق غير موجود");

        var currentSubscription = await _context.BarberSubscriptions
            .Include(bs => bs.SubscriptionPlan)
            .FirstOrDefaultAsync(bs => bs.BarberProfileId == barberId && bs.Status == "active");
        if (currentSubscription == null)
            throw new InvalidOperationException("لا يوجد اشتراك نشط");

        var newPlan = await _context.SubscriptionPlans.FindAsync(request.NewPlanId);
        if (newPlan == null)
            throw new InvalidOperationException("الخطة الجديدة غير موجودة");

        // Calculate proration
        var daysRemaining = (currentSubscription.EndDate - DateTime.UtcNow).Days;
        var currentDailyRate = currentSubscription.SubscriptionPlan.MonthlyPrice / 30;
        var credit = currentDailyRate * daysRemaining;

        var newAmount = currentSubscription.IsYearly ? newPlan.YearlyPrice : newPlan.MonthlyPrice;
        var amountToPay = Math.Max(0, newAmount - credit);

        // Update current subscription
        currentSubscription.Status = "cancelled";

        // Create new subscription
        var newEndDate = currentSubscription.IsYearly
            ? DateTime.UtcNow.AddYears(1)
            : DateTime.UtcNow.AddMonths(1);

        var newSubscription = new BarberSubscription
        {
            BarberProfileId = barberId,
            SubscriptionPlanId = request.NewPlanId,
            StartDate = DateTime.UtcNow,
            EndDate = newEndDate,
            IsYearly = currentSubscription.IsYearly,
            AmountPaid = amountToPay,
            PaymentMethod = request.PaymentMethod,
            Status = "active"
        };

        _context.BarberSubscriptions.Add(newSubscription);

        // Update barber profile
        barber.SubscriptionPlan = newPlan.Name;

        // Create history record
        var history = new SubscriptionHistory
        {
            BarberSubscriptionId = newSubscription.Id,
            BarberProfileId = barberId,
            Action = "upgraded",
            PreviousPlanId = currentSubscription.SubscriptionPlanId,
            NewPlanId = request.NewPlanId,
            AmountPaid = amountToPay,
            PaymentMethod = request.PaymentMethod,
            Notes = $"ترقية من {currentSubscription.SubscriptionPlan.NameArabic} إلى {newPlan.NameArabic}. رصيد متبقى: {credit:F2}₪"
        };
        _context.SubscriptionHistories.Add(history);

        await _context.SaveChangesAsync();

        return await GetCurrentSubscriptionAsync(barberId) ?? throw new InvalidOperationException("خطأ في الترقية");
    }

    public async Task CancelAsync(Guid barberId)
    {
        var barber = await _context.BarberProfiles
            .FirstOrDefaultAsync(bp => bp.Id == barberId);
        if (barber == null)
            throw new InvalidOperationException("الحلاق غير موجود");

        var subscription = await _context.BarberSubscriptions
            .Include(bs => bs.SubscriptionPlan)
            .FirstOrDefaultAsync(bs => bs.BarberProfileId == barberId && bs.Status == "active");
        if (subscription == null)
            throw new InvalidOperationException("لا يوجد اشتراك نشط");

        subscription.Status = "cancel_pending";

        // Create history record
        var history = new SubscriptionHistory
        {
            BarberSubscriptionId = subscription.Id,
            BarberProfileId = barberId,
            Action = "cancel_requested",
            PreviousPlanId = subscription.SubscriptionPlanId,
            NewPlanId = subscription.SubscriptionPlanId,
            AmountPaid = 0,
            Notes = $"طلب إلغاء الاشتراك من {subscription.SubscriptionPlan.NameArabic}. ينتهي في {subscription.EndDate:yyyy-MM-dd}"
        };
        _context.SubscriptionHistories.Add(history);

        await _context.SaveChangesAsync();
    }

    public async Task<BookingLimitStatusDto> GetBookingLimitStatusAsync(Guid barberId)
    {
        var count = await GetMonthlyBookingCountAsync(barberId);
        var limit = await GetBookingLimitAsync(barberId);

        var status = "normal";
        if (limit > 0)
        {
            if (count >= limit) status = "limit_reached";
            else if (count >= limit * 0.8) status = "warning";
        }

        return new BookingLimitStatusDto
        {
            CurrentCount = count,
            Limit = limit,
            Status = status
        };
    }

    public async Task<int> GetMonthlyBookingCountAsync(Guid barberId)
    {
        var now = DateTime.UtcNow;
        return await _context.Bookings
            .CountAsync(b => b.BarberProfileId == barberId
                && b.Status != "Cancelled"
                && b.BookingDate.Year == now.Year
                && b.BookingDate.Month == now.Month);
    }

    public async Task<int> GetBookingLimitAsync(Guid barberId)
    {
        var barber = await _context.BarberProfiles
            .FirstOrDefaultAsync(bp => bp.Id == barberId);
        if (barber == null) return 150;

        var subscription = await _context.BarberSubscriptions
            .Include(bs => bs.SubscriptionPlan)
            .FirstOrDefaultAsync(bs => bs.BarberProfileId == barberId && bs.Status == "active");

        if (subscription != null)
            return subscription.SubscriptionPlan.MaxBookingsPerMonth;

        var plan = await _context.SubscriptionPlans
            .FirstOrDefaultAsync(p => p.Name.ToLower() == barber.SubscriptionPlan.ToLower());
        return plan?.MaxBookingsPerMonth ?? 150;
    }

    public async Task<bool> CanAddServiceAsync(Guid barberId)
    {
        var plan = await GetActivePlanForBarberAsync(barberId);
        if (plan == null) return false;
        if (plan.MaxServices < 0) return true;
        var count = await _context.BarberServices.CountAsync(s => s.BarberProfileId == barberId);
        return count < plan.MaxServices;
    }

    public async Task<bool> CanAddPhotoAsync(Guid barberId)
    {
        var plan = await GetActivePlanForBarberAsync(barberId);
        if (plan == null) return false;
        if (plan.MaxPhotos < 0) return true;
        var count = await _context.PortfolioImages.CountAsync(p => p.BarberProfileId == barberId);
        return count < plan.MaxPhotos;
    }

    public async Task<bool> CanAddEmployeeAsync(Guid barberId)
    {
        var plan = await GetActivePlanForBarberAsync(barberId);
        if (plan == null) return false;
        if (plan.MaxEmployees < 0) return true;
        var count = await _context.BarberEmployees.CountAsync(e => e.BarberProfileId == barberId && e.IsActive);
        return count < plan.MaxEmployees;
    }

    public async Task<bool> CanUseAnalyticsAsync(Guid barberId)
    {
        var plan = await GetActivePlanForBarberAsync(barberId);
        return plan?.AnalyticsLevel != "none";
    }

    public async Task<bool> CanUsePromoCodesAsync(Guid barberId)
    {
        var plan = await GetActivePlanForBarberAsync(barberId);
        return plan?.HasPromoCodes ?? false;
    }

    private async Task<SubscriptionPlan?> GetActivePlanForBarberAsync(Guid barberId)
    {
        // Try active subscription first
        var sub = await _context.BarberSubscriptions
            .Include(s => s.SubscriptionPlan)
            .Where(s => s.BarberProfileId == barberId && s.Status == "active" && s.EndDate > DateTime.UtcNow)
            .OrderByDescending(s => s.CreatedAt)
            .FirstOrDefaultAsync();

        if (sub != null)
            return sub.SubscriptionPlan;

        // Fallback to BarberProfile.SubscriptionPlan
        var barber = await _context.BarberProfiles.FindAsync(barberId);
        if (barber == null) return null;

        return await _context.SubscriptionPlans
            .FirstOrDefaultAsync(p => p.Name.ToLower() == barber.SubscriptionPlan.ToLower());
    }

    public async Task<bool> HasPrioritySupportAsync(Guid barberId)
    {
        var sub = await _context.BarberSubscriptions
            .Include(s => s.SubscriptionPlan)
            .Where(s => s.BarberProfileId == barberId && s.Status == "active" && s.EndDate > DateTime.UtcNow)
            .OrderByDescending(s => s.CreatedAt)
            .FirstOrDefaultAsync();
        return sub?.SubscriptionPlan.HasPrioritySupport ?? false;
    }

    public async Task<List<SubscriptionHistoryDto>> GetHistoryAsync(Guid barberId)
    {
        return await _context.SubscriptionHistories
            .Include(h => h.PreviousPlan)
            .Include(h => h.NewPlan)
            .Where(h => h.BarberProfileId == barberId)
            .OrderByDescending(h => h.CreatedAt)
            .Select(h => new SubscriptionHistoryDto
            {
                Id = h.Id,
                Action = h.Action,
                PreviousPlanName = h.PreviousPlan != null ? h.PreviousPlan.NameArabic : null,
                NewPlanName = h.NewPlan.NameArabic,
                AmountPaid = h.AmountPaid,
                PaymentMethod = h.PaymentMethod,
                PaymentConfirmedBy = h.PaymentConfirmedBy,
                Notes = h.Notes,
                CreatedAt = h.CreatedAt
            })
            .ToListAsync();
    }

    public async Task<SubscriptionStatsDto> GetStatsAsync()
    {
        var now = DateTime.UtcNow;
        var monthStart = new DateTime(now.Year, now.Month, 1, 0, 0, 0, DateTimeKind.Utc);

        var allActive = await _context.BarberSubscriptions
            .Include(bs => bs.SubscriptionPlan)
            .Where(bs => bs.Status == "active")
            .ToListAsync();

        var activeCount = allActive.Count(bs => bs.EndDate > now);
        var basicCount = allActive.Count(bs => bs.SubscriptionPlan.Name == "basic");
        var proCount = allActive.Count(bs => bs.SubscriptionPlan.Name == "pro");
        var premiumCount = allActive.Count(bs => bs.SubscriptionPlan.Name == "premium");

        var monthlyRevenue = allActive
            .Where(bs => bs.StartDate >= monthStart)
            .Sum(bs => bs.AmountPaid);

        var expiredThisMonth = await _context.BarberSubscriptions
            .CountAsync(bs => bs.Status == "expired" && bs.EndDate >= monthStart && bs.EndDate < now);

        var newThisMonth = await _context.BarberSubscriptions
            .CountAsync(bs => bs.CreatedAt >= monthStart);

        return new SubscriptionStatsDto
        {
            TotalActiveSubscriptions = activeCount,
            TotalBasicSubscriptions = basicCount,
            TotalProSubscriptions = proCount,
            TotalPremiumSubscriptions = premiumCount,
            TotalMonthlyRevenue = monthlyRevenue,
            ExpiredThisMonth = expiredThisMonth,
            NewThisMonth = newThisMonth
        };
    }

    public async Task<List<CurrentSubscriptionDto>> GetAllSubscriptionsAsync(string? status = null, int page = 1, int pageSize = 20)
    {
        var query = _context.BarberSubscriptions
            .Include(bs => bs.SubscriptionPlan)
            .Include(bs => bs.BarberProfile)
                .ThenInclude(bp => bp.User)
            .AsQueryable();

        if (!string.IsNullOrEmpty(status))
            query = query.Where(bs => bs.Status == status);

        var subscriptions = await query
            .OrderByDescending(bs => bs.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        var result = new List<CurrentSubscriptionDto>();
        foreach (var sub in subscriptions)
        {
            var bookingCount = await GetMonthlyBookingCountAsync(sub.BarberProfileId);
            result.Add(new CurrentSubscriptionDto
            {
                SubscriptionId = sub.Id,
                PlanId = sub.SubscriptionPlanId,
                PlanName = sub.SubscriptionPlan.Name,
                PlanNameArabic = sub.SubscriptionPlan.NameArabic,
                AmountPaid = sub.AmountPaid,
                PaymentMethod = sub.PaymentMethod,
                Status = sub.Status,
                IsYearly = sub.IsYearly,
                StartDate = sub.StartDate,
                EndDate = sub.EndDate,
                MaxServices = sub.SubscriptionPlan.MaxServices,
                MaxPhotos = sub.SubscriptionPlan.MaxPhotos,
                MaxBookingsPerMonth = sub.SubscriptionPlan.MaxBookingsPerMonth,
                MaxEmployees = sub.SubscriptionPlan.MaxEmployees,
                AnalyticsLevel = sub.SubscriptionPlan.AnalyticsLevel,
                HasPromoCodes = sub.SubscriptionPlan.HasPromoCodes,
                HasPrioritySupport = sub.SubscriptionPlan.HasPrioritySupport,
                ShopName = sub.BarberProfile.ShopName,
                OwnerName = sub.BarberProfile.User.FullName,
                CurrentBookingsCount = bookingCount
            });
        }

        return result;
    }

    public async Task<CurrentSubscriptionDto?> GetSubscriptionByIdAsync(Guid subscriptionId)
    {
        var subscription = await _context.BarberSubscriptions
            .Include(bs => bs.SubscriptionPlan)
            .Include(bs => bs.BarberProfile)
            .FirstOrDefaultAsync(bs => bs.Id == subscriptionId);

        if (subscription == null) return null;

        var bookingCount = await GetMonthlyBookingCountAsync(subscription.BarberProfileId);
        return new CurrentSubscriptionDto
        {
            SubscriptionId = subscription.Id,
            PlanId = subscription.SubscriptionPlanId,
            PlanName = subscription.SubscriptionPlan.Name,
            PlanNameArabic = subscription.SubscriptionPlan.NameArabic,
            AmountPaid = subscription.AmountPaid,
            PaymentMethod = subscription.PaymentMethod,
            Status = subscription.Status,
            IsYearly = subscription.IsYearly,
            StartDate = subscription.StartDate,
            EndDate = subscription.EndDate,
            MaxServices = subscription.SubscriptionPlan.MaxServices,
            MaxPhotos = subscription.SubscriptionPlan.MaxPhotos,
            MaxBookingsPerMonth = subscription.SubscriptionPlan.MaxBookingsPerMonth,
            MaxEmployees = subscription.SubscriptionPlan.MaxEmployees,
            AnalyticsLevel = subscription.SubscriptionPlan.AnalyticsLevel,
            HasPromoCodes = subscription.SubscriptionPlan.HasPromoCodes,
            HasPrioritySupport = subscription.SubscriptionPlan.HasPrioritySupport,
            CurrentBookingsCount = bookingCount
        };
    }

    public async Task ExtendSubscriptionAsync(Guid subscriptionId, int days, string confirmedBy)
    {
        var subscription = await _context.BarberSubscriptions.FindAsync(subscriptionId);
        if (subscription == null)
            throw new InvalidOperationException("الاشتراك غير موجود");

        var previousEndDate = subscription.EndDate;
        subscription.EndDate = subscription.EndDate.AddDays(days);

        // Create history record
        var history = new SubscriptionHistory
        {
            BarberSubscriptionId = subscription.Id,
            BarberProfileId = subscription.BarberProfileId,
            Action = "extended",
            NewPlanId = subscription.SubscriptionPlanId,
            AmountPaid = 0,
            PaymentConfirmedBy = confirmedBy,
            Notes = $"تمديد الاشتراك {days} أيام. من {previousEndDate:yyyy-MM-dd} إلى {subscription.EndDate:yyyy-MM-dd}"
        };
        _context.SubscriptionHistories.Add(history);

        await _context.SaveChangesAsync();
    }

    public async Task ForceChangePlanAsync(Guid barberId, Guid planId, string confirmedBy)
    {
        var barber = await _context.BarberProfiles.FindAsync(barberId);
        if (barber == null)
            throw new InvalidOperationException("الحلاق غير موجود");

        var plan = await _context.SubscriptionPlans.FindAsync(planId);
        if (plan == null)
            throw new InvalidOperationException("الخطة غير موجودة");

        // Cancel current subscription
        var currentSubscription = await _context.BarberSubscriptions
            .FirstOrDefaultAsync(bs => bs.BarberProfileId == barberId && bs.Status == "active");
        if (currentSubscription != null)
            currentSubscription.Status = "cancelled";

        // Create new subscription
        var newSubscription = new BarberSubscription
        {
            BarberProfileId = barberId,
            SubscriptionPlanId = planId,
            StartDate = DateTime.UtcNow,
            EndDate = DateTime.UtcNow.AddMonths(1),
            IsYearly = false,
            AmountPaid = plan.MonthlyPrice,
            PaymentMethod = "admin_override",
            Status = "active"
        };
        _context.BarberSubscriptions.Add(newSubscription);

        // Update barber profile
        barber.SubscriptionPlan = plan.Name;

        // Create history record
        var history = new SubscriptionHistory
        {
            BarberSubscriptionId = newSubscription.Id,
            BarberProfileId = barberId,
            Action = "admin_override",
            NewPlanId = planId,
            AmountPaid = plan.MonthlyPrice,
            PaymentConfirmedBy = confirmedBy,
            Notes = $"تغيير خطة بواسطة المسؤول إلى {plan.NameArabic}"
        };
        _context.SubscriptionHistories.Add(history);

        await _context.SaveChangesAsync();
    }
}
