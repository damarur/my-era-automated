import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myera_clock/api.dart';
import 'package:myera_clock/settings.dart';
import 'package:myera_clock/summary.dart';

Clocking c(bool isIn, String t) => Clocking(isIn, DateTime.parse(t));

void main() {
  final cfg = DayConfig(breakStart: '13:00', breakEnd: '13:30');

  test('configured break is deducted even with a clocked break elsewhere', () {
    final ms = effectiveMs(
      [c(true, '2026-10-20T07:54'), c(false, '2026-10-20T14:02'), c(true, '2026-10-20T15:16'), c(false, '2026-10-20T17:51')],
      '2026-10-20',
      false,
      cfg,
    );
    // 7:54-14:02 (6h08) + 15:16-17:51 (2h35) - 30 min = 8h13
    expect(ms, (8 * 60 + 13) * 60000);
  });

  test('open block today only counts up to now', () {
    final ms = effectiveMs([c(true, '2026-10-21T07:46')], '2026-10-21', true, cfg, DateTime.parse('2026-10-21T12:00'));
    expect(ms, (4 * 60 + 14) * 60000);
  });

  test('consecutive in-in counts as a block', () {
    final ms = effectiveMs([c(true, '2026-10-21T08:00'), c(true, '2026-10-21T10:00')], '2026-10-21', false, cfg);
    expect(ms, 2 * 3600000);
  });

  test("timeline: blocks, lunch inside the block and a dashed break", () {
    final lunch = DayConfig(breakStart: "13:00", breakEnd: "14:00");
    final cl = [c(true, "2026-10-22T07:48"), c(false, "2026-10-22T14:04"), c(true, "2026-10-22T15:14"), c(false, "2026-10-22T18:05")];
    final items = buildTimeline(cl, "2026-10-22", false, lunch);
    expect(items.map((i) => i.isBreak), [false, true, false]);
    expect(items[0].lunchMs, 3600000); // 13:00-14:00 inside 07:48-14:04
    expect(items[0].ms, (5 * 60 + 16) * 60000); // 6h16 - 1h
    expect(items[1].ms, 70 * 60000); // break 1h10
    expect(items[2].lunchMs, 0);
    expect(items[2].ms, (2 * 60 + 51) * 60000);
    final blocks = items.where((i) => !i.isBreak).fold<int>(0, (s, i) => s + i.ms);
    expect(blocks, effectiveMs(cl, "2026-10-22", false, lunch)); // 8h07
  });

  test("timeline: open block today and in-in", () {
    final items = buildTimeline([c(true, "2026-10-22T08:00"), c(true, "2026-10-22T10:00")], "2026-10-22", true, cfg, DateTime.parse("2026-10-22T11:00"));
    expect(items.length, 2);
    expect(items[0].ms, 2 * 3600000);
    expect(items[1].open, true);
    expect(items[1].ms, 3600000);
  });

  test("lunch override applies to one date only and is persisted", () async {
    SharedPreferences.setMockInitialValues({});
    final thu = DateTime(2026, 10, 22); // Thursday
    await LunchOverrides.set(thu, LunchOverride(enabled: true, start: "13:00", end: "13:30"));
    final s = await AppSettings.load();
    expect(s.hasLunchOverride(thu), true);
    expect(s.configFor(thu).breakEnd, "13:30");
    expect(s.configFor(DateTime(2026, 10, 15)).breakEnd, "14:00"); // another Thursday keeps the settings
    expect(s.days[4]!.breakEnd, "14:00"); // weekly settings untouched
    // effect on the worked time: 07:48-14:04 + 15:14-18:05 with a 30 min lunch instead of 1 h
    final cl = [c(true, "2026-10-22T07:48"), c(false, "2026-10-22T14:04"), c(true, "2026-10-22T15:14"), c(false, "2026-10-22T18:05")];
    expect(effectiveMs(cl, "2026-10-22", false, s.configFor(thu)), (8 * 60 + 37) * 60000);
    await LunchOverrides.set(thu, null);
    expect((await AppSettings.load()).hasLunchOverride(thu), false);
  });

  test("overrides older than a year are dropped", () async {
    SharedPreferences.setMockInitialValues({});
    final now = DateTime.now();
    final old = DateTime(now.year - 2, now.month, 10);
    await LunchOverrides.set(old, LunchOverride(enabled: false, start: "13:00", end: "14:00"));
    await LunchOverrides.set(now, LunchOverride(enabled: false, start: "13:00", end: "14:00"));
    final all = await LunchOverrides.load();
    expect(all.length, 1);
  });
}
