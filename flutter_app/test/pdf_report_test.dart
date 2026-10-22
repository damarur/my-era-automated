import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart' show Locale;
import 'package:myera_clock/api.dart';
import 'package:myera_clock/l10n.dart';
import 'package:myera_clock/pdf_report.dart';
import 'package:myera_clock/settings.dart';
import 'package:myera_clock/summary.dart';
import 'package:shared_preferences/shared_preferences.dart';

Clocking c(bool isIn, String t) => Clocking(isIn, DateTime.parse(t));

DayRow day(String key, List<Clocking> cl, {String? off, int target = 8 * 3600000, List<String> anomalies = const []}) {
  final cfg = DayConfig(breakStart: '13:00', breakEnd: '14:00');
  return DayRow(
    date: DateTime.parse(key),
    key: key,
    clockings: cl,
    off: off,
    target: off != null ? 0 : target,
    ms: effectiveMs(cl, key, false, cfg),
    pending: false,
    cfg: cfg,
    baseCfg: cfg,
    anomalies: anomalies,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await L10n.init();
    L10n.set(const Locale('en'));
  });

  // Week 1: Mon 7h/8h... built from two weeks, one with a holiday.
  final rows = [
    day('2026-09-28', [c(true, '2026-09-28T08:00'), c(false, '2026-09-28T17:00')]), // 8h
    day('2026-09-29', [c(true, '2026-09-29T08:00'), c(false, '2026-09-29T14:04'), c(true, '2026-09-29T15:14'), c(false, '2026-09-29T18:05')], anomalies: ['tiempo máximo de pausa excedido']),
    day('2026-09-30', [], off: 'Holiday'),
    day('2026-10-01', [c(true, '2026-10-01T08:00'), c(false, '2026-10-01T16:00')]), // 7h
    day('2026-10-02', [c(true, '2026-10-02T08:00'), c(false, '2026-10-02T17:30')]), // 8h30
  ];
  final summary = PeriodSummary(rows, rows.fold(0, (s, r) => s + r.ms), rows.fold(0, (s, r) => s + r.target), rows.fold(0, (s, r) => s + r.target));

  test('report model: weekly and monthly totals vs target', () {
    final m = buildReportModel(summary, DateTime(2026, 10, 1), DateTime(2026, 10, 31));
    expect(m.weeks.length, 1);
    final w = m.weeks.first;
    // 8h + (6h04+2h51-1h = 7h55) + 0 + 7h + 8h30 = 31h25 ; target 8+8+0+8+8 = 32h
    expect(w.worked, (31 * 60 + 25) * 60000);
    expect(w.target, 32 * 3600000);
    expect(w.diff, -35 * 60000);
    expect(m.diff, w.diff);
    final tue = w.days[1];
    expect(tue.clockings, '08:00 - 14:04    15:14 - 18:05');
    expect(tue.breaks, '1h 10m');
    expect(tue.lunch, '13:00-14:00 (1h)');
    // a missing clock-out is spelled out
    final open = buildReportModel(PeriodSummary([day('2026-10-02', [c(true, '2026-10-02T08:00')])], 0, 0, 0), DateTime(2026, 10, 1), DateTime(2026, 10, 31));
    expect(open.weeks.first.days.first.clockings, '08:00 - no clock-out');
    expect(w.days[2].clockings, 'Holiday');
  });

  test('days after today are listed but not counted', () {
    final m = buildReportModel(summary, DateTime(2026, 10, 1), DateTime(2026, 9, 30));
    expect(m.target, 16 * 3600000); // Mon + Tue + the holiday (0)
    expect(m.weeks.first.days.last.due, false);
  });

  test('pdf is generated', () async {
    final bytes = await buildMonthReportPdf(summary: summary, month: DateTime(2026, 10, 1), employee: 'Test User', now: DateTime(2026, 10, 31));
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    expect(bytes.length, greaterThan(1500));
    final out = Platform.environment['REPORT_OUT'];
    if (out != null) File(out).writeAsBytesSync(bytes);
  });

  test("a full 5-week month fits on one page", () async {
    final all = <DayRow>[];
    for (var d = DateTime(2026, 10, 1); d.month == 10; d = DateTime(d.year, d.month, d.day + 1)) {
      if (d.weekday > 5) continue;
      final k = "2026-10-${d.day.toString().padLeft(2, "0")}";
      if (d.day == 12) {
        all.add(day(k, [], off: "Holiday"));
      } else {
        all.add(day(k, [c(true, "${k}T08:00"), c(false, "${k}T14:04"), c(true, "${k}T15:14"), c(false, "${k}T18:05")]));
      }
    }
    final sum = PeriodSummary(all, all.fold(0, (s, r) => s + r.ms), all.fold(0, (s, r) => s + r.target), all.fold(0, (s, r) => s + r.target));
    final bytes = await buildMonthReportPdf(summary: sum, month: DateTime(2026, 10, 1), employee: "Test User", now: DateTime(2026, 10, 22));
    final pages = RegExp(r"/Types*/Page(?!s)").allMatches(String.fromCharCodes(bytes)).length;
    expect(pages, 1);
    final out = Platform.environment["REPORT_FULL_OUT"];
    if (out != null) File(out).writeAsBytesSync(bytes);
  });
}
