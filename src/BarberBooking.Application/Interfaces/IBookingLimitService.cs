using BarberBooking.Application.DTOs.Subscription;

namespace BarberBooking.Application.Interfaces;

public interface IBookingLimitService
{
    Task<BookingLimitStatusDto> CheckBookingLimitAsync(Guid barberId);
    Task<bool> IsBookingAllowedAsync(Guid barberId);
    Task<int> GetRemainingBookingsAsync(Guid barberId);
}
