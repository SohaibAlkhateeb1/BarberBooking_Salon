import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_responsive.dart';
import '../../../core/animations/app_animations.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/image_helper.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/widgets/app_button.dart';
import '../../account/data/customer_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _customerService = CustomerService(ApiClient());
  final ImagePicker _imagePicker = ImagePicker();

  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;
  String? _selectedCity;
  String? _profileImageUrl;
  Uint8List? _selectedImageBytes;

  static const List<String> _palestinianCities = [
    'رام الله', 'بيت لحم', 'نابلس', 'الخليل', 'جنين', 'غزة',
    'طولكرم', 'قلقيلية', 'سلفيت', 'oberit', 'أريحا', 'القدس',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final profile = await _customerService.getProfile();
      setState(() {
        _nameController.text = profile.fullName;
        _phoneController.text = profile.phoneNumber;
        _emailController.text = profile.email ?? '';
        _selectedCity = profile.city;
        _profileImageUrl = profile.profileImageUrl;
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _error = 'حدث خطأ أثناء تحميل البيانات'; _isLoading = false; });
    }
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.surfaceColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: context.cardBorderColor, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Text('اختر مصدر الصورة', style: AppTextStyles.subtitle(context.isDark)),
              const SizedBox(height: 20),
              _buildImageOption(icon: Icons.camera_alt_outlined, title: 'الكاميرا', onTap: () => _pickAndProcessImage(ImageSource.camera)),
              const SizedBox(height: 8),
              _buildImageOption(icon: Icons.photo_library_outlined, title: 'المعرض', onTap: () => _pickAndProcessImage(ImageSource.gallery)),
              const SizedBox(height: 8),
              if (_profileImageUrl != null || _selectedImageBytes != null)
                _buildImageOption(icon: Icons.delete_outline, title: 'إزالة الصورة', color: AppColors.error, onTap: () {
                  setState(() { _selectedImageBytes = null; _profileImageUrl = null; });
                  Navigator.pop(context);
                }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageOption({required IconData icon, required String title, required VoidCallback onTap, Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.primary, size: 24),
      title: Text(title, style: TextStyle(color: color ?? context.textColor, fontSize: 16)),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppBorderRadius.md)),
    );
  }

  Future<void> _pickAndProcessImage(ImageSource source) async {
    Navigator.pop(context);
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(source: source, maxWidth: 512, maxHeight: 512, imageQuality: 80);
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() { _selectedImageBytes = bytes; });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: AppColors.error));
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      String? imageUrl = _profileImageUrl;

      if (_selectedImageBytes != null) {
        final base64Image = base64Encode(_selectedImageBytes!);
        imageUrl = await _customerService.uploadImage(base64Image);
      }

      await _customerService.updateProfile(
        fullName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        profileImageUrl: imageUrl,
        city: _selectedCity,
      );

      final tokenStorage = TokenStorage();
      await tokenStorage.saveFullName(_nameController.text.trim());
      await tokenStorage.savePhoneNumber(_phoneController.text.trim());
      if (_selectedCity != null) await tokenStorage.saveCity(_selectedCity!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديث الملف الشخصي بنجاح'), backgroundColor: AppColors.success));
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ: ${e.toString()}'), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        backgroundColor: context.backgroundColor,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back_ios_new, color: context.textColor, size: 20), onPressed: () => Navigator.pop(context)),
        title: Text('تعديل الملف الشخصي', style: AppTextStyles.subtitle(isDark).copyWith(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _buildErrorState(isDark)
              : _buildForm(isDark),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 48),
          const SizedBox(height: 16),
          Text(_error!, style: AppTextStyles.secondary(isDark)),
          const SizedBox(height: 16),
          AppButton(label: 'إعادة المحاولة', icon: Icons.refresh, onPressed: _loadProfile, isSmall: true, width: 180),
        ],
      ),
    );
  }

  Widget _buildForm(bool isDark) {
    return KeyboardDismiss(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
        key: _formKey,
        child: Column(
          children: [
            FadeIn(child: _buildAvatar(isDark)),
            const SizedBox(height: 24),
            FadeIn(child: _buildTextField(
              controller: _nameController,
              label: 'الاسم الكامل',
              icon: Icons.person_outline,
              isDark: isDark,
              validator: (value) { if (value == null || value.trim().isEmpty) return 'الاسم مطلوب'; return null; },
            )),
            const SizedBox(height: 16),
            FadeIn(child: _buildTextField(
              controller: _phoneController,
              label: 'رقم الجوال',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              isDark: isDark,
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'رقم الجوال مطلوب';
                if (value.trim().length < 9) return 'رقم الجوال غير صحيح';
                return null;
              },
            )),
            const SizedBox(height: 16),
            FadeIn(child: _buildTextField(
              controller: _emailController,
              label: 'البريد الإلكتروني (اختياري)',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              isDark: isDark,
            )),
            const SizedBox(height: 16),
            FadeIn(child: _buildCityDropdown(isDark)),
            const SizedBox(height: 32),
            FadeIn(child: AppButton(
              label: 'حفظ التغييرات',
              isLoading: _isSaving,
              onPressed: _isSaving ? null : _saveProfile,
            )),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildAvatar(bool isDark) {
    return GestureDetector(
      onTap: _pickImage,
      child: Stack(
        children: [
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.surfaceColor,
              border: Border.all(color: context.cardBorderColor, width: 2),
              image: _buildAvatarImage(),
            ),
            child: _buildAvatarContent(isDark),
          ),
          Positioned(
            bottom: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  DecorationImage? _buildAvatarImage() {
    if (_selectedImageBytes != null) return DecorationImage(image: MemoryImage(_selectedImageBytes!), fit: BoxFit.cover);
    final provider = ImageHelper.getImageProvider(_profileImageUrl);
    if (provider != null) return DecorationImage(image: provider, fit: BoxFit.cover);
    return null;
  }

  Widget _buildAvatarContent(bool isDark) {
    if (_selectedImageBytes != null || (_profileImageUrl != null && _profileImageUrl!.isNotEmpty)) return const SizedBox.shrink();
    return Icon(Icons.person, color: context.hintColor, size: 50);
  }

  Widget _buildCityDropdown(bool isDark) {
    return Container(
      decoration: BoxDecoration(color: context.surfaceColor, borderRadius: BorderRadius.circular(AppBorderRadius.md), border: Border.all(color: context.cardBorderColor)),
      child: DropdownButtonFormField<String>(
        value: _selectedCity,
        hint: Text('اختر مدينتك', style: TextStyle(color: context.hintColor, fontSize: 14)),
        icon: Icon(Icons.keyboard_arrow_down, color: context.hintColor),
        dropdownColor: context.surfaceColor,
        style: TextStyle(color: context.textColor, fontSize: 15),
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.location_on_outlined, color: context.hintColor, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        items: _palestinianCities.map((city) => DropdownMenuItem(value: city, child: Text(city))).toList(),
        onChanged: (value) => setState(() => _selectedCity = value),
        validator: (value) { if (value == null || value.isEmpty) return 'المدينة مطلوبة'; return null; },
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(color: context.surfaceColor, borderRadius: BorderRadius.circular(AppBorderRadius.md), border: Border.all(color: context.cardBorderColor)),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        style: TextStyle(color: context.textColor, fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: context.hintColor, fontSize: 14),
          prefixIcon: Icon(icon, color: context.hintColor, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          errorStyle: const TextStyle(color: AppColors.error, fontSize: 12),
        ),
      ),
    );
  }
}
