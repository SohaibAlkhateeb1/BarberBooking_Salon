import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/animations/app_animations.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../home/data/barbers_service.dart';

class SelectEmployeeStep extends StatelessWidget {
  final List<EmployeeModel> employees;
  final String? selectedEmployeeId;
  final void Function(String id, String name) onEmployeeSelected;
  final VoidCallback onNext;

  const SelectEmployeeStep({super.key, required this.employees, this.selectedEmployeeId, required this.onEmployeeSelected, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                FadeIn(child: Text('اختر الموظف', style: AppTextStyles.headline(isDark))),
                const SizedBox(height: 4),
                FadeIn(delay: const Duration(milliseconds: 100), child: Text('اختر الموظف الذي تريد الحجز معه', style: AppTextStyles.secondary(isDark))),
                const SizedBox(height: 20),
                if (employees.isEmpty) _buildNoEmployees(context, isDark)
                else ...List.generate(employees.length, (index) {
                  final employee = employees[index];
                  final isSelected = employee.id == selectedEmployeeId;
                  return FadeIn(delay: Duration(milliseconds: 100 * (index + 1)), child: Padding(padding: const EdgeInsets.only(bottom: 12), child: _buildEmployeeCard(context, employee, isSelected, isDark)));
                }),
                const SizedBox(height: 20),
                _buildOwnerOption(context, isDark),
              ],
            ),
          ),
        ),
        _buildBottomButton(context, isDark),
      ],
    );
  }

  Widget _buildNoEmployees(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: context.surfaceColor, borderRadius: BorderRadius.circular(AppBorderRadius.md), border: Border.all(color: context.cardBorderColor)),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.people_outline, color: context.hintColor, size: 48),
            const SizedBox(height: 12),
            Text('لا يوجد موظفين حالياً', style: AppTextStyles.secondary(isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildOwnerOption(BuildContext context, bool isDark) {
    final isSelected = selectedEmployeeId == null;
    return FadeIn(
      delay: const Duration(milliseconds: 500),
      child: GestureDetector(
        onTap: () { HapticFeedback.lightImpact(); onEmployeeSelected('', 'صاحب الصالون'); },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : context.surfaceColor,
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
            border: Border.all(color: isSelected ? AppColors.primary : context.cardBorderColor, width: isSelected ? 2 : 1),
          ),
          child: Row(
            children: [
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(color: isSelected ? AppColors.primary.withValues(alpha: 0.2) : context.surfaceColor, borderRadius: BorderRadius.circular(AppBorderRadius.md)),
                child: Icon(Icons.store, color: isSelected ? AppColors.primary : context.textSecondaryColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('صاحب الصالون', style: AppTextStyles.bodyMedium(isDark).copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('الحجز مع صاحب الصالون مباشرة', style: AppTextStyles.caption(isDark)),
                  ],
                ),
              ),
              if (isSelected) const Icon(Icons.check_circle, color: AppColors.primary, size: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmployeeCard(BuildContext context, EmployeeModel employee, bool isSelected, bool isDark) {
    return GestureDetector(
      onTap: () { HapticFeedback.lightImpact(); onEmployeeSelected(employee.id, employee.name); },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : context.surfaceColor,
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          border: Border.all(color: isSelected ? AppColors.primary : context.cardBorderColor, width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(color: isSelected ? AppColors.primary.withValues(alpha: 0.2) : context.surfaceColor, borderRadius: BorderRadius.circular(AppBorderRadius.md)),
              child: Icon(Icons.person, color: isSelected ? AppColors.primary : context.textSecondaryColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(employee.name, style: AppTextStyles.bodyMedium(isDark).copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(employee.phoneNumber, style: AppTextStyles.caption(isDark)),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle, color: AppColors.primary, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButton(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
      decoration: BoxDecoration(color: context.surfaceColor, border: Border(top: BorderSide(color: context.cardBorderColor))),
      child: SafeArea(top: false, child: AppButton(label: 'متابعة', onPressed: onNext)),
    );
  }
}
