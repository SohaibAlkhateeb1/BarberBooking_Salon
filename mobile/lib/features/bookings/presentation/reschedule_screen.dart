import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/animations/app_animations.dart';
import '../../../core/utils/time_formatter.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/error_extractor.dart';
import '../data/bookings_service.dart';

class RescheduleScreen extends StatefulWidget {
  final String bookingId;

  const RescheduleScreen({super.key, required this.bookingId});

  @override
  State<RescheduleScreen> createState() => _RescheduleScreenState();
}

class _RescheduleScreenState extends State<RescheduleScreen> {
  final BookingsService _bookingsService = BookingsService(ApiClient());
  BookingDetailModel? _booking;
  bool _isLoading = true;
  bool _isSubmitting = false;
  DateTime? _selectedDate;
  String? _selectedTime;
  bool _loadingSlots = false;

  List<String> _availableSlotTimes = [];

  final List<String> _allTimes = const [
    '09:00',
    '09:30',
    '10:00',
    '10:30',
    '11:00',
    '11:30',
    '12:00',
    '12:30',
    '13:00',
    '13:30',
    '14:00',
    '14:30',
    '15:00',
    '15:30',
    '16:00',
    '16:30',
    '17:00',
    '17:30',
    '18:00',
    '18:30',
    '19:00',
    '19:30',
    '20:00',
    '20:30',
    '21:00',
  ];

  @override
  void initState() {
    super.initState();
    _loadBookingDetail();
  }

  Future<void> _loadBookingDetail() async {
    try {
      final detail = await _bookingsService.getBookingDetail(widget.bookingId);
      if (mounted) {
        setState(() {
          _booking = detail;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadAvailableSlots() async {
    if (_selectedDate == null || _booking == null) return;
    setState(() => _loadingSlots = true);
    try {
      final dateStr = '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';
      final slots = await _bookingsService.getAvailableSlots(
        barberProfileId: _booking!.barberProfileId,
        date: dateStr,
        durationInMinutes: _booking!.serviceDuration,
      );
      if (mounted) {
        setState(() {
          _loadingSlots = false;
          _selectedTime = null;
          _availableSlotTimes = slots
              .where((s) => s.isAvailable)
              .map((s) => s.time)
              .toList();
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingSlots = false);
    }
  }

  List<String> _getFilteredTimes() {
    final now = DateTime.now();
    final isToday = _selectedDate != null &&
        _selectedDate!.year == now.year &&
        _selectedDate!.month == now.month &&
        _selectedDate!.day == now.day;

    if (!isToday) return _availableSlotTimes.isNotEmpty ? _availableSlotTimes : _allTimes;

    final currentHour = now.hour;
    final currentMinute = now.minute;

    final sourceSlots = _availableSlotTimes.isNotEmpty ? _availableSlotTimes : _allTimes;
    return sourceSlots.where((time) {
      final hour = int.parse(time.split(':')[0]);
      final minute = int.parse(time.split(':')[1]);
      if (hour > currentHour) return true;
      if (hour == currentHour && minute > currentMinute) return true;
      return false;
    }).toList();
  }

  Future<void> _selectDate() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.primary,
              surface: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              onSurface: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
            dialogTheme: DialogThemeData(backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _loadAvailableSlots();
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    const days = ['الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];
    return '${days[date.weekday - 1]}، ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(String time) {
    final hour = int.parse(time.split(':')[0]);
    final minute = time.split(':')[1];
    final period = hour >= 12 ? 'م' : 'ص';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  Future<void> _submit() async {
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار التاريخ والوقت'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final dateStr = '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';
      await _bookingsService.rescheduleBooking(
        id: widget.bookingId,
        newDate: dateStr,
        newTime: _selectedTime!,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إعادة جدولة الحجز بنجاح'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      String msg = extractErrorMessage(e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_booking != null)
                            FadeIn(
                              delay: const Duration(milliseconds: 100),
                              child: _buildBookingSummary(),
                            ),
                          const SizedBox(height: 24),
                          FadeIn(
                            delay: const Duration(milliseconds: 200),
                            child: _buildDatePicker(),
                          ),
                          const SizedBox(height: 20),
                          FadeIn(
                            delay: const Duration(milliseconds: 300),
                            child: _buildTimePicker(),
                          ),
                          const SizedBox(height: 32),
                          FadeIn(
                            delay: const Duration(milliseconds: 400),
                            child: _buildSubmitButton(),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Icon(Icons.arrow_back_ios, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary, size: 20),
          ),
          const Spacer(),
          Text(
            'إعادة جدولة الحجز',
            style: TextStyle(
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 20),
        ],
      ),
    );
  }

  Widget _buildBookingSummary() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final booking = _booking!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الحجز الحالي',
            style: TextStyle(
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.person, color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  booking.barberName,
                  style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.content_cut, color: isDark ? AppColors.darkTextHint : AppColors.lightTextHint, size: 20),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  '${booking.serviceName} - ${booking.serviceDuration} دقيقة',
                  style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined, color: isDark ? AppColors.darkTextHint : AppColors.lightTextHint, size: 20),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  '${booking.bookingDate} - ${TimeFormatter.format(booking.bookingTime)}',
                  style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'اختر التاريخ الجديد',
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _selectDate,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _selectedDate != null ? AppColors.primary : (isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  color: _selectedDate != null ? AppColors.primary : (isDark ? AppColors.darkTextHint : AppColors.lightTextHint),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  _selectedDate != null ? _formatDate(_selectedDate!) : 'اضغط لاختيار التاريخ',
                  style: TextStyle(
                    color: _selectedDate != null
                        ? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)
                        : (isDark ? AppColors.darkTextHint : AppColors.lightTextHint),
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                if (_selectedDate != null)
                  const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimePicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filteredTimes = _getFilteredTimes();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'اختر الوقت الجديد',
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (_loadingSlots)
          const Center(child: CircularProgressIndicator(color: AppColors.primary))
        else if (filteredTimes.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                _selectedDate == null ? 'اختر التاريخ أولاً' : 'لا توجد مواعيد متاحة لهذا اليوم',
                style: TextStyle(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: filteredTimes.map((time) {
              final isSelected = _selectedTime == time;
              return GestureDetector(
                onTap: () => setState(() => _selectedTime = time),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : (isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
                    ),
                  ),
                  child: Text(
                    _formatTime(time),
                    style: TextStyle(
                      color: isSelected ? (isDark ? AppColors.darkBackground : AppColors.lightBackground) : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isSubmitting
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'تأكيد الموعد الجديد',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}
