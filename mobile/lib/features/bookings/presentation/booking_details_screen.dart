import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/animations/app_animations.dart';
import '../../../core/utils/time_formatter.dart';
import '../../../core/utils/error_extractor.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/app_button.dart';
import '../data/bookings_service.dart';
import 'cancel_booking_dialog.dart';
import 'reschedule_screen.dart';

class BookingDetailsScreen extends StatefulWidget {
  final String bookingId;

  const BookingDetailsScreen({super.key, required this.bookingId});

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  final BookingsService _bookingsService = BookingsService(ApiClient());
  BookingDetailModel? _booking;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBookingDetail();
  }

  Future<void> _loadBookingDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final detail = await _bookingsService.getBookingDetail(widget.bookingId);
      if (mounted) {
        setState(() {
          _booking = detail;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'حدث خطأ أثناء تحميل تفاصيل الحجز';
          _isLoading = false;
        });
      }
    }
  }

  String _statusBadgeText(String status) {
    switch (status) {
      case 'Pending': return 'بانتظار الموافقة';
      case 'Accepted': return 'مؤكد';
      case 'InProgress': return 'قيد التنفيذ';
      case 'PaymentPending': return 'بانتظار الدفع';
      case 'Completed': return 'مكتمل';
      case 'Cancelled': return 'ملغي';
      case 'Rejected': return 'مرفوض';
      case 'NoShow': return 'لم يحضر';
      case 'Expired': return 'منتهي';
      default: return status;
    }
  }

  Color _statusBadgeColor(String status) {
    switch (status) {
      case 'Pending': return Colors.orange;
      case 'Accepted': return AppColors.primary;
      case 'InProgress': return Colors.blue;
      case 'PaymentPending': return AppColors.ratingStar;
      case 'Completed': return AppColors.success;
      case 'Cancelled':
      case 'Rejected': return AppColors.error;
      case 'NoShow':
      case 'Expired': return Colors.grey;
      default: return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          style: AppTextStyles.body(context.isDark).copyWith(color: context.textSecondaryColor),
                        ),
                        const SizedBox(height: 16),
                        AppButton(
                          label: 'إعادة المحاولة',
                          type: AppButtonType.outline,
                          width: 200,
                          onPressed: _loadBookingDetail,
                        ),
                      ],
                    ),
                  )
                : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final booking = _booking!;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          Padding(
            padding: AppSpacing.pageAll,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeIn(
                  delay: const Duration(milliseconds: 100),
                  child: _buildBookingCode(booking),
                ),
                const SizedBox(height: 16),
                FadeIn(
                  delay: const Duration(milliseconds: 200),
                  child: _buildBarberInfo(booking),
                ),
                const SizedBox(height: 20),
                FadeIn(
                  delay: const Duration(milliseconds: 300),
                  child: _buildServiceInfo(booking),
                ),
                const SizedBox(height: 20),
                FadeIn(
                  delay: const Duration(milliseconds: 400),
                  child: _buildPriceInfo(booking),
                ),
                const SizedBox(height: 20),
                FadeIn(
                  delay: const Duration(milliseconds: 500),
                  child: _buildDateTimeInfo(booking),
                ),
                const SizedBox(height: 20),
                FadeIn(
                  delay: const Duration(milliseconds: 600),
                  child: _buildMapSection(booking),
                ),
                const SizedBox(height: 20),
                if (booking.notes != null && booking.notes!.isNotEmpty) ...[
                  FadeIn(
                    delay: const Duration(milliseconds: 700),
                    child: _buildNotesSection(booking),
                  ),
                  const SizedBox(height: 20),
                ],
                if (booking.status == 'Pending' || booking.status == 'Accepted') ...[
                  FadeIn(
                    delay: const Duration(milliseconds: 700),
                    child: _buildActionButtons(booking),
                  ),
                ],
                if (booking.status == 'Completed' && !booking.hasReview) ...[
                  FadeIn(
                    delay: const Duration(milliseconds: 700),
                    child: _buildReviewButton(booking),
                  ),
                ],
                if (booking.status == 'Completed' && booking.hasReview) ...[
                  FadeIn(
                    delay: const Duration(milliseconds: 700),
                    child: _buildReviewedBadge(),
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Icon(Icons.arrow_back_ios, color: context.textColor, size: 20),
          ),
          const Spacer(),
          Text(
            'تفاصيل الحجز',
            style: AppTextStyles.title(context.isDark),
          ),
          const Spacer(),
          const SizedBox(width: 20),
        ],
      ),
    );
  }

  Widget _buildBookingCode(BookingDetailModel booking) {
    return Container(
      width: double.infinity,
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(color: context.cardBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _statusBadgeColor(booking.status).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppBorderRadius.sm),
            ),
            child: Text(
              _statusBadgeText(booking.status),
              style: TextStyle(
                color: _statusBadgeColor(booking.status),
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '#${booking.bookingCode}',
            style: AppTextStyles.title(context.isDark).copyWith(
              color: AppColors.primary,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'كود الحجز',
            style: AppTextStyles.caption(context.isDark).copyWith(color: context.hintColor),
          ),
        ],
      ),
    );
  }

  Widget _buildBarberInfo(BookingDetailModel booking) {
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(color: context.cardBorderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.3),
                  AppColors.primaryDark.withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(Icons.person, color: AppColors.primary, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.barberName,
                  style: AppTextStyles.subtitle(context.isDark),
                ),
                const SizedBox(height: 4),
                Text(
                  booking.shopName,
                  style: AppTextStyles.bodySmall(context.isDark).copyWith(color: context.textSecondaryColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceInfo(BookingDetailModel booking) {
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(color: context.cardBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('تفاصيل الخدمة', style: AppTextStyles.subtitle(context.isDark)),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('الخدمة', style: AppTextStyles.bodySmall(context.isDark).copyWith(color: context.hintColor)),
              const Spacer(),
              Flexible(
                child: Text(booking.serviceName, style: AppTextStyles.body(context.isDark), overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('المدة', style: AppTextStyles.bodySmall(context.isDark).copyWith(color: context.hintColor)),
              Text('${booking.serviceDuration} دقيقة', style: AppTextStyles.body(context.isDark)),
            ],
          ),
          if (booking.employeeName != null && booking.employeeName!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('الموظف', style: AppTextStyles.bodySmall(context.isDark).copyWith(color: context.hintColor)),
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_outline, size: 14, color: AppColors.primary.withValues(alpha: 0.7)),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          booking.employeeName!,
                          style: AppTextStyles.bodySmall(context.isDark).copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPriceInfo(BookingDetailModel booking) {
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(color: context.cardBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('التكاليف الإجمالية', style: AppTextStyles.subtitle(context.isDark)),
          const SizedBox(height: 12),
          Row(
            children: [
              Flexible(
                child: Text(booking.serviceName, style: AppTextStyles.bodySmall(context.isDark).copyWith(color: context.hintColor), overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              Text('${booking.servicePrice.toStringAsFixed(0)} شيكل', style: AppTextStyles.bodySmall(context.isDark).copyWith(color: context.textSecondaryColor)),
            ],
          ),
          const SizedBox(height: 8),
          Divider(color: context.cardBorderColor),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('الإجمالي', style: AppTextStyles.subtitle(context.isDark)),
              Text(
                '${booking.totalPrice.toStringAsFixed(0)} شيكل',
                style: AppTextStyles.title(context.isDark).copyWith(color: AppColors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeInfo(BookingDetailModel booking) {
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(color: context.cardBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('الموعد', style: AppTextStyles.subtitle(context.isDark)),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, color: AppColors.primary, size: 20),
              const SizedBox(width: 12),
              Text(booking.bookingDate, style: AppTextStyles.body(context.isDark)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.access_time, color: AppColors.primary, size: 20),
              const SizedBox(width: 12),
              Text(TimeFormatter.format(booking.bookingTime), style: AppTextStyles.body(context.isDark)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMapSection(BookingDetailModel booking) {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        color: context.isDark ? AppColors.darkSurfaceLight : AppColors.lightSurfaceVariant,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(color: context.cardBorderColor),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.map_outlined, size: 48, color: context.hintColor.withValues(alpha: 0.5)),
          const SizedBox(height: 8),
          Text(
            booking.shopAddress,
            style: AppTextStyles.bodySmall(context.isDark).copyWith(color: context.textSecondaryColor),
            textAlign: TextAlign.center,
          ),
          if (booking.shopCity.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              booking.shopCity,
              style: AppTextStyles.caption(context.isDark).copyWith(color: context.hintColor),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotesSection(BookingDetailModel booking) {
    return Container(
      width: double.infinity,
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(color: context.cardBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ملاحظات إضافية', style: AppTextStyles.subtitle(context.isDark)),
          const SizedBox(height: 8),
          Text(booking.notes!, style: AppTextStyles.bodySmall(context.isDark).copyWith(color: context.textSecondaryColor)),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BookingDetailModel booking) {
    return Row(
      children: [
        Expanded(
          child: AppButton(
            label: 'إلغاء الحجز',
            type: AppButtonType.danger,
            onPressed: () => _showCancelDialog(booking.id),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppButton(
            label: 'إعادة جدولة',
            type: AppButtonType.outline,
            onPressed: () {
              HapticFeedback.lightImpact();
              Get.to(() => RescheduleScreen(bookingId: booking.id), transition: Transition.rightToLeft, duration: const Duration(milliseconds: 250));
            },
          ),
        ),
      ],
    );
  }

  void _showCancelDialog(String bookingId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CancelBookingDialog(
        bookingId: bookingId,
        onCancelled: () {
          Navigator.pop(context);
          _loadBookingDetail();
        },
      ),
    );
  }

  Widget _buildReviewButton(BookingDetailModel booking) {
    return AppButton(
      label: 'قيّم تجربتك',
      type: AppButtonType.primary,
      icon: Icons.star_outline,
      onPressed: () => _showReviewSheet(booking),
    );
  }

  Widget _buildReviewedBadge() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, color: AppColors.success, size: 22),
          const SizedBox(width: 8),
          Text(
            'تم التقييم',
            style: AppTextStyles.subtitle(context.isDark).copyWith(color: AppColors.success),
          ),
        ],
      ),
    );
  }

  void _showReviewSheet(BookingDetailModel booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ReviewBottomSheet(
        booking: booking,
        onReviewSubmitted: () {
          Navigator.pop(context);
          _loadBookingDetail();
        },
      ),
    );
  }
}

class _ReviewBottomSheet extends StatefulWidget {
  final BookingDetailModel booking;
  final VoidCallback onReviewSubmitted;

  const _ReviewBottomSheet({
    required this.booking,
    required this.onReviewSubmitted,
  });

  @override
  State<_ReviewBottomSheet> createState() => _ReviewBottomSheetState();
}

class _ReviewBottomSheetState extends State<_ReviewBottomSheet> {
  int _rating = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  final List<String> _ratingLabels = [
    '',
    'سيء جداً',
    'سيء',
    'مقبول',
    'جيد',
    'ممتاز',
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء اختيار تقييم'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final bookingsService = BookingsService(ApiClient());
      await bookingsService.addReview(
        bookingId: widget.booking.id,
        rating: _rating,
        comment: _commentController.text.isNotEmpty ? _commentController.text : null,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إضافة التقييم بنجاح'),
            backgroundColor: AppColors.success,
          ),
        );
        widget.onReviewSubmitted();
      }
    } catch (e) {
      String msg = extractErrorMessage(e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.error),
        );
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.cardBorderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'قيّم تجربتك مع ${widget.booking.barberName}',
              style: AppTextStyles.title(context.isDark),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              widget.booking.serviceName,
              style: AppTextStyles.body(context.isDark).copyWith(color: context.textSecondaryColor),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starNumber = index + 1;
                return GestureDetector(
                  onTap: () => setState(() => _rating = starNumber),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      starNumber <= _rating ? Icons.star : Icons.star_border,
                      color: AppColors.ratingStar,
                      size: 44,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),
            if (_rating > 0)
              Text(
                _ratingLabels[_rating],
                style: AppTextStyles.primary(context.isDark).copyWith(fontSize: 16),
              ),
            const SizedBox(height: 24),
            TextField(
              controller: _commentController,
              maxLines: 4,
              style: AppTextStyles.body(context.isDark),
              decoration: InputDecoration(
                hintText: 'اكتب تعليقك (اختياري)...',
                hintStyle: AppTextStyles.hint(context.isDark),
                filled: true,
                fillColor: context.isDark ? AppColors.darkSurfaceLight : AppColors.lightSurfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                  borderSide: BorderSide(color: context.cardBorderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                  borderSide: BorderSide(color: context.cardBorderColor),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'إرسال التقييم',
              isLoading: _isSubmitting,
              onPressed: _submitReview,
            ),
          ],
        ),
      ),
    );
  }
}
