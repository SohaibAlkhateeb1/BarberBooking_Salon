using System.IdentityModel.Tokens.Jwt;
using System.Text;
using BarberBooking.API.Authorization;
using BarberBooking.API.Data;
using BarberBooking.API.Hubs;
using BarberBooking.API.Middleware;
using BarberBooking.API.Services;
using BarberBooking.Application;
using BarberBooking.Application.Interfaces;
using BarberBooking.Infrastructure;
using BarberBooking.Infrastructure.Data;
using BarberBooking.Infrastructure.Services;
using FluentValidation.AspNetCore;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;

using Serilog;

var builder = WebApplication.CreateBuilder(args);

// --- Serilog ---
builder.Host.UseSerilog((ctx, lc) => lc
    .ReadFrom.Configuration(ctx.Configuration)
    .Enrich.FromLogContext()
    .WriteTo.Console());

// --- Environment Variables (Secrets) ---
builder.Configuration
    .AddJsonFile("appsettings.json", optional: false, reloadOnChange: true)
    .AddJsonFile($"appsettings.{builder.Environment.EnvironmentName}.json", optional: true, reloadOnChange: true)
    .AddUserSecrets<Program>(optional: true)
    .AddEnvironmentVariables(prefix: "");

// Validate required secrets (skip during design-time / migrations)
var isDesignTime = Environment.GetCommandLineArgs().Any(a => a.Contains("ef"));
if (!isDesignTime)
{
    var jwtSecret = builder.Configuration["Jwt:Secret"];
    var dbConnection = builder.Configuration.GetConnectionString("DefaultConnection");

    if (string.IsNullOrEmpty(jwtSecret) || jwtSecret.Length < 32)
        throw new InvalidOperationException("JWT Secret is not configured. Set JWT_SECRET environment variable.");

    if (string.IsNullOrEmpty(dbConnection))
        throw new InvalidOperationException("Database connection string is not configured. Set ConnectionStrings__DefaultConnection environment variable.");

    // Ensure SSL for Supabase connections
    if (dbConnection.Contains("supabase") && !dbConnection.Contains("SSL Mode"))
    {
        dbConnection += ";SSL Mode=Require;Trust Server Certificate=true";
        builder.Configuration["ConnectionStrings:DefaultConnection"] = dbConnection;
    }
}

// --- Application Layer ---
builder.Services.AddApplication();

// --- Infrastructure Layer ---
builder.Services.AddInfrastructure(builder.Configuration);

// --- File Storage Service ---
var cloudName = builder.Configuration["Cloudinary:CloudName"];
var cloudApiKey = builder.Configuration["Cloudinary:ApiKey"];
var cloudApiSecret = builder.Configuration["Cloudinary:ApiSecret"];
if (!string.IsNullOrEmpty(cloudName) && !string.IsNullOrEmpty(cloudApiKey) && !string.IsNullOrEmpty(cloudApiSecret))
{
    builder.Services.AddSingleton<IFileStorageService>(new CloudinaryStorageService(cloudName, cloudApiKey, cloudApiSecret));
}
else
{
    var uploadsPath = Path.Combine(builder.Environment.ContentRootPath, "uploads");
    var uploadsBaseUrl = "/uploads";
    builder.Services.AddSingleton<IFileStorageService>(new LocalFileStorageService(uploadsPath, uploadsBaseUrl));
}

// --- Controllers + FluentValidation ---
builder.Services.AddControllers()
    .AddFluentValidation(fv =>
    {
        fv.RegisterValidatorsFromAssemblyContaining<BarberBooking.Application.DTOs.Auth.RegisterCustomerDto>();
    });
builder.Services.ConfigureHttpJsonOptions(options =>
{
    options.SerializerOptions.MaxDepth = 64;
});
builder.WebHost.ConfigureKestrel(options =>
{
    options.Limits.MaxRequestBodySize = 52428800; // 50MB
});

// --- CORS (Limited to Flutter + Admin origins) ---
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFlutter", policy =>
    {
        policy.SetIsOriginAllowed(origin =>
            {
                var uri = new Uri(origin);
                return uri.Host == "localhost"
                    || uri.Host == "127.0.0.1"
                    || uri.Host == "10.0.2.2"
                    || uri.Host == "192.168.1.11"
                    || uri.Host.Contains("web.app")
                    || uri.Host.Contains("firebaseapp.com")
                    || uri.Host.Contains("vercel.app");
            })
            .AllowAnyMethod()
            .AllowAnyHeader()
            .AllowCredentials();
    });
});

// --- Rate Limiting ---
builder.Services.AddRateLimiter(options =>
{
    options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;

    options.AddFixedWindowLimiter("auth", opt =>
    {
        opt.PermitLimit = 5;
        opt.Window = TimeSpan.FromMinutes(1);
    });

    options.AddFixedWindowLimiter("api", opt =>
    {
        opt.PermitLimit = 30;
        opt.Window = TimeSpan.FromMinutes(1);
    });

    options.AddFixedWindowLimiter("upload", opt =>
    {
        opt.PermitLimit = 10;
        opt.Window = TimeSpan.FromMinutes(1);
    });
});

// --- JWT Authentication ---
var jwtSettings = builder.Configuration.GetSection("Jwt").Get<BarberBooking.Infrastructure.Models.JwtSettings>()!;
var key = Encoding.UTF8.GetBytes(jwtSettings.Secret);

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,
        ValidIssuer = jwtSettings.Issuer,
        ValidAudience = jwtSettings.Audience,
        IssuerSigningKey = new SymmetricSecurityKey(key)
    };

    options.Events = new JwtBearerEvents
    {
        OnTokenValidated = async context =>
        {
            var jti = context.Principal?.FindFirst(JwtRegisteredClaimNames.Jti)?.Value;
            if (!string.IsNullOrEmpty(jti))
            {
                var dbContext = context.HttpContext.RequestServices.GetRequiredService<BarberBookingDbContext>();
                var isRevoked = await dbContext.RevokedTokens
                    .AnyAsync(r => r.Jti == jti);
                if (isRevoked)
                {
                    context.Fail("Token has been revoked");
                }
            }
        }
    };
});

builder.Services.AddAuthorization();

// --- Subscription Services ---
    builder.Services.AddScoped<ISubscriptionService, SubscriptionService>();
    builder.Services.AddScoped<IPaymentRequestService, PaymentRequestService>();
    builder.Services.AddScoped<IBookingLimitService, BookingLimitService>();
    builder.Services.AddScoped<ISupportTicketService, SupportTicketService>();
builder.Services.AddSubscriptionPolicies();

// --- FCM Notification Service ---
builder.Services.AddHttpClient();

// --- Operations Center Services ---
builder.Services.AddScoped<IAuditLogService, AuditLogService>();
builder.Services.AddScoped<IAutoAlertService, AutoAlertService>();
builder.Services.AddHostedService(sp =>
{
    return new AutoAlertService(sp);
});

// --- FCM Notifications ---
builder.Services.AddScoped<BarberBooking.API.Services.IFirebasePushService, BarberBooking.API.Services.FcmNotificationService>();

// --- SignalR ---
builder.Services.AddSignalR();

// --- Health Checks ---
builder.Services.AddHealthChecks()
    .AddDbContextCheck<BarberBookingDbContext>();

// --- Swagger with JWT ---
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "BarberBooking API",
        Version = "v1",
        Description = "Barber Booking Platform API"
    });

    options.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Name = "Authorization",
        Type = SecuritySchemeType.Http,
        Scheme = "bearer",
        BearerFormat = "JWT",
        In = ParameterLocation.Header,
        Description = "Enter your JWT token"
    });

    options.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            Array.Empty<string>()
        }
    });
});

// --- Background Services ---
builder.Services.AddHostedService<BookingReminderService>();
builder.Services.AddHostedService<SubscriptionExpiryService>();
builder.Services.AddHostedService<PendingBookingExpiryService>();
builder.Services.AddHostedService<DailyCancelResetService>();
builder.Services.AddHostedService<ServiceTimerService>();

// --- Build App ---
var app = builder.Build();

// --- Middleware Pipeline ---
app.UseMiddleware<InputSanitizationMiddleware>();
app.UseMiddleware<GlobalExceptionHandlingMiddleware>();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI(options =>
    {
        options.SwaggerEndpoint("/swagger/v1/swagger.json", "BarberBooking API v1");
    });
}

app.UseHttpsRedirection();
app.UseRateLimiter();
app.UseCors("AllowFlutter");

// --- Serve uploaded files (before auth so images are accessible without token) ---
var uploadDir = Path.Combine(app.Environment.ContentRootPath, "uploads");
if (!Directory.Exists(uploadDir))
    Directory.CreateDirectory(uploadDir);
app.UseStaticFiles(new StaticFileOptions
{
    FileProvider = new Microsoft.Extensions.FileProviders.PhysicalFileProvider(uploadDir),
    RequestPath = "/uploads"
});

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();
app.MapHub<NotificationHub>("/hubs/notifications");
app.MapHealthChecks("/health");

// --- Database Migration + Seed ---
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<BarberBookingDbContext>();
    var logger = scope.ServiceProvider.GetRequiredService<ILogger<Program>>();
    try
    {
        await db.Database.MigrateAsync();
        await SeedData.SeedAsync(db);
    }
    catch (Exception ex)
    {
        logger.LogCritical(ex, "Database startup failed. Migration or seed error.");
        throw;
    }
}

app.Run();

