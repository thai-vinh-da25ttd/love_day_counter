import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/firestore_service.dart';

class BucketRepository {
  BucketRepository._();
  static final BucketRepository instance = BucketRepository._();

  final FirestoreService _service = FirestoreService.instance;

  Stream<QuerySnapshot<Map<String, dynamic>>> stream(String coupleId) {
    return _service.bucketStream(coupleId);
  }

  Future<void> add({
    required String coupleId,
    required String title,
    required String createdBy,
  }) {
    return _service.addBucketItem(
      coupleId: coupleId,
      title: title,
      createdBy: createdBy,
    );
  }

  Future<void> toggle({
    required String coupleId,
    required String itemId,
    required bool completed,
  }) {
    return _service.toggleBucketItem(
      coupleId: coupleId,
      itemId: itemId,
      completed: completed,
    );
  }

  Future<void> delete({
    required String coupleId,
    required String itemId,
  }) {
    return _service.deleteBucketItem(
      coupleId: coupleId,
      itemId: itemId,
    );
  }
}
