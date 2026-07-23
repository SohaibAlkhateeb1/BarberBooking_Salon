namespace BarberBooking.Application.DTOs.Auth;

public class RegisterBarberDto
{
    public string FullName { get; set; } = string.Empty;
    public string PhoneNumber { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
    public string ShopName { get; set; } = string.Empty;
    public string? ShopDescription { get; set; }
    public string? ProfileImageUrl { get; set; }
    public string? ShopLogoUrl { get; set; }
    public string City { get; set; } = string.Empty;
    public string Address { get; set; } = string.Empty;
    public double? Latitude { get; set; }
    public double? Longitude { get; set; }
    public string SubscriptionPlan { get; set; } = "basic";
    public bool IsYearly { get; set; }
    public List<BarberServiceDto> Services { get; set; } = new();
    public List<WorkingHourDto> WorkingHours { get; set; } = new();
    public bool AcceptTerms { get; set; }
}

public class BarberServiceDto
{
    public string Name { get; set; } = string.Empty;
    public decimal Price { get; set; }
    public int DurationInMinutes { get; set; }
}

public class WorkingHourDto
{
    public string DayName { get; set; } = string.Empty;
    public bool IsOpen { get; set; }
    public string OpenTime { get; set; } = string.Empty;
    public string CloseTime { get; set; } = string.Empty;
}
