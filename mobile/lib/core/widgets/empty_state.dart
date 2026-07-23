import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum EmptyStateType { bookings, favorites, notifications, reviews, search, services, generic }

class EmptyState extends StatelessWidget {
  final EmptyStateType type;
  final String? title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? icon;

  const EmptyState({
    super.key,
    required this.type,
    this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    final config = _getConfig(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon ?? config.icon,
                size: 40,
                color: AppColors.primary.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title ?? config.title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle ?? config.subtitle,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                  minimumSize: const Size(200, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  _EmptyConfig _getConfig(BuildContext context) {
    switch (type) {
      case EmptyStateType.bookings:
        return const _EmptyConfig(
          icon: Icons.calendar_today_outlined,
          title: 'لا توجد حجوزات',
          subtitle: 'لم تقم بأي حجز حتى الآن\nابدأ بحجز موعدك مع حلاقك المفضل',
        );
      case EmptyStateType.favorites:
        return const _EmptyConfig(
          icon: Icons.favorite_outline,
          title: 'المفضلة فارغة',
          subtitle: 'أضف صالونات إلى قائمة المفضلة\nللوصول إليها بسرعة',
        );
      case EmptyStateType.notifications:
        return const _EmptyConfig(
          icon: Icons.notifications_outlined,
          title: 'لا توجد إشعارات',
          subtitle: 'ستظهر إشعاراتك هنا\nعندما تكون هناك أخبار جديدة',
        );
      case EmptyStateType.reviews:
        return const _EmptyConfig(
          icon: Icons.rate_review_outlined,
          title: 'لا توجد تقييمات',
          subtitle: 'لم تقيّم أي حلاق بعد\nتقييمك يساعد الآخرين',
        );
      case EmptyStateType.search:
        return const _EmptyConfig(
          icon: Icons.search_off_outlined,
          title: 'لا توجد نتائج',
          subtitle: 'جرّب كلمات بحث مختلفة\nأو غيّر معايير البحث',
        );
      case EmptyStateType.services:
        return const _EmptyConfig(
          icon: Icons.content_cut_outlined,
          title: 'لا توجد خدمات',
          subtitle: 'لم تُضف أي خدمات بعد',
        );
      case EmptyStateType.generic:
        return const _EmptyConfig(
          icon: Icons.inbox_outlined,
          title: 'فارغ',
          subtitle: 'لا توجد عناصر للعرض',
        );
    }
  }
}

class _EmptyConfig {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyConfig({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}
