import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../../core/contact.dart';
import '../../core/formatters.dart';
import '../../core/theme/app_theme.dart';
import '../../models/app_user.dart';
import '../../models/expertise_listing.dart';
import '../../services/expertise_repository.dart';
import '../../services/session.dart';
import '../../services/user_repository.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/feedback.dart';
import '../../widgets/listing_card.dart';
import '../../widgets/state_views.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.userId, this.isTab = false});

  final String userId;

  /// True when shown as the "Profile" tab rather than a pushed page.
  final bool isTab;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Stream<AppUser?> _user;
  late Stream<List<ExpertiseListing>> _listings;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  @override
  void didUpdateWidget(ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) _subscribe();
  }

  void _subscribe() {
    _user = context.read<UserRepository>().watch(widget.userId);
    _listings = context.read<ExpertiseRepository>().watchByOwner(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<Session>();
    final isMe = session.uid == widget.userId;

    return Scaffold(
      body: StreamBuilder<AppUser?>(
        stream: _user,
        initialData: isMe ? session.profile : null,
        builder: (context, snapshot) {
          if (snapshot.hasError) return ErrorState(error: snapshot.error!);
          final user = snapshot.data;
          if (user == null) {
            return snapshot.connectionState == ConnectionState.waiting
                ? const Center(child: CircularProgressIndicator())
                : const EmptyState(
                    icon: Icons.person_off_rounded,
                    title: 'Profile not found',
                    message: 'This member may have left Flexibleea.',
                  );
          }
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _Header(user: user, isMe: isMe, showBack: !widget.isTab),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: isMe ? _MyActions(user: user) : _ContactActions(user: user),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: _InfoCard(user: user),
                ),
              ),
              _ListingsSection(stream: _listings, isMe: isMe),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.user, required this.isMe, required this.showBack});

  final AppUser user;
  final bool isMe;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topInset = MediaQuery.paddingOf(context).top;
    const bannerHeight = 150.0;
    const avatarSize = 108.0;

    return Column(
      children: [
        SizedBox(
          height: bannerHeight + topInset + avatarSize / 2,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              Container(
                height: bannerHeight + topInset,
                decoration: const BoxDecoration(
                  gradient: AppColors.heroGradient,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(AppRadii.xl)),
                ),
              ),
              if (showBack)
                Positioned(
                  top: topInset + 4,
                  left: 8,
                  child: IconButton(
                    tooltip: 'Back',
                    color: Colors.white,
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                ),
              Positioned(
                bottom: 0,
                child: AppAvatar(
                  imageUrl: user.imageUrl,
                  name: user.displayName,
                  size: avatarSize,
                  ring: true,
                ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          user.displayName,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ).animate().fadeIn(delay: 150.ms),
        if (user.createdAt != null)
          Text(
            'Member since ${formatMonthYear(user.createdAt!)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ).animate().fadeIn(delay: 220.ms),
      ],
    );
  }
}

class _MyActions extends StatelessWidget {
  const _MyActions({required this.user});

  final AppUser user;

  Future<void> _signOut(BuildContext context) async {
    final ok = await confirmAction(
      context,
      title: 'Sign out?',
      message: 'You can sign back in at any time.',
      confirmLabel: 'Sign out',
    );
    if (ok && context.mounted) await context.read<Session>().signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => EditProfileScreen(existing: user)),
            ),
            icon: const Icon(Icons.edit_rounded),
            label: const Text('Edit profile'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(56)),
            onPressed: () => _signOut(context),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Sign out'),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.2, end: 0);
  }
}

class _ContactActions extends StatelessWidget {
  const _ContactActions({required this.user});

  final AppUser user;

  Future<void> _open(BuildContext context, Uri uri) async {
    final ok = await Contact.open(uri);
    if (!ok && context.mounted) {
      showMessage(context, 'No app available to open this link.', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPhone = user.phoneNumber.isNotEmpty;
    final hasEmail = user.email.isNotEmpty;
    final buttons = [
      _RoundAction(
        icon: FontAwesomeIcons.whatsapp,
        label: 'WhatsApp',
        color: const Color(0xFF25D366),
        onTap: hasPhone
            ? () => _open(context, Contact.whatsApp(user.phoneNumber,
                message: 'Hi ${user.name}, I found you on Flexibleea.'))
            : null,
      ),
      _RoundAction(
        icon: Icons.mail_rounded,
        label: 'Email',
        color: AppColors.brand,
        onTap: hasEmail
            ? () => _open(context, Contact.email(user.email, subject: 'Hello from Flexibleea'))
            : null,
      ),
      _RoundAction(
        icon: Icons.call_rounded,
        label: 'Call',
        color: AppColors.teal,
        onTap: hasPhone ? () => _open(context, Contact.call(user.phoneNumber)) : null,
      ),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: buttons
          .animate(interval: 70.ms)
          .fadeIn(delay: 200.ms)
          .scaleXY(begin: 0.6, curve: Curves.easeOutBack),
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final tint = enabled ? color : Theme.of(context).disabledColor;
    return Column(
      children: [
        Material(
          color: tint.withValues(alpha: 0.12),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Icon(icon, color: tint, size: 26),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final rows = <(IconData, String, String)>[
      if (user.email.isNotEmpty) (Icons.alternate_email_rounded, 'Email', user.email),
      if (user.phoneNumber.isNotEmpty) (Icons.phone_rounded, 'Phone', user.phoneNumber),
    ];
    if (rows.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          children: [
            for (final (icon, label, value) in rows)
              ListTile(
                leading: Icon(icon, color: scheme.primary),
                title: Text(label, style: Theme.of(context).textTheme.labelMedium),
                subtitle: Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0);
  }
}

class _ListingsSection extends StatelessWidget {
  const _ListingsSection({required this.stream, required this.isMe});

  final Stream<List<ExpertiseListing>> stream;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<List<ExpertiseListing>>(
      stream: stream,
      builder: (context, snapshot) {
        final listings = (snapshot.data ?? const <ExpertiseListing>[])
            .where((l) => isMe || l.isOpen)
            .toList();
        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
          sliver: SliverList.list(
            children: [
              Row(
                children: [
                  Text(
                    isMe ? 'My listings' : 'Listings',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(width: 8),
                  if (snapshot.hasData)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('${listings.length}',
                          style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              if (snapshot.hasError)
                ErrorState(error: snapshot.error!)
              else if (!snapshot.hasData)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (listings.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    isMe
                        ? 'You have not published any expertise yet. Tap "Offer expertise" on Explore to start.'
                        : 'No open listings right now.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              else
                for (final (i, listing) in listings.indexed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: ListingCard(listing: listing, showStatus: isMe)
                        .animate(key: ValueKey(listing.id))
                        .fadeIn(delay: (i < 6 ? i * 60 : 0).ms)
                        .slideY(begin: 0.1, end: 0),
                  ),
            ],
          ),
        );
      },
    );
  }
}
