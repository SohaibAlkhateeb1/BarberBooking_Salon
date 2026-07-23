namespace BarberBooking.Application.Interfaces;

public interface IFcmNotificationService
{
    Task SendNotificationAsync(string fcmToken, string title, string body, Dictionary<string, string>? data = null);
    Task SendBookingLimitWarningAsync(string fcmToken, int currentCount, int limit);
    Task SendBookingLimitReachedAsync(string fcmToken, int currentCount, int limit);
    Task SendSubscriptionExpiredAsync(string fcmToken, string planName);
    Task SendBookingConfirmationAsync(string fcmToken, string shopName, string date, string time);
    Task SendBookingReminderAsync(string fcmToken, string shopName, string date, string time);
}
