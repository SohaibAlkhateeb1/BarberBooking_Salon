using System.Security.Claims;
using BarberBooking.Application.DTOs.Support;
using BarberBooking.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace BarberBooking.API.Controllers;

[ApiController]
[Route("api/support")]
public class SupportTicketController : ControllerBase
{
    private readonly ISupportTicketService _supportService;

    public SupportTicketController(ISupportTicketService supportService)
    {
        _supportService = supportService;
    }

    private Guid GetCurrentUserId()
    {
        var sub = User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? User.FindFirst("sub")?.Value;
        return Guid.Parse(sub!);
    }

    private bool IsBarber() => User.IsInRole("Barber");

    [HttpPost("tickets")]
    [Authorize]
    public async Task<IActionResult> CreateTicket([FromBody] CreateTicketDto dto)
    {
        try
        {
            var userId = GetCurrentUserId();
            var ticket = await _supportService.CreateTicketAsync(userId, dto, IsBarber());
            return Ok(ticket);
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpGet("my-tickets")]
    [Authorize]
    public async Task<IActionResult> GetMyTickets()
    {
        try
        {
            var userId = GetCurrentUserId();
            var tickets = await _supportService.GetUserTicketsAsync(userId);
            return Ok(tickets);
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpGet("tickets/{id}")]
    [Authorize]
    public async Task<IActionResult> GetTicketDetail(Guid id)
    {
        try
        {
            var userId = GetCurrentUserId();
            var ticket = await _supportService.GetTicketDetailAsync(id, userId);
            if (ticket == null) return NotFound();
            return Ok(ticket);
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost("tickets/{id}/reply")]
    [Authorize]
    public async Task<IActionResult> AddReply(Guid id, [FromBody] ReplyTicketDto dto)
    {
        try
        {
            var userId = GetCurrentUserId();
            var role = IsBarber() ? "Barber" : "Customer";
            var reply = await _supportService.AddReplyAsync(id, userId, dto, role);
            return Ok(reply);
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost("tickets/{id}/rate")]
    [Authorize]
    public async Task<IActionResult> RateTicket(Guid id, [FromBody] RateTicketDto dto)
    {
        try
        {
            var userId = GetCurrentUserId();
            var result = await _supportService.RateTicketAsync(id, userId, dto);
            if (!result) return BadRequest(new { message = "Cannot rate this ticket" });
            return Ok(new { message = "Rating submitted" });
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }
}
