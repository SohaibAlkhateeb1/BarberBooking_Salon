import 'package:flutter/material.dart';
import 'app_theme.dart';

class AppResponsive {
  AppResponsive._();

  static const double mobile = 320;
  static const double mobileMid = 375;
  static const double mobileLarge = 414;
  static const double tablet = 768;
  static const double desktop = 1024;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < tablet;

  static bool isTablet(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= tablet && w < desktop;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= desktop;

  static double screenWidth(BuildContext context) =>
      MediaQuery.sizeOf(context).width;

  static double screenHeight(BuildContext context) =>
      MediaQuery.sizeOf(context).height;

  static double scale(BuildContext context, double size) {
    final width = screenWidth(context);
    return size * (width / 414);
  }

  static double verticalScale(BuildContext context, double size) {
    final height = screenHeight(context);
    return size * (height / 896);
  }

  static double fontSize(BuildContext context, double size) {
    final width = screenWidth(context);
    if (width < mobileMid) return size * 0.9;
    if (width > tablet) return size * 1.1;
    return size;
  }

  static EdgeInsets symmetric(BuildContext context, {double horizontal = 20, double vertical = 0}) {
    final w = screenWidth(context);
    final h = w < mobileMid ? 12.0 : (w > tablet ? 32.0 : horizontal);
    return EdgeInsets.symmetric(horizontal: h, vertical: vertical);
  }

  static EdgeInsets pagePadding(BuildContext context) {
    final w = screenWidth(context);
    if (w < mobileMid) return const EdgeInsets.symmetric(horizontal: 16);
    if (w > tablet) return const EdgeInsets.symmetric(horizontal: 48);
    return const EdgeInsets.symmetric(horizontal: 20);
  }

  static double gridCrossAxisCount(BuildContext context) {
    final w = screenWidth(context);
    if (w < mobileMid) return 2;
    if (w < tablet) return 3;
    return 4;
  }

  static double cardHeight(BuildContext context) {
    final w = screenWidth(context);
    if (w < mobileMid) return 100;
    if (w < tablet) return 120;
    return 140;
  }

  static double buttonHeight(BuildContext context, {bool isSmall = false}) {
    final w = screenWidth(context);
    if (isSmall) return w < mobileMid ? 40.0 : 44.0;
    return w < mobileMid ? 48.0 : 56.0;
  }

  static double iconSize(BuildContext context, {double base = 22}) {
    final w = screenWidth(context);
    if (w < mobileMid) return base * 0.9;
    if (w > tablet) return base * 1.1;
    return base;
  }
}

class KeyboardDismiss extends StatelessWidget {
  final Widget child;
  final bool dismissOnTap;

  const KeyboardDismiss({
    super.key,
    required this.child,
    this.dismissOnTap = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!dismissOnTap) return child;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: child,
    );
  }
}

class ResponsiveScrollView extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool dismissKeyboard;

  const ResponsiveScrollView({
    super.key,
    required this.child,
    this.padding,
    this.dismissKeyboard = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectivePadding = padding ?? AppResponsive.pagePadding(context);
    final scrollable = SingleChildScrollView(
      padding: effectivePadding,
      child: child,
    );

    if (!dismissKeyboard) return scrollable;

    return KeyboardDismiss(child: scrollable);
  }
}

class ResponsiveScaffold extends StatelessWidget {
  final Widget? appBar;
  final Widget body;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final Color? backgroundColor;
  final bool resizeToAvoidBottomInset;
  final bool dismissKeyboard;

  const ResponsiveScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
    this.dismissKeyboard = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor ?? context.backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      body: dismissKeyboard
          ? KeyboardDismiss(child: body)
          : body,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}
