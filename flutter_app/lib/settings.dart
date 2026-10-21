import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

int toMin(String t) {
  final p = t.split(':');
  return int.parse(p[0]) * 60 + int.parse(p[1]);
}

String toHm(int min) => '${((min ~/ 60) % 24).toString().padLeft(2, '0')}:${(min % 60).toString().padLeft(2, '0')}';

/// Daily schedule config. Days are keyed by DateTime.weekday: 1 = Mon .. 5 = Fri.
/// in/out = schedule (reminders and auto clock); break* = unpaid break window, deducted from
/// worked time; target = daily hours to complete (informative).
class DayConfig {
  DayConfig({
    this.enabled = true,
    this.inTime = '08:00',
    this.outTime = '17:00',
    this.breakEnabled = true,
    this.breakStart = '13:00',
    this.breakEnd = '14:00',
    this.target = '08:00',
  });

  bool enabled;
  String inTime;
  String outTime;
  bool breakEnabled;
  String breakStart;
  String breakEnd;
  String target;

  int get targetMs => toMin(target) * 60000;

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'in': inTime,
        'out': outTime,
        'breakEnabled': breakEnabled,
        'breakStart': breakStart,
        'breakEnd': breakEnd,
        'target': target,
      };

  factory DayConfig.fromJson(Map<String, dynamic> j, DayConfig d) => DayConfig(
        enabled: j['enabled'] as bool? ?? d.enabled,
        inTime: j['in'] as String? ?? d.inTime,
        outTime: j['out'] as String? ?? d.outTime,
        breakEnabled: j['breakEnabled'] as bool? ?? d.breakEnabled,
        breakStart: j['breakStart'] as String? ?? d.breakStart,
        breakEnd: j['breakEnd'] as String? ?? d.breakEnd,
        target: j['target'] as String? ?? d.target,
      );
}

const standardTarget = '07:36';

/// Preset "Standard": 7h36 per day from [start], with a break window. Clock out is derived.
Map<int, DayConfig> standardPreset({String start = '09:00', String breakStart = '13:00', String breakEnd = '13:30'}) {
  final breakMin = (toMin(breakEnd) - toMin(breakStart)).clamp(0, 24 * 60);
  final out = toHm(toMin(start) + toMin(standardTarget) + breakMin);
  return {
    for (var d = 1; d <= 5; d++)
      d: DayConfig(inTime: start, outTime: out, breakStart: breakStart, breakEnd: breakEnd, target: standardTarget),
  };
}

/// Preset "Irregular schedule": 8h Mon-Thu (start + 8h + break) and 6h on Fri (start + 6h, no break).
Map<int, DayConfig> irregularPreset({String start = '08:00', String breakStart = '13:00', String breakEnd = '14:00'}) {
  final breakMin = (toMin(breakEnd) - toMin(breakStart)).clamp(0, 24 * 60);
  return {
    for (var d = 1; d <= 4; d++)
      d: DayConfig(inTime: start, outTime: toHm(toMin(start) + 8 * 60 + breakMin), breakStart: breakStart, breakEnd: breakEnd, target: '08:00'),
    5: DayConfig(inTime: start, outTime: toHm(toMin(start) + 6 * 60), breakEnabled: false, breakStart: breakStart, breakEnd: breakEnd, target: '06:00'),
  };
}

class AppSettings {
  AppSettings({this.remindersEnabled = true, this.autoClockAck = false, this.autoClockEnabled = false, Map<int, DayConfig>? days})
      : days = days ?? irregularPreset();

  bool remindersEnabled;
  bool autoClockAck;
  bool autoClockEnabled;
  Map<int, DayConfig> days;

  /// Auto clock only runs when the user has accepted the risks and switched it on.
  bool get autoClockActive => autoClockEnabled && autoClockAck;

  Map<String, dynamic> toJson() => {
        'remindersEnabled': remindersEnabled,
        'autoClock': {'ack': autoClockAck, 'enabled': autoClockEnabled},
        'days': {for (final e in days.entries) '${e.key}': e.value.toJson()},
      };

  static const _key = 'settings';

  static Future<AppSettings> load() async {
    final raw = (await SharedPreferences.getInstance()).getString(_key);
    final defaults = irregularPreset();
    if (raw == null) return AppSettings(days: defaults);
    final j = jsonDecode(raw) as Map<String, dynamic>;
    final stored = (j['days'] as Map<String, dynamic>?) ?? {};
    final auto = (j['autoClock'] as Map<String, dynamic>?) ?? {};
    return AppSettings(
      remindersEnabled: j['remindersEnabled'] as bool? ?? true,
      autoClockAck: auto['ack'] as bool? ?? false,
      autoClockEnabled: auto['enabled'] as bool? ?? false,
      days: {
        for (final e in defaults.entries)
          e.key: stored['${e.key}'] != null ? DayConfig.fromJson(stored['${e.key}'] as Map<String, dynamic>, e.value) : e.value,
      },
    );
  }

  Future<void> save() async => (await SharedPreferences.getInstance()).setString(_key, jsonEncode(toJson()));
}
