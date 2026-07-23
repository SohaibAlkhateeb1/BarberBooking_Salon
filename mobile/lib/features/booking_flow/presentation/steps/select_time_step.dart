import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/animations/app_animations.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/time_formatter.dart';
import '../../../bookings/data/bookings_service.dart';

class SelectTimeStep extends StatefulWidget {
  final String barberProfileId;
  final String? employeeId;
  final DateTime selectedDate;
  final String? selectedTime;
  final int durationInMinutes;
  final ValueChanged<String> onTimeSelected;
  final VoidCallback onNext;

  const SelectTimeStep({super.key, required this.barberProfileId, this.employeeId, required this.selectedDate, required this.selectedTime, this.durationInMinutes = 30, required this.onTimeSelected, required this.onNext});

  @override
  State<SelectTimeStep> createState() => _SelectTimeStepState();
}

class _SelectTimeStepState extends State<SelectTimeStep> {
  final BookingsService _bookingsService = BookingsService(ApiClient());
  List<AvailableSlotModel> _slots = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() { super.initState(); _loadAvailableSlots(); }

  Future<void> _loadAvailableSlots() async {
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(widget.selectedDate);
      final slots = await _bookingsService.getAvailableSlots(barberProfileId: widget.barberProfileId, date: dateStr, employeeId: widget.employeeId, durationInMinutes: widget.durationInMinutes);
      setState(() { _slots = slots; _isLoading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
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
            AppButton(label: 'إعادة المحاولة', onPressed: _loadAvailableSlots, isSmall: true, width: 160),
          ],
        ),
      );
    }

    final isToday = DateFormat('yyyy-MM-dd').format(widget.selectedDate) == DateFormat('yyyy-MM-dd').format(DateTime.now());
    final now = DateTime.now();
    final currentHour = now.hour;
    final currentMinute = now.minute;

    final filteredSlots = isToday ? _slots.where((s) {
      final parts = s.time.split(':');
      final h = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 0;
      if (h > currentHour) return true;
      if (h == currentHour && m > currentMinute) return true;
      return false;
    }).toList() : _slots;

    final morningSlots = filteredSlots.where((s) => s.period == 'صباحاً').toList();
    final afternoonSlots = filteredSlots.where((s) => s.period == 'مساءً').toList();
    final bookedCount = filteredSlots.where((s) => !s.isAvailable).length;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                FadeIn(child: Text('اختر الوقت', style: AppTextStyles.headline(isDark))),
                const SizedBox(height: 4),
                FadeIn(delay: const Duration(milliseconds: 100), child: Text('المواعيد المتاحة ليوم ${DateFormat('EEEE d MMMM', 'ar').format(widget.selectedDate)}', style: AppTextStyles.secondary(isDark))),
                if (bookedCount > 0) Padding(padding: const EdgeInsets.only(top: 4), child: Text('$bookedCount مواعيد محجوزة', style: const TextStyle(color: AppColors.error, fontSize: 12))),
                const SizedBox(height: 20),
                if (morningSlots.isNotEmpty) ...[
                  FadeIn(delay: const Duration(milliseconds: 200), child: Text('الصباح', style: AppTextStyles.subtitle(isDark))),
                  const SizedBox(height: 12),
                  FadeIn(delay: const Duration(milliseconds: 250), child: _buildTimeGrid(morningSlots, isDark)),
                  const SizedBox(height: 24),
                ],
                if (afternoonSlots.isNotEmpty) ...[
                  FadeIn(delay: const Duration(milliseconds: 300), child: Text('الظهيرة', style: AppTextStyles.subtitle(isDark))),
                  const SizedBox(height: 12),
                  FadeIn(delay: const Duration(milliseconds: 350), child: _buildTimeGrid(afternoonSlots, isDark)),
                ],
                if (filteredSlots.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('لا توجد مواعيد متاحة لهذا اليوم', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)))),
              ],
            ),
          ),
        ),
        _buildBottomButton(isDark),
      ],
    );
  }

  Widget _buildTimeGrid(List<AvailableSlotModel> slots, bool isDark) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: slots.map((slot) {
        final isSelected = widget.selectedTime == slot.time;
        final isAvailable = slot.isAvailable;
        return GestureDetector(
          onTap: isAvailable ? () { HapticFeedback.lightImpact(); widget.onTimeSelected(slot.time); } : null,
          child: Container(
            width: 90,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : isAvailable ? context.surfaceColor : AppColors.error.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isSelected ? AppColors.primary : isAvailable ? context.cardBorderColor : AppColors.error.withValues(alpha: 0.3)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(TimeFormatter.format(slot.time), style: TextStyle(color: isSelected ? context.backgroundColor : isAvailable ? context.textColor : AppColors.error, fontSize: 14, fontWeight: FontWeight.w500, decoration: isAvailable ? null : TextDecoration.lineThrough)),
                if (!isAvailable) const Icon(Icons.lock_outline, size: 12, color: AppColors.error),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomButton(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
      decoration: BoxDecoration(color: context.surfaceColor, border: Border(top: BorderSide(color: context.cardBorderColor))),
      child: SafeArea(top: false, child: AppButton(label: 'متابعة', onPressed: widget.selectedTime != null ? widget.onNext : null)),
    );
  }
}
