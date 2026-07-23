using BarberBooking.Application.DTOs.Booking;
using FluentValidation;

namespace BarberBooking.Application.Validators;

public class CreateBookingValidator : AbstractValidator<CreateBookingDto>
{
    public CreateBookingValidator()
    {
        RuleFor(x => x.BarberProfileId)
            .NotEmpty().WithMessage("معرف الحلاق مطلوب");

        RuleFor(x => x.BarberServiceId)
            .NotEmpty().WithMessage("معرف الخدمة مطلوب");

        RuleFor(x => x.BookingDate)
            .NotEmpty().WithMessage("تاريخ الحجز مطلوب")
            .GreaterThanOrEqualTo(DateTime.UtcNow.Date).WithMessage("تاريخ الحجز يجب أن يكون في المستقبل");

        RuleFor(x => x.BookingTime)
            .NotEmpty().WithMessage("وقت الحجز مطلوب")
            .Matches(@"^\d{2}:\d{2}$").WithMessage("صيغة الوقت غير صحيحة (مثال: 14:30)");
    }
}

public class RescheduleValidator : AbstractValidator<RescheduleDto>
{
    public RescheduleValidator()
    {
        RuleFor(x => x.NewDate)
            .NotEmpty().WithMessage("التاريخ الجديد مطلوب")
            .GreaterThanOrEqualTo(DateTime.UtcNow.Date).WithMessage("التاريخ يجب أن يكون في المستقبل");

        RuleFor(x => x.NewTime)
            .NotEmpty().WithMessage("الوقت الجديد مطلوب")
            .Matches(@"^\d{2}:\d{2}$").WithMessage("صيغة الوقت غير صحيحة (مثال: 14:30)");
    }
}

public class AddReviewValidator : AbstractValidator<AddReviewDto>
{
    public AddReviewValidator()
    {
        RuleFor(x => x.Rating)
            .InclusiveBetween(1, 5).WithMessage("التقييم يجب أن يكون بين 1 و 5");

        RuleFor(x => x.Comment)
            .MaximumLength(1000).WithMessage("التعليق يجب أن يكون أقل من 1000 حرف")
            .When(x => !string.IsNullOrEmpty(x.Comment));
    }
}
