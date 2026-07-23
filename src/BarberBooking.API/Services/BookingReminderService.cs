using BarberBooking.Domain.Entities;
using BarberBooking.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace BarberBooking.API.Services;

public class BookingReminderService : BackgroundService
{
    private readonly IServiceProvider _serviceProvider;
    private readonly ILogger<BookingReminderService> _logger;
    private static readonly TimeZoneInfo PalestineTimeZone = TimeZoneInfo.FindSystemTimeZoneById("Asia/Hebron");

    public BookingReminderService(IServiceProvider serviceProvider, ILogger<BookingReminderService> logger)
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
                await CheckAndSendReminders();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in BookingReminderService");
            }

            await Task.Delay(TimeSpan.FromMinutes(1), stoppingToken);
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

        _logger.LogDebug("Reminder check at local time {LocalTime}, window {Window}", nowLocal, reminderWindow);

        var upcomingBookings = await context.Bookings
            .Include(b => b.BarberProfile)
                .ThenInclude(bp => bp.User)
            .Include(b => b.Customer)
            .Include(b => b.BarberService)
            .Where(b => b.Status == "Pending" || b.Status == "Accepted" || b.Status == "InProgress")
            .ToListAsync();

        foreach (var booking in upcomingBookings)
        {
            // BookingDate is stored as local date but with Kind=Unspecified or Utc
            // BookingTime is the local time of the appointment
            var bookingLocal = booking.BookingDate.Date + booking.BookingTime;

            _logger.LogDebug("Booking {BookingId}: bookingLocal={BookingLocal}, nowLocal={NowLocal}, inWindow={InWindow}",
                booking.Id, bookingLocal, nowLocal, bookingLocal > fiveMinutesAgo && bookingLocal <= reminderWindow);

            if (bookingLocal > fiveMinutesAgo && bookingLocal <= reminderWindow)
            {
                var timeUntil = bookingLocal - nowLocal;
                var timeText = timeUntil.TotalMinutes < 1
                    ? "الآن"
                    : $"بعد {(int)timeUntil.TotalMinutes} دقيقة";

                // --- Customer reminder ---
                var customerAlreadyReminded = await context.Notifications
                    .AnyAsync(n => n.UserId == booking.CustomerId
                        && n.Type == "reminder"
                        && n.Data == booking.Id.ToString());

                if (!customerAlreadyReminded)
                {
                    context.Notifications.Add(new Notification
                    {
                        UserId = booking.CustomerId,
                        Title = "تذكير بموعد الحلاقة",
                        Message = $"لديك موعد في {booking.BarberProfile.ShopName} {timeText}، لا تنسى",
                        Type = "reminder",
                        IsRead = false,
                        Data = booking.Id.ToString()
                    });

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

                    _logger.LogInformation("Customer reminder sent for booking {BookingId}", booking.Id);
                }

                // --- Barber reminder ---
                var barberAlreadyReminded = await context.Notifications
                    .AnyAsync(n => n.UserId == booking.BarberProfile.UserId
                        && n.Type == "reminder"
                        && n.Data == booking.Id.ToString());

                if (!barberAlreadyReminded)
                {
                    context.Notifications.Add(new Notification
                    {
                        UserId = booking.BarberProfile.UserId,
                        Title = "تذكير بموعد",
                        Message = $"موعد مع {booking.Customer.FullName} {timeText}",
                        Type = "reminder",
                        IsRead = false,
                        Data = booking.Id.ToString()
                    });

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

                    _logger.LogInformation("Barber reminder sent for booking {BookingId}", booking.Id);
                }
            }
        }

        await context.SaveChangesAsync();
    }
}
