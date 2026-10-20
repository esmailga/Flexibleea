import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../models/app_user.dart';
import '../../services/session.dart';
import '../../services/user_repository.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/search_field.dart';
import '../../widgets/skeleton.dart';
import '../../widgets/state_views.dart';
import '../profile/profile_screen.dart';

class PeopleScreen extends StatefulWidget {
  const PeopleScreen({super.key});

  @override
  State<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends State<PeopleScreen> {
  late Stream<List<AppUser>> _stream;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _stream = context.read<UserRepository>().watchAll();
  }

  @override
  Widget build(BuildContext context) {
    final myId = context.select<Session, String?>((s) => s.uid);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            const SliverAppBar.medium(title: Text('People'), pinned: true),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: SearchField(
                  hint: 'Search by name or email',
                  onChanged: (q) => setState(() => _query = q),
                ),
              ),
            ),
            StreamBuilder<List<AppUser>>(
              stream: _stream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: ErrorState(
                      error: snapshot.error!,
                      onRetry: () => setState(() =>
                          _stream = context.read<UserRepository>().watchAll()),
                    ),
                  );
                }
                if (!snapshot.hasData) return const SkeletonList(sliver: true);

                final people = snapshot.data!
                    .where((u) => u.id != myId && u.matches(_query))
                    .toList();
                if (people.isEmpty) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.person_search_rounded,
                      title: 'Nobody found',
                      message: 'Try another name.',
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  sliver: SliverList.separated(
                    itemCount: people.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => _PersonTile(user: people[i])
                        .animate(key: ValueKey(people[i].id))
                        .fadeIn(duration: 300.ms, delay: (i < 10 ? i * 40 : 0).ms)
                        .slideX(begin: 0.06, end: 0, curve: Curves.easeOutCubic),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PersonTile extends StatelessWidget {
  const _PersonTile({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: AppAvatar(imageUrl: user.imageUrl, name: user.displayName, size: 48),
        title: Text(
          user.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          user.createdAt == null
              ? 'Member'
              : 'Member since ${formatMonthYear(user.createdAt!)}',
          style: theme.textTheme.bodySmall,
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ProfileScreen(userId: user.id)),
        ),
      ),
    );
  }
}
