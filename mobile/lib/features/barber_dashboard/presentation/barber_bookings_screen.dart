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
import '../data/barber_dashboard_service.dart';
import 'barber_booking_detail_screen.dart';

class BarberBookingsScreen extends StatefulWidget {
  const BarberBookingsScreen({super.key});

  @override
  State<BarberBookingsScreen> createState() => _BarberBookingsScreenState();
}

class _BarberBookingsScreenState extends State<BarberBookingsScreen>
    with SingleTickerProviderStateMixin {
  final BarberDashboardService _service =
      BarberDashboardService(ApiClient());
  late TabController _tabController;
  List<BarberBookingModel> _allBookings = [];
  bool _isLoading = true;
  bool _hasError = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadBookings();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final bookings = await _service.getBookings();
      if (mounted) {
        setState(() {
          _allBookings = bookings;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  List<BarberBookingModel> get _todayBookings {
    final today = DateTime.now();
    return _allBookings.where((b) {
      final bookingDate = DateTime.tryParse(b.bookingDate);
      final isToday = bookingDate != null &&
          bookingDate.year == today.year &&
          bookingDate.month == today.month &&
          bookingDate.day == today.day;
      return isToday;
    }).toList();
  }
  List<BarberBookingModel> get _pendingBookings =>
      _allBookings.where((b) => b.status == 'Pending').toList();
  List<BarberBookingModel> get _acceptedBookings =>
      _allBookings.where((b) => b.status == 'Accepted').toList();
  List<BarberBookingModel> get _inProgressBookings =>
      _allBookings.where((b) => b.status == 'InProgress' || b.status == 'PaymentPending').toList();
  List<BarberBookingModel> get _completedBookings =>
      _allBookings.where((b) => b.status == 'Completed').toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Text(
              'إدارة الحجوزات',
              style: AppTextStyles.headline(context.isDark),
            ),
            const SizedBox(height: 16),
            _buildTabBar(),
            Expanded(
              child: _isLoading
                  ? _buildLoadingSkeleton()
                  : _hasError
                      ? ErrorState(
                          onRetry: _loadBookings,
                        )
                      : RefreshIndicator(
                          onRefresh: _loadBookings,
                          color: AppColors.primary,
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _buildBookingsList(_todayBookings, 'اليوم'),
                              _buildBookingsList(_pendingBookings, 'بانتظار'),
                              _buildBookingsList(_acceptedBookings, 'مؤكد'),
                              _buildBookingsList(_inProgressBookings, 'قيد التنفيذ'),
                              _buildBookingsList(_completedBookings, 'مكتمل'),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      padding: AppSpacing.pageAll,
      itemCount: 5,
      itemBuilder: (context, index) => const Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: SkeletonListTile(),
      ),
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
        labelStyle: AppTextStyles.caption(context.isDark).copyWith(fontWeight: FontWeight.bold),
        unselectedLabelStyle: AppTextStyles.caption(context.isDark),
        labelPadding: EdgeInsets.zero,
        tabs: const [
          Tab(text: 'اليوم'),
          Tab(text: 'بانتظار'),
          Tab(text: 'مؤكد'),
          Tab(text: 'قيد التنفيذ'),
          Tab(text: 'مكتمل'),
        ],
      ),
    );
  }

  Widget _buildBookingsList(
    List<BarberBookingModel> bookings,
    String label,
  ) {
    if (bookings.isEmpty) {
      return const EmptyState(
        type: EmptyStateType.bookings,
      );
    }
    return ListView.builder(
      padding: AppSpacing.pageAll,
      itemCount: bookings.length,
      itemBuilder: (context, index) => FadeIn(
        delay: Duration(milliseconds: 50 * index),
        child: _buildBookingCard(bookings[index]),
      ),
    );
  }

  Widget _buildBookingCard(BarberBookingModel booking) {
    Color statusColor;
    String statusText;
    switch (booking.status) {
      case 'Pending':
        statusColor = Colors.orange;
        statusText = 'بانتظار الموافقة';
        break;
      case 'Accepted':
        statusColor = AppColors.primary;
        statusText = 'مؤكد';
        break;
      case 'InProgress':
        statusColor = Colors.blue;
        statusText = 'قيد التنفيذ';
        break;
      case 'PaymentPending':
        statusColor = AppColors.ratingStar;
        statusText = 'بانتظار الدفع';
        break;
      case 'Completed':
        statusColor = AppColors.success;
        statusText = 'مكتمل';
        break;
      case 'Cancelled':
        statusColor = AppColors.error;
        statusText = 'ملغي';
        break;
      case 'Rejected':
        statusColor = AppColors.error;
        statusText = 'مرفوض';
        break;
      case 'NoShow':
        statusColor = Colors.grey;
        statusText = 'لم يحضر';
        break;
      case 'Expired':
        statusColor = Colors.grey;
        statusText = 'منتهي';
        break;
      default:
        statusColor = context.textSecondaryColor;
        statusText = booking.status;
    }

    return PressEffect(
      onTap: () async {
        HapticFeedback.lightImpact();
        await Get.to(() => BarberBookingDetailScreen(bookingId: booking.id), transition: Transition.rightToLeft, duration: const Duration(milliseconds: 250));
        _loadBookings();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          border: Border.all(color: context.cardBorderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.customerName,
                        style: AppTextStyles.subtitle(context.isDark),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        booking.serviceName,
                        style: AppTextStyles.bodySmall(context.isDark).copyWith(
                          color: context.textSecondaryColor,
                        ),
                      ),
                      if (booking.employeeName != null && booking.employeeName!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.person_outline, size: 12, color: AppColors.primary.withValues(alpha: 0.7)),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                booking.employeeName!,
                                style: AppTextStyles.bodySmall(context.isDark).copyWith(
                                  color: AppColors.primary.withValues(alpha: 0.8),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${booking.totalPrice.toStringAsFixed(0)} ش',
                      style: AppTextStyles.primary(context.isDark),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time, color: context.hintColor, size: 16),
                const SizedBox(width: 6),
                Text(
                  TimeFormatter.format(booking.bookingTime),
                  style: AppTextStyles.bodySmall(context.isDark).copyWith(color: context.textSecondaryColor),
                ),
                const SizedBox(width: 16),
                Icon(Icons.timelapse, color: context.hintColor, size: 16),
                const SizedBox(width: 6),
                Text(
                  '${booking.serviceDuration} دقيقة',
                  style: AppTextStyles.bodySmall(context.isDark).copyWith(color: context.textSecondaryColor),
                ),
              ],
            ),
            if (booking.status == 'Pending') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'رفض',
                      type: AppButtonType.danger,
                      isSmall: true,
                      onPressed: () async {
                        await _service.rejectBooking(booking.id);
                        _loadBookings();
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppButton(
                      label: 'قبول',
                      type: AppButtonType.primary,
                      isSmall: true,
                      onPressed: () async {
                        await _service.acceptBooking(booking.id);
                        _loadBookings();
                      },
                    ),
                  ),
                ],
              ),
            ],
            if (booking.status == 'Accepted') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'لم يحضر',
                      type: AppButtonType.danger,
                      isSmall: true,
                      onPressed: () async {
                        await _service.noShowBooking(booking.id);
                        _loadBookings();
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppButton(
                      label: 'بدء الخدمة',
                      type: AppButtonType.primary,
                      isSmall: true,
                      onPressed: () async {
                        await _service.startBooking(booking.id);
                        _loadBookings();
                      },
                    ),
                  ),
                ],
              ),
            ],
            if (booking.status == 'InProgress') ...[
              const SizedBox(height: 12),
              _buildServiceTimer(booking),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  label: 'طلب الدفع',
                  type: AppButtonType.primary,
                  isSmall: true,
                  icon: Icons.payment_rounded,
                  onPressed: () async {
                    await _service.requestPayment(booking.id);
                    _loadBookings();
                  },
                ),
              ),
            ],
            if (booking.status == 'PaymentPending') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  label: 'تأكيد الدفع والإكمال',
                  type: AppButtonType.primary,
                  isSmall: true,
                  onPressed: () async {
                    await _service.completeBooking(booking.id);
                    _loadBookings();
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildServiceTimer(BarberBookingModel booking) {
    if (booking.startedAt == null) return const SizedBox.shrink();

    final startedAt = DateTime.tryParse(booking.startedAt!)?.toLocal();
    if (startedAt == null) return const SizedBox.shrink();

    final now = DateTime.now();
    final elapsed = now.difference(startedAt);
    final expectedDuration = Duration(minutes: booking.serviceDurationMinutes);
    final remaining = expectedDuration - elapsed;
    final isOverdue = remaining.isNegative;
    final elapsedStr = _formatDuration(elapsed);
    final remainingStr = _formatDuration(remaining.abs());

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isOverdue
            ? AppColors.error.withValues(alpha: 0.1)
            : Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isOverdue
              ? AppColors.error.withValues(alpha: 0.3)
              : Colors.blue.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                isOverdue ? Icons.warning_amber_rounded : Icons.timer_outlined,
                color: isOverdue ? AppColors.error : Colors.blue,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'الخدمة الحالية',
                style: AppTextStyles.bodySmall(context.isDark).copyWith(
                  color: context.textSecondaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'المدة',
                      style: AppTextStyles.bodySmall(context.isDark).copyWith(
                        color: context.hintColor,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      elapsedStr,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: context.textColor,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 30,
                color: context.cardBorderColor,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      isOverdue ? 'متأخرة' : 'المتبقي',
                      style: AppTextStyles.bodySmall(context.isDark).copyWith(
                        color: isOverdue ? AppColors.error : context.hintColor,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      remainingStr,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isOverdue ? AppColors.error : AppColors.success,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 30,
                color: context.cardBorderColor,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'المتوقع',
                      style: AppTextStyles.bodySmall(context.isDark).copyWith(
                        color: context.hintColor,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      '${booking.serviceDurationMinutes} دقيقة',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.textColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
