import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/animations/app_animations.dart';
import '../../../../core/models/barber_registration_data.dart';
import '../../../../core/widgets/app_button.dart';

class BusinessInfoStep extends StatefulWidget {
  final BarberRegistrationData data;
  final VoidCallback onNext;
  final VoidCallback onBack;
  const BusinessInfoStep({super.key, required this.data, required this.onNext, required this.onBack});

  @override
  State<BusinessInfoStep> createState() => _BusinessInfoStepState();
}

class _BusinessInfoStepState extends State<BusinessInfoStep> {
  final _formKey = GlobalKey<FormState>();
  Uint8List? _barberPhotoBytes;
  Uint8List? _shopLogoBytes;
  late final TextEditingController _shopNameController;
  late final TextEditingController _shopDescController;

  @override
  void initState() {
    super.initState();
    _shopNameController = TextEditingController(text: widget.data.shopName);
    _shopDescController = TextEditingController(text: widget.data.shopDescription);
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _shopDescController.dispose();
    super.dispose();
  }

  void _validateAndNext() {
    if (_formKey.currentState!.validate()) {
      widget.onNext();
    }
  }

  Future<void> _pickImage({required bool isBarberPhoto}) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512, maxHeight: 512, imageQuality: 80);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      final base64Str = base64Encode(bytes);
      setState(() {
        if (isBarberPhoto) {
          _barberPhotoBytes = bytes;
          widget.data.barberPhotoBase64 = base64Str;
        } else {
          _shopLogoBytes = bytes;
          widget.data.shopLogoBase64 = base64Str;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            FadeIn(
              delay: const Duration(milliseconds: 0),
              child: Text('هوية المتجر', style: AppTextStyles.headline(isDark)),
            ),
            const SizedBox(height: 8),
            FadeIn(
              delay: const Duration(milliseconds: 50),
              child: Text('ادخل تفاصيل متجرك الأساسية.\nهذه المعلومات ستظهر للعملاء في ملفك الشخصي.', style: AppTextStyles.secondary(isDark)),
            ),
            const SizedBox(height: 28),
            FadeIn(delay: const Duration(milliseconds: 100), child: Text('اسم المتجر', style: AppTextStyles.secondary(isDark))),
            const SizedBox(height: 8),
            FadeIn(
              delay: const Duration(milliseconds: 150),
              child: TextFormField(
                controller: _shopNameController,
                onChanged: (v) => widget.data.shopName = v,
                style: TextStyle(color: context.textColor, fontSize: 14),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'اسم المتجر مطلوب';
                  if (v.trim().length < 2) return 'اسم المتجر يجب أن يكون حرفين على الأقل';
                  return null;
                },
                decoration: InputDecoration(
                  hintText: 'أدخل اسم المتجر (مثلاً، صالة الأناقة)',
                  prefixIcon: const Icon(Icons.store_outlined, size: 20, color: AppColors.primary),
                  filled: true,
                  fillColor: context.surfaceColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.md), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.md), borderSide: BorderSide(color: context.cardBorderColor)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.md), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                  errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.md), borderSide: const BorderSide(color: AppColors.error)),
                  focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.md), borderSide: const BorderSide(color: AppColors.error, width: 2)),
                ),
              ),
            ),
            const SizedBox(height: 20),
            FadeIn(delay: const Duration(milliseconds: 200), child: Text('وصف المتجر', style: AppTextStyles.secondary(isDark))),
            const SizedBox(height: 8),
            FadeIn(
              delay: const Duration(milliseconds: 250),
              child: TextField(
                maxLines: 4,
                maxLength: 250,
                controller: _shopDescController,
                onChanged: (v) => widget.data.shopDescription = v,
                style: TextStyle(color: context.textColor, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'اكتب نبذة مختصرة عن خدماتك ومميزات صالونك...',
                  alignLabelWithHint: true,
                  filled: true,
                  fillColor: context.surfaceColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.md), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.md), borderSide: BorderSide(color: context.cardBorderColor)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.md), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                ),
              ),
            ),
            const SizedBox(height: 20),
            FadeIn(delay: const Duration(milliseconds: 300), child: Text('صورة الحلاق', style: AppTextStyles.secondary(isDark))),
            const SizedBox(height: 8),
            FadeIn(
              delay: const Duration(milliseconds: 350),
              child: _buildImageUpload(icon: Icons.add_photo_alternate_outlined, label: 'انقر للرفع', imageBytes: _barberPhotoBytes, onTap: () => _pickImage(isBarberPhoto: true), isDark: isDark),
            ),
            const SizedBox(height: 20),
            FadeIn(delay: const Duration(milliseconds: 400), child: Text('شعار المتجر (Logo)', style: AppTextStyles.secondary(isDark))),
            const SizedBox(height: 8),
            FadeIn(
              delay: const Duration(milliseconds: 450),
              child: _buildImageUpload(icon: Icons.storefront_outlined, label: 'تحميل الشعار', imageBytes: _shopLogoBytes, onTap: () => _pickImage(isBarberPhoto: false), isDark: isDark),
            ),
            const SizedBox(height: 32),
            FadeIn(
              delay: const Duration(milliseconds: 500),
              child: AppButton(label: 'الحفظ والمتابعة', onPressed: _validateAndNext),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildImageUpload({required IconData icon, required String label, Uint8List? imageBytes, VoidCallback? onTap, bool isDark = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 140,
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          border: Border.all(color: context.cardBorderColor, width: 2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          child: imageBytes != null
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(imageBytes, fit: BoxFit.cover),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.edit, color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: context.hintColor, size: 36),
                    const SizedBox(height: 8),
                    Text(label, style: AppTextStyles.caption(isDark)),
                  ],
                ),
        ),
      ),
    );
  }
}
