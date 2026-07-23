using System.Security.Claims;
using BarberBooking.Domain.Entities;
using BarberBooking.Infrastructure.Data;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace BarberBooking.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class PromoCodesController : ControllerBase
{
    private readonly BarberBookingDbContext _context;

    public PromoCodesController(BarberBookingDbContext context)
    {
        _context = context;
    }

    private Guid GetCurrentUserId()
    {
        var sub = User.FindFirst(ClaimTypes.NameIdentifier)?.Value
                  ?? User.FindFirst("sub")?.Value;
        if (string.IsNullOrEmpty(sub))
            throw new UnauthorizedAccessException("غير مصرح");
        return Guid.Parse(sub);
    }

    [HttpPost("validate")]
    public async Task<IActionResult> ValidatePromoCode([FromBody] ValidatePromoCodeDto dto)
    {
        var promoCode = await _context.PromoCodes
            .FirstOrDefaultAsync(p => p.Code == dto.Code && p.IsActive);

        if (promoCode == null)
            return NotFound(new { message = "كوبون الخصم غير موجود" });

        if (promoCode.EndDate < DateTime.UtcNow)
            return BadRequest(new { message = "كوبون الخصم منتهي الصلاحية" });

        if (promoCode.StartDate > DateTime.UtcNow)
            return BadRequest(new { message = "كوبون الخصم لم يبدأ بعد" });

        if (promoCode.UsageLimit > 0 && promoCode.UsedCount >= promoCode.UsageLimit)
            return BadRequest(new { message = "تم استخدام كوبون الخصم بالحد الأقصى" });

        if (promoCode.MinBookingAmount.HasValue && dto.BookingAmount < promoCode.MinBookingAmount.Value)
            return BadRequest(new { message = $"الحد الأدنى للمبلغ هو {promoCode.MinBookingAmount.Value} شيكل" });

        var discountAmount = (dto.BookingAmount * promoCode.DiscountPercent) / 100;
        if (promoCode.MaxDiscountAmount.HasValue && discountAmount > promoCode.MaxDiscountAmount.Value)
            discountAmount = promoCode.MaxDiscountAmount.Value;

        var finalPrice = dto.BookingAmount - discountAmount;

        return Ok(new
        {
            valid = true,
            discountPercent = promoCode.DiscountPercent,
            discountAmount = discountAmount,
            finalPrice = finalPrice,
            description = promoCode.Description
        });
    }

    [HttpPost("apply")]
    public async Task<IActionResult> ApplyPromoCode([FromBody] ApplyPromoCodeDto dto)
    {
        var userId = GetCurrentUserId();

        var promoCode = await _context.PromoCodes
            .FirstOrDefaultAsync(p => p.Code == dto.Code && p.IsActive);

        if (promoCode == null)
            return NotFound(new { message = "كوبون الخصم غير موجود" });

        if (promoCode.EndDate < DateTime.UtcNow)
            return BadRequest(new { message = "كوبون الخصم منتهي الصلاحية" });

        if (promoCode.UsageLimit > 0 && promoCode.UsedCount >= promoCode.UsageLimit)
            return BadRequest(new { message = "تم استخدام كوبون الخصم بالحد الأقصى" });

        var booking = await _context.Bookings
            .FirstOrDefaultAsync(b => b.Id == dto.BookingId && b.CustomerId == userId);

        if (booking == null)
            return NotFound(new { message = "الحجز غير موجود" });

        if (booking.PromoCode != null)
            return BadRequest(new { message = "تم استخدام كوبون خصم على هذا الحجز بالفعل" });

        var discountAmount = (booking.TotalPrice * promoCode.DiscountPercent) / 100;
        if (promoCode.MaxDiscountAmount.HasValue && discountAmount > promoCode.MaxDiscountAmount.Value)
            discountAmount = promoCode.MaxDiscountAmount.Value;

        booking.PromoCode = dto.Code;
        booking.DiscountAmount = discountAmount;
        booking.FinalPrice = booking.TotalPrice - discountAmount;
        promoCode.UsedCount++;

        await _context.SaveChangesAsync();

        return Ok(new
        {
            message = "تم تطبيق كوبون الخصم بنجاح",
            discountAmount = discountAmount,
            finalPrice = booking.FinalPrice
        });
    }

    // Barber manages promo codes
    [HttpGet("barber")]
    [Authorize(Roles = "Barber")]
    public async Task<IActionResult> GetBarberPromoCodes()
    {
        var userId = GetCurrentUserId();
        var profile = await _context.BarberProfiles
            .FirstOrDefaultAsync(bp => bp.UserId == userId);

        if (profile == null)
            return NotFound(new { message = "الحلاق غير موجود" });

        var promoCodes = await _context.PromoCodes
            .Where(p => p.BarberProfileId == profile.Id)
            .OrderByDescending(p => p.CreatedAt)
            .Select(p => new
            {
                id = p.Id,
                code = p.Code,
                description = p.Description,
                discountPercent = p.DiscountPercent,
                maxDiscountAmount = p.MaxDiscountAmount,
                minBookingAmount = p.MinBookingAmount,
                usageLimit = p.UsageLimit,
                usedCount = p.UsedCount,
                startDate = p.StartDate,
                endDate = p.EndDate,
                isActive = p.IsActive
            })
            .ToListAsync();

        return Ok(promoCodes);
    }

    [HttpPost("barber")]
    [Authorize(Roles = "Barber")]
    public async Task<IActionResult> CreatePromoCode([FromBody] CreatePromoCodeDto dto)
    {
        var userId = GetCurrentUserId();
        var profile = await _context.BarberProfiles
            .FirstOrDefaultAsync(bp => bp.UserId == userId);

        if (profile == null)
            return NotFound(new { message = "الحلاق غير موجود" });

        var existingCode = await _context.PromoCodes
            .AnyAsync(p => p.Code == dto.Code && p.BarberProfileId == profile.Id);

        if (existingCode)
            return BadRequest(new { message = "كود الخصم موجود بالفعل" });

        var promoCode = new PromoCode
        {
            Code = dto.Code,
            Description = dto.Description,
            DiscountPercent = dto.DiscountPercent,
            MaxDiscountAmount = dto.MaxDiscountAmount,
            MinBookingAmount = dto.MinBookingAmount,
            UsageLimit = dto.UsageLimit,
            StartDate = dto.StartDate,
            EndDate = dto.EndDate,
            BarberProfileId = profile.Id,
            IsActive = true
        };

        _context.PromoCodes.Add(promoCode);
        await _context.SaveChangesAsync();

        return Ok(new { message = "تم إنشاء كوبون الخصم بنجاح", id = promoCode.Id });
    }

    [HttpPut("barber/{id}")]
    [Authorize(Roles = "Barber")]
    public async Task<IActionResult> UpdatePromoCode(Guid id, [FromBody] CreatePromoCodeDto dto)
    {
        var userId = GetCurrentUserId();
        var profile = await _context.BarberProfiles
            .FirstOrDefaultAsync(bp => bp.UserId == userId);

        if (profile == null)
            return NotFound(new { message = "الحلاق غير موجود" });

        var promoCode = await _context.PromoCodes
            .FirstOrDefaultAsync(p => p.Id == id && p.BarberProfileId == profile.Id);

        if (promoCode == null)
            return NotFound(new { message = "كوبون الخصم غير موجود" });

        promoCode.Code = dto.Code;
        promoCode.Description = dto.Description;
        promoCode.DiscountPercent = dto.DiscountPercent;
        promoCode.MaxDiscountAmount = dto.MaxDiscountAmount;
        promoCode.MinBookingAmount = dto.MinBookingAmount;
        promoCode.UsageLimit = dto.UsageLimit;
        promoCode.StartDate = dto.StartDate;
        promoCode.EndDate = dto.EndDate;

        await _context.SaveChangesAsync();

        return Ok(new { message = "تم تحديث كوبون الخصم بنجاح" });
    }

    [HttpDelete("barber/{id}")]
    [Authorize(Roles = "Barber")]
    public async Task<IActionResult> DeletePromoCode(Guid id)
    {
        var userId = GetCurrentUserId();
        var profile = await _context.BarberProfiles
            .FirstOrDefaultAsync(bp => bp.UserId == userId);

        if (profile == null)
            return NotFound(new { message = "الحلاق غير موجود" });

        var promoCode = await _context.PromoCodes
            .FirstOrDefaultAsync(p => p.Id == id && p.BarberProfileId == profile.Id);

        if (promoCode == null)
            return NotFound(new { message = "كوبون الخصم غير موجود" });

        _context.PromoCodes.Remove(promoCode);
        await _context.SaveChangesAsync();

        return Ok(new { message = "تم حذف كوبون الخصم بنجاح" });
    }

    [HttpPut("barber/{id}/toggle")]
    [Authorize(Roles = "Barber")]
    public async Task<IActionResult> TogglePromoCode(Guid id)
    {
        var userId = GetCurrentUserId();
        var profile = await _context.BarberProfiles
            .FirstOrDefaultAsync(bp => bp.UserId == userId);

        if (profile == null)
            return NotFound(new { message = "الحلاق غير موجود" });

        var promoCode = await _context.PromoCodes
            .FirstOrDefaultAsync(p => p.Id == id && p.BarberProfileId == profile.Id);

        if (promoCode == null)
            return NotFound(new { message = "كوبون الخصم غير موجود" });

        promoCode.IsActive = !promoCode.IsActive;
        await _context.SaveChangesAsync();

        return Ok(new { message = "تم تحديث حالة كوبون الخصم", isActive = promoCode.IsActive });
    }
}

public class ValidatePromoCodeDto
{
    public string Code { get; set; } = string.Empty;
    public decimal BookingAmount { get; set; }
}

public class ApplyPromoCodeDto
{
    public string Code { get; set; } = string.Empty;
    public Guid BookingId { get; set; }
}

public class CreatePromoCodeDto
{
    public string Code { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public decimal DiscountPercent { get; set; }
    public decimal? MaxDiscountAmount { get; set; }
    public decimal? MinBookingAmount { get; set; }
    public int UsageLimit { get; set; }
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
}
