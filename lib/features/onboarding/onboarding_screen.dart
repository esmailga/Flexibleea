import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../core/theme/app_theme.dart';
import '../../services/onboarding_store.dart';

class _IntroPage {
  const _IntroPage(this.image, this.eyebrow, this.title, this.body);

  final String image;
  final String eyebrow;
  final String title;
  final String body;
}

const _pages = [
  _IntroPage(
    'assets/images/intro.jpg',
    'WELCOME TO FLEXIBLEEA',
    'Work on your own terms',
    'Set your pay rate, the dates you are free and the hours that suit you.',
  ),
  _IntroPage(
    'assets/images/login.jpg',
    'FREELANCER FIRST',
    'Showcase your expertise',
    'Publish what you are great at, attach your qualifications and get discovered.',
  ),
  _IntroPage(
    'assets/images/signup.jpg',
    'GROW TOGETHER',
    'Recruit, review, repeat',
    'Find the right person fast, send a request in one tap and leave a review.',
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  bool get _isLast => _page == _pages.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await OnboardingStore.markSeen();
    widget.onFinished();
  }

  void _next() {
    if (_isLast) {
      _finish();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          const _AuroraBackground(),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset('assets/icons/logo.png', height: 36),
                      ),
                      const Spacer(),
                      AnimatedOpacity(
                        opacity: _isLast ? 0 : 1,
                        duration: const Duration(milliseconds: 200),
                        child: TextButton(
                          onPressed: _isLast ? null : _finish,
                          child: const Text('Skip'),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: _pages.length,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemBuilder: (context, index) => _ParallaxIllustration(
                      controller: _controller,
                      index: index,
                      image: _pages[index].image,
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppRadii.xl + 4),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.brand.withValues(alpha: 0.08),
                        blurRadius: 30,
                        offset: const Offset(0, -8),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _PageCopy(key: ValueKey(_page), page: _pages[_page]),
                        const SizedBox(height: 28),
                        Row(
                          children: [
                            SmoothPageIndicator(
                              controller: _controller,
                              count: _pages.length,
                              onDotClicked: (i) => _controller.animateToPage(
                                i,
                                duration: const Duration(milliseconds: 450),
                                curve: Curves.easeOutCubic,
                              ),
                              effect: ExpandingDotsEffect(
                                dotHeight: 8,
                                dotWidth: 8,
                                expansionFactor: 3.5,
                                spacing: 6,
                                activeDotColor: scheme.primary,
                                dotColor: scheme.primary.withValues(alpha: 0.2),
                              ),
                            ),
                            const Spacer(),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeOutCubic,
                              width: _isLast ? 168 : 64,
                              height: 64,
                              child: FilledButton(
                                onPressed: _next,
                                style: FilledButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(64, 64),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppRadii.lg),
                                  ),
                                ),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 250),
                                  child: _isLast
                                      ? const Text('Get started',
                                          key: ValueKey('start'), maxLines: 1)
                                      : const Icon(Icons.arrow_forward_rounded,
                                          key: ValueKey('next')),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PageCopy extends StatelessWidget {
  const _PageCopy({super.key, required this.page});

  final _IntroPage page;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          page.eyebrow,
          style: theme.textTheme.labelMedium?.copyWith(
            color: scheme.primary,
            letterSpacing: 1.4,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          page.title,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          page.body,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.45,
          ),
        ),
      ]
          .animate(interval: 70.ms)
          .fadeIn(duration: 350.ms)
          .slideX(begin: 0.08, end: 0, curve: Curves.easeOutCubic),
    );
  }
}

/// Illustration that drifts and scales with the page scroll offset.
class _ParallaxIllustration extends StatelessWidget {
  const _ParallaxIllustration({
    required this.controller,
    required this.index,
    required this.image,
  });

  final PageController controller;
  final int index;
  final String image;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        double offset = 0;
        if (controller.hasClients && controller.position.haveDimensions) {
          offset = (controller.page ?? 0) - index;
        }
        final distance = offset.abs().clamp(0.0, 1.0);
        return Opacity(
          opacity: 1 - distance * 0.6,
          child: Transform.translate(
            offset: Offset(offset * -80, 0),
            child: Transform.scale(scale: 1 - distance * 0.15, child: child),
          ),
        );
      },
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadii.xl),
              boxShadow: [
                BoxShadow(
                  color: AppColors.brand.withValues(alpha: 0.12),
                  blurRadius: 40,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.lg),
              child: Image.asset(image, fit: BoxFit.contain),
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .moveY(begin: -6, end: 6, duration: 2600.ms, curve: Curves.easeInOut),
        ),
      ),
    );
  }
}

/// Soft, slowly drifting colour blobs behind the onboarding content.
class _AuroraBackground extends StatelessWidget {
  const _AuroraBackground();

  @override
  Widget build(BuildContext context) {
    Widget blob(Color color, double size) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color.withValues(alpha: 0.35), color.withValues(alpha: 0)],
            ),
          ),
        );

    return Positioned.fill(
      child: Stack(
        children: [
          Positioned(
            top: -80,
            left: -60,
            child: blob(AppColors.brandLight, 320)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .move(begin: Offset.zero, end: const Offset(40, 30), duration: 6.seconds),
          ),
          Positioned(
            top: 140,
            right: -100,
            child: blob(AppColors.teal, 300)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .move(begin: Offset.zero, end: const Offset(-30, 40), duration: 7.seconds),
          ),
        ],
      ),
    );
  }
}
