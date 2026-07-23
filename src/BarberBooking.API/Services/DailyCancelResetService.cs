using BarberBooking.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace BarberBooking.API.Services;

public class DailyCancelResetService : BackgroundService
{
    private readonly IServiceProvider _serviceProvider;
    private readonly ILogger<DailyCancelResetService> _logger;

    public DailyCancelResetService(IServiceProvider serviceProvider, ILogger<DailyCancelResetService> logger)
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
                var now = DateTime.UtcNow;
                var tomorrow = now.Date.AddDays(1);
                var delay = tomorrow - now;

                if (delay.TotalMilliseconds > 0)
                {
                    await Task.Delay(delay, stoppingToken);
                }

                await ResetDailyCancelCountsAsync();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error resetting daily cancel counts");
                await Task.Delay(TimeSpan.FromHours(1), stoppingToken);
            }
        }
    }

    private async Task ResetDailyCancelCountsAsync()
    {
        using var scope = _serviceProvider.CreateScope();
        var context = scope.ServiceProvider.GetRequiredService<BarberBookingDbContext>();

        var resetCount = await context.Users
            .Where(u => u.DailyCancelCount > 0)
            .ExecuteUpdateAsync(s => s
                .SetProperty(u => u.DailyCancelCount, 0)
                .SetProperty(u => u.LastCancelDate, (DateTime?)null));

        _logger.LogInformation("Reset daily cancel counts for {Count} users", resetCount);
    }
}
