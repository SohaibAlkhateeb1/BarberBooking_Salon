using FirebaseAdmin;
using FirebaseAdmin.Messaging;
using Google.Apis.Auth.OAuth2;
using BarberBooking.Domain.Entities;
using BarberBooking.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace BarberBooking.API.Services;

public interface IFirebasePushService
{
    Task SaveDeviceToken(Guid userId, string fcmToken, string platform, string? deviceName);
    Task RemoveDeviceToken(string fcmToken);
    Task SendToUser(Guid userId, string title, string body, Dictionary<string, string>? data = null);
    Task SendToAllCustomers(string title, string body, Dictionary<string, string>? data = null);
    Task SendToBarber(Guid barberUserId, string title, string body, Dictionary<string, string>? data = null);
}

public class FcmNotificationService : IFirebasePushService
{
    private readonly BarberBookingDbContext _context;
    private readonly ILogger<FcmNotificationService> _logger;
    private readonly IConfiguration _configuration;
    private static bool _firebaseInitialized = false;

    public FcmNotificationService(
        BarberBookingDbContext context,
        ILogger<FcmNotificationService> logger,
        IConfiguration configuration)
    {
        _context = context;
        _logger = logger;
        _configuration = configuration;
        InitializeFirebase();
    }

    private void InitializeFirebase()
    {
        if (_firebaseInitialized) return;

        try
        {
            var credentialsJson = _configuration["Firebase:Credentials"];
            if (!string.IsNullOrEmpty(credentialsJson))
            {
                FirebaseApp.Create(new AppOptions()
                {
                    Credential = GoogleCredential.FromJson(credentialsJson)
                });
                _firebaseInitialized = true;
                _logger.LogInformation("Firebase Admin SDK initialized from environment variable");
                return;
            }

            var credentialsPath = _configuration["Firebase:CredentialsPath"];
            if (string.IsNullOrEmpty(credentialsPath))
            {
                credentialsPath = Path.Combine(AppContext.BaseDirectory, "firebase-service-account.json");
            }

            if (File.Exists(credentialsPath))
            {
                FirebaseApp.Create(new AppOptions()
                {
                    Credential = GoogleCredential.FromFile(credentialsPath)
                });
                _firebaseInitialized = true;
                _logger.LogInformation("Firebase Admin SDK initialized from file");
            }
            else
            {
                _logger.LogWarning("Firebase credentials not found. FCM notifications will be disabled.");
            }
        }
        catch (Exception)
        {
            _logger.LogWarning("Failed to initialize Firebase Admin SDK. FCM notifications will be disabled.");
        }
    }

    public async Task SaveDeviceToken(Guid userId, string fcmToken, string platform, string? deviceName)
    {
        if (string.IsNullOrWhiteSpace(fcmToken)) return;

        var existing = await _context.UserDevices
            .FirstOrDefaultAsync(ud => ud.UserId == userId && ud.FcmToken == fcmToken);

        if (existing != null)
        {
            existing.LastUsedAt = DateTime.UtcNow;
            existing.IsActive = true;
            existing.DeviceName = deviceName ?? existing.DeviceName;
        }
        else
        {
            var oldTokens = await _context.UserDevices
                .Where(ud => ud.UserId == userId && ud.FcmToken == fcmToken)
                .ToListAsync();

            _context.UserDevices.AddRange(oldTokens);

            _context.UserDevices.Add(new UserDevice
            {
                UserId = userId,
                FcmToken = fcmToken,
                Platform = platform,
                DeviceName = deviceName,
                IsActive = true,
                LastUsedAt = DateTime.UtcNow
            });
        }

        await _context.SaveChangesAsync();
    }

    public async Task RemoveDeviceToken(string fcmToken)
    {
        var device = await _context.UserDevices
            .FirstOrDefaultAsync(ud => ud.FcmToken == fcmToken);

        if (device != null)
        {
            device.IsActive = false;
            await _context.SaveChangesAsync();
        }
    }

    public async Task SendToUser(Guid userId, string title, string body, Dictionary<string, string>? data = null)
    {
        var tokens = await _context.UserDevices
            .Where(ud => ud.UserId == userId && ud.IsActive)
            .Select(ud => ud.FcmToken)
            .ToListAsync();

        if (tokens.Count == 0)
        {
            _logger.LogWarning("No device tokens found for user {UserId}", userId);
            return;
        }

        await SendToTokens(tokens, title, body, data);
    }

    public async Task SendToAllCustomers(string title, string body, Dictionary<string, string>? data = null)
    {
        var tokens = await _context.UserDevices
            .Where(ud => ud.User.Role == "Customer" && ud.IsActive)
            .Select(ud => ud.FcmToken)
            .ToListAsync();

        if (tokens.Count == 0) return;

        await SendToTokens(tokens, title, body, data);
    }

    public async Task SendToBarber(Guid barberUserId, string title, string body, Dictionary<string, string>? data = null)
    {
        await SendToUser(barberUserId, title, body, data);
    }

    private async Task SendToTokens(List<string> tokens, string title, string body, Dictionary<string, string>? data = null)
    {
        if (!_firebaseInitialized)
        {
            _logger.LogWarning("Firebase not initialized. Cannot send notification: {Title}", title);
            return;
        }

        try
        {
            var message = new MulticastMessage()
            {
                Tokens = tokens,
                Notification = new FirebaseAdmin.Messaging.Notification()
                {
                    Title = title,
                    Body = body
                },
                Data = data ?? new Dictionary<string, string>(),
                Android = new AndroidConfig()
                {
                    Priority = Priority.High,
                    Notification = new AndroidNotification()
                    {
                        ChannelId = "barber_booking_channel",
                        Icon = "@mipmap/ic_launcher",
                        Color = "#0DF1B5"
                    }
                }
            };

            var response = await FirebaseMessaging.DefaultInstance.SendEachForMulticastAsync(message);

            _logger.LogInformation("FCM sent: {SuccessCount} success, {FailureCount} failure",
                response.SuccessCount, response.FailureCount);

            if (response.FailureCount > 0)
            {
                var failedTokens = new List<string>();
                for (int i = 0; i < response.Responses.Count; i++)
                {
                    if (!response.Responses[i].IsSuccess)
                    {
                        failedTokens.Add(tokens[i]);
                    }
                }

                if (failedTokens.Count > 0)
                {
                    var invalidDevices = await _context.UserDevices
                        .Where(ud => failedTokens.Contains(ud.FcmToken))
                        .ToListAsync();

                    foreach (var device in invalidDevices)
                    {
                        device.IsActive = false;
                    }
                    await _context.SaveChangesAsync();
                }
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to send FCM notification");
        }
    }
}
