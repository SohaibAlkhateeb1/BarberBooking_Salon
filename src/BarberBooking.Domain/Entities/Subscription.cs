namespace BarberBooking.Domain.Entities;

public class SubscriptionPlan : BaseEntity
{
    public string Name { get; set; } = string.Empty;
    public string NameArabic { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public decimal MonthlyPrice { get; set; }
    public decimal YearlyPrice { get; set; }
    public int MaxServices { get; set; }
    public int MaxPhotos { get; set; }
    public int MaxBookingsPerMonth { get; set; }
    public int MaxEmployees { get; set; }
    public string AnalyticsLevel { get; set; } = "none"; // none, basic, advanced
    public bool HasPromoCodes { get; set; }
    public bool HasPrioritySupport { get; set; }
    public bool IsActive { get; set; } = true;
}

public class BarberSubscription : BaseEntity
{
    public Guid BarberProfileId { get; set; }
    public Guid SubscriptionPlanId { get; set; }
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public bool IsYearly { get; set; }
    public decimal AmountPaid { get; set; }
    public string PaymentMethod { get; set; } = "cash";
    public string Status { get; set; } = "active"; // active, expired, cancelled
    public string? PaymentConfirmedBy { get; set; }
    public DateTime? PaymentConfirmedAt { get; set; }

    public BarberProfile BarberProfile { get; set; } = null!;
    public SubscriptionPlan SubscriptionPlan { get; set; } = null!;
}

public class SubscriptionHistory : BaseEntity
{
    public Guid BarberSubscriptionId { get; set; }
    public Guid BarberProfileId { get; set; }
    public string Action { get; set; } = string.Empty; // created, upgraded, downgraded, cancelled, expired, extended
    public Guid? PreviousPlanId { get; set; }
    public Guid NewPlanId { get; set; }
    public decimal AmountPaid { get; set; }
    public string PaymentMethod { get; set; } = "cash";
    public string? PaymentConfirmedBy { get; set; }
    public string? Notes { get; set; }

    public BarberSubscription BarberSubscription { get; set; } = null!;
    public BarberProfile BarberProfile { get; set; } = null!;
    public SubscriptionPlan? PreviousPlan { get; set; }
    public SubscriptionPlan NewPlan { get; set; } = null!;
}

public class BarberEmployee : BaseEntity
{
    public Guid BarberProfileId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string PhoneNumber { get; set; } = string.Empty;
    public string? ProfileImageUrl { get; set; }
    public bool IsActive { get; set; } = true;

    public BarberProfile BarberProfile { get; set; } = null!;
    public ICollection<EmployeeSchedule> Schedules { get; set; } = new List<EmployeeSchedule>();
    public ICollection<EmployeeService> EmployeeServices { get; set; } = new List<EmployeeService>();
}
