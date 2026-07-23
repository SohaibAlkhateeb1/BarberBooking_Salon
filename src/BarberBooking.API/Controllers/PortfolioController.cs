using BarberBooking.Application.Interfaces;
using BarberBooking.Domain.Entities;
using BarberBooking.Infrastructure.Data;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace BarberBooking.API.Controllers;

[ApiController]
[Route("api/barber/portfolio")]
[Authorize(Roles = "Barber")]
public class PortfolioController : ControllerBase
{
    private readonly BarberBookingDbContext _context;
    private readonly IFileStorageService _fileStorageService;

    public PortfolioController(BarberBookingDbContext context, IFileStorageService fileStorageService)
    {
        _context = context;
        _fileStorageService = fileStorageService;
    }

    private Guid GetBarberProfileId()
    {
        var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        return _context.BarberProfiles
            .Where(bp => bp.UserId == Guid.Parse(userId!))
            .Select(bp => bp.Id)
            .First();
    }

    [HttpGet]
    public async Task<IActionResult> GetMyPortfolio()
    {
        var profileId = GetBarberProfileId();
        var images = await _context.PortfolioImages
            .Where(p => p.BarberProfileId == profileId)
            .OrderBy(p => p.SortOrder)
            .Select(p => new
            {
                id = p.Id,
                imageUrl = p.ImageUrl,
                caption = p.Caption,
                sortOrder = p.SortOrder
            })
            .ToListAsync();

        return Ok(images);
    }

    [HttpPost]
    public async Task<IActionResult> AddImage([FromBody] AddPortfolioImageRequest request)
    {
        var profileId = GetBarberProfileId();
        var imageUrl = request.ImageUrl;

        if (!string.IsNullOrEmpty(imageUrl) && imageUrl.StartsWith("data:image"))
        {
            imageUrl = await _fileStorageService.SaveImageAsync(imageUrl, "portfolio");
        }

        var image = new BarberPortfolioImage
        {
            BarberProfileId = profileId,
            ImageUrl = imageUrl,
            Caption = request.Caption,
            SortOrder = request.SortOrder
        };

        _context.PortfolioImages.Add(image);
        await _context.SaveChangesAsync();

        return Ok(new
        {
            id = image.Id,
            imageUrl = image.ImageUrl,
            caption = image.Caption,
            sortOrder = image.SortOrder
        });
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateImage(Guid id, [FromBody] UpdatePortfolioImageRequest request)
    {
        var profileId = GetBarberProfileId();
        var image = await _context.PortfolioImages
            .FirstOrDefaultAsync(p => p.Id == id && p.BarberProfileId == profileId);

        if (image == null)
            return NotFound(new { message = "الصورة غير موجودة" });

        image.Caption = request.Caption ?? image.Caption;
        image.SortOrder = request.SortOrder ?? image.SortOrder;
        image.ImageUrl = request.ImageUrl ?? image.ImageUrl;

        await _context.SaveChangesAsync();

        return Ok(new
        {
            id = image.Id,
            imageUrl = image.ImageUrl,
            caption = image.Caption,
            sortOrder = image.SortOrder
        });
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteImage(Guid id)
    {
        var profileId = GetBarberProfileId();
        var image = await _context.PortfolioImages
            .FirstOrDefaultAsync(p => p.Id == id && p.BarberProfileId == profileId);

        if (image == null)
            return NotFound(new { message = "الصورة غير موجودة" });

        if (!string.IsNullOrEmpty(image.ImageUrl) && image.ImageUrl.StartsWith("/uploads/"))
        {
            var filePath = Path.Combine(Directory.GetCurrentDirectory(), image.ImageUrl.TrimStart('/'));
            if (System.IO.File.Exists(filePath))
                System.IO.File.Delete(filePath);
        }

        _context.PortfolioImages.Remove(image);
        await _context.SaveChangesAsync();

        return Ok(new { message = "تم حذف الصورة" });
    }

    [HttpPut("reorder")]
    public async Task<IActionResult> ReorderImages([FromBody] ReorderRequest request)
    {
        var profileId = GetBarberProfileId();
        var images = await _context.PortfolioImages
            .Where(p => p.BarberProfileId == profileId)
            .ToListAsync();

        foreach (var image in images)
        {
            var sortOrder = request.ImageIds.IndexOf(image.Id);
            if (sortOrder >= 0)
                image.SortOrder = sortOrder;
        }

        await _context.SaveChangesAsync();
        return Ok(new { message = "تم تحديث الترتيب" });
    }
}

public class AddPortfolioImageRequest
{
    public string ImageUrl { get; set; } = string.Empty;
    public string? Caption { get; set; }
    public int SortOrder { get; set; }
}

public class UpdatePortfolioImageRequest
{
    public string? ImageUrl { get; set; }
    public string? Caption { get; set; }
    public int? SortOrder { get; set; }
}

public class ReorderRequest
{
    public List<Guid> ImageIds { get; set; } = new();
}
