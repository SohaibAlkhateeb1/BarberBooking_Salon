import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_responsive.dart';
import '../../../core/animations/app_animations.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/error_extractor.dart';
import '../../../core/widgets/app_button.dart';
import 'reset_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';
  String _successMessage = '';

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() => _errorMessage = 'رقم الهاتف مطلوب');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _successMessage = '';
    });

    try {
      final apiClient = ApiClient();
      await apiClient.dio.post('/api/auth/forgot-password', data: {'phoneNumber': phone});

      setState(() {
        _successMessage = 'تم إرسال رمز التحقق';
        _errorMessage = '';
      });
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Get.to(() => ResetPasswordScreen(phoneNumber: phone), transition: Transition.rightToLeft, duration: const Duration(milliseconds: 250));
      }
    } catch (e) {
      String msg = extractErrorMessage(e);
      setState(() => _errorMessage = msg);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: context.textColor),
      ),
      body: SafeArea(
        child: KeyboardDismiss(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              FadeIn(
                delay: const Duration(milliseconds: 100),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.1),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 2),
                  ),
                  child: const Icon(Icons.lock_reset_rounded, size: 48, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 24),
              FadeIn(delay: const Duration(milliseconds: 200), child: Text('نسيت كلمة المرور؟', style: AppTextStyles.headline(isDark))),
              const SizedBox(height: 12),
              FadeIn(
                delay: const Duration(milliseconds: 300),
                child: Text('أدخل رقم هاتفك المسجل وسنرسل لك رمز التحقق لإعادة تعيين كلمة المرور', style: AppTextStyles.secondary(isDark), textAlign: TextAlign.center),
              ),
              const SizedBox(height: 32),
              FadeIn(
                delay: const Duration(milliseconds: 400),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppBorderRadius.md),
                    border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.info, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text('سيتم إرسال رمز التحقق على واتساب أو رسائل SMS خلال 24 ساعة أو أقل.', style: const TextStyle(color: AppColors.info, fontSize: 13), textAlign: TextAlign.center),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FadeIn(
                delay: const Duration(milliseconds: 500),
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.textColor, letterSpacing: 2),
                  decoration: InputDecoration(
                    hintText: '05XXXXXXXX',
                    hintStyle: TextStyle(color: context.hintColor.withValues(alpha: 0.5), letterSpacing: 2),
                    prefixIcon: const Icon(Icons.phone_android, color: AppColors.primary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppBorderRadius.md),
                      borderSide: BorderSide(color: context.cardBorderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppBorderRadius.md),
                      borderSide: BorderSide(color: context.cardBorderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppBorderRadius.md),
                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                    ),
                    filled: true,
                    fillColor: context.surfaceColor,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_errorMessage.isNotEmpty)
                FadeIn(
                  delay: const Duration(milliseconds: 100),
                  child: Container(
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
                ),
              if (_successMessage.isNotEmpty)
                FadeIn(
                  delay: const Duration(milliseconds: 100),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                      border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                    ),
                    child: Text(_successMessage, style: AppTextStyles.success(isDark), textAlign: TextAlign.center),
                  ),
                ),
              FadeIn(
                delay: const Duration(milliseconds: 600),
                child: AppButton(
                  label: 'إرسال رمز التحقق',
                  onPressed: _isLoading ? null : _sendOtp,
                  isLoading: _isLoading,
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}
