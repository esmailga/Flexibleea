import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'constants.dart';

final _dayMonth = DateFormat('d MMM');
final _dayMonthYear = DateFormat('d MMM yyyy');
final _monthYear = DateFormat('MMMM yyyy');

String formatDate(DateTime date) => _dayMonthYear.format(date);

String formatMonthYear(DateTime date) => _monthYear.format(date);

String formatDateRange(DateTime start, DateTime end) {
  if (start.year == end.year) {
    return '${_dayMonth.format(start)} – ${_dayMonthYear.format(end)}';
  }
  return '${_dayMonthYear.format(start)} – ${_dayMonthYear.format(end)}';
}

String formatAmount(double amount) => amount == amount.roundToDouble()
    ? amount.toStringAsFixed(0)
    : amount.toStringAsFixed(2);

/// Plain-text rate, stored on listings for older app versions. The UI shows
/// rates with the riyal sign via `RiyalAmount` instead.
String formatRate(double rate) => '$kCurrencySymbol${formatAmount(rate)}/hr';

/// Times are stored as 24h "HH:mm" strings so they are locale independent.
String encodeTime(TimeOfDay time) =>
    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

TimeOfDay? decodeTime(String? value) {
  if (value == null) return null;
  final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(value.trim());
  if (match == null) return null;
  final hour = int.parse(match.group(1)!);
  final minute = int.parse(match.group(2)!);
  if (hour > 23 || minute > 59) return null;
  return TimeOfDay(hour: hour, minute: minute);
}

String formatTimeRange(BuildContext context, TimeOfDay start, TimeOfDay end) {
  final l = MaterialLocalizations.of(context);
  return '${l.formatTimeOfDay(start)} – ${l.formatTimeOfDay(end)}';
}

/// Older listings stored placeholder text such as "Select available date"
/// and raw `TimeOfDay(09:00)` strings. These helpers make them presentable.
String cleanLegacyDate(String value) {
  final v = value.trim();
  if (_isPlaceholder(v)) return '';
  return v.replaceAll(RegExp(r'\s+To\s+'), ' – ');
}

String cleanLegacyTime(String value) {
  final v = value.trim();
  if (_isPlaceholder(v)) return '';
  return v.replaceAllMapped(
    RegExp(r'TimeOfDay\((\d{1,2}:\d{2})\)'),
    (m) => m.group(1)!,
  );
}

bool _isPlaceholder(String v) =>
    v.isEmpty || v.startsWith('Select') || v.startsWith('Choose') || v == 'Date';

String initialsOf(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
  if (parts.isEmpty) return '?';
  final letters = parts.take(2).map((p) => p.characters.first.toUpperCase());
  return letters.join();
}

String timeAgo(DateTime date, {DateTime? now}) {
  final diff = (now ?? DateTime.now()).difference(date);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inDays < 1) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return formatDate(date);
}

String greetingFor(DateTime now) {
  if (now.hour < 12) return 'Good morning';
  if (now.hour < 18) return 'Good afternoon';
  return 'Good evening';
}
