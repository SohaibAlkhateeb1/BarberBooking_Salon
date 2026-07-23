import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/animations/app_animations.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/utils/error_extractor.dart';
import '../../../core/widgets/app_button.dart';
import 'login_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String purpose;
  final VoidCallback? onVerified;

  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
    this.purpose = 'verify',
    this.onVerified,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  String _errorMessage = '';
  String _successMessage = '';

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _code => _controllers.map((c) => c.text).join();

  Future<void> _verifyOtp() async {
    final code = _code;
    if (code.length != 6) {
      setState(() => _errorMessage = 'الرجاء إدخال الرمز كاملاً (6 أرقام)');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final apiClient = ApiClient();
      final response = await apiClient.dio.post(
        '/api/auth/verify-otp',
        data: {
          'phoneNumber': widget.phoneNumber,
          'code': code,
          'purpose': widget.purpose,
        },
      );

      if (response.data['verified'] == true) {
        setState(() {
          _successMessage = 'تم التحقق بنجاح';
          _errorMessage = '';
        });
        await TokenStorage().clearPendingOtpPhone();
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          if (widget.onVerified != null) {
            widget.onVerified!();
          } else {
            Get.offAll(() => const LoginScreen());
          }
        }
      }
    } on Exception catch (e) {
      String msg = extractErrorMessage(e);
      setState(() => _errorMessage = msg);
    } catch (e) {
      String msg = extractErrorMessage(e);
      setState(() => _errorMessage = msg);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          // Don't allow going back - stay on OTP screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('يجب إدخال رمز التحقق للمتابعة'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: context.backgroundColor,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Title (no back button)
                FadeIn(
                  delay: const Duration(milliseconds: 100),
                  child: Center(
                    child: Text('تحقق من رقم الهاتف', style: AppTextStyles.title(isDark)),
                  ),
                ),
                const SizedBox(height: 40),
                // Icon
                FadeIn(
                  delay: const Duration(milliseconds: 200),
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: 0.1),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.phone_android_outlined,
                      size: 48,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Title
                FadeIn(
                  delay: const Duration(milliseconds: 300),
                  child: Text('أدخل رمز التحقق', style: AppTextStyles.headline(isDark)),
                ),
                const SizedBox(height: 12),
                // Subtitle
                FadeIn(
                  delay: const Duration(milliseconds: 400),
                  child: Text('تم إرسال رمز مكون من 6 أرقام إلى', style: AppTextStyles.secondary(isDark), textAlign: TextAlign.center),
                ),
                const SizedBox(height: 4),
                FadeIn(
                  delay: const Duration(milliseconds: 450),
                  child: Text(widget.phoneNumber, style: AppTextStyles.primary(isDark), textAlign: TextAlign.center),
                ),
                const SizedBox(height: 8),
                // 24 hours note
                FadeIn(
                  delay: const Duration(milliseconds: 500),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppBorderRadius.md),
                      border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: AppColors.info,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'سيتم إرسال رمز التحقق على واتساب أو رسائل SMS خلال 24 ساعة أو أقل.',
                            style: const TextStyle(
                              color: AppColors.info,
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                // OTP Input
                FadeIn(
                  delay: const Duration(milliseconds: 600),
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(6, (index) {
                      return Container(
                        width: 42,
                        height: 52,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        child: KeyboardListener(
                          focusNode: FocusNode(),
                          onKeyEvent: (event) {
                            if (event is KeyDownEvent &&
                                event.logicalKey == LogicalKeyboardKey.backspace &&
                                _controllers[index].text.isEmpty &&
                                index > 0) {
                              _controllers[index - 1].clear();
                              _focusNodes[index - 1].requestFocus();
                            }
                          },
                          child: TextField(
                            controller: _controllers[index],
                            focusNode: _focusNodes[index],
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            maxLength: 1,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: context.textColor,
                            ),
                            decoration: InputDecoration(
                              counterText: '',
                              contentPadding: EdgeInsets.zero,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppBorderRadius.md),
                                borderSide: BorderSide(
                                  color: context.cardBorderColor,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppBorderRadius.md),
                                borderSide: BorderSide(
                                  color: _controllers[index].text.isNotEmpty
                                      ? AppColors.primary
                                      : context.cardBorderColor,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppBorderRadius.md),
                                borderSide: const BorderSide(
                                  color: AppColors.primary,
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: context.surfaceColor,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: (value) {
                              setState(() {
                                _errorMessage = '';
                                _successMessage = '';
                              });
                              if (value.length == 1 && index < 5) {
                                _focusNodes[index + 1].requestFocus();
                              }
                              if (value.length == 1 && index == 5) {
                                _focusNodes[index].unfocus();
                                if (_code.length == 6) {
                                  _verifyOtp();
                                }
                              }
                            },
                          ),
                        ),
                      );
                    }),
                  ),
                  ),
                ),
                const SizedBox(height: 16),
                // Error message
                if (_errorMessage.isNotEmpty)
                  FadeIn(
                    delay: const Duration(milliseconds: 100),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                      ),
                      child: Text(_errorMessage, style: AppTextStyles.error(isDark), textAlign: TextAlign.center),
                    ),
                  ),
                // Success message
                if (_successMessage.isNotEmpty)
                  FadeIn(
                    delay: const Duration(milliseconds: 100),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                      ),
                      child: Text(_successMessage, style: AppTextStyles.success(isDark), textAlign: TextAlign.center),
                    ),
                  ),
                const SizedBox(height: 8),
                // Verify Button
                FadeIn(
                  delay: const Duration(milliseconds: 700),
                  child: AppButton(
                    label: 'تحقق',
                    onPressed: _isLoading ? null : _verifyOtp,
                    isLoading: _isLoading,
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
