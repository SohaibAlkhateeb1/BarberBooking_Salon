using Microsoft.AspNetCore.Authorization;

namespace BarberBooking.API.Authorization;

public enum SubscriptionFeature
{
    AddService,
    AddPhoto,
    AddEmployee,
    UseAnalytics,
    UsePromoCodes,
    PrioritySupport
}

public class FeatureRequirement : IAuthorizationRequirement
{
    public SubscriptionFeature Feature { get; }

    public FeatureRequirement(SubscriptionFeature feature)
    {
        Feature = feature;
    }
}
