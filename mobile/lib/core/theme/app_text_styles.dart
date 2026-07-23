import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_theme.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle _base({
    required bool isDark,
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.normal,
    Color? color,
  }) {
    return GoogleFonts.cairo(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
    );
  }

  static TextStyle caption(bool isDark) => _base(isDark: isDark, fontSize: 11, fontWeight: FontWeight.w500);
  static TextStyle bodySmall(bool isDark) => _base(isDark: isDark, fontSize: 12);
  static TextStyle body(bool isDark) => _base(isDark: isDark, fontSize: 14);
  static TextStyle bodyMedium(bool isDark) => _base(isDark: isDark, fontSize: 14, fontWeight: FontWeight.w500);
  static TextStyle subtitle(bool isDark) => _base(isDark: isDark, fontSize: 16, fontWeight: FontWeight.w600);
  static TextStyle title(bool isDark) => _base(isDark: isDark, fontSize: 18, fontWeight: FontWeight.bold);
  static TextStyle headline(bool isDark) => _base(isDark: isDark, fontSize: 22, fontWeight: FontWeight.bold);
  static TextStyle display(bool isDark) => _base(isDark: isDark, fontSize: 28, fontWeight: FontWeight.bold);

  static TextStyle error(bool isDark) => _base(isDark: isDark, fontSize: 12, color: AppColors.error);
  static TextStyle success(bool isDark) => _base(isDark: isDark, fontSize: 12, color: AppColors.success);
  static TextStyle primary(bool isDark) => _base(isDark: isDark, fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w600);
  static TextStyle hint(bool isDark) => _base(isDark: isDark, fontSize: 14, color: isDark ? AppColors.darkTextHint : AppColors.lightTextHint);
  static TextStyle secondary(bool isDark) => _base(isDark: isDark, fontSize: 13, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary);
}
