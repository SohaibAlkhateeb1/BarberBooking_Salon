using BarberBooking.Domain.Entities;
using BarberBooking.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace BarberBooking.API.Services;

public class BookingReminderService : BackgroundService
{
    private readonly IServiceProvider _serviceProvider;
    private readonly ILogger<BookingReminderService> _logger;
    private static readonly TimeZoneInfo PalestineTimeZone = TimeZoneInfo.FindSystemTimeZoneById("Asia/Hebron");
    private bool _isRunning = false;

    public BookingReminderService(IServiceProvider serviceProvider, ILogger<BookingReminderService> logger)
    {
        _serviceProvider = serviceProvider;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            if (!_isRunning)
            {
                try
                {
                    _isRunning = true;
                    await CheckAndSendReminders();
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error in BookingReminderService");
                }
                finally
                {
                    _isRunning = false;
                }
            }

            await Task.Delay(TimeSpan.FromMinutes(2), stoppingToken);
        }
    }

    private async Task CheckAndSendReminders()
    {
        using var scope = _serviceProvider.CreateScope();
        var context = scope.ServiceProvider.GetRequiredService<BarberBookingDbContext>();
        var fcm = scope.ServiceProvider.GetRequiredService<IFirebasePushService>();

        var nowLocal = TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, PalestineTimeZone);
        var reminderWindow = nowLocal.AddMinutes(30);
        var fiveMinutesAgo = nowLocal.AddMinutes(-5);

        var upcomingBookings = await context.Bookings
            .Include(b => b.BarberProfile)
                .ThenInclude(bp => bp.User)
            .Include(b => b.Customer)
            .Include(b => b.BarberService)
            .Where(b => b.Status == "Pending" || b.Status == "Accepted" || b.Status == "InProgress")
            .ToListAsync();

        foreach (var booking in upcomingBookings)
        {
            var bookingLocal = booking.BookingDate.Date + booking.BookingTime;

            if (bookingLocal > fiveMinutesAgo && bookingLocal <= reminderWindow)
            {
                var timeUntil = bookingLocal - nowLocal;
                var timeText = timeUntil.TotalMinutes < 1
                    ? "الآن"
                    : $"بعد {(int)timeUntil.TotalMinutes} دقيقة";

                // --- Customer reminder ---
                var customerAlreadyReminded = await context.Notifications
                    .AnyAsync(n => n.UserId == booking.CustomerId
                        && (n.Type == "reminder" || n.Type == "service_reminder")
                        && n.Data == booking.Id.ToString());

                if (!customerAlreadyReminded)
                {
                    var notification = new Notification
                    {
                        UserId = booking.CustomerId,
                        Title = "تذكير بموعد الحلاقة",
                        Message = $"لديك موعد في {booking.BarberProfile.ShopName} {timeText}، لا تنسى",
                        Type = "reminder",
                        IsRead = false,
                        Data = booking.Id.ToString()
                    };
                    context.Notifications.Add(notification);
                    await context.SaveChangesAsync();

                    try
                    {
                        await fcm.SendToUser(
                            booking.CustomerId,
                            "تذكير بموعد الحلاقة",
                            $"لديك موعد في {booking.BarberProfile.ShopName} {timeText}، لا تنسى",
                            new Dictionary<string, string>
                            {
                                { "type", "booking_reminder" },
                                { "bookingId", booking.Id.ToString() },
                                { "shopName", booking.BarberProfile.ShopName }
                            });
                    }
                    catch (Exception ex)
                    {
                        _logger.LogWarning(ex, "Failed to send FCM reminder to customer {CustomerId}", booking.CustomerId);
                    }
                }

                // --- Barber reminder ---
                var barberAlreadyReminded = await context.Notifications
                    .AnyAsync(n => n.UserId == booking.BarberProfile.UserId
                        && (n.Type == "reminder" || n.Type == "service_reminder")
                        && n.Data == booking.Id.ToString());

                if (!barberAlreadyReminded)
                {
                    var notification = new Notification
                    {
                        UserId = booking.BarberProfile.UserId,
                        Title = "تذكير بموعد",
                        Message = $"موعد مع {booking.Customer.FullName} {timeText}",
                        Type = "reminder",
                        IsRead = false,
                        Data = booking.Id.ToString()
                    };
                    context.Notifications.Add(notification);
                    await context.SaveChangesAsync();

                    try
                    {
                        await fcm.SendToUser(
                            booking.BarberProfile.UserId,
                            "تذكير بموعد",
                            $"موعد مع {booking.Customer.FullName} {timeText}",
                            new Dictionary<string, string>
                            {
                                { "type", "booking_reminder" },
                                { "bookingId", booking.Id.ToString() },
                                { "customerName", booking.Customer.FullName }
                            });
                    }
                    catch (Exception ex)
                    {
                        _logger.LogWarning(ex, "Failed to send FCM reminder to barber {BarberUserId}", booking.BarberProfile.UserId);
                    }
                }
            }
        }
    }
}
