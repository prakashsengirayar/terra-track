import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/constants/app_constants.dart';

enum AppFontSize { small, medium, large, extraLarge }

extension AppFontSizeExt on AppFontSize {
  double get scale {
    switch (this) {
      case AppFontSize.small: return 0.85;
      case AppFontSize.medium: return 1.0;
      case AppFontSize.large: return 1.15;
      case AppFontSize.extraLarge: return 1.3;
    }
  }

  String get key {
    switch (this) {
      case AppFontSize.small: return 'small';
      case AppFontSize.medium: return 'medium';
      case AppFontSize.large: return 'large';
      case AppFontSize.extraLarge: return 'extraLarge';
    }
  }
}

class AppSettings {
  final Locale locale;
  final AppFontSize appFontSize;
  final ThemeMode themeMode;

  const AppSettings({
    this.locale = const Locale('en'),
    this.appFontSize = AppFontSize.medium,
    this.themeMode = ThemeMode.system,
  });

  double get fontSize => appFontSize.scale;

  AppSettings copyWith({
    Locale? locale,
    AppFontSize? appFontSize,
    ThemeMode? themeMode,
  }) {
    return AppSettings(
      locale: locale ?? this.locale,
      appFontSize: appFontSize ?? this.appFontSize,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  final Box _box;

  SettingsNotifier(this._box) : super(const AppSettings()) {
    _load();
  }

  void _load() {
    final localeCode = _box.get(AppConstants.localeKey, defaultValue: 'en') as String;
    final fontKey = _box.get(AppConstants.fontSizeKey, defaultValue: 'medium') as String;
    final themeKey = _box.get(AppConstants.themeModeKey, defaultValue: 'system') as String;

    state = AppSettings(
      locale: Locale(localeCode),
      appFontSize: AppFontSize.values.firstWhere(
        (f) => f.key == fontKey,
        orElse: () => AppFontSize.medium,
      ),
      themeMode: _parseTheme(themeKey),
    );
  }

  ThemeMode _parseTheme(String key) {
    switch (key) {
      case 'light': return ThemeMode.light;
      case 'dark': return ThemeMode.dark;
      default: return ThemeMode.system;
    }
  }

  String _themeKey(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light: return 'light';
      case ThemeMode.dark: return 'dark';
      default: return 'system';
    }
  }

  Future<void> setLocale(Locale locale) async {
    await _box.put(AppConstants.localeKey, locale.languageCode);
    state = state.copyWith(locale: locale);
  }

  Future<void> setFontSize(AppFontSize size) async {
    await _box.put(AppConstants.fontSizeKey, size.key);
    state = state.copyWith(appFontSize: size);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _box.put(AppConstants.themeModeKey, _themeKey(mode));
    state = state.copyWith(themeMode: mode);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>(
  (ref) => SettingsNotifier(Hive.box(AppConstants.settingsBox)),
);
