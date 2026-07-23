import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/image_helper.dart';
import '../../splash/presentation/splash_screen.dart';
import '../../edit_profile/presentation/edit_profile_screen.dart';
import '../../bookings/presentation/customer_help_support_screen.dart';
import '../../favorites/presentation/favorites_screen.dart';
import '../../my_reviews/presentation/my_reviews_screen.dart';
import '../../barber_dashboard/presentation/barber_notifications_screen.dart';
import '../data/customer_service.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  String? _fullName;
  String? _phoneNumber;
  String? _city;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final tokenStorage = TokenStorage();
    final name = await tokenStorage.getFullName();
    final phone = await tokenStorage.getPhoneNumber();
    final city = await tokenStorage.getCity();

    String? imageUrl;
    try {
      final customerService = CustomerService(ApiClient());
      final profile = await customerService.getProfile();
      imageUrl = profile.profileImageUrl;
    } catch (_) {}

    if (mounted) {
      setState(() {
        _fullName = name;
        _phoneNumber = phone;
        _city = city;
        _profileImageUrl = imageUrl;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              _buildProfileHeader(),
              const SizedBox(height: 16),
              _buildMenuItem(Icons.person_outline, 'الملف الشخصي', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                ).then((_) => _loadProfile());
              }),
              _buildMenuItem(Icons.favorite_outline, 'المفضلة', () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesScreen()));
              }),
              _buildMenuItem(Icons.star_outline, 'تقييماتي', () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const MyReviewsScreen()));
              }),
              _buildMenuItem(Icons.notifications_outlined, 'الإشعارات', () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const BarberNotificationsScreen()));
              }),
              _buildThemeToggle(themeController, isDark),
              _buildMenuItem(Icons.help_outline, 'المساعدة والدعم', () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerHelpSupportScreen()));
              }),
              _buildMenuItem(Icons.info_outline, 'حول التطبيق', () {
                _showAboutDialog(context);
              }),
              const SizedBox(height: 16),
              _buildLogoutButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? AppColors.darkSurfaceLight : AppColors.lightSurfaceVariant,
              border: Border.all(color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
            ),
            child: _buildProfileImage(),
          ),
          const SizedBox(height: 12),
          Text(
            _fullName ?? '',
            style: TextStyle(
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _phoneNumber ?? '',
            style: TextStyle(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              fontSize: 14,
            ),
          ),
          if (_city != null && _city!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on_outlined, color: AppColors.primary, size: 14),
                const SizedBox(width: 4),
                Text(
                  _city!,
                  style: const TextStyle(color: AppColors.primary, fontSize: 13),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileImage() {
    return ImageHelper.displayImage(
      imageUrl: _profileImageUrl,
      width: 80,
      height: 80,
      borderRadius: BorderRadius.circular(40),
      placeholder: const Icon(Icons.person, color: AppColors.textHint, size: 40),
    );
  }

  Widget _buildThemeToggle(ThemeController themeController, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
      ),
      child: ListTile(
        leading: Icon(
          isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
        ),
        title: Text(
          isDark ? 'الوضع الفاتح' : 'الوضع الداكن',
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            fontSize: 15,
          ),
        ),
        trailing: Switch(
          value: !isDark,
          onChanged: (_) => themeController.toggleTheme(),
          activeColor: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            fontSize: 15,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: isDark ? AppColors.darkTextHint : AppColors.lightTextHint,
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: () async {
          final tokenStorage = TokenStorage();
          await tokenStorage.clearAll();
          if (context.mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const SplashScreen()),
              (route) => false,
            );
          }
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: const BorderSide(color: AppColors.error),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text('تسجيل الخروج', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'حول التطبيق',
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'تطبيق حجز الحلاقين',
              style: TextStyle(
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'الإصدار: 1.0.0',
              style: TextStyle(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'تطبيق لحجز مواعيد الحلاقة في فلسطين. ابحث عن أفضل الحلاقين في منطقتك واحجز موعدك بسهولة.',
              style: TextStyle(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسناً', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}
