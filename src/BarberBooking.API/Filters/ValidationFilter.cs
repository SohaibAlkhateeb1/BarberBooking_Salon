using FluentValidation;

namespace BarberBooking.API.Filters;

public class ValidationFilter<T> : IEndpointFilter where T : class
{
    public async ValueTask<object?> InvokeAsync(
        EndpointFilterInvocationContext context,
        EndpointFilterDelegate next)
    {
        var validator = context.HttpContext.RequestServices.GetService<IValidator<T>>();

        if (validator == null)
            return await next(context);

        var entity = context.Arguments
            .OfType<T>()
            .FirstOrDefault();

        if (entity == null)
            return await next(context);

        var result = await validator.ValidateAsync(entity);

        if (!result.IsValid)
        {
            var errors = result.Errors
                .Select(e => new { field = e.PropertyName, message = e.ErrorMessage });

            return Results.ValidationProblem(
                result.ToDictionary(),
                title: "Validation failed");
        }

        return await next(context);
    }
}
