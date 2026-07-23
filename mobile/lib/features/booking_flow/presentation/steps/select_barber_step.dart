import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/animations/app_animations.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/rating_badge.dart';
import '../../../home/data/barbers_service.dart';

class SelectBarberStep extends StatelessWidget {
  final BarberDetailModel barberDetail;
  final VoidCallback onNext;

  const SelectBarberStep({super.key, required this.barberDetail, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                FadeIn(child: Text('تفاصيل الحلاق', style: AppTextStyles.headline(isDark))),
                const SizedBox(height: 4),
                FadeIn(delay: const Duration(milliseconds: 100), child: Text('تأكد من بيانات الحلاق قبل المتابعة', style: AppTextStyles.secondary(isDark))),
                const SizedBox(height: 20),
                FadeIn(delay: const Duration(milliseconds: 200), child: _buildBarberCard(context, isDark)),
                const SizedBox(height: 20),
                FadeIn(delay: const Duration(milliseconds: 300), child: _buildInfoRow(context, Icons.star, 'التقييم', '${barberDetail.averageRating} (${barberDetail.reviewCount} تقييم)', isDark)),
                const SizedBox(height: 12),
                FadeIn(delay: const Duration(milliseconds: 350), child: _buildInfoRow(context, Icons.work_outline, 'الخبرة', '${barberDetail.reviewCount}+ تقييم', isDark)),
                const SizedBox(height: 12),
                FadeIn(delay: const Duration(milliseconds: 400), child: _buildInfoRow(context, Icons.location_on_outlined, 'الموقع', '${barberDetail.address}, ${barberDetail.city}', isDark)),
                const SizedBox(height: 20),
                if (barberDetail.services.isNotEmpty) ...[
                  FadeIn(delay: const Duration(milliseconds: 450), child: Text('الخدمات المتاحة', style: AppTextStyles.subtitle(isDark))),
                  const SizedBox(height: 12),
                  FadeIn(
                    delay: const Duration(milliseconds: 500),
                    child: Wrap(
                      spacing: 8, runSpacing: 8,
                      children: barberDetail.services.map((service) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(color: context.surfaceColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: context.cardBorderColor)),
                          child: Text(service.name, style: AppTextStyles.caption(isDark)),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        _buildBottomButton(context, isDark),
      ],
    );
  }

  Widget _buildBarberCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: context.surfaceColor, borderRadius: BorderRadius.circular(AppBorderRadius.md), border: Border.all(color: context.cardBorderColor)),
      child: Row(
        children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(AppBorderRadius.md)),
            child: const Icon(Icons.content_cut, color: AppColors.primary, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(barberDetail.ownerName, style: AppTextStyles.subtitle(isDark).copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(barberDetail.shopName, style: AppTextStyles.primary(isDark)),
                const SizedBox(height: 6),
                Row(children: [RatingBadge(rating: barberDetail.averageRating, reviewCount: barberDetail.reviewCount, starSize: 16)]),
              ],
            ),
          ),
          Container(
            width: 40, height: 40,
            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            child: Icon(Icons.check, color: context.backgroundColor, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: context.surfaceColor, borderRadius: BorderRadius.circular(AppBorderRadius.md), border: Border.all(color: context.cardBorderColor)),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.caption(isDark)),
                const SizedBox(height: 2),
                Text(value, style: AppTextStyles.bodyMedium(isDark), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
      decoration: BoxDecoration(color: context.surfaceColor, border: Border(top: BorderSide(color: context.cardBorderColor))),
      child: SafeArea(top: false, child: AppButton(label: 'متابعة', onPressed: onNext)),
    );
  }
}
