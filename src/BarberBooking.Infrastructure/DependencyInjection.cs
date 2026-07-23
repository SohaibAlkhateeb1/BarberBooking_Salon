using BarberBooking.Application.Interfaces;
using BarberBooking.Infrastructure.Data;
using BarberBooking.Infrastructure.Models;
using BarberBooking.Infrastructure.Services;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace BarberBooking.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(this IServiceCollection services, IConfiguration configuration)
    {
        services.Configure<JwtSettings>(configuration.GetSection("Jwt"));

        services.AddDbContext<BarberBookingDbContext>(options =>
            options.UseNpgsql(configuration.GetConnectionString("DefaultConnection")));

        services.AddScoped<IAuthService, AuthService>();
        services.AddScoped<IBarberAuthService, BarberAuthService>();
        services.AddScoped<ISmsService, MockSmsService>();
        services.AddScoped<IJwtTokenService, JwtTokenService>();

        return services;
    }
}
