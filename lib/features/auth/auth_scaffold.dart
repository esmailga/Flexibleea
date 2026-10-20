import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_theme.dart';

/// Shared layout for sign-in, sign-up and password reset: a gradient hero
/// with the floating logo, and a rounded sheet that slides up with the form.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.header,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  /// Optional widget shown in the hero instead of the logo (e.g. photo slot).
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canPop = Navigator.of(context).canPop();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.brandDeep,
        body: Stack(
          children: [
            const Positioned.fill(child: _HeroBackground()),
            SafeArea(
              bottom: false,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                      child: SizedBox(
                        height: 48,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: canPop
                              ? IconButton(
                                  tooltip: 'Back',
                                  color: Colors.white,
                                  onPressed: () => Navigator.of(context).maybePop(),
                                  icon: const Icon(Icons.arrow_back_rounded),
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                      child: Center(
                        child: header ??
                            ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Image.asset('assets/icons/logo.png', width: 210),
                            )
                                .animate()
                                .fadeIn(duration: 500.ms)
                                .scaleXY(begin: 0.85, curve: Curves.easeOutBack)
                                .animate(onPlay: (c) => c.repeat(reverse: true))
                                .moveY(begin: 0, end: -6, duration: 2.seconds, curve: Curves.easeInOut),
                      ),
                    ),
                  ),
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Container(
                      padding: EdgeInsets.fromLTRB(
                          24, 32, 24, 24 + MediaQuery.paddingOf(context).bottom),
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(AppRadii.xl + 4),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            subtitle,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 28),
                          ...children,
                        ]
                            .animate(interval: 45.ms)
                            .fadeIn(duration: 380.ms, delay: 120.ms)
                            .slideY(begin: 0.15, end: 0, curve: Curves.easeOutCubic),
                      ),
                    )
                        .animate()
                        .slideY(begin: 0.25, end: 0, duration: 550.ms, curve: Curves.easeOutCubic),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroBackground extends StatelessWidget {
  const _HeroBackground();

  @override
  Widget build(BuildContext context) {
    Widget orb(double size, Color color) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        );

    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.heroGradient),
      child: Stack(
        children: [
          Positioned(
            top: -60,
            right: -40,
            child: orb(220, Colors.white.withValues(alpha: 0.07))
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(begin: 1, end: 1.15, duration: 4.seconds, curve: Curves.easeInOut),
          ),
          Positioned(
            top: 120,
            left: -70,
            child: orb(180, AppColors.teal.withValues(alpha: 0.18))
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .moveX(begin: 0, end: 30, duration: 5.seconds, curve: Curves.easeInOut),
          ),
        ],
      ),
    );
  }
}

/// Password field with a show/hide toggle.
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    this.label = 'Password',
    this.validator,
    this.textInputAction = TextInputAction.done,
    this.onSubmitted,
    this.autofillHints = const [AutofillHints.password],
  });

  final TextEditingController controller;
  final String label;
  final FormFieldValidator<String>? validator;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String> autofillHints;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscure,
      validator: widget.validator,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onSubmitted,
      autofillHints: widget.autofillHints,
      keyboardType: TextInputType.visiblePassword,
      decoration: InputDecoration(
        labelText: widget.label,
        prefixIcon: const Icon(Icons.lock_outline_rounded),
        suffixIcon: IconButton(
          tooltip: _obscure ? 'Show password' : 'Hide password',
          onPressed: () => setState(() => _obscure = !_obscure),
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, a) => RotationTransition(
              turns: Tween(begin: 0.75, end: 1.0).animate(a),
              child: FadeTransition(opacity: a, child: child),
            ),
            child: Icon(
              _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              key: ValueKey(_obscure),
            ),
          ),
        ),
      ),
    );
  }
}
