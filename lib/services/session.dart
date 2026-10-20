import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import 'auth_service.dart';
import 'user_repository.dart';

enum SessionStatus { loading, signedOut, needsProfile, member, admin, error }

/// Single source of truth for who is signed in and their profile.
///
/// Replaces the old global `name` / `userImage` / `phone` variables, which
/// were only loaded when a details screen opened and leaked between accounts.
class Session extends ChangeNotifier {
  Session({required AuthService auth, required UserRepository users})
      : _auth = auth,
        _users = users {
    _authSub = _auth.authStateChanges().listen(
          _onAuthChanged,
          onError: (Object e) => _fail(e),
        );
  }

  final AuthService _auth;
  final UserRepository _users;
  StreamSubscription<User?>? _authSub;
  StreamSubscription<AppUser?>? _profileSub;
  int _generation = 0;
  bool _registering = false;

  SessionStatus status = SessionStatus.loading;
  User? user;
  AppUser? profile;
  Object? error;

  String? get uid => user?.uid;
  bool get isAdmin => status == SessionStatus.admin;

  /// While sign-up is still writing the profile, report "loading" instead of
  /// "needs profile" so the complete-profile screen does not flash.
  void beginRegistration() => _registering = true;

  void endRegistration() {
    _registering = false;
    if (user != null && profile == null && status == SessionStatus.loading) {
      _set(SessionStatus.needsProfile);
    }
  }

  Future<void> retry() async => _onAuthChanged(_auth.currentUser);

  Future<void> signOut() => _auth.signOut();

  Future<void> _onAuthChanged(User? next) async {
    final generation = ++_generation;
    await _profileSub?.cancel();
    _profileSub = null;
    error = null;
    user = next;
    profile = null;

    if (next == null) {
      _set(SessionStatus.signedOut);
      return;
    }
    _set(SessionStatus.loading);

    // Refresh the token so a newly granted admin claim applies on next
    // sign-in; fall back to the cached token when offline.
    bool admin = false;
    try {
      admin = await _auth.isAdmin(next, forceRefresh: true);
    } catch (_) {
      try {
        admin = await _auth.isAdmin(next);
      } catch (_) {
        // Claims are best-effort; a member session still works without them.
      }
    }
    if (generation != _generation) return;
    if (admin) {
      _set(SessionStatus.admin);
      return;
    }

    _profileSub = _users.watch(next.uid).listen(
      (p) {
        profile = p;
        if (p != null) {
          _set(SessionStatus.member);
        } else {
          _set(_registering ? SessionStatus.loading : SessionStatus.needsProfile);
        }
      },
      onError: (Object e) => _fail(e),
    );
  }

  void _fail(Object e) {
    error = e;
    _set(SessionStatus.error);
  }

  void _set(SessionStatus next) {
    status = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _profileSub?.cancel();
    super.dispose();
  }
}
