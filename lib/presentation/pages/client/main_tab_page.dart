import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../bloc/auth/auth_provider.dart';

class MainTabPage extends ConsumerStatefulWidget {
  final Widget child;
  const MainTabPage({super.key, required this.child});
  @override
  ConsumerState<MainTabPage> createState() => _MainTabPageState();
}

class _MainTabPageState extends ConsumerState<MainTabPage> {
  int _currentIndex = 0;

  static const _routes = ['/client', '/client/new-entry'];

  void _onTap(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
    context.go(_routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final session = ref.watch(authProvider).session;

    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: _EntryAppBar(
        appName: 'TerraTrack',
        vehicleName: session?.vehicleName,
        onSettings: () => context.go('/client/settings'),
        onLogout: () async {
          await ref.read(authProvider.notifier).logout();
          if (mounted) context.go('/login');
        },
      ),
      body: widget.child,
      bottomNavigationBar: _EntryBottomNav(
        currentIndex: _currentIndex,
        onTap: _onTap,
        items: [
          _NavItemData(
            icon: Icons.list_alt_rounded,
            activeIcon: Icons.list_alt_rounded,
            label: l.workLogs,
          ),
          _NavItemData(
            icon: Icons.add_circle_outline_rounded,
            activeIcon: Icons.add_circle_rounded,
            label: l.newEntry,
          ),
        ],
      ),
    );
  }
}

/// Dark, rounded header matching the TerraTrack Entry mockup: app name +
/// vehicle name on the left, two rounded icon tiles (settings / logout) on
/// the right.
class _EntryAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String appName;
  final String? vehicleName;
  final VoidCallback onSettings;
  final VoidCallback onLogout;

  const _EntryAppBar({
    required this.appName,
    required this.vehicleName,
    required this.onSettings,
    required this.onLogout,
  });

  @override
  Size get preferredSize => const Size.fromHeight(92);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.entryHeaderTop, AppColors.entryHeaderBottom],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      appName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.entryTextPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (vehicleName != null && vehicleName!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          vehicleName!,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.entryAccentDark,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              _NavIconTile(icon: Icons.settings_rounded, onTap: onSettings),
              const SizedBox(width: 8),
              _NavIconTile(icon: Icons.logout_rounded, onTap: onLogout),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavIconTile extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavIconTile({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.entryIconTileBg,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: AppColors.entryTextMuted, size: 22),
        ),
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItemData({required this.icon, required this.activeIcon, required this.label});
}

/// Dark bottom navigation bar with a rounded green highlight behind the
/// active tab, matching the TerraTrack Entry mockup's footer.
class _EntryBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<_NavItemData> items;

  const _EntryBottomNav({
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.entryNavBg,
        border: Border(top: BorderSide(color: AppColors.entryCardBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: List.generate(items.length, (i) {
            final item = items[i];
            final selected = i == currentIndex;
            return Expanded(
              child: InkWell(
                onTap: () => onTap(i),
                child: Container(
                  decoration: BoxDecoration(
                    color: selected ? AppColors.entryAccentSurfaceSoft : Colors.transparent,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        selected ? item.activeIcon : item.icon,
                        size: 26,
                        color: selected ? AppColors.entryAccent : AppColors.entryTextMuted2,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: selected ? FontWeight.w900 : FontWeight.w800,
                          color: selected ? AppColors.entryAccent : AppColors.entryTextMuted2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
