import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_responsive.dart';
import '../../../core/animations/app_animations.dart';
import '../../../core/network/api_client.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/utils/error_extractor.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/password_field.dart';
import '../../auth/presentation/forgot_password_screen.dart';
import '../../barber_registration/presentation/barber_registration_screen.dart';
import '../../barber_dashboard/presentation/barber_main_shell.dart';
import '../data/barber_auth_service.dart';

class BarberLoginScreen extends StatefulWidget {
  const BarberLoginScreen({super.key});

  @override
  State<BarberLoginScreen> createState() => _BarberLoginScreenState();
}

class _BarberLoginScreenState extends State<BarberLoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    setState(() => _errorMessage = '');

    if (_phoneController.text.isEmpty) {
      setState(() => _errorMessage = 'رقم الهاتف مطلوب');
      return;
    }
    if (_passwordController.text.isEmpty) {
      setState(() => _errorMessage = 'كلمة المرور مطلوبة');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = BarberAuthService(ApiClient());
      await authService.login(
        phoneNumber: _phoneController.text,
        password: _passwordController.text,
      );

      // Save FCM token to backend after login
      try {
        await NotificationService().saveTokenToBackend();
      } catch (_) {}

      if (!mounted) return;
      Get.offAll(() => const BarberMainShell());
    } catch (e) {
      String msg = extractErrorMessage(e);
      setState(() {
        _errorMessage = msg;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        child: KeyboardDismiss(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              FadeIn(
                delay: const Duration(milliseconds: 100),
                child: Text('أهلاً بك', style: AppTextStyles.display(isDark).copyWith(color: AppColors.primary)),
              ),
              const SizedBox(height: 32),
              FadeIn(
                delay: const Duration(milliseconds: 200),
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('تسجيل الدخول', style: AppTextStyles.headline(isDark)),
                      const SizedBox(height: 8),
                      Text('مرحباً بك مجدداً! أدخل رقم هاتفك للمتابعة', style: AppTextStyles.secondary(isDark)),
                      const SizedBox(height: 24),
                      Text('رقم الهاتف', style: AppTextStyles.secondary(isDark)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        textDirection: TextDirection.ltr,
                        style: TextStyle(color: context.textColor, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: '05X XXX XXXX',
                          hintTextDirection: TextDirection.ltr,
                          prefixIcon: const Icon(Icons.phone_outlined, size: 20, color: AppColors.primary),
                          filled: true,
                          fillColor: context.surfaceColor,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.md), borderSide: BorderSide.none),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.md), borderSide: BorderSide(color: context.cardBorderColor)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.md), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text('كلمة المرور', style: AppTextStyles.secondary(isDark)),
                      const SizedBox(height: 8),
                      PasswordField(
                        controller: _passwordController,
                        hintText: '••••••••••••••••',
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () => Get.to(() => const ForgotPasswordScreen(), transition: Transition.rightToLeft, duration: const Duration(milliseconds: 250)),
                          style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                          child: Text('نسيت كلمة المرور؟', style: AppTextStyles.primary(isDark)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_errorMessage.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                            border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                          ),
                          child: Text(_errorMessage, style: AppTextStyles.error(isDark), textAlign: TextAlign.center),
                        ),
                      AppButton(label: 'دخول', onPressed: _isLoading ? null : _login, isLoading: _isLoading),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: Divider(color: context.cardBorderColor)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text('أو', style: AppTextStyles.secondary(isDark)),
                          ),
                          Expanded(child: Divider(color: context.cardBorderColor)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      AppButton(
                        label: 'إنشاء حساب جديد',
                        onPressed: () => Get.to(() => const BarberRegistrationScreen(), transition: Transition.rightToLeft, duration: const Duration(milliseconds: 250)),
                        type: AppButtonType.outline,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              FadeIn(
                delay: const Duration(milliseconds: 300),
                child: Text('تحتاج مساعدة؟ تواصل مع الدعم الفني', style: AppTextStyles.caption(isDark)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
        ),
      ),
    );
  }
}
