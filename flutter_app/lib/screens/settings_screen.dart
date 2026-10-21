import 'package:flutter/material.dart';

import '../scheduler.dart';
import '../settings.dart';
import '../theme_controller.dart';
import 'common.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  AppSettings? _s;

  @override
  void initState() {
    super.initState();
    AppSettings.load().then((s) => setState(() => _s = s));
  }

  Future<void> _save() async {
    final s = _s!;
    await s.save();
    await reschedule().catchError((Object _) {});
    if (!mounted) return;
    final short = [
      for (var d = 1; d <= 5; d++)
        if (s.days[d]!.breakEnabled && toMin(s.days[d]!.breakEnd) - toMin(s.days[d]!.breakStart) < 30) dayNames[d - 1]
    ];
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(short.isEmpty ? 'Saved' : 'Saved. Warning: break under 30 min on ${short.join(', ')}')),
    );
  }

  Future<String?> _pickTime(String current) async {
    final m = toMin(current);
    final t = await showTimePicker(context: context, initialTime: TimeOfDay(hour: m ~/ 60, minute: m % 60));
    return t == null ? null : toHm(t.hour * 60 + t.minute);
  }

  Future<void> _applyPreset(bool standard) async {
    String start = standard ? '09:00' : '08:00';
    String bs = '13:00';
    String be = standard ? '13:30' : '14:00';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: Text(standard ? 'Standard 7h 36m' : 'Irregular schedule'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(standard ? '7h 36m per day from the start time, with the break below. Clock out is calculated.' : '8h Mon–Thu (start + 8h + break) and 6h on Fri without break (start + 6h).'),
              const SizedBox(height: 12),
              _timeRow('Start', start, (v) => setD(() => start = v)),
              _timeRow('Break from', bs, (v) => setD(() => bs = v)),
              _timeRow('Break to', be, (v) => setD(() => be = v)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Apply')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    setState(() => _s!.days = standard ? standardPreset(start: start, breakStart: bs, breakEnd: be) : irregularPreset(start: start, breakStart: bs, breakEnd: be));
    await _save();
  }

  Widget _timeRow(String label, String value, ValueChanged<String> onChanged) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        TextButton(
          onPressed: () async {
            final v = await _pickTime(value);
            if (v != null) onChanged(v);
          },
          child: Text(value),
        ),
      ],
    );
  }

  Future<void> _setAutoClock(bool on) async {
    final s = _s!;
    if (on && !s.autoClockAck) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Auto clock'),
          content: const Text(
            'The app will clock in and out for you at the scheduled times, even when it is closed. '
            'Android may delay or skip it (battery saver, device asleep). It re-checks MyEra first and '
            'never doubles a clocking, but you stay responsible for your clockings. Keep checking them.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('I understand')),
          ],
        ),
      );
      if (ok != true) return;
      s.autoClockAck = true;
    }
    setState(() => s.autoClockEnabled = on);
    await _save();
  }

  @override
  Widget build(BuildContext context) {
    final s = _s;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: s == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: ValueListenableBuilder<ThemeMode>(
                    valueListenable: ThemeController.instance,
                    builder: (context, mode, _) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Theme'),
                        const SizedBox(height: 8),
                        SegmentedButton<ThemeMode>(
                          showSelectedIcon: false,
                          segments: const [
                            ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.brightness_auto), label: Text('System')),
                            ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode), label: Text('Light')),
                            ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode), label: Text('Dark')),
                          ],
                          selected: {mode},
                          onSelectionChanged: (v) => ThemeController.instance.set(v.first),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(),
                SwitchListTile(
                  title: const Text('Clock reminders'),
                  subtitle: const Text('Notification at each scheduled clock in/out'),
                  value: s.remindersEnabled,
                  onChanged: (v) {
                    setState(() => s.remindersEnabled = v);
                    _save();
                  },
                ),
                SwitchListTile(
                  title: const Text('Auto clock'),
                  subtitle: const Text('Clock in/out automatically at the scheduled times'),
                  value: s.autoClockActive,
                  onChanged: _setAutoClock,
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(child: OutlinedButton(onPressed: () => _applyPreset(true), child: const Text('Preset: Standard'))),
                      const SizedBox(width: 8),
                      Expanded(child: OutlinedButton(onPressed: () => _applyPreset(false), child: const Text('Preset: Irregular'))),
                    ],
                  ),
                ),
                for (var d = 1; d <= 5; d++) _dayCard(s, d),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'The break is unpaid and deducted from the daily worked time. The minimum required break is 30 min; switch the break off for days without one. The daily target is only used to compare against the worked time in the summary.',
                    style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _dayCard(AppSettings s, int d) {
    final c = s.days[d]!;
    void edit(void Function() f) {
      setState(f);
      _save();
    }

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        child: Column(
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(dayNames[d - 1], style: const TextStyle(fontWeight: FontWeight.w600)),
              value: c.enabled,
              onChanged: (v) => edit(() => c.enabled = v),
            ),
            if (c.enabled) ...[
              _timeRow('Clock in', c.inTime, (v) => edit(() => c.inTime = v)),
              _timeRow('Clock out', c.outTime, (v) => edit(() => c.outTime = v)),
              _timeRow('Target', c.target, (v) => edit(() => c.target = v)),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Lunch break'),
                value: c.breakEnabled,
                onChanged: (v) => edit(() => c.breakEnabled = v),
              ),
              if (c.breakEnabled) ...[
                _timeRow('Break from', c.breakStart, (v) => edit(() => c.breakStart = v)),
                _timeRow('Break to', c.breakEnd, (v) => edit(() => c.breakEnd = v)),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
