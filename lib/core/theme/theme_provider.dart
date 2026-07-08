import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(),
);

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  static const _key = 'theme_mode';

  ThemeModeNotifier() : super(ThemeMode.system) {
    _load();
  }

  void _load() {
    try {
      if (Hive.isBoxOpen('settings')) {
        final saved =
            Hive.box<dynamic>('settings').get(_key, defaultValue: 'system')
                as String;
        state = _parse(saved);
      }
    } catch (_) {}
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    try {
      if (Hive.isBoxOpen('settings')) {
        await Hive.box<dynamic>('settings').put(_key, _serialize(mode));
      }
    } catch (_) {}
  }

  static ThemeMode _parse(String s) {
    if (s == 'light') return ThemeMode.light;
    if (s == 'dark') return ThemeMode.dark;
    return ThemeMode.system;
  }

  static String _serialize(ThemeMode m) {
    if (m == ThemeMode.light) return 'light';
    if (m == ThemeMode.dark) return 'dark';
    return 'system';
  }
}
