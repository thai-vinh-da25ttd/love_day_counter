import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BiometricService {
  BiometricService._();
  static final BiometricService instance = BiometricService._();

  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secure = const FlutterSecureStorage();

  static const _pinKey = 'love_app_pin';

  Future<bool> isDeviceSupported() async {
    try {
      return await _localAuth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  Future<bool> canCheckBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticate() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Xác thực để mở Love Day Counter',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } on PlatformException {
      return false;
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
