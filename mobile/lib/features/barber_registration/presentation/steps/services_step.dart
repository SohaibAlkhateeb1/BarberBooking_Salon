import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/animations/app_animations.dart';
import '../../../../core/models/barber_registration_data.dart';
import '../../../../core/widgets/app_button.dart';

class ServicesStep extends StatefulWidget {
  final BarberRegistrationData data;
  final VoidCallback onNext;
  final VoidCallback onBack;
  const ServicesStep({super.key, required this.data, required this.onNext, required this.onBack});

  @override
  State<ServicesStep> createState() => _ServicesStepState();
}

class _ServicesStepState extends State<ServicesStep> {
  final List<String> _quickActions = ['تنظيف بشرة', 'فرد شعر', 'حمام زيت'];

  @override
  void initState() {
    super.initState();
    if (widget.data.services.isEmpty) {
      widget.data.services.addAll([
        BarberService(name: 'حلاقة شعر', price: '50', duration: '30'),
        BarberService(name: 'حلاقة ذقن', price: '25', duration: '15'),
      ]);
    }
  }

  void _addService() {
    setState(() => widget.data.services.add(BarberService(name: '', price: '', duration: '45')));
  }

  void _removeService(int index) {
    setState(() => widget.data.services.removeAt(index));
  }

  void _validateAndNext() {
    if (widget.data.services.isEmpty) {
      _showError('يجب إضافة خدمة واحدة على الأقل');
      return;
    }
    for (int i = 0; i < widget.data.services.length; i++) {
      final s = widget.data.services[i];
      if (s.name.trim().isEmpty) {
        _showError('اسم الخدمة ${i + 1} مطلوب');
        return;
      }
      if (double.tryParse(s.price) == null || double.parse(s.price) <= 0) {
        _showError('سعر الخدمة "${s.name}" غير صحيح');
        return;
      }
      if (int.tryParse(s.duration) == null || int.parse(s.duration) <= 0) {
        _showError('مدة الخدمة "${s.name}" غير صحيحة');
        return;
      }
    }
    widget.onNext();
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, textAlign: TextAlign.center),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
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
            child: Text('ما هي الخدمات التي تقدمها؟', style: AppTextStyles.headline(isDark)),
          ),
          const SizedBox(height: 8),
          FadeIn(
            delay: const Duration(milliseconds: 50),
            child: Text('قم بترتيب الخدمات التيقدمها مع السعر والمدة الزمنية.', style: AppTextStyles.secondary(isDark)),
          ),
          const SizedBox(height: 20),
          ...List.generate(widget.data.services.length, (index) => FadeIn(
            delay: Duration(milliseconds: 100 + index * 80),
            child: _buildServiceCard(index, isDark),
          )),
          const SizedBox(height: 16),
          FadeIn(delay: const Duration(milliseconds: 200), child: Text('اقتراحات سريعة', style: AppTextStyles.caption(isDark))),
          const SizedBox(height: 10),
          FadeIn(
            delay: const Duration(milliseconds: 250),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _quickActions.map((action) {
                return GestureDetector(
                  onTap: () => setState(() => widget.data.services.add(BarberService(name: action, price: '', duration: '30'))),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(color: context.surfaceColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: context.cardBorderColor)),
                    child: Text('+ $action', style: TextStyle(color: context.textColor, fontSize: 13)),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          FadeIn(
            delay: const Duration(milliseconds: 300),
            child: GestureDetector(
              onTap: _addService,
              child: Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(AppBorderRadius.md)),
                child: Icon(Icons.add, color: context.backgroundColor, size: 28),
              ),
            ),
          ),
          const SizedBox(height: 24),
          FadeIn(
            delay: const Duration(milliseconds: 350),
            child: AppButton(label: 'الحفظ والمتابعة', onPressed: _validateAndNext),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildServiceCard(int index, bool isDark) {
    final service = widget.data.services[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: context.surfaceColor, borderRadius: BorderRadius.circular(AppBorderRadius.lg), border: Border.all(color: context.cardBorderColor)),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => _removeService(index),
                child: const Icon(Icons.delete_outline, color: AppColors.error, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: TextEditingController(text: service.name),
                  onChanged: (v) => service.name = v,
                  style: TextStyle(color: context.textColor),
                  decoration: InputDecoration(
                    hintText: 'اسم الخدمة',
                    hintStyle: TextStyle(color: context.hintColor),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.sm), borderSide: BorderSide(color: context.cardBorderColor)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.sm), borderSide: BorderSide(color: context.cardBorderColor)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.sm), borderSide: const BorderSide(color: AppColors.primary)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: TextEditingController(text: service.price),
                  onChanged: (v) => service.price = v,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    hintText: 'السعر', suffixText: 'ش',
                    hintStyle: TextStyle(color: context.hintColor),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.sm), borderSide: BorderSide(color: context.cardBorderColor)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.sm), borderSide: BorderSide(color: context.cardBorderColor)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.sm), borderSide: const BorderSide(color: AppColors.primary)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: TextEditingController(text: service.duration),
                  onChanged: (v) => service.duration = v,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: context.textColor),
                  decoration: InputDecoration(
                    hintText: 'المدة', suffixText: 'دقيقة',
                    hintStyle: TextStyle(color: context.hintColor),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.sm), borderSide: BorderSide(color: context.cardBorderColor)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.sm), borderSide: BorderSide(color: context.cardBorderColor)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.sm), borderSide: const BorderSide(color: AppColors.primary)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
