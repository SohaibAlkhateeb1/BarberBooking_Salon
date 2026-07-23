namespace BarberBooking.Application.DTOs.Subscription;

public class SubscriptionPlanDto
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string NameArabic { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public decimal MonthlyPrice { get; set; }
    public decimal YearlyPrice { get; set; }
    public int MaxServices { get; set; }
    public int MaxPhotos { get; set; }
    public int MaxBookingsPerMonth { get; set; }
    public int MaxEmployees { get; set; }
    public string AnalyticsLevel { get; set; } = "none";
    public bool HasPromoCodes { get; set; }
    public bool HasPrioritySupport { get; set; }
    public bool IsActive { get; set; }
    public int DiscountPercentage => MonthlyPrice > 0 ? (int)((1 - YearlyPrice / (MonthlyPrice * 12)) * 100) : 0;
}
