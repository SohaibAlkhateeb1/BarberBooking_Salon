import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_responsive.dart';
import '../../../core/animations/app_animations.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/error_extractor.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/password_field.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String phoneNumber;

  const ResetPasswordScreen({super.key, required this.phoneNumber});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String _errorMessage = '';
  String _successMessage = '';

  @override
  void dispose() {
    for (final c in _otpControllers) { c.dispose(); }
    for (final f in _otpFocusNodes) { f.dispose(); }
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String get _otpCode => _otpControllers.map((c) => c.text).join();

  Future<void> _resetPassword() async {
    final code = _otpCode;
    if (code.length != 6) { setState(() => _errorMessage = 'الرجاء إدخال رمز التحقق كاملاً (6 أرقام)'); return; }
    if (_passwordController.text.isEmpty) { setState(() => _errorMessage = 'كلمة المرور الجديدة مطلوبة'); return; }
    if (_passwordController.text.length < 8) { setState(() => _errorMessage = 'كلمة المرور يجب أن تكون 8 أحرف على الأقل'); return; }
    if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(_passwordController.text)) { setState(() => _errorMessage = 'كلمة المرور يجب أن تحتوي على حرف كبير وحرف صغير ورقم'); return; }
    if (_passwordController.text != _confirmPasswordController.text) { setState(() => _errorMessage = 'كلمتا المرور غير متطابقتين'); return; }

    setState(() { _isLoading = true; _errorMessage = ''; });
    try {
      final apiClient = ApiClient();
      await apiClient.dio.post('/api/auth/reset-password', data: {'phoneNumber': widget.phoneNumber, 'code': code, 'newPassword': _passwordController.text});
      setState(() { _successMessage = 'تم تغيير كلمة المرور بنجاح'; _errorMessage = ''; });
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) { Get.offAll(() => const LoginScreen()); }
    } catch (e) {
      String msg = extractErrorMessage(e);
      setState(() => _errorMessage = msg);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  InputDecoration _otpDecoration(BuildContext context, bool isDark, int index) {
    return InputDecoration(
      counterText: '',
      contentPadding: EdgeInsets.zero,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        borderSide: BorderSide(color: context.cardBorderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        borderSide: BorderSide(color: _otpControllers[index].text.isNotEmpty ? AppColors.primary : context.cardBorderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      filled: true,
      fillColor: context.surfaceColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: context.backgroundColor,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, iconTheme: IconThemeData(color: context.textColor)),
        body: SafeArea(
          child: KeyboardDismiss(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 10),
                FadeIn(
                  delay: const Duration(milliseconds: 100),
                  child: Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primary.withValues(alpha: 0.1), border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 2)),
                    child: const Icon(Icons.lock_reset_rounded, size: 40, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 20),
                FadeIn(delay: const Duration(milliseconds: 200), child: Text('إعادة تعيين كلمة المرور', style: AppTextStyles.headline(isDark))),
                const SizedBox(height: 8),
                FadeIn(delay: const Duration(milliseconds: 300), child: Text('أدخل رمز التحقق وكلمة المرور الجديدة', style: AppTextStyles.secondary(isDark), textAlign: TextAlign.center)),
                const SizedBox(height: 6),
                FadeIn(delay: const Duration(milliseconds: 350), child: Text(widget.phoneNumber, style: AppTextStyles.primary(isDark))),
                const SizedBox(height: 24),
                FadeIn(delay: const Duration(milliseconds: 400), child: Text('رمز التحقق', style: AppTextStyles.subtitle(isDark))),
                const SizedBox(height: 12),
                FadeIn(
                  delay: const Duration(milliseconds: 500),
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(6, (index) {
                        return Container(
                          width: 46, height: 54,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          child: TextField(
                            controller: _otpControllers[index],
                            focusNode: _otpFocusNodes[index],
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            maxLength: 1,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                            decoration: _otpDecoration(context, isDark, index),
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            onChanged: (value) {
                              setState(() => _errorMessage = '');
                              if (value.length == 1 && index < 5) _otpFocusNodes[index + 1].requestFocus();
                              if (value.length == 1 && index == 5) _otpFocusNodes[index].unfocus();
                            },
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FadeIn(
                  delay: const Duration(milliseconds: 600),
                  child: PasswordField(
                    controller: _passwordController,
                    hintText: 'كلمة المرور الجديدة',
                    labelText: '',
                  ),
                ),
                const SizedBox(height: 12),
                FadeIn(
                  delay: const Duration(milliseconds: 700),
                  child: TextField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirm,
                    style: TextStyle(color: context.textColor, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'تأكيد كلمة المرور',
                      prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility, color: context.hintColor),
                        onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                      filled: true,
                      fillColor: context.surfaceColor,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.md), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.md), borderSide: BorderSide(color: context.cardBorderColor)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.md), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                FadeIn(delay: const Duration(milliseconds: 750), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Text('8 أحرف على الأقل، حرف كبير وحرف صغير ورقم', style: AppTextStyles.caption(isDark)))),
                const SizedBox(height: 16),
                if (_errorMessage.isNotEmpty)
                  FadeIn(
                    delay: const Duration(milliseconds: 100),
                    child: Container(
                      width: double.infinity, padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppBorderRadius.sm), border: Border.all(color: AppColors.error.withValues(alpha: 0.3))),
                      child: Text(_errorMessage, style: AppTextStyles.error(isDark), textAlign: TextAlign.center),
                    ),
                  ),
                if (_successMessage.isNotEmpty)
                  FadeIn(
                    delay: const Duration(milliseconds: 100),
                    child: Container(
                      width: double.infinity, padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppBorderRadius.sm), border: Border.all(color: AppColors.success.withValues(alpha: 0.3))),
                      child: Text(_successMessage, style: AppTextStyles.success(isDark), textAlign: TextAlign.center),
                    ),
                  ),
                FadeIn(
                  delay: const Duration(milliseconds: 800),
                  child: AppButton(label: 'إعادة تعيين كلمة المرور', onPressed: _isLoading ? null : _resetPassword, isLoading: _isLoading),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          ),
        ),
      ),
    );
  }
}
