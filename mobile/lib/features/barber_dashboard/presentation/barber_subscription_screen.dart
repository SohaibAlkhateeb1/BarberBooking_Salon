import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/animations/app_animations.dart';
import '../../../core/services/subscription_service.dart';
import '../../../core/network/api_client.dart';
import 'plan_selection_screen.dart';

class BarberSubscriptionScreen extends StatefulWidget {
  const BarberSubscriptionScreen({super.key});

  @override
  State<BarberSubscriptionScreen> createState() => _BarberSubscriptionScreenState();
}

class _BarberSubscriptionScreenState extends State<BarberSubscriptionScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService(ApiClient());
  CurrentSubscription? _subscription;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final sub = await _subscriptionService.getCurrentSubscription();
      if (mounted) {
        setState(() {
          _subscription = sub;
          _isLoading = false;
        });
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
        title: Text('اشتراكي', style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _subscription == null
              ? _buildNoSubscription(isDark)
              : _buildSubscriptionDetails(isDark),
    );
  }

  Widget _buildNoSubscription(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.card_membership_outlined, color: (isDark ? AppColors.darkTextHint : AppColors.lightTextHint).withValues(alpha: 0.5), size: 80),
          const SizedBox(height: 20),
          Text(
            'لا يوجد اشتراك نشط',
            style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'اشترك في باقة للحصول على مميزات إضافية',
            style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary, fontSize: 14),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PlanSelectionScreen()),
              );
              if (result == true) _loadData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('اختر خطة'),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionDetails(bool isDark) {
    final sub = _subscription!;
    final dateFormat = DateFormat('yyyy-MM-dd');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Plan Header
          FadeIn(
            delay: const Duration(milliseconds: 100),
            child: _buildPlanHeader(isDark, sub),
          ),
          const SizedBox(height: 20),

          // Usage Stats
          FadeIn(
            delay: const Duration(milliseconds: 200),
            child: _buildUsageSection(isDark, sub),
          ),
          const SizedBox(height: 20),

          // Date Section
          FadeIn(
            delay: const Duration(milliseconds: 300),
            child: _buildDateSection(isDark, sub, dateFormat),
          ),
          const SizedBox(height: 20),

          // Features Section
          FadeIn(
            delay: const Duration(milliseconds: 400),
            child: _buildFeaturesSection(isDark, sub),
          ),
          const SizedBox(height: 20),

          // Action Buttons
          FadeIn(
            delay: const Duration(milliseconds: 500),
            child: _buildActionButtons(isDark, sub),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanHeader(bool isDark, CurrentSubscription sub) {
    final isCancelledPending = sub.isCancelPending;
    final isExpired = sub.isExpired;

    Color gradientStart, gradientEnd, borderColor, iconColor;
    String statusText;
    Color statusTextColor;

    if (isExpired) {
      gradientStart = AppColors.error.withValues(alpha: 0.2);
      gradientEnd = AppColors.error.withValues(alpha: 0.05);
      borderColor = AppColors.error.withValues(alpha: 0.3);
      iconColor = AppColors.error;
      statusText = 'الاشتراك منتهي';
      statusTextColor = AppColors.error;
    } else if (isCancelledPending) {
      gradientStart = Colors.orange.withValues(alpha: 0.2);
      gradientEnd = Colors.orange.withValues(alpha: 0.05);
      borderColor = Colors.orange.withValues(alpha: 0.3);
      iconColor = Colors.orange;
      statusText = 'إلغاء معلق — ينتهي ${sub.endDate.day}/${sub.endDate.month}/${sub.endDate.year}';
      statusTextColor = Colors.orange;
    } else if (sub.isExpiringSoon) {
      gradientStart = AppColors.error.withValues(alpha: 0.2);
      gradientEnd = AppColors.error.withValues(alpha: 0.05);
      borderColor = AppColors.error.withValues(alpha: 0.3);
      iconColor = AppColors.error;
      statusText = 'ينتهي خلال ${sub.daysRemaining} يوم';
      statusTextColor = AppColors.error;
    } else {
      gradientStart = AppColors.primary.withValues(alpha: 0.2);
      gradientEnd = AppColors.primaryDark.withValues(alpha: 0.05);
      borderColor = AppColors.primary.withValues(alpha: 0.3);
      iconColor = AppColors.primary;
      statusText = '';
      statusTextColor = AppColors.primary;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [gradientStart, gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Icon(Icons.workspace_premium, color: iconColor, size: 48),
          const SizedBox(height: 12),
          Text(
            sub.planNameArabic,
            style: TextStyle(color: iconColor, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '${sub.amountPaid.toInt()} ₪ / ${sub.isYearly ? 'سنة' : 'شهر'}',
            style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          if (statusText.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusTextColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                statusText,
                style: TextStyle(color: statusTextColor, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUsageSection(bool isDark, CurrentSubscription sub) {
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
            'الاستخدام',
            style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildUsageItem(isDark, 'الخدمات', sub.currentServicesCount, sub.maxServices),
          _buildUsageItem(isDark, 'الصور', sub.currentPhotosCount, sub.maxPhotos),
          _buildUsageItem(isDark, 'الحجوزات الشهرية', sub.currentBookingsCount, sub.maxBookingsPerMonth),
          if (sub.maxEmployees > 0)
            _buildUsageItem(isDark, 'الموظفين', sub.currentEmployeesCount, sub.maxEmployees),
        ],
      ),
    );
  }

  Widget _buildUsageItem(bool isDark, String label, int current, int max) {
    final isUnlimited = max < 0;
    final percentage = isUnlimited ? 0.0 : (current / max * 100).clamp(0.0, 100.0);
    final isWarning = percentage >= 80;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary, fontSize: 13),
              ),
              Text(
                isUnlimited ? '$current / ∞' : '$current / $max',
                style: TextStyle(
                  color: isWarning ? AppColors.error : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (!isUnlimited)
            LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: isDark ? AppColors.darkSurfaceLight : AppColors.lightSurfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(
                isWarning ? AppColors.error : AppColors.primary,
              ),
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
        ],
      ),
    );
  }

  Widget _buildDateSection(bool isDark, CurrentSubscription sub, DateFormat dateFormat) {
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
            'فترة الاشتراك',
            style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildDateItem(isDark, Icons.play_circle_outline, 'تاريخ البداية', dateFormat.format(sub.startDate)),
              const SizedBox(width: 16),
              _buildDateItem(isDark, Icons.stop_circle_outlined, 'تاريخ النهاية', dateFormat.format(sub.endDate)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateItem(bool isDark, IconData icon, String label, String date) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceLight : AppColors.lightSurfaceVariant,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 16),
                const SizedBox(width: 6),
                Text(label, style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 6),
            Text(date, style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesSection(bool isDark, CurrentSubscription sub) {
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
            'الخصائص',
            style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildFeatureItem(isDark, 'الخدمات', sub.maxServices < 0 ? 'غير محدود' : '${sub.maxServices}', true),
          _buildFeatureItem(isDark, 'الصور', sub.maxPhotos < 0 ? 'غير محدود' : '${sub.maxPhotos}', true),
          _buildFeatureItem(isDark, 'الحجوزات الشهرية', sub.maxBookingsPerMonth < 0 ? 'غير محدود' : '${sub.maxBookingsPerMonth}', true),
          if (sub.maxEmployees > 0 || sub.planName == 'premium')
            _buildFeatureItem(isDark, 'الموظفين', sub.maxEmployees < 0 ? 'غير محدود' : '${sub.maxEmployees}', true),
          _buildFeatureItem(isDark, 'التحليلات', sub.analyticsLevel == 'none' ? 'لا' : (sub.analyticsLevel == 'basic' ? 'أساسية' : 'متقدمة'), sub.analyticsLevel != 'none'),
          _buildFeatureItem(isDark, 'أكواد الخصم', '', sub.hasPromoCodes),
          _buildFeatureItem(isDark, 'الدعم أولوية', '', sub.hasPrioritySupport),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(bool isDark, String text, String value, bool isAvailable) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            isAvailable ? Icons.check_circle : Icons.cancel,
            color: isAvailable ? AppColors.primary : AppColors.error,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                fontSize: 14,
              ),
            ),
          ),
          if (value.isNotEmpty)
            Flexible(
              child: Text(
                value,
                style: TextStyle(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isDark, CurrentSubscription sub) {
    final isActive = sub.status == 'active' && !sub.isExpired;
    final isCancelPending = sub.isCancelPending;
    final isExpired = sub.isExpired;

    return Column(
      children: [
        // Renew / Reactivate Button (for expired or cancel_pending)
        if (isExpired || isCancelPending)
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlanSelectionScreen())).then((_) => _loadData()),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                isExpired ? 'تجديد الاشتراك' : 'إعادة تفعيل الاشتراك',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),

        // Active subscription actions
        if (isActive) ...[
          if (sub.planName != 'premium')
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlanSelectionScreen())).then((_) => _loadData()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('ترقية الخطة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          const SizedBox(height: 12),
          if (sub.planName != 'basic')
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () => _showCancelDialog(isDark),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('إلغاء الاشتراك', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ],
    );
  }

  void _showCancelDialog(bool isDark) {
    final sub = _subscription!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        title: Text('إلغاء الاشتراك', style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'هل أنت متأكد من إلغاء الاشتراك؟',
              style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('الخطة الحالية: ${sub.planNameArabic}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('تنتهي: ${sub.endDate.day}/${sub.endDate.month}/${sub.endDate.year}'),
                  const SizedBox(height: 8),
                  const Text('• ستظل تستخدم جميع ميزات الخطة حتى تاريخ الانتهاء', style: TextStyle(fontSize: 13)),
                  const Text('• بعد الانتهاء، ستتوقف الميزات المدفوعة', style: TextStyle(fontSize: 13)),
                  const Text('• يمكنك تجديد الاشتراك في أي وقت', style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _cancelSubscription();
            },
            child: const Text('تأكيد الإلغاء', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelSubscription() async {
    try {
      await _subscriptionService.cancel();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إلغاء الاشتراك. ستظل تستخدم الميزات حتى تاريخ الانتهاء.')),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    }
  }
}
