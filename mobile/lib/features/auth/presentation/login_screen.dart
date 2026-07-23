import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_responsive.dart';
import '../../../core/animations/app_animations.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/password_field.dart';
import 'auth_controller.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final controller = Get.put(AuthController());

    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        child: KeyboardDismiss(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              FadeIn(
                delay: const Duration(milliseconds: 100),
                child: Text(
                  'أهلاً بك',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SlideIn(
                delay: const Duration(milliseconds: 200),
                child: AppCard(
                  padding: const EdgeInsets.all(24),
                  margin: EdgeInsets.zero,
                  borderRadius: AppBorderRadius.xl,
                  showShadow: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FadeIn(
                        delay: const Duration(milliseconds: 300),
                        child: Text(
                          'تسجيل الدخول',
                          style: AppTextStyles.headline(isDark),
                        ),
                      ),
                      const SizedBox(height: 8),
                      FadeIn(
                        delay: const Duration(milliseconds: 350),
                        child: Text(
                          'مرحباً بك مجدداً! أدخل رقم هاتفك للمتابعة',
                          style: AppTextStyles.secondary(isDark),
                        ),
                      ),
                      const SizedBox(height: 24),
                      FadeIn(
                        delay: const Duration(milliseconds: 400),
                        child: Text('رقم الهاتف', style: AppTextStyles.secondary(isDark)),
                      ),
                      const SizedBox(height: 8),
                      SlideIn(
                        delay: const Duration(milliseconds: 450),
                        child: TextField(
                          onChanged: controller.updatePhoneNumber,
                          keyboardType: TextInputType.phone,
                          textDirection: TextDirection.ltr,
                          style: TextStyle(
                            color: context.textColor,
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            hintText: '05X XXX XXXX',
                            hintTextDirection: TextDirection.ltr,
                            prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                            prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                            filled: true,
                            fillColor: isDark ? AppColors.darkSurfaceLight : AppColors.lightSurfaceVariant,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppBorderRadius.md),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppBorderRadius.md),
                              borderSide: BorderSide(color: context.cardBorderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppBorderRadius.md),
                              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      FadeIn(
                        delay: const Duration(milliseconds: 500),
                        child: Text('كلمة المرور', style: AppTextStyles.secondary(isDark)),
                      ),
                      const SizedBox(height: 8),
                      SlideIn(
                        delay: const Duration(milliseconds: 550),
                        child: PasswordField(
                          hintText: '••••••••••••••••',
                          onChanged: controller.updatePassword,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FadeIn(
                        delay: const Duration(milliseconds: 560),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: () => Get.to(() => const ForgotPasswordScreen(), transition: Transition.rightToLeft, duration: const Duration(milliseconds: 250)),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'نسيت كلمة المرور؟',
                              style: TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      FadeIn(
                        delay: const Duration(milliseconds: 600),
                        child: Obx(() => AppButton(
                          label: 'دخول',
                          onPressed: controller.isLoading.value ? null : controller.login,
                          isLoading: controller.isLoading.value,
                        )),
                      ),
                      const SizedBox(height: 16),
                      Obx(() {
                        if (controller.errorMessage.value.isEmpty) return const SizedBox.shrink();
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                            border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            controller.errorMessage.value,
                            style: AppTextStyles.error(isDark),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                      FadeIn(
                        delay: const Duration(milliseconds: 650),
                        child: Row(
                          children: [
                            Expanded(child: Divider(color: context.cardBorderColor)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text('أو', style: AppTextStyles.hint(isDark)),
                            ),
                            Expanded(child: Divider(color: context.cardBorderColor)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      FadeIn(
                        delay: const Duration(milliseconds: 700),
                        child: AppButton(
                          label: 'إنشاء حساب جديد',
                          type: AppButtonType.outline,
                          onPressed: () => Get.to(() => const RegisterScreen(), transition: Transition.rightToLeft, duration: const Duration(milliseconds: 250)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              FadeIn(
                delay: const Duration(milliseconds: 800),
                child: Text(
                  'تحتاج مساعدة؟ تواصل مع الدعم الفني',
                  style: AppTextStyles.hint(isDark),
                ),
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
