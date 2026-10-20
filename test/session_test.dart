import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flexibleea/models/app_user.dart';
import 'package:flexibleea/services/auth_service.dart';
import 'package:flexibleea/services/session.dart';
import 'package:flexibleea/services/user_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeUser extends Fake implements User {
  _FakeUser(this.uid);

  @override
  final String uid;
}

class _FakeAuth extends AuthService {
  final controller = StreamController<User?>.broadcast();
  final admins = <String>{};

  @override
  Stream<User?> authStateChanges() => controller.stream;

  @override
  Future<bool> isAdmin(User user, {bool forceRefresh = false}) async =>
      admins.contains(user.uid);
}

class _FakeUsers extends UserRepository {
  final profiles = <String, StreamController<AppUser?>>{};

  StreamController<AppUser?> profileFor(String uid) =>
      profiles.putIfAbsent(uid, () => StreamController<AppUser?>.broadcast());

  @override
  Stream<AppUser?> watch(String uid) => profileFor(uid).stream;
}

AppUser _profile(String id) =>
    AppUser(id: id, name: 'Alex', email: 'a@b.com', phoneNumber: '', imageUrl: '');

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  late _FakeAuth auth;
  late _FakeUsers users;
  late Session session;

  setUp(() {
    auth = _FakeAuth();
    users = _FakeUsers();
    session = Session(auth: auth, users: users);
  });

  tearDown(() => session.dispose());

  test('starts loading, then signed out', () async {
    expect(session.status, SessionStatus.loading);
    auth.controller.add(null);
    await _settle();
    expect(session.status, SessionStatus.signedOut);
  });

  test('member with a profile becomes ready', () async {
    auth.controller.add(_FakeUser('u1'));
    await _settle();
    users.profileFor('u1').add(_profile('u1'));
    await _settle();
    expect(session.status, SessionStatus.member);
    expect(session.profile?.name, 'Alex');
  });

  test('member without a profile must complete it', () async {
    auth.controller.add(_FakeUser('u1'));
    await _settle();
    users.profileFor('u1').add(null);
    await _settle();
    expect(session.status, SessionStatus.needsProfile);
  });

  test('registration suppresses the complete-profile flash', () async {
    session.beginRegistration();
    auth.controller.add(_FakeUser('u1'));
    await _settle();
    users.profileFor('u1').add(null);
    await _settle();
    expect(session.status, SessionStatus.loading);

    users.profileFor('u1').add(_profile('u1'));
    await _settle();
    session.endRegistration();
    expect(session.status, SessionStatus.member);
  });

  test('admin claim routes to the admin console', () async {
    auth.admins.add('boss');
    auth.controller.add(_FakeUser('boss'));
    await _settle();
    await _settle();
    expect(session.status, SessionStatus.admin);
    expect(session.isAdmin, isTrue);
  });

  test('switching accounts never leaks the previous profile', () async {
    auth.controller.add(_FakeUser('u1'));
    await _settle();
    users.profileFor('u1').add(_profile('u1'));
    await _settle();
    expect(session.profile?.id, 'u1');

    auth.controller.add(_FakeUser('u2'));
    await _settle();
    expect(session.profile, isNull);
    users.profileFor('u1').add(_profile('u1')); // stale stream must be ignored
    await _settle();
    expect(session.profile, isNull);
  });
}
