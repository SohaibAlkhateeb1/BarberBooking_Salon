using BarberBooking.Application.DTOs.Barber;
using BarberBooking.Application.DTOs.Booking;
using BarberBooking.Domain.Entities;
using BarberBooking.Domain.Exceptions;
using BarberBooking.Infrastructure.Data;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace BarberBooking.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class PaymentsController : ControllerBase
{
    private readonly BarberBookingDbContext _context;

    public PaymentsController(BarberBookingDbContext context)
    {
        _context = context;
    }

    private Guid GetCurrentUserId()
    {
        var sub = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value
                  ?? User.FindFirst("sub")?.Value;
        if (string.IsNullOrEmpty(sub))
            throw new UnauthorizedAccessException("غير مصرح");
        return Guid.Parse(sub);
    }

    [HttpPost("confirm-cash/{bookingId}")]
    public async Task<IActionResult> ConfirmCashPayment(Guid bookingId)
    {
        var userId = GetCurrentUserId();
        var role = User.FindFirst(System.Security.Claims.ClaimTypes.Role)?.Value;

        var booking = await _context.Bookings
            .Include(b => b.BarberProfile)
            .Include(b => b.BarberService)
            .Include(b => b.Customer)
            .FirstOrDefaultAsync(b => b.Id == bookingId);

        if (booking == null)
            return NotFound(new { message = "الحجز غير موجود" });

        // Only the barber can confirm payment
        if (role != "Barber" || booking.BarberProfile.UserId != userId)
            return Forbid();

        if (booking.Status != "Completed")
            return BadRequest(new { message = "لا يمكن تأكيد الدفع إلا بعد إكمال الحجز" });

        if (booking.PaymentStatus == "Paid")
            return BadRequest(new { message = "تم تأكيد الدفع بالفعل" });

        booking.PaymentStatus = "Paid";
        booking.PaymentMethod = "cash";
        booking.PaidAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        // Create notification for customer
        var notification = new Notification
        {
            UserId = booking.CustomerId,
            Title = "تأكيد الدفع",
            Message = $"تم تأكيد الدفع النقدي لمبلغ {booking.FinalPrice} شيكل",
            Type = "payment",
            IsRead = false
        };
        _context.Notifications.Add(notification);
        await _context.SaveChangesAsync();

        return Ok(new
        {
            message = "تم تأكيد الدفع النقدي بنجاح",
            paymentStatus = "Paid",
            paidAt = booking.PaidAt
        });
    }

    [HttpGet("status/{bookingId}")]
    public async Task<IActionResult> GetPaymentStatus(Guid bookingId)
    {
        var booking = await _context.Bookings
            .Include(b => b.BarberService)
            .FirstOrDefaultAsync(b => b.Id == bookingId);

        if (booking == null)
            return NotFound(new { message = "الحجز غير موجود" });

        return Ok(new
        {
            bookingId = booking.Id,
            totalPrice = booking.TotalPrice,
            discountAmount = booking.DiscountAmount,
            finalPrice = booking.FinalPrice,
            paymentStatus = booking.PaymentStatus,
            paymentMethod = booking.PaymentMethod,
            paidAt = booking.PaidAt
        });
    }
}
