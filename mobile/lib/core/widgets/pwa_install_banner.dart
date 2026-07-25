import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'platform_check_stub.dart'
    if (dart.library.js_interop) 'platform_check_web.dart';

class PwaInstallBanner extends StatefulWidget {
  final Widget child;
  const PwaInstallBanner({super.key, required this.child});

  @override
  State<PwaInstallBanner> createState() => _PwaInstallBannerState();
}

class _PwaInstallBannerState extends State<PwaInstallBanner> {
  bool _showBanner = false;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _checkAndShowBanner();
    }
  }

  void _checkAndShowBanner() {
    try {
      final isIos = PlatformCheck.isIosBrowser();
      final isStandalone = PlatformCheck.isStandalone();

      if (isIos && !isStandalone && !_dismissed) {
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted && !_dismissed) {
            setState(() => _showBanner = true);
          }
        });
      }
    } catch (e) {
      debugPrint('PWA install check error: $e');
    }
  }

  void _dismiss() {
    setState(() {
      _dismissed = true;
      _showBanner = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_showBanner)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0A2A1F), Color(0xFF0DF1B5)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.notifications_active,
                            color: Color(0xFF0DF1B5),
                            size: 28,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'فعّل الإشعارات',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _dismiss,
                            icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'للاستفادة من إشعارات الحجز، أضف التطبيق للشاشة الرئيسية:',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _buildStep('1', 'اضغط زر المشاركة'),
                          const SizedBox(width: 8),
                          _buildStep('2', '"أضف للشاشة الرئيسية"'),
                          const SizedBox(width: 8),
                          _buildStep('3', 'افتح من الشاشة'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStep(String number, String text) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Color(0xFF0DF1B5),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  number,
                  style: const TextStyle(
                    color: Color(0xFF0A2A1F),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
