import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/animations/app_animations.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/platform_url.dart';
import '../data/barber_dashboard_service.dart';

class BarberEditProfileScreen extends StatefulWidget {
  const BarberEditProfileScreen({super.key});

  @override
  State<BarberEditProfileScreen> createState() => _BarberEditProfileScreenState();
}

class _BarberEditProfileScreenState extends State<BarberEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = BarberDashboardService(ApiClient());
  final _shopNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _instagramController = TextEditingController();
  final _tiktokController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  String? _selectedCity;
  List<Map<String, dynamic>> _workingHours = [];
  bool _loadingSchedule = true;

  String? _profileImageUrl;
  String? _coverImageUrl;
  Uint8List? _selectedProfileBytes;
  Uint8List? _selectedCoverBytes;

  static const List<String> _palestinianCities = [
    'رام الله', 'بيت لحم', 'نابلس', 'الخليل', 'جنين',
    'غزة', 'طولكرم', 'قلقيلية', 'سلفيت', 'oberit', 'أريحا', 'القدس',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadSchedule();
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _ownerNameController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _instagramController.dispose();
    _tiktokController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final profile = await _service.getProfileInfo();
      if (mounted) {
        setState(() {
          _shopNameController.text = profile.shopName;
          _ownerNameController.text = profile.ownerName;
          _descriptionController.text = profile.shopDescription ?? '';
          _phoneController.text = profile.phoneNumber;
          _whatsappController.text = profile.whatsappNumber ?? '';
          _emailController.text = profile.email ?? '';
          _addressController.text = profile.address;
          _instagramController.text = profile.instagramHandle ?? '';
          _tiktokController.text = profile.tiktokHandle ?? '';
          _selectedCity = profile.city;
          _profileImageUrl = profile.profileImageUrl;
          _coverImageUrl = profile.coverImageUrl;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = 'حدث خطأ أثناء تحميل البيانات'; _isLoading = false; });
    }
  }

  Future<void> _pickImage(String type) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Text('اختر مصدر الصورة', style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _buildImageOption(isDark, icon: Icons.camera_alt_outlined, title: 'الكاميرا', onTap: () => _processImage(ImageSource.camera, type)),
              const SizedBox(height: 8),
              _buildImageOption(isDark, icon: Icons.photo_library_outlined, title: 'المعرض', onTap: () => _processImage(ImageSource.gallery, type)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageOption(bool isDark, {required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 24),
      title: Text(title, style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary, fontSize: 16)),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Future<void> _processImage(ImageSource source, String type) async {
    Navigator.pop(context);
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(source: source, maxWidth: 1024, maxHeight: 1024, imageQuality: 80);
      if (pickedFile != null) {
          final bytes = await pickedFile.readAsBytes();
          setState(() {
            if (type == 'profile') { _selectedProfileBytes = bytes; }
            else if (type == 'cover') { _selectedCoverBytes = bytes; }
          });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      String? newProfileUrl = _profileImageUrl;
      String? newCoverUrl = _coverImageUrl;

      if (_selectedProfileBytes != null) {
        final urls = await _service.uploadImage(base64Encode(_selectedProfileBytes!), 'profile');
        newProfileUrl = urls['profileImageUrl'];
      }

      if (_selectedCoverBytes != null) {
        final urls = await _service.uploadImage(base64Encode(_selectedCoverBytes!), 'cover');
        newCoverUrl = urls['coverImageUrl'];
      }

      await _service.updateProfileInfo(
        shopName: _shopNameController.text.trim(),
        shopDescription: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        city: _selectedCity,
        address: _addressController.text.trim(),
        whatsappNumber: _whatsappController.text.trim().isEmpty ? null : _whatsappController.text.trim(),
        instagramHandle: _instagramController.text.trim().isEmpty ? null : _instagramController.text.trim(),
        tiktokHandle: _tiktokController.text.trim().isEmpty ? null : _tiktokController.text.trim(),
        ownerName: _ownerNameController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        profileImageUrl: newProfileUrl,
        coverImageUrl: newCoverUrl,
      );

      if (_workingHours.isNotEmpty) {
        await _service.updateSchedule(_workingHours);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث الملف الشخصي بنجاح'), backgroundColor: AppColors.success),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: ${e.toString()}'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('تعديل الملف الشخصي', style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary, size: 22),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.arrow_forward_ios, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ],
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
          Text(_error!, style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary, fontSize: 15)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadProfile,
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة المحاولة'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeIn(
              delay: const Duration(milliseconds: 100),
              child: _buildCoverSection(isDark),
            ),
            const SizedBox(height: 40),
            FadeIn(
              delay: const Duration(milliseconds: 200),
              child: _buildAvatarSection(),
            ),
            const SizedBox(height: 24),
            FadeIn(
              delay: const Duration(milliseconds: 250),
              child: _buildSectionTitle('معلومات العمل'),
            ),
            const SizedBox(height: 12),
            FadeIn(
              delay: const Duration(milliseconds: 300),
              child: _buildTextField(isDark, controller: _shopNameController, label: 'اسم الصالون', icon: Icons.store_outlined,
                validator: (v) => v == null || v.trim().isEmpty ? 'اسم الصالون مطلوب' : null),
            ),
            const SizedBox(height: 12),
            FadeIn(
              delay: const Duration(milliseconds: 350),
              child: _buildTextField(isDark, controller: _ownerNameController, label: 'اسم المالك', icon: Icons.person_outline,
                validator: (v) => v == null || v.trim().isEmpty ? 'اسم المالك مطلوب' : null),
            ),
            const SizedBox(height: 12),
            FadeIn(
              delay: const Duration(milliseconds: 400),
              child: _buildTextField(isDark, controller: _descriptionController, label: 'وصف الصالون', icon: Icons.description_outlined, maxLines: 3),
            ),
            const SizedBox(height: 24),
            FadeIn(
              delay: const Duration(milliseconds: 450),
              child: _buildSectionTitle('معلومات التواصل'),
            ),
            const SizedBox(height: 12),
            FadeIn(
              delay: const Duration(milliseconds: 500),
              child: _buildTextField(isDark, controller: _phoneController, label: 'رقم الهاتف', icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
            ),
            const SizedBox(height: 12),
            FadeIn(
              delay: const Duration(milliseconds: 550),
              child: _buildTextField(isDark, controller: _whatsappController, label: 'رقم واتساب', icon: Icons.chat_outlined, keyboardType: TextInputType.phone),
            ),
            const SizedBox(height: 12),
            FadeIn(
              delay: const Duration(milliseconds: 600),
              child: _buildTextField(isDark, controller: _emailController, label: 'البريد الإلكتروني', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
            ),
            const SizedBox(height: 24),
            FadeIn(
              delay: const Duration(milliseconds: 650),
              child: _buildSectionTitle('الموقع'),
            ),
            const SizedBox(height: 12),
            FadeIn(
              delay: const Duration(milliseconds: 700),
              child: _buildCityDropdown(isDark),
            ),
            const SizedBox(height: 12),
            FadeIn(
              delay: const Duration(milliseconds: 750),
              child: _buildTextField(isDark, controller: _addressController, label: 'العنوان', icon: Icons.location_on_outlined),
            ),
            const SizedBox(height: 24),
            FadeIn(
              delay: const Duration(milliseconds: 800),
              child: _buildSectionTitle('حسابات التواصل الاجتماعي'),
            ),
            const SizedBox(height: 12),
            FadeIn(
              delay: const Duration(milliseconds: 850),
              child: _buildTextField(isDark, controller: _instagramController, label: 'إنستغرام', icon: Icons.camera_alt_outlined),
            ),
            const SizedBox(height: 12),
            FadeIn(
              delay: const Duration(milliseconds: 900),
              child: _buildTextField(isDark, controller: _tiktokController, label: 'تيك توك', icon: Icons.music_note_outlined),
            ),
            const SizedBox(height: 24),
            FadeIn(
              delay: const Duration(milliseconds: 950),
              child: _buildSectionTitle('ساعات الدوام'),
            ),
            const SizedBox(height: 12),
            FadeIn(
              delay: const Duration(milliseconds: 1000),
              child: _buildWorkingHoursSection(isDark),
            ),
            const SizedBox(height: 32),
            FadeIn(
              delay: const Duration(milliseconds: 1050),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        side: BorderSide(color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('إلغاء', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isSaving
                          ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: isDark ? AppColors.darkBackground : AppColors.lightBackground, strokeWidth: 2))
                          : const Text('حفظ التغييرات', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverSection(bool isDark) {
    return GestureDetector(
      onTap: () => _pickImage('cover'),
      child: Container(
        height: 140,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isDark ? AppColors.darkSurfaceLight : AppColors.lightSurfaceVariant,
          border: Border.all(color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: _buildCoverContent(isDark),
        ),
      ),
    );
  }

  Widget _buildCoverContent(bool isDark) {
    if (_selectedCoverBytes != null) {
      return Image.memory(_selectedCoverBytes!, fit: BoxFit.cover);
    }
    if (_coverImageUrl != null && _coverImageUrl!.isNotEmpty) {
      if (_coverImageUrl!.startsWith('/uploads/') || _coverImageUrl!.startsWith('http')) {
        final url = _coverImageUrl!.startsWith('http')
            ? _coverImageUrl!
            : '${_getBaseUrl()}${_coverImageUrl!}';
        return Image.network(url, fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Center(child: Icon(Icons.broken_image, color: isDark ? AppColors.darkTextHint : AppColors.lightTextHint, size: 32)),
        );
      }
      try {
        String b64 = _coverImageUrl!;
        if (b64.startsWith('data:')) b64 = b64.split(',')[1];
        return Image.memory(base64Decode(b64), fit: BoxFit.cover);
      } catch (_) {}
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.camera_alt_outlined, color: (isDark ? AppColors.darkTextHint : AppColors.lightTextHint).withValues(alpha: 0.5), size: 32),
          const SizedBox(height: 8),
          Text('إضافة صورة غلاف', style: TextStyle(color: isDark ? AppColors.darkTextHint : AppColors.lightTextHint, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Center(
      child: GestureDetector(
        onTap: () => _pickImage('profile'),
        child: Stack(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.15),
                border: Border.all(color: AppColors.primary, width: 3),
              ),
              child: _buildAvatarContent(),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarContent() {
    if (_selectedProfileBytes != null) {
      return ClipOval(child: Image.memory(_selectedProfileBytes!, width: 100, height: 100, fit: BoxFit.cover));
    }
    if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
      if (_profileImageUrl!.startsWith('/uploads/') || _profileImageUrl!.startsWith('http')) {
        final url = _profileImageUrl!.startsWith('http')
            ? _profileImageUrl!
            : '${_getBaseUrl()}${_profileImageUrl!}';
        return ClipOval(child: Image.network(url, width: 100, height: 100, fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: AppColors.primary, size: 40),
        ));
      }
      try {
        String b64 = _profileImageUrl!;
        if (b64.startsWith('data:')) b64 = b64.split(',')[1];
        return ClipOval(child: Image.memory(base64Decode(b64), width: 100, height: 100, fit: BoxFit.cover));
      } catch (_) {}
    }
    return const Icon(Icons.content_cut, color: Colors.white, size: 40);
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.bold));
  }

  Widget _buildTextField(
    bool isDark, {
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary, fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: isDark ? AppColors.darkTextHint : AppColors.lightTextHint, fontSize: 14),
          prefixIcon: Icon(icon, color: isDark ? AppColors.darkTextHint : AppColors.lightTextHint, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          errorStyle: const TextStyle(color: AppColors.error, fontSize: 12),
        ),
      ),
    );
  }

  String _getBaseUrl() => getApiBaseUrl();

  Widget _buildCityDropdown(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedCity,
        hint: Text('اختر المدينة', style: TextStyle(color: isDark ? AppColors.darkTextHint : AppColors.lightTextHint, fontSize: 14)),
        icon: Icon(Icons.keyboard_arrow_down, color: isDark ? AppColors.darkTextHint : AppColors.lightTextHint),
        dropdownColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary, fontSize: 15),
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.location_on_outlined, color: isDark ? AppColors.darkTextHint : AppColors.lightTextHint, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        items: _palestinianCities.map((city) => DropdownMenuItem(value: city, child: Text(city))).toList(),
        onChanged: (value) => setState(() => _selectedCity = value),
      ),
    );
  }

  Future<void> _loadSchedule() async {
    try {
      final schedule = await _service.getSchedule();
      if (mounted) {
        setState(() {
          _workingHours = schedule.map((wh) => ({
            'dayName': wh.dayName,
            'isOpen': wh.isOpen,
            'openTime': wh.openTime,
            'closeTime': wh.closeTime,
          })).toList();
          _loadingSchedule = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingSchedule = false);
    }
  }

  Widget _buildWorkingHoursSection(bool isDark) {
    if (_loadingSchedule) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_workingHours.isEmpty) {
      return Text('لا توجد ساعات دوام', style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary));
    }
    return Column(
      children: _workingHours.map((wh) => _buildWorkingHourItem(wh, isDark)).toList(),
    );
  }

  Widget _buildWorkingHourItem(Map<String, dynamic> wh, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(wh['dayName'] ?? '', style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
          ),
          Switch(
            value: wh['isOpen'] ?? false,
            onChanged: (val) => setState(() => wh['isOpen'] = val),
            activeColor: AppColors.primary,
          ),
          if (wh['isOpen']) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _pickTime(wh, true),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceLight : AppColors.lightSurfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(wh['openTime'] ?? '09:00', style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary, fontSize: 12)),
              ),
            ),
            Text(' - ', style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
            GestureDetector(
              onTap: () => _pickTime(wh, false),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceLight : AppColors.lightSurfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(wh['closeTime'] ?? '21:00', style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary, fontSize: 12)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickTime(Map<String, dynamic> wh, bool isOpen) async {
    final parts = (isOpen ? wh['openTime'] : wh['closeTime'] ?? '21:00').split(':');
    final initial = TimeOfDay(hour: int.tryParse(parts[0]) ?? (isOpen ? 9 : 21), minute: parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0);
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      final timeStr = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() {
        if (isOpen) {
          wh['openTime'] = timeStr;
        } else {
          wh['closeTime'] = timeStr;
        }
      });
    }
  }
}
