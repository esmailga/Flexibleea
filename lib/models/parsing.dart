import 'package:cloud_firestore/cloud_firestore.dart';

/// Defensive readers for Firestore maps. Older documents are missing fields
/// or store them with different types, so never index a map directly.
String readString(Map<String, dynamic> data, String key) {
  final value = data[key];
  if (value == null) return '';
  return value is String ? value : value.toString();
}

String? readOptionalString(Map<String, dynamic> data, String key) {
  final value = readString(data, key);
  return value.isEmpty ? null : value;
}

bool readBool(Map<String, dynamic> data, String key, {bool fallback = false}) {
  final value = data[key];
  return value is bool ? value : fallback;
}

int readInt(Map<String, dynamic> data, String key) {
  final value = data[key];
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

double? readDouble(Map<String, dynamic> data, String key) {
  final value = data[key];
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim());
  return null;
}

DateTime? readDate(Map<String, dynamic> data, String key) {
  final value = data[key];
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is String) return DateTime.tryParse(value);
  return null;
}
