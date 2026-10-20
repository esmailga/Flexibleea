import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/formatters.dart';
import '../../core/theme/app_theme.dart';
import '../../models/expertise_listing.dart';
import '../../services/expertise_repository.dart';
import '../../services/session.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/listing_card.dart';
import '../../widgets/search_field.dart';
import '../../widgets/skeleton.dart';
import '../../widgets/state_views.dart';
import '../listing/listing_form_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key, this.onOpenProfile});

  final VoidCallback? onOpenProfile;

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  late Stream<List<ExpertiseListing>> _stream;
  String _query = '';
  String? _category;

  @override
  void initState() {
    super.initState();
    _stream = context.read<ExpertiseRepository>().watchOpen();
  }

  void _retry() =>
      setState(() => _stream = context.read<ExpertiseRepository>().watchOpen());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = context.watch<Session>().profile;

    return Scaffold(
      floatingActionButton: _NewListingButton(),
      body: SafeArea(
        bottom: false,
        child: StreamBuilder<List<ExpertiseListing>>(
          stream: _stream,
          builder: (context, snapshot) {
            final all = snapshot.data ?? const <ExpertiseListing>[];
            final visible =
                all.where((l) => l.matches(query: _query, category: _category)).toList();

            return CustomScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                greetingFor(DateTime.now()),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                profile?.name.split(' ').first ?? 'there',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: widget.onOpenProfile,
                          child: Semantics(
                            button: true,
                            label: 'Open my profile',
                            child: AppAvatar(
                              imageUrl: profile?.imageUrl ?? '',
                              name: profile?.name ?? '',
                              size: 48,
                              ring: true,
                            ),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(duration: 350.ms).slideX(begin: -0.05, end: 0),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                    child: _HeroBanner(count: snapshot.hasData ? all.length : null),
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _FilterHeaderDelegate(
                    background: theme.scaffoldBackgroundColor,
                    child: _Filters(
                      category: _category,
                      onQuery: (q) => setState(() => _query = q),
                      onCategory: (c) => setState(() => _category = c),
                    ),
                  ),
                ),
                if (snapshot.hasError)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: ErrorState(error: snapshot.error!, onRetry: _retry),
                  )
                else if (!snapshot.hasData)
                  const SkeletonList(sliver: true)
                else if (visible.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: all.isEmpty ? Icons.rocket_launch_rounded : Icons.search_off_rounded,
                      title: all.isEmpty ? 'No listings yet' : 'No matches',
                      message: all.isEmpty
                          ? 'Be the first to offer your expertise.'
                          : 'Try a different search or category.',
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 110),
                    sliver: SliverList.separated(
                      itemCount: visible.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, i) {
                        final listing = visible[i];
                        return ListingCard(key: ValueKey(listing.id), listing: listing)
                            .animate(key: ValueKey('anim-${listing.id}'))
                            .fadeIn(duration: 350.ms, delay: (i < 8 ? i * 60 : 0).ms)
                            .slideY(begin: 0.12, end: 0, curve: Curves.easeOutCubic);
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.count});

  final int? count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Find flexible talent',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    count == null
                        ? 'Loading freelancers…'
                        : '$count ${count == 1 ? 'freelancer is' : 'freelancers are'} open for work',
                    key: ValueKey(count),
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 30),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(begin: 1, end: 1.08, duration: 1200.ms, curve: Curves.easeInOut),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 80.ms).slideY(begin: 0.1, end: 0);
  }
}

class _Filters extends StatelessWidget {
  const _Filters({required this.category, required this.onQuery, required this.onCategory});

  final String? category;
  final ValueChanged<String> onQuery;
  final ValueChanged<String?> onCategory;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
          child: SearchField(hint: 'Search skills, people, categories', onChanged: onQuery),
        ),
        SizedBox(
          height: 42,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              _CategoryChip(
                label: 'All',
                icon: Icons.apps_rounded,
                selected: category == null,
                onTap: () => onCategory(null),
              ),
              for (final c in kCategories)
                _CategoryChip(
                  label: c.name,
                  icon: c.icon,
                  selected: category == c.name,
                  onTap: () => onCategory(category == c.name ? null : c.name),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: selected,
        onSelected: (_) => onTap(),
        avatar: Icon(icon, size: 18, color: selected ? scheme.onPrimary : scheme.primary),
        label: Text(label),
        labelStyle: TextStyle(
          color: selected ? scheme.onPrimary : scheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        selectedColor: scheme.primary,
      ),
    );
  }
}

class _FilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  _FilterHeaderDelegate({required this.child, required this.background});

  final Widget child;
  final Color background;

  static const _height = 132.0;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: background,
        boxShadow: overlapsContent || shrinkOffset > 0
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : const [],
      ),
      child: child,
    );
  }

  @override
  bool shouldRebuild(_FilterHeaderDelegate oldDelegate) =>
      oldDelegate.child != child || oldDelegate.background != background;
}

class _NewListingButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return OpenContainer(
      transitionType: ContainerTransitionType.fadeThrough,
      transitionDuration: const Duration(milliseconds: 500),
      closedElevation: 6,
      closedColor: scheme.primary,
      openColor: Theme.of(context).scaffoldBackgroundColor,
      closedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md + 2)),
      openBuilder: (_, __) => const ListingFormScreen(),
      closedBuilder: (_, open) => InkWell(
        onTap: open,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, color: scheme.onPrimary),
              const SizedBox(width: 8),
              Text(
                'Offer expertise',
                style: TextStyle(color: scheme.onPrimary, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    ).animate().scale(delay: 400.ms, duration: 400.ms, curve: Curves.easeOutBack);
  }
}
