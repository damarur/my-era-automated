import 'package:flutter/material.dart';

import '../api.dart';
import 'common.dart';

String _hm(TimeOfDay t) => '${pad(t.hour)}:${pad(t.minute)}';

Future<bool> _confirmSend(BuildContext context, String summary) async {
  return await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Send request?'),
          content: Text(summary),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Send')),
          ],
        ),
      ) ??
      false;
}

/// New absence request. Pops `true` when it was sent.
class NewAbsenceScreen extends StatefulWidget {
  const NewAbsenceScreen({super.key});

  @override
  State<NewAbsenceScreen> createState() => _NewAbsenceScreenState();
}

class _NewAbsenceScreenState extends State<NewAbsenceScreen> {
  AbsenceType? _type;
  DateTime? _start;
  DateTime? _end;
  int _part = 0; // 0 = full day(s), 1 = first part, 2 = second part, 3 = hours
  TimeOfDay? _from;
  TimeOfDay? _to;
  final _remark = TextEditingController();
  bool _busy = false;
  late final Future<List<AbsenceType>> _types = MyEraApi.instance.absenceTypes();

  Future<DateTime?> _pickDate(DateTime? initial) => showDatePicker(
        context: context,
        initialDate: initial ?? DateTime.now(),
        firstDate: DateTime.now().subtract(const Duration(days: 365)),
        lastDate: DateTime.now().add(const Duration(days: 730)),
      );

  String? _validate() {
    final t = _type;
    if (t == null) return 'Choose an absence type';
    if (_start == null) return 'Choose a date';
    if (_part == 0 && t.allowFullday && _end != null && _end!.isBefore(_start!)) return 'End date is before start date';
    if (_part == 3 && (_from == null || _to == null)) return 'Choose the hours';
    if (t.needRemark && _remark.text.trim().isEmpty) return 'A remark is required for this type';
    if (t.needFile) return 'This type needs an attachment, which the app does not support yet. Use the web app.';
    return null;
  }

  Future<void> _send() async {
    final error = _validate();
    final messenger = ScaffoldMessenger.of(context);
    if (error != null) {
      messenger.showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    final t = _type!;
    final fullDays = _part == 0 && t.allowFullday;
    final end = fullDays ? (_end ?? _start!) : _start!;
    final summary = '${t.label}\n${ymd(_start!)}${end != _start ? ' – ${ymd(end)}' : ''}'
        '${_part == 1 ? ' (first part)' : _part == 2 ? ' (second part)' : _part == 3 ? ' ${_hm(_from!)}-${_hm(_to!)}' : ''}';
    if (!await _confirmSend(context, summary) || !mounted) return;
    setState(() => _busy = true);
    try {
      await MyEraApi.instance.requestAbsence(
        t,
        start: _start!,
        end: end,
        dayPart: _part == 1 || _part == 2 ? _part : 0,
        hourStart: _part == 3 ? _hm(_from!) : null,
        hourEnd: _part == 3 ? _hm(_to!) : null,
        remark: _remark.text.trim(),
      );
      messenger.showSnackBar(const SnackBar(content: Text('Request sent')));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Absence request')),
      body: AsyncBody<List<AbsenceType>>(
        loader: () => _types,
        builder: (context, types) {
          final t = _type;
          final range = _part == 0 && (t?.allowFullday ?? true);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              DropdownButtonFormField<AbsenceType>(
                initialValue: t,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                items: [for (final a in types) DropdownMenuItem(value: a, child: Text(a.label, overflow: TextOverflow.ellipsis))],
                onChanged: (v) => setState(() {
                  _type = v;
                  _part = 0;
                }),
              ),
              if (t?.guidelines != null && t!.guidelines!.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(t.guidelines!)),
              const SizedBox(height: 16),
              if (t != null && (t.allowDaypart || t.allowHours))
                SegmentedButton<int>(
                  showSelectedIcon: false,
                  segments: [
                    if (t.allowFullday) const ButtonSegment(value: 0, label: Text('Full day')),
                    if (t.allowDaypart) ...const [ButtonSegment(value: 1, label: Text('1st part')), ButtonSegment(value: 2, label: Text('2nd part'))],
                    if (t.allowHours) const ButtonSegment(value: 3, label: Text('Hours')),
                  ],
                  selected: {_part},
                  onSelectionChanged: (s) => setState(() => _part = s.first),
                ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.event),
                label: Text(_start == null ? (range ? 'Start date' : 'Date') : ymd(_start!)),
                onPressed: () async {
                  final d = await _pickDate(_start);
                  if (d != null) setState(() => _start = d);
                },
              ),
              if (range) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.event),
                  label: Text(_end == null ? 'End date (optional)' : ymd(_end!)),
                  onPressed: () async {
                    final d = await _pickDate(_end ?? _start);
                    if (d != null) setState(() => _end = d);
                  },
                ),
              ],
              if (_part == 3) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final v = await showTimePicker(context: context, initialTime: _from ?? const TimeOfDay(hour: 9, minute: 0));
                          if (v != null) setState(() => _from = v);
                        },
                        child: Text(_from == null ? 'From' : _hm(_from!)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final v = await showTimePicker(context: context, initialTime: _to ?? const TimeOfDay(hour: 10, minute: 0));
                          if (v != null) setState(() => _to = v);
                        },
                        child: Text(_to == null ? 'To' : _hm(_to!)),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              TextField(
                controller: _remark,
                maxLines: 2,
                decoration: InputDecoration(labelText: t?.needRemark == true ? 'Remark (required)' : 'Remark', border: const OutlineInputBorder()),
              ),
              const SizedBox(height: 20),
              FilledButton(onPressed: _busy ? null : _send, child: _busy ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Send request')),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _remark.dispose();
    super.dispose();
  }
}

/// New clocking request ("fichaje en reloj"): a worked block start-end on a date.
class NewClockingRequestScreen extends StatefulWidget {
  const NewClockingRequestScreen({super.key});

  @override
  State<NewClockingRequestScreen> createState() => _NewClockingRequestScreenState();
}

class _NewClockingRequestScreenState extends State<NewClockingRequestScreen> {
  DateTime? _date;
  TimeOfDay? _from;
  TimeOfDay? _to;
  final _remark = TextEditingController();
  bool _busy = false;

  Future<void> _send() async {
    final messenger = ScaffoldMessenger.of(context);
    if (_date == null || _from == null || _to == null) {
      messenger.showSnackBar(const SnackBar(content: Text('Choose date, start and end')));
      return;
    }
    if (_to!.hour * 60 + _to!.minute <= _from!.hour * 60 + _from!.minute) {
      messenger.showSnackBar(const SnackBar(content: Text('End must be after start')));
      return;
    }
    if (!await _confirmSend(context, 'Clocking ${ymd(_date!)}\n${_hm(_from!)} – ${_hm(_to!)}') || !mounted) return;
    setState(() => _busy = true);
    try {
      await MyEraApi.instance.requestClocking(_date!, _hm(_from!), _hm(_to!), remark: _remark.text.trim());
      messenger.showSnackBar(const SnackBar(content: Text('Request sent')));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clocking request')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          OutlinedButton.icon(
            icon: const Icon(Icons.event),
            label: Text(_date == null ? 'Date' : ymd(_date!)),
            onPressed: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _date ?? DateTime.now(),
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now(),
              );
              if (d != null) setState(() => _date = d);
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final v = await showTimePicker(context: context, initialTime: _from ?? const TimeOfDay(hour: 8, minute: 0));
                    if (v != null) setState(() => _from = v);
                  },
                  child: Text(_from == null ? 'Clock in' : _hm(_from!)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final v = await showTimePicker(context: context, initialTime: _to ?? const TimeOfDay(hour: 17, minute: 0));
                    if (v != null) setState(() => _to = v);
                  },
                  child: Text(_to == null ? 'Clock out' : _hm(_to!)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(controller: _remark, maxLines: 2, decoration: const InputDecoration(labelText: 'Remark', border: OutlineInputBorder())),
          const SizedBox(height: 20),
          FilledButton(onPressed: _busy ? null : _send, child: _busy ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Send request')),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _remark.dispose();
    super.dispose();
  }
}
