import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:myera_clock/l10n.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('English and Spanish have exactly the same keys', () {
    Map<String, dynamic> load(String f) => jsonDecode(File('lib/l10n/$f.arb').readAsStringSync()) as Map<String, dynamic>;
    final en = load('app_en').keys.where((k) => !k.startsWith('@')).toSet();
    final es = load('app_es').keys.where((k) => !k.startsWith('@')).toSet();
    expect(es.difference(en), isEmpty);
    expect(en.difference(es), isEmpty);
  });

  test('strings, weekdays and months follow the language', () async {
    SharedPreferences.setMockInitialValues({});
    await L10n.init();
    L10n.set(const Locale('es'));
    expect(L10n.current.worked, 'Trabajado');
    expect(monthName(10), 'Octubre');
    expect(weekdayShort(1), 'Lun');
    expect(L10n.current.clockedInAt('08:00'), 'Entrada fichada a las 08:00');
    L10n.set(const Locale('en'));
    expect(L10n.current.worked, 'Worked');
    expect(monthName(10), 'October');
    expect(weekdayShort(1), 'Mon');
  });

  test('a saved language wins over the device one, unsupported ones fall back to English', () async {
    SharedPreferences.setMockInitialValues({});
    await LocaleController.instance.set(const Locale('es'));
    await LocaleController.instance.load();
    expect(LocaleController.instance.value, const Locale('es'));
    expect(L10n.resolve(LocaleController.instance.value), const Locale('es'));
    await LocaleController.instance.set(null);
    expect(LocaleController.instance.value, isNull);
    expect(L10n.resolve(null), const Locale('en')); // test device language is English
  });
}
