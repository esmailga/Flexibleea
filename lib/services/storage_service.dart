import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  StorageService({FirebaseStorage? storage}) : _override = storage;

  final FirebaseStorage? _override;

  FirebaseStorage get _storage => _override ?? FirebaseStorage.instance;

  Reference _profileRef(String uid) => _storage.ref('userImages/$uid.jpg');

  Reference _qualificationRef(String uid, String listingId) =>
      _storage.ref('qualifications/$uid/$listingId.pdf');

  Future<String> uploadProfileImage(String uid, File file) async {
    final ref = _profileRef(uid);
    await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }

  Future<String> uploadQualification(
      String uid, String listingId, File file) async {
    final ref = _qualificationRef(uid, listingId);
    await ref.putFile(file, SettableMetadata(contentType: 'application/pdf'));
    return ref.getDownloadURL();
  }

  Future<void> deleteProfileImage(String uid) => _deleteQuietly(_profileRef(uid));

  Future<void> deleteQualification(String uid, String listingId) =>
      _deleteQuietly(_qualificationRef(uid, listingId));

  Future<void> _deleteQuietly(Reference ref) async {
    try {
      await ref.delete();
    } on FirebaseException catch (e) {
      if (e.code != 'object-not-found') rethrow;
    }
  }
}
