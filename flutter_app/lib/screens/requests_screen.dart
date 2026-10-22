import 'package:flutter/material.dart';

import '../api.dart';
import '../l10n.dart';
import 'common.dart';
import 'new_request.dart';

/// Asks for the kind of request and opens its form. Returns true when a request was sent.
Future<bool> startNewRequest(BuildContext context) async {
  final choice = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(leading: const Icon(Icons.beach_access_outlined), title: Text(context.l10n.absenceRequest), onTap: () => Navigator.pop(ctx, 'absence')),
          ListTile(leading: const Icon(Icons.edit_calendar_outlined), title: Text(context.l10n.clockingRequest), onTap: () => Navigator.pop(ctx, 'clocking')),
        ],
      ),
    ),
  );
  if (choice == null || !context.mounted) return false;
  final done = await Navigator.push<bool>(
    context,
    MaterialPageRoute(builder: (_) => choice == 'absence' ? const NewAbsenceScreen() : const NewClockingRequestScreen()),
  );
  return done == true;
}

/// Requests of the selected year (newest event first), with new absence / clocking requests and
/// withdrawing pending ones. Absences without a request behind them come from the calendar.
class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  final _body = GlobalKey<AsyncBodyState<List<RequestItem>>>();
  int _year = DateTime.now().year;

  // One year back (history) and one ahead (planned absences).
  int get _minYear => DateTime.now().year - 1;
  int get _maxYear => DateTime.now().year + 1;

  void _goTo(int year) {
    if (year < _minYear || year > _maxYear || year == _year) return;
    setState(() => _year = year);
  }

  String _dmy(String iso) {
    final p = iso.split('T').first.split('-');
    return p.length == 3 ? '${p[2]}/${p[1]}/${p[0]}' : iso;
  }

  Future<void> _new() async {
    if (await startNewRequest(context)) await _body.currentState?.reload();
  }

  Future<void> _delete(RequestItem r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.withdrawTitle),
        content: Text(r.description.isEmpty ? r.type : r.description),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(context.l10n.withdraw)),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await MyEraApi.instance.deleteRequest(r.code);
      await _body.currentState?.reload();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  /// An authorized absence cannot be withdrawn: MyEra only lets the employee ask for its cancellation
  /// (POST requests/deleteabsence), which the approver then has to accept.
  bool _canCancel(RequestItem r) => !r.allowDelete && r.type == 'ausencia' && !r.status.toLowerCase().contains('deneg');

  Future<void> _cancelAbsence(RequestItem r) async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final from = DateTime.parse(r.from);
    final to = DateTime.parse(r.to ?? r.from);
    try {
      final options = await MyEraApi.instance.deletableAbsences(from, to);
      if (!mounted) return;
      if (options.isEmpty) {
        messenger.showSnackBar(SnackBar(content: Text(l.cancelNotAvailable)));
        return;
      }
      // Preselect the absence this item is about; with several candidates the user chooses.
      final preselected = options.where((o) => o.code == r.absenceCode).firstOrNull ??
          options.where((o) => o.label == r.description).firstOrNull ??
          (options.length == 1 ? options.first : null);
      final range = r.to != null && r.to != r.from ? '${_dmy(r.from)} – ${_dmy(r.to!)}' : _dmy(r.from);
      final remark = TextEditingController();
      DeletableAbsence? chosen = preselected;
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setD) => AlertDialog(
            title: Text(l.requestCancellation),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.description.isEmpty ? r.type : r.description, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(range),
                  const SizedBox(height: 12),
                  if (options.length > 1) ...[
                    DropdownButtonFormField<DeletableAbsence>(
                      initialValue: chosen,
                      isExpanded: true,
                      hint: Text(l.chooseAbsence),
                      decoration: InputDecoration(labelText: l.absenceToCancel, border: const OutlineInputBorder()),
                      items: [for (final o in options) DropdownMenuItem(value: o, child: Text(o.label, overflow: TextOverflow.ellipsis))],
                      onChanged: (v) => setD(() => chosen = v),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: remark,
                    maxLength: 100,
                    maxLines: 2,
                    decoration: InputDecoration(labelText: l.remark, border: const OutlineInputBorder()),
                  ),
                  Text(l.cancelAbsenceNote, style: TextStyle(fontSize: 12, color: Theme.of(ctx).colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
              FilledButton(onPressed: chosen == null ? null : () => Navigator.pop(ctx, true), child: Text(l.send)),
            ],
          ),
        ),
      );
      final text = remark.text.trim();
      remark.dispose();
      final pick = chosen;
      if (ok != true || pick == null || !mounted) return;
      await MyEraApi.instance.requestAbsenceCancellation(pick.code, from, to, remark: text);
      messenger.showSnackBar(SnackBar(content: Text(l.cancellationRequested)));
      await _body.currentState?.reload();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(onPressed: _new, icon: const Icon(Icons.add), label: Text(context.l10n.newShort)),
      body: Column(
        children: [
          PeriodNav(
            label: '$_year',
            onPrev: _year > _minYear ? () => _goTo(_year - 1) : null,
            onNext: _year < _maxYear ? () => _goTo(_year + 1) : null,
            onToday: _year != DateTime.now().year ? () => _goTo(DateTime.now().year) : null,
          ),
          Expanded(
            child: GestureDetector(
              // Swipe left for the next year, right for the previous one.
              onHorizontalDragEnd: (d) {
                final v = d.primaryVelocity ?? 0;
                if (v < -300) _goTo(_year + 1);
                if (v > 300) _goTo(_year - 1);
              },
              child: AsyncBody<List<RequestItem>>(
        key: ValueKey('$_year'),
        loader: () => MyEraApi.instance.requests(year: _year),
        builder: (context, items) {
          if (items.isEmpty) return ListView(children: [const SizedBox(height: 80), Center(child: Text(context.l10n.noRequestsYear('$_year')))]);
          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 88),
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final r = items[i];
              final range = r.to != null && r.to != r.from ? '${_dmy(r.from)} – ${_dmy(r.to!)}' : _dmy(r.from);
              final hasRemark = r.remark != null && r.remark!.isNotEmpty;
              return ListTile(
                title: Text(r.description.isEmpty ? r.type : r.description),
                subtitle: Text('${r.type} · $range${hasRemark ? '\n${r.remark}' : ''}'),
                isThreeLine: hasRemark,
                onLongPress: r.allowDelete ? () => _delete(r) : (_canCancel(r) ? () => _cancelAbsence(r) : null),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(r.status, style: TextStyle(fontWeight: FontWeight.w600, color: _statusColor(r.status, cs))),
                    Text(r.allowDelete ? context.l10n.holdToWithdraw : _canCancel(r) ? context.l10n.holdToCancel : (r.requested.isEmpty ? context.l10n.fromCalendar : _dmy(r.requested)), style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                  ],
                ),
              );
            },
          );
        },
      ),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status, ColorScheme cs) {
    final s = status.toLowerCase();
    if (s.contains('deneg')) return cs.error;
    if (s.contains('autoriz')) return Colors.green.shade600;
    if (s.contains('registr')) return cs.onSurfaceVariant;
    return cs.onSurfaceVariant;
  }
}
