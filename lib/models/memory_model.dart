import 'package:cloud_firestore/cloud_firestore.dart';

class MemoryModel {
  final String id;
  final String title;
  final String note;
  final DateTime date;
  final String imageUrl;
  final String createdBy;

  const MemoryModel({
    required this.id,
    required this.title,
    required this.note,
    required this.date,
    required this.imageUrl,
    required this.createdBy,
  });

  factory MemoryModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final rawDate = data['date'];
    DateTime date = DateTime.now();

    if (rawDate is Timestamp) {
      date = rawDate.toDate();
    } else if (rawDate is int) {
      date = DateTime.fromMillisecondsSinceEpoch(rawDate);
    }

    return MemoryModel(
      id: doc.id,
      title: data['title']?.toString() ?? '',
      note: data['note']?.toString() ?? '',
      date: date,
      imageUrl: data['imageUrl']?.toString() ?? '',
      createdBy: data['createdBy']?.toString() ?? '',
    );
  }
}
