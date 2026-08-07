import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../discover/discover_screen.dart';
import '../profile/profile_screen.dart';
import '../tickets/tickets_screen.dart';

/// Hosts the three main screens behind Eventix's bottom navigation bar.
/// Event detail is pushed on top of this shell, not part of it.
///
/// Each screen keeps its own [Scaffold]; this shell only owns the
/// [NavigationBar] and which screen is visible. Using [IndexedStack] keeps
/// every tab's scroll position and state alive when switching between
/// them. The selected index lives in [rootTabIndexProvider] rather than
/// local state, so screens pushed on top of this shell (like the ticket
/// confirmation screen) can switch tabs before popping back.
class RootShell extends ConsumerWidget {
  const RootShell({super.key});

  static const List<Widget> _screens = <Widget>[
    DiscoverScreen(),
    TicketsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(rootTabIndexProvider);

    return Scaffold(
      body: IndexedStack(
        index: selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) => ref.read(rootTabIndexProvider.notifier).state = index,
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Discover',
          ),
          NavigationDestination(
            icon: Icon(Icons.confirmation_number_outlined),
            selectedIcon: Icon(Icons.confirmation_number),
            label: 'My Tickets',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
