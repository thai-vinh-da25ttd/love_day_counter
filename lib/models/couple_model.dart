import 'package:cloud_firestore/cloud_firestore.dart';

class CoupleMember {
  final String uid;
  final String nickname;
  final String avatarUrl;

  const CoupleMember({
    required this.uid,
    required this.nickname,
    required this.avatarUrl,
  });

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'nickname': nickname,
        'avatarUrl': avatarUrl,
      };

  factory CoupleMember.fromMap(Map<String, dynamic>? map) {
    final data = map ?? {};
    return CoupleMember(
      uid: data['uid']?.toString() ?? '',
      nickname: data['nickname']?.toString() ?? '',
      avatarUrl: data['avatarUrl']?.toString() ?? '',
    );
  }
}

class CoupleModel {
  final String id;
  final String pairCode;
  final DateTime startDate;
  final String backgroundUrl;
  final List<String> memberIds;
  final CoupleMember person1;
  final CoupleMember person2;
  final bool pinEnabled;
  final bool biometricEnabled;

  const CoupleModel({
    required this.id,
    required this.pairCode,
    required this.startDate,
    required this.backgroundUrl,
    required this.memberIds,
    required this.person1,
    required this.person2,
    required this.pinEnabled,
    required this.biometricEnabled,
  });

  CoupleMember? memberFor(String uid) {
    if (person1.uid == uid) return person1;
    if (person2.uid == uid) return person2;
    return null;
  }

  CoupleMember? partnerFor(String uid) {
    if (person1.uid == uid) return person2.uid.isEmpty ? null : person2;
    if (person2.uid == uid) return person1.uid.isEmpty ? null : person1;
    return null;
  }

  factory CoupleModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final rawStart = data['startDate'];

    DateTime startDate;
    if (rawStart is Timestamp) {
      startDate = rawStart.toDate();
    } else if (rawStart is int) {
      startDate = DateTime.fromMillisecondsSinceEpoch(rawStart);
    } else {
      startDate = DateTime.now();
    }

    return CoupleModel(
      id: doc.id,
      pairCode: data['pairCode']?.toString() ?? '',
      startDate: startDate,
      backgroundUrl: data['backgroundUrl']?.toString() ?? '',
      memberIds: List<String>.from(data['memberIds'] ?? const []),
      person1: CoupleMember.fromMap(data['person1'] as Map<String, dynamic>?),
      person2: CoupleMember.fromMap(data['person2'] as Map<String, dynamic>?),
      pinEnabled: data['settings']?['pinEnabled'] == true,
      biometricEnabled: data['settings']?['biometricEnabled'] == true,
    );
  }
}
