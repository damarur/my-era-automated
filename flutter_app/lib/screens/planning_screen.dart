import 'package:flutter/material.dart';

import '../api.dart';
import 'common.dart';

/// Personal planning: month grid (Mon-Sun) with the day schedule and absences.
class PlanningScreen extends StatefulWidget {
  const PlanningScreen({super.key});

  @override
  State<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends State<PlanningScreen> {
  int _offset = 0;

  Future<Map<String, CalendarDay>> _load(DateTime first) async {
    final last = DateTime(first.year, first.month + 1, 0);
    final start = DateTime(first.year, first.month, 1 - (first.weekday - 1));
    final end = DateTime(last.year, last.month, last.day + (7 - last.weekday));
    final days = await MyEraApi.instance.calendar(start, end);
    return {for (final d in days) d.date: d};
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final first = DateTime(now.year, now.month + _offset, 1);
    return Column(
      children: [
        PeriodNav(
          label: '${monthNames[first.month - 1]} ${first.year}',
          onPrev: () => setState(() => _offset--),
          onNext: () => setState(() => _offset++),
          onToday: _offset != 0 ? () => setState(() => _offset = 0) : null,
        ),
        Expanded(
          child: AsyncBody<Map<String, CalendarDay>>(
            key: ValueKey(_offset),
            loader: () => _load(first),
            builder: (context, byDate) {
              final cs = Theme.of(context).colorScheme;
              final start = DateTime(first.year, first.month, 1 - (first.weekday - 1));
              final weeks = ((DateTime(first.year, first.month + 1, 0).day + first.weekday - 1) / 7).ceil();
              return ListView(
                padding: const EdgeInsets.all(8),
                children: [
                  Row(children: [for (final n in dayNames) Expanded(child: Center(child: Text(n, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant))))]),
                  const SizedBox(height: 4),
                  for (var w = 0; w < weeks; w++)
                    Row(
                      children: [
                        for (var d = 0; d < 7; d++) Expanded(child: _cell(context, DateTime(start.year, start.month, start.day + w * 7 + d), first, byDate)),
                      ],
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _cell(BuildContext context, DateTime date, DateTime month, Map<String, CalendarDay> byDate) {
    final cs = Theme.of(context).colorScheme;
    final entry = byDate[ymd(date)];
    final inMonth = date.month == month.month;
    final isToday = ymd(date) == ymd(DateTime.now());
    final abs = entry?.absenceColor;
    final label = entry == null
        ? ''
        : entry.absences.isNotEmpty
            ? (entry.absenceShort ?? 'A')
            : entry.holiday
                ? 'H'
                : (entry.scheduleLabel ?? '');
    final rest = entry != null && entry.scheduleLabel != null && entry.scheduleLabel!.toLowerCase().contains('descanso');
    return GestureDetector(
      onTap: entry == null ? null : () => _details(context, date, entry),
      child: Opacity(
        opacity: inMonth ? 1 : 0.35,
        child: Container(
          height: 64,
          margin: const EdgeInsets.all(1.5),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: abs != null ? hexColor(abs, cs.surfaceContainerHighest).withValues(alpha: 0.85) : (rest ? cs.surfaceContainerHighest : cs.surfaceContainerLow),
            borderRadius: BorderRadius.circular(6),
            border: isToday ? Border.all(color: cs.primary, width: 2) : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${date.day}', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: abs != null ? Colors.white : null)),
              Expanded(child: Text(label, overflow: TextOverflow.fade, style: TextStyle(fontSize: 10, color: abs != null ? Colors.white : cs.onSurfaceVariant))),
            ],
          ),
        ),
      ),
    );
  }

  void _details(BuildContext context, DateTime date, CalendarDay e) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${dayNames[date.weekday - 1]} ${pad(date.day)}/${pad(date.month)}/${date.year}', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (e.scheduleLabel != null) Text('Schedule: ${e.scheduleLabel}'),
            for (final a in e.absences) Text('Absence: $a'),
            if (e.holiday) const Text('Public holiday'),
            if (e.clockings.isNotEmpty) Text('Clockings: ${e.clockings.map((c) => '${c.isIn ? '→' : '←'} ${pad(c.time.hour)}:${pad(c.time.minute)}').join('  ')}'),
            for (final n in e.notes.where((n) => n.isNotEmpty)) Text('Note: $n'),
          ],
        ),
      ),
    );
  }
}
