import 'package:flutter/material.dart';

import '../api.dart';
import '../l10n.dart';
import 'common.dart';

/// Balances and counters of the employee (vacation days, banked hours...).
class CountersScreen extends StatelessWidget {
  const CountersScreen({super.key});

  String _num(num? v) => v == null ? '–' : (v == v.roundToDouble() ? v.toInt().toString() : v.toString());

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AsyncBody<List<Counter>>(
      loader: MyEraApi.instance.counters,
      builder: (context, counters) {
        if (counters.isEmpty) return ListView(children: [const SizedBox(height: 80), Center(child: Text(context.l10n.noCounters))]);
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: counters.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final c = counters[i];
            return Card(
              margin: EdgeInsets.zero,
              elevation: 0,
              color: cs.surfaceContainerLow,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5))),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Expanded(child: Text(c.label, style: const TextStyle(fontSize: 15))),
                    const SizedBox(width: 12),
                    Text(_num(c.value), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                    if (c.unit.isNotEmpty) ...[const SizedBox(width: 4), Text(c.unit, style: TextStyle(color: cs.onSurfaceVariant))],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
