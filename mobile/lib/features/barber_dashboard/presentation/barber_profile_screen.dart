import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/animations/app_animations.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../data/barber_dashboard_service.dart';

class BarberProfileScreen2 extends StatefulWidget {
  const BarberProfileScreen2({super.key});

  @override
  State<BarberProfileScreen2> createState() => _BarberProfileScreen2State();
}

class _BarberProfileScreen2State extends State<BarberProfileScreen2> {
  final BarberDashboardService _service = BarberDashboardService(ApiClient());
  final TokenStorage _tokenStorage = TokenStorage();
  String _shopName = '';
  String _fullName = '';
  String _phone = '';
  List<WorkingHourModel2> _schedule = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final results = await Future.wait([
        _service.getDashboard(),
        _service.getSchedule(),
        _tokenStorage.getFullName(),
        _tokenStorage.getPhoneNumber(),
      ]);
      if (mounted) {
        setState(() {
          _shopName = (results[0] as dynamic).shopName ?? '';
          _schedule = results[1] as List<WorkingHourModel2>;
          _fullName = results[2] as String? ?? '';
          _phone = results[3] as String? ?? '';
          _isLoading = false;
        });
      }
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
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FadeIn(
                      delay: const Duration(milliseconds: 100),
                      child: Text('حسابي', style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 24),
                    FadeIn(
                      delay: const Duration(milliseconds: 200),
                      child: _buildProfileCard(isDark),
                    ),
                    const SizedBox(height: 20),
                    FadeIn(
                      delay: const Duration(milliseconds: 300),
                      child: _buildScheduleSection(isDark),
                    ),
                    const SizedBox(height: 20),
                    FadeIn(
                      delay: const Duration(milliseconds: 400),
                      child: _buildLogoutButton(),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildProfileCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
      ),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.content_cut, color: AppColors.primary, size: 32),
          ),
          const SizedBox(height: 12),
          Text(_shopName, style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(_fullName, style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary, fontSize: 14)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.phone, color: isDark ? AppColors.darkTextHint : AppColors.lightTextHint, size: 16),
              const SizedBox(width: 6),
              Text(_phone, style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('أيام العمل', style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ..._schedule.map((wh) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 80,
                  child: Text(wh.dayName, style: TextStyle(color: wh.isOpen ? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary) : (isDark ? AppColors.darkTextHint : AppColors.lightTextHint), fontSize: 14)),
                ),
                const Spacer(),
                if (wh.isOpen)
                  Text('${wh.openTime} - ${wh.closeTime}', style: const TextStyle(color: AppColors.primary, fontSize: 14))
                else
                  const Text('مغلق', style: TextStyle(color: AppColors.error, fontSize: 14)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: () async {
        await _tokenStorage.clearAll();
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.error),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, color: AppColors.error, size: 20),
            SizedBox(width: 8),
            Text('تسجيل الخروج', style: TextStyle(color: AppColors.error, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
