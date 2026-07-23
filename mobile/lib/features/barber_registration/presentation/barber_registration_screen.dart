import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/animations/app_animations.dart';
import '../../../core/models/barber_registration_data.dart';
import 'steps/basic_info_step.dart';
import 'steps/business_info_step.dart';
import 'steps/location_step.dart';
import 'steps/services_step.dart';
import 'steps/working_hours_step.dart';
import 'steps/pricing_plan_step.dart';

class BarberRegistrationScreen extends StatefulWidget {
  const BarberRegistrationScreen({super.key});

  @override
  State<BarberRegistrationScreen> createState() => _BarberRegistrationScreenState();
}

class _BarberRegistrationScreenState extends State<BarberRegistrationScreen> {
  int _currentStep = 0;
  final BarberRegistrationData _data = BarberRegistrationData();

  final List<String> _stepLabels = ['الأساسيات', 'النوعية', 'الموقع', 'الخدمات', 'أوقات'];

  late final List<Widget> _steps;

  @override
  void initState() {
    super.initState();
    _steps = [
      BasicInfoStep(data: _data, onNext: _nextStep),
      BusinessInfoStep(data: _data, onNext: _nextStep, onBack: _prevStep),
      LocationStep(data: _data, onNext: _nextStep, onBack: _prevStep),
      ServicesStep(data: _data, onNext: _nextStep, onBack: _prevStep),
      WorkingHoursStep(data: _data, onNext: _nextStep, onBack: _prevStep),
    ];
  }

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      setState(() => _currentStep++);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => PricingPlanStep(data: _data)),
      );
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      Navigator.pop(context);
    }
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
                  IconButton(
                    onPressed: _prevStep,
                    icon: Icon(Icons.arrow_forward, color: context.textColor),
                  ),
                  Text('تسجيل الحلاق', style: AppTextStyles.subtitle(isDark).copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            Padding(
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
                            FadeIn(
                              delay: Duration(milliseconds: index * 80),
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isActive || isCompleted ? AppColors.primary : context.surfaceColor,
                                  border: Border.all(
                                    color: isActive || isCompleted ? AppColors.primary : context.cardBorderColor,
                                    width: 2,
                                  ),
                                ),
                                child: Center(
                                  child: isCompleted
                                      ? Icon(Icons.check, color: context.backgroundColor, size: 16)
                                      : Text(
                                          '${index + 1}',
                                          style: TextStyle(
                                            color: isActive || isCompleted ? context.backgroundColor : context.hintColor,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _stepLabels[index],
                              style: TextStyle(
                                color: isActive ? AppColors.primary : isCompleted ? context.textColor : context.hintColor,
                                fontSize: 10,
                                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                        if (index < _stepLabels.length - 1)
                          Expanded(
                            child: Container(
                              height: 2,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              color: isCompleted ? AppColors.primary : context.cardBorderColor,
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _steps[_currentStep],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
