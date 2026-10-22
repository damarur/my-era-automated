import 'package:flutter/material.dart';

import '../api.dart';
import '../l10n.dart';
import '../settings.dart';
import '../summary.dart';
import 'common.dart';

String _hm(DateTime t) => '${pad(t.hour)}:${pad(t.minute)}';

/// "1h", "30m", "1h 10m".
String _short(int ms) {
  final m = ms.abs() ~/ 60000;
  if (m < 60) return '${m}m';
  return m % 60 == 0 ? '${m ~/ 60}h' : '${m ~/ 60}h ${pad(m % 60)}m';
}

/// Detail of one day, shared by the summary (selected day) and the home screen (today):
/// result, one line per in/out block with its effective time (lunch break in between when it
/// falls inside the block), dashed separators for clocked breaks, absence and incidencias.
class DayDetailCard extends StatelessWidget {
  const DayDetailCard({
    super.key,
    required this.date,
    required this.clockings,
    required this.cfg,
    required this.target,
    this.off,
    this.absenceLabels = const [],
    this.anomalies = const [],
    this.title,
    this.baseCfg,
    this.lunchEdited = false,
    this.onLunchChanged,
  });

  factory DayDetailCard.fromRow(DayRow r, {String? title, VoidCallback? onLunchChanged}) => DayDetailCard(
        key: ValueKey(r.key),
        date: r.date,
        clockings: r.clockings,
        cfg: r.cfg,
        target: r.target,
        off: r.off,
        absenceLabels: r.absenceLabels,
        anomalies: r.anomalies,
        title: title,
        baseCfg: r.baseCfg,
        lunchEdited: r.lunchEdited,
        onLunchChanged: onLunchChanged,
      );

  final DateTime date;
  final List<Clocking> clockings;
  final DayConfig cfg;
  final int target;
  final String? off; // "Absent" | "Holiday"
  final List<String> absenceLabels;
  final List<String> anomalies;
  final String? title;

  /// Weekly settings of this weekday; the lunch break of this date can be overridden against it.
  final DayConfig? baseCfg;
  final bool lunchEdited;
  final VoidCallback? onLunchChanged;

  Future<void> _editLunch(BuildContext context) async {
    final result = await showModalBottomSheet<_LunchResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _LunchSheet(date: date, current: cfg, base: baseCfg!, edited: lunchEdited),
    );
    if (result == null) return;
    await LunchOverrides.set(date, result.override);
    onLunchChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final key = ymd(date);
    final isToday = key == ymd(now);
    final hasClockings = clockings.isNotEmpty;
    final open = hasClockings && clockings.last.isIn;
    final pending = key.compareTo(ymd(now)) > 0 || (isToday && (open || !hasClockings));
    final ms = effectiveMs(clockings, key, isToday, cfg, now);
    final color = diffColor(context, pending: pending, ok: ms >= target) ?? cs.onSurfaceVariant;
    final items = buildTimeline(clockings, key, isToday, cfg, now);

    return Card(
      margin: const EdgeInsets.only(top: 12),
      elevation: 0,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5))),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title ?? fmtLongDate(date),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
                if (hasClockings) DiffChip(text: fmtSigned(ms - target), color: color),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _kv(context, context.l10n.worked, hasClockings ? fmtDuration(ms) : '–'),
                _kv(context, context.l10n.target, off != null ? '–' : fmtDuration(target)),
              ],
            ),
            if (off == null && baseCfg != null) ...[
              const SizedBox(height: 4),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _editLunch(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.restaurant_outlined, size: 18, color: cs.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Text(context.l10n.lunch),
                      const SizedBox(width: 8),
                      if (lunchEdited) DiffChip(text: context.l10n.edited, color: cs.primary),
                      const Spacer(),
                      Text(
                        cfg.breakEnabled ? '${cfg.breakStart}–${cfg.breakEnd} (${_short((toMin(cfg.breakEnd) - toMin(cfg.breakStart)) * 60000)})' : context.l10n.none,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.edit_outlined, size: 16, color: cs.onSurfaceVariant),
                    ],
                  ),
                ),
              ),
            ],
            if (off != null) ...[
              const SizedBox(height: 12),
              Wrap(spacing: 6, children: [
                Chip(avatar: Icon(off == 'Holiday' ? Icons.celebration_outlined : Icons.beach_access_outlined, size: 16), label: Text(offLabel(context.l10n, off!))),
                for (final l in absenceLabels) Chip(label: Text(l)),
              ]),
            ],
            const Divider(height: 24),
            if (!hasClockings)
              Text(pending ? context.l10n.noClockingsYet : context.l10n.noClockings, style: TextStyle(color: cs.onSurfaceVariant))
            else
              for (final it in items) it.isBreak ? _BreakLine(it) : _BlockLine(it, pending: isToday && it.open, onLunchTap: baseCfg == null ? null : () => _editLunch(context)),
            if (anomalies.isNotEmpty) ...[
              const SizedBox(height: 8),
              for (final a in anomalies)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(children: [
                    Icon(Icons.warning_amber, size: 18, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Expanded(child: Text(a)),
                  ]),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _kv(BuildContext context, String k, String v) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(k, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          Text(v, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        ]),
      );
}

Widget _stamp(BuildContext context, Clocking c) {
  final cs = Theme.of(context).colorScheme;
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(c.isIn ? Icons.login : Icons.logout, size: 18, color: c.isIn ? Colors.green.shade600 : cs.error),
      const SizedBox(width: 6),
      Text(_hm(c.time), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
    ],
  );
}

/// One in -> out block: both clockings, the lunch break inside it (if any) and the effective time.
class _BlockLine extends StatelessWidget {
  const _BlockLine(this.item, {required this.pending, this.onLunchTap});
  final TimelineItem item;
  final bool pending;
  final VoidCallback? onLunchTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 14,
              runSpacing: 4,
              children: [
                _stamp(context, item.from),
                if (item.lunchMs > 0)
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: onLunchTap,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.restaurant_outlined, size: 16, color: cs.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(_short(item.lunchMs), style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                      ]),
                    ),
                  ),
                if (item.to != null) _stamp(context, item.to!) else Text(context.l10n.nowLabel, style: TextStyle(fontStyle: FontStyle.italic, color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          if (item.to != null || item.open)
            Text(
              fmtDuration(item.ms),
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: pending ? cs.onSurfaceVariant : null),
            ),
        ],
      ),
    );
  }
}

/// Clocked break (out then in): full width dashed line with the break length in the middle.
class _BreakLine extends StatelessWidget {
  const _BreakLine(this.item);
  final TimelineItem item;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final line = Expanded(child: CustomPaint(size: const Size.fromHeight(1), painter: _DashPainter(cs.outline)));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          line,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(context.l10n.breakDuration(fmtDuration(item.ms)), style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          ),
          line,
        ],
      ),
    );
  }
}

class _DashPainter extends CustomPainter {
  _DashPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 8) {
      canvas.drawLine(Offset(x, 0), Offset((x + 4).clamp(0, size.width), 0), p);
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => old.color != color;
}

/// Result of the lunch editor: [override] null means "back to the weekly settings".
class _LunchResult {
  _LunchResult(this.override);
  final LunchOverride? override;
}

/// Bottom sheet to change the lunch break of one date without touching the weekly settings.
class _LunchSheet extends StatefulWidget {
  const _LunchSheet({required this.date, required this.current, required this.base, required this.edited});
  final DateTime date;
  final DayConfig current;
  final DayConfig base;
  final bool edited;

  @override
  State<_LunchSheet> createState() => _LunchSheetState();
}

class _LunchSheetState extends State<_LunchSheet> {
  late bool _enabled = widget.current.breakEnabled;
  late String _start = widget.current.breakStart;
  late String _end = widget.current.breakEnd;

  static const _quick = [15, 30, 45, 60];

  int get _minutes => toMin(_end) - toMin(_start);

  Future<void> _pick(bool start) async {
    final m = toMin(start ? _start : _end);
    final t = await showTimePicker(context: context, initialTime: TimeOfDay(hour: m ~/ 60, minute: m % 60));
    if (t == null) return;
    setState(() => start ? _start = toHm(t.hour * 60 + t.minute) : _end = toHm(t.hour * 60 + t.minute));
  }

  void _save() {
    final o = LunchOverride(enabled: _enabled && _minutes > 0, start: _start, end: _end);
    Navigator.pop(context, _LunchResult(o.sameAs(widget.base) ? null : o));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final d = widget.date;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.lunchBreakOn(fmtLongDate(d)), style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 2),
          Text(context.l10n.lunchOnlyThisDay, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              ChoiceChip(label: Text(context.l10n.none), selected: !_enabled, onSelected: (_) => setState(() => _enabled = false)),
              for (final q in _quick)
                ChoiceChip(
                  label: Text(_short(q * 60000)),
                  selected: _enabled && _minutes == q,
                  onSelected: (_) => setState(() {
                    _enabled = true;
                    _end = toHm(toMin(_start) + q);
                  }),
                ),
            ],
          ),
          if (_enabled) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: () => _pick(true), child: Text(context.l10n.fromTime(_start)))),
                const SizedBox(width: 8),
                Expanded(child: OutlinedButton(onPressed: () => _pick(false), child: Text(context.l10n.toTime(_end)))),
              ],
            ),
            if (_minutes <= 0) Padding(padding: const EdgeInsets.only(top: 6), child: Text(context.l10n.endAfterStart, style: TextStyle(fontSize: 12, color: cs.error))),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              if (widget.edited) TextButton(onPressed: () => Navigator.pop(context, _LunchResult(null)), child: Text(context.l10n.resetToSettings)),
              const Spacer(),
              TextButton(onPressed: () => Navigator.pop(context), child: Text(context.l10n.cancel)),
              const SizedBox(width: 8),
              FilledButton(onPressed: _enabled && _minutes <= 0 ? null : _save, child: Text(context.l10n.save)),
            ],
          ),
        ],
      ),
    );
  }
}
