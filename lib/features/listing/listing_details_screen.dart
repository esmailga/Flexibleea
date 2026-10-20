import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/contact.dart';
import '../../core/theme/app_theme.dart';
import '../../models/expertise_listing.dart';
import '../../models/review.dart';
import '../../services/expertise_repository.dart';
import '../../services/session.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/feedback.dart';
import '../../widgets/riyal.dart';
import '../../widgets/state_views.dart';
import '../profile/profile_screen.dart';
import 'listing_form_screen.dart';
import 'reviews_section.dart';

class ListingDetailsScreen extends StatefulWidget {
  const ListingDetailsScreen({super.key, required this.listingId, this.initial});

  final String listingId;

  /// Data already on screen (e.g. from the feed) to render immediately.
  final ExpertiseListing? initial;

  @override
  State<ListingDetailsScreen> createState() => _ListingDetailsScreenState();
}

class _ListingDetailsScreenState extends State<ListingDetailsScreen> {
  late final ExpertiseRepository _repo = context.read<ExpertiseRepository>();
  late final Stream<ExpertiseListing?> _listing = _repo.watch(widget.listingId);
  late final Stream<List<Review>> _reviews = _repo.watchReviews(widget.listingId);
  bool _busy = false;

  Future<void> _toggleOpen(ExpertiseListing listing, bool open) async {
    try {
      await _repo.setOpen(listing.id, open);
      if (mounted) {
        showMessage(context, open ? 'Listing is open for requests' : 'Listing paused');
      }
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> _delete(ExpertiseListing listing) async {
    final ok = await confirmAction(
      context,
      title: 'Delete listing?',
      message: '"${listing.displayTitle}" and its reviews will be removed permanently.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok || !mounted) return;
    final navigator = Navigator.of(context);
    setState(() => _busy = true);
    try {
      await _repo.delete(listing);
      if (mounted) showMessage(context, 'Listing deleted');
      navigator.pop();
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showError(context, e);
      }
    }
  }

  Future<void> _request(ExpertiseListing listing) async {
    final session = context.read<Session>();
    final me = session.profile;
    final opened = await Contact.open(Contact.email(
      listing.ownerEmail,
      subject: 'Request: ${listing.displayTitle} (via Flexibleea)',
      body: 'Hi ${listing.displayOwner},\n\n'
          'I found your "${listing.displayTitle}" listing on Flexibleea and would like to work with you.\n\n'
          '${me == null ? '' : 'Best regards,\n${me.name}\n${me.phoneNumber}'}',
    ));
    if (!mounted) return;
    if (!opened) {
      showMessage(context, 'No email app found. Reach out on ${listing.ownerEmail}.',
          isError: true);
      return;
    }
    try {
      await _repo.recordRequest(listing.id);
    } catch (_) {
      // The email is what matters; the counter is best-effort.
    }
  }

  void _showContactSheet(ExpertiseListing listing) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(FontAwesomeIcons.whatsapp, color: Color(0xFF25D366)),
                title: const Text('WhatsApp'),
                subtitle: Text(listing.ownerPhone),
                enabled: listing.ownerPhone.isNotEmpty,
                onTap: () {
                  Navigator.pop(ctx);
                  Contact.open(Contact.whatsApp(listing.ownerPhone,
                      message: 'Hi ${listing.displayOwner}, I saw "${listing.displayTitle}" on Flexibleea.'));
                },
              ),
              ListTile(
                leading: const Icon(Icons.call_rounded, color: AppColors.teal),
                title: const Text('Call'),
                subtitle: Text(listing.ownerPhone),
                enabled: listing.ownerPhone.isNotEmpty,
                onTap: () {
                  Navigator.pop(ctx);
                  Contact.open(Contact.call(listing.ownerPhone));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<Session>();
    return StreamBuilder<ExpertiseListing?>(
      stream: _listing,
      initialData: widget.initial,
      builder: (context, snapshot) {
        final listing = snapshot.data;
        if (listing == null) {
          return Scaffold(
            appBar: AppBar(),
            body: snapshot.hasError
                ? ErrorState(error: snapshot.error!)
                : snapshot.connectionState == ConnectionState.waiting
                    ? const Center(child: CircularProgressIndicator())
                    : const EmptyState(
                        icon: Icons.inventory_2_outlined,
                        title: 'Listing removed',
                        message: 'This listing is no longer available.',
                      ),
          );
        }

        final isOwner = session.uid == listing.ownerId;
        final isAdmin = session.isAdmin;
        final canRequest = !isOwner && !isAdmin;

        return Scaffold(
          bottomNavigationBar: canRequest
              ? _RequestBar(
                  listing: listing,
                  onRequest: () => _request(listing),
                  onContact: () => _showContactSheet(listing),
                )
              : null,
          body: StreamBuilder<List<Review>>(
            stream: _reviews,
            builder: (context, reviewSnap) {
              final reviews = [...?reviewSnap.data, ...listing.legacyReviews];
              final average = Review.averageRating(reviews);
              return CustomScrollView(
                slivers: [
                  _HeroAppBar(
                    listing: listing,
                    actions: [
                      if (isOwner)
                        IconButton(
                          tooltip: 'Edit listing',
                          onPressed: _busy
                              ? null
                              : () => Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => ListingFormScreen(existing: listing))),
                          icon: const Icon(Icons.edit_rounded),
                        ),
                      if (isOwner || isAdmin)
                        IconButton(
                          tooltip: 'Delete listing',
                          onPressed: _busy ? null : () => _delete(listing),
                          icon: const Icon(Icons.delete_outline_rounded),
                        ),
                    ],
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                    sliver: SliverList.list(
                      children: [
                        _OwnerRow(listing: listing),
                        const SizedBox(height: 18),
                        _StatsRow(
                          requests: listing.requestCount,
                          listing: listing,
                          rating: average,
                          reviewCount: reviews.length,
                        ),
                        if (isOwner) ...[
                          const SizedBox(height: 16),
                          Card(
                            child: SwitchListTile(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppRadii.lg),
                              ),
                              secondary: Icon(
                                listing.isOpen
                                    ? Icons.campaign_rounded
                                    : Icons.pause_circle_outline_rounded,
                                color: listing.isOpen ? AppColors.success : null,
                              ),
                              title: const Text('Open for requests',
                                  style: TextStyle(fontWeight: FontWeight.w700)),
                              subtitle: Text(listing.isOpen
                                  ? 'Visible on Explore'
                                  : 'Hidden from Explore'),
                              value: listing.isOpen,
                              onChanged: (v) => _toggleOpen(listing, v),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        _Section(
                          title: 'About',
                          icon: Icons.notes_rounded,
                          child: Text(
                            listing.description.isEmpty
                                ? 'No description provided.'
                                : listing.description,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(height: 1.5),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _AvailabilityCard(listing: listing),
                        if (listing.hasQualification) ...[
                          const SizedBox(height: 16),
                          Card(
                            child: ListTile(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppRadii.lg),
                              ),
                              leading: const Icon(Icons.picture_as_pdf_rounded,
                                  color: Colors.redAccent),
                              title: const Text('Qualification',
                                  style: TextStyle(fontWeight: FontWeight.w700)),
                              subtitle: const Text('Open the attached PDF'),
                              trailing: const Icon(Icons.open_in_new_rounded),
                              onTap: () =>
                                  Contact.open(Uri.parse(listing.qualificationUrl)),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        ReviewsSection(
                          listing: listing,
                          reviews: reviews,
                          loading: !reviewSnap.hasData && !reviewSnap.hasError,
                          average: average,
                          canWrite: canRequest && session.profile != null,
                        ),
                      ]
                          .animate(interval: 50.ms)
                          .fadeIn(duration: 350.ms)
                          .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _HeroAppBar extends StatelessWidget {
  const _HeroAppBar({required this.listing, required this.actions});

  final ExpertiseListing listing;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SliverAppBar(
      pinned: true,
      stretch: true,
      expandedHeight: 230,
      foregroundColor: Colors.white,
      backgroundColor: AppColors.brand,
      actions: actions,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground, StretchMode.fadeTitle],
        titlePadding: const EdgeInsetsDirectional.only(start: 56, end: 96, bottom: 16),
        title: Text(
          listing.displayTitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        background: DecoratedBox(
          decoration: const BoxDecoration(gradient: AppColors.heroGradient),
          child: Stack(
            children: [
              Positioned(
                right: -30,
                top: 30,
                child: Icon(
                  iconForCategory(listing.category),
                  size: 200,
                  color: Colors.white.withValues(alpha: 0.1),
                )
                    .animate()
                    .rotate(begin: -0.05, end: 0, duration: 800.ms)
                    .fadeIn(duration: 800.ms),
              ),
              if (listing.category.isNotEmpty)
                Positioned(
                  left: 20,
                  top: MediaQuery.paddingOf(context).top + kToolbarHeight + 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(iconForCategory(listing.category),
                            size: 16, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          listing.category,
                          style: theme.textTheme.labelLarge?.copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.2, end: 0),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OwnerRow extends StatelessWidget {
  const _OwnerRow({required this.listing});

  final ExpertiseListing listing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: listing.ownerId.isEmpty
            ? null
            : () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ProfileScreen(userId: listing.ownerId))),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              AppAvatar(imageUrl: listing.ownerImage, name: listing.displayOwner, size: 54, ring: true),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(listing.displayOwner,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                    Text('View profile',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.requests,
    required this.listing,
    required this.rating,
    required this.reviewCount,
  });

  final int requests;
  final ExpertiseListing listing;
  final double? rating;
  final int reviewCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            icon: Icons.how_to_reg_rounded,
            color: AppColors.brand,
            label: 'Requests',
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: requests.toDouble()),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => Text(v.round().toString()),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            icon: Icons.payments_rounded,
            color: AppColors.teal,
            label: 'Rate',
            child: FittedBox(fit: BoxFit.scaleDown, child: RateText(listing: listing)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            icon: Icons.star_rounded,
            color: AppColors.amber,
            label: reviewCount == 1 ? '1 review' : '$reviewCount reviews',
            child: Text(rating == null ? '—' : rating!.toStringAsFixed(1)),
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.child,
  });

  final IconData icon;
  final Color color;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 6),
            DefaultTextStyle.merge(
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              child: child,
            ),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.icon, required this.child});

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _AvailabilityCard extends StatelessWidget {
  const _AvailabilityCard({required this.listing});

  final ExpertiseListing listing;

  @override
  Widget build(BuildContext context) {
    final date = listing.dateLabel;
    final time = listing.timeLabel(context);
    Widget row(IconData icon, Color color, String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: Theme.of(context).textTheme.labelMedium),
                    Text(
                      value.isEmpty ? 'Not specified' : value,
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

    return _Section(
      title: 'Availability',
      icon: Icons.event_available_rounded,
      child: Column(
        children: [
          row(Icons.date_range_rounded, AppColors.teal, 'Dates', date),
          row(Icons.schedule_rounded, AppColors.amber, 'Hours', time),
        ],
      ),
    );
  }
}

class _RequestBar extends StatelessWidget {
  const _RequestBar({
    required this.listing,
    required this.onRequest,
    required this.onContact,
  });

  final ExpertiseListing listing;
  final VoidCallback onRequest;
  final VoidCallback onContact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            IconButton.filledTonal(
              tooltip: 'Contact',
              iconSize: 26,
              padding: const EdgeInsets.all(14),
              onPressed: listing.ownerPhone.isEmpty ? null : onContact,
              icon: const Icon(Icons.chat_bubble_outline_rounded),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: listing.isOpen ? onRequest : null,
                icon: Icon(listing.isOpen ? Icons.send_rounded : Icons.pause_rounded),
                label: Text(listing.isOpen ? 'Request freelancer' : 'Currently unavailable'),
              ),
            ),
          ],
        ),
      ),
    ).animate().slideY(begin: 1, end: 0, duration: 450.ms, curve: Curves.easeOutCubic);
  }
}
