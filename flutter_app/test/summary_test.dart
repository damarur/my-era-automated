import 'package:flutter_test/flutter_test.dart';
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
}
