using System.Text.RegularExpressions;

namespace BarberBooking.API.Middleware;

public class InputSanitizationMiddleware
{
    private readonly RequestDelegate _next;

    public InputSanitizationMiddleware(RequestDelegate next)
    {
        _next = next;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        // Enable buffering so we can read the body multiple times
        context.Request.EnableBuffering();

        await _next(context);
    }
}

public static class InputSanitizer
{
    public static string Sanitize(string? input)
    {
        if (string.IsNullOrEmpty(input))
            return string.Empty;

        // Remove HTML tags
        var sanitized = Regex.Replace(input, "<.*?>", string.Empty);

        // Remove script tags and their content
        sanitized = Regex.Replace(sanitized, @"<script[^>]*>.*?</script>", string.Empty, RegexOptions.IgnoreCase);

        // Remove event handlers
        sanitized = Regex.Replace(sanitized, @"on\w+\s*=\s*[""'][^""']*[""']", string.Empty, RegexOptions.IgnoreCase);

        return sanitized.Trim();
    }

    public static string SanitizePhone(string? phone)
    {
        if (string.IsNullOrEmpty(phone))
            return string.Empty;

        // Remove all non-digit characters except + at the start
        var cleaned = Regex.Replace(phone, @"[^\d+]", "");

        // Remove + if not at the start
        if (cleaned.Contains('+'))
        {
            var firstPlus = cleaned.IndexOf('+');
            cleaned = "+" + cleaned.Substring(firstPlus + 1).Replace("+", "");
        }

        return cleaned;
    }

    public static string SanitizeEmail(string? email)
    {
        if (string.IsNullOrEmpty(email))
            return string.Empty;

        return email.Trim().ToLowerInvariant();
    }
}
