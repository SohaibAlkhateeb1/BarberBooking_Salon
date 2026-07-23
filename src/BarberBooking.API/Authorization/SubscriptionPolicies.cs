using Microsoft.AspNetCore.Authorization;

namespace BarberBooking.API.Authorization;

public static class SubscriptionPolicies
{
    public const string CanAddService = "CanAddService";
    public const string CanAddPhoto = "CanAddPhoto";
    public const string CanAddEmployee = "CanAddEmployee";
    public const string CanUseAnalytics = "CanUseAnalytics";
    public const string CanUsePromoCodes = "CanUsePromoCodes";
    public const string HasPrioritySupport = "HasPrioritySupport";

    public static void AddSubscriptionPolicies(this IServiceCollection services)
    {
        services.AddSingleton<IAuthorizationHandler, FeatureHandler>();

        services.AddAuthorization(options =>
        {
            options.AddPolicy(CanAddService, policy =>
                policy.Requirements.Add(new FeatureRequirement(SubscriptionFeature.AddService)));

            options.AddPolicy(CanAddPhoto, policy =>
                policy.Requirements.Add(new FeatureRequirement(SubscriptionFeature.AddPhoto)));

            options.AddPolicy(CanAddEmployee, policy =>
                policy.Requirements.Add(new FeatureRequirement(SubscriptionFeature.AddEmployee)));

            options.AddPolicy(CanUseAnalytics, policy =>
                policy.Requirements.Add(new FeatureRequirement(SubscriptionFeature.UseAnalytics)));

            options.AddPolicy(CanUsePromoCodes, policy =>
                policy.Requirements.Add(new FeatureRequirement(SubscriptionFeature.UsePromoCodes)));

            options.AddPolicy(HasPrioritySupport, policy =>
                policy.Requirements.Add(new FeatureRequirement(SubscriptionFeature.PrioritySupport)));
        });
    }
}
