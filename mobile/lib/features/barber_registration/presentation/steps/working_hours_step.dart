import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/animations/app_animations.dart';
import '../../../../core/models/barber_registration_data.dart';
import '../../../../core/widgets/app_button.dart';

class WorkingHoursStep extends StatefulWidget {
  final BarberRegistrationData data;
  final VoidCallback onNext;
  final VoidCallback onBack;
  const WorkingHoursStep({super.key, required this.data, required this.onNext, required this.onBack});

  @override
  State<WorkingHoursStep> createState() => _WorkingHoursStepState();
}

class _WorkingHoursStepState extends State<WorkingHoursStep> {
  @override
  void initState() {
    super.initState();
    if (widget.data.workingHours.isEmpty) {
      widget.data.workingHours.addAll([
        DaySchedule(dayName: 'السبت'),
        DaySchedule(dayName: 'الأحد'),
        DaySchedule(dayName: 'الاثنين'),
        DaySchedule(dayName: 'الثلاثاء'),
        DaySchedule(dayName: 'الأربعاء'),
        DaySchedule(dayName: 'الخميس'),
        DaySchedule(dayName: 'الجمعة', isEnabled: false),
      ]);
    }
  }

  void _validateAndNext() {
    final enabledDays = widget.data.workingHours.where((d) => d.isEnabled).length;
    if (enabledDays == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('يجب تفعيل يوم عمل واحد على الأقل', textAlign: TextAlign.center),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          FadeIn(
            delay: const Duration(milliseconds: 0),
            child: Text('أوقات العمل', style: AppTextStyles.headline(isDark)),
          ),
          const SizedBox(height: 8),
          FadeIn(
            delay: const Duration(milliseconds: 50),
            child: Text('حدد أيام وساعات العمل الخاصة بصالونك.', style: AppTextStyles.secondary(isDark)),
          ),
          const SizedBox(height: 16),
          FadeIn(
            delay: const Duration(milliseconds: 100),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  for (var day in widget.data.workingHours) {
                    day.isEnabled = true;
                    day.startTime = '09:00 AM';
                    day.endTime = '10:00 PM';
                  }
                });
              },
              child: Row(
                children: [
                  Container(
                    width: 22, height: 22,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), border: Border.all(color: AppColors.primary, width: 2), color: AppColors.primary),
                    child: Icon(Icons.check, size: 16, color: context.backgroundColor),
                  ),
                  const SizedBox(width: 8),
                  Text('تطبيق على جميع الأيام', style: AppTextStyles.primary(isDark)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          FadeIn(
            delay: const Duration(milliseconds: 150),
            child: Container(
              decoration: BoxDecoration(color: context.surfaceColor, borderRadius: BorderRadius.circular(AppBorderRadius.lg), border: Border.all(color: context.cardBorderColor)),
              child: Column(
                children: List.generate(widget.data.workingHours.length, (index) => _buildDayRow(index, isDark)),
              ),
            ),
          ),
          const SizedBox(height: 24),
          FadeIn(
            delay: const Duration(milliseconds: 200),
            child: AppButton(label: 'الحفظ والمتابعة', onPressed: _validateAndNext),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDayRow(int index, bool isDark) {
    final day = widget.data.workingHours[index];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: index < widget.data.workingHours.length - 1 ? BorderSide(color: context.cardBorderColor, width: 0.5) : BorderSide.none),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 55,
            child: Text(day.dayName, style: TextStyle(color: day.isEnabled ? context.textColor : context.hintColor, fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: day.isEnabled,
              onChanged: (val) => setState(() => day.isEnabled = val),
              activeColor: AppColors.primary,
              activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
              inactiveThumbColor: context.hintColor,
              inactiveTrackColor: context.cardBorderColor,
            ),
          ),
          if (day.isEnabled) ...[
            _buildTimeField(time: day.endTime, onTap: () => _pickTime(context, index, isStart: false)),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Text('-', style: TextStyle(color: context.hintColor, fontSize: 12))),
            _buildTimeField(time: day.startTime, onTap: () => _pickTime(context, index, isStart: true)),
          ] else ...[
            Expanded(child: Text(day.startTime, style: TextStyle(color: context.hintColor, fontSize: 12), textAlign: TextAlign.center, maxLines: 1)),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Text('-', style: TextStyle(color: context.hintColor, fontSize: 12))),
            Expanded(child: Text(day.endTime, style: TextStyle(color: context.hintColor, fontSize: 12), textAlign: TextAlign.center, maxLines: 1)),
          ],
        ],
      ),
    );
  }

  Future<void> _pickTime(BuildContext context, int index, {required bool isStart}) async {
    final day = widget.data.workingHours[index];
    final current = isStart ? day.startTime : day.endTime;
    final parsed = _parseTimeString(current);

    final picked = await showTimePicker(
      context: context,
      initialTime: parsed,
      builder: (context, child) {
        return MediaQuery(data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false), child: child!);
      },
    );

    if (picked != null) {
      final now = DateTime.now();
      final dt = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
      final formatted = DateFormat('hh:mm a').format(dt);
      setState(() {
        if (isStart) { day.startTime = formatted; } else { day.endTime = formatted; }
      });
    }
  }

  TimeOfDay _parseTimeString(String time) {
    try {
      final clean = time.trim();
      final formats = ['hh:mm a', 'h:mm a', 'HH:mm', 'H:mm'];
      for (final fmt in formats) {
        try { final d = DateFormat(fmt).parseStrict(clean); return TimeOfDay.fromDateTime(d); } catch (_) {}
      }
    } catch (_) {}
    return const TimeOfDay(hour: 9, minute: 0);
  }

  Widget _buildTimeField({required String time, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 75,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppBorderRadius.sm),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(child: Text(time, style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w500), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 2),
            const Icon(Icons.access_time, size: 10, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
