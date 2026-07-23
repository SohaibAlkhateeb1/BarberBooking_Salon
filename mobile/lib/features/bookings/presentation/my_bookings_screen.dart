import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/time_formatter.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/widgets.dart';
import '../../../core/animations/app_animations.dart';
import '../data/bookings_service.dart';
import 'booking_details_screen.dart';
import 'cancel_booking_dialog.dart';
import 'reschedule_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> with SingleTickerProviderStateMixin {
  final BookingsService _bookingsService = BookingsService(ApiClient());
  late TabController _tabController;
  List<BookingModel> _active = [];
  List<BookingModel> _completed = [];
  List<BookingModel> _cancelled = [];
  bool _isLoading = true;
  String? _error;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadBookings();
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) _loadBookings();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    if (_active.isEmpty && _completed.isEmpty && _cancelled.isEmpty) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    try {
      final results = await Future.wait([
        _bookingsService.getMyBookings(status: 'Pending'),
        _bookingsService.getMyBookings(status: 'Accepted'),
        _bookingsService.getMyBookings(status: 'InProgress'),
        _bookingsService.getMyBookings(status: 'PaymentPending'),
        _bookingsService.getMyBookings(status: 'Completed'),
        _bookingsService.getMyBookings(status: 'Cancelled'),
      ]);
      if (mounted) {
        setState(() {
          _active = [...results[0], ...results[1], ...results[2], ...results[3]];
          _completed = results[4];
          _cancelled = results[5];
          _isLoading = false;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'فشل تحميل البيانات';
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
        child: Column(
          children: [
            const SizedBox(height: 16),
            Text(
              'مواعيدي',
              style: AppTextStyles.headline(context.isDark),
            ),
            const SizedBox(height: 16),
            _buildTabBar(),
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : _error != null
                      ? ErrorState(
                          title: 'حدث خطأ',
                          message: _error,
                          onRetry: _loadBookings,
                        )
                      : RefreshIndicator(
                          onRefresh: _loadBookings,
                          color: AppColors.primary,
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _buildBookingsList(_active),
                              _buildBookingsList(_completed),
                              _buildBookingsList(_cancelled),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: const [
        SkeletonCard(),
        SkeletonCard(),
        SkeletonCard(),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: AppSpacing.pageHorizontal,
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          gradient: AppColors.primaryGradient,
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: context.backgroundColor,
        unselectedLabelColor: context.textSecondaryColor,
        labelStyle: AppTextStyles.bodySmall(context.isDark).copyWith(fontWeight: FontWeight.bold),
        unselectedLabelStyle: AppTextStyles.bodySmall(context.isDark),
        labelPadding: EdgeInsets.zero,
        tabs: const [
          Tab(text: 'النشطة'),
          Tab(text: 'المكتملة'),
          Tab(text: 'الملغاة'),
        ],
      ),
    );
  }

  Widget _buildBookingsList(List<BookingModel> bookings) {
    if (bookings.isEmpty) {
      return const EmptyState(
        type: EmptyStateType.bookings,
        title: 'لا توجد مواعيد',
        subtitle: 'لم تقم بأي حجز حتى الآن',
      );
    }
    return ListView.builder(
      padding: AppSpacing.pageAll,
      itemCount: bookings.length,
      itemBuilder: (context, index) => FadeIn(
        delay: Duration(milliseconds: index * 80),
        child: _buildBookingCard(bookings[index]),
      ),
    );
  }

  Widget _buildBookingCard(BookingModel booking) {
    final isCancelled = booking.status == 'Cancelled' || booking.status == 'Rejected' || booking.status == 'Expired' || booking.status == 'NoShow';
    final canCancelOrReschedule = booking.status == 'Pending' || booking.status == 'Accepted';

    return PressEffect(
      onTap: () {
        HapticFeedback.lightImpact();
        Get.to(() => BookingDetailsScreen(bookingId: booking.id), transition: Transition.rightToLeft, duration: const Duration(milliseconds: 250));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          border: Border.all(
            color: isCancelled
                ? AppColors.error.withValues(alpha: 0.3)
                : context.cardBorderColor,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusBadgeColor(booking.status).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                  ),
                  child: Text(
                    _statusBadgeText(booking.status),
                    style: TextStyle(
                      color: _statusBadgeColor(booking.status),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                if (!isCancelled) ...[
                  RatingBadge(
                    rating: booking.averageRating,
                    reviewCount: booking.reviewCount,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Text(
              booking.barberName,
              style: AppTextStyles.subtitle(context.isDark).copyWith(
                color: isCancelled ? context.textSecondaryColor : context.textColor,
                decoration: isCancelled ? TextDecoration.lineThrough : null,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              booking.shopName,
              style: AppTextStyles.bodySmall(context.isDark).copyWith(
                color: isCancelled ? context.hintColor : context.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Flexible(
                  child: Text(
                    booking.employeeName != null && booking.employeeName!.isNotEmpty
                        ? '${booking.serviceName} — ${booking.employeeName}'
                        : booking.serviceName,
                    style: AppTextStyles.bodySmall(context.isDark).copyWith(
                      color: isCancelled ? context.hintColor : context.textSecondaryColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${booking.serviceDuration} ش',
                  style: AppTextStyles.bodySmall(context.isDark).copyWith(
                    color: isCancelled ? context.hintColor : context.textSecondaryColor,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${booking.totalPrice.toStringAsFixed(0)} شيكل',
                  style: AppTextStyles.body(context.isDark).copyWith(
                    color: isCancelled ? context.hintColor : context.textColor,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today_outlined, color: context.hintColor, size: 14),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    booking.bookingDate,
                    style: AppTextStyles.bodySmall(context.isDark).copyWith(
                      color: isCancelled ? context.hintColor : context.textSecondaryColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(Icons.access_time, color: context.hintColor, size: 14),
                const SizedBox(width: 6),
                Text(
                   TimeFormatter.format(booking.bookingTime),
                  style: AppTextStyles.bodySmall(context.isDark).copyWith(
                    color: isCancelled ? context.hintColor : context.textSecondaryColor,
                  ),
                ),
              ],
            ),
            if (isCancelled && booking.cancellationReason != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.error, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'سبب الإلغاء: ${booking.cancellationReason}',
                        style: AppTextStyles.bodySmall(context.isDark).copyWith(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (canCancelOrReschedule) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  AppButton(
                    label: 'إلغاء',
                    type: AppButtonType.danger,
                    isSmall: true,
                    icon: Icons.close_rounded,
                    flex: 1,
                    onPressed: () => _showCancelDialog(booking.id),
                  ),
                  const SizedBox(width: 10),
                  AppButton(
                    label: 'إعادة جدولة',
                    type: AppButtonType.outline,
                    isSmall: true,
                    icon: Icons.schedule_rounded,
                    flex: 1,
                    onPressed: () => _showRescheduleScreen(booking.id),
                  ),
                  const SizedBox(width: 10),
                  AppButton(
                    label: 'التفاصيل',
                    type: AppButtonType.primary,
                    isSmall: true,
                    icon: Icons.arrow_forward_ios_rounded,
                    flex: 1,
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Get.to(() => BookingDetailsScreen(bookingId: booking.id), transition: Transition.rightToLeft, duration: const Duration(milliseconds: 250));
                    },
                  ),
                ],
              ),
            ],
            if (isCancelled) ...[
              const SizedBox(height: 12),
              AppButton(
                label: 'عرض التفاصيل',
                type: AppButtonType.outline,
                isSmall: true,
                icon: Icons.visibility_outlined,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Get.to(() => BookingDetailsScreen(bookingId: booking.id), transition: Transition.rightToLeft, duration: const Duration(milliseconds: 250));
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showCancelDialog(String bookingId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CancelBookingDialog(bookingId: bookingId),
    );
  }

  void _showRescheduleScreen(String bookingId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RescheduleScreen(bookingId: bookingId)),
    );
  }
}
