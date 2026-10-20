import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants.dart';
import '../models/app_user.dart';
import '../models/expertise_listing.dart';
import '../models/review.dart';
import 'storage_service.dart';

/// Listings and their reviews.
///
/// Queries only use single-field ordering/filters so they work without any
/// composite indexes; open/closed filtering and sorting happen client side.
class ExpertiseRepository {
  ExpertiseRepository({FirebaseFirestore? firestore, StorageService? storage})
      : _override = firestore,
        _storage = storage ?? StorageService();

  final FirebaseFirestore? _override;
  final StorageService _storage;

  FirebaseFirestore get _db => _override ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _listings =>
      _db.collection(Collections.listings);

  CollectionReference<Map<String, dynamic>> _reviews(String listingId) =>
      _listings.doc(listingId).collection(Collections.reviews);

  String newId() => _listings.doc().id;

  Stream<List<ExpertiseListing>> watchAll({int limit = 300}) => _listings
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((snap) => snap.docs.map(ExpertiseListing.fromDoc).toList());

  Stream<List<ExpertiseListing>> watchOpen() =>
      watchAll().map((all) => all.where((l) => l.isOpen).toList());

  Stream<List<ExpertiseListing>> watchByOwner(String uid) => _listings
      .where('uploadedBy', isEqualTo: uid)
      .snapshots()
      .map((snap) => _newestFirst(snap.docs.map(ExpertiseListing.fromDoc)));

  Future<List<ExpertiseListing>> fetchByOwner(String uid) async {
    final snap = await _listings.where('uploadedBy', isEqualTo: uid).get();
    return snap.docs.map(ExpertiseListing.fromDoc).toList();
  }

  Stream<ExpertiseListing?> watch(String id) => _listings
      .doc(id)
      .snapshots()
      .map((doc) => doc.exists ? ExpertiseListing.fromDoc(doc) : null);

  Future<void> create({
    required String id,
    required AppUser owner,
    required ListingDraft draft,
  }) {
    return _listings.doc(id).set({
      ...draft.toMap(),
      ...ListingDraft.ownerFields(owner),
      'freelancerId': id,
      'recruitment': true,
      'numberRequests': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> update(String id, ListingDraft draft) => _listings.doc(id).update({
        ...draft.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> setOpen(String id, bool open) =>
      _listings.doc(id).update({'recruitment': open});

  Future<void> recordRequest(String id) =>
      _listings.doc(id).update({'numberRequests': FieldValue.increment(1)});

  /// Deletes the listing, its reviews and its qualification document.
  Future<void> delete(ExpertiseListing listing) async {
    final reviews = await _reviews(listing.id).get();
    final batch = _db.batch();
    for (final review in reviews.docs) {
      batch.delete(review.reference);
    }
    batch.delete(_listings.doc(listing.id));
    await batch.commit();
    if (listing.hasQualification) {
      await _storage.deleteQualification(listing.ownerId, listing.id);
    }
  }

  Stream<List<Review>> watchReviews(String listingId) => _reviews(listingId)
      .snapshots()
      .map((snap) => snap.docs.map(Review.fromDoc).toList()
        ..sort((a, b) => (b.createdAt ?? DateTime.now())
            .compareTo(a.createdAt ?? DateTime.now())));

  Future<void> saveReview(String listingId, Review review) =>
      _reviews(listingId).doc(review.authorId).set(review.toMap());

  Future<void> deleteReview(String listingId, String reviewerId) =>
      _reviews(listingId).doc(reviewerId).delete();

  static List<ExpertiseListing> _newestFirst(Iterable<ExpertiseListing> items) {
    final list = items.toList()
      ..sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
    return list;
  }
}
