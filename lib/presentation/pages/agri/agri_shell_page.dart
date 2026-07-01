// lib/presentation/pages/agri/agri_shell_page.dart
//
// Bottom-navigation shell for the agri module's 4 main screens (Lands,
// Workers, Work Entries, Expenses & Harvests). Styled after the existing
// lib/presentation/pages/client/main_tab_page.dart shell pattern, but a
// separate widget so the existing vehicle/work-log shell is never touched.
// The current tab is derived from the active GoRouter location (rather than
// internal State) so deep links and the system back button keep the
// bottom-nav indicator in sync.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../bloc/agri/agri_auth_provider.dart';

class AgriShellPage extends ConsumerWidget {
  final Widget child;
  const AgriShellPage({super.key, required this.child});

  static const _routes = [
    '/agri/lands',
    '/agri/workers',
    '/agri/work-entries',
    '/agri/expenses-harvests',
    '/agri/vehicles',
  ];

  int _indexForLocation(String location) {
    for (var i = _routes.length - 1; i >= 0; i--) {
      if (location.startsWith(_routes[i])) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _indexForLocation(location);
    final agriAuth = ref.watch(agriAuthProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.agriModuleTitle, style: const TextStyle(fontSize: 16)),
            if (agriAuth.user?.email != null)
              Text(
                agriAuth.user!.email!,
                style: const TextStyle(fontSize: 12, color: AppColors.primaryLighter),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: l.agriSignOut,
            onPressed: () async {
              await ref.read(agriAuthProvider.notifier).signOut();
              if (context.mounted) context.go('/agri/login');
            },
          ),
        ],
      ),
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => context.go(_routes[index]),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.terrain_outlined),
            activeIcon: const Icon(Icons.terrain),
            label: l.lands,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.groups_outlined),
            activeIcon: const Icon(Icons.groups),
            label: l.workers,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.work_outline),
            activeIcon: const Icon(Icons.work),
            label: l.agriWorkEntries,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.receipt_long_outlined),
            activeIcon: const Icon(Icons.receipt_long),
            label: l.expensesAndHarvests,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.directions_car_outlined),
            activeIcon: const Icon(Icons.directions_car),
            label: l.vehicles,
          ),
        ],
      ),
    );
  }
}
