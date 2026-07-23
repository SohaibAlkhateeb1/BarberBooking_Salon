using BarberBooking.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace BarberBooking.Infrastructure.Data;

public class BarberBookingDbContext : DbContext
{
    public BarberBookingDbContext(DbContextOptions<BarberBookingDbContext> options)
        : base(options)
    {
    }

    public DbSet<User> Users => Set<User>();
    public DbSet<BarberProfile> BarberProfiles => Set<BarberProfile>();
    public DbSet<BarberService> BarberServices => Set<BarberService>();
    public DbSet<WorkingHour> WorkingHours => Set<WorkingHour>();
    public DbSet<Booking> Bookings => Set<Booking>();
    public DbSet<Review> Reviews => Set<Review>();
    public DbSet<Favorite> Favorites => Set<Favorite>();
    public DbSet<RefreshToken> RefreshTokens => Set<RefreshToken>();
    public DbSet<RevokedToken> RevokedTokens => Set<RevokedToken>();
    public DbSet<OtpCode> OtpCodes => Set<OtpCode>();
    public DbSet<PromoCode> PromoCodes => Set<PromoCode>();
    public DbSet<Notification> Notifications => Set<Notification>();
    public DbSet<SubscriptionPlan> SubscriptionPlans => Set<SubscriptionPlan>();
    public DbSet<BarberSubscription> BarberSubscriptions => Set<BarberSubscription>();
    public DbSet<BarberPortfolioImage> PortfolioImages => Set<BarberPortfolioImage>();
    public DbSet<SubscriptionHistory> SubscriptionHistories => Set<SubscriptionHistory>();
    public DbSet<BarberEmployee> BarberEmployees => Set<BarberEmployee>();
    public DbSet<EmployeeSchedule> EmployeeSchedules => Set<EmployeeSchedule>();
    public DbSet<EmployeeService> EmployeeServices => Set<EmployeeService>();
    public DbSet<PaymentRequest> PaymentRequests => Set<PaymentRequest>();
    public DbSet<SupportTicket> SupportTickets => Set<SupportTicket>();
    public DbSet<TicketReply> TicketReplies => Set<TicketReply>();
    public DbSet<SystemAlert> SystemAlerts => Set<SystemAlert>();
    public DbSet<AuditLog> AuditLogs => Set<AuditLog>();
    public DbSet<UserDevice> UserDevices => Set<UserDevice>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(BarberBookingDbContext).Assembly);
    }

    public override Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        foreach (var entry in ChangeTracker.Entries<BaseEntity>())
        {
            switch (entry.State)
            {
                case EntityState.Added:
                    entry.Entity.CreatedAt = DateTime.UtcNow;
                    break;
                case EntityState.Modified:
                    entry.Entity.UpdatedAt = DateTime.UtcNow;
                    break;
            }
        }

        return base.SaveChangesAsync(cancellationToken);
    }
}
