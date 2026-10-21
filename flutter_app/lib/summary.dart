import 'api.dart';
import 'settings.dart';

String fmtDuration(int ms) {
  final m = ms.abs() ~/ 60000;
  return '${m ~/ 60}h ${pad(m % 60)}m';
}

String fmtSigned(int ms) => '${ms < 0 ? '−' : '+'}${fmtDuration(ms)}';

/// Effective time = sum of the time blocks between consecutive clockings, minus the overlap with
/// the configured lunch break window. Every pair of consecutive clockings is a valid block
/// (in->out, but also in->in and out->out, since MyEra allows repeated clockings of the same
/// type), except out->in, which is a break. The configured window is always deducted from the
/// worked blocks, even when the day also has a clocked break elsewhere (a clocked break that
/// overlaps the window is not deducted twice, since it is already outside the blocks). A block
/// still open today (last clocking is an "in") only counts up to now, so a break that has not
/// started yet is not deducted.
int effectiveMs(List<Clocking> clockings, String key, bool isToday, DayConfig cfg, [DateTime? now]) {
  final intervals = <List<int>>[];
  Clocking? prev;
  for (final c in clockings) {
    if (prev != null && (prev.isIn || !c.isIn)) {
      intervals.add([prev.time.millisecondsSinceEpoch, c.time.millisecondsSinceEpoch]);
    }
    prev = c;
  }
  if (prev != null && prev.isIn && isToday) {
    intervals.add([prev.time.millisecondsSinceEpoch, (now ?? DateTime.now()).millisecondsSinceEpoch]);
  }

  final bs = DateTime.parse('${key}T${cfg.breakStart}').millisecondsSinceEpoch;
  final be = DateTime.parse('${key}T${cfg.breakEnd}').millisecondsSinceEpoch;
  var total = 0;
  for (final iv in intervals) {
    total += iv[1] - iv[0];
    if (cfg.breakEnabled && be > bs) {
      final overlap = (iv[1] < be ? iv[1] : be) - (iv[0] > bs ? iv[0] : bs);
      if (overlap > 0) total -= overlap;
    }
  }
  return total;
}

class DayRow {
  DayRow({required this.date, required this.key, required this.clockings, required this.off, required this.target, required this.ms, required this.pending});
  final DateTime date;
  final String key;
  final List<Clocking> clockings;
  final String? off; // "Absent" | "Holiday"
  final int target;
  final int ms;
  final bool pending;
}

class PeriodSummary {
  PeriodSummary(this.rows, this.total, this.target);
  final List<DayRow> rows;
  final int total;
  final int target;
}

/// Monday of the week containing [d].
DateTime weekStart(DateTime d) => DateTime(d.year, d.month, d.day - (d.weekday - 1));

({DateTime start, DateTime end}) periodRange(DateTime now, bool month, int offset) {
  if (!month) {
    final s = weekStart(now).add(Duration.zero);
    final start = DateTime(s.year, s.month, s.day + 7 * offset);
    return (start: start, end: DateTime(start.year, start.month, start.day + 6));
  }
  return (start: DateTime(now.year, now.month + offset, 1), end: DateTime(now.year, now.month + offset + 1, 0));
}

/// Builds the Mon-Fri rows of a period. Target per day: the average configured daily target x
/// working days is spread over the week. On a normal week each day keeps its own target; when a
/// day is off (absence/holiday) the average is spread over the remaining days so the weekly
/// average does not go over (e.g. 38h/5 = 7h36 per working day).
Future<PeriodSummary> buildSummary(AppSettings settings, bool month, int offset, {DateTime? nowOverride}) async {
  final now = nowOverride ?? DateTime.now();
  final range = periodRange(now, month, offset);
  final first = weekStart(range.start);
  final last = DateTime(range.end.year, range.end.month, range.end.day - (range.end.weekday - 1) + 4);
  final fetchEnd = offset == 0 && ymd(now).compareTo(ymd(last)) > 0 ? now : last;
  final calendar = await MyEraApi.instance.calendar(first, fetchEnd);
  final byDate = {for (final d in calendar) d.date: d};

  final today = ymd(now);
  final rows = <DayRow>[];
  var total = 0, totalTarget = 0;
  for (var w = first; !w.isAfter(last); w = DateTime(w.year, w.month, w.day + 7)) {
    final days = <({DateTime d, String key, DayConfig cfg, CalendarDay? entry, String? off})>[];
    for (var i = 0; i < 5; i++) {
      final d = DateTime(w.year, w.month, w.day + i);
      final key = ymd(d);
      final entry = byDate[key];
      final off = entry == null ? null : entry.absences.isNotEmpty ? 'Absent' : entry.holiday ? 'Holiday' : null;
      days.add((d: d, key: key, cfg: settings.days[d.weekday]!, entry: entry, off: off));
    }
    final avg = days.fold<int>(0, (s, x) => s + x.cfg.targetMs) ~/ 5;
    final redistribute = days.any((x) => x.off != null);
    for (final x in days) {
      if (x.d.isBefore(range.start) || x.d.isAfter(range.end)) continue;
      final target = x.off != null ? 0 : redistribute ? avg : x.cfg.targetMs;
      final clockings = x.entry?.clockings ?? const <Clocking>[];
      final ms = effectiveMs(clockings, x.key, x.key == today, x.cfg, now);
      final open = clockings.isNotEmpty && clockings.last.isIn;
      final pending = x.key.compareTo(today) > 0 || (x.key == today && (open || clockings.isEmpty));
      total += ms;
      // The week view keeps the full weekly target; in the month view days not due yet are left out.
      totalTarget += month && x.key.compareTo(today) > 0 ? 0 : target;
      rows.add(DayRow(date: x.d, key: x.key, clockings: clockings, off: x.off, target: target, ms: ms, pending: pending));
    }
  }
  return PeriodSummary(rows, total, totalTarget);
}
