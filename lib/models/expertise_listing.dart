import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../core/formatters.dart';
import 'app_user.dart';
import 'parsing.dart';
import 'review.dart';

/// A document in the `Freelancer Expertise` collection.
///
/// Field names are kept compatible with existing data: `expertise` is the
/// title, `recruitment` is "open for requests" and `uploadedBy` is the owner.
class ExpertiseListing {
  const ExpertiseListing({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.ownerImage,
    required this.ownerEmail,
    required this.ownerPhone,
    required this.category,
    required this.title,
    required this.description,
    required this.isOpen,
    required this.requestCount,
    this.availableFrom,
    this.availableTo,
    this.startTime,
    this.endTime,
    this.legacyDate = '',
    this.legacyTime = '',
    this.hourlyRate,
    this.legacyRate = '',
    this.qualificationUrl = '',
    this.createdAt,
    this.legacyReviews = const [],
  });

  factory ExpertiseListing.fromMap(String id, Map<String, dynamic> data) {
    final rawReviews = data['reviews'];
    return ExpertiseListing(
      id: id,
      ownerId: readString(data, 'uploadedBy'),
      ownerName: readString(data, 'name'),
      ownerImage: readString(data, 'userImage'),
      ownerEmail: readString(data, 'email'),
      ownerPhone: readString(data, 'phoneNumber'),
      category: readString(data, 'category'),
      title: readString(data, 'expertise'),
      description: readString(data, 'description'),
      isOpen: readBool(data, 'recruitment'),
      requestCount: readInt(data, 'numberRequests'),
      availableFrom: readDate(data, 'availableFrom'),
      availableTo: readDate(data, 'availableTo'),
      startTime: decodeTime(readOptionalString(data, 'startTime')),
      endTime: decodeTime(readOptionalString(data, 'endTime')),
      legacyDate: cleanLegacyDate(readString(data, 'availableDate')),
      legacyTime: cleanLegacyTime(readString(data, 'availableTime')),
      hourlyRate: readDouble(data, 'hourlyRate') ?? readDouble(data, 'hourlyPayRate'),
      legacyRate: readString(data, 'hourlyPayRate').trim(),
      qualificationUrl: readString(data, 'qualificationUrl'),
      createdAt: readDate(data, 'createdAt'),
      legacyReviews: rawReviews is List
          ? rawReviews
              .whereType<Map>()
              .map((m) => Review.fromLegacyMap(Map<String, dynamic>.from(m)))
              .where((r) => r.body.isNotEmpty)
              .toList()
          : const [],
    );
  }

  factory ExpertiseListing.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      ExpertiseListing.fromMap(doc.id, doc.data() ?? const {});

  final String id;
  final String ownerId;
  final String ownerName;
  final String ownerImage;
  final String ownerEmail;
  final String ownerPhone;
  final String category;
  final String title;
  final String description;
  final bool isOpen;
  final int requestCount;
  final DateTime? availableFrom;
  final DateTime? availableTo;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final String legacyDate;
  final String legacyTime;
  final double? hourlyRate;
  final String legacyRate;
  final String qualificationUrl;
  final DateTime? createdAt;
  final List<Review> legacyReviews;

  String get displayTitle => title.isEmpty ? 'Untitled expertise' : title;

  String get displayOwner => ownerName.isEmpty ? 'Freelancer' : ownerName;

  String get dateLabel {
    if (availableFrom != null && availableTo != null) {
      return formatDateRange(availableFrom!, availableTo!);
    }
    return legacyDate;
  }

  String timeLabel(BuildContext context) {
    if (startTime != null && endTime != null) {
      return formatTimeRange(context, startTime!, endTime!);
    }
    return legacyTime;
  }

  String get rateLabel {
    if (hourlyRate != null) return formatRate(hourlyRate!);
    return legacyRate;
  }

  bool get hasQualification => qualificationUrl.isNotEmpty;

  bool matches({String query = '', String? category}) {
    if (category != null && this.category != category) return false;
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return title.toLowerCase().contains(q) ||
        ownerName.toLowerCase().contains(q) ||
        this.category.toLowerCase().contains(q) ||
        description.toLowerCase().contains(q);
  }
}

/// The editable part of a listing, produced by the listing form.
class ListingDraft {
  const ListingDraft({
    required this.category,
    required this.title,
    required this.description,
    required this.availableFrom,
    required this.availableTo,
    required this.startTime,
    required this.endTime,
    required this.hourlyRate,
    this.qualificationUrl = '',
  });

  final String category;
  final String title;
  final String description;
  final DateTime availableFrom;
  final DateTime availableTo;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final double hourlyRate;
  final String qualificationUrl;

  ListingDraft withQualification(String url) => ListingDraft(
        category: category,
        title: title,
        description: description,
        availableFrom: availableFrom,
        availableTo: availableTo,
        startTime: startTime,
        endTime: endTime,
        hourlyRate: hourlyRate,
        qualificationUrl: url,
      );

  /// Writes structured fields plus the legacy display strings, so older
  /// app versions still render the listing sensibly.
  Map<String, dynamic> toMap() => {
        'category': category,
        'expertise': title.trim(),
        'description': description.trim(),
        'availableFrom': Timestamp.fromDate(availableFrom),
        'availableTo': Timestamp.fromDate(availableTo),
        'startTime': encodeTime(startTime),
        'endTime': encodeTime(endTime),
        'availableDate': formatDateRange(availableFrom, availableTo),
        'availableTime': '${encodeTime(startTime)} – ${encodeTime(endTime)}',
        'hourlyRate': hourlyRate,
        'hourlyPayRate': formatRate(hourlyRate),
        'qualificationUrl': qualificationUrl,
      };

  /// Owner fields copied onto the listing so feeds render without extra reads.
  static Map<String, dynamic> ownerFields(AppUser owner) => {
        'uploadedBy': owner.id,
        'name': owner.name,
        'userImage': owner.imageUrl,
        'email': owner.email,
        'phoneNumber': owner.phoneNumber,
      };
}
