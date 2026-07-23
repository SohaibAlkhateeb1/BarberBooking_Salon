import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/error_extractor.dart';

class EmployeeScheduleScreen extends StatefulWidget {
  final String employeeId;
  final String employeeName;

  const EmployeeScheduleScreen({
    super.key,
    required this.employeeId,
    required this.employeeName,
  });

  @override
  State<EmployeeScheduleScreen> createState() => _EmployeeScheduleScreenState();
}

class _EmployeeScheduleScreenState extends State<EmployeeScheduleScreen> {
  final ApiClient _api = ApiClient();
  List<Map<String, dynamic>> _schedules = [];
  bool _isLoading = true;
  bool _isSaving = false;

  static const _daysArabic = [
    'السبت',
    'الأحد',
    'الاثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
  ];

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    try {
      final response = await _api.dio.get(
        '/api/barber/dashboard/employees/${widget.employeeId}/schedule',
      );
      final data = response.data;
      final List<dynamic> schedules = data['schedules'] ?? [];

      final mapByDay = <String, Map<String, dynamic>>{};
      for (var s in schedules) {
        mapByDay[s['dayName']] = s;
      }

      final result = <Map<String, dynamic>>[];
      for (var day in _daysArabic) {
        if (mapByDay.containsKey(day)) {
          result.add(mapByDay[day]!);
        } else {
          result.add({
            'dayName': day,
            'isOpen': false,
            'openTime': '09:00',
            'closeTime': '17:00',
          });
        }
      }

      if (mounted) {
        setState(() {
          _schedules = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSchedule() async {
    setState(() => _isSaving = true);
    try {
      final days = _schedules.map((s) => {
        'dayName': s['dayName'],
        'isOpen': s['isOpen'],
        'openTime': s['openTime'],
        'closeTime': s['closeTime'],
      }).toList();

      await _api.dio.put(
        '/api/barber/dashboard/employees/${widget.employeeId}/schedule',
        data: {'days': days},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ جدول الدوام بنجاح'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      String msg = extractErrorMessage(e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickTime(int index, bool isStart) async {
    final current = _schedules[index];
    final timeStr = isStart ? current['openTime'] : current['closeTime'];
    final parts = timeStr.split(':');
    final initial = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.primary,
              surface: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              onSurface: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final timeStr = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() {
        if (isStart) {
          _schedules[index]['openTime'] = timeStr;
        } else {
          _schedules[index]['closeTime'] = timeStr;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text('جدول دوام ${widget.employeeName}'),
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        foregroundColor: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _schedules.length,
                    itemBuilder: (context, index) => _buildDayCard(index, isDark),
                  ),
                ),
                _buildSaveButton(isDark),
              ],
            ),
    );
  }

  Widget _buildDayCard(int index, bool isDark) {
    final day = _schedules[index];
    final isOpen = day['isOpen'] as bool;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOpen
              ? AppColors.primary.withValues(alpha: 0.5)
              : (isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                day['dayName'],
                style: TextStyle(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Switch(
                value: isOpen,
                onChanged: (val) {
                  setState(() => _schedules[index]['isOpen'] = val);
                },
                activeColor: AppColors.primary,
              ),
            ],
          ),
          if (isOpen) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTimeButton(
                    'من: ${day['openTime']}',
                    () => _pickTime(index, true),
                    isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTimeButton(
                    'إلى: ${day['closeTime']}',
                    () => _pickTime(index, false),
                    isDark,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeButton(String text, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: (isDark ? AppColors.darkSurfaceLight : AppColors.lightSurfaceVariant),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(top: BorderSide(color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: _isSaving ? null : _saveSchedule,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
            disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isSaving
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  'حفظ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
        ),
      ),
    );
  }
}
