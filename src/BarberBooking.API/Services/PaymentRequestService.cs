using BarberBooking.Application.DTOs.Payment;
using BarberBooking.Application.Interfaces;
using BarberBooking.Domain.Entities;
using BarberBooking.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace BarberBooking.API.Services;

public class PaymentRequestService : IPaymentRequestService
{
    private readonly BarberBookingDbContext _context;

    public PaymentRequestService(BarberBookingDbContext context)
    {
        _context = context;
    }

    public async Task<PaymentRequestDto> CreatePaymentRequestAsync(Guid barberProfileId, CreatePaymentRequestDto dto)
    {
        var barberProfile = await _context.BarberProfiles
            .Include(bp => bp.User)
            .FirstOrDefaultAsync(bp => bp.Id == barberProfileId);

        if (barberProfile == null)
            throw new InvalidOperationException("الحلاق غير موجود");

        var latestRequest = await _context.PaymentRequests
            .Where(pr => pr.BarberProfileId == barberProfileId && pr.Status == "pending")
            .FirstOrDefaultAsync();

        if (latestRequest != null)
            throw new InvalidOperationException("لديك طلب دفع قيد المراجعة بالفعل");

        string planName;
        decimal amount;

        if (dto.IsUpgrade && !string.IsNullOrEmpty(dto.PlanName))
        {
            planName = dto.PlanName;
            amount = dto.Amount ?? 0;
        }
        else
        {
            planName = dto.PlanName ?? barberProfile.SubscriptionPlan ?? "basic";
            var plan = await _context.SubscriptionPlans
                .FirstOrDefaultAsync(p => p.Name.ToLower() == planName.ToLower());
            if (plan == null)
                throw new InvalidOperationException("الخطة غير موجودة");
            amount = dto.IsYearly ? plan.YearlyPrice : plan.MonthlyPrice;
        }

        var paymentRequest = new PaymentRequest
        {
            BarberProfileId = barberProfileId,
            PaymentMethod = dto.PaymentMethod,
            Amount = amount,
            PlanName = planName,
            IsYearly = dto.IsYearly,
            ReceiptImageUrl = dto.ReceiptImageUrl,
            Status = "pending",
            IsUpgrade = dto.IsUpgrade,
            FromPlanName = dto.FromPlanName
        };

        _context.PaymentRequests.Add(paymentRequest);
        await _context.SaveChangesAsync();

        return MapToDto(paymentRequest);
    }

    public async Task<List<PaymentRequestDto>> GetMyPaymentRequestsAsync(Guid barberProfileId)
    {
        return await _context.PaymentRequests
            .Where(pr => pr.BarberProfileId == barberProfileId)
            .OrderByDescending(pr => pr.CreatedAt)
            .Select(pr => new PaymentRequestDto
            {
                Id = pr.Id,
                PaymentMethod = pr.PaymentMethod,
                Amount = pr.Amount,
                PlanName = pr.PlanName,
                IsYearly = pr.IsYearly,
                ReceiptImageUrl = pr.ReceiptImageUrl,
                Status = pr.Status,
                AdminNotes = pr.AdminNotes,
                CreatedAt = pr.CreatedAt,
                ReviewedAt = pr.ReviewedAt
            })
            .ToListAsync();
    }

    public async Task<PaymentRequestDto?> GetPaymentRequestByIdAsync(Guid id)
    {
        var pr = await _context.PaymentRequests.FindAsync(id);
        if (pr == null) return null;
        return MapToDto(pr);
    }

    public async Task<List<PaymentRequestWithBarberDto>> GetAllPaymentRequestsAsync(string? status, int page = 1, int pageSize = 20)
    {
        var query = _context.PaymentRequests
            .Include(pr => pr.BarberProfile)
                .ThenInclude(bp => bp.User)
            .AsQueryable();

        if (!string.IsNullOrEmpty(status))
            query = query.Where(pr => pr.Status == status);

        return await query
            .OrderByDescending(pr => pr.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(pr => new PaymentRequestWithBarberDto
            {
                Id = pr.Id,
                PaymentMethod = pr.PaymentMethod,
                Amount = pr.Amount,
                PlanName = pr.PlanName,
                IsYearly = pr.IsYearly,
                ReceiptImageUrl = pr.ReceiptImageUrl,
                Status = pr.Status,
                AdminNotes = pr.AdminNotes,
                CreatedAt = pr.CreatedAt,
                ReviewedAt = pr.ReviewedAt,
                IsUpgrade = pr.IsUpgrade,
                FromPlanName = pr.FromPlanName,
                BarberName = pr.BarberProfile.User.FullName,
                ShopName = pr.BarberProfile.ShopName,
                PhoneNumber = pr.BarberProfile.User.PhoneNumber
            })
            .ToListAsync();
    }

    public async Task<int> GetPendingPaymentRequestsCountAsync()
    {
        return await _context.PaymentRequests
            .CountAsync(pr => pr.Status == "pending");
    }

    public async Task<PaymentRequestDto> ReviewPaymentRequestAsync(Guid requestId, ReviewPaymentRequestDto dto, Guid reviewedById)
    {
        var paymentRequest = await _context.PaymentRequests
            .Include(pr => pr.BarberProfile)
                .ThenInclude(bp => bp.User)
            .FirstOrDefaultAsync(pr => pr.Id == requestId);

        if (paymentRequest == null)
            throw new InvalidOperationException("طلب الدفع غير موجود");

        if (paymentRequest.Status != "pending")
            throw new InvalidOperationException("تم مراجعة هذا الطلب بالفعل");

        paymentRequest.Status = dto.Status;
        paymentRequest.AdminNotes = dto.AdminNotes;
        paymentRequest.ReviewedAt = DateTime.UtcNow;
        paymentRequest.ReviewedById = reviewedById;

        if (dto.Status == "approved")
        {
            var barberProfile = paymentRequest.BarberProfile;

            var plan = await _context.SubscriptionPlans
                .FirstOrDefaultAsync(p => p.Name.ToLower() == paymentRequest.PlanName.ToLower());

            if (plan != null)
            {
                if (paymentRequest.IsUpgrade)
                {
                    var activeSub = await _context.BarberSubscriptions
                        .Where(bs => bs.BarberProfileId == paymentRequest.BarberProfileId && bs.Status == "active")
                        .FirstOrDefaultAsync();

                    if (activeSub != null)
                    {
                        activeSub.Status = "cancelled";
                    }
                }
                else
                {
                    var oldSub = await _context.BarberSubscriptions
                        .Where(bs => bs.BarberProfileId == paymentRequest.BarberProfileId && (bs.Status == "cancel_pending" || bs.Status == "expired"))
                        .FirstOrDefaultAsync();

                    if (oldSub != null)
                    {
                        oldSub.Status = "expired";
                    }
                }

                var endDate = paymentRequest.IsYearly
                    ? DateTime.UtcNow.AddYears(1)
                    : DateTime.UtcNow.AddMonths(1);

                var subscription = new BarberSubscription
                {
                    BarberProfileId = paymentRequest.BarberProfileId,
                    SubscriptionPlanId = plan.Id,
                    StartDate = DateTime.UtcNow,
                    EndDate = endDate,
                    IsYearly = paymentRequest.IsYearly,
                    AmountPaid = paymentRequest.Amount,
                    PaymentMethod = paymentRequest.PaymentMethod,
                    Status = "active",
                    PaymentConfirmedBy = "admin",
                    PaymentConfirmedAt = DateTime.UtcNow
                };

                _context.BarberSubscriptions.Add(subscription);

                barberProfile.SubscriptionPlan = paymentRequest.PlanName;
                barberProfile.IsYearly = paymentRequest.IsYearly;

                barberProfile.User.IsActive = true;

                string notifMessage;
                string notifTitle;
                if (paymentRequest.IsUpgrade)
                {
                    notifMessage = $"تم ترقية اشتراكك إلى خطة {plan.NameArabic}. يمكنك الآن استخدام جميع مزايا الخطة الجديدة.";
                    notifTitle = "تم ترقية اشتراكك";
                }
                else
                {
                    notifMessage = $"تم تجديد اشتراكك على خطة {plan.NameArabic}. يمكنك الآن استخدام جميع مزايا الخطة.";
                    notifTitle = "تم تجديد اشتراكك";
                }

                var notification = new Notification
                {
                    UserId = barberProfile.UserId,
                    Title = notifTitle,
                    Message = notifMessage,
                    Type = "subscription",
                    IsRead = false
                };
                _context.Notifications.Add(notification);
            }
        }
        else if (dto.Status == "rejected")
        {
            var notification = new Notification
            {
                UserId = paymentRequest.BarberProfile.UserId,
                Title = "تم رفض طلب الدفع",
                Message = $"تم رفض طلب الدفع. السبب: {dto.AdminNotes ?? "غير محدد"}. يرجى المحاولة مرة أخرى.",
                Type = "subscription",
                IsRead = false
            };
            _context.Notifications.Add(notification);
        }

        await _context.SaveChangesAsync();

        return MapToDto(paymentRequest);
    }

    private static PaymentRequestDto MapToDto(PaymentRequest pr)
    {
        return new PaymentRequestDto
        {
            Id = pr.Id,
            PaymentMethod = pr.PaymentMethod,
            Amount = pr.Amount,
            PlanName = pr.PlanName,
            IsYearly = pr.IsYearly,
            ReceiptImageUrl = pr.ReceiptImageUrl,
            Status = pr.Status,
            AdminNotes = pr.AdminNotes,
            CreatedAt = pr.CreatedAt,
            ReviewedAt = pr.ReviewedAt,
            IsUpgrade = pr.IsUpgrade,
            FromPlanName = pr.FromPlanName
        };
    }
}
