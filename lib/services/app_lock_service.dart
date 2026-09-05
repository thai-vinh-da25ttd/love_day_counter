import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'auth_service.dart';
import 'biometric_service.dart';
import 'firestore_service.dart';

class AppLockService extends ChangeNotifier {
  AppLockService._();
  static final AppLockService instance = AppLockService._();

  bool _locked = false;
  bool get locked => _locked;

  /// Khoá app nếu PIN hoặc sinh trắc học đang bật cho cặp đôi này.
  ///
  /// Trước đây hàm này tự đi đọc Firestore + SharedPreferences mỗi lần gọi,
  /// và CHỈ được gọi khi app bị đưa xuống nền (didChangeAppLifecycleState).
  /// Hệ quả là:
  ///  1) Mở app từ trạng thái tắt hẳn sẽ KHÔNG bị khoá (chỉ khoá sau khi bạn
  ///     thoát app 1 lần rồi mở lại) — đây là một lỗi thật sự.
  ///  2) Có thêm 1 lượt gọi mạng không cần thiết ngay trên luồng bảo mật,
  ///     dễ bị trễ/lỗi khi mất mạng.
  ///
  /// Giờ hàm này chỉ nhận thẳng 2 cờ settings (HomeScreen đã có sẵn từ
  /// stream của couple, không cần hỏi lại Firestore) nên chạy đồng bộ, không
  /// phụ thuộc mạng, và được gọi cả lúc mới vào Home lẫn lúc app quay lại từ
  /// nền.
  void lockIfEnabled({
    required bool pinEnabled,
    required bool biometricEnabled,
  }) {
    if ((pinEnabled || biometricEnabled) && !_locked) {
      _locked = true;
      notifyListeners();
    }
  }

  Future<BiometricAuthResult> unlockWithBiometric() async {
    final result = await BiometricService.instance.authenticate();
    if (result == BiometricAuthResult.success) unlock();
    return result;
  }

  Future<bool> unlockWithPin(String pin) async {
    final ok = await BiometricService.instance.verifyPin(pin);
    if (ok) unlock();
    return ok;
  }

  Future<void> recoverPinWithGoogle({required String coupleId}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Phiên đăng nhập đã hết.');
    await AuthService.instance.reauthenticateWithGoogle();

    await FirestoreService.instance.updateSecurity(
      coupleId: coupleId,
      pinEnabled: false,
      biometricEnabled: false,
    );
    await BiometricService.instance.clearPin();
    unlock();
  }

  void unlock() {
    if (!_locked) return;
    _locked = false;
    notifyListeners();
  }
}
