import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  FirestoreService._();
  static final FirestoreService instance = FirestoreService._();

  final FirebaseFirestore db = FirebaseFirestore.instance;

  String generatePairCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    return List.generate(
      6,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
  }

  DocumentReference<Map<String, dynamic>> userRef(String uid) {
    return db.collection('users').doc(uid);
  }

  DocumentReference<Map<String, dynamic>> coupleRef(String coupleId) {
    return db.collection('couples').doc(coupleId);
  }

  Future<String?> getCoupleIdForUser(String uid) async {
    final snap = await userRef(uid).get();
    return snap.data()?['coupleId']?.toString();
  }

  Future<String> createCouple({
    required User user,
    required String nickname,
    required DateTime startDate,
  }) async {
    final coupleId = db.collection('couples').doc().id;
    final pairCode = generatePairCode();

    await coupleRef(coupleId).set({
      'pairCode': pairCode,
      'startDate': Timestamp.fromDate(startDate),
      'backgroundUrl': '',
      'memberIds': [user.uid],
      'person1': {
        'uid': user.uid,
        'nickname': nickname,
        'avatarUrl': user.photoURL ?? '',
      },
      'person2': {
        'uid': '',
        'nickname': 'Người ấy',
        'avatarUrl': '',
      },
      'settings': {
        'pinEnabled': false,
        'biometricEnabled': false,
      },
      'createdAt': FieldValue.serverTimestamp(),
    });

    await userRef(user.uid).set({
      'email': user.email ?? '',
      'displayName': user.displayName ?? '',
      'coupleId': coupleId,
      'fcmToken': null,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return coupleId;
  }

  Future<String?> joinCouple({
    required User user,
    required String pairCode,
    required String nickname,
  }) async {
    final query = await db
        .collection('couples')
        .where('pairCode', isEqualTo: pairCode)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;

    final couple = query.docs.first;
    final data = couple.data();
    final memberIds = List<String>.from(data['memberIds'] ?? const []);

    if (memberIds.contains(user.uid)) {
      await userRef(user.uid).set({
        'coupleId': couple.id,
      }, SetOptions(merge: true));
      return couple.id;
    }

    if (memberIds.length >= 2) {
      throw Exception('Cặp đôi này đã đủ 2 người.');
    }

    await couple.reference.update({
      'memberIds': [...memberIds, user.uid],
      'person2': {
        'uid': user.uid,
        'nickname': nickname,
        'avatarUrl': user.photoURL ?? '',
      },
    });

    await userRef(user.uid).set({
      'email': user.email ?? '',
      'displayName': user.displayName ?? '',
      'coupleId': couple.id,
      'fcmToken': null,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return couple.id;
  }

  Future<void> updateMember({
    required String coupleId,
    required String uid,
    String? nickname,
    String? avatarUrl,
  }) async {
    final ref = coupleRef(coupleId);
    final snap = await ref.get();
    if (!snap.exists) throw Exception('Không tìm thấy cặp đôi.');

    final data = snap.data() ?? {};
    final p1 = Map<String, dynamic>.from(data['person1'] ?? {});
    final p2 = Map<String, dynamic>.from(data['person2'] ?? {});

    final target = p1['uid'] == uid ? p1 : p2;
    if (nickname != null) target['nickname'] = nickname;
    if (avatarUrl != null) target['avatarUrl'] = avatarUrl;

    await ref.update({
      p1['uid'] == uid ? 'person1' : 'person2': target,
    });
  }

  Future<void> updateBackground({
    required String coupleId,
    required String url,
  }) async {
    await coupleRef(coupleId).update({'backgroundUrl': url});
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> coupleStream(String coupleId) {
    return coupleRef(coupleId).snapshots();
  }

  Future<void> saveFcmToken({
    required String uid,
    required String token,
  }) async {
    await userRef(uid).set({
      'fcmToken': token,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> sendLove({
    required String coupleId,
    required String fromUid,
    required String toUid,
  }) async {
    await db.collection('couples').doc(coupleId).collection('reactions').add({
      'fromUid': fromUid,
      'toUid': toUid,
      'type': 'love',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  CollectionReference<Map<String, dynamic>> memoriesRef(String coupleId) =>
      coupleRef(coupleId).collection('memories');

  CollectionReference<Map<String, dynamic>> bucketRef(String coupleId) =>
      coupleRef(coupleId).collection('bucket_items');

  DocumentReference<Map<String, dynamic>> canvasRef(String coupleId) =>
      coupleRef(coupleId).collection('canvas').doc('current');

  Future<void> addMemory({
    required String coupleId,
    required String title,
    required String note,
    required DateTime date,
    required String imageUrl,
    required String createdBy,
  }) async {
    await memoriesRef(coupleId).add({
      'title': title,
      'note': note,
      'date': Timestamp.fromDate(date),
      'imageUrl': imageUrl,
      'createdBy': createdBy,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> memoriesStream(String coupleId) {
    return memoriesRef(coupleId)
        .orderBy('date', descending: true)
        .snapshots();
  }

  Future<void> addBucketItem({
    required String coupleId,
    required String title,
    required String createdBy,
  }) async {
    await bucketRef(coupleId).add({
      'title': title,
      'completed': false,
      'createdBy': createdBy,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> toggleBucketItem({
    required String coupleId,
    required String itemId,
    required bool completed,
  }) async {
    await bucketRef(coupleId).doc(itemId).update({'completed': completed});
  }

  Future<void> deleteBucketItem({
    required String coupleId,
    required String itemId,
  }) async {
    await bucketRef(coupleId).doc(itemId).delete();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> bucketStream(String coupleId) {
    return bucketRef(coupleId)
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  Future<void> saveCanvas({
    required String coupleId,
    required List<Map<String, dynamic>> strokes,
  }) async {
    await canvasRef(coupleId).set({
      'strokes': strokes,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> canvasStream(String coupleId) {
    return canvasRef(coupleId).snapshots();
  }

  Future<void> updateSecurity({
    required String coupleId,
    required bool pinEnabled,
    required bool biometricEnabled,
  }) async {
    await coupleRef(coupleId).update({
      'settings': {
        'pinEnabled': pinEnabled,
        'biometricEnabled': biometricEnabled,
      },
    });
  }
}
