import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';

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
        ],
      ),
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _navigate,
        items: navItems.map((item) => BottomNavigationBarItem(
          icon: Icon(item.$1),
          activeIcon: Icon(item.$2),
          label: item.$3,
        )).toList(),
      ),
    );
  }
}
