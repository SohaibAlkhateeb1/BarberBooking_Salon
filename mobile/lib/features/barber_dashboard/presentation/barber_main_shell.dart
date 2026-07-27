import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/session/session_manager.dart';
import '../../../core/storage/token_storage.dart';
import '../../role_selection/presentation/role_selection_screen.dart';
import 'barber_dashboard_screen.dart';
import 'barber_bookings_screen.dart';
import 'barber_services_screen.dart';
import 'barber_account_screen.dart';

class BarberMainShell extends StatefulWidget {
  const BarberMainShell({super.key});

  @override
  State<BarberMainShell> createState() => _BarberMainShellState();
}

class _BarberMainShellState extends State<BarberMainShell> with WidgetsBindingObserver {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    BarberDashboardScreen(),
    BarberBookingsScreen(),
    BarberServicesScreen(),
    BarberAccountScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SessionManager().initialize(onSessionExpired: _handleSessionExpired);
    SessionManager().onUserActivity();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkSession();
    }
  }

  Future<void> _checkSession() async {
    final valid = await SessionManager().checkSessionOnResume();
    if (!valid && mounted) {
      _handleSessionExpired();
    }
  }

  void _handleSessionExpired() async {
    if (!mounted) return;
    await TokenStorage().clearAll();
    SessionManager().dispose();
    if (mounted) {
      Get.offAll(() => const RoleSelectionScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          border: Border(top: BorderSide(color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            SessionManager().onUserActivity();
            setState(() => _currentIndex = index);
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          selectedItemColor: AppColors.primary,
          unselectedItemColor: isDark ? AppColors.darkTextHint : AppColors.lightTextHint,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'لوحة التحكم',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined),
              activeIcon: Icon(Icons.calendar_today),
              label: 'المواعيد',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.content_cut_outlined),
              activeIcon: Icon(Icons.content_cut),
              label: 'الخدمات',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'حسابي',
            ),
          ],
        ),
      ),
    );
  }
}
