import 'package:flutter/material.dart';

import '../api.dart';
import '../l10n.dart';
import '../settings.dart';
import 'common.dart';
import 'day_detail.dart';
import 'requests_screen.dart';

class _HomeData {
  _HomeData(this.today, this.settings);
  final CalendarDay? today;
  final AppSettings settings;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onClocked, required this.onRequestCreated});
  final VoidCallback onClocked;
  final VoidCallback onRequestCreated;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _busy = false;
  final _body = GlobalKey<AsyncBodyState<_HomeData>>();

  Future<_HomeData> _load() async {
    final api = MyEraApi.instance;
    final now = DateTime.now();
    final results = await Future.wait<Object?>([api.calendar(now, now), AppSettings.load()]);
    final days = results[0] as List<CalendarDay>;
    return _HomeData(days.where((d) => d.date == ymd(now)).firstOrNull, results[1] as AppSettings);
  }

  Future<void> _clock(int type) async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await MyEraApi.instance.clock(type);
      if (!mounted) return;
      final t = TimeOfDay.now().format(context);
      messenger.showSnackBar(SnackBar(content: Text(type == 1 ? context.l10n.clockedInAt(t) : context.l10n.clockedOutAt(t))));
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
        final cfg = data.settings.days[now.weekday] == null ? null : data.settings.configFor(now);
        final target = data.today?.off == true ? 0 : (cfg?.targetMs ?? 0);
        final cs = Theme.of(context).colorScheme;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('${weekdayShort(now.weekday)} ${pad(now.day)}/${pad(now.month)}', style: Theme.of(context).textTheme.headlineSmall),
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
                    label: Text(context.l10n.clockIn),
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: _busy || !isIn ? null : () => _clock(2),
                    icon: const Icon(Icons.logout),
                    label: Text(context.l10n.clockOut),
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                if (await startNewRequest(context)) widget.onRequestCreated();
              },
              icon: const Icon(Icons.add),
              label: Text(context.l10n.newRequest),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            ),
            const SizedBox(height: 4),
            if (cfg != null)
              DayDetailCard(
                date: now,
                clockings: clockings,
                cfg: cfg,
                target: target,
                off: data.today?.off == true ? (data.today!.absences.isNotEmpty ? 'Absent' : 'Holiday') : null,
                absenceLabels: data.today?.absenceLabels ?? const [],
                anomalies: data.today?.anomalies ?? const [],
                title: context.l10n.today,
                baseCfg: data.settings.days[now.weekday],
                lunchEdited: data.settings.hasLunchOverride(now),
                onLunchChanged: widget.onClocked,
              ),
          ],
        );
      },
    );
  }

}
