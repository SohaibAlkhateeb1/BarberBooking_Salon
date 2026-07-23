import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/error_extractor.dart';
import '../data/auth_service.dart';
import '../../main_shell/presentation/main_shell.dart';
import 'otp_verification_screen.dart';

class AuthController extends GetxController {
  final AuthService _authService;

  AuthController() : _authService = AuthService(ApiClient());

  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final fullName = ''.obs;
  final phoneNumber = ''.obs;
  final password = ''.obs;
  final acceptTerms = false.obs;
  final profileImageFile = Rxn<XFile>();
  final profileImageBytes = Rxn<Uint8List>();
  final profileImageBase64 = ''.obs;

  void clearError() => errorMessage.value = '';

  void updateFullName(String value) => fullName.value = value;
  void updatePhoneNumber(String value) => phoneNumber.value = value;
  void updatePassword(String value) => password.value = value;
  void toggleAcceptTerms() => acceptTerms.value = !acceptTerms.value;

  Future<void> pickProfileImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512, maxHeight: 512, imageQuality: 80);
    if (picked != null) {
      profileImageFile.value = picked;
      final bytes = await picked.readAsBytes();
      profileImageBytes.value = bytes;
      profileImageBase64.value = base64Encode(bytes);
    }
  }

  Future<void> register() async {
    clearError();

    if (fullName.value.isEmpty) {
      errorMessage.value = 'الاسم الكامل مطلوب';
      return;
    }
    if (phoneNumber.value.isEmpty) {
      errorMessage.value = 'رقم الهاتف مطلوب';
      return;
    }
    if (password.value.isEmpty) {
      errorMessage.value = 'كلمة المرور مطلوبة';
      return;
    }
    if (!acceptTerms.value) {
      errorMessage.value = 'يجب الموافقة على الشروط والخصوصية';
      return;
    }

    isLoading.value = true;

    try {
      await _authService.register(
        fullName: fullName.value,
        phoneNumber: phoneNumber.value,
        password: password.value,
        acceptTerms: acceptTerms.value,
        profileImageUrl: profileImageBase64.value.isNotEmpty ? profileImageBase64.value : null,
      );
      final tokenStorage = TokenStorage();
      await tokenStorage.savePendingOtpPhone(phoneNumber.value);
      // Navigate to OTP verification screen
      Get.off(() => OtpVerificationScreen(
        phoneNumber: phoneNumber.value,
      ));
    } on AppException catch (e) {
      errorMessage.value = e.message;
    } on DioException catch (e) {
      if (e.error is AppException) {
        errorMessage.value = (e.error as AppException).message;
      } else if (e.response?.data is Map && e.response!.data['message'] != null) {
        errorMessage.value = e.response!.data['message'];
      } else {
        errorMessage.value = 'حدث خطأ في الاتصال بالسيرفر';
      }
    } catch (e) {
      String msg = extractErrorMessage(e);
      errorMessage.value = msg;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> login() async {
    clearError();

    if (phoneNumber.value.isEmpty) {
      errorMessage.value = 'رقم الهاتف مطلوب';
      return;
    }
    if (password.value.isEmpty) {
      errorMessage.value = 'كلمة المرور مطلوبة';
      return;
    }

    isLoading.value = true;

    try {
      await _authService.login(
        phoneNumber: phoneNumber.value,
        password: password.value,
      );

      // Save FCM token to backend after login
      try {
        await NotificationService().saveTokenToBackend();
      } catch (_) {}

      Get.offAll(() => const MainShell());
    } on AppException catch (e) {
      errorMessage.value = e.message;
    } on DioException catch (e) {
      if (e.error is AppException) {
        errorMessage.value = (e.error as AppException).message;
      } else if (e.response?.data is Map && e.response!.data['message'] != null) {
        errorMessage.value = e.response!.data['message'];
      } else {
        errorMessage.value = 'حدث خطأ في الاتصال بالسيرفر';
      }
    } catch (e) {
      String msg = extractErrorMessage(e);
      errorMessage.value = msg;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
  }
}
