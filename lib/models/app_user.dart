import 'package:cloud_firestore/cloud_firestore.dart';

import 'parsing.dart';

/// A profile document in the `Users` collection.
class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.imageUrl,
    this.createdAt,
  });

  factory AppUser.fromMap(String id, Map<String, dynamic> data) {
    return AppUser(
      id: id,
      name: readString(data, 'name').trim(),
      email: readString(data, 'email').trim(),
      phoneNumber: readString(data, 'phoneNumber').trim(),
      imageUrl: readString(data, 'userImage').trim(),
      createdAt: readDate(data, 'createdAt'),
    );
  }

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      AppUser.fromMap(doc.id, doc.data() ?? const {});

  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final String imageUrl;
  final DateTime? createdAt;

  String get displayName => name.isEmpty ? 'Unnamed member' : name;

  /// Fields written to Firestore (createdAt is set by the server on create).
  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'email': email,
        'phoneNumber': phoneNumber,
        'userImage': imageUrl,
      };

  AppUser copyWith({String? name, String? phoneNumber, String? imageUrl}) {
    return AppUser(
      id: id,
      name: name ?? this.name,
      email: email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt,
    );
  }

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return name.toLowerCase().contains(q) || email.toLowerCase().contains(q);
  }
}
