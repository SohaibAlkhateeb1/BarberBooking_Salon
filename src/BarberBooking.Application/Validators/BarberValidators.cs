using BarberBooking.Application.DTOs.Barber;
using FluentValidation;

namespace BarberBooking.Application.Validators;

public class BarberRescheduleValidator : AbstractValidator<BarberRescheduleDto>
{
    public BarberRescheduleValidator()
    {
        RuleFor(x => x.NewDate)
            .NotEmpty().WithMessage("التاريخ الجديد مطلوب")
            .GreaterThanOrEqualTo(DateTime.UtcNow.Date).WithMessage("التاريخ يجب أن يكون في المستقبل");

        RuleFor(x => x.NewTime)
            .NotEmpty().WithMessage("الوقت الجديد مطلوب")
            .Matches(@"^\d{2}:\d{2}$").WithMessage("صيغة الوقت غير صحيحة (مثال: 14:30)");
    }
}

public class CreateServiceValidator : AbstractValidator<CreateServiceDto>
{
    public CreateServiceValidator()
    {
        RuleFor(x => x.Name)
            .NotEmpty().WithMessage("اسم الخدمة مطلوب")
            .MaximumLength(200).WithMessage("اسم الخدمة يجب أن يكون أقل من 200 حرف");

        RuleFor(x => x.Price)
            .GreaterThan(0).WithMessage("السعر يجب أن يكون أكبر من 0")
            .LessThanOrEqualTo(10000).WithMessage("السعر يجب أن يكون أقل من 10,000 شيكل");

        RuleFor(x => x.DurationInMinutes)
            .InclusiveBetween(5, 480).WithMessage("المدة يجب أن تكون بين 5 و 480 دقيقة");
    }
}

public class UpdateScheduleValidator : AbstractValidator<UpdateScheduleDto>
{
    public UpdateScheduleValidator()
    {
        RuleFor(x => x.DayName)
            .NotEmpty().WithMessage("اسم اليوم مطلوب")
            .Must(day => new[] { "السبت", "الأحد", "الاثنين", "الثلاثاء", "الأربعاء", "الخميس", "الجمعة" }.Contains(day))
            .WithMessage("اسم اليوم غير صحيح");

        RuleFor(x => x.OpenTime)
            .Matches(@"^\d{2}:\d{2}$").WithMessage("صيغة وقت الفتح غير صحيحة")
            .When(x => x.IsOpen);

        RuleFor(x => x.CloseTime)
            .Matches(@"^\d{2}:\d{2}$").WithMessage("صيغة وقت الإغلاق غير صحيحة")
            .When(x => x.IsOpen);
    }
}
