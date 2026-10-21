import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App theme mode (system / light / dark), persisted. Listen to it from the root MaterialApp.
class ThemeController extends ValueNotifier<ThemeMode> {
  ThemeController._() : super(ThemeMode.system);
  static final ThemeController instance = ThemeController._();

  static const _key = 'themeMode';

  Future<void> load() async {
    final name = (await SharedPreferences.getInstance()).getString(_key);
    value = ThemeMode.values.firstWhere((m) => m.name == name, orElse: () => ThemeMode.system);
  }

  Future<void> set(ThemeMode mode) async {
    value = mode;
    await (await SharedPreferences.getInstance()).setString(_key, mode.name);
  }
}
