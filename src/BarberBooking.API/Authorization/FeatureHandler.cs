using System.Security.Claims;
using BarberBooking.Application.Interfaces;
using BarberBooking.Infrastructure.Data;
using Microsoft.AspNetCore.Authorization;
using Microsoft.EntityFrameworkCore;

namespace BarberBooking.API.Authorization;

public class FeatureHandler : AuthorizationHandler<FeatureRequirement>
{
    private readonly IServiceScopeFactory _scopeFactory;

    public FeatureHandler(IServiceScopeFactory scopeFactory)
    {
        _scopeFactory = scopeFactory;
    }

    protected override async Task HandleRequirementAsync(
        AuthorizationHandlerContext context,
        FeatureRequirement requirement)
    {
        var userId = context.User.FindFirst(ClaimTypes.NameIdentifier)?.Value
                     ?? context.User.FindFirst("sub")?.Value;

        if (string.IsNullOrEmpty(userId))
        {
            context.Fail();
            return;
        }

        if (context.User.IsInRole("Admin"))
        {
            context.Succeed(requirement);
            return;
        }

        using var scope = _scopeFactory.CreateScope();
        var subscriptionService = scope.ServiceProvider.GetRequiredService<ISubscriptionService>();
        var dbContext = scope.ServiceProvider.GetRequiredService<BarberBookingDbContext>();

        var barberId = await GetBarberIdAsync(dbContext, userId);
        if (barberId == null)
        {
            context.Fail();
            return;
        }

        var allowed = requirement.Feature switch
        {
            SubscriptionFeature.AddService => await subscriptionService.CanAddServiceAsync(barberId.Value),
            SubscriptionFeature.AddPhoto => await subscriptionService.CanAddPhotoAsync(barberId.Value),
            SubscriptionFeature.AddEmployee => await subscriptionService.CanAddEmployeeAsync(barberId.Value),
            SubscriptionFeature.UseAnalytics => await subscriptionService.CanUseAnalyticsAsync(barberId.Value),
            SubscriptionFeature.UsePromoCodes => await subscriptionService.CanUsePromoCodesAsync(barberId.Value),
            SubscriptionFeature.PrioritySupport => await subscriptionService.HasPrioritySupportAsync(barberId.Value),
            _ => false
        };

        if (allowed)
            context.Succeed(requirement);
        else
            context.Fail();
    }

    private async Task<Guid?> GetBarberIdAsync(BarberBookingDbContext context, string userId)
    {
        if (!Guid.TryParse(userId, out var userGuid))
            return null;

        var profile = await context.BarberProfiles
            .FirstOrDefaultAsync(bp => bp.UserId == userGuid);

        return profile?.Id;
    }
}
