using BarberBooking.Domain.Entities;
using BarberBooking.Infrastructure.Data;
using BarberBooking.API.Services;
using Microsoft.EntityFrameworkCore;

namespace BarberBooking.API.Services;

public class ServiceTimerService : BackgroundService
{
    private readonly IServiceProvider _serviceProvider;
    private readonly ILogger<ServiceTimerService> _logger;
    private static readonly TimeZoneInfo PalestineTimeZone = TimeZoneInfo.FindSystemTimeZoneById("Asia/Hebron");

    public ServiceTimerService(IServiceProvider serviceProvider, ILogger<ServiceTimerService> logger)
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
                await CheckBookings();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in ServiceTimerService");
            }

            await Task.Delay(TimeSpan.FromMinutes(1), stoppingToken);
        }
    }

    private async Task CheckBookings()
    {
        using var scope = _serviceProvider.CreateScope();
        var context = scope.ServiceProvider.GetRequiredService<BarberBookingDbContext>();
        var fcm = scope.ServiceProvider.GetRequiredService<IFirebasePushService>();

        var nowLocal = TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, PalestineTimeZone);

        await CheckAcceptedBookings(context, fcm, nowLocal);
        await CheckLateAcceptedBookings(context, fcm, nowLocal);
        await CheckOverdueBookings(context, fcm, nowLocal);
    }

    private async Task CheckAcceptedBookings(BarberBookingDbContext context, IFirebasePushService fcm, DateTime nowLocal)
    {
        var dueBookings = await context.Bookings
            .Include(b => b.BarberProfile).ThenInclude(bp => bp.User)
            .Include(b => b.Customer)
            .Include(b => b.BarberService)
            .Where(b => b.Status == "Accepted" && b.StartedAt == null)
            .ToListAsync();

        foreach (var booking in dueBookings)
        {
            var bookingLocal = booking.BookingDate.Date + booking.BookingTime;
            var diff = (nowLocal - bookingLocal).TotalMinutes;

            if (diff >= 0 && diff <= 3)
            {
                var alreadyReminded = await context.Notifications
                    .AnyAsync(n => n.UserId == booking.BarberProfile.UserId
                        && n.Type == "service_reminder"
                        && n.Data == booking.Id.ToString());

                if (!alreadyReminded)
                {
                    context.Notifications.Add(new Notification
                    {
                        UserId = booking.BarberProfile.UserId,
                        Title = "حان موعد الخدمة",
                        Message = $"حان موعد {booking.Customer.FullName}. اضغط (بدء الخدمة) عند وصول العميل.",
                        Type = "service_reminder",
                        IsRead = false,
                        Data = booking.Id.ToString()
                    });

                    context.Notifications.Add(new Notification
                    {
                        UserId = booking.CustomerId,
                        Title = "موعدك الآن",
                        Message = $"موعدك الآن لدى صالون {booking.BarberProfile.ShopName}",
                        Type = "service_reminder",
                        IsRead = false,
                        Data = booking.Id.ToString()
                    });

                    await context.SaveChangesAsync();

                    try
                    {
                        await fcm.SendToUser(
                            booking.BarberProfile.UserId,
                            "حان موعد الخدمة",
                            $"حان موعد {booking.Customer.FullName}. اضغط (بدء الخدمة) عند وصول العميل.",
                            new Dictionary<string, string>
                            {
                                { "type", "service_reminder" },
                                { "bookingId", booking.Id.ToString() },
                                { "action", "time_to_start" }
                            });
                    }
                    catch { }

                    try
                    {
                        await fcm.SendToUser(
                            booking.CustomerId,
                            "موعدك الآن",
                            $"موعدك الآن لدى صالون {booking.BarberProfile.ShopName}",
                            new Dictionary<string, string>
                            {
                                { "type", "service_reminder" },
                                { "bookingId", booking.Id.ToString() },
                                { "action", "time_to_start" }
                            });
                    }
                    catch { }

                    _logger.LogInformation("Service time reminder sent for booking {BookingId}", booking.Id);
                }
            }
        }
    }

    private async Task CheckLateAcceptedBookings(BarberBookingDbContext context, IFirebasePushService fcm, DateTime nowLocal)
    {
        var lateBookings = await context.Bookings
            .Include(b => b.BarberProfile).ThenInclude(bp => bp.User)
            .Include(b => b.Customer)
            .Include(b => b.BarberService)
            .Where(b => b.Status == "Accepted" && b.StartedAt == null)
            .ToListAsync();

        foreach (var booking in lateBookings)
        {
            var bookingLocal = booking.BookingDate.Date + booking.BookingTime;
            var minutesLate = (nowLocal - bookingLocal).TotalMinutes;

            if (minutesLate >= 5 && minutesLate <= 7)
            {
                var alreadyReminded = await context.Notifications
                    .AnyAsync(n => n.UserId == booking.BarberProfile.UserId
                        && n.Type == "service_late_reminder"
                        && n.Data == booking.Id.ToString());

                if (!alreadyReminded)
                {
                    context.Notifications.Add(new Notification
                    {
                        UserId = booking.BarberProfile.UserId,
                        Title = "مرّت 5 دقائق",
                        Message = $"مرّت 5 دقائق منذ موعد {booking.Customer.FullName}، هل بدأت الخدمة؟",
                        Type = "service_late_reminder",
                        IsRead = false,
                        Data = booking.Id.ToString()
                    });

                    await context.SaveChangesAsync();

                    try
                    {
                        await fcm.SendToUser(
                            booking.BarberProfile.UserId,
                            "مرّت 5 دقائق",
                            $"مرّت 5 دقائق منذ موعد {booking.Customer.FullName}، هل بدأت الخدمة؟",
                            new Dictionary<string, string>
                            {
                                { "type", "service_late_reminder" },
                                { "bookingId", booking.Id.ToString() },
                                { "action", "did_you_start" }
                            });
                    }
                    catch { }

                    _logger.LogInformation("Late service reminder sent for booking {BookingId}", booking.Id);
                }
            }
        }
    }

    private async Task CheckOverdueBookings(BarberBookingDbContext context, IFirebasePushService fcm, DateTime nowLocal)
    {
        var inProgressBookings = await context.Bookings
            .Include(b => b.BarberProfile).ThenInclude(bp => bp.User)
            .Include(b => b.BarberService)
            .Where(b => b.Status == "InProgress"
                && b.StartedAt != null
                && b.ServiceCompletedAt == null)
            .ToListAsync();

        foreach (var booking in inProgressBookings)
        {
            if (booking.StartedAt == null) continue;

            var expectedEndLocal = TimeZoneInfo.ConvertTimeFromUtc(booking.StartedAt.Value, PalestineTimeZone)
                .AddMinutes(booking.ServiceDurationMinutes);
            var minutesOverdue = (nowLocal - expectedEndLocal).TotalMinutes;

            if (minutesOverdue >= 0 && minutesOverdue <= 2)
            {
                var alreadyReminded = await context.Notifications
                    .AnyAsync(n => n.UserId == booking.BarberProfile.UserId
                        && n.Type == "service_time_up"
                        && n.Data == booking.Id.ToString());

                if (!alreadyReminded)
                {
                    context.Notifications.Add(new Notification
                    {
                        UserId = booking.BarberProfile.UserId,
                        Title = "انتهى الوقت المتوقع",
                        Message = $"انتهى الوقت المتوقع للخدمة، هل تريد إنهاء الموعد؟",
                        Type = "service_time_up",
                        IsRead = false,
                        Data = booking.Id.ToString()
                    });

                    await context.SaveChangesAsync();

                    try
                    {
                        await fcm.SendToUser(
                            booking.BarberProfile.UserId,
                            "انتهى الوقت المتوقع",
                            $"انتهى الوقت المتوقع للخدمة، هل تريد إنهاء الموعد؟",
                            new Dictionary<string, string>
                            {
                                { "type", "service_time_up" },
                                { "bookingId", booking.Id.ToString() },
                                { "action", "time_is_up" }
                            });
                    }
                    catch { }

                    _logger.LogInformation("Service time up reminder sent for booking {BookingId}", booking.Id);
                }
            }
        }
    }
}
