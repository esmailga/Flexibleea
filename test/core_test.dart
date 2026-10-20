import 'package:firebase_auth/firebase_auth.dart';
import 'package:flexibleea/core/contact.dart';
import 'package:flexibleea/core/errors.dart';
import 'package:flexibleea/core/formatters.dart';
import 'package:flexibleea/core/validators.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators', () {
    test('email', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('nope'), isNotNull);
      expect(Validators.email('a@b'), isNotNull);
      expect(Validators.email(' a@b.co '), isNull);
    });

    test('password', () {
      expect(Validators.password('short'), isNotNull);
      expect(Validators.password('long enough'), isNull);
    });

    test('phone', () {
      expect(Validators.phone(''), isNotNull);
      expect(Validators.phone('12345'), isNotNull);
      expect(Validators.phone('abc1234567'), isNotNull);
      expect(Validators.phone('+60 12-345 6789'), isNull);
    });

    test('hourly rate', () {
      expect(Validators.hourlyRate(''), isNotNull);
      expect(Validators.hourlyRate('0'), isNotNull);
      expect(Validators.hourlyRate('abc'), isNotNull);
      expect(Validators.hourlyRate('45.5'), isNull);
    });

    test('min length', () {
      expect(Validators.minLength('', 7, 'review'), 'Enter a review');
      expect(Validators.minLength('short', 7, 'review'), contains('at least 7'));
      expect(Validators.minLength('long enough', 7, 'review'), isNull);
    });
  });

  group('Formatters', () {
    test('time encoding round-trips', () {
      const t = TimeOfDay(hour: 7, minute: 5);
      expect(encodeTime(t), '07:05');
      expect(decodeTime('07:05'), t);
      expect(decodeTime('25:00'), isNull);
      expect(decodeTime('TimeOfDay(09:00)'), isNull);
    });

    test('rates', () {
      expect(formatRate(45), 'SAR 45/hr');
      expect(formatRate(45.5), 'SAR 45.50/hr');
    });

    test('initials', () {
      expect(initialsOf('alex tan lee'), 'AT');
      expect(initialsOf('  '), '?');
    });

    test('relative time', () {
      final now = DateTime(2026, 1, 10, 12);
      expect(timeAgo(now.subtract(const Duration(seconds: 10)), now: now), 'just now');
      expect(timeAgo(now.subtract(const Duration(hours: 3)), now: now), '3h ago');
      expect(timeAgo(now.subtract(const Duration(days: 2)), now: now), '2d ago');
    });
  });

  group('Contact links', () {
    test('WhatsApp strips formatting and encodes the message', () {
      final uri = Contact.whatsApp('+60 12-345', message: 'Hi there');
      expect(uri.toString(), 'https://wa.me/6012345?text=Hi%20there');
    });

    test('mailto encodes spaces as %20', () {
      final uri = Contact.email('a@b.com', subject: 'Hello world');
      expect(uri.toString(), 'mailto:a@b.com?subject=Hello%20world');
    });

    test('tel keeps a leading plus', () {
      expect(Contact.call('+60 12 345').toString(), 'tel:+6012345');
    });
  });

  group('describeError', () {
    test('maps auth codes to friendly text', () {
      expect(
        describeError(FirebaseAuthException(code: 'invalid-credential')),
        'Incorrect email or password.',
      );
      expect(
        describeError(FirebaseAuthException(code: 'email-already-in-use')),
        contains('already exists'),
      );
    });

    test('never leaks raw exceptions', () {
      expect(describeError(StateError('boom')), 'Something went wrong. Please try again.');
    });
  });
}
