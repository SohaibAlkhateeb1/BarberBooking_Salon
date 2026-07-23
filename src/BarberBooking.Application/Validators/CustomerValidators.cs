using BarberBooking.Application.DTOs.Customer;
using FluentValidation;

namespace BarberBooking.Application.Validators;

public class UpdateProfileValidator : AbstractValidator<UpdateProfileDto>
{
    public UpdateProfileValidator()
    {
        RuleFor(x => x.FullName)
            .MaximumLength(200).WithMessage("الاسم يجب أن يكون أقل من 200 حرف")
            .When(x => !string.IsNullOrEmpty(x.FullName));

        RuleFor(x => x.PhoneNumber)
            .Must(BeValidPalestinianPhone).WithMessage("رقم الهاتف يجب أن يكون رقم فلسطيني صحيح")
            .When(x => !string.IsNullOrEmpty(x.PhoneNumber));

        RuleFor(x => x.Email)
            .EmailAddress().WithMessage("البريد الإلكتروني غير صالح")
            .When(x => !string.IsNullOrEmpty(x.Email));
    }

    private static bool BeValidPalestinianPhone(string phone)
    {
        if (string.IsNullOrEmpty(phone)) return true;
        phone = phone.Replace(" ", "").Replace("-", "");
        if (System.Text.RegularExpressions.Regex.IsMatch(phone, @"^05\d{8}$")) return true;
        if (phone.StartsWith("+970") && phone.Length == 13 &&
            System.Text.RegularExpressions.Regex.IsMatch(phone, @"^\+9705\d{8}$")) return true;
        if (phone.StartsWith("970") && phone.Length == 12 &&
            System.Text.RegularExpressions.Regex.IsMatch(phone, @"^9705\d{8}$")) return true;
        return false;
    }
}
