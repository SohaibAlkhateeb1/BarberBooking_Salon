import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/animations/app_animations.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/app_button.dart';
import '../../home/data/barbers_service.dart';
import 'steps/select_service_step.dart';
import 'steps/select_barber_step.dart';
import 'steps/select_employee_step.dart';
import 'steps/select_date_step.dart';
import 'steps/select_time_step.dart';
import 'steps/confirm_booking_step.dart';

class BookingFlowScreen extends StatefulWidget {
  final String barberProfileId;
  final List<String> selectedServiceIds;

  const BookingFlowScreen({super.key, required this.barberProfileId, required this.selectedServiceIds});

  @override
  State<BookingFlowScreen> createState() => _BookingFlowScreenState();
}

class _BookingFlowScreenState extends State<BookingFlowScreen> {
  int _currentStep = 0;
  final BarbersService _barbersService = BarbersService(ApiClient());
  BarberDetailModel? _barberDetail;
  bool _isLoading = true;
  String? _error;

  final Set<String> _selectedServiceIds = {};
  String? _selectedEmployeeId;
  String? _selectedEmployeeName;
  DateTime? _selectedDate;
  String? _selectedTime;
  String? _promoCode;
  String? _notes;

  final List<String> _stepLabels = ['الحلاق', 'الفريق', 'الخدمة', 'التاريخ', 'الوقت', 'تأكيد'];

  @override
  void initState() {
    super.initState();
    _loadBarberDetail();
  }

  Future<void> _loadBarberDetail() async {
    try {
      final detail = await _barbersService.getBarberById(widget.barberProfileId);
      setState(() { _barberDetail = detail; _isLoading = false; _selectedServiceIds.addAll(widget.selectedServiceIds); });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  void _nextStep() { if (_currentStep < 5) setState(() => _currentStep++); }
  void _prevStep() { if (_currentStep > 0) setState(() => _currentStep--); else Navigator.pop(context); }
  void _onServiceToggled(String id) { setState(() { if (_selectedServiceIds.contains(id)) _selectedServiceIds.remove(id); else _selectedServiceIds.add(id); }); }
  void _onDateSelected(DateTime date) { setState(() => _selectedDate = date); }
  void _onTimeSelected(String time) { setState(() => _selectedTime = time); }
  void _onPromoCodeChanged(String? code) { setState(() => _promoCode = code); }
  void _onNotesChanged(String? notes) { setState(() => _notes = notes); }

  int get _totalDurationMinutes {
    if (_barberDetail == null) return 30;
    return _barberDetail!.services
        .where((s) => _selectedServiceIds.contains(s.id))
        .fold(0, (sum, s) => sum + s.durationInMinutes);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    if (_isLoading) {
      return Scaffold(backgroundColor: context.backgroundColor, body: const Center(child: CircularProgressIndicator(color: AppColors.primary)));
    }

    if (_error != null || _barberDetail == null) {
      return Scaffold(
        backgroundColor: context.backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 16),
              Text(_error ?? 'حدث خطأ', style: AppTextStyles.body(isDark)),
              const SizedBox(height: 16),
              AppButton(label: 'إعادة المحاولة', onPressed: _loadBarberDetail, isSmall: true, width: 160),
            ],
          ),
        ),
      );
    }

    Widget currentStep;
    switch (_currentStep) {
      case 0: currentStep = SelectBarberStep(barberDetail: _barberDetail!, onNext: _nextStep); break;
      case 1: currentStep = SelectEmployeeStep(employees: _barberDetail!.employees, selectedEmployeeId: _selectedEmployeeId, onEmployeeSelected: (id, name) { setState(() { _selectedEmployeeId = id; _selectedEmployeeName = name; _selectedServiceIds.clear(); }); }, onNext: _nextStep); break;
      case 2: currentStep = SelectServiceStep(barberProfileId: widget.barberProfileId, employeeId: _selectedEmployeeId, selectedServiceIds: _selectedServiceIds, onServiceToggled: _onServiceToggled, onNext: _nextStep); break;
      case 3: currentStep = SelectDateStep(selectedDate: _selectedDate, onDateSelected: _onDateSelected, onNext: _nextStep); break;
      case 4: currentStep = SelectTimeStep(barberProfileId: widget.barberProfileId, employeeId: _selectedEmployeeId, selectedDate: _selectedDate!, selectedTime: _selectedTime, durationInMinutes: _totalDurationMinutes, onTimeSelected: _onTimeSelected, onNext: _nextStep); break;
      case 5:
        final selectedServices = _barberDetail!.services.where((s) => _selectedServiceIds.contains(s.id)).toList();
        currentStep = ConfirmBookingStep(barberDetail: _barberDetail!, selectedService: selectedServices.isNotEmpty ? selectedServices.first : _barberDetail!.services.first, selectedServices: selectedServices, selectedDate: _selectedDate!, selectedTime: _selectedTime!, promoCode: _promoCode, notes: _notes, onPromoCodeChanged: _onPromoCodeChanged, onNotesChanged: _onNotesChanged, barberProfileId: widget.barberProfileId, employeeId: _selectedEmployeeId, employeeName: _selectedEmployeeName);
        break;
      default: currentStep = const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isDark),
            _buildStepIndicator(isDark),
            Expanded(child: FadeIn(child: AnimatedSwitcher(duration: const Duration(milliseconds: 300), child: currentStep))),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(onPressed: _prevStep, icon: Icon(Icons.arrow_forward, color: context.textColor)),
          Text('حجز موعد', style: AppTextStyles.subtitle(isDark).copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Row(
        children: List.generate(_stepLabels.length, (index) {
          final isActive = index == _currentStep;
          final isCompleted = index < _currentStep;
          return Expanded(
            child: Row(
              children: [
                Column(
                  children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive || isCompleted ? AppColors.primary : context.surfaceColor,
                        border: Border.all(color: isActive || isCompleted ? AppColors.primary : context.cardBorderColor, width: 2),
                      ),
                      child: Center(
                        child: isCompleted
                            ? Icon(Icons.check, color: context.backgroundColor, size: 16)
                            : Text('${index + 1}', style: TextStyle(color: isActive || isCompleted ? context.backgroundColor : context.hintColor, fontSize: 13, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(_stepLabels[index], style: TextStyle(color: isActive ? AppColors.primary : isCompleted ? context.textColor : context.hintColor, fontSize: 10, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
                  ],
                ),
                if (index < _stepLabels.length - 1) Expanded(child: Container(height: 2, margin: const EdgeInsets.symmetric(horizontal: 4), color: isCompleted ? AppColors.primary : context.cardBorderColor)),
              ],
            ),
          );
        }),
      ),
    );
  }
}
