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

class BarberDashboardScreen extends StatefulWidget {
  const BarberDashboardScreen({super.key});

  @override
  State<BarberDashboardScreen> createState() => _BarberDashboardScreenState();
}

class _BarberDashboardScreenState extends State<BarberDashboardScreen> {
  final BarberDashboardService _service = BarberDashboardService(ApiClient());
  BarberDashboardModel? _dashboard;
  bool _isLoading = true;
  String? _error;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) _loadDashboard();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDashboard() async {
    if (_dashboard == null) {
      setState(() { _isLoading = true; _error = null; });
    }
    try {
      final data = await _service.getDashboard();
      if (mounted) setState(() { _dashboard = data; _isLoading = false; _error = null; });
    } catch (e) {
      if (_dashboard == null && mounted) {
        setState(() { _error = 'حدث خطأ'; _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        child: _isLoading
            ? _buildLoadingSkeleton()
            : _error != null
                ? ErrorState(
                    message: _error,
                    onRetry: _loadDashboard,
                  )
                : RefreshIndicator(
                    onRefresh: _loadDashboard,
                    color: AppColors.primary,
                    child: SingleChildScrollView(
                      padding: AppSpacing.pageAll,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FadeIn(
                            child: _buildHeader(),
                          ),
                          const SizedBox(height: 24),
                          FadeIn(
                            delay: const Duration(milliseconds: 100),
                            child: _buildStatsGrid(),
                          ),
                          const SizedBox(height: 24),
                          FadeIn(
                            delay: const Duration(milliseconds: 200),
                            child: _buildRevenueChart(),
                          ),
                          const SizedBox(height: 24),
                          FadeIn(
                            delay: const Duration(milliseconds: 300),
                            child: _buildRecentBookings(),
                          ),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return Padding(
      padding: AppSpacing.pageAll,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonLoader(width: 200, height: 28, borderRadius: 8),
          const SizedBox(height: 8),
          const SkeletonLoader(width: 120, height: 16, borderRadius: 6),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: SkeletonLoader(height: 100, borderRadius: AppBorderRadius.lg)),
              const SizedBox(width: 12),
              Expanded(child: SkeletonLoader(height: 100, borderRadius: AppBorderRadius.lg)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: SkeletonLoader(height: 100, borderRadius: AppBorderRadius.lg)),
              const SizedBox(width: 12),
              Expanded(child: SkeletonLoader(height: 100, borderRadius: AppBorderRadius.lg)),
            ],
          ),
          const SizedBox(height: 24),
          SkeletonLoader(height: 200, borderRadius: AppBorderRadius.lg),
          const SizedBox(height: 24),
          const SkeletonLoader(width: 160, height: 20, borderRadius: 6),
          const SizedBox(height: 12),
          SkeletonLoader(height: 72, borderRadius: AppBorderRadius.md),
          const SizedBox(height: 10),
          SkeletonLoader(height: 72, borderRadius: AppBorderRadius.md),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'مرحباً، ${_dashboard!.shopName}',
                style: AppTextStyles.headline(context.isDark),
              ),
              const SizedBox(height: 4),
              Text(
                'لوحة التحكم',
                style: AppTextStyles.bodySmall(context.isDark).copyWith(
                  color: context.textSecondaryColor,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
            border: Border.all(color: context.cardBorderColor),
          ),
          child: Icon(
            Icons.notifications_outlined,
            color: context.textColor,
            size: 22,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        SlideIn(
          delay: const Duration(milliseconds: 50),
          child: _buildStatCard('حجوزات اليوم', '${_dashboard!.todayBookingsCount}', Icons.calendar_today, AppColors.primary),
        ),
        SlideIn(
          delay: const Duration(milliseconds: 100),
          child: _buildStatCard('إيرادات اليوم', '${_dashboard!.todayRevenue.toStringAsFixed(0)} ش', Icons.attach_money, AppColors.success),
        ),
        SlideIn(
          delay: const Duration(milliseconds: 150),
          child: _buildStatCard('التقييم', '${_dashboard!.averageRating}', Icons.star, AppColors.ratingStar),
        ),
        SlideIn(
          delay: const Duration(milliseconds: 200),
          child: _buildStatCard('العملاء النشطين', '${_dashboard!.activeClients}', Icons.people, AppColors.primary),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(color: context.cardBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.caption(context.isDark).copyWith(
                    color: context.textSecondaryColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChart() {
    final weeklyRevenue = _dashboard!.weeklyRevenue;
    final maxRevenue = weeklyRevenue.map((e) => e.revenue).reduce((a, b) => a > b ? a : b);
    
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(color: context.cardBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'تحليل الإيرادات',
            style: AppTextStyles.subtitle(context.isDark),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: weeklyRevenue.map((item) {
                final height = maxRevenue > 0 ? (item.revenue / maxRevenue) * 120 : 0.0;
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: 24,
                        height: height.clamp(4.0, 120.0),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.day,
                        style: AppTextStyles.caption(context.isDark).copyWith(
                          color: context.hintColor,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentBookings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'أحدث الحجوزات',
              style: AppTextStyles.subtitle(context.isDark),
            ),
            GestureDetector(
              onTap: () {},
              child: Text('عرض الكل', style: AppTextStyles.primary(context.isDark)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...(_dashboard!.recentBookings.asMap().entries.map((entry) {
          return FadeIn(
            delay: Duration(milliseconds: 350 + (entry.key * 50)),
            child: _buildRecentBookingCard(entry.value),
          );
        })),
      ],
    );
  }

  Widget _buildRecentBookingCard(BarberBookingModel booking) {
    Color statusColor;
    String statusText;
    switch (booking.status) {
      case 'Upcoming':
        statusColor = AppColors.primary;
        statusText = 'مؤكد';
        break;
      case 'Completed':
        statusColor = AppColors.success;
        statusText = 'مكتمل';
        break;
      case 'Cancelled':
        statusColor = AppColors.error;
        statusText = 'ملغي';
        break;
      default:
        statusColor = context.textSecondaryColor;
        statusText = booking.status;
    }

    return PressEffect(
      onTap: () {
        HapticFeedback.lightImpact();
        Get.to(() => BarberBookingDetailScreen(bookingId: booking.id), transition: Transition.rightToLeft, duration: const Duration(milliseconds: 250));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          border: Border.all(color: context.cardBorderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking.customerName,
                    style: AppTextStyles.body(context.isDark).copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${booking.serviceName} · ${TimeFormatter.format(booking.bookingTime)}',
                    style: AppTextStyles.bodySmall(context.isDark).copyWith(
                      color: context.textSecondaryColor,
                    ),
                  ),
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
                  child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
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
      ),
    );
  }
}
