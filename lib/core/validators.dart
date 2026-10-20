/// Form field validators. Each returns an error message, or null when valid.
abstract final class Validators {
  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _phoneChars = RegExp(r'^[0-9+()\-\s]+$');

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Enter your email';
    if (!_email.hasMatch(v)) return 'Enter a valid email address';
    return null;
  }

  static String? password(String? value) {
    if ((value ?? '').trim().length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  static String? name(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Enter your name';
    if (v.length > 80) return 'Name is too long';
    return null;
  }

  static String? phone(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Enter your phone number';
    final digits = v.replaceAll(RegExp(r'[^0-9]'), '').length;
    if (!_phoneChars.hasMatch(v) || digits < 7 || digits > 15) {
      return 'Enter a valid phone number, e.g. +60 12 345 6789';
    }
    return null;
  }

  static String? required(String? value, {String message = 'Required'}) {
    return (value?.trim() ?? '').isEmpty ? message : null;
  }

  static String? minLength(String? value, int min, String label) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Enter a $label';
    if (v.length < min) return '${_capitalize(label)} needs at least $min characters';
    return null;
  }

  static String? hourlyRate(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Enter your hourly rate';
    final rate = double.tryParse(v);
    if (rate == null || rate <= 0) return 'Enter a positive number';
    if (rate > 100000) return 'That rate looks too high';
    return null;
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
