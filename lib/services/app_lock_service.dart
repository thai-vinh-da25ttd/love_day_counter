import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_service.dart';
import 'biometric_service.dart';
import 'firestore_service.dart';

class AppLockService extends ChangeNotifier {
  AppLockService._();
  static final AppLockService instance = AppLockService._();

  bool _locked = false;
  bool get locked => _locked;

  Future<void> lockIfEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final coupleId = prefs.getString('current_couple_id');
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (coupleId == null || uid == null) return;

    final snap = await FirestoreService.instance.coupleRef(coupleId).get();
    if (!snap.exists) return;
    final data = snap.data() ?? {};
    final settings = Map<String, dynamic>.from(data['settings'] ?? {});
    final pinEnabled = settings['pinEnabled'] == true;
    final biometricEnabled = settings['biometricEnabled'] == true;

    if (pinEnabled || biometricEnabled) {
      _locked = true;
      notifyListeners();
    }
  }

  Future<bool> unlockWithBiometric() async {
    final ok = await BiometricService.instance.authenticate();
    if (ok) unlock();
    return ok;
  }

  Future<bool> unlockWithPin(String pin) async {
    final ok = await BiometricService.instance.verifyPin(pin);
    if (ok) unlock();
    return ok;
  }

  Future<void> recoverPinWithGoogle() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Phiên đăng nhập đã hết.');
    await AuthService.instance.reauthenticateWithGoogle();

    final prefs = await SharedPreferences.getInstance();
    final coupleId = prefs.getString('current_couple_id');
    if (coupleId != null) {
      await FirestoreService.instance.updateSecurity(
        coupleId: coupleId,
        pinEnabled: false,
        biometricEnabled: false,
      );
    }
    await BiometricService.instance.clearPin();
    unlock();
  }

  void unlock() {
    _locked = false;
    notifyListeners();
  }
}
