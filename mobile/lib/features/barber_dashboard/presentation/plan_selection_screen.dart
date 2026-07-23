import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/animations/app_animations.dart';
import '../../../core/services/subscription_service.dart';
import '../../../core/network/api_client.dart';
import 'payment_screen.dart';

const _planOrder = {'basic': 0, 'pro': 1, 'premium': 2};

class PlanSelectionScreen extends StatefulWidget {
  const PlanSelectionScreen({super.key});

  @override
  State<PlanSelectionScreen> createState() => _PlanSelectionScreenState();
}

class _PlanSelectionScreenState extends State<PlanSelectionScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService(ApiClient());
  List<SubscriptionPlan> _plans = [];
  bool _isLoading = true;
  bool _isYearly = false;
  String? _selectedPlanId;
  CurrentSubscription? _currentSub;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    try {
      final plans = await _subscriptionService.getPlans();
      CurrentSubscription? sub;
      try { sub = await _subscriptionService.getCurrentSubscription(); } catch (_) {}
      if (mounted) {
        setState(() {
          _plans = plans;
          _currentSub = sub;
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
        title: const Text('اختر الخطة'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        'اختر الخطة المناسبة لصالونك',
                        style: TextStyle(
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'يمكنك تغيير الخطة في أي وقت',
                        style: TextStyle(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      _buildPeriodToggle(isDark),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _plans.length,
                    itemBuilder: (context, index) {
                      return FadeIn(
                        delay: Duration(milliseconds: 100 * index),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildPlanCard(_plans[index], isDark),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPeriodToggle(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isYearly = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: !_isYearly ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'شهري',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: !_isYearly
                        ? (isDark ? AppColors.darkBackground : AppColors.lightBackground)
                        : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isYearly = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _isYearly ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'سنوي وفر ${_plans.isNotEmpty ? _plans.first.discountPercentage : 17}%',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _isYearly
                        ? (isDark ? AppColors.darkBackground : AppColors.lightBackground)
                        : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(SubscriptionPlan plan, bool isDark) {
    final isSelected = _selectedPlanId == plan.id;
    final isPopular = plan.name == 'pro';
    final price = _isYearly ? plan.yearlyPrice : plan.monthlyPrice;
    final period = _isYearly ? 'سنة' : 'شهر';

    return GestureDetector(
      onTap: () => setState(() => _selectedPlanId = plan.id),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPopular
                ? AppColors.primary
                : isSelected
                    ? AppColors.primary
                    : (isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
            width: isPopular || isSelected ? 2 : 1,
          ),
          boxShadow: isPopular
              ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.1), blurRadius: 20, spreadRadius: 2)]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isPopular)
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'ينصح بها',
                    style: TextStyle(
                      color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            if (isPopular) const SizedBox(height: 12),
            Text(
              plan.nameArabic,
              style: TextStyle(
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              plan.description,
              style: TextStyle(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price.toInt().toString(),
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '₪ / $period',
                    style: TextStyle(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildFeatureRow('الخدمات', plan.maxServicesText, true, isDark),
            _buildFeatureRow('الصور', plan.maxPhotosText, true, isDark),
            _buildFeatureRow('الحجوزات الشهرية', plan.maxBookingsText, true, isDark),
            if (plan.maxEmployees > 0 || plan.name == 'premium')
              _buildFeatureRow('الموظفين', plan.maxEmployeesText, true, isDark),
            _buildFeatureRow('التحليلات', plan.analyticsLevel != 'none', true, isDark),
            _buildFeatureRow('أكواد الخصم', plan.hasPromoCodes, true, isDark),
            _buildFeatureRow('الدعم أولوية', plan.hasPrioritySupport, true, isDark),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () => _selectPlan(plan),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isSelected ? AppColors.primary : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                  side: BorderSide(
                    color: isSelected
                        ? AppColors.primary
                        : (isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  isSelected ? 'تم التحديد' : 'اختيار الخطة',
                  style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(String label, dynamic value, bool isDark, bool valueIsBool) {
    final displayValue = value is bool ? (value ? '✓' : '✗') : value.toString();
    final isAvailable = value is bool ? value : true;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            isAvailable ? Icons.check_circle : Icons.cancel_outlined,
            color: isAvailable
                ? AppColors.primary
                : (isDark ? AppColors.darkTextHint : AppColors.lightTextHint),
            size: 20,
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
            displayValue,
            style: TextStyle(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _selectPlan(SubscriptionPlan plan) async {
    final hasActiveSub = _currentSub != null && !_currentSub!.isExpired;
    final isCancelPending = _currentSub?.status == 'cancel_pending';
    final currentPlanName = _currentSub?.planName ?? '';
    final currentIsYearly = _currentSub?.isYearly ?? false;
    final currentLevel = _planOrder[currentPlanName] ?? -1;
    final selectedLevel = _planOrder[plan.name] ?? -1;

    // cancel_pending = subscription still active until EndDate, but user wants to renew
    if (hasActiveSub && isCancelPending) {
      final price = _isYearly ? plan.yearlyPrice : plan.monthlyPrice;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('تجديد الاشتراك'),
          content: Text('اشتراكيك الحالي سينتهي قريباً. هل تريد تجديد الاشتراك بالخطة ${plan.nameArabic}؟\nالفترة: ${_isYearly ? 'سنوي' : 'شهري'} — ${price.toInt()}₪'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('تجديد')),
          ],
        ),
      );

      if (confirmed == true && mounted) {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => PaymentScreen(
            planName: plan.name,
            planNameArabic: plan.nameArabic,
            amount: price,
            isYearly: _isYearly,
          ),
        ));
      }
      return;
    }

    if (hasActiveSub && currentPlanName.isNotEmpty) {
      if (selectedLevel < currentLevel) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('لا يمكن تخفيض الخطة'),
              content: const Text('يجب أن تنتظر حتى ينتهي اشتراكك الحالي لتتمكن من تغيير الخطة إلى خطة أقل.'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('حسناً')),
              ],
            ),
          );
        }
        return;
      }

      if (currentIsYearly && !_isYearly) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('لا يمكن التحويل للدفع الشهري'),
              content: const Text('اشتراكاتك سنوية، لا يمكنك التحويل إلى الدفع الشهري. يمكنك فقط ترقية الخطة مع الحفاظ على الدفع السنوي.'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('حسناً')),
              ],
            ),
          );
        }
        return;
      }

      final isPeriodChange = selectedLevel == currentLevel && _isYearly != currentIsYearly;
      final isUpgrade = selectedLevel > currentLevel;

      if (isPeriodChange || isUpgrade) {
        final newPrice = _isYearly ? plan.yearlyPrice : plan.monthlyPrice;
        final oldPrice = _currentSub?.amountPaid ?? 0;
        final priceDiff = newPrice - oldPrice;

        final String dialogTitle;
        final String dialogMessage;

        if (isPeriodChange) {
          dialogTitle = 'تغيير فترة الاشتراك';
          dialogMessage = 'هل تريد تغيير اشتراكك من ${currentIsYearly ? 'سنوي' : 'شهري'} إلى ${_isYearly ? 'سنوي' : 'شهري'}؟\nالفترة الجديدة: ${newPrice.toInt()}₪ / ${_isYearly ? 'سنة' : 'شهر'}';
        } else {
          dialogTitle = 'ترقية الخطة';
          dialogMessage = 'هل تريد ترقية اشتراكك إلى الخطة ${plan.nameArabic}؟\nالفترة: ${_isYearly ? 'سنوي' : 'شهري'} — ${newPrice.toInt()}₪';
        }

        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(dialogTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dialogMessage),
                if (priceDiff > 0) ...[
                  const SizedBox(height: 8),
                  Text('الفرق المالي: ${priceDiff.toInt()}₪', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
                const SizedBox(height: 12),
                const Text('• سيتم تفعيل الخطة الجديدة مباشرة بعد تأكيد الدفع'),
                const Text('• ستصبح جميع الميزات متاحة فور التفعيل'),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('متابعة')),
            ],
          ),
        );

        if (confirmed == true && mounted) {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => PaymentScreen(
              planName: plan.name,
              planNameArabic: plan.nameArabic,
              amount: newPrice,
              isYearly: _isYearly,
              isUpgrade: isUpgrade,
              fromPlanName: currentPlanName,
            ),
          ));
        }
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لديك اشتراك نشط بهذه الخطة بالفعل')),
        );
      }
      return;
    }

    if (mounted) {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => PaymentScreen(
          planName: plan.name,
          planNameArabic: plan.nameArabic,
          amount: _isYearly ? plan.yearlyPrice : plan.monthlyPrice,
          isYearly: _isYearly,
        ),
      ));
    }
  }
}
