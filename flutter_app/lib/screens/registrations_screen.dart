import 'package:flutter/material.dart';

import '../api.dart';
import 'common.dart';

/// Monthly "Fichajes personales" table: schedule, absence, card clockings and balance.
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
          child: AsyncBody<Registrations>(
            key: ValueKey(_offset),
            loader: () => MyEraApi.instance.registrations(first, DateTime(first.year, first.month + 1, 0)),
            builder: (context, reg) {
              final cs = Theme.of(context).colorScheme;
              // Columns: 0 date, 1 schedule, 2 absence, 3 clockings, 4 balance.
              final total = reg.totals.length > 4 ? reg.totals[4] : null;
              return ListView(
                children: [
                  for (final r in reg.rows)
                    ListTile(
                      dense: true,
                      tileColor: r.date == ymd(now) ? cs.primaryContainer.withValues(alpha: 0.4) : null,
                      leading: r.anomaly ? Icon(Icons.warning_amber, color: cs.error) : null,
                      title: Text(_col(r, 0), style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text([_col(r, 1), _col(r, 2)].where((e) => e.isNotEmpty).join(' · ')),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(_col(r, 3)),
                          if (_col(r, 4).isNotEmpty && _col(r, 4) != '-') Text('BH ${_col(r, 4)}', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  if (total != null)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Totals · ${reg.titles.length > 4 ? reg.titles[4] : ''} $total', style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  String _col(RegistrationRow r, int i) => i < r.columns.length ? r.columns[i] : '';
}
