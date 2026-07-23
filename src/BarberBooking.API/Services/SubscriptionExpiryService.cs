using BarberBooking.Domain.Entities;
using BarberBooking.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace BarberBooking.API.Services;

public class SubscriptionExpiryService : BackgroundService
{
    private readonly IServiceProvider _serviceProvider;
    private readonly ILogger<SubscriptionExpiryService> _logger;

    public SubscriptionExpiryService(IServiceProvider serviceProvider, ILogger<SubscriptionExpiryService> logger)
    {
        _serviceProvider = serviceProvider;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await CheckExpiredSubscriptionsAsync();
                await Task.Delay(TimeSpan.FromHours(1), stoppingToken); // Check every hour
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error checking expired subscriptions");
                await Task.Delay(TimeSpan.FromMinutes(5), stoppingToken); // Retry after 5 minutes on error
            }
        }
    }

    private async Task CheckExpiredSubscriptionsAsync()
    {
        using var scope = _serviceProvider.CreateScope();
        var context = scope.ServiceProvider.GetRequiredService<BarberBookingDbContext>();

        var now = DateTime.UtcNow;

        var expiredSubscriptions = await context.BarberSubscriptions
            .Include(s => s.SubscriptionPlan)
            .Include(s => s.BarberProfile)
            .Where(s => (s.Status == "active" || s.Status == "cancel_pending") && s.EndDate < now)
            .ToListAsync();

        foreach (var subscription in expiredSubscriptions)
        {
            subscription.Status = "expired";

            if (!string.IsNullOrEmpty(subscription.BarberProfile.SubscriptionPlan) &&
                subscription.BarberProfile.SubscriptionPlan.ToLower() != "basic")
            {
                var history = new SubscriptionHistory
                {
                    BarberSubscriptionId = subscription.Id,
                    BarberProfileId = subscription.BarberProfileId,
                    Action = "expired",
                    PreviousPlanId = subscription.SubscriptionPlanId,
                    NewPlanId = subscription.SubscriptionPlanId,
                    AmountPaid = 0,
                    Notes = $"انتهى الاشتراك من {subscription.SubscriptionPlan.NameArabic}"
                };
                context.SubscriptionHistories.Add(history);
            }

            _logger.LogInformation("Subscription expired for barber {BarberId}, plan: {PlanName}, status was: {Status}",
                subscription.BarberProfileId, subscription.SubscriptionPlan.NameArabic, subscription.Status);
        }

        if (expiredSubscriptions.Any())
        {
            await context.SaveChangesAsync();
            _logger.LogInformation("Processed {Count} expired subscriptions", expiredSubscriptions.Count);
        }
    }
}
