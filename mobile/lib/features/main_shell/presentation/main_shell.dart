import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/animations/app_animations.dart';
import '../../../core/session/session_manager.dart';
import '../../../core/storage/token_storage.dart';
import '../../home/presentation/home_screen.dart';
import '../../search/presentation/search_screen.dart';
import '../../bookings/presentation/my_bookings_screen.dart';
import '../../account/presentation/account_screen.dart';
import '../../role_selection/presentation/role_selection_screen.dart';

class MainShell extends StatefulWidget {
  final int initialTab;
  const MainShell({super.key, this.initialTab = 0});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  late int _currentIndex = widget.initialTab;
  final Map<int, Widget> _screenCache = {};

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

  Widget _buildTab(int index) {
    return _screenCache.putIfAbsent(index, () {
      switch (index) {
        case 0: return const HomeScreen();
        case 1: return const SearchScreen();
        case 2: return const MyBookingsScreen();
        case 3: return const AccountScreen();
        default: return const HomeScreen();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: _buildTab(_currentIndex),
      bottomNavigationBar: FadeIn(
        delay: const Duration(milliseconds: 200),
        child: Container(
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
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'الرئيسية',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.search),
                label: 'البحث',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today_outlined),
                activeIcon: Icon(Icons.calendar_today),
                label: 'المواعيد',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'حساب',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
