import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/animations/app_animations.dart';
import '../../../../core/models/barber_registration_data.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/error_extractor.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../barber_auth/data/barber_auth_service.dart';
import '../../../barber_dashboard/presentation/payment_screen.dart';

class PricingPlanStep extends StatefulWidget {
  final BarberRegistrationData data;
  const PricingPlanStep({super.key, required this.data});

  @override
  State<PricingPlanStep> createState() => _PricingPlanStepState();
}

class _PricingPlanStepState extends State<PricingPlanStep> {
  bool _isYearly = false;
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _isYearly = widget.data.isYearly;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.arrow_forward, color: context.textColor)),
                  Text('تسجيل الحلاق', style: AppTextStyles.subtitle(isDark).copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    FadeIn(
                      delay: const Duration(milliseconds: 0),
                      child: Text('اختر الخطة المناسبة لصالونك', style: AppTextStyles.headline(isDark), textAlign: TextAlign.center),
                    ),
                    const SizedBox(height: 12),
                    FadeIn(
                      delay: const Duration(milliseconds: 50),
                      child: Text('قم بترقية عملك وإدارة صالونك بأدواتنا المتقدمة.\nيمكنك تغيير الخطة في أي وقت.', style: AppTextStyles.secondary(isDark)),
                    ),
                    const SizedBox(height: 24),
                    FadeIn(delay: const Duration(milliseconds: 100), child: _buildPeriodToggle(isDark)),
                    const SizedBox(height: 24),
                    FadeIn(
                      delay: const Duration(milliseconds: 150),
                      child: _buildPlanCard(id: 'basic', title: 'الأساسية', subtitle: 'للحلاقين المستقلين والصالونات الصغيرة', monthlyPrice: '80', yearlyPrice: '800', features: [('5 خدمات', true), ('5 صور', true), ('150 حجز شهرياً', true), ('إدارة المواعيد', true), ('تذكير تلقائي للعملاء', true), ('تحليلات', false), ('أكواد خصم', false), ('موظفين', false)], isDark: isDark),
                    ),
                    const SizedBox(height: 16),
                    FadeIn(
                      delay: const Duration(milliseconds: 200),
                      child: _buildPlanCard(id: 'pro', title: 'الاحترافية', subtitle: 'الخيار الأمثل للصالونات المتطورة', monthlyPrice: '100', yearlyPrice: '1000', features: [('10 خدمات', true), ('15 صورة', true), ('250 حجز شهرياً', true), ('3 موظفين', true), ('تحليلات أساسية', true), ('أكواد خصم', true), ('دعم أولوية', false)], isPopular: true, isDark: isDark),
                    ),
                    const SizedBox(height: 16),
                    FadeIn(
                      delay: const Duration(milliseconds: 250),
                      child: _buildPlanCard(id: 'premium', title: 'VIP', subtitle: 'للصالونات الكبيرة وسلاسل الحلاقة', monthlyPrice: '150', yearlyPrice: '1500', features: [('15 خدمة', true), ('30 صورة', true), ('350 حجز شهرياً', true), ('10 موظفين', true), ('تحليلات متقدمة', true), ('أكواد خصم', true), ('دعم أولوية', true)], isDark: isDark),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: context.surfaceColor, border: Border(top: BorderSide(color: context.cardBorderColor))),
              child: Column(
                children: [
                  if (_errorMessage.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                      ),
                      child: Text(_errorMessage, style: AppTextStyles.error(isDark), textAlign: TextAlign.center),
                    ),
                  AppButton(
                    label: 'الحفظ والمتابعة',
                    isLoading: _isLoading,
                    onPressed: _isLoading ? null : () async {
                      if (widget.data.selectedPlan.isEmpty) {
                        setState(() { _errorMessage = 'يجب اختيار خطة اشتراك'; });
                        return;
                      }
                      setState(() { _isLoading = true; _errorMessage = ''; });
                      widget.data.isYearly = _isYearly;
                      try {
                        final authService = BarberAuthService(ApiClient());
                        final servicesData = widget.data.services.map((s) => {
                          'name': s.name,
                          'price': double.tryParse(s.price) ?? 0.0,
                          'durationInMinutes': int.tryParse(s.duration) ?? 30,
                        }).toList();
                        final workingHoursData = widget.data.workingHours.map((w) => {
                          'dayName': w.dayName,
                          'isOpen': w.isEnabled,
                          'openTime': w.startTime,
                          'closeTime': w.endTime,
                        }).toList();
                        await authService.register(
                          fullName: widget.data.fullName,
                          phoneNumber: widget.data.phoneNumber,
                          password: widget.data.password,
                          shopName: widget.data.shopName,
                          shopDescription: widget.data.shopDescription,
                          profileImageUrl: widget.data.barberPhotoBase64,
                          shopLogoUrl: widget.data.shopLogoBase64,
                          city: widget.data.city,
                          address: widget.data.address,
                          latitude: widget.data.latitude,
                          longitude: widget.data.longitude,
                          subscriptionPlan: widget.data.selectedPlan,
                          isYearly: widget.data.isYearly,
                          services: servicesData,
                          workingHours: workingHoursData,
                        );
                        if (mounted && context.mounted) {
                          final planPrices = {'basic': 80.0, 'pro': 100.0, 'premium': 150.0};
                          final yearlyPrices = {'basic': 800.0, 'pro': 1000.0, 'premium': 1500.0};
                          final planArabic = {'basic': 'الأساسية', 'pro': 'الاحترافية', 'premium': 'VIP'};
                          final amount = widget.data.isYearly ? (yearlyPrices[widget.data.selectedPlan] ?? 500.0) : (planPrices[widget.data.selectedPlan] ?? 50.0);
                          final arabicName = planArabic[widget.data.selectedPlan] ?? 'الأساسية';
                          Get.offAll(() => PaymentScreen(planName: widget.data.selectedPlan, planNameArabic: arabicName, amount: amount, isYearly: widget.data.isYearly));
                        }
                      } catch (e) {
                        String msg = extractErrorMessage(e);
                        setState(() { _errorMessage = msg; _isLoading = false; });
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodToggle(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: context.surfaceColor, borderRadius: BorderRadius.circular(AppBorderRadius.md), border: Border.all(color: context.cardBorderColor)),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isYearly = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(color: !_isYearly ? AppColors.primary : Colors.transparent, borderRadius: BorderRadius.circular(10)),
                child: Text('شهري', textAlign: TextAlign.center, style: TextStyle(color: !_isYearly ? context.backgroundColor : context.textColor, fontSize: 14, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isYearly = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(color: _isYearly ? AppColors.primary : Colors.transparent, borderRadius: BorderRadius.circular(10)),
                child: Text('سنوي وفر 17%', textAlign: TextAlign.center, style: TextStyle(color: _isYearly ? context.backgroundColor : context.textColor, fontSize: 14, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard({required String id, required String title, required String subtitle, required String monthlyPrice, required String yearlyPrice, required List<(String, bool)> features, bool isPopular = false, bool isDark = false}) {
    final isSelected = widget.data.selectedPlan == id;
    final displayPrice = _isYearly ? yearlyPrice : monthlyPrice;
    final priceLabel = _isYearly ? 'شن / سنة' : 'شن / شهر';

    return GestureDetector(
      onTap: () => setState(() => widget.data.selectedPlan = id),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          border: Border.all(color: isPopular ? AppColors.primary : isSelected ? AppColors.primary : context.cardBorderColor, width: isPopular || isSelected ? 2 : 1),
          boxShadow: isPopular ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.1), blurRadius: 20, spreadRadius: 2)] : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isPopular)
              Align(alignment: Alignment.centerRight, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)), child: Text('ينصح بها', style: TextStyle(color: context.backgroundColor, fontSize: 12, fontWeight: FontWeight.bold)))),
            if (isPopular) const SizedBox(height: 12),
            Text(title, style: AppTextStyles.subtitle(isDark).copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(subtitle, style: AppTextStyles.caption(isDark)),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(displayPrice, style: TextStyle(color: context.textColor, fontSize: 36, fontWeight: FontWeight.bold)),
                const SizedBox(width: 4),
                Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(priceLabel, style: AppTextStyles.secondary(isDark))),
              ],
            ),
            const SizedBox(height: 16),
            ...features.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                Icon(f.$2 ? Icons.check_circle : Icons.cancel_outlined, color: f.$2 ? AppColors.primary : context.hintColor, size: 20),
                const SizedBox(width: 8),
                Text(f.$1, style: TextStyle(color: f.$2 ? context.textColor : context.hintColor, fontSize: 14)),
              ]),
            )),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity, height: 48,
              child: OutlinedButton(
                onPressed: () => setState(() => widget.data.selectedPlan = id),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isSelected ? AppColors.primary : context.textColor,
                  side: BorderSide(color: isSelected ? AppColors.primary : context.cardBorderColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppBorderRadius.md)),
                ),
                child: Text(isSelected ? 'تم التحديد' : 'اختيار الخطة', style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
