import 'package:flutter/material.dart';

import '../api.dart';
import '../settings.dart';
import '../summary.dart';
import 'common.dart';

class _HomeData {
  _HomeData(this.today, this.counters, this.settings);
  final CalendarDay? today;
  final List<Counter> counters;
  final AppSettings settings;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onClocked});
  final VoidCallback onClocked;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _busy = false;
  final _body = GlobalKey<AsyncBodyState<_HomeData>>();

  Future<_HomeData> _load() async {
    final api = MyEraApi.instance;
    final now = DateTime.now();
    final results = await Future.wait<Object?>([api.calendar(now, now), api.counters(), AppSettings.load()]);
    final days = results[0] as List<CalendarDay>;
    return _HomeData(days.where((d) => d.date == ymd(now)).firstOrNull, results[1] as List<Counter>, results[2] as AppSettings);
  }

  Future<void> _clock(int type) async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await MyEraApi.instance.clock(type);
      if (!mounted) return;
      final t = TimeOfDay.now().format(context);
      messenger.showSnackBar(SnackBar(content: Text('${type == 1 ? 'Clocked in' : 'Clocked out'} at $t')));
      widget.onClocked();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AsyncBody<_HomeData>(
      key: _body,
      loader: _load,
      builder: (context, data) {
        final clockings = data.today?.clockings ?? const <Clocking>[];
        final isIn = clockings.isNotEmpty && clockings.last.isIn;
        final now = DateTime.now();
        final cfg = data.settings.days[now.weekday];
        final worked = cfg == null ? 0 : effectiveMs(clockings, ymd(now), true, cfg, now);
        final target = data.today?.off == true ? 0 : (cfg?.targetMs ?? 0);
        final cs = Theme.of(context).colorScheme;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('${dayNames[now.weekday - 1]} ${pad(now.day)}/${pad(now.month)}', style: Theme.of(context).textTheme.headlineSmall),
            Text(
              [if (data.today?.scheduleLabel != null) data.today!.scheduleLabel!, ...?data.today?.absences].join(' · '),
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _busy || isIn ? null : () => _clock(1),
                    icon: const Icon(Icons.login),
                    label: const Text('Clock in'),
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: _busy || !isIn ? null : () => _clock(2),
                    icon: const Icon(Icons.logout),
                    label: const Text('Clock out'),
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Today', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    if (clockings.isEmpty) const Text('No clockings yet') else Wrap(spacing: 8, runSpacing: 4, children: [for (final c in clockings) _ClockChip(c)]),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Worked ${fmtDuration(worked)}'),
                        Text('Target ${fmtDuration(target)}'),
                        Text(
                          fmtSigned(worked - target),
                          style: TextStyle(fontWeight: FontWeight.w600, color: diffColor(context, pending: isIn || clockings.isEmpty, ok: worked >= target)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Counters', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Card(
              child: Column(
                children: [
                  for (final c in data.counters)
                    ListTile(dense: true, title: Text(c.label), trailing: Text('${_num(c.value)} ${c.unit}', style: const TextStyle(fontWeight: FontWeight.w600))),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  String _num(num? v) => v == null ? '–' : (v == v.roundToDouble() ? v.toInt().toString() : v.toString());
}

class _ClockChip extends StatelessWidget {
  const _ClockChip(this.c);
  final Clocking c;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(c.isIn ? Icons.login : Icons.logout, size: 16),
      label: Text('${pad(c.time.hour)}:${pad(c.time.minute)}'),
      visualDensity: VisualDensity.compact,
    );
  }
}
