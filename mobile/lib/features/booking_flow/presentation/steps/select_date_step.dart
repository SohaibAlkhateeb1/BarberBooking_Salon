import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/animations/app_animations.dart';
import '../../../../core/widgets/app_button.dart';

class SelectDateStep extends StatelessWidget {
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final VoidCallback onNext;

  const SelectDateStep({super.key, required this.selectedDate, required this.onDateSelected, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final now = DateTime.now();
    final dates = List.generate(7, (i) => DateTime(now.year, now.month, now.day + i));

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                FadeIn(child: Text('اختر التاريخ', style: AppTextStyles.headline(isDark))),
                const SizedBox(height: 4),
                FadeIn(delay: const Duration(milliseconds: 100), child: Text('اختر التاريخ المناسب لك', style: AppTextStyles.secondary(isDark))),
                const SizedBox(height: 20),
                FadeIn(delay: const Duration(milliseconds: 200), child: _buildQuickButtons(context, dates, isDark)),
                const SizedBox(height: 24),
                FadeIn(delay: const Duration(milliseconds: 300), child: _buildDatePicker(context, dates, isDark)),
              ],
            ),
          ),
        ),
        _buildBottomButton(context, isDark),
      ],
    );
  }

  Widget _buildQuickButtons(BuildContext context, List<DateTime> dates, bool isDark) {
    final today = DateTime.now();
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final weekend = _getNextWeekend();
    final quickDates = [_QuickDate('اليوم', today), _QuickDate('غداً', tomorrow), _QuickDate('نهاية الأسبوع', weekend)];

    return Row(
      children: quickDates.map((qd) {
        final isSelected = selectedDate != null && selectedDate!.year == qd.date.year && selectedDate!.month == qd.date.month && selectedDate!.day == qd.date.day;
        return Expanded(
          child: GestureDetector(
            onTap: () { HapticFeedback.lightImpact(); onDateSelected(qd.date); },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : context.surfaceColor,
                borderRadius: BorderRadius.circular(AppBorderRadius.md),
                border: Border.all(color: isSelected ? AppColors.primary : context.cardBorderColor, width: isSelected ? 2 : 1),
              ),
              child: Center(child: Text(qd.label, style: TextStyle(color: isSelected ? AppColors.primary : context.textSecondaryColor, fontSize: 14, fontWeight: FontWeight.w600))),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDatePicker(BuildContext context, List<DateTime> dates, bool isDark) {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: dates.length,
        itemBuilder: (_, index) {
          final date = dates[index];
          final isSelected = selectedDate != null && selectedDate!.year == date.year && selectedDate!.month == date.month && selectedDate!.day == date.day;
          final dayName = DateFormat('EEE', 'ar').format(date);
          final monthName = DateFormat('MMM', 'ar').format(date);

          return GestureDetector(
            onTap: () { HapticFeedback.lightImpact(); onDateSelected(date); },
            child: Container(
              width: 70,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : context.surfaceColor,
                borderRadius: BorderRadius.circular(AppBorderRadius.md),
                border: Border.all(color: isSelected ? AppColors.primary : context.cardBorderColor, width: isSelected ? 2 : 1),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(dayName, style: TextStyle(color: isSelected ? context.backgroundColor : context.hintColor, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text('${date.day}', style: TextStyle(color: isSelected ? context.backgroundColor : context.textColor, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(monthName, style: TextStyle(color: isSelected ? context.backgroundColor : context.hintColor, fontSize: 12)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  DateTime _getNextWeekend() {
    final now = DateTime.now();
    final daysUntilSaturday = (6 - now.weekday) % 7;
    final saturday = now.add(Duration(days: daysUntilSaturday == 0 ? 7 : daysUntilSaturday));
    return DateTime(saturday.year, saturday.month, saturday.day);
  }

  Widget _buildBottomButton(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
      decoration: BoxDecoration(color: context.surfaceColor, border: Border(top: BorderSide(color: context.cardBorderColor))),
      child: SafeArea(top: false, child: AppButton(label: 'متابعة', onPressed: selectedDate != null ? onNext : null)),
    );
  }
}

class _QuickDate {
  final String label;
  final DateTime date;
  const _QuickDate(this.label, this.date);
}
