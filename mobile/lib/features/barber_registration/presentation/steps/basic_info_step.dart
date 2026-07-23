import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_responsive.dart';
import '../../../../core/animations/app_animations.dart';
import '../../../../core/models/barber_registration_data.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/password_field.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/error_extractor.dart';

class BasicInfoStep extends StatefulWidget {
  final BarberRegistrationData data;
  final VoidCallback onNext;
  const BasicInfoStep({super.key, required this.data, required this.onNext});

  @override
  State<BasicInfoStep> createState() => _BasicInfoStepState();
}

class _BasicInfoStepState extends State<BasicInfoStep> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  bool _isCheckingPhone = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.data.fullName);
    _phoneController = TextEditingController(text: widget.data.phoneNumber);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _validateAndNext() async {
    if (!_formKey.currentState!.validate()) return;

    final password = widget.data.password;
    if (password.isEmpty) {
      _showSnack('كلمة المرور مطلوبة');
      return;
    }
    if (password.length < 8) {
      _showSnack('كلمة المرور يجب أن تكون 8 أحرف على الأقل');
      return;
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      _showSnack('كلمة المرور يجب أن تحتوي على حرف كبير واحد على الأقل');
      return;
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      _showSnack('كلمة المرور يجب أن تحتوي على حرف صغير واحد على الأقل');
      return;
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      _showSnack('كلمة المرور يجب أن تحتوي على رقم واحد على الأقل');
      return;
    }

    setState(() => _isCheckingPhone = true);
    try {
      final api = ApiClient();
      final cleaned = widget.data.phoneNumber.replaceAll(RegExp(r'[\s\-]'), '');
      final response = await api.dio.get('/api/barber/check-phone', queryParameters: {'phone': cleaned});
      final available = response.data['available'] as bool;
      if (!available) {
        _showSnack('رقم الهاتف مسجل بالفعل');
        return;
      }
      widget.onNext();
    } on DioException {
      _showSnack('حدث خطأ في الاتصال، حاول مرة أخرى');
    } catch (e) {
      _showSnack(extractErrorMessage(e));
    } finally {
      if (mounted) setState(() => _isCheckingPhone = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, textAlign: TextAlign.center),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return KeyboardDismiss(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              FadeIn(
                delay: const Duration(milliseconds: 0),
                child: Text('المعلومات الأساسية', style: AppTextStyles.headline(isDark)),
              ),
              const SizedBox(height: 8),
              FadeIn(
                delay: const Duration(milliseconds: 50),
                child: Text('لإنشاء حسابك لعملك.', style: AppTextStyles.secondary(isDark)),
              ),
              const SizedBox(height: 32),
              FadeIn(delay: const Duration(milliseconds: 100), child: Text('الاسم الكامل', style: AppTextStyles.secondary(isDark))),
              const SizedBox(height: 8),
              FadeIn(
                delay: const Duration(milliseconds: 150),
                child: TextFormField(
                  textCapitalization: TextCapitalization.words,
                  controller: _nameController,
                  onChanged: (v) => widget.data.fullName = v,
                  style: TextStyle(color: context.textColor, fontSize: 14),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'الاسم مطلوب';
                    if (v.trim().length < 2) return 'الاسم يجب أن يكون حرفين على الأقل';
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: 'أدخل اسمك الكامل',
                    prefixIcon: const Icon(Icons.person_outline, size: 20, color: AppColors.primary),
                    filled: true,
                    fillColor: context.surfaceColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.md), borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.md), borderSide: BorderSide(color: context.cardBorderColor)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.md), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.md), borderSide: const BorderSide(color: AppColors.error)),
                    focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.md), borderSide: const BorderSide(color: AppColors.error, width: 2)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              FadeIn(delay: const Duration(milliseconds: 200), child: Text('رقم الهاتف', style: AppTextStyles.secondary(isDark))),
              const SizedBox(height: 8),
              FadeIn(
                delay: const Duration(milliseconds: 250),
                child: TextFormField(
                  keyboardType: TextInputType.phone,
                  textDirection: TextDirection.ltr,
                  controller: _phoneController,
                  onChanged: (v) => widget.data.phoneNumber = v,
                  style: TextStyle(color: context.textColor, fontSize: 14),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'رقم الهاتف مطلوب';
                    final cleaned = v.replaceAll(RegExp(r'[\s\-]'), '');
                    if (!RegExp(r'^05\d{8}$').hasMatch(cleaned)) return 'رقم الهاتف يجب أن يبدأ بـ 05 ويكون 10 أرقام';
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: '05X XXX XXXX',
                    hintTextDirection: TextDirection.ltr,
                    prefixIcon: const Icon(Icons.phone_outlined, size: 20, color: AppColors.primary),
                    filled: true,
                    fillColor: context.surfaceColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.md), borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.md), borderSide: BorderSide(color: context.cardBorderColor)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.md), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.md), borderSide: const BorderSide(color: AppColors.error)),
                    focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.md), borderSide: const BorderSide(color: AppColors.error, width: 2)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              FadeIn(delay: const Duration(milliseconds: 300), child: Text('كلمة المرور', style: AppTextStyles.secondary(isDark))),
              const SizedBox(height: 8),
              FadeIn(
                delay: const Duration(milliseconds: 350),
                child: PasswordField(
                  controller: TextEditingController(text: widget.data.password),
                  onChanged: (v) => widget.data.password = v,
                ),
              ),
              const SizedBox(height: 40),
              FadeIn(
                delay: const Duration(milliseconds: 400),
                child: AppButton(
                  label: _isCheckingPhone ? 'جاري التحقق...' : 'الحفظ والمتابعة',
                  onPressed: _isCheckingPhone ? null : _validateAndNext,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
