import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/validators.dart';
import '../../models/app_user.dart';
import '../../services/admin_service.dart';
import '../../services/user_repository.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/feedback.dart';
import '../../widgets/search_field.dart';
import '../../widgets/skeleton.dart';
import '../../widgets/state_views.dart';
import '../profile/profile_screen.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  late Stream<List<AppUser>> _stream = context.read<UserRepository>().watchAll();
  String _query = '';
  final Set<String> _busy = {};

  Future<void> _rename(AppUser user) async {
    final controller = TextEditingController(text: user.name);
    final formKey = GlobalKey<FormState>();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename member'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            validator: Validators.name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Full name'),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(88, 44)),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, controller.text.trim());
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name == user.name || !mounted) return;
    await _run(user.id, () => context.read<AdminService>().renameUser(user, name), 'Member renamed');
  }

  Future<void> _delete(AppUser user) async {
    final ok = await confirmAction(
      context,
      title: 'Delete ${user.displayName}?',
      message: 'Their profile, listings, reviews on those listings and photo will be removed. '
          'Disable or delete the sign-in account itself in the Firebase console.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok || !mounted) return;
    await _run(user.id, () => context.read<AdminService>().deleteUser(user.id), 'Member deleted');
  }

  Future<void> _run(String id, Future<void> Function() action, String done) async {
    setState(() => _busy.add(id));
    try {
      await action();
      if (mounted) showMessage(context, done);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
          child: SearchField(
            hint: 'Search members',
            onChanged: (q) => setState(() => _query = q),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<AppUser>>(
            stream: _stream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return ErrorState(
                  error: snapshot.error!,
                  onRetry: () => setState(
                      () => _stream = context.read<UserRepository>().watchAll()),
                );
              }
              if (!snapshot.hasData) return const SkeletonList();
              final users = snapshot.data!.where((u) => u.matches(_query)).toList();
              if (users.isEmpty) {
                return const EmptyState(icon: Icons.group_off_rounded, title: 'No members found');
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                itemCount: users.length + 1,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  if (i == 0) {
                    return Text('${snapshot.data!.length} members',
                        style: Theme.of(context).textTheme.labelLarge);
                  }
                  final user = users[i - 1];
                  final busy = _busy.contains(user.id);
                  return Card(
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      contentPadding: const EdgeInsets.fromLTRB(16, 6, 4, 6),
                      leading: AppAvatar(imageUrl: user.imageUrl, name: user.displayName),
                      title: Text(user.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(user.email, maxLines: 1, overflow: TextOverflow.ellipsis),
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => ProfileScreen(userId: user.id))),
                      trailing: busy
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox.square(
                                  dimension: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2.5)),
                            )
                          : PopupMenuButton<String>(
                              tooltip: 'Actions',
                              onSelected: (v) => v == 'rename' ? _rename(user) : _delete(user),
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: 'rename',
                                  child: ListTile(
                                    leading: Icon(Icons.edit_rounded),
                                    title: Text('Rename'),
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: ListTile(
                                    leading: Icon(Icons.delete_outline_rounded, color: Colors.red),
                                    title: Text('Delete'),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  )
                      .animate(key: ValueKey(user.id))
                      .fadeIn(delay: (i < 10 ? i * 35 : 0).ms)
                      .slideX(begin: 0.05, end: 0);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
