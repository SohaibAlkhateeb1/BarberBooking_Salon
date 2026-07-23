using BarberBooking.Application.DTOs.Subscription;

namespace BarberBooking.Application.Interfaces;

public interface ISubscriptionService
{
    // Plans
    Task<List<SubscriptionPlanDto>> GetPlansAsync();
    Task<SubscriptionPlanDto?> GetPlanByIdAsync(Guid planId);
    Task<SubscriptionPlanDto?> GetPlanByNameAsync(string name);

    // Current Subscription
    Task<CurrentSubscriptionDto?> GetCurrentSubscriptionAsync(Guid barberId);
    Task<CurrentSubscriptionDto> SubscribeAsync(Guid barberId, SubscribeRequestDto request);
    Task<CurrentSubscriptionDto> UpgradeAsync(Guid barberId, UpgradeRequestDto request);
    Task CancelAsync(Guid barberId);

    // Booking Limits
    Task<BookingLimitStatusDto> GetBookingLimitStatusAsync(Guid barberId);
    Task<int> GetMonthlyBookingCountAsync(Guid barberId);
    Task<int> GetBookingLimitAsync(Guid barberId);

    // Feature Checks
    Task<bool> CanAddServiceAsync(Guid barberId);
    Task<bool> CanAddPhotoAsync(Guid barberId);
    Task<bool> CanAddEmployeeAsync(Guid barberId);
    Task<bool> CanUseAnalyticsAsync(Guid barberId);
    Task<bool> CanUsePromoCodesAsync(Guid barberId);
    Task<bool> HasPrioritySupportAsync(Guid barberId);

    // History
    Task<List<SubscriptionHistoryDto>> GetHistoryAsync(Guid barberId);

    // Admin
    Task<SubscriptionStatsDto> GetStatsAsync();
    Task<List<CurrentSubscriptionDto>> GetAllSubscriptionsAsync(string? status = null, int page = 1, int pageSize = 20);
    Task<CurrentSubscriptionDto?> GetSubscriptionByIdAsync(Guid subscriptionId);
    Task ExtendSubscriptionAsync(Guid subscriptionId, int days, string confirmedBy);
    Task ForceChangePlanAsync(Guid barberId, Guid planId, string confirmedBy);
}
