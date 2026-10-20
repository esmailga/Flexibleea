import '../models/app_user.dart';
import 'expertise_repository.dart';
import 'storage_service.dart';
import 'user_repository.dart';

/// Moderation actions. Every call is authorised by the `admin` custom claim
/// in the security rules, not by anything on the client.
class AdminService {
  AdminService({
    required UserRepository users,
    required ExpertiseRepository listings,
    required StorageService storage,
  })  : _users = users,
        _listings = listings,
        _storage = storage;

  final UserRepository _users;
  final ExpertiseRepository _listings;
  final StorageService _storage;

  /// Removes a member's profile, listings (with their reviews and files) and
  /// profile photo. The Firebase Auth account itself can only be deleted from
  /// the Firebase console or the Admin SDK.
  Future<void> deleteUser(String uid) async {
    for (final listing in await _listings.fetchByOwner(uid)) {
      await _listings.delete(listing);
    }
    await _users.delete(uid);
    await _storage.deleteProfileImage(uid);
  }

  Future<void> renameUser(AppUser user, String name) =>
      _users.update(user.copyWith(name: name.trim()));
}
