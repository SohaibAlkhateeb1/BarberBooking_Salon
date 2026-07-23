using BarberBooking.Application.DTOs.Auth;
using FluentValidation;

namespace BarberBooking.Application.Validators;

public class SendOtpValidator : AbstractValidator<SendOtpDto>
{
    public SendOtpValidator()
    {
        RuleFor(x => x.PhoneNumber)
            .NotEmpty().WithMessage("رقم الهاتف مطلوب")
            .Must(BeValidPalestinianPhone).WithMessage("رقم الهاتف يجب أن يكون رقم فلسطيني صحيح");

        RuleFor(x => x.Purpose)
            .Must(p => string.IsNullOrEmpty(p) || new[] { "register", "reset", "verify" }.Contains(p.ToLower()))
            .WithMessage("الغرض يجب أن يكون register أو reset أو verify")
            .When(x => !string.IsNullOrEmpty(x.Purpose));
    }

    private static bool BeValidPalestinianPhone(string phone)
    {
        if (string.IsNullOrEmpty(phone)) return false;
        phone = phone.Replace(" ", "").Replace("-", "");
        if (System.Text.RegularExpressions.Regex.IsMatch(phone, @"^05\d{8}$")) return true;
        if (phone.StartsWith("+970") && phone.Length == 13 &&
            System.Text.RegularExpressions.Regex.IsMatch(phone, @"^\+9705\d{8}$")) return true;
        if (phone.StartsWith("970") && phone.Length == 12 &&
            System.Text.RegularExpressions.Regex.IsMatch(phone, @"^9705\d{8}$")) return true;
        return false;
    }
}

public class VerifyOtpValidator : AbstractValidator<VerifyOtpDto>
{
    public VerifyOtpValidator()
    {
        RuleFor(x => x.PhoneNumber)
            .NotEmpty().WithMessage("رقم الهاتف مطلوب")
            .Must(BeValidPalestinianPhone).WithMessage("رقم الهاتف غير صحيح");

        RuleFor(x => x.Code)
            .NotEmpty().WithMessage("رمز التحقق مطلوب")
            .Matches(@"^\d{6}$").WithMessage("رمز التحقق يجب أن يكون 6 أرقام");
    }

    private static bool BeValidPalestinianPhone(string phone)
    {
        if (string.IsNullOrEmpty(phone)) return false;
        phone = phone.Replace(" ", "").Replace("-", "");
        if (System.Text.RegularExpressions.Regex.IsMatch(phone, @"^05\d{8}$")) return true;
        if (phone.StartsWith("+970") && phone.Length == 13 &&
            System.Text.RegularExpressions.Regex.IsMatch(phone, @"^\+9705\d{8}$")) return true;
        if (phone.StartsWith("970") && phone.Length == 12 &&
            System.Text.RegularExpressions.Regex.IsMatch(phone, @"^9705\d{8}$")) return true;
        return false;
    }
}

public class ForgotPasswordValidator : AbstractValidator<ForgotPasswordDto>
{
    public ForgotPasswordValidator()
    {
        RuleFor(x => x.PhoneNumber)
            .NotEmpty().WithMessage("رقم الهاتف مطلوب")
            .Must(BeValidPalestinianPhone).WithMessage("رقم الهاتف غير صحيح");
    }

    private static bool BeValidPalestinianPhone(string phone)
    {
        if (string.IsNullOrEmpty(phone)) return false;
        phone = phone.Replace(" ", "").Replace("-", "");
        if (System.Text.RegularExpressions.Regex.IsMatch(phone, @"^05\d{8}$")) return true;
        if (phone.StartsWith("+970") && phone.Length == 13 &&
            System.Text.RegularExpressions.Regex.IsMatch(phone, @"^\+9705\d{8}$")) return true;
        if (phone.StartsWith("970") && phone.Length == 12 &&
            System.Text.RegularExpressions.Regex.IsMatch(phone, @"^9705\d{8}$")) return true;
        return false;
    }
}

public class ResetPasswordValidator : AbstractValidator<ResetPasswordDto>
{
    public ResetPasswordValidator()
    {
        RuleFor(x => x.PhoneNumber)
            .NotEmpty().WithMessage("رقم الهاتف مطلوب")
            .Must(BeValidPalestinianPhone).WithMessage("رقم الهاتف غير صحيح");

        RuleFor(x => x.Code)
            .NotEmpty().WithMessage("رمز التحقق مطلوب")
            .Matches(@"^\d{6}$").WithMessage("رمز التحقق يجب أن يكون 6 أرقام");

        RuleFor(x => x.NewPassword)
            .NotEmpty().WithMessage("كلمة المرور الجديدة مطلوبة")
            .MinimumLength(8).WithMessage("كلمة المرور يجب أن تكون 8 أحرف على الأقل")
            .Matches("[A-Z]").WithMessage("كلمة المرور يجب أن تحتوي على حرف كبير")
            .Matches("[a-z]").WithMessage("كلمة المرور يجب أن تحتوي على حرف صغير")
            .Matches("[0-9]").WithMessage("كلمة المرور يجب أن تحتوي على رقم");
    }

    private static bool BeValidPalestinianPhone(string phone)
    {
        if (string.IsNullOrEmpty(phone)) return false;
        phone = phone.Replace(" ", "").Replace("-", "");
        if (System.Text.RegularExpressions.Regex.IsMatch(phone, @"^05\d{8}$")) return true;
        if (phone.StartsWith("+970") && phone.Length == 13 &&
            System.Text.RegularExpressions.Regex.IsMatch(phone, @"^\+9705\d{8}$")) return true;
        if (phone.StartsWith("970") && phone.Length == 12 &&
            System.Text.RegularExpressions.Regex.IsMatch(phone, @"^9705\d{8}$")) return true;
        return false;
    }
}

public class RefreshTokenValidator : AbstractValidator<RefreshTokenDto>
{
    public RefreshTokenValidator()
    {
        RuleFor(x => x.RefreshToken)
            .NotEmpty().WithMessage("Refresh Token مطلوب");
    }
}

public class RegisterCustomerValidator : AbstractValidator<RegisterCustomerDto>
{
    public RegisterCustomerValidator()
    {
        RuleFor(x => x.FullName)
            .NotEmpty().WithMessage("الاسم الكامل مطلوب")
            .MaximumLength(200).WithMessage("الاسم الكامل يجب أن يكون أقل من 200 حرف");

        RuleFor(x => x.PhoneNumber)
            .NotEmpty().WithMessage("رقم الهاتف مطلوب")
            .Must(BeValidPalestinianPhone).WithMessage("رقم الهاتف يجب أن يكون رقم فلسطيني صحيح");

        RuleFor(x => x.Password)
            .NotEmpty().WithMessage("كلمة المرور مطلوبة")
            .MinimumLength(8).WithMessage("كلمة المرور يجب أن تكون 8 أحرف على الأقل")
            .Matches("[A-Z]").WithMessage("كلمة المرور يجب أن تحتوي على حرف كبير")
            .Matches("[a-z]").WithMessage("كلمة المرور يجب أن تحتوي على حرف صغير")
            .Matches("[0-9]").WithMessage("كلمة المرور يجب أن تحتوي على رقم");

        RuleFor(x => x.Email)
            .EmailAddress().WithMessage("البريد الإلكتروني غير صالح")
            .When(x => !string.IsNullOrEmpty(x.Email));

        RuleFor(x => x.AcceptTerms)
            .Equal(true).WithMessage("يجب الموافقة على الشروط والخصوصية");
    }

    private static bool BeValidPalestinianPhone(string phone)
    {
        if (string.IsNullOrEmpty(phone)) return false;
        phone = phone.Replace(" ", "").Replace("-", "");
        if (System.Text.RegularExpressions.Regex.IsMatch(phone, @"^05\d{8}$")) return true;
        if (phone.StartsWith("+970") && phone.Length == 13 &&
            System.Text.RegularExpressions.Regex.IsMatch(phone, @"^\+9705\d{8}$")) return true;
        if (phone.StartsWith("970") && phone.Length == 12 &&
            System.Text.RegularExpressions.Regex.IsMatch(phone, @"^9705\d{8}$")) return true;
        return false;
    }
}

public class RegisterBarberValidator : AbstractValidator<RegisterBarberDto>
{
    public RegisterBarberValidator()
    {
        RuleFor(x => x.FullName)
            .NotEmpty().WithMessage("الاسم الكامل مطلوب")
            .MaximumLength(200).WithMessage("الاسم الكامل يجب أن يكون أقل من 200 حرف");

        RuleFor(x => x.PhoneNumber)
            .NotEmpty().WithMessage("رقم الهاتف مطلوب")
            .Must(BeValidPalestinianPhone).WithMessage("رقم الهاتف يجب أن يكون رقم فلسطيني صحيح");

        RuleFor(x => x.Password)
            .NotEmpty().WithMessage("كلمة المرور مطلوبة")
            .MinimumLength(8).WithMessage("كلمة المرور يجب أن تكون 8 أحرف على الأقل")
            .Matches("[A-Z]").WithMessage("كلمة المرور يجب أن تحتوي على حرف كبير")
            .Matches("[a-z]").WithMessage("كلمة المرور يجب أن تحتوي على حرف صغير")
            .Matches("[0-9]").WithMessage("كلمة المرور يجب أن تحتوي على رقم");

        RuleFor(x => x.ShopName)
            .NotEmpty().WithMessage("اسم الصالة مطلوب")
            .MaximumLength(200).WithMessage("اسم الصالة يجب أن يكون أقل من 200 حرف");

        RuleFor(x => x.City)
            .NotEmpty().WithMessage("المدينة مطلوبة");

        RuleFor(x => x.Address)
            .NotEmpty().WithMessage("العنوان مطلوب");

        RuleFor(x => x.AcceptTerms)
            .Equal(true).WithMessage("يجب الموافقة على الشروط والخصوصية");
    }

    private static bool BeValidPalestinianPhone(string phone)
    {
        if (string.IsNullOrEmpty(phone)) return false;
        phone = phone.Replace(" ", "").Replace("-", "");
        if (System.Text.RegularExpressions.Regex.IsMatch(phone, @"^05\d{8}$")) return true;
        if (phone.StartsWith("+970") && phone.Length == 13 &&
            System.Text.RegularExpressions.Regex.IsMatch(phone, @"^\+9705\d{8}$")) return true;
        if (phone.StartsWith("970") && phone.Length == 12 &&
            System.Text.RegularExpressions.Regex.IsMatch(phone, @"^9705\d{8}$")) return true;
        return false;
    }
}

public class LoginValidator : AbstractValidator<LoginDto>
{
    public LoginValidator()
    {
        RuleFor(x => x.PhoneNumber)
            .NotEmpty().WithMessage("رقم الهاتف مطلوب")
            .Must(BeValidPalestinianPhone).WithMessage("رقم الهاتف يجب أن يكون رقم فلسطيني صحيح");

        RuleFor(x => x.Password)
            .NotEmpty().WithMessage("كلمة المرور مطلوبة");
    }

    private static bool BeValidPalestinianPhone(string phone)
    {
        if (string.IsNullOrEmpty(phone)) return false;
        phone = phone.Replace(" ", "").Replace("-", "");
        if (System.Text.RegularExpressions.Regex.IsMatch(phone, @"^05\d{8}$")) return true;
        if (phone.StartsWith("+970") && phone.Length == 13 &&
            System.Text.RegularExpressions.Regex.IsMatch(phone, @"^\+9705\d{8}$")) return true;
        if (phone.StartsWith("970") && phone.Length == 12 &&
            System.Text.RegularExpressions.Regex.IsMatch(phone, @"^9705\d{8}$")) return true;
        return false;
    }
}
