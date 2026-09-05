import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Kết quả trả về sau khi thử xác thực sinh trắc học.
enum BiometricAuthResult {
  success,
  notAvailable,
  notEnrolled,
  lockedOut,
  permanentlyLockedOut,
  passcodeNotSet,
  cancelled,
  error,
}

class BiometricService {
  BiometricService._();
  static final BiometricService instance = BiometricService._();

  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secure = const FlutterSecureStorage();

  static const _pinKey = 'love_app_pin';

  /// Thiết bị có phần cứng/OS hỗ trợ sinh trắc học hoặc khoá màn hình không.
  Future<bool> isDeviceSupported() async {
    try {
      return await _localAuth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  /// Thiết bị đã đăng ký ít nhất 1 vân tay/khuôn mặt chưa.
  Future<bool> canCheckBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  /// Gọi cả 2 kiểm tra trên cùng lúc — dùng để quyết định có hiện nút
  /// "Dùng sinh trắc học" hay không.
  Future<bool> isBiometricReady() async {
    final results = await Future.wait([
      isDeviceSupported(),
      canCheckBiometrics(),
    ]);
    return results[0] && results[1];
  }

  Future<BiometricAuthResult> authenticate() async {
  try {
    final ok = await _localAuth.authenticate(
      localizedReason: 'Xác thực để mở Love Day Counter',
      biometricOnly: true,
      persistAcrossBackgrounding: true,
    );

    return ok
        ? BiometricAuthResult.success
        : BiometricAuthResult.cancelled;
  } on PlatformException catch (e) {
    return _mapError(e);
  } catch (e) {
    debugPrint('BiometricService.authenticate lỗi không xác định: $e');
    return BiometricAuthResult.error;
  }
}

  BiometricAuthResult _mapError(PlatformException e) {
    switch (e.code) {
      case 'NotAvailable':
        return BiometricAuthResult.notAvailable;
      case 'NotEnrolled':
        return BiometricAuthResult.notEnrolled;
      case 'LockedOut':
        return BiometricAuthResult.lockedOut;
      case 'PermanentlyLockedOut':
        return BiometricAuthResult.permanentlyLockedOut;
      case 'PasscodeNotSet':
        return BiometricAuthResult.passcodeNotSet;
      default:
        debugPrint('BiometricService lỗi ${e.code}: ${e.message}');
        return BiometricAuthResult.error;
    }
  }

  /// Huỷ hộp thoại xác thực đang mở — gọi khi app bị đưa xuống nền giữa chừng.
  Future<void> cancelAuthentication() async {
    try {
      await _localAuth.stopAuthentication();
    } catch (_) {
      // Không có phiên nào đang chạy — bỏ qua.
    }
  }

  Future<void> savePin(String pin) async {
    await _secure.write(key: _pinKey, value: pin);
  }

  Future<bool> hasPin() async {
    return (await _secure.read(key: _pinKey)) != null;
  }

  Future<bool> verifyPin(String pin) async {
    return await _secure.read(key: _pinKey) == pin;
  }

  Future<void> clearPin() async {
    await _secure.delete(key: _pinKey);
  }
}