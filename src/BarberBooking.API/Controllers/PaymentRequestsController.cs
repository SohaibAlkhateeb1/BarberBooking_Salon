using System.Security.Claims;
using BarberBooking.Application.DTOs.Payment;
using BarberBooking.Application.Interfaces;
using BarberBooking.Infrastructure.Data;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace BarberBooking.API.Controllers;

[ApiController]
[Route("api/payment-requests")]
[Authorize]
public class PaymentRequestsController : ControllerBase
{
    private readonly IPaymentRequestService _paymentRequestService;
    private readonly BarberBookingDbContext _context;

    public PaymentRequestsController(IPaymentRequestService paymentRequestService, BarberBookingDbContext context)
    {
        _paymentRequestService = paymentRequestService;
        _context = context;
    }

    private Guid GetCurrentUserId()
    {
        var sub = User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? User.FindFirst("sub")?.Value;
        if (string.IsNullOrEmpty(sub)) throw new UnauthorizedAccessException();
        return Guid.Parse(sub);
    }

    private async Task<Guid> GetBarberProfileId()
    {
        var userId = GetCurrentUserId();
        var profile = await _context.BarberProfiles.FirstOrDefaultAsync(bp => bp.UserId == userId);
        if (profile == null) throw new InvalidOperationException("الحلاق غير موجود");
        return profile.Id;
    }

    [HttpPost]
    [Authorize(Roles = "Barber")]
    public async Task<IActionResult> CreatePaymentRequest([FromBody] CreatePaymentRequestDto dto)
    {
        try
        {
            var barberProfileId = await GetBarberProfileId();

            if (string.IsNullOrEmpty(dto.PaymentMethod) || (dto.PaymentMethod != "cash" && dto.PaymentMethod != "bank_transfer"))
                return BadRequest(new { message = "طريقة الدفع غير صحيحة" });

            if (dto.PaymentMethod == "bank_transfer" && string.IsNullOrEmpty(dto.ReceiptImageUrl))
                return BadRequest(new { message = "يجب رفع صورة إيصال التحويل البنكي" });

            var result = await _paymentRequestService.CreatePaymentRequestAsync(barberProfileId, dto);
            return Ok(new { message = "تم إرسال طلب الدفع بنجاح", paymentRequest = result });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpGet("my")]
    [Authorize(Roles = "Barber")]
    public async Task<IActionResult> GetMyPaymentRequests()
    {
        var barberProfileId = await GetBarberProfileId();
        var requests = await _paymentRequestService.GetMyPaymentRequestsAsync(barberProfileId);
        return Ok(requests);
    }

    [HttpGet("{id}")]
    [Authorize(Roles = "Barber")]
    public async Task<IActionResult> GetPaymentRequest(Guid id)
    {
        var result = await _paymentRequestService.GetPaymentRequestByIdAsync(id);
        if (result == null) return NotFound(new { message = "الطلب غير موجود" });
        return Ok(result);
    }
}
