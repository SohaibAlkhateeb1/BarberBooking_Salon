using BarberBooking.Application.DTOs.Subscription;
using BarberBooking.Application.Interfaces;
using BarberBooking.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace BarberBooking.API.Services;

public class BookingLimitService : IBookingLimitService
{
    private readonly BarberBookingDbContext _context;
    private readonly ISubscriptionService _subscriptionService;

    public BookingLimitService(BarberBookingDbContext context, ISubscriptionService subscriptionService)
    {
        _context = context;
        _subscriptionService = subscriptionService;
    }

    public async Task<BookingLimitStatusDto> CheckBookingLimitAsync(Guid barberId)
    {
        return await _subscriptionService.GetBookingLimitStatusAsync(barberId);
    }

    public async Task<bool> IsBookingAllowedAsync(Guid barberId)
    {
        var status = await CheckBookingLimitAsync(barberId);
        // Always allow bookings (no blocking), just tracking
        return true;
    }

    public async Task<int> GetRemainingBookingsAsync(Guid barberId)
    {
        var status = await CheckBookingLimitAsync(barberId);
        if (status.Limit < 0) return int.MaxValue; // unlimited
        return Math.Max(0, status.Limit - status.CurrentCount);
    }
}
