import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/animations/app_animations.dart';
import '../../../core/utils/time_formatter.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_button.dart';
import '../../main_shell/presentation/main_shell.dart';

class BookingSuccessScreen extends StatelessWidget {
  final String barberName;
  final String serviceName;
  final double servicePrice;
  final String date;
  final String time;

  const BookingSuccessScreen({super.key, required this.barberName, required this.serviceName, required this.servicePrice, required this.date, required this.time});

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
              FadeIn(child: Container(
                width: 100, height: 100,
                decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.15), shape: BoxShape.circle, border: Border.all(color: AppColors.success.withValues(alpha: 0.3), width: 2)),
                child: const Icon(Icons.check_circle_outline, color: AppColors.success, size: 50),
              )),
              const SizedBox(height: 24),
              FadeIn(delay: const Duration(milliseconds: 150), child: Text('تم تأيد حجزك!', style: AppTextStyles.headline(isDark))),
              const SizedBox(height: 8),
              FadeIn(delay: const Duration(milliseconds: 250), child: Text('تم تأكيد حجزك بنجاح', style: AppTextStyles.secondary(isDark))),
              const SizedBox(height: 32),
              FadeIn(
                delay: const Duration(milliseconds: 350),
                child: AppCard(
                  child: Column(
                    children: [
                      _buildDetailRow(Icons.person_outline, 'الحلاق', barberName, isDark),
                      Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Divider(color: context.cardBorderColor, height: 1)),
                      _buildDetailRow(Icons.content_cut, 'الخدمة', serviceName, isDark),
                      Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Divider(color: context.cardBorderColor, height: 1)),
                      _buildDetailRow(Icons.calendar_today_outlined, 'التاريخ', date, isDark),
                      Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Divider(color: context.cardBorderColor, height: 1)),
                      _buildDetailRow(Icons.access_time, 'الوقت', TimeFormatter.format(time), isDark),
                      Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Divider(color: context.cardBorderColor, height: 1)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('المجموع', style: AppTextStyles.secondary(isDark)),
                          Text('${servicePrice.toStringAsFixed(0)} ش', style: AppTextStyles.primary(isDark).copyWith(fontWeight: FontWeight.bold, fontSize: 22)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(flex: 2),
              FadeIn(
                delay: const Duration(milliseconds: 450),
                child: AppButton(label: 'عرض حجوزاتي', onPressed: () => Get.offAll(() => const MainShell(initialTab: 2))),
              ),
              const SizedBox(height: 12),
              FadeIn(
                delay: const Duration(milliseconds: 550),
                child: AppButton(label: 'العودة للرئيسية', type: AppButtonType.outline, onPressed: () => Get.offAll(() => const MainShell())),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(width: 8),
        Text(label, style: AppTextStyles.caption(isDark)),
        const Spacer(),
        Flexible(
          child: Text(value, style: AppTextStyles.bodyMedium(isDark).copyWith(fontWeight: FontWeight.w500, fontSize: 13), overflow: TextOverflow.ellipsis, maxLines: 1),
        ),
      ],
    );
  }
}
