namespace BarberBooking.Application.DTOs.Subscription;

public class CurrentSubscriptionDto
{
    public Guid SubscriptionId { get; set; }
    public Guid PlanId { get; set; }
    public string PlanName { get; set; } = string.Empty;
    public string PlanNameArabic { get; set; } = string.Empty;
    public decimal AmountPaid { get; set; }
    public string PaymentMethod { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public bool IsYearly { get; set; }
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public int DaysRemaining => Math.Max(0, (EndDate - DateTime.UtcNow).Days);
    public bool IsExpiringSoon => DaysRemaining <= 7;
    public bool IsExpired => EndDate < DateTime.UtcNow;

    // Plan features
    public int MaxServices { get; set; }
    public int MaxPhotos { get; set; }
    public int MaxBookingsPerMonth { get; set; }
    public int MaxEmployees { get; set; }
    public string AnalyticsLevel { get; set; } = "none";
    public bool HasPromoCodes { get; set; }
    public bool HasPrioritySupport { get; set; }

    // Barber info
    public string ShopName { get; set; } = string.Empty;
    public string OwnerName { get; set; } = string.Empty;

    // Current usage
    public int CurrentServicesCount { get; set; }
    public int CurrentPhotosCount { get; set; }
    public int CurrentBookingsCount { get; set; }
    public int CurrentEmployeesCount { get; set; }
    public string BookingLimitStatus { get; set; } = "normal"; // normal, warning, limit_reached
}

public class SubscribeRequestDto
{
    public Guid PlanId { get; set; }
    public bool IsYearly { get; set; }
}

public class UpgradeRequestDto
{
    public Guid NewPlanId { get; set; }
    public string PaymentMethod { get; set; } = "cash";
}

public class SubscriptionHistoryDto
{
    public Guid Id { get; set; }
    public string Action { get; set; } = string.Empty;
    public string? PreviousPlanName { get; set; }
    public string NewPlanName { get; set; } = string.Empty;
    public decimal AmountPaid { get; set; }
    public string PaymentMethod { get; set; } = string.Empty;
    public string? PaymentConfirmedBy { get; set; }
    public string? Notes { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class SubscriptionStatsDto
{
    public int TotalActiveSubscriptions { get; set; }
    public int TotalBasicSubscriptions { get; set; }
    public int TotalProSubscriptions { get; set; }
    public int TotalPremiumSubscriptions { get; set; }
    public decimal TotalMonthlyRevenue { get; set; }
    public decimal TotalYearlyRevenue { get; set; }
    public int ExpiredThisMonth { get; set; }
    public int NewThisMonth { get; set; }
}

public class BookingLimitStatusDto
{
    public int CurrentCount { get; set; }
    public int Limit { get; set; }
    public string Status { get; set; } = "normal"; // normal, warning, limit_reached
    public double Percentage => Limit > 0 ? (double)CurrentCount / Limit * 100 : 0;
    public bool CanBook => Limit < 0 || CurrentCount < Limit; // -1 = unlimited
}

public class EmployeeDto
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string PhoneNumber { get; set; } = string.Empty;
    public string? ProfileImageUrl { get; set; }
    public bool IsActive { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class CreateEmployeeRequestDto
{
    public string Name { get; set; } = string.Empty;
    public string PhoneNumber { get; set; } = string.Empty;
    public string? ProfileImageUrl { get; set; }
}

public class UpdateEmployeeRequestDto
{
    public string? Name { get; set; }
    public string? PhoneNumber { get; set; }
    public string? ProfileImageUrl { get; set; }
    public bool? IsActive { get; set; }
}

public class UpdateEmployeeScheduleDto
{
    public List<EmployeeScheduleDayDto> Days { get; set; } = new();
}

public class EmployeeScheduleDayDto
{
    public string DayName { get; set; } = string.Empty;
    public bool IsOpen { get; set; }
    public string OpenTime { get; set; } = "09:00";
    public string CloseTime { get; set; } = "17:00";
}

public class EmployeeServicesDto
{
    public Guid EmployeeId { get; set; }
    public string EmployeeName { get; set; } = string.Empty;
    public List<EmployeeServiceItemDto> AllServices { get; set; } = new();
}

public class EmployeeServiceItemDto
{
    public Guid ServiceId { get; set; }
    public string ServiceName { get; set; } = string.Empty;
    public decimal Price { get; set; }
    public int DurationMinutes { get; set; }
    public bool IsAssigned { get; set; }
}

public class UpdateEmployeeServicesDto
{
    public List<Guid> ServiceIds { get; set; } = new();
}
