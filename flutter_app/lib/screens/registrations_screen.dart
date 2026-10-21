import 'package:flutter/material.dart';

import '../api.dart';
import '../settings.dart';
import '../summary.dart';
import 'common.dart';

class _MonthData {
  _MonthData(this.reg, this.summary, this.anomalies);
  final Registrations reg;
  final PeriodSummary summary;
  final Map<String, List<String>> anomalies; // date -> incidencias labels
}

/// Monthly "Fichajes personales" table: schedule, absence, card clockings and balance, with the
/// month balance, the progress to date and the explanation of each day's incidencias.
class RegistrationsScreen extends StatefulWidget {
  const RegistrationsScreen({super.key});

  @override
  State<RegistrationsScreen> createState() => _RegistrationsScreenState();
}

class _RegistrationsScreenState extends State<RegistrationsScreen> {
  int _offset = 0;

  DateTime get _first {
    final n = DateTime.now();
    return DateTime(n.year, n.month + _offset, 1);
  }

  Future<_MonthData> _load(DateTime first) async {
    final api = MyEraApi.instance;
    final last = DateTime(first.year, first.month + 1, 0);
    final settings = await AppSettings.load();
    final results = await Future.wait<Object>([
      api.registrations(first, last),
      buildSummary(settings, true, _offset),
      api.calendar(first, last),
    ]);
    final days = results[2] as List<CalendarDay>;
    return _MonthData(
      results[0] as Registrations,
      results[1] as PeriodSummary,
      {for (final d in days) if (d.anomalies.isNotEmpty) d.date: d.anomalies},
    );
  }

  @override
  Widget build(BuildContext context) {
    final first = _first;
    final now = DateTime.now();
    final limit = DateTime(now.year - 1, now.month, 1);
    return Column(
      children: [
        PeriodNav(
          label: '${monthNames[first.month - 1]} ${first.year}',
          onPrev: first.isAfter(limit) ? () => setState(() => _offset--) : null,
          onNext: _offset < 0 ? () => setState(() => _offset++) : null,
          onToday: _offset < 0 ? () => setState(() => _offset = 0) : null,
        ),
        Expanded(
          child: AsyncBody<_MonthData>(
            key: ValueKey(_offset),
            loader: () => _load(first),
            builder: (context, data) {
              final cs = Theme.of(context).colorScheme;
              final reg = data.reg;
              // Columns: 0 date, 1 schedule, 2 absence, 3 clockings, 4 balance.
              final total = reg.totals.length > 4 ? reg.totals[4] : null;
              return ListView(
                children: [
                  _MonthCard(summary: data.summary, current: _offset == 0),
                  for (final r in reg.rows) _row(context, r, data.anomalies[r.date] ?? const [], now),
                  if (total != null && total.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Totals · ${reg.titles.length > 4 ? reg.titles[4] : ''} $total', style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    child: Text('⚠ = incidencia reported by MyEra for that day (red while unapproved). Tap a day to see it.', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _row(BuildContext context, RegistrationRow r, List<String> anomalies, DateTime now) {
    final cs = Theme.of(context).colorScheme;
    String col(int i) => i < r.columns.length ? r.columns[i] : '';
    final labels = anomalies.isEmpty && r.anomaly ? const ['Incidencia'] : anomalies;
    final warnColor = r.unapproved ? cs.error : Colors.orange.shade700;
    return ListTile(
      dense: true,
      tileColor: r.date == ymd(now) ? cs.primaryContainer.withValues(alpha: 0.4) : null,
      leading: r.anomaly ? Icon(Icons.warning_amber, color: warnColor) : null,
      title: Text(col(0), style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        [
          [col(1), col(2)].where((e) => e.isNotEmpty).join(' · '),
          if (r.anomaly) '⚠ ${labels.join(', ')}',
        ].where((e) => e.isNotEmpty).join('\n'),
      ),
      isThreeLine: r.anomaly,
      onTap: r.anomaly ? () => _anomalyDialog(context, r, labels) : null,
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(col(3)),
          if (col(4).isNotEmpty && col(4) != '-') Text('BH ${col(4)}', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }

  void _anomalyDialog(BuildContext context, RegistrationRow r, List<String> labels) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(r.columns.isNotEmpty ? r.columns.first : r.date),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final l in labels) Text('• $l'),
            const SizedBox(height: 12),
            Text(r.unapproved ? 'Not approved yet.' : 'Already approved.'),
            if (r.columns.length > 3 && r.columns[3].isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text('Clockings: ${r.columns[3]}')),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
      ),
    );
  }
}

class _MonthCard extends StatelessWidget {
  const _MonthCard({required this.summary, required this.current});
  final PeriodSummary summary;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final today = ymd(DateTime.now());
    // Closed days only: a day still open today would make the comparison look behind.
    final closed = summary.rows.where((r) => r.key.compareTo(today) <= 0 && !r.pending).toList();
    final worked = closed.fold<int>(0, (s, r) => s + r.ms);
    final target = closed.fold<int>(0, (s, r) => s + r.target);
    final diff = worked - target;
    final todayRow = summary.rows.where((r) => r.key == today && r.pending).firstOrNull;
    final remaining = summary.fullTarget - summary.total;
    Widget line(String label, String value, {Color? color, bool bold = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [Text(label), Text(value, style: TextStyle(color: color, fontWeight: bold ? FontWeight.w700 : FontWeight.w500))],
          ),
        );
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            line(current ? 'Worked (closed days)' : 'Worked', fmtDuration(worked)),
            line(current ? 'Target (closed days)' : 'Target', fmtDuration(target)),
            line(diff >= 0 ? 'Ahead' : 'Behind', fmtSigned(diff), color: diff >= 0 ? Colors.green.shade600 : cs.error, bold: true),
            if (todayRow != null) line('Today so far', '${fmtDuration(todayRow.ms)} / ${fmtDuration(todayRow.target)}'),
            if (current) ...[
              const Divider(height: 20),
              line('Month target', fmtDuration(summary.fullTarget)),
              line('Worked incl. today', fmtDuration(summary.total)),
              line(
                remaining > 0 ? 'Still to work' : 'Month target reached',
                remaining > 0 ? fmtDuration(remaining) : fmtSigned(-remaining),
                bold: true,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
