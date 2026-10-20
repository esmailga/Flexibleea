import 'package:cloud_firestore/cloud_firestore.dart';

import 'parsing.dart';

/// A review of a listing. New reviews live in the `reviews` subcollection,
/// keyed by the reviewer's uid. Legacy reviews were stored in an array on the
/// listing document and have no rating.
class Review {
  const Review({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorImage,
    required this.body,
    this.rating,
    this.createdAt,
    this.isLegacy = false,
  });

  factory Review.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    final rating = readInt(data, 'rating');
    return Review(
      id: doc.id,
      authorId: readString(data, 'authorId'),
      authorName: readString(data, 'authorName'),
      authorImage: readString(data, 'authorImage'),
      body: readString(data, 'body'),
      rating: rating >= 1 && rating <= 5 ? rating : null,
      createdAt: readDate(data, 'createdAt'),
    );
  }

  factory Review.fromLegacyMap(Map<String, dynamic> data) {
    return Review(
      id: readString(data, 'reviewId'),
      authorId: readString(data, 'Id'),
      authorName: readString(data, 'name'),
      authorImage: readString(data, 'userImageUrl'),
      body: readString(data, 'reviewBody'),
      createdAt: readDate(data, 'time'),
      isLegacy: true,
    );
  }

  final String id;
  final String authorId;
  final String authorName;
  final String authorImage;
  final String body;
  final int? rating;
  final DateTime? createdAt;
  final bool isLegacy;

  Map<String, dynamic> toMap() => {
        'authorId': authorId,
        'authorName': authorName,
        'authorImage': authorImage,
        'body': body,
        'rating': rating ?? 5,
        'createdAt': FieldValue.serverTimestamp(),
      };

  static double? averageRating(Iterable<Review> reviews) {
    final rated = reviews.where((r) => r.rating != null).toList();
    if (rated.isEmpty) return null;
    return rated.fold<int>(0, (total, r) => total + r.rating!) / rated.length;
  }
}
