import 'package:flutter/material.dart';

import '../api.dart';
import '../settings.dart';
import '../summary.dart';
import 'common.dart';

/// Week / month summary of worked time vs target, with history up to one year back.
class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  bool _month = false;
  int _offset = 0;

  Future<PeriodSummary> _load() async => buildSummary(await AppSettings.load(), _month, _offset);

  String _label(DateTime now) {
    final r = periodRange(now, _month, _offset);
    String dm(DateTime d) => '${pad(d.day)}/${pad(d.month)}';
    return _month ? '${monthNames[r.start.month - 1]} ${r.start.year}' : '${dm(r.start)} – ${dm(r.end)}';
  }

  bool _canGoBack(DateTime now) {
    final limit = DateTime(now.year - 1, now.month, now.day);
    return !periodRange(now, _month, _offset - 1).end.isBefore(limit);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: SegmentedButton<bool>(
            segments: const [ButtonSegment(value: false, label: Text('Week')), ButtonSegment(value: true, label: Text('Month'))],
            selected: {_month},
            onSelectionChanged: (s) => setState(() {
              _month = s.first;
              _offset = 0;
            }),
          ),
        ),
        PeriodNav(
          label: _label(now),
          onPrev: _canGoBack(now) ? () => setState(() => _offset--) : null,
          onNext: _offset < 0 ? () => setState(() => _offset++) : null,
          onToday: _offset < 0 ? () => setState(() => _offset = 0) : null,
        ),
        Expanded(
          child: AsyncBody<PeriodSummary>(
            key: ValueKey('$_month$_offset'),
            loader: _load,
            builder: (context, s) => ListView(
              children: [
                for (final r in s.rows) _row(context, r),
                const Divider(height: 24),
                _totals(context, s),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _row(BuildContext context, DayRow r) {
    final cs = Theme.of(context).colorScheme;
    final hasClockings = r.clockings.isNotEmpty;
    final String diff;
    Color? color;
    if (hasClockings) {
      diff = fmtSigned(r.ms - r.target);
      color = diffColor(context, pending: r.pending, ok: r.ms >= r.target);
    } else {
      diff = r.off ?? '–';
      color = r.off != null ? cs.onSurfaceVariant : null;
    }
    final today = r.key == ymd(DateTime.now());
    return Container(
      color: today ? cs.primaryContainer.withValues(alpha: 0.4) : null,
      child: ListTile(
        dense: true,
        leading: SizedBox(
          width: 52,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [Text(dayNames[r.date.weekday - 1], style: const TextStyle(fontWeight: FontWeight.w600)), Text('${pad(r.date.day)}/${pad(r.date.month)}')],
          ),
        ),
        title: Text(hasClockings ? fmtDuration(r.ms) : '–'),
        subtitle: Text(r.off != null ? '${r.off}' : 'Target ${fmtDuration(r.target)}'),
        trailing: Text(diff, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _totals(BuildContext context, PeriodSummary s) {
    final diff = s.total - s.target;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('${_month ? 'Month' : 'Week'} ${fmtDuration(s.total)}', style: const TextStyle(fontWeight: FontWeight.w600)),
          Text('Target ${fmtDuration(s.target)}'),
          Text(fmtSigned(diff), style: TextStyle(fontWeight: FontWeight.w700, color: diffColor(context, pending: false, ok: diff >= 0))),
        ],
      ),
    );
  }
}
