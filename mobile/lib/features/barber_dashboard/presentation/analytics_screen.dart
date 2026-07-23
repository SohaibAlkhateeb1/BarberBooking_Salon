import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/animations/app_animations.dart';
import '../../../core/services/subscription_service.dart';
import '../../../core/network/api_client.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService(ApiClient());
  CurrentSubscription? _subscription;
  Map<String, dynamic>? _analytics;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final sub = await _subscriptionService.getCurrentSubscription();
      if (sub != null && sub.analyticsLevel != 'none') {
        // Load analytics based on plan level
        final response = await ApiClient().dio.get('/api/barber/dashboard/analytics');
        if (mounted) {
          setState(() {
            _subscription = sub;
            _analytics = response.data;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _subscription = sub;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('التحليلات', style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _subscription == null || _subscription!.analyticsLevel == 'none'
              ? _buildNoAccess(isDark)
              : _subscription!.analyticsLevel == 'basic'
                  ? _buildBasicAnalytics(isDark)
                  : _buildAdvancedAnalytics(isDark),
    );
  }

  Widget _buildNoAccess(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.analytics_outlined, color: (isDark ? AppColors.darkTextHint : AppColors.lightTextHint).withValues(alpha: 0.5), size: 80),
          const SizedBox(height: 20),
          Text(
            'التحليلات غير متاحة',
            style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'اشترك في خطة Pro أو Premium للحصول على التحليلات',
            style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBasicAnalytics(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeIn(
            delay: const Duration(milliseconds: 100),
            child: _buildSectionHeader(isDark, 'التحليلات الأساسية', 'خطة Pro'),
          ),
          const SizedBox(height: 20),

          // Stats Cards
          FadeIn(
            delay: const Duration(milliseconds: 200),
            child: _buildStatsGrid(isDark),
          ),
          const SizedBox(height: 20),

          // Bookings by Day
          FadeIn(
            delay: const Duration(milliseconds: 300),
            child: _buildBookingsByDay(isDark),
          ),
          const SizedBox(height: 20),

          // Top Services
          FadeIn(
            delay: const Duration(milliseconds: 400),
            child: _buildTopServices(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedAnalytics(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeIn(
            delay: const Duration(milliseconds: 100),
            child: _buildSectionHeader(isDark, 'التحليلات المتقدمة', 'خطة Premium'),
          ),
          const SizedBox(height: 20),

          // Stats Cards
          FadeIn(
            delay: const Duration(milliseconds: 200),
            child: _buildStatsGrid(isDark),
          ),
          const SizedBox(height: 20),

          // Customer Analysis
          FadeIn(
            delay: const Duration(milliseconds: 300),
            child: _buildCustomerAnalysis(isDark),
          ),
          const SizedBox(height: 20),

          // Peak Hours
          FadeIn(
            delay: const Duration(milliseconds: 400),
            child: _buildPeakHours(isDark),
          ),
          const SizedBox(height: 20),

          // Service Performance
          FadeIn(
            delay: const Duration(milliseconds: 500),
            child: _buildServicePerformance(isDark),
          ),
          const SizedBox(height: 20),

          // Retention Rate
          FadeIn(
            delay: const Duration(milliseconds: 600),
            child: _buildRetentionRate(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(bool isDark, String title, String planBadge) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            planBadge,
            style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(bool isDark) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: [
        _buildStatCard(isDark, 'الحجوزات', '${_analytics?['totalBookings'] ?? 0}', Icons.calendar_today),
        _buildStatCard(isDark, 'الإيرادات', '${_analytics?['totalRevenue'] ?? 0} ₪', Icons.attach_money),
        _buildStatCard(isDark, 'متوسط التقييم', '${_analytics?['averageRating'] ?? 0}', Icons.star),
        _buildStatCard(isDark, 'الزبائن', '${_analytics?['totalCustomers'] ?? 0}', Icons.people),
      ],
    );
  }

  Widget _buildStatCard(bool isDark, String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsByDay(bool isDark) {
    final days = ['السبت', 'الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة'];
    final values = _analytics?['bookingsByDay'] ?? [0, 0, 0, 0, 0, 0, 0];
    final maxValue = (values as List).fold<int>(0, (max, v) => v > max ? v : max);

    return _buildCard(isDark, 'الحجوزات حسب اليوم', Column(
      children: List.generate(7, (index) {
        final percentage = maxValue > 0 ? (values[index] / maxValue) : 0.0;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox(
                width: 60,
                child: Text(
                  days[index],
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
              Expanded(
                child: LinearProgressIndicator(
                  value: percentage.toDouble(),
                  backgroundColor: isDark ? AppColors.darkSurfaceLight : AppColors.lightSurfaceVariant,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 30,
                child: Text(
                  '${values[index]}',
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        );
      }),
    ));
  }

  Widget _buildTopServices(bool isDark) {
    final services = _analytics?['topServices'] ?? [];

    return _buildCard(isDark, 'الخدمات الأكثر طلباً', Column(
      children: (services as List).take(5).toList().asMap().entries.map((entry) {
        final service = entry.value;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    '${entry.key + 1}',
                    style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  service['name'] ?? '',
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    fontSize: 14,
                  ),
                ),
              ),
              Text(
                '${service['count'] ?? 0} حجز',
                style: TextStyle(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      }).toList(),
    ));
  }

  Widget _buildCustomerAnalysis(bool isDark) {
    return _buildCard(isDark, 'تحليل الزبائن', Column(
      children: [
        _buildAnalysisRow(isDark, 'الزبائن الجدد', '${_analytics?['newCustomers'] ?? 0}', AppColors.primary),
        _buildAnalysisRow(isDark, 'الزبائن العائدين', '${_analytics?['returningCustomers'] ?? 0}', AppColors.success),
        const SizedBox(height: 12),
        Text(
          'معدل العودة: ${_analytics?['returnRate'] ?? 0}%',
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ));
  }

  Widget _buildPeakHours(bool isDark) {
    final hours = _analytics?['peakHours'] ?? [];

    return _buildCard(isDark, 'ساعات الذروة', Column(
      children: (hours as List).take(5).toList().asMap().entries.map((entry) {
        final hour = entry.value;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Icon(Icons.access_time, color: AppColors.primary, size: 16),
              const SizedBox(width: 8),
              Text(
                '${hour['hour']}:00',
                style: TextStyle(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Text(
                '${hour['count'] ?? 0} حجز',
                style: TextStyle(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      }).toList(),
    ));
  }

  Widget _buildServicePerformance(bool isDark) {
    final services = _analytics?['servicePerformance'] ?? [];

    return _buildCard(isDark, 'أداء الخدمات', Column(
      children: (services as List).take(5).toList().asMap().entries.map((entry) {
        final service = entry.value;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service['name'] ?? '',
                      style: TextStyle(
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${service['bookings'] ?? 0} حجز',
                      style: TextStyle(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '${service['revenue'] ?? 0} ₪',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    ));
  }

  Widget _buildRetentionRate(bool isDark) {
    return _buildCard(isDark, 'معدل الاحتفاظ', Column(
      children: [
        SizedBox(
          height: 120,
          width: 120,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 120,
                width: 120,
                child: CircularProgressIndicator(
                  value: (_analytics?['retentionRate'] ?? 0) / 100,
                  backgroundColor: isDark ? AppColors.darkSurfaceLight : AppColors.lightSurfaceVariant,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  strokeWidth: 10,
                ),
              ),
              Text(
                '${_analytics?['retentionRate'] ?? 0}%',
                style: TextStyle(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'نسبة الزبائن العائدين',
          style: TextStyle(
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            fontSize: 14,
          ),
        ),
      ],
    ));
  }

  Widget _buildAnalysisRow(bool isDark, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(bool isDark, String title, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
