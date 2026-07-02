import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../bloc/admin/admin_auth_provider.dart';

class AdminShellPage extends ConsumerStatefulWidget {
  final Widget child;
  const AdminShellPage({super.key, required this.child});
  @override
  ConsumerState<AdminShellPage> createState() => _AdminShellPageState();
}

class _AdminShellPageState extends ConsumerState<AdminShellPage> {
  int _selectedIndex = 0;

  final _routes = ['/admin', '/admin/add-entry', '/admin/vehicles', '/admin/settings'];

  void _navigate(int index) {
    setState(() => _selectedIndex = index);
    context.go(_routes[index]);
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out of the admin portal?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Logout')),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(adminAuthProvider.notifier).logout();
    if (mounted) context.go('/admin/login');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isDesktop = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    final navItems = [
      (Icons.dashboard_outlined, Icons.dashboard, l.dashboard),
      (Icons.add_box_outlined, Icons.add_box, l.addEntry),
      (Icons.directions_car_outlined, Icons.directions_car, 'Vehicles'),
      (Icons.settings_outlined, Icons.settings, l.settings),
    ];

    if (isDesktop) {
      return Scaffold(
        body: Row(children: [
          // Sidebar
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _navigate,
            extended: true,
            minExtendedWidth: 200,
            backgroundColor: AppColors.primaryDark,
            selectedIconTheme: const IconThemeData(color: AppColors.white),
            unselectedIconTheme: const IconThemeData(color: AppColors.primaryLighter),
            selectedLabelTextStyle: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w600),
            unselectedLabelTextStyle: const TextStyle(color: AppColors.primaryLighter),
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.agriculture, color: AppColors.white, size: 36),
                  const SizedBox(height: 8),
                  const Text('TerraTrack',
                      style: TextStyle(color: AppColors.white,
                          fontSize: 18, fontWeight: FontWeight.w700)),
                  Text(l.dashboard,
                      style: const TextStyle(color: AppColors.primaryLighter, fontSize: 12)),
                ],
              ),
            ),
            destinations: navItems.map((item) => NavigationRailDestination(
              icon: Icon(item.$1),
              selectedIcon: Icon(item.$2),
              label: Text(item.$3),
            )).toList(),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: IconButton(
                    icon: const Icon(Icons.logout),
                    color: AppColors.primaryLighter,
                    tooltip: 'Logout',
                    onPressed: _logout,
                  ),
                ),
              ),
            ),
          ),
          const VerticalDivider(thickness: 0, width: 0),
          Expanded(child: widget.child),
        ]),
      );
    }

    // Mobile layout
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          const Icon(Icons.agriculture, size: 22),
          const SizedBox(width: 8),
          const Text('TerraTrack Admin'),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Back to client',
            onPressed: () => context.go('/client'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _navigate,
        // Explicit here (rather than relying on the theme) so this bar
        // stays a fixed 4-item strip with visible labels regardless of
        // light/dark theme — with >3 items Flutter otherwise defaults to
        // BottomNavigationBarType.shifting, which hides unselected labels
        // and can make the menu look like it isn't rendering on mobile.
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.grey500,
        items: navItems.map((item) => BottomNavigationBarItem(
          icon: Icon(item.$1),
          activeIcon: Icon(item.$2),
          label: item.$3,
        )).toList(),
      ),
    );
  }
}
