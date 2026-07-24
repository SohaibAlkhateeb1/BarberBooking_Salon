using System.Security.Claims;
using System.Text.Json;
using BarberBooking.Application.DTOs.Customer;
using BarberBooking.Application.Interfaces;
using BarberBooking.Domain.Entities;
using BarberBooking.Infrastructure.Data;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace BarberBooking.API.Controllers;

[ApiController]
[Route("api/customer")]
[Authorize(Roles = "Customer")]
public class CustomerController : ControllerBase
{
    private readonly BarberBookingDbContext _context;
    private readonly ILogger<CustomerController> _logger;
    private readonly IFileStorageService _fileStorage;

    public CustomerController(BarberBookingDbContext context, ILogger<CustomerController> logger, IFileStorageService fileStorage)
    {
        _context = context;
        _logger = logger;
        _fileStorage = fileStorage;
    }

    private Guid GetCurrentUserId()
    {
        var sub = User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? User.FindFirst("sub")?.Value;
        if (string.IsNullOrEmpty(sub))
            throw new UnauthorizedAccessException("ط؛ظٹط± ظ…طµط±ط­");
        return Guid.Parse(sub);
    }

    [HttpGet("profile")]
    public async Task<IActionResult> GetProfile()
    {
        var userId = GetCurrentUserId();
        var user = await _context.Users.FindAsync(userId);
        if (user == null) return NotFound(new { message = "ط§ظ„ظ…ط³طھط®ط¯ظ… ط؛ظٹط± ظ…ظˆط¬ظˆط¯" });

        return Ok(new
        {
            id = user.Id,
            fullName = user.FullName,
            phoneNumber = user.PhoneNumber,
            email = user.Email,
            profileImageUrl = user.ProfileImageUrl,
            city = user.City,
            latitude = user.Latitude,
            longitude = user.Longitude,
            role = user.Role
        });
    }

    [HttpPut("profile")]
    [DisableRequestSizeLimit]
    public async Task<IActionResult> UpdateProfile([FromBody] UpdateProfileDto dto)
    {
        var userId = GetCurrentUserId();
        var user = await _context.Users.FindAsync(userId);
        if (user == null) return NotFound(new { message = "ط§ظ„ظ…ط³طھط®ط¯ظ… ط؛ظٹط± ظ…ظˆط¬ظˆط¯" });

        if (!string.IsNullOrEmpty(dto.FullName))
            user.FullName = dto.FullName;
        if (!string.IsNullOrEmpty(dto.PhoneNumber))
            user.PhoneNumber = dto.PhoneNumber;
        if (dto.Email != null)
            user.Email = dto.Email;
        if (dto.ProfileImageUrl != null)
            user.ProfileImageUrl = dto.ProfileImageUrl;
        if (dto.City != null)
            user.City = dto.City;
        if (dto.Latitude.HasValue) user.Latitude = dto.Latitude;
        if (dto.Longitude.HasValue) user.Longitude = dto.Longitude;

        user.UpdatedAt = DateTime.UtcNow;
        await _context.SaveChangesAsync();

        return Ok(new { message = "طھظ… طھط­ط¯ظٹط« ط§ظ„ظ…ظ„ظپ ط§ظ„ط´ط®طµظٹ ط¨ظ†ط¬ط§ط­" });
    }

    [HttpPost("upload-image")]
    [DisableRequestSizeLimit]
    public async Task<IActionResult> UploadImage()
    {
        try
        {
            var userId = GetCurrentUserId();
            var user = await _context.Users.FindAsync(userId);
            if (user == null) return NotFound(new { message = "ط§ظ„ظ…ط³طھط®ط¯ظ… ط؛ظٹط± ظ…ظˆط¬ظˆط¯" });

            using var reader = new StreamReader(Request.Body);
            var body = await reader.ReadToEndAsync();

            _logger.LogInformation("Upload image received, body length: {Length}", body.Length);

            if (string.IsNullOrEmpty(body))
                return BadRequest(new { message = "ط§ظ„طµظˆط±ط© ظ…ط·ظ„ظˆط¨ط©" });

            using var doc = JsonDocument.Parse(body);
            if (doc.RootElement.TryGetProperty("imageBase64", out var imageProp))
            {
                var imageBase64 = imageProp.GetString();
                if (!string.IsNullOrEmpty(imageBase64))
                {
                    if (!string.IsNullOrEmpty(user.ProfileImageUrl))
                    {
                        await _fileStorage.DeleteImageAsync(user.ProfileImageUrl);
                    }
                    var imageUrl = await _fileStorage.SaveImageAsync(imageBase64, "profiles");
                    user.ProfileImageUrl = imageUrl;
                    user.UpdatedAt = DateTime.UtcNow;
                    await _context.SaveChangesAsync();
                    return Ok(new { profileImageUrl = user.ProfileImageUrl, message = "طھظ… ط±ظپط¹ ط§ظ„طµظˆط±ط© ط¨ظ†ط¬ط§ط­" });
                }
            }

            return BadRequest(new { message = "ط§ظ„طµظˆط±ط© ظ…ط·ظ„ظˆط¨ط©" });
        }
        catch (Exception ex)
        {
            var innerMsg = ex.InnerException?.Message ?? "no inner exception";
            var fullMsg = ex.Message + " | Inner: " + innerMsg;
            _logger.LogError(ex, "Error uploading image: {FullMessage}", fullMsg);
            return StatusCode(500, new { message = $"ط®ط·ط£ ظپظٹ ط±ظپط¹ ط§ظ„طµظˆط±ط©: {fullMsg}" });
        }
    }

    [HttpGet("favorites")]
    public async Task<IActionResult> GetFavorites()
    {
        var userId = GetCurrentUserId();
        var favorites = await _context.Set<Favorite>()
            .Where(f => f.UserId == userId)
            .Include(f => f.BarberProfile)
                .ThenInclude(bp => bp.User)
            .Include(f => f.BarberProfile)
                .ThenInclude(bp => bp.Services)
            .Include(f => f.BarberProfile)
                .ThenInclude(bp => bp.Reviews)
            .Select(f => new
            {
                id = f.BarberProfile.Id,
                shopName = f.BarberProfile.ShopName,
                shopDescription = f.BarberProfile.ShopDescription,
                city = f.BarberProfile.City,
                address = f.BarberProfile.Address,
                ownerName = f.BarberProfile.User.FullName,
                averageRating = f.BarberProfile.Reviews.Any() ? Math.Round(f.BarberProfile.Reviews.Average(r => r.Rating), 1) : 0.0,
                reviewCount = f.BarberProfile.Reviews.Count,
                services = f.BarberProfile.Services.Select(s => new
                {
                    id = s.Id,
                    name = s.Name,
                    price = s.Price,
                    durationInMinutes = s.DurationInMinutes
                }).ToList(),
                isOpen = true
            })
            .ToListAsync();

        return Ok(favorites);
    }

    [HttpPost("favorites/{barberProfileId}")]
    public async Task<IActionResult> AddFavorite(Guid barberProfileId)
    {
        var userId = GetCurrentUserId();
        var exists = await _context.Set<Favorite>()
            .AnyAsync(f => f.UserId == userId && f.BarberProfileId == barberProfileId);

        if (exists)
            return BadRequest(new { message = "ظپظٹ ط§ظ„ظ…ظپط¶ظ„ط© ط¨ط§ظ„ظپط¹ظ„" });

        var favorite = new Favorite
        {
            UserId = userId,
            BarberProfileId = barberProfileId
        };

        _context.Set<Favorite>().Add(favorite);
        await _context.SaveChangesAsync();

        return Ok(new { message = "طھظ…طھ ط§ظ„ط¥ط¶ط§ظپط© ظ„ظ„ظ…ظپط¶ظ„ط©" });
    }

    [HttpDelete("favorites/{barberProfileId}")]
    public async Task<IActionResult> RemoveFavorite(Guid barberProfileId)
    {
        var userId = GetCurrentUserId();
        var favorite = await _context.Set<Favorite>()
            .FirstOrDefaultAsync(f => f.UserId == userId && f.BarberProfileId == barberProfileId);

        if (favorite == null)
            return NotFound(new { message = "ط؛ظٹط± ظ…ظˆط¬ظˆط¯ ظپظٹ ط§ظ„ظ…ظپط¶ظ„ط©" });

        _context.Set<Favorite>().Remove(favorite);
        await _context.SaveChangesAsync();

        return Ok(new { message = "طھظ…طھ ط§ظ„ط¥ط²ط§ظ„ط© ظ…ظ† ط§ظ„ظ…ظپط¶ظ„ط©" });
    }

    [HttpGet("favorites/check/{barberProfileId}")]
    public async Task<IActionResult> CheckFavorite(Guid barberProfileId)
    {
        var userId = GetCurrentUserId();
        var isFavorite = await _context.Set<Favorite>()
            .AnyAsync(f => f.UserId == userId && f.BarberProfileId == barberProfileId);

        return Ok(new { isFavorite });
    }

    [HttpGet("reviews")]
    public async Task<IActionResult> GetMyReviews()
    {
        var userId = GetCurrentUserId();
        var reviews = await _context.Reviews
            .Where(r => r.CustomerId == userId)
            .Include(r => r.BarberProfile)
                .ThenInclude(bp => bp.User)
            .OrderByDescending(r => r.CreatedAt)
            .Select(r => new
            {
                id = r.Id,
                barberName = r.BarberProfile.User.FullName,
                shopName = r.BarberProfile.ShopName,
                rating = r.Rating,
                comment = r.Comment,
                createdAt = r.CreatedAt
            })
            .ToListAsync();

        return Ok(reviews);
    }
}

