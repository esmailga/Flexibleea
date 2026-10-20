import 'package:flutter/material.dart';

/// Firestore collection names. These match the data already in production,
/// including the legacy space in "Freelancer Expertise".
abstract final class Collections {
  static const users = 'Users';
  static const listings = 'Freelancer Expertise';
  static const reviews = 'reviews';
}

/// Plain-text currency prefix for stored rate strings and other text-only
/// contexts. On screen, rates use the official riyal sign (see widgets/riyal.dart).
const kCurrencySymbol = 'SAR ';

class ExpertiseCategory {
  const ExpertiseCategory(this.name, this.icon);

  final String name;
  final IconData icon;
}

const kCategories = <ExpertiseCategory>[
  ExpertiseCategory('Development & Programming', Icons.code_rounded),
  ExpertiseCategory('Arts & Design', Icons.palette_rounded),
  ExpertiseCategory('Marketing', Icons.campaign_rounded),
  ExpertiseCategory('Business', Icons.business_center_rounded),
  ExpertiseCategory('Information Technology', Icons.dns_rounded),
  ExpertiseCategory('Education & Training', Icons.school_rounded),
  ExpertiseCategory('Accounting', Icons.calculate_rounded),
  ExpertiseCategory('Architecture & Construction', Icons.architecture_rounded),
  ExpertiseCategory('Medical', Icons.medical_services_rounded),
];

IconData iconForCategory(String category) {
  for (final c in kCategories) {
    if (c.name == category) return c.icon;
  }
  return Icons.work_outline_rounded;
}
