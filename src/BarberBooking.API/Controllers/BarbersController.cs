using BarberBooking.Infrastructure.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace BarberBooking.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class BarbersController : ControllerBase
{
    private readonly BarberBookingDbContext _context;

    public BarbersController(BarberBookingDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll(
        [FromQuery] string? city,
        [FromQuery] string? search,
        [FromQuery] double? minRating,
        [FromQuery] string? priceCategory)
    {
        var query = _context.BarberProfiles
            .Include(bp => bp.User)
            .Include(bp => bp.Services)
            .Include(bp => bp.Reviews)
            .AsQueryable();

        if (!string.IsNullOrEmpty(city))
            query = query.Where(bp => bp.City == city);

        if (!string.IsNullOrEmpty(search))
        {
            var searchLower = search.ToLower();
            query = query.Where(bp =>
                bp.ShopName.ToLower().Contains(searchLower) ||
                bp.User.FullName.ToLower().Contains(searchLower) ||
                bp.Address.ToLower().Contains(searchLower) ||
                bp.City.ToLower().Contains(searchLower) ||
                bp.Services.Any(s => s.Name.ToLower().Contains(searchLower)));
        }

        var allBarbers = await query.ToListAsync();

        if (minRating.HasValue)
            allBarbers = allBarbers.Where(bp => bp.Reviews.Any() && bp.Reviews.Average(r => r.Rating) >= minRating.Value).ToList();

        if (!string.IsNullOrEmpty(priceCategory))
        {
            switch (priceCategory)
            {
                case "اقتصادي":
                    allBarbers = allBarbers.Where(bp => bp.Services.Any(s => s.Price < 30)).ToList();
                    break;
                case "متوسطة":
                    allBarbers = allBarbers.Where(bp => bp.Services.Any(s => s.Price >= 30 && s.Price < 80)).ToList();
                    break;
                case "VIP":
                    allBarbers = allBarbers.Where(bp => bp.Services.Any(s => s.Price >= 80)).ToList();
                    break;
            }
        }

        var barbers = allBarbers.Select(bp => new
        {
            id = bp.Id,
            shopName = bp.ShopName,
            shopDescription = bp.ShopDescription,
            shopLogoUrl = bp.ShopLogoUrl,
            coverImageUrl = bp.CoverImageUrl,
            city = bp.City,
            address = bp.Address,
            ownerName = bp.User.FullName,
            averageRating = bp.Reviews.Any() ? Math.Round(bp.Reviews.Average(r => r.Rating), 1) : 0.0,
            reviewCount = bp.Reviews.Count,
            services = bp.Services.Select(s => new
            {
                id = s.Id,
                name = s.Name,
                price = s.Price,
                durationInMinutes = s.DurationInMinutes
            }).ToList(),
            isOpen = true,
            latitude = bp.Latitude,
            longitude = bp.Longitude
        }).ToList();

        return Ok(barbers);
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetById(Guid id)
    {
        var barber = await _context.BarberProfiles
            .Include(bp => bp.User)
            .Include(bp => bp.Services)
            .Include(bp => bp.WorkingHours)
            .Include(bp => bp.Reviews)
                .ThenInclude(r => r.Customer)
            .Include(bp => bp.PortfolioImages)
            .FirstOrDefaultAsync(bp => bp.Id == id);

        if (barber == null)
            return NotFound(new { message = "الحلاق غير موجود" });

        return Ok(new
        {
            id = barber.Id,
            shopName = barber.ShopName,
            shopDescription = barber.ShopDescription,
            shopLogoUrl = barber.ShopLogoUrl,
            coverImageUrl = barber.CoverImageUrl,
            profileImageUrl = barber.User.ProfileImageUrl,
            city = barber.City,
            address = barber.Address,
            ownerName = barber.User.FullName,
            averageRating = barber.Reviews.Any() ? Math.Round(barber.Reviews.Average(r => r.Rating), 1) : 0.0,
            reviewCount = barber.Reviews.Count,
            services = barber.Services.Select(s => new
            {
                id = s.Id,
                name = s.Name,
                price = s.Price,
                durationInMinutes = s.DurationInMinutes
            }).ToList(),
            workingHours = barber.WorkingHours.Select(wh => new
            {
                dayName = wh.DayName,
                isOpen = wh.IsOpen,
                openTime = wh.OpenTime.ToString(@"hh\:mm"),
                closeTime = wh.CloseTime.ToString(@"hh\:mm")
            }).ToList(),
            reviews = barber.Reviews.OrderByDescending(r => r.CreatedAt).Take(10).Select(r => new
            {
                id = r.Id,
                customerName = r.Customer.FullName,
                rating = r.Rating,
                comment = r.Comment,
                createdAt = r.CreatedAt
            }).ToList(),
            portfolioImages = barber.PortfolioImages.OrderBy(p => p.SortOrder).Select(p => new
            {
                id = p.Id,
                imageUrl = p.ImageUrl,
                caption = p.Caption,
                sortOrder = p.SortOrder
            }).ToList(),
            employees = _context.BarberEmployees
                .Where(e => e.BarberProfileId == barber.Id && e.IsActive)
                .Select(e => new
                {
                    id = e.Id,
                    name = e.Name,
                    phoneNumber = e.PhoneNumber,
                    profileImageUrl = e.ProfileImageUrl
                }).ToList(),
            latitude = barber.Latitude,
            longitude = barber.Longitude
        });
    }

    [HttpGet("{barberProfileId}/employee-services")]
    public async Task<IActionResult> GetEmployeeServices(Guid barberProfileId, [FromQuery] Guid? employeeId = null)
    {
        if (employeeId == null || employeeId == Guid.Empty)
        {
            var allServices = await _context.BarberServices
                .Where(s => s.BarberProfileId == barberProfileId)
                .Select(s => new
                {
                    id = s.Id,
                    name = s.Name,
                    price = s.Price,
                    durationInMinutes = s.DurationInMinutes
                }).ToListAsync();
            return Ok(allServices);
        }

        var assignedServiceIds = await _context.EmployeeServices
            .Where(es => es.EmployeeId == employeeId)
            .Select(es => es.BarberServiceId)
            .ToListAsync();

        var services = await _context.BarberServices
            .Where(s => s.BarberProfileId == barberProfileId && assignedServiceIds.Contains(s.Id))
            .Select(s => new
            {
                id = s.Id,
                name = s.Name,
                price = s.Price,
                durationInMinutes = s.DurationInMinutes
            }).ToListAsync();

        return Ok(services);
    }

    [HttpGet("nearby")]
    public async Task<IActionResult> GetNearby(
        [FromQuery] double latitude,
        [FromQuery] double longitude,
        [FromQuery] double radiusKm = 20)
    {
        var barbers = await _context.BarberProfiles
            .Include(bp => bp.User)
            .Include(bp => bp.Services)
            .Include(bp => bp.Reviews)
            .ToListAsync();

        var nearby = barbers
            .Where(bp => bp.Latitude.HasValue && bp.Longitude.HasValue)
            .Select(bp => new
            {
                id = bp.Id,
                shopName = bp.ShopName,
                shopDescription = bp.ShopDescription,
                shopLogoUrl = bp.ShopLogoUrl,
                city = bp.City,
                address = bp.Address,
                ownerName = bp.User.FullName,
                averageRating = bp.Reviews.Any() ? Math.Round(bp.Reviews.Average(r => r.Rating), 1) : 0.0,
                reviewCount = bp.Reviews.Count,
                services = bp.Services.Select(s => new
                {
                    id = s.Id,
                    name = s.Name,
                    price = s.Price,
                    durationInMinutes = s.DurationInMinutes
                }).ToList(),
                isOpen = true,
                latitude = bp.Latitude,
                longitude = bp.Longitude,
                distanceKm = Math.Round(CalculateDistance(latitude, longitude, bp.Latitude!.Value, bp.Longitude!.Value), 1)
            })
            .Where(bp => bp.distanceKm <= radiusKm)
            .OrderBy(bp => bp.distanceKm)
            .ToList();

        return Ok(nearby);
    }

    private static double CalculateDistance(double lat1, double lon1, double lat2, double lon2)
    {
        var R = 6371.0;
        var dLat = ToRadians(lat2 - lat1);
        var dLon = ToRadians(lon2 - lon1);
        var a = Math.Sin(dLat / 2) * Math.Sin(dLat / 2) +
                Math.Cos(ToRadians(lat1)) * Math.Cos(ToRadians(lat2)) *
                Math.Sin(dLon / 2) * Math.Sin(dLon / 2);
        var c = 2 * Math.Atan2(Math.Sqrt(a), Math.Sqrt(1 - a));
        return R * c;
    }

    private static double ToRadians(double deg) => deg * Math.PI / 180.0;
}
