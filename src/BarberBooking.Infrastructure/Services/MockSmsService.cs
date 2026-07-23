using BarberBooking.Application.Interfaces;
using Microsoft.Extensions.Logging;

namespace BarberBooking.Infrastructure.Services;

public class MockSmsService : ISmsService
{
    private readonly ILogger<MockSmsService> _logger;

    public MockSmsService(ILogger<MockSmsService> logger)
    {
        _logger = logger;
    }

    public Task SendOtpAsync(string phoneNumber, string code)
    {
        _logger.LogInformation("===== MOCK SMS ===== To: {Phone}, Code: {Code} =====", phoneNumber, code);
        Console.WriteLine($"[MOCK SMS] To: {phoneNumber}, Code: {code}");
        return Task.CompletedTask;
    }
}
