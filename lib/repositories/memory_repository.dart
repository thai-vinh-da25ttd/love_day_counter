import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/firestore_service.dart';

class MemoryRepository {
  MemoryRepository._();
  static final MemoryRepository instance = MemoryRepository._();

  final FirestoreService _service = FirestoreService.instance;

  Stream<QuerySnapshot<Map<String, dynamic>>> stream(String coupleId) {
    return _service.memoriesStream(coupleId);
  }

  Future<void> add({
    required String coupleId,
    required String title,
    required String note,
    required DateTime date,
    required String imageUrl,
    required String createdBy,
  }) {
    return _service.addMemory(
      coupleId: coupleId,
      title: title,
      note: note,
      date: date,
      imageUrl: imageUrl,
      createdBy: createdBy,
    );
  }
}
