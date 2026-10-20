// In-memory stand-ins for the Firebase-backed services, used only by the
// screenshot demo build. They serve the same freelancers that
// tool/admin/demo-data.mjs seeds into Firestore.
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flexibleea/models/app_user.dart';
import 'package:flexibleea/models/expertise_listing.dart';
import 'package:flexibleea/models/review.dart';
import 'package:flexibleea/services/auth_service.dart';
import 'package:flexibleea/services/expertise_repository.dart';
import 'package:flexibleea/services/user_repository.dart';

import 'demo_data.g.dart';

const viewerId = 'demo-viewer';

class DemoUser implements User {
  DemoUser(this.uid, this.email);

  @override
  final String uid;

  @override
  final String? email;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class DemoAuth extends AuthService {
  DemoAuth({required this.signedIn, this.admin = false});

  final bool signedIn;
  final bool admin;

  @override
  Stream<User?> authStateChanges() =>
      Stream.value(signedIn ? DemoUser(admin ? 'demo-admin' : viewerId, 'yousef@example.com') : null);

  @override
  User? get currentUser => null;

  @override
  Future<bool> isAdmin(User user, {bool forceRefresh = false}) async => admin;

  @override
  Future<void> signIn({required String email, required String password}) async {}
}

class DemoData {
  DemoData(String avatarBase) {
    final json = jsonDecode(demoFreelancersJson) as Map<String, dynamic>;
    final today = DateTime.now();
    DateTime day(int offset) => DateTime(today.year, today.month, today.day + offset);
    String avatar(String id) => '$avatarBase/$id.jpg';

    final freelancers = (json['freelancers'] as List).cast<Map<String, dynamic>>();
    for (final (i, f) in freelancers.indexed) {
      final id = f['id'] as String;
      final email = '${id.replaceFirst('demo-', '')}@example.com';
      users[id] = AppUser(
        id: id,
        name: f['name'] as String,
        email: email,
        phoneNumber: '',
        imageUrl: avatar(id),
        createdAt: day(-(400 - i * 30)),
      );
      final from = day(f['startDay'] as int);
      final to = day((f['startDay'] as int) + (f['lengthDays'] as int));
      listings.add(ExpertiseListing.fromMap('$id-listing', {
        'uploadedBy': id,
        'name': f['name'],
        'userImage': avatar(id),
        'email': email,
        'phoneNumber': '',
        'category': f['category'],
        'expertise': f['title'],
        'description': f['description'],
        'availableFrom': from,
        'availableTo': to,
        'startTime': f['startTime'],
        'endTime': f['endTime'],
        'hourlyRate': f['hourlyRate'],
        'recruitment': true,
        'numberRequests': f['requests'],
        'createdAt': day(-(20 - i * 2)),
      }));
    }

    for (final (i, r) in (json['reviews'] as List).cast<Map<String, dynamic>>().indexed) {
      final author = users[r['author']]!;
      reviews.putIfAbsent('${r['listing']}-listing', () => []).add(Review(
            id: author.id,
            authorId: author.id,
            authorName: author.name,
            authorImage: author.imageUrl,
            body: r['body'] as String,
            rating: r['rating'] as int,
            createdAt: today.subtract(Duration(days: i + 1, hours: i * 3)),
          ));
    }

    users[viewerId] = AppUser(
      id: viewerId,
      name: 'Yousef Al-Shammari',
      email: 'yousef@example.com',
      phoneNumber: '+966 5X XXX XXXX',
      imageUrl: '',
      createdAt: day(-90),
    );
    listings.sort((a, b) => b.createdAt!.compareTo(a.createdAt!));
  }

  final users = <String, AppUser>{};
  final listings = <ExpertiseListing>[];
  final reviews = <String, List<Review>>{};
}

class DemoUsers extends UserRepository {
  DemoUsers(this.data);

  final DemoData data;

  @override
  Stream<AppUser?> watch(String uid) => Stream.value(data.users[uid]);

  @override
  Stream<List<AppUser>> watchAll() => Stream.value(
      data.users.values.where((u) => u.id != viewerId).toList()
        ..sort((a, b) => a.name.compareTo(b.name)));

  @override
  Future<void> update(AppUser user) async {}

  @override
  Future<void> create(AppUser user) async {}
}

class DemoListings extends ExpertiseRepository {
  DemoListings(this.data);

  final DemoData data;

  @override
  Stream<List<ExpertiseListing>> watchAll({int limit = 300}) => Stream.value(data.listings);

  @override
  Stream<List<ExpertiseListing>> watchOpen() => watchAll();

  @override
  Stream<List<ExpertiseListing>> watchByOwner(String uid) =>
      Stream.value(data.listings.where((l) => l.ownerId == uid).toList());

  @override
  Stream<ExpertiseListing?> watch(String id) =>
      Stream.value(data.listings.where((l) => l.id == id).firstOrNull);

  @override
  Stream<List<Review>> watchReviews(String listingId) =>
      Stream.value(data.reviews[listingId] ?? const []);
}
