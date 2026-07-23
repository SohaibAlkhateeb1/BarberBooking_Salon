using System.Net;
using System.Text.Json;
using BarberBooking.Domain.Exceptions;

namespace BarberBooking.API.Middleware;

public class GlobalExceptionHandlingMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<GlobalExceptionHandlingMiddleware> _logger;

    public GlobalExceptionHandlingMiddleware(RequestDelegate next, ILogger<GlobalExceptionHandlingMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await _next(context);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "EXCEPTION: {Type}: {Message}", ex.GetType().Name, ex.Message);
            if (ex.InnerException != null)
                _logger.LogError(ex.InnerException, "INNER: {Type}: {Message}", ex.InnerException.GetType().Name, ex.InnerException.Message);
            await HandleExceptionAsync(context, ex);
        }
    }

    private static async Task HandleExceptionAsync(HttpContext context, Exception exception)
    {
        var (statusCode, message) = exception switch
        {
            BadRequestException ex => (HttpStatusCode.BadRequest, ex.Message),
            ConflictException ex => (HttpStatusCode.Conflict, ex.Message),
            NotFoundException ex => (HttpStatusCode.NotFound, ex.Message),
            FluentValidation.ValidationException ex => (
                HttpStatusCode.BadRequest,
                string.Join(", ", ex.Errors.Select(e => e.ErrorMessage))
            ),
            _ => (HttpStatusCode.InternalServerError, "حدث خطأ غير متوقع")
        };

        context.Response.ContentType = "application/json";
        context.Response.StatusCode = (int)statusCode;

        var response = new
        {
            success = false,
            message = message,
            statusCode = (int)statusCode
        };

        var json = JsonSerializer.Serialize(response, new JsonSerializerOptions
        {
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase
        });

        await context.Response.WriteAsync(json);
    }
}
