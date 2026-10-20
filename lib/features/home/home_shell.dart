import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/session.dart';
import '../../widgets/fade_indexed_stack.dart';
import '../explore/explore_screen.dart';
import '../people/people_screen.dart';
import '../profile/profile_screen.dart';

/// Member app shell. Tabs keep their state (scroll position, search text)
/// instead of being rebuilt with pushReplacement on every tap.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late int _index = widget.initialIndex;

  @override
  Widget build(BuildContext context) {
    final uid = context.select<Session, String?>((s) => s.uid) ?? '';
    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _index = 0);
      },
      child: Scaffold(
        body: FadeIndexedStack(
          index: _index,
          children: [
            ExploreScreen(onOpenProfile: () => setState(() => _index = 2)),
            const PeopleScreen(),
            ProfileScreen(userId: uid, isTab: true),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.explore_outlined),
              selectedIcon: Icon(Icons.explore_rounded),
              label: 'Explore',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_alt_outlined),
              selectedIcon: Icon(Icons.people_alt_rounded),
              label: 'People',
            ),
            NavigationDestination(
              icon: Icon(Icons.account_circle_outlined),
              selectedIcon: Icon(Icons.account_circle_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
