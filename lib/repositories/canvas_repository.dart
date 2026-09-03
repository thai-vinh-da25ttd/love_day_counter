import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/firestore_service.dart';

class CanvasRepository {
  CanvasRepository._();
  static final CanvasRepository instance = CanvasRepository._();

  final FirestoreService _service = FirestoreService.instance;

  Stream<DocumentSnapshot<Map<String, dynamic>>> stream(String coupleId) {
    return _service.canvasStream(coupleId);
  }

  Future<void> save({
    required String coupleId,
    required List<Map<String, dynamic>> strokes,
  }) {
    return _service.saveCanvas(
      coupleId: coupleId,
      strokes: strokes,
    );
  }
}
