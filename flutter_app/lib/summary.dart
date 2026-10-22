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

/// One line of a day's timeline: a worked block (in -> out, also in -> in / out -> out) with its
/// effective time, or a clocked break (out -> in).
class TimelineItem {
  TimelineItem.block(this.from, this.to, this.ms, this.lunchMs, {this.open = false}) : isBreak = false;
  TimelineItem.pause(this.from, this.to, this.ms)
      : isBreak = true,
        lunchMs = 0,
        open = false;

  final Clocking from;
  final Clocking? to; // null: block still open today (or a lone clocking)
  final int ms; // effective time (lunch break already deducted); the break length for a pause
  final int lunchMs; // configured lunch break inside the block
  final bool isBreak;
  final bool open;
}

/// Builds the timeline of a day. The effective times of the blocks add up to [effectiveMs].
List<TimelineItem> buildTimeline(List<Clocking> clockings, String key, bool isToday, DayConfig cfg, [DateTime? now]) {
  final bs = DateTime.parse('${key}T${cfg.breakStart}').millisecondsSinceEpoch;
  final be = DateTime.parse('${key}T${cfg.breakEnd}').millisecondsSinceEpoch;
  int lunchIn(int a, int b) {
    if (!cfg.breakEnabled || be <= bs) return 0;
    final o = (b < be ? b : be) - (a > bs ? a : bs);
    return o > 0 ? o : 0;
  }

  final items = <TimelineItem>[];
  for (var i = 1; i < clockings.length; i++) {
    final p = clockings[i - 1], c = clockings[i];
    final a = p.time.millisecondsSinceEpoch, b = c.time.millisecondsSinceEpoch;
    if (!p.isIn && c.isIn) {
      // A break only makes sense after some worked time.
      if (items.isNotEmpty) items.add(TimelineItem.pause(p, c, b - a));
    } else {
      final lunch = lunchIn(a, b);
      items.add(TimelineItem.block(p, c, b - a - lunch, lunch));
    }
  }
  if (clockings.isNotEmpty) {
    final last = clockings.last;
    if (last.isIn) {
      final a = last.time.millisecondsSinceEpoch;
      final b = isToday ? (now ?? DateTime.now()).millisecondsSinceEpoch : a;
      final lunch = lunchIn(a, b);
      items.add(TimelineItem.block(last, null, isToday ? b - a - lunch : 0, lunch, open: isToday));
    } else if (clockings.length == 1) {
      items.add(TimelineItem.block(last, null, 0, 0));
    }
  }
  return items;
}

class DayRow {
  DayRow({required this.date, required this.key, required this.clockings, required this.off, required this.target, required this.ms, required this.pending, required this.cfg, required this.baseCfg, this.lunchEdited = false, this.anomalies = const [], this.absenceLabels = const []});
  final DateTime date;
  final String key;
  final List<Clocking> clockings;
  final String? off; // "Absent" | "Holiday"
  final int target;
  final int ms;
  final bool pending;
  final DayConfig cfg; // effective config of the day (lunch override applied)
  final DayConfig baseCfg; // weekly settings of that weekday
  final bool lunchEdited;
  final List<String> anomalies; // incidencias of the day
  final List<String> absenceLabels; // e.g. "U-Vacaciones"
}

class PeriodSummary {
  PeriodSummary(this.rows, this.total, this.target, this.fullTarget);
  final List<DayRow> rows;
  final int total;
  /// Target of the days due so far (past days and today); the whole period when it is over.
  final int target;
  /// Target of every working day of the period, including the days still to come.
  final int fullTarget;
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
  var total = 0, totalTarget = 0, fullTarget = 0;
  for (var w = first; !w.isAfter(last); w = DateTime(w.year, w.month, w.day + 7)) {
    final days = <({DateTime d, String key, DayConfig cfg, DayConfig base, CalendarDay? entry, String? off})>[];
    for (var i = 0; i < 5; i++) {
      final d = DateTime(w.year, w.month, w.day + i);
      final key = ymd(d);
      final entry = byDate[key];
      final off = entry == null ? null : entry.absences.isNotEmpty ? 'Absent' : entry.holiday ? 'Holiday' : null;
      days.add((d: d, key: key, cfg: settings.configFor(d), base: settings.days[d.weekday]!, entry: entry, off: off));
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
      fullTarget += target;
      // The week view keeps the full weekly target; in the month view days not due yet are left out.
      totalTarget += month && x.key.compareTo(today) > 0 ? 0 : target;
      rows.add(DayRow(date: x.d, key: x.key, clockings: clockings, off: x.off, target: target, ms: ms, pending: pending, cfg: x.cfg, baseCfg: x.base, lunchEdited: settings.hasLunchOverride(x.d), anomalies: x.entry?.anomalies ?? const [], absenceLabels: x.entry?.absenceLabels ?? const []));
    }
  }
  return PeriodSummary(rows, total, totalTarget, fullTarget);
}
