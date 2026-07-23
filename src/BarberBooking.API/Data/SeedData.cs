using BarberBooking.Domain.Entities;
using BarberBooking.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace BarberBooking.API.Data;

public static class SeedData
{
    public static async Task SeedAsync(BarberBookingDbContext context)
    {
        // ===== SUBSCRIPTION PLANS =====
        if (!await context.SubscriptionPlans.AnyAsync())
        {
            var plans = new List<SubscriptionPlan>
            {
                new()
                {
                    Id = Guid.NewGuid(),
                    Name = "basic",
                    NameArabic = "الأساسية",
                    Description = "للحلاقين المستقلين والصالونات الصغيرة",
                    MonthlyPrice = 80,
                    YearlyPrice = 800,
                    MaxServices = 5,
                    MaxPhotos = 5,
                    MaxBookingsPerMonth = 150,
                    MaxEmployees = 0,
                    AnalyticsLevel = "none",
                    HasPrioritySupport = false,
                    HasPromoCodes = false
                },
                new()
                {
                    Id = Guid.NewGuid(),
                    Name = "pro",
                    NameArabic = "الاحترافية",
                    Description = "الخيار الأمثل للصالونات المتطورة",
                    MonthlyPrice = 100,
                    YearlyPrice = 1000,
                    MaxServices = 10,
                    MaxPhotos = 15,
                    MaxBookingsPerMonth = 250,
                    MaxEmployees = 3,
                    AnalyticsLevel = "basic",
                    HasPrioritySupport = false,
                    HasPromoCodes = true
                },
                new()
                {
                    Id = Guid.NewGuid(),
                    Name = "premium",
                    NameArabic = "VIP",
                    Description = "للصالونات الكبيرة وسلاسل الحلاقة",
                    MonthlyPrice = 150,
                    YearlyPrice = 1500,
                    MaxServices = 15,
                    MaxPhotos = 30,
                    MaxBookingsPerMonth = 350,
                    MaxEmployees = 10,
                    AnalyticsLevel = "advanced",
                    HasPrioritySupport = true,
                    HasPromoCodes = true
                }
            };
            context.SubscriptionPlans.AddRange(plans);
            await context.SaveChangesAsync();
        }
    }
}
