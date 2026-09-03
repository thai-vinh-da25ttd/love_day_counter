import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadFile({
    required File file,
    required String path,
  }) async {
    final ref = _storage.ref().child(path);
    await ref.putFile(file);
    return ref.getDownloadURL();
  }

  Future<String> uploadAvatar({
    required String coupleId,
    required String uid,
    required File file,
  }) {
    return uploadFile(
      file: file,
      path: 'couples/$coupleId/avatars/$uid.jpg',
    );
  }

  Future<String> uploadBackground({
    required String coupleId,
    required File file,
  }) {
    return uploadFile(
      file: file,
      path: 'couples/$coupleId/background/background.jpg',
    );
  }

  Future<String> uploadMemory({
    required String coupleId,
    required String memoryId,
    required File file,
  }) {
    return uploadFile(
      file: file,
      path: 'couples/$coupleId/memories/$memoryId.jpg',
    );
  }
}
