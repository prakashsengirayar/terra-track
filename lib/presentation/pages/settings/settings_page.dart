import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../bloc/settings/settings_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l.settings)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Language ──────────────────────────────────────────────────────
          _SectionLabel(l.language),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                _LangTile(
                  flag: '🇬🇧',
                  label: 'English',
                  sublabel: 'English',
                  selected: settings.locale.languageCode == 'en',
                  onTap: () => notifier.setLocale(const Locale('en')),
                ),
                const Divider(height: 0, indent: 16),
                _LangTile(
                  flag: '🇮🇳',
                  label: 'Tamil',
                  sublabel: 'தமிழ்',
                  selected: settings.locale.languageCode == 'ta',
                  onTap: () => notifier.setLocale(const Locale('ta')),
                ),
                const Divider(height: 0, indent: 16),
                _LangTile(
                  flag: '🇮🇳',
                  label: 'Hindi',
                  sublabel: 'हिंदी',
                  selected: settings.locale.languageCode == 'hi',
                  onTap: () => notifier.setLocale(const Locale('hi')),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms),

          const SizedBox(height: 24),

          // ── Font size ─────────────────────────────────────────────────────
          _SectionLabel(l.fontSize),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppColors.primary,
                      inactiveTrackColor: AppColors.grey200,
                      thumbColor: AppColors.primary,
                      overlayColor: AppColors.primary.withOpacity(0.15),
                    ),
                    child: Slider(
                      value: AppFontSize.values.indexOf(settings.appFontSize).toDouble(),
                      min: 0,
                      max: (AppFontSize.values.length - 1).toDouble(),
                      divisions: AppFontSize.values.length - 1,
                      onChanged: (v) =>
                          notifier.setFontSize(AppFontSize.values[v.round()]),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: AppFontSize.values.map((f) {
                      final selected = f == settings.appFontSize;
                      return GestureDetector(
                        onTap: () => notifier.setFontSize(f),
                        child: Text(
                          _fontLabel(f),
                          style: TextStyle(
                            fontSize: 11 + AppFontSize.values.indexOf(f) * 2.0,
                            color: selected ? AppColors.primary : AppColors.grey500,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 100.ms, duration: 400.ms),

          const SizedBox(height: 24),

          // ── Theme ─────────────────────────────────────────────────────────
          _SectionLabel(l.themeMode),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  _ThemeBtn(
                    icon: Icons.light_mode_outlined,
                    label: l.lightMode,
                    selected: settings.themeMode == ThemeMode.light,
                    onTap: () => notifier.setThemeMode(ThemeMode.light),
                  ),
                  const SizedBox(width: 8),
                  _ThemeBtn(
                    icon: Icons.dark_mode_outlined,
                    label: l.darkMode,
                    selected: settings.themeMode == ThemeMode.dark,
                    onTap: () => notifier.setThemeMode(ThemeMode.dark),
                  ),
                  const SizedBox(width: 8),
                  _ThemeBtn(
                    icon: Icons.brightness_auto_outlined,
                    label: l.systemMode,
                    selected: settings.themeMode == ThemeMode.system,
                    onTap: () => notifier.setThemeMode(ThemeMode.system),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

          const SizedBox(height: 24),

          // ── Preview ───────────────────────────────────────────────────────
          _SectionLabel(l.preview),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.agriculture,
                          color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(l.appName, style: theme.textTheme.titleSmall),
                      Text(l.appTagline,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: AppColors.grey500)),
                    ]),
                  ]),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(l.customerName,
                      style: theme.textTheme.bodySmall?.copyWith(color: AppColors.grey500)),
                  Text('Sample Customer Name', style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 8),
                  Row(children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(l.totalAmount,
                          style: theme.textTheme.bodySmall?.copyWith(color: AppColors.grey500)),
                      Text('₹ 2,550',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(color: AppColors.primary)),
                    ]),
                    const SizedBox(width: 32),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(l.balanceAmount,
                          style: theme.textTheme.bodySmall?.copyWith(color: AppColors.grey500)),
                      Text('₹ 550',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(color: AppColors.error)),
                    ]),
                  ]),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

          const SizedBox(height: 24),

          // ── Agri module entry point ───────────────────────────────────────
          // Additive entry point into the separate Land/Worker/Work-Entry/
          // Expense/Harvest module, which has its own Firebase-auth identity
          // and is reached at /agri/lands (the router redirects to
          // /agri/login automatically if not yet signed in to that module).
          Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => context.go('/agri/lands'),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.agriculture_outlined,
                        color: AppColors.primary, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.agriModuleTitle,
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        Text(l.agriModuleSubtitle,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: AppColors.grey500)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.grey500),
                ]),
              ),
            ),
          ).animate().fadeIn(delay: 350.ms, duration: 400.ms),

          const SizedBox(height: 24),

          // ── App info ──────────────────────────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                Row(children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.eco, color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('TerraTrack',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const Text('Version 1.0.0 · Pilot',
                        style: TextStyle(fontSize: 12, color: AppColors.grey500)),
                  ]),
                ]),
                const SizedBox(height: 12),
                const Divider(),
                _InfoRow(icon: Icons.language, label: 'Languages',
                    value: 'English · தமிழ் · हिंदी'),
                _InfoRow(icon: Icons.cloud_outlined, label: 'Backend',
                    value: 'Firebase (Spark Plan)'),
              ]),
            ),
          ).animate().fadeIn(delay: 400.ms, duration: 400.ms),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _fontLabel(AppFontSize f) {
    switch (f) {
      case AppFontSize.small: return 'Small';
      case AppFontSize.medium: return 'Medium';
      case AppFontSize.large: return 'Large';
      case AppFontSize.extraLarge: return 'X-Large';
    }
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: const TextStyle(
        fontSize: 11, fontWeight: FontWeight.w600,
        color: AppColors.primary, letterSpacing: 1.2),
  );
}

class _LangTile extends StatelessWidget {
  final String flag, label, sublabel;
  final bool selected;
  final VoidCallback onTap;
  const _LangTile({required this.flag, required this.label,
      required this.sublabel, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Text(flag, style: const TextStyle(fontSize: 24)),
      title: Text(label,
          style: TextStyle(fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
      subtitle: Text(sublabel, style: const TextStyle(fontSize: 12)),
      trailing: selected ? const Icon(Icons.check_circle, color: AppColors.primary) : null,
      onTap: onTap,
    );
  }
}

class _ThemeBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ThemeBtn({required this.icon, required this.label,
      required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.primarySurface : Colors.transparent,
            border: Border.all(
                color: selected ? AppColors.primary : AppColors.grey200,
                width: selected ? 1.5 : 0.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(children: [
            Icon(icon,
                color: selected ? AppColors.primary : AppColors.grey500, size: 22),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: selected ? AppColors.primary : AppColors.grey500,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
          ]),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Icon(icon, size: 16, color: AppColors.grey500),
        const SizedBox(width: 10),
        Text('$label: ',
            style: const TextStyle(fontSize: 12, color: AppColors.grey500)),
        Expanded(child: Text(value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
      ]),
    );
  }
}
