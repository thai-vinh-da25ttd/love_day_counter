import 'package:cloud_firestore/cloud_firestore.dart';

class BucketModel {
  final String id;
  final String title;
  final bool completed;
  final String createdBy;
  final DateTime createdAt;

  const BucketModel({
    required this.id,
    required this.title,
    required this.completed,
    required this.createdBy,
    required this.createdAt,
  });

  factory BucketModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final rawCreatedAt = data['createdAt'];
    DateTime createdAt = DateTime.now();

    if (rawCreatedAt is Timestamp) {
      createdAt = rawCreatedAt.toDate();
    } else if (rawCreatedAt is int) {
      createdAt = DateTime.fromMillisecondsSinceEpoch(rawCreatedAt);
    }

    return BucketModel(
      id: doc.id,
      title: data['title']?.toString() ?? '',
      completed: data['completed'] == true,
      createdBy: data['createdBy']?.toString() ?? '',
      createdAt: createdAt,
    );
  }
}
