import 'package:flutter/material.dart';

import 'package:printing/printing.dart';

import '../api.dart';
import '../l10n.dart';
import '../pdf_report.dart';
import '../settings.dart';
import '../summary.dart';
import 'common.dart';
import 'day_detail.dart';

/// Week / month summary of worked time vs target, with history up to one year back.
/// Week: summary card plus one card per working day. Month: calendar with worked/target per day
/// and the month result at the bottom.
class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key, this.onLunchChanged});
  final VoidCallback? onLunchChanged;

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  bool _month = false;
  int _offset = 0;
  int _reload = 0; // bumped after a lunch override to rebuild the data
  String? _selected; // yyyy-MM-dd of the day whose detail is shown; "" = none, null = default (today)

  void _select(String key, String? shown) => setState(() => _selected = shown == key ? "" : key);

  PeriodSummary? _data; // last loaded summary, kept for the PDF export
  String? _dataKey;

  Future<PeriodSummary> _load() async {
    final key = '$_month$_offset$_reload';
    final s = await buildSummary(await AppSettings.load(), _month, _offset);
    _data = s;
    _dataKey = key;
    return s;
  }

  Future<void> _export() async {
    final messenger = ScaffoldMessenger.of(context);
    final s = _data;
    if (s == null || _dataKey != '$_month$_offset$_reload') {
      messenger.showSnackBar(SnackBar(content: Text(L10n.current.stillLoading)));
      return;
    }
    try {
      final month = periodRange(DateTime.now(), true, _offset).start;
      final name = await MyEraApi.instance.savedName() ?? '';
      final bytes = await buildMonthReportPdf(summary: s, month: month, employee: name);
      await Printing.sharePdf(bytes: bytes, filename: 'myera-${month.year}-${pad(month.month)}.pdf');
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(L10n.current.pdfError('$e'))));
    }
  }

  String _label(DateTime now) {
    final r = periodRange(now, _month, _offset);
    String dm(DateTime d) => '${pad(d.day)}/${pad(d.month)}';
    return _month ? '${monthName(r.start.month)} ${r.start.year}' : '${dm(r.start)} – ${dm(r.end)}';
  }

  bool _canGoBack(DateTime now) {
    final limit = DateTime(now.year - 1, now.month, now.day);
    return !periodRange(now, _month, _offset - 1).end.isBefore(limit);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    void lunchChanged() {
      setState(() => _reload++);
      widget.onLunchChanged?.call();
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: false, icon: const Icon(Icons.view_week_outlined), label: Text(context.l10n.week)),
              ButtonSegment(value: true, icon: const Icon(Icons.calendar_month_outlined), label: Text(context.l10n.month)),
            ],
            selected: {_month},
            onSelectionChanged: (s) => setState(() {
              _month = s.first;
              _offset = 0;
              _selected = null;
            }),
          ),
        ),
        PeriodNav(
          label: _label(now),
          onPrev: _canGoBack(now) ? () => setState(() { _offset--; _selected = null; }) : null,
          onNext: _offset < 0 ? () => setState(() { _offset++; _selected = null; }) : null,
          onToday: _offset < 0 ? () => setState(() { _offset = 0; _selected = null; }) : null,
          trailing: _month ? IconButton(icon: const Icon(Icons.picture_as_pdf_outlined), tooltip: context.l10n.exportPdf, onPressed: _export) : null,
        ),
        Expanded(
          child: AsyncBody<PeriodSummary>(
            key: ValueKey('$_month$_offset$_reload'),
            loader: _load,
            builder: (context, s) {
              // Current period: today is shown by default.
              final String? sel = _selected == "" ? null : _selected ?? (_offset == 0 && s.rows.any((r) => r.key == ymd(now)) ? ymd(now) : null);
              return _month
                  ? _MonthView(summary: s, start: periodRange(now, true, _offset).start, selected: sel, onSelect: (k) => _select(k, sel), current: _offset == 0, onLunchChanged: lunchChanged)
                  : _WeekView(summary: s, selected: sel, onSelect: (k) => _select(k, sel), onLunchChanged: lunchChanged);
            },
          ),
        ),
      ],
    );
  }
}

/// "7h 36m" style duration, but short ("7:36") for tight spaces.
String fmtShort(int ms) {
  final m = ms.abs() ~/ 60000;
  return '${m ~/ 60}:${pad(m % 60)}';
}

class _WeekView extends StatelessWidget {
  const _WeekView({required this.summary, required this.selected, required this.onSelect, required this.onLunchChanged});
  final VoidCallback onLunchChanged;
  final PeriodSummary summary;
  final String? selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final s = summary;
    final cs = Theme.of(context).colorScheme;
    final diff = s.total - s.target;
    final progress = s.fullTarget == 0 ? 0.0 : (s.total / s.fullTarget).clamp(0.0, 1.0);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        Card(
          elevation: 0,
          color: cs.primaryContainer.withValues(alpha: 0.45),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(fmtDuration(s.total), style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const Spacer(),
                    DiffChip(text: fmtSigned(diff), color: diffColor(context, pending: false, ok: diff >= 0), big: true),
                  ],
                ),
                const SizedBox(height: 2),
                Text(context.l10n.ofTargetThisWeek(fmtDuration(s.fullTarget)), style: TextStyle(color: cs.onSurfaceVariant)),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(value: progress, minHeight: 8, backgroundColor: cs.surface.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        for (final r in s.rows) _DayCard(row: r, selected: r.key == selected, onTap: () => onSelect(r.key)),
        for (final r in s.rows.where((r) => r.key == selected)) DayDetailCard.fromRow(r, onLunchChanged: onLunchChanged),
      ],
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({required this.row, required this.selected, required this.onTap});
  final DayRow row;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final r = row;
    final cs = Theme.of(context).colorScheme;
    final today = r.key == ymd(DateTime.now());
    final hasClockings = r.clockings.isNotEmpty;
    final ratio = r.target == 0 ? 0.0 : (r.ms / r.target).clamp(0.0, 1.0);
    final ok = r.ms >= r.target;
    final color = diffColor(context, pending: r.pending, ok: ok) ?? cs.onSurfaceVariant;

    final Widget trailing;
    if (hasClockings) {
      trailing = DiffChip(text: fmtSigned(r.ms - r.target), color: color);
    } else if (r.off != null) {
      trailing = DiffChip(text: offLabel(context.l10n, r.off!), color: cs.tertiary);
    } else {
      trailing = DiffChip(text: '–', color: cs.onSurfaceVariant);
    }

    return Card(
      margin: const EdgeInsets.only(top: 8),
      elevation: 0,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: selected || today ? cs.primary : cs.outlineVariant.withValues(alpha: 0.5), width: selected ? 2 : today ? 1.5 : 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 46,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(color: today ? cs.primary : cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(10)),
              child: Column(
                children: [
                  Text(weekdayShort(r.date.weekday), style: TextStyle(fontSize: 11, color: today ? cs.onPrimary : cs.onSurfaceVariant)),
                  Text('${r.date.day}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: today ? cs.onPrimary : cs.onSurface)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: r.off != null && !hasClockings
                  ? Text(context.l10n.noTargetToday, style: TextStyle(color: cs.onSurfaceVariant))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(TextSpan(children: [
                          TextSpan(text: hasClockings ? fmtDuration(r.ms) : '–', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                          TextSpan(text: '  / ${fmtDuration(r.target)}', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
                        ])),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(value: ratio, minHeight: 5, color: color, backgroundColor: cs.surfaceContainerHighest),
                        ),
                      ],
                    ),
            ),
            const SizedBox(width: 12),
            trailing,
          ],
        ),
        ),
      ),
    );
  }
}

class _MonthView extends StatelessWidget {
  const _MonthView({required this.summary, required this.start, required this.selected, required this.onSelect, required this.current, required this.onLunchChanged});
  final VoidCallback onLunchChanged;
  final PeriodSummary summary;
  final DateTime start;
  final String? selected;
  final ValueChanged<String> onSelect;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final s = summary;
    final cs = Theme.of(context).colorScheme;
    final byKey = {for (final r in s.rows) r.key: r};
    final gridStart = weekStart(start);
    final last = DateTime(start.year, start.month + 1, 0);
    final weeks = <DateTime>[];
    for (var w = gridStart; !w.isAfter(last); w = DateTime(w.year, w.month, w.day + 7)) {
      weeks.add(w);
    }
    final diff = s.total - s.target;

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
      children: [
        Row(
          children: [
            for (var n = 1; n <= 7; n++) Expanded(child: Center(child: Text(weekdayShort(n), style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)))),
          ],
        ),
        const SizedBox(height: 4),
        for (final w in weeks)
          Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: _MonthCell(
                    date: DateTime(w.year, w.month, w.day + i),
                    inMonth: DateTime(w.year, w.month, w.day + i).month == start.month,
                    row: byKey[ymd(DateTime(w.year, w.month, w.day + i))],
                    selected: ymd(DateTime(w.year, w.month, w.day + i)) == selected,
                    onTap: byKey[ymd(DateTime(w.year, w.month, w.day + i))] == null ? null : () => onSelect(ymd(DateTime(w.year, w.month, w.day + i))),
                  ),
                ),
            ],
          ),
        for (final r in s.rows.where((r) => r.key == selected)) DayDetailCard.fromRow(r, onLunchChanged: onLunchChanged),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          color: cs.primaryContainer.withValues(alpha: 0.45),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _stat(context, context.l10n.worked, fmtDuration(s.total))),
                    Expanded(child: _stat(context, context.l10n.target, fmtDuration(s.target))),
                    DiffChip(text: fmtSigned(diff), color: diffColor(context, pending: false, ok: diff >= 0), big: true),
                  ],
                ),
                if (current) ...[
                  const Divider(height: 24),
                  Row(
                    children: [
                      Expanded(child: _stat(context, context.l10n.monthTarget, fmtDuration(s.fullTarget))),
                      Expanded(child: _stat(context, s.fullTarget > s.total ? context.l10n.stillToWork : context.l10n.overMonthTarget, fmtDuration((s.fullTarget - s.total).abs()))),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8, left: 4),
          child: Text(context.l10n.monthFootnote,
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
        ),
      ],
    );
  }

  Widget _stat(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _MonthCell extends StatelessWidget {
  const _MonthCell({required this.date, required this.inMonth, required this.row, required this.selected, required this.onTap});
  final DateTime date;
  final bool inMonth;
  final DayRow? row;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final r = row;
    final today = ymd(date) == ymd(DateTime.now());
    final hasClockings = r != null && r.clockings.isNotEmpty;

    Color? tint;
    if (r != null && hasClockings) {
      tint = diffColor(context, pending: r.pending, ok: r.ms >= r.target);
    } else if (r?.off != null) {
      tint = cs.tertiary;
    }

    Widget? body;
    if (r != null && inMonth) {
      if (r.off != null && !hasClockings) {
        body = Text(r.off == 'Holiday' ? context.l10n.holidayInitial : context.l10n.absentInitial, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: cs.tertiary));
      } else {
        body = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(hasClockings ? fmtShort(r.ms) : '–', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: tint ?? cs.onSurface)),
            Text(fmtShort(r.target), style: TextStyle(fontSize: 9, color: cs.onSurfaceVariant)),
          ],
        );
      }
    }

    return GestureDetector(
      onTap: inMonth ? onTap : null,
      child: Container(
      height: 62,
      margin: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        color: !inMonth
            ? Colors.transparent
            : tint != null && (hasClockings || r?.off != null)
                ? tint.withValues(alpha: 0.10)
                : cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: selected ? Border.all(color: cs.primary, width: 2) : today ? Border.all(color: cs.primary.withValues(alpha: 0.5), width: 1.5) : null,
      ),
      child: !inMonth
          ? null
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${date.day}', style: TextStyle(fontSize: 11, color: today ? cs.primary : cs.onSurfaceVariant, fontWeight: today ? FontWeight.w700 : FontWeight.w400)),
                if (body != null) ...[const SizedBox(height: 2), body],
              ],
            ),
      ),
    );
  }
}
