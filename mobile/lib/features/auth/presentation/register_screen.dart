import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_responsive.dart';
import '../../../core/animations/app_animations.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/password_field.dart';
import 'auth_controller.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final controller = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        child: KeyboardDismiss(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              FadeIn(
                delay: const Duration(milliseconds: 100),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('تسجيل حساب جديد', style: AppTextStyles.title(isDark)),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.arrow_forward, color: context.textColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              FadeIn(
                delay: const Duration(milliseconds: 200),
                child: Obx(() => GestureDetector(
                  onTap: controller.pickProfileImage,
                  child: Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: context.hintColor.withValues(alpha: 0.5),
                            width: 2,
                          ),
                        ),
                        child: ClipOval(
                          child: controller.profileImageBytes.value != null
                              ? Image.memory(controller.profileImageBytes.value!, fit: BoxFit.cover, width: 100, height: 100)
                              : Center(child: Icon(Icons.person_outline, size: 40, color: context.hintColor)),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: context.surfaceColor,
                            border: Border.all(color: context.cardBorderColor),
                          ),
                          child: Icon(Icons.camera_alt_outlined, size: 16, color: context.hintColor),
                        ),
                      ),
                    ],
                  ),
                )),
              ),
              const SizedBox(height: 8),
              FadeIn(
                delay: const Duration(milliseconds: 250),
                child: Text('إضافة صورة شخصية', style: AppTextStyles.secondary(isDark)),
              ),
              const SizedBox(height: 32),
              FadeIn(delay: const Duration(milliseconds: 300), child: _buildLabel('الاسم الكامل', isDark)),
              const SizedBox(height: 8),
              SlideIn(
                delay: const Duration(milliseconds: 350),
                child: TextField(
                  onChanged: controller.updateFullName,
                  textCapitalization: TextCapitalization.words,
                  style: TextStyle(color: context.textColor, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'أدخل اسمك الكامل',
                    prefixIcon: const Icon(Icons.person_outline, size: 20),
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
              const SizedBox(height: 20),
              FadeIn(delay: const Duration(milliseconds: 400), child: _buildLabel('رقم الهاتف', isDark)),
              const SizedBox(height: 8),
              SlideIn(
                delay: const Duration(milliseconds: 450),
                child: TextField(
                  onChanged: controller.updatePhoneNumber,
                  keyboardType: TextInputType.phone,
                  textDirection: TextDirection.ltr,
                  style: TextStyle(color: context.textColor, fontSize: 14),
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
              const SizedBox(height: 20),
              FadeIn(delay: const Duration(milliseconds: 500), child: _buildLabel('كلمة المرور', isDark)),
              const SizedBox(height: 8),
              SlideIn(
                delay: const Duration(milliseconds: 550),
                child: PasswordField(
                  hintText: '••••••••••••••••',
                  onChanged: controller.updatePassword,
                ),
              ),
              const SizedBox(height: 24),
              FadeIn(
                delay: const Duration(milliseconds: 600),
                child: Obx(() => GestureDetector(
                  onTap: controller.toggleAcceptTerms,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        margin: const EdgeInsets.only(top: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: controller.acceptTerms.value ? AppColors.primary : context.hintColor,
                            width: 2,
                          ),
                          color: controller.acceptTerms.value ? AppColors.primary : Colors.transparent,
                        ),
                        child: controller.acceptTerms.value
                            ? Icon(Icons.check, size: 16, color: context.backgroundColor)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(color: context.textSecondaryColor, fontSize: 13, height: 1.5),
                            children: [
                              const TextSpan(text: 'أوافق على '),
                              TextSpan(text: 'الشروط والأحكام', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                              const TextSpan(text: ' و'),
                              TextSpan(text: 'سياسة الخصوصية', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                              const TextSpan(text: '\nالخاصة بالتطبيق.'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
              ),
              const SizedBox(height: 24),
              Obx(() {
                if (controller.errorMessage.value.isEmpty) return const SizedBox.shrink();
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Text(controller.errorMessage.value, style: AppTextStyles.error(isDark), textAlign: TextAlign.center),
                );
              }),
              FadeIn(
                delay: const Duration(milliseconds: 650),
                child: Obx(() => AppButton(
                  label: 'إنشاء الحساب',
                  icon: Icons.arrow_forward_ios,
                  onPressed: controller.isLoading.value ? null : controller.register,
                  isLoading: controller.isLoading.value,
                )),
              ),
              const SizedBox(height: 20),
              FadeIn(
                delay: const Duration(milliseconds: 700),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('لديك حساب بالفعل؟ ', style: AppTextStyles.secondary(isDark)),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text('تسجيل الدخول', style: TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
        ),
      ),
    );
  }

  static Widget _buildLabel(String text, bool isDark) {
    return Align(
      alignment: Alignment.centerRight,
      child: Text(text, style: AppTextStyles.secondary(isDark)),
    );
  }
}
