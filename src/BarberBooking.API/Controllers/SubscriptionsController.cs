using System.Security.Claims;
using BarberBooking.Application.DTOs.Subscription;
using BarberBooking.Application.Interfaces;
using BarberBooking.Domain.Entities;
using BarberBooking.Infrastructure.Data;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace BarberBooking.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class SubscriptionsController : ControllerBase
{
    private readonly BarberBookingDbContext _context;
    private readonly ISubscriptionService _subscriptionService;

    public SubscriptionsController(BarberBookingDbContext context, ISubscriptionService subscriptionService)
    {
        _context = context;
        _subscriptionService = subscriptionService;
    }

    private Guid GetCurrentUserId()
    {
        var sub = User.FindFirst(ClaimTypes.NameIdentifier)?.Value
                  ?? User.FindFirst("sub")?.Value;
        if (string.IsNullOrEmpty(sub))
            throw new UnauthorizedAccessException("غير مصرح");
        return Guid.Parse(sub);
    }

    [HttpGet("plans")]
    public async Task<IActionResult> GetPlans()
    {
        var plans = await _subscriptionService.GetPlansAsync();
        return Ok(plans);
    }

    [HttpGet("current")]
    [Authorize(Roles = "Barber")]
    public async Task<IActionResult> GetCurrentSubscription()
    {
        var userId = GetCurrentUserId();
        var profile = await _context.BarberProfiles
            .FirstOrDefaultAsync(bp => bp.UserId == userId);

        if (profile == null)
            return NotFound(new { message = "الحلاق غير موجود" });

        var subscription = await _subscriptionService.GetCurrentSubscriptionAsync(profile.Id);
        if (subscription == null)
            return Ok(new { hasSubscription = false, planName = "Free", endDate = (DateTime?)null });

        return Ok(subscription);
    }

    [HttpGet("current/status")]
    [Authorize(Roles = "Barber")]
    public async Task<IActionResult> GetBookingLimitStatus()
    {
        var userId = GetCurrentUserId();
        var profile = await _context.BarberProfiles
            .FirstOrDefaultAsync(bp => bp.UserId == userId);

        if (profile == null)
            return NotFound(new { message = "الحلاق غير موجود" });

        var status = await _subscriptionService.GetBookingLimitStatusAsync(profile.Id);
        return Ok(status);
    }

    [HttpGet("history")]
    [Authorize(Roles = "Barber")]
    public async Task<IActionResult> GetHistory()
    {
        var userId = GetCurrentUserId();
        var profile = await _context.BarberProfiles
            .FirstOrDefaultAsync(bp => bp.UserId == userId);

        if (profile == null)
            return NotFound(new { message = "الحلاق غير موجود" });

        var history = await _subscriptionService.GetHistoryAsync(profile.Id);
        return Ok(history);
    }

    [HttpPost("subscribe")]
    [Authorize(Roles = "Barber")]
    public async Task<IActionResult> Subscribe([FromBody] SubscribeRequestDto dto)
    {
        var userId = GetCurrentUserId();
        var profile = await _context.BarberProfiles
            .FirstOrDefaultAsync(bp => bp.UserId == userId);

        if (profile == null)
            return NotFound(new { message = "الحلاق غير موجود" });

        try
        {
            var result = await _subscriptionService.SubscribeAsync(profile.Id, dto);
            return Ok(new { message = "تم الاشتراك بنجاح", subscription = result });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost("upgrade")]
    [Authorize(Roles = "Barber")]
    public async Task<IActionResult> Upgrade([FromBody] UpgradeRequestDto dto)
    {
        var userId = GetCurrentUserId();
        var profile = await _context.BarberProfiles
            .FirstOrDefaultAsync(bp => bp.UserId == userId);

        if (profile == null)
            return NotFound(new { message = "الحلاق غير موجود" });

        try
        {
            var result = await _subscriptionService.UpgradeAsync(profile.Id, dto);
            return Ok(new { message = "تم الترقية بنجاح", subscription = result });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost("cancel")]
    [Authorize(Roles = "Barber")]
    public async Task<IActionResult> CancelSubscription()
    {
        var userId = GetCurrentUserId();
        var profile = await _context.BarberProfiles
            .FirstOrDefaultAsync(bp => bp.UserId == userId);

        if (profile == null)
            return NotFound(new { message = "الحلاق غير موجود" });

        try
        {
            await _subscriptionService.CancelAsync(profile.Id);
            return Ok(new { message = "تم إلغاء الاشتراك بنجاح" });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpGet("check/{feature}")]
    [Authorize(Roles = "Barber")]
    public async Task<IActionResult> CheckFeature(string feature)
    {
        var userId = GetCurrentUserId();
        var profile = await _context.BarberProfiles
            .FirstOrDefaultAsync(bp => bp.UserId == userId);

        if (profile == null)
            return NotFound(new { message = "الحلاق غير موجود" });

        var result = feature.ToLower() switch
        {
            "service" => await _subscriptionService.CanAddServiceAsync(profile.Id),
            "photo" => await _subscriptionService.CanAddPhotoAsync(profile.Id),
            "employee" => await _subscriptionService.CanAddEmployeeAsync(profile.Id),
            "analytics" => await _subscriptionService.CanUseAnalyticsAsync(profile.Id),
            "promocodes" => await _subscriptionService.CanUsePromoCodesAsync(profile.Id),
            "priority_support" => await _subscriptionService.HasPrioritySupportAsync(profile.Id),
            _ => throw new InvalidOperationException("ميزة غير معروفة")
        };

        return Ok(new { feature, allowed = result });
    }
}
