import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/animations/app_animations.dart';
import '../../../../core/models/barber_registration_data.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../barber_dashboard/presentation/barber_main_shell.dart';

class BarberSuccessStep extends StatelessWidget {
  final BarberRegistrationData data;
  const BarberSuccessStep({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              FadeIn(
                delay: const Duration(milliseconds: 0),
                child: Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.15),
                    border: Border.all(color: AppColors.primary, width: 3),
                  ),
                  child: const Icon(Icons.check, color: AppColors.primary, size: 50),
                ),
              ),
              const SizedBox(height: 32),
              FadeIn(
                delay: const Duration(milliseconds: 100),
                child: Text('تم إنشاء المتجر بنجاح!', style: AppTextStyles.headline(isDark), textAlign: TextAlign.center),
              ),
              const SizedBox(height: 12),
              FadeIn(
                delay: const Duration(milliseconds: 150),
                child: Text('لقد قمت بإعداد ملف تعريف صالون الحلاق الخاص بك.\nأنت الآن جاهز لاستقبال الحجوزات\nوإدارة عملائك.', style: AppTextStyles.secondary(isDark)),
              ),
              const SizedBox(height: 40),
              FadeIn(
                delay: const Duration(milliseconds: 200),
                child: AppCard(
                  child: Column(
                    children: [
                      _buildSummaryRow('اسم المتجر', data.shopName.isNotEmpty ? data.shopName : data.fullName, isDark, textColor: context.textColor, borderColor: context.cardBorderColor),
                      Divider(color: context.cardBorderColor, height: 24),
                      _buildSummaryRow('الخدمات المضافة', '${data.totalServices} خدمات', isDark, textColor: context.textColor, borderColor: context.cardBorderColor),
                      Divider(color: context.cardBorderColor, height: 24),
                      _buildSummaryRow('ساعات العمل', data.workingHoursSummary, isDark, valueColor: AppColors.primary, textColor: context.textColor, borderColor: context.cardBorderColor),
                    ],
                  ),
                ),
              ),
              const Spacer(flex: 2),
              FadeIn(
                delay: const Duration(milliseconds: 250),
                child: AppButton(
                  label: 'الانتقال إلى لوحة التحكم',
                  onPressed: () => Get.offAll(() => const BarberMainShell()),
                ),
              ),
              const SizedBox(height: 12),
              FadeIn(
                delay: const Duration(milliseconds: 300),
                child: AppButton(
                  label: 'معاينة صفحة المتجر',
                  type: AppButtonType.outline,
                  onPressed: () => Get.offAll(() => const BarberMainShell()),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, bool isDark, {Color? valueColor, Color? textColor, Color? borderColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.secondary(isDark)),
        Text(value, style: TextStyle(color: valueColor ?? textColor, fontSize: 15, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
