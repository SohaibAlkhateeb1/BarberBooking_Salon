using System.Security.Claims;
using BarberBooking.Application.DTOs.Support;
using BarberBooking.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace BarberBooking.API.Controllers;

[ApiController]
[Route("api/admin/support")]
[Authorize(Roles = "Admin")]
public class AdminSupportController : ControllerBase
{
    private readonly ISupportTicketService _supportService;

    public AdminSupportController(ISupportTicketService supportService)
    {
        _supportService = supportService;
    }

    private Guid GetAdminId()
    {
        var sub = User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? User.FindFirst("sub")?.Value;
        return Guid.Parse(sub!);
    }

    [HttpGet("tickets")]
    public async Task<IActionResult> GetAllTickets(
        [FromQuery] string? status,
        [FromQuery] string? priority,
        [FromQuery] string? ticketType)
    {
        var tickets = await _supportService.GetAllTicketsAsync(status, priority, ticketType);
        return Ok(tickets);
    }

    [HttpGet("tickets/{id}")]
    public async Task<IActionResult> GetTicketDetail(Guid id)
    {
        var ticket = await _supportService.AdminGetTicketDetailAsync(id);
        if (ticket == null) return NotFound();
        return Ok(ticket);
    }

    [HttpPost("tickets/{id}/reply")]
    public async Task<IActionResult> ReplyToTicket(Guid id, [FromBody] ReplyTicketDto dto)
    {
        try
        {
            var adminId = GetAdminId();
            var reply = await _supportService.AdminReplyAsync(id, adminId, dto);
            return Ok(reply);
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPut("tickets/{id}/status")]
    public async Task<IActionResult> UpdateStatus(Guid id, [FromBody] UpdateTicketStatusDto dto)
    {
        var result = await _supportService.UpdateTicketStatusAsync(id, dto);
        if (!result) return NotFound();
        return Ok(new { message = "Status updated" });
    }
}
