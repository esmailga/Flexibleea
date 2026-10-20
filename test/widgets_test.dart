import 'package:flexibleea/core/theme/app_theme.dart';
import 'package:flexibleea/features/auth/login_screen.dart';
import 'package:flexibleea/features/onboarding/onboarding_screen.dart';
import 'package:flexibleea/services/auth_service.dart';
import 'package:flexibleea/widgets/riyal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RecordingAuth extends AuthService {
  String? email;
  String? password;

  @override
  Future<void> signIn({required String email, required String password}) async {
    this.email = email;
    this.password = password;
  }
}

Widget _app(Widget child, {AuthService? auth}) => Provider<AuthService>.value(
      value: auth ?? _RecordingAuth(),
      child: MaterialApp(theme: AppTheme.light(useGoogleFonts: false), home: child),
    );

/// The UI uses looping animations, so pumpAndSettle would never finish.
Future<void> _pumpFor(WidgetTester tester, [int ms = 1500]) async {
  for (var i = 0; i < ms ~/ 100; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  group('LoginScreen', () {
    testWidgets('validates before calling Firebase', (tester) async {
      final auth = _RecordingAuth();
      await tester.pumpWidget(_app(const LoginScreen(), auth: auth));
      await _pumpFor(tester);

      await tester.ensureVisible(find.byKey(const Key('login-submit')));
      await tester.tap(find.byKey(const Key('login-submit')));
      await _pumpFor(tester, 300);

      expect(find.text('Enter your email'), findsOneWidget);
      expect(find.text('Password must be at least 8 characters'), findsOneWidget);
      expect(auth.email, isNull);
    });

    testWidgets('signs in with normalised input', (tester) async {
      final auth = _RecordingAuth();
      await tester.pumpWidget(_app(const LoginScreen(), auth: auth));
      await _pumpFor(tester);

      await tester.enterText(find.byKey(const Key('login-email')), 'Alex@Example.com');
      await tester.enterText(
        find.descendant(of: find.byKey(const Key('login-password')), matching: find.byType(EditableText)),
        'supersecret',
      );
      await tester.ensureVisible(find.byKey(const Key('login-submit')));
      await tester.tap(find.byKey(const Key('login-submit')));
      await _pumpFor(tester, 500);

      expect(auth.email, 'Alex@Example.com'); // AuthService lowercases internally
      expect(auth.password, 'supersecret');
    });
  });

  group('OnboardingScreen', () {
    testWidgets('pages forward and remembers completion', (tester) async {
      SharedPreferences.setMockInitialValues({});
      var finished = false;
      await tester.pumpWidget(_app(OnboardingScreen(onFinished: () => finished = true)));
      await _pumpFor(tester);

      expect(find.text('Work on your own terms'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.arrow_forward_rounded));
      await _pumpFor(tester, 1000);
      expect(find.text('Showcase your expertise'), findsOneWidget);

      await tester.tap(find.text('Skip'));
      await _pumpFor(tester, 500);
      expect(finished, isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('onboarding_seen_v1'), isTrue);
    });
  });

  group('RiyalAmount', () {
    testWidgets('draws the riyal sign at numeral height and reads naturally', (tester) async {
      await tester.pumpWidget(_app(const Scaffold(
        body: Center(child: RiyalAmount(amount: 220, style: TextStyle(fontSize: 20))),
      )));

      final sign = tester.getSize(find.byType(RiyalSymbol));
      expect(sign.height, closeTo(20 * RiyalAmount.signHeight, 0.01));
      expect(sign.width, closeTo(sign.height * RiyalSymbol.aspectRatio, 0.01));
      expect(find.bySemanticsLabel('220 Saudi riyals per hour'), findsOneWidget);
    });
  });
}
