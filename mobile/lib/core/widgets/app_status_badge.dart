import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppStatusBadge extends StatelessWidget {
  final String status;
  final double? fontSize;

  const AppStatusBadge({
    super.key,
    required this.status,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _getStatusColors(status);
    final text = _getStatusText(status);
    final fs = fontSize ?? 11;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.$1.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppBorderRadius.sm),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: colors.$1,
          fontSize: fs,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  (Color, Color) _getStatusColors(String status) {
    return switch (status) {
      'Pending' => (AppColors.warning, AppColors.warning),
      'Accepted' => (AppColors.primary, AppColors.primary),
      'InProgress' => (AppColors.info, AppColors.info),
      'PaymentPending' => (AppColors.warning, AppColors.warning),
      'Completed' => (AppColors.success, AppColors.success),
      'Cancelled' => (AppColors.error, AppColors.error),
      'Rejected' => (AppColors.error, AppColors.error),
      'NoShow' => (AppColors.error, AppColors.error),
      'Expired' => (AppColors.darkTextHint, AppColors.lightTextHint),
      _ => (AppColors.darkTextSecondary, AppColors.lightTextSecondary),
    };
  }

  String _getStatusText(String status) {
    return switch (status) {
      'Pending' => 'قيد الانتظار',
      'Accepted' => 'مقبول',
      'InProgress' => 'جاري',
      'PaymentPending' => 'بانتظار الدفع',
      'Completed' => 'مكتمل',
      'Cancelled' => 'ملغي',
      'Rejected' => 'مرفوض',
      'NoShow' => 'لم يحضر',
      'Expired' => 'منتهي',
      _ => status,
    };
  }
}
