import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/platform_url.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/widgets/widgets.dart';
import '../../../core/animations/app_animations.dart';
import '../../splash/presentation/splash_screen.dart';
import '../data/barber_dashboard_service.dart';
import 'barber_edit_profile_screen.dart';
import 'barber_help_support_screen.dart';
import 'barber_my_reviews_screen.dart';
import 'barber_notifications_screen.dart';
import 'barber_portfolio_screen.dart';
import 'barber_subscription_screen.dart';
import 'team_management_screen.dart';
import 'analytics_screen.dart';
import 'plan_selection_screen.dart';
import 'blocked_customers_screen.dart';

class BarberAccountScreen extends StatefulWidget {
  const BarberAccountScreen({super.key});

  @override
  State<BarberAccountScreen> createState() => _BarberAccountScreenState();
}

class _BarberAccountScreenState extends State<BarberAccountScreen> {
  final BarberDashboardService _service = BarberDashboardService(ApiClient());
  BarberProfileInfoModel? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final profile = await _service.getProfileInfo();
      if (mounted) setState(() { _profile = profile; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: _isLoading
            ? _buildLoadingSkeleton()
            : _profile == null
                ? ErrorState(
                    message: 'حدث خطأ أثناء تحميل البيانات',
                    onRetry: _loadProfile,
                  )
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildCoverAndProfile(isDark),
                        const SizedBox(height: 8),
                        ..._buildMenuItems(isDark),
                        const SizedBox(height: 16),
                        _buildLogoutButton(context, isDark),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return SingleChildScrollView(
      child: Column(
        children: [
          SkeletonCard(),
          ...List.generate(8, (_) => SkeletonListTile()),
        ],
      ),
    );
  }

  List<Widget> _buildMenuItems(bool isDark) {
    final themeController = Get.find<ThemeController>();
    final items = [
      (Icons.edit_outlined, 'تعديل المعلومات الشخصية', () async {
        final result = await Navigator.push(context,
          MaterialPageRoute(builder: (_) => const BarberEditProfileScreen()));
        if (result == true) _loadProfile();
      }),
      (Icons.photo_library_outlined, 'أعمالي', () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const BarberPortfolioScreen()));
      }),
      (Icons.access_time, 'ساعات الدوام', () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const BarberEditProfileScreen()));
      }),
      (Icons.notifications_outlined, 'الإشعارات', () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const BarberNotificationsScreen()));
      }),
      (Icons.card_membership_outlined, 'اشتراكي', () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const BarberSubscriptionScreen()));
      }),
      (Icons.swap_horiz, 'تغيير الخطة', () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const PlanSelectionScreen()));
      }),
      (Icons.people_outline, 'إدارة الفريق', () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const TeamManagementScreen()));
      }),
      (Icons.analytics_outlined, 'التحليلات', () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const AnalyticsScreen()));
      }),
      (Icons.person_off_outlined, 'المحظورون', () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const BlockedCustomersScreen()));
      }),
      (Icons.star_outline, 'تقييماتي', () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const BarberMyReviewsScreen()));
      }),
      (Icons.help_outline, 'المساعدة والدعم', () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const BarberHelpSupportScreen()));
      }),
      (Icons.info_outline, 'حول التطبيق', () {
        _showAboutDialog(context, isDark);
      }),
    ];

    return [
      ...List.generate(items.length, (index) {
        final (icon, title, onTap) = items[index];
        return FadeIn(
          delay: Duration(milliseconds: 50 * index),
          child: _buildMenuItem(icon, title, onTap, isDark),
        );
      }),
      FadeIn(
        delay: Duration(milliseconds: 50 * items.length),
        child: _buildThemeToggle(themeController, isDark),
      ),
    ];
  }

  Widget _buildCoverAndProfile(bool isDark) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        border: Border(bottom: BorderSide(color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder)),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.3),
                      AppColors.primaryDark.withValues(alpha: 0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: _buildCoverImage(),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.notifications_outlined, color: isDark ? AppColors.darkBackground : AppColors.lightBackground, size: 20),
                ),
              ),
            ],
          ),
          Transform.translate(
            offset: const Offset(0, -40),
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark ? AppColors.darkSurfaceLight : AppColors.lightSurfaceVariant,
                        border: Border.all(color: AppColors.primary, width: 3),
                      ),
                      child: _buildProfileImage(),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.camera_alt, color: isDark ? AppColors.darkBackground : AppColors.lightBackground, size: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _profile?.shopName ?? '',
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _profile?.ownerName ?? '',
                  style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary, fontSize: 14),
                ),
                if (_profile?.shopDescription != null && _profile!.shopDescription!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      _profile!.shopDescription!,
                      style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary, fontSize: 13),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.phone, color: isDark ? AppColors.darkTextHint : AppColors.lightTextHint, size: 16),
                    const SizedBox(width: 6),
                    Text(_profile?.phoneNumber ?? '', style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.location_on_outlined, color: AppColors.primary, size: 16),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '${_profile?.city ?? ''} - ${_profile?.address ?? ''}',
                        style: const TextStyle(color: AppColors.primary, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _getBaseUrl() => getApiBaseUrl();

  Widget _buildCoverImage() {
    if (_profile?.coverImageUrl != null && _profile!.coverImageUrl!.isNotEmpty) {
      final imageUrl = _profile!.coverImageUrl!;
      if (imageUrl.startsWith('http') || imageUrl.startsWith('/uploads/')) {
        final fullUrl = imageUrl.startsWith('http') ? imageUrl : '${_getBaseUrl()}$imageUrl';
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
          child: Image.network(fullUrl, width: double.infinity, height: 140, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox(height: 140),
          ),
        );
      }
      try {
        String base64Str = imageUrl;
        if (base64Str.startsWith('data:')) base64Str = base64Str.split(',')[1];
        final imageBytes = base64Decode(base64Str);
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
          child: Image.memory(imageBytes, width: double.infinity, height: 140, fit: BoxFit.cover),
        );
      } catch (_) {}
    }
    return const SizedBox(height: 140);
  }

  Widget _buildProfileImage() {
    if (_profile?.profileImageUrl != null && _profile!.profileImageUrl!.isNotEmpty) {
      final imageUrl = _profile!.profileImageUrl!;
      if (imageUrl.startsWith('http') || imageUrl.startsWith('/uploads/')) {
        final fullUrl = imageUrl.startsWith('http') ? imageUrl : '${_getBaseUrl()}$imageUrl';
        return ClipOval(
          child: Image.network(fullUrl, width: 90, height: 90, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Icon(Icons.content_cut, color: AppColors.primary, size: 40),
          ),
        );
      }
      try {
        String base64Str = imageUrl;
        if (base64Str.startsWith('data:')) base64Str = base64Str.split(',')[1];
        final imageBytes = base64Decode(base64Str);
        return ClipOval(child: Image.memory(imageBytes, width: 90, height: 90, fit: BoxFit.cover));
      } catch (_) {}
    }
    return const Icon(Icons.content_cut, color: AppColors.primary, size: 40);
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
      ),
      child: ListTile(
        leading: Icon(icon, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
        title: Text(title, style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary, fontSize: 15)),
        trailing: Icon(Icons.arrow_forward_ios, color: isDark ? AppColors.darkTextHint : AppColors.lightTextHint, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildThemeToggle(ThemeController themeController, bool isDark) {
    return Obx(() {
      final isDarkMode = themeController.themeMode.value == ThemeMode.dark;
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
        ),
        child: ListTile(
          leading: Icon(
            isDarkMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
            color: AppColors.primary,
          ),
          title: Text(
            'الوضع الليلي',
            style: TextStyle(
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              fontSize: 15,
            ),
          ),
          trailing: Switch(
            value: isDarkMode,
            onChanged: (_) => themeController.toggleTheme(),
            activeColor: AppColors.primary,
          ),
        ),
      );
    });
  }

  Widget _buildLogoutButton(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
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
      ),
    );
  }

  void _showAboutDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('حول التطبيق', style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('تطبيق حجز الحلاقين', style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('الإصدار: 1.0.0', style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary, fontSize: 14)),
            const SizedBox(height: 8),
            Text('تطبيق لحجز مواعيد الحلاقة في فلسطين.', style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary, fontSize: 14)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('حسناً', style: TextStyle(color: AppColors.primary))),
        ],
      ),
    );
  }
}
