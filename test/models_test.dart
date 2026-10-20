import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flexibleea/models/app_user.dart';
import 'package:flexibleea/models/expertise_listing.dart';
import 'package:flexibleea/models/review.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExpertiseListing', () {
    test('parses a legacy document written by the old app', () {
      final listing = ExpertiseListing.fromMap('abc', {
        'freelancerId': 'abc',
        'uploadedBy': 'u1',
        'email': 'a@b.com',
        'category': 'Marketing',
        'expertise': 'SEO audits',
        'description': 'I audit sites',
        'availableDate': '2024/5/1  To  2024/5/30',
        'availableTime': 'TimeOfDay(09:00) - TimeOfDay(17:00)',
        'hourlyPayRate': '45',
        'reviews': [
          {
            'Id': 'u2',
            'reviewId': 'r1',
            'name': 'Sam',
            'userImageUrl': '',
            'reviewBody': 'Great work!',
            'time': Timestamp.fromDate(DateTime(2024, 5, 2)),
          },
        ],
        'recruitment': true,
        'createdAt': Timestamp.fromDate(DateTime(2024, 4, 1)),
        'name': 'Alex',
        'userImage': 'https://example.com/a.jpg',
        'phoneNumber': '0123',
        'numberRequests': 3,
      });

      expect(listing.ownerId, 'u1');
      expect(listing.title, 'SEO audits');
      expect(listing.isOpen, isTrue);
      expect(listing.requestCount, 3);
      expect(listing.dateLabel, '2024/5/1 – 2024/5/30');
      expect(listing.legacyTime, '09:00 - 17:00');
      expect(listing.hourlyRate, 45);
      expect(listing.rateLabel, 'SAR 45/hr');
      expect(listing.legacyReviews, hasLength(1));
      expect(listing.legacyReviews.single.body, 'Great work!');
      expect(listing.legacyReviews.single.isLegacy, isTrue);
    });

    test('hides placeholder text left by the old form', () {
      final listing = ExpertiseListing.fromMap('x', {
        'availableDate': 'Select available date',
        'availableTime': 'Choose Available time',
      });
      expect(listing.dateLabel, isEmpty);
      expect(listing.legacyTime, isEmpty);
    });

    test('tolerates missing fields and wrong types', () {
      final listing = ExpertiseListing.fromMap('x', {
        'numberRequests': '7',
        'recruitment': 'yes',
        'reviews': 'not a list',
      });
      expect(listing.displayTitle, 'Untitled expertise');
      expect(listing.displayOwner, 'Freelancer');
      expect(listing.requestCount, 7);
      expect(listing.isOpen, isFalse);
      expect(listing.legacyReviews, isEmpty);
      expect(listing.rateLabel, isEmpty);
    });

    test('draft round-trips structured availability fields', () {
      final draft = ListingDraft(
        category: 'Business',
        title: '  Consulting ',
        description: ' Strategy ',
        availableFrom: DateTime(2026, 1, 5),
        availableTo: DateTime(2026, 2, 5),
        startTime: const TimeOfDay(hour: 9, minute: 30),
        endTime: const TimeOfDay(hour: 17, minute: 0),
        hourlyRate: 80,
      );
      final listing = ExpertiseListing.fromMap('id', {
        ...draft.toMap(),
        'recruitment': true,
      });
      expect(listing.title, 'Consulting');
      expect(listing.description, 'Strategy');
      expect(listing.startTime, const TimeOfDay(hour: 9, minute: 30));
      expect(listing.endTime, const TimeOfDay(hour: 17, minute: 0));
      expect(listing.availableFrom, DateTime(2026, 1, 5));
      expect(listing.hourlyRate, 80);
      expect(listing.dateLabel, '5 Jan – 5 Feb 2026');
    });

    test('matches search query and category', () {
      final listing = ExpertiseListing.fromMap('x', {
        'expertise': 'Logo design',
        'name': 'Rina',
        'category': 'Arts & Design',
      });
      expect(listing.matches(query: 'logo'), isTrue);
      expect(listing.matches(query: 'RINA'), isTrue);
      expect(listing.matches(query: 'python'), isFalse);
      expect(listing.matches(category: 'Arts & Design'), isTrue);
      expect(listing.matches(category: 'Medical'), isFalse);
    });
  });

  group('AppUser', () {
    test('parses and serialises using the legacy field names', () {
      final user = AppUser.fromMap('u1', {
        'id': 'u1',
        'name': ' Alex Tan ',
        'email': 'alex@example.com',
        'phoneNumber': '+60123',
        'userImage': 'https://example.com/a.jpg',
      });
      expect(user.name, 'Alex Tan');
      expect(user.toMap(), {
        'id': 'u1',
        'name': 'Alex Tan',
        'email': 'alex@example.com',
        'phoneNumber': '+60123',
        'userImage': 'https://example.com/a.jpg',
      });
      expect(user.matches('tan'), isTrue);
      expect(user.matches('zzz'), isFalse);
    });

    test('falls back gracefully for empty documents', () {
      final user = AppUser.fromMap('u1', const {});
      expect(user.displayName, 'Unnamed member');
      expect(user.imageUrl, isEmpty);
    });
  });

  group('Review', () {
    test('averages only rated reviews', () {
      const reviews = [
        Review(id: '1', authorId: 'a', authorName: '', authorImage: '', body: 'x', rating: 5),
        Review(id: '2', authorId: 'b', authorName: '', authorImage: '', body: 'x', rating: 3),
        Review(id: '3', authorId: 'c', authorName: '', authorImage: '', body: 'x', isLegacy: true),
      ];
      expect(Review.averageRating(reviews), 4);
      expect(Review.averageRating(const []), isNull);
    });
  });
}
