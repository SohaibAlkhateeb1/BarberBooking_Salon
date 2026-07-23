using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;

namespace BarberBooking.API.Hubs;

[Authorize]
public class NotificationHub : Hub
{
    private readonly ILogger<NotificationHub> _logger;

    public NotificationHub(ILogger<NotificationHub> logger)
    {
        _logger = logger;
    }

    public override async Task OnConnectedAsync()
    {
        var userId = Context.UserIdentifier;
        if (!string.IsNullOrEmpty(userId))
        {
            await Groups.AddToGroupAsync(Context.ConnectionId, $"user_{userId}");
            _logger.LogInformation("User {UserId} connected to notification hub", userId);
        }

        await base.OnConnectedAsync();
    }

    public override async Task OnDisconnectedAsync(Exception? exception)
    {
        var userId = Context.UserIdentifier;
        if (!string.IsNullOrEmpty(userId))
        {
            await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"user_{userId}");
            _logger.LogInformation("User {UserId} disconnected from notification hub", userId);
        }

        await base.OnDisconnectedAsync(exception);
    }

    public async Task JoinBarberGroup(string barberId)
    {
        await Groups.AddToGroupAsync(Context.ConnectionId, $"barber_{barberId}");
        _logger.LogInformation("Connection {ConnectionId} joined barber group {BarberId}", Context.ConnectionId, barberId);
    }

    public async Task LeaveBarberGroup(string barberId)
    {
        await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"barber_{barberId}");
        _logger.LogInformation("Connection {ConnectionId} left barber group {BarberId}", Context.ConnectionId, barberId);
    }

    public async Task JoinAdminGroup()
    {
        await Groups.AddToGroupAsync(Context.ConnectionId, "admins");
        _logger.LogInformation("Admin connection {ConnectionId} joined admin group", Context.ConnectionId);
    }
}
