import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/session.dart';
import '../../widgets/fade_indexed_stack.dart';
import '../../widgets/feedback.dart';
import 'admin_listings_screen.dart';
import 'admin_users_screen.dart';

/// Moderation console, shown to accounts with the `admin` custom claim.
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  Future<void> _signOut() async {
    final ok = await confirmAction(
      context,
      title: 'Sign out?',
      message: 'You will leave the admin console.',
      confirmLabel: 'Sign out',
    );
    if (ok && mounted) await context.read<Session>().signOut();
  }

  @override
  Widget build(BuildContext context) {
    final email = context.select<Session, String?>((s) => s.user?.email) ?? '';
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Admin console'),
            Text(email, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: _signOut,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: FadeIndexedStack(
        index: _index,
        children: const [AdminUsersScreen(), AdminListingsScreen()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.group_outlined),
            selectedIcon: Icon(Icons.group_rounded),
            label: 'Members',
          ),
          NavigationDestination(
            icon: Icon(Icons.view_list_outlined),
            selectedIcon: Icon(Icons.view_list_rounded),
            label: 'Listings',
          ),
        ],
      ),
    );
  }
}
