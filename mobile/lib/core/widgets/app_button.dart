import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

enum AppButtonType { primary, secondary, outline, text, danger }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final IconData? icon;
  final bool isLoading;
  final bool isSmall;
  final double? width;
  final double? height;
  final int? flex;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.type = AppButtonType.primary,
    this.icon,
    this.isLoading = false,
    this.isSmall = false,
    this.width,
    this.height,
    this.flex,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final isEnabled = onPressed != null && !isLoading;
    final btnHeight = isSmall ? 40.0 : (height ?? 54.0);
    final radius = BorderRadius.circular(isSmall ? 10 : AppBorderRadius.md);
    final fontSize = isSmall ? 12.0 : 15.0;
    final iconSize = isSmall ? 15.0 : 18.0;

    VoidCallback? wrappedOnPressed = isEnabled
        ? () {
            HapticFeedback.lightImpact();
            onPressed!();
          }
        : null;

    Widget button;

    switch (type) {
      case AppButtonType.primary:
        button = ElevatedButton(
          onPressed: wrappedOnPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
            disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
            disabledForegroundColor: (isDark ? AppColors.darkBackground : AppColors.lightBackground).withValues(alpha: 0.5),
            elevation: isSmall ? 0 : 2,
            shadowColor: AppColors.primary.withValues(alpha: 0.3),
            minimumSize: Size(width ?? double.infinity, btnHeight),
            shape: RoundedRectangleBorder(borderRadius: radius),
            padding: EdgeInsets.symmetric(horizontal: isSmall ? 12 : 20, vertical: isSmall ? 8 : 14),
          ),
          child: _buildChild(context, isDark, fontSize, iconSize),
        );
        break;

      case AppButtonType.secondary:
        button = ElevatedButton(
          onPressed: wrappedOnPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark ? AppColors.darkSurfaceLight : AppColors.lightSurfaceVariant,
            foregroundColor: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            disabledBackgroundColor: (isDark ? AppColors.darkSurfaceLight : AppColors.lightSurfaceVariant).withValues(alpha: 0.5),
            disabledForegroundColor: (isDark ? AppColors.darkTextHint : AppColors.lightTextHint),
            elevation: 0,
            minimumSize: Size(width ?? double.infinity, btnHeight),
            shape: RoundedRectangleBorder(borderRadius: radius),
            padding: EdgeInsets.symmetric(horizontal: isSmall ? 12 : 20, vertical: isSmall ? 8 : 14),
          ),
          child: _buildChild(context, isDark, fontSize, iconSize),
        );
        break;

      case AppButtonType.outline:
        button = OutlinedButton(
          onPressed: wrappedOnPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            side: BorderSide(
              color: isEnabled
                  ? context.cardBorderColor
                  : context.cardBorderColor.withValues(alpha: 0.4),
              width: 1,
            ),
            minimumSize: Size(width ?? double.infinity, btnHeight),
            shape: RoundedRectangleBorder(borderRadius: radius),
            padding: EdgeInsets.symmetric(horizontal: isSmall ? 12 : 20, vertical: isSmall ? 8 : 14),
          ),
          child: _buildChild(context, isDark, fontSize, iconSize),
        );
        break;

      case AppButtonType.text:
        button = TextButton(
          onPressed: wrappedOnPressed,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            disabledForegroundColor: AppColors.primary.withValues(alpha: 0.4),
            minimumSize: Size(width ?? double.infinity, btnHeight),
            shape: RoundedRectangleBorder(borderRadius: radius),
            padding: EdgeInsets.symmetric(horizontal: isSmall ? 12 : 20, vertical: isSmall ? 8 : 14),
          ),
          child: _buildChild(context, isDark, fontSize, iconSize),
        );
        break;

      case AppButtonType.danger:
        button = ElevatedButton(
          onPressed: wrappedOnPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.error.withValues(alpha: 0.4),
            disabledForegroundColor: Colors.white.withValues(alpha: 0.5),
            elevation: isSmall ? 0 : 2,
            shadowColor: AppColors.error.withValues(alpha: 0.3),
            minimumSize: Size(width ?? double.infinity, btnHeight),
            shape: RoundedRectangleBorder(borderRadius: radius),
            padding: EdgeInsets.symmetric(horizontal: isSmall ? 12 : 20, vertical: isSmall ? 8 : 14),
          ),
          child: _buildChild(context, isDark, fontSize, iconSize),
        );
        break;
    }

    if (flex != null) {
      return Expanded(flex: flex!, child: button);
    }

    return button;
  }

  Widget _buildChild(BuildContext context, bool isDark, double fontSize, double iconSize) {
    if (isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            type == AppButtonType.danger
                ? Colors.white
                : (isDark ? AppColors.darkBackground : AppColors.lightBackground),
          ),
        ),
      );
    }

    final textStyle = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      height: 1.2,
    );

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize),
          SizedBox(width: isSmall ? 4 : 6),
          Text(label, style: textStyle),
        ],
      );
    }

    return Text(label, style: textStyle);
  }
}
