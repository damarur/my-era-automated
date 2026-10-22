import 'package:flutter/material.dart';

import '../l10n.dart';
import '../scheduler.dart';
import '../settings.dart';
import '../theme_controller.dart';

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
        if (s.days[d]!.breakEnabled && toMin(s.days[d]!.breakEnd) - toMin(s.days[d]!.breakStart) < 30) weekdayShort(d)
    ];
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(short.isEmpty ? context.l10n.savedOk : context.l10n.savedWarnShortBreak(short.join(', ')))),
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
          title: Text(standard ? context.l10n.presetStandardTitle : context.l10n.presetIrregularTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(standard ? context.l10n.presetStandardDesc : context.l10n.presetIrregularDesc),
              const SizedBox(height: 12),
              _timeRow(context.l10n.start, start, (v) => setD(() => start = v)),
              _timeRow(context.l10n.breakFrom, bs, (v) => setD(() => bs = v)),
              _timeRow(context.l10n.breakTo, be, (v) => setD(() => be = v)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.l10n.cancel)),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(context.l10n.apply)),
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
          title: Text(context.l10n.autoClock),
          content: Text(context.l10n.autoClockWarning),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.l10n.cancel)),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(context.l10n.iUnderstand)),
          ],
        ),
      );
      if (ok != true) return;
      s.autoClockAck = true;
    }
    setState(() => s.autoClockEnabled = on);
    await _save();
  }

  Widget _section(BuildContext context, String title, {String? hint}) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: cs.primary)),
          if (hint != null) Padding(padding: const EdgeInsets.only(top: 2), child: Text(hint, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant))),
        ],
      ),
    );
  }

  Widget _card(BuildContext context, Widget child, {EdgeInsets margin = const EdgeInsets.symmetric(horizontal: 16)}) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: margin,
      elevation: 0,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5))),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = _s;
    return Scaffold(
      body: s == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                _section(context, context.l10n.settingsAppearance),
                _card(
                  context,
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ValueListenableBuilder<ThemeMode>(
                          valueListenable: ThemeController.instance,
                          builder: (context, mode, _) => SegmentedButton<ThemeMode>(
                            showSelectedIcon: false,
                            segments: [
                              ButtonSegment(value: ThemeMode.system, icon: const Icon(Icons.brightness_auto), label: Text(context.l10n.themeSystem)),
                              ButtonSegment(value: ThemeMode.light, icon: const Icon(Icons.light_mode), label: Text(context.l10n.themeLight)),
                              ButtonSegment(value: ThemeMode.dark, icon: const Icon(Icons.dark_mode), label: Text(context.l10n.themeDark)),
                            ],
                            selected: {mode},
                            onSelectionChanged: (v) => ThemeController.instance.set(v.first),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(context.l10n.settingsLanguage, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        const SizedBox(height: 6),
                        ValueListenableBuilder<Locale?>(
                          valueListenable: LocaleController.instance,
                          builder: (context, locale, _) => SegmentedButton<String>(
                            showSelectedIcon: false,
                            segments: [
                              ButtonSegment(value: 'system', icon: const Icon(Icons.language), label: Text(context.l10n.languageSystem)),
                              const ButtonSegment(value: 'en', label: Text('English')),
                              const ButtonSegment(value: 'es', label: Text('Español')),
                            ],
                            selected: {locale?.languageCode ?? 'system'},
                            onSelectionChanged: (v) async {
                              await LocaleController.instance.set(v.first == 'system' ? null : Locale(v.first));
                              // Reminders are planned with the texts of the current language.
                              await reschedule().catchError((Object _) {});
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _section(context, context.l10n.settingsClocking),
                _card(
                  context,
                  Column(
                    children: [
                      SwitchListTile(
                        secondary: const Icon(Icons.notifications_active_outlined),
                        title: Text(context.l10n.clockReminders),
                        subtitle: Text(context.l10n.clockRemindersSub),
                        value: s.remindersEnabled,
                        onChanged: (v) {
                          setState(() => s.remindersEnabled = v);
                          _save();
                        },
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      SwitchListTile(
                        secondary: const Icon(Icons.auto_mode_outlined),
                        title: Text(context.l10n.autoClock),
                        subtitle: Text(context.l10n.autoClockSub),
                        value: s.autoClockActive,
                        onChanged: _setAutoClock,
                      ),
                    ],
                  ),
                ),
                _section(context, context.l10n.weeklySchedule, hint: context.l10n.tapToChange),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(child: OutlinedButton.icon(icon: const Icon(Icons.bolt, size: 18), label: Text(context.l10n.presetStandard), onPressed: () => _applyPreset(true))),
                      const SizedBox(width: 8),
                      Expanded(child: OutlinedButton.icon(icon: const Icon(Icons.bolt, size: 18), label: Text(context.l10n.presetIrregular), onPressed: () => _applyPreset(false))),
                    ],
                  ),
                ),
                for (var d = 1; d <= 5; d++) _dayCard(context, s, d),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    context.l10n.scheduleFootnote,
                    style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
    );
  }

  /// Tappable time value with a small caption on top.
  Widget _timeTile(BuildContext context, String caption, IconData icon, String value, VoidCallback onTap) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Material(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: cs.outlineVariant)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(icon, size: 13, color: cs.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(caption, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                ]),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Compact switch: the default Material one is too big next to the time tiles.
  Widget _miniSwitch(bool value, ValueChanged<bool> onChanged) => SizedBox(
        height: 24,
        child: FittedBox(child: Switch(value: value, onChanged: onChanged, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap)),
      );

  Widget _dayCard(BuildContext context, AppSettings s, int d) {
    final cs = Theme.of(context).colorScheme;
    final c = s.days[d]!;
    void edit(void Function() f) {
      setState(f);
      _save();
    }

    Future<void> pick(String current, void Function(String) set) async {
      final v = await _pickTime(current);
      if (v != null) edit(() => set(v));
    }

    final net = toMin(c.outTime) - toMin(c.inTime) - (c.breakEnabled ? toMin(c.breakEnd) - toMin(c.breakStart) : 0);
    final netText = net > 0 ? context.l10n.netTime('${net ~/ 60}h ${(net % 60).toString().padLeft(2, '0')}m') : '';
    const gap = SizedBox(height: 12);
    const hgap = SizedBox(width: 8);

    return _card(
      context,
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 28,
              child: Row(
                children: [
                  Text(weekdayLong(d), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 8),
                  if (c.enabled) Text(netText, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                  const Spacer(),
                  _miniSwitch(c.enabled, (v) => edit(() => c.enabled = v)),
                ],
              ),
            ),
            if (c.enabled) ...[
              gap,
              Row(
                children: [
                  _timeTile(context, context.l10n.inLabel, Icons.login, c.inTime, () => pick(c.inTime, (v) => c.inTime = v)),
                  hgap,
                  _timeTile(context, context.l10n.outLabel, Icons.logout, c.outTime, () => pick(c.outTime, (v) => c.outTime = v)),
                  hgap,
                  _timeTile(context, context.l10n.target, Icons.flag_outlined, c.target, () => pick(c.target, (v) => c.target = v)),
                ],
              ),
              gap,
              SizedBox(
                height: 28,
                child: Row(
                  children: [
                    Icon(Icons.restaurant_outlined, size: 18, color: cs.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Expanded(child: Text(context.l10n.lunchBreak)),
                    _miniSwitch(c.breakEnabled, (v) => edit(() => c.breakEnabled = v)),
                  ],
                ),
              ),
              if (c.breakEnabled) ...[
                gap,
                Row(
                  children: [
                    _timeTile(context, context.l10n.fromLabel, Icons.schedule, c.breakStart, () => pick(c.breakStart, (v) => c.breakStart = v)),
                    hgap,
                    _timeTile(context, context.l10n.toLabel, Icons.schedule, c.breakEnd, () => pick(c.breakEnd, (v) => c.breakEnd = v)),
                    hgap,
                    const Expanded(child: SizedBox.shrink()),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
