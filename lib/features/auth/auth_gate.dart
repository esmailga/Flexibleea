import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/session.dart';
import '../../widgets/state_views.dart';
import '../admin/admin_shell.dart';
import '../home/home_shell.dart';
import '../profile/edit_profile_screen.dart';
import 'login_screen.dart';

/// Chooses the root screen from the session state, with a fade-through
/// transition whenever it changes.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Session _session;
  SessionStatus? _previous;

  @override
  void initState() {
    super.initState();
    _session = context.read<Session>();
    _previous = _session.status;
    _session.addListener(_onSessionChanged);
  }

  @override
  void dispose() {
    _session.removeListener(_onSessionChanged);
    super.dispose();
  }

  /// On sign-out, drop any pushed pages so they cannot outlive the session.
  void _onSessionChanged() {
    final status = _session.status;
    if (status == SessionStatus.signedOut && _previous != SessionStatus.signedOut) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
    _previous = status;
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<Session>();
    final Widget child = switch (session.status) {
      SessionStatus.loading => const SplashView(key: ValueKey('loading')),
      SessionStatus.signedOut => const LoginScreen(key: ValueKey('login')),
      SessionStatus.needsProfile =>
        const EditProfileScreen(key: ValueKey('complete-profile')),
      SessionStatus.member => const HomeShell(key: ValueKey('home')),
      SessionStatus.admin => const AdminShell(key: ValueKey('admin')),
      SessionStatus.error => Scaffold(
          key: const ValueKey('error'),
          body: ErrorState(
            error: session.error ?? 'Unknown error',
            onRetry: session.retry,
          ),
        ),
    };

    return PageTransitionSwitcher(
      duration: const Duration(milliseconds: 450),
      transitionBuilder: (child, primary, secondary) => FadeThroughTransition(
        animation: primary,
        secondaryAnimation: secondary,
        child: child,
      ),
      child: child,
    );
  }
}
