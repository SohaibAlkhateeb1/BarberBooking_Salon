import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/animations/app_animations.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/network/api_client.dart';

class SelectServiceStep extends StatefulWidget {
  final String barberProfileId;
  final String? employeeId;
  final Set<String> selectedServiceIds;
  final ValueChanged<String> onServiceToggled;
  final VoidCallback onNext;

  const SelectServiceStep({super.key, required this.barberProfileId, this.employeeId, required this.selectedServiceIds, required this.onServiceToggled, required this.onNext});

  @override
  State<SelectServiceStep> createState() => _SelectServiceStepState();
}

class _SelectServiceStepState extends State<SelectServiceStep> {
  final ApiClient _api = ApiClient();
  List<_ServiceItem> _services = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() { super.initState(); _loadServices(); }

  @override
  void didUpdateWidget(covariant SelectServiceStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.employeeId != widget.employeeId) _loadServices();
  }

  Future<void> _loadServices() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final empParam = (widget.employeeId != null && widget.employeeId!.isNotEmpty) ? widget.employeeId! : '';
      final response = await _api.dio.get('/api/barbers/${widget.barberProfileId}/employee-services', queryParameters: {'employeeId': empParam});
      final data = response.data as List;
      if (mounted) {
        setState(() {
          _services = data.map((s) => _ServiceItem(id: s['id'] ?? '', name: s['name'] ?? '', price: (s['price'] ?? 0).toDouble(), durationInMinutes: s['durationInMinutes'] ?? 0)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = 'فشل تحميل الخدمات'; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    if (_isLoading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            Text(_error!, style: AppTextStyles.body(isDark)),
            const SizedBox(height: 16),
            AppButton(label: 'إعادة المحاولة', onPressed: _loadServices, isSmall: true, width: 160),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                FadeIn(child: Text('اختر الخدمة', style: AppTextStyles.headline(isDark))),
                const SizedBox(height: 4),
                FadeIn(delay: const Duration(milliseconds: 100), child: Text('اختر الخدمة التي تريدها من ${_services.length} خدمة متاحة', style: AppTextStyles.secondary(isDark))),
                const SizedBox(height: 20),
                ..._services.asMap().entries.map((entry) => FadeIn(delay: Duration(milliseconds: 150 + entry.key * 80), child: _buildServiceCard(entry.value, isDark))),
                if (_services.isEmpty) Padding(padding: const EdgeInsets.all(40), child: Center(child: Text('لا توجد خدمات متاحة لهذا الموظف', style: AppTextStyles.secondary(isDark)))),
              ],
            ),
          ),
        ),
        _buildBottomButton(isDark),
      ],
    );
  }

  Widget _buildServiceCard(_ServiceItem service, bool isDark) {
    final isSelected = widget.selectedServiceIds.contains(service.id);
    return GestureDetector(
      onTap: () { HapticFeedback.lightImpact(); widget.onServiceToggled(service.id); },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : context.surfaceColor,
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          border: Border.all(color: isSelected ? AppColors.primary : context.cardBorderColor, width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(AppBorderRadius.sm)),
              child: const Icon(Icons.content_cut, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(service.name, style: AppTextStyles.bodyMedium(isDark).copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('${service.durationInMinutes} دقيقة', style: AppTextStyles.caption(isDark)),
                ],
              ),
            ),
            Text('${service.price.toStringAsFixed(0)} ش', style: AppTextStyles.primary(isDark).copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(width: 12),
            Container(
              width: 24, height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.primary : Colors.transparent,
                border: Border.all(color: isSelected ? AppColors.primary : context.hintColor, width: 2),
              ),
              child: isSelected ? Icon(Icons.check, color: context.backgroundColor, size: 16) : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButton(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
      decoration: BoxDecoration(color: context.surfaceColor, border: Border(top: BorderSide(color: context.cardBorderColor))),
      child: SafeArea(
        top: false,
        child: AppButton(
          label: widget.selectedServiceIds.isNotEmpty ? 'متابعة (${widget.selectedServiceIds.length} خدمة)' : 'متابعة',
          onPressed: widget.selectedServiceIds.isNotEmpty ? widget.onNext : null,
        ),
      ),
    );
  }
}

class _ServiceItem {
  final String id;
  final String name;
  final double price;
  final int durationInMinutes;
  _ServiceItem({required this.id, required this.name, required this.price, required this.durationInMinutes});
}
