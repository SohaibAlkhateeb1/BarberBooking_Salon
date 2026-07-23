import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class RatingBadge extends StatelessWidget {
  final double rating;
  final int reviewCount;
  final double? starSize;
  final double? fontSize;
  final bool showReviewCount;

  const RatingBadge({
    super.key,
    required this.rating,
    required this.reviewCount,
    this.starSize,
    this.fontSize,
    this.showReviewCount = true,
  });

  @override
  Widget build(BuildContext context) {
    if (reviewCount == 0) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_border, color: AppColors.ratingStar, size: starSize ?? 14),
          const SizedBox(width: 2),
          Text(
            'جديد',
            style: TextStyle(
              color: AppColors.ratingStar.withValues(alpha: 0.7),
              fontSize: fontSize ?? 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star, color: AppColors.ratingStar, size: starSize ?? 14),
        const SizedBox(width: 3),
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize ?? 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (showReviewCount && reviewCount > 0) ...[
          const SizedBox(width: 2),
          Text(
            '($reviewCount)',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: (fontSize ?? 12) - 1,
            ),
          ),
        ],
      ],
    );
  }
}

class RatingSummary extends StatelessWidget {
  final double rating;
  final int reviewCount;

  const RatingSummary({
    super.key,
    required this.rating,
    required this.reviewCount,
  });

  @override
  Widget build(BuildContext context) {
    if (reviewCount == 0) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_border, color: AppColors.ratingStar, size: 18),
          const SizedBox(width: 4),
          Text(
            'لا توجد تقييمات بعد',
            style: TextStyle(
              color: AppColors.ratingStar.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star, color: AppColors.ratingStar, size: 18),
        const SizedBox(width: 4),
        Text(
          '$rating',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '($reviewCount تقييم)',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
