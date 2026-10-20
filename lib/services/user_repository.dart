import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants.dart';
import '../models/app_user.dart';

class UserRepository {
  UserRepository({FirebaseFirestore? firestore}) : _override = firestore;

  final FirebaseFirestore? _override;

  FirebaseFirestore get _db => _override ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection(Collections.users);

  CollectionReference<Map<String, dynamic>> get _listings =>
      _db.collection(Collections.listings);

  Stream<AppUser?> watch(String uid) => _users
      .doc(uid)
      .snapshots()
      .map((doc) => doc.exists ? AppUser.fromDoc(doc) : null);

  Stream<List<AppUser>> watchAll() => _users.snapshots().map((snap) {
        final users = snap.docs.map(AppUser.fromDoc).toList()
          ..sort((a, b) =>
              a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
        return users;
      });

  Future<void> create(AppUser user) => _users.doc(user.id).set({
        ...user.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });

  /// Saves the profile and refreshes the owner details copied onto the
  /// user's listings, so feeds show the new name and photo.
  Future<void> update(AppUser user) async {
    final batch = _db.batch()..update(_users.doc(user.id), user.toMap());
    final owned = await _listings.where('uploadedBy', isEqualTo: user.id).get();
    for (final doc in owned.docs) {
      batch.update(doc.reference, {
        'name': user.name,
        'userImage': user.imageUrl,
        'phoneNumber': user.phoneNumber,
        'email': user.email,
      });
    }
    await batch.commit();
  }

  Future<void> delete(String uid) => _users.doc(uid).delete();
}
