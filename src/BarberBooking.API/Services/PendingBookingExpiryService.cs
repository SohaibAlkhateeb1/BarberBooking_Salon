using BarberBooking.Domain.Entities;
using BarberBooking.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace BarberBooking.API.Services;

public class PendingBookingExpiryService : BackgroundService
{
    private readonly IServiceProvider _serviceProvider;
    private readonly ILogger<PendingBookingExpiryService> _logger;

    public PendingBookingExpiryService(IServiceProvider serviceProvider, ILogger<PendingBookingExpiryService> logger)
    {
        _serviceProvider = serviceProvider;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await CheckPendingBookingsAsync();
                await Task.Delay(TimeSpan.FromMinutes(1), stoppingToken);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error checking pending bookings");
                await Task.Delay(TimeSpan.FromMinutes(2), stoppingToken);
            }
        }
    }

    private async Task CheckPendingBookingsAsync()
    {
        using var scope = _serviceProvider.CreateScope();
        var context = scope.ServiceProvider.GetRequiredService<BarberBookingDbContext>();

        var cutoff = DateTime.UtcNow.AddMinutes(-30);

        var expiredBookings = await context.Bookings
            .Include(b => b.Customer)
            .Include(b => b.BarberService)
            .Where(b => b.Status == "Pending" && b.CreatedAt < cutoff)
            .ToListAsync();

        foreach (var booking in expiredBookings)
        {
            booking.Status = "Expired";

            context.Notifications.Add(new Notification
            {
                UserId = booking.CustomerId,
                Title = "انتهت صلاحية طلب الحجز",
                Message = $"لم يتم تأكيد موعدك — {booking.BarberService.Name} يوم {booking.BookingDate:yyyy-MM-dd}. يرجى المحاولة مرة أخرى.",
                Type = "booking",
                IsRead = false,
                Data = booking.Id.ToString()
            });

            _logger.LogInformation("Booking expired for customer {CustomerId}, service: {ServiceName}",
                booking.CustomerId, booking.BarberService.Name);
        }

        if (expiredBookings.Any())
        {
            await context.SaveChangesAsync();
            _logger.LogInformation("Processed {Count} expired pending bookings", expiredBookings.Count);
        }
    }
}
