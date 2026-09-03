import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/couple_model.dart';
import '../services/firestore_service.dart';

class CoupleRepository {
  CoupleRepository._();
  static final CoupleRepository instance = CoupleRepository._();

  final FirestoreService _service = FirestoreService.instance;

  Stream<DocumentSnapshot<Map<String, dynamic>>> stream(String coupleId) {
    return _service.coupleStream(coupleId);
  }

  Future<String> create({
    required User user,
    required String nickname,
    required DateTime startDate,
  }) {
    return _service.createCouple(
      user: user,
      nickname: nickname,
      startDate: startDate,
    );
  }

  Future<String?> join({
    required User user,
    required String pairCode,
    required String nickname,
  }) {
    return _service.joinCouple(
      user: user,
      pairCode: pairCode,
      nickname: nickname,
    );
  }

  Future<CoupleModel?> getCurrentCouple(String uid) async {
    final coupleId = await _service.getCoupleIdForUser(uid);
    if (coupleId == null || coupleId.isEmpty) return null;

    final doc = await _service.coupleRef(coupleId).get();
    if (!doc.exists) return null;

    return CoupleModel.fromFirestore(doc);
  }
}
