import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/auth_gate.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'services/admin_service.dart';
import 'services/auth_service.dart';
import 'services/expertise_repository.dart';
import 'services/session.dart';
import 'services/storage_service.dart';
import 'services/user_repository.dart';

class FlexibleeaApp extends StatelessWidget {
  const FlexibleeaApp({
    super.key,
    required this.showOnboarding,
    this.auth,
    this.users,
    this.listings,
    this.home,
    this.themeMode = ThemeMode.system,
  });

  final bool showOnboarding;

  /// Optional service overrides (used by tests and the screenshot demo).
  final AuthService? auth;
  final UserRepository? users;
  final ExpertiseRepository? listings;

  /// Optional root widget override; defaults to onboarding / [AuthGate].
  final Widget? home;
  final ThemeMode themeMode;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => auth ?? AuthService()),
        Provider(create: (_) => StorageService()),
        Provider(create: (_) => users ?? UserRepository()),
        Provider(
          create: (c) => listings ?? ExpertiseRepository(storage: c.read<StorageService>()),
        ),
        Provider(
          create: (c) => AdminService(
            users: c.read<UserRepository>(),
            listings: c.read<ExpertiseRepository>(),
            storage: c.read<StorageService>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (c) => Session(
            auth: c.read<AuthService>(),
            users: c.read<UserRepository>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Flexibleea',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: themeMode,
        home: home ?? (showOnboarding ? const _OnboardingThenGate() : const AuthGate()),
      ),
    );
  }
}

class _OnboardingThenGate extends StatelessWidget {
  const _OnboardingThenGate();

  @override
  Widget build(BuildContext context) {
    return OnboardingScreen(
      onFinished: () => Navigator.of(context).pushReplacement(
        PageRouteBuilder<void>(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (_, __, ___) => const AuthGate(),
          transitionsBuilder: (_, animation, __, child) => FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          ),
        ),
      ),
    );
  }
}
