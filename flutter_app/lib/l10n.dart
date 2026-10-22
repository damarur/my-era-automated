import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'l10n/app_localizations.dart';

export 'l10n/app_localizations.dart';

/// App language: null follows the device language, otherwise the chosen one. Persisted.
class LocaleController extends ValueNotifier<Locale?> {
  LocaleController._() : super(null);
  static final LocaleController instance = LocaleController._();

  static const _key = 'language';

  Future<void> load() async {
    final code = (await SharedPreferences.getInstance()).getString(_key);
    value = AppLocalizations.supportedLocales.where((l) => l.languageCode == code).firstOrNull;
  }

  Future<void> set(Locale? locale) async {
    value = locale;
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove(_key);
    } else {
      await prefs.setString(_key, locale.languageCode);
    }
  }
}

/// Strings for code that has no BuildContext (API errors, notifications, the PDF). Widgets use
/// `context.l10n`; this one is kept in sync by the root MaterialApp and, in a background isolate,
/// by [L10n.init].
class L10n {
  static AppLocalizations current = lookupAppLocalizations(const Locale('en'));

  /// The chosen language, or the device one when none was chosen, limited to the supported ones.
  static Locale resolve(Locale? chosen) {
    if (chosen != null) return chosen;
    final device = PlatformDispatcher.instance.locale;
    return AppLocalizations.supportedLocales.where((l) => l.languageCode == device.languageCode).firstOrNull ?? const Locale('en');
  }

  static void set(Locale locale) => current = lookupAppLocalizations(locale);

  static String get code => current.localeName;

  /// Loads date symbols and the saved language. Call at startup and in background isolates.
  static Future<void> init() async {
    await initializeDateFormatting();
    await LocaleController.instance.load();
    set(resolve(LocaleController.instance.value));
  }
}

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// "Mon" / "Lun" for [weekday] (1 = Monday).
String weekdayShort(int weekday) => _cap(DateFormat.E(L10n.code).format(DateTime(2024, 1, weekday)));

/// "Monday" / "Lunes".
String weekdayLong(int weekday) => _cap(DateFormat.EEEE(L10n.code).format(DateTime(2024, 1, weekday)));

/// "October" / "Octubre" for [month] (1-12).
String monthName(int month) => _cap(DateFormat.MMMM(L10n.code).format(DateTime(2024, month)));

/// "Thursday, October 22" / "jueves, 22 de octubre".
String fmtLongDate(DateTime d) => _cap(DateFormat.MMMMEEEEd(L10n.code).format(d));

/// Localized label of an off day code ("Absent" | "Holiday") used internally by the summary.
String offLabel(AppLocalizations l, String off) => off == 'Holiday' ? l.holiday : l.absent;

/// Short numeric date in the current language ("22/10/2026").
String fmtDate(DateTime d) => DateFormat.yMd(L10n.code).format(d);
