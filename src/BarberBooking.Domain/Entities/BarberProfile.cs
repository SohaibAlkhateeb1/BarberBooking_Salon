namespace BarberBooking.Domain.Entities;

public class BarberProfile : BaseEntity
{
    public Guid UserId { get; set; }
    public string ShopName { get; set; } = string.Empty;
    public string? ShopDescription { get; set; }
    public string? ShopLogoUrl { get; set; }
    public string? CoverImageUrl { get; set; }
    public string City { get; set; } = string.Empty;
    public string Address { get; set; } = string.Empty;
    public double? Latitude { get; set; }
    public double? Longitude { get; set; }
    public string? WhatsAppNumber { get; set; }
    public string? InstagramHandle { get; set; }
    public string? TikTokHandle { get; set; }
    public string SubscriptionPlan { get; set; } = "basic";
    public bool IsYearly { get; set; }
    public string? FcmToken { get; set; }

    public User User { get; set; } = null!;
    public ICollection<BarberService> Services { get; set; } = new List<BarberService>();
    public ICollection<WorkingHour> WorkingHours { get; set; } = new List<WorkingHour>();
    public ICollection<Booking> Bookings { get; set; } = new List<Booking>();
    public ICollection<Review> Reviews { get; set; } = new List<Review>();
    public ICollection<Favorite> Favorites { get; set; } = new List<Favorite>();
    public ICollection<BarberPortfolioImage> PortfolioImages { get; set; } = new List<BarberPortfolioImage>();
    public ICollection<BarberEmployee> Employees { get; set; } = new List<BarberEmployee>();
    public ICollection<BarberSubscription> Subscriptions { get; set; } = new List<BarberSubscription>();
}
