import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/entities.dart';
import '../../bloc/auth/auth_provider.dart';
import '../../bloc/providers.dart';
import '../../bloc/settings/settings_provider.dart';

/// Looks up the full VehicleEntity (for its registration number) behind the
/// current session — SessionEntity only carries vehicleId/vehicleName/
/// driverName, not the plate number shown on this screen.
final _currentVehicleProvider = FutureProvider<VehicleEntity?>((ref) async {
  final session = ref.watch(authProvider).session;
  if (session == null) return null;
  final result = await ref.read(getAllVehiclesUseCaseProvider).call();
  return result.fold((_) => null, (list) {
    for (final v in list) {
      if (v.id == session.vehicleId) return v;
    }
    return null;
  });
});

/// Settings screen — restyled to match the "TerraTrack Settings" dark
/// mockup: a view-only Vehicle & Owner card, Display (font size + light/
/// dark), Language, and About, all in the same dark card language as the
/// Dashboard/New Entry screens. (The "Land & Crop Management" / Agri-module
/// entry point has been removed per request — that module is no longer
/// reachable from the UI, though its routes still exist.)
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final session = ref.watch(authProvider).session;
    final vehicleAsync = ref.watch(_currentVehicleProvider);

    return Scaffold(
      backgroundColor: AppColors.entryBgBottom,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.entryBgTop, AppColors.entryBgBottom],
          ),
        ),
        child: SafeArea(
          child: Column(children: [
            _header(context, l),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
                child: Column(children: [
                  _vehicleCard(l, session, vehicleAsync),
                  const SizedBox(height: 14),
                  _displayCard(l, settings, notifier),
                  const SizedBox(height: 14),
                  _languageCard(l, settings, notifier),
                  const SizedBox(height: 14),
                  _aboutCard(),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────
  Widget _header(BuildContext context, AppLocalizations l) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 10),
      child: Row(children: [
        Material(
          color: AppColors.entryIconTileBg,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => context.pop(),
            child: const SizedBox(
                width: 46, height: 46, child: Icon(Icons.arrow_back, color: AppColors.entryTextPrimary, size: 26)),
          ),
        ),
        Expanded(
          child: Center(
            child: Text(l.settings,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.entryTextPrimary)),
          ),
        ),
        const SizedBox(width: 46),
      ]),
    );
  }

  // ─── VEHICLE & OWNER (view only) ─────────────────────────────────────────
  Widget _vehicleCard(AppLocalizations l, SessionEntity? session, AsyncValue<VehicleEntity?> vehicleAsync) {
    final vehicleNumber = vehicleAsync.when(
      data: (v) => v?.vehicleNumber ?? '—',
      loading: () => '…',
      error: (_, __) => '—',
    );
    return _card(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        _sectionHeader(Icons.directions_car_rounded, 'VEHICLE & OWNER'),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration:
              BoxDecoration(color: AppColors.entryIconTileBg, borderRadius: BorderRadius.circular(999)),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.lock_rounded, size: 15, color: AppColors.entryTextMuted),
            SizedBox(width: 4),
            Text('View only',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.entryTextMuted)),
          ]),
        ),
      ]),
      _infoRow(Icons.sell_rounded, 'Vehicle Number', vehicleNumber, divider: false),
      _infoRow(Icons.local_shipping_rounded, l.vehicleNameField, session?.vehicleName ?? '—'),
      _infoRow(Icons.person_rounded, l.driverOwnerName.replaceAll(' Name', ''), session?.driverName ?? '—'),
    ]);
  }

  Widget _infoRow(IconData icon, String label, String value, {bool divider = true}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: divider
          ? const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.entryWhite06, width: 1)))
          : null,
      child: Row(children: [
        Icon(icon, size: 22, color: AppColors.entryIconMuted),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.entryTextMuted)),
        ),
        Text(value,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.entryTextPrimary)),
      ]),
    );
  }

  // ─── DISPLAY ────────────────────────────────────────────────────────────
  Widget _displayCard(AppLocalizations l, AppSettings settings, SettingsNotifier notifier) {
    final previewSize = switch (settings.appFontSize) {
      AppFontSize.small => 15.0,
      AppFontSize.large || AppFontSize.extraLarge => 22.0,
      _ => 18.0,
    };
    return _card(children: [
      _sectionHeader(Icons.tune_rounded, 'DISPLAY'),
      Text(l.fontSize,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.entryTextMuted)),
      const SizedBox(height: 8),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(color: AppColors.entryWhite04, borderRadius: BorderRadius.circular(13)),
        child: Text('Aa — sample text',
            style: TextStyle(fontSize: previewSize, fontWeight: FontWeight.w800, color: AppColors.entryTextPrimary)),
      ),
      Row(children: [
        Expanded(child: _fontSizeBtn('Small', 17, AppFontSize.small, settings, notifier)),
        const SizedBox(width: 9),
        Expanded(child: _fontSizeBtn('Medium', 22, AppFontSize.medium, settings, notifier)),
        const SizedBox(width: 9),
        Expanded(child: _fontSizeBtn('Large', 28, AppFontSize.large, settings, notifier)),
      ]),
      const SizedBox(height: 18),
      const Text('Light or Dark mode',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.entryTextMuted)),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(
            child: _modeBtn(Icons.light_mode_rounded, l.lightMode, ThemeMode.light, settings, notifier)),
        const SizedBox(width: 10),
        Expanded(child: _modeBtn(Icons.dark_mode_rounded, l.darkMode, ThemeMode.dark, settings, notifier)),
      ]),
    ]);
  }

  Widget _fontSizeBtn(
      String label, double letterSize, AppFontSize value, AppSettings settings, SettingsNotifier notifier) {
    final active = settings.appFontSize == value;
    return Material(
      color: active ? AppColors.entryAccentTintStrong : AppColors.entryWhite04,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => notifier.setFontSize(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: active ? AppColors.entryAccent : AppColors.entryWhite10, width: active ? 2 : 1),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('A',
                style: TextStyle(
                    fontSize: letterSize,
                    fontWeight: FontWeight.w900,
                    height: 1,
                    color: active ? AppColors.entryAccent : AppColors.entryTextSecondary)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: active ? AppColors.entryAccent : AppColors.entryTextSecondary)),
          ]),
        ),
      ),
    );
  }

  Widget _modeBtn(
      IconData icon, String label, ThemeMode value, AppSettings settings, SettingsNotifier notifier) {
    final active = settings.themeMode == value;
    return Material(
      color: active ? AppColors.entryAccentTintStrong : AppColors.entryWhite04,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => notifier.setThemeMode(value),
        child: Container(
          height: 58,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: active ? AppColors.entryAccent : AppColors.entryWhite10, width: active ? 2 : 1),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 24, color: active ? AppColors.entryAccent : AppColors.entryTextSecondary),
            const SizedBox(width: 9),
            Text(label,
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: active ? AppColors.entryAccent : AppColors.entryTextSecondary)),
          ]),
        ),
      ),
    );
  }

  // ─── LANGUAGE ───────────────────────────────────────────────────────────
  Widget _languageCard(AppLocalizations l, AppSettings settings, SettingsNotifier notifier) {
    final options = [
      ('en', 'English', 'English'),
      ('ta', 'தமிழ்', 'Tamil'),
      ('hi', 'हिन्दी', 'Hindi'),
    ];
    return _card(children: [
      _sectionHeader(Icons.translate_rounded, 'LANGUAGE'),
      Column(
        children: options.map((o) {
          final active = settings.locale.languageCode == o.$1;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: active ? AppColors.entryAccentSurface : AppColors.entryCardBg,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => notifier.setLocale(Locale(o.$1)),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: active ? AppColors.entryAccent : AppColors.entryWhite10, width: active ? 2 : 1),
                  ),
                  child: Row(children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(o.$2,
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.entryTextPrimary)),
                          const SizedBox(height: 1),
                          Text(o.$3,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.entryTextMuted)),
                        ],
                      ),
                    ),
                    if (active)
                      const Icon(Icons.check_circle, size: 26, color: AppColors.entryAccent),
                  ]),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    ]);
  }

  // ─── ABOUT ──────────────────────────────────────────────────────────────
  Widget _aboutCard() {
    return _card(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.entryAccent,
            borderRadius: BorderRadius.circular(19),
            boxShadow: [
              BoxShadow(color: AppColors.entryAccent.withOpacity(0.28), blurRadius: 24, offset: const Offset(0, 10)),
            ],
          ),
          alignment: Alignment.center,
          child: const Text('T',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.entryPillText)),
        ),
        const SizedBox(height: 12),
        const Text('TerraTrack',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: AppColors.entryTextPrimary)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
          decoration:
              BoxDecoration(color: AppColors.entryIconTileBg, borderRadius: BorderRadius.circular(999)),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.info_rounded, size: 17, color: AppColors.entryIconMuted),
            SizedBox(width: 6),
            Text('App Version',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.entryTextSecondary)),
            SizedBox(width: 6),
            Text('v1.0.0',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.entryTextPrimary)),
          ]),
        ),
        const SizedBox(height: 14),
        const Text('© 2026 TerraTrack. All rights reserved.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.entryTextMutedDeep, height: 1.5)),
      ],
    );
  }

  // ─── shared building blocks ────────────────────────────────────────────
  Widget _card({required List<Widget> children, CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.entryCardBg,
        border: Border.all(color: AppColors.entryCardBorder),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(crossAxisAlignment: crossAxisAlignment, children: children),
    );
  }

  Widget _sectionHeader(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Icon(icon, size: 20, color: AppColors.entryAccent),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: AppColors.entryAccent)),
      ]),
    );
  }
}
