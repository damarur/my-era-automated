import 'package:flutter/material.dart';

import '../api.dart';
import 'common.dart';
import 'new_request.dart';

/// Personal requests list, with new absence / clocking requests and withdrawing pending ones.
class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  final _body = GlobalKey<AsyncBodyState<List<RequestItem>>>();

  String _dmy(String iso) {
    final p = iso.split('T').first.split('-');
    return p.length == 3 ? '${p[2]}/${p[1]}/${p[0]}' : iso;
  }

  Future<void> _new() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: const Icon(Icons.beach_access_outlined), title: const Text('Absence request'), onTap: () => Navigator.pop(ctx, 'absence')),
            ListTile(leading: const Icon(Icons.edit_calendar_outlined), title: const Text('Clocking request'), onTap: () => Navigator.pop(ctx, 'clocking')),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;
    final done = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => choice == 'absence' ? const NewAbsenceScreen() : const NewClockingRequestScreen()),
    );
    if (done == true) await _body.currentState?.reload();
  }

  Future<void> _delete(RequestItem r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Withdraw request?'),
        content: Text(r.description.isEmpty ? r.type : r.description),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Withdraw')),
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(onPressed: _new, icon: const Icon(Icons.add), label: const Text('New')),
      body: AsyncBody<List<RequestItem>>(
        key: _body,
        loader: MyEraApi.instance.requests,
        builder: (context, items) {
          if (items.isEmpty) return ListView(children: const [SizedBox(height: 80), Center(child: Text('No requests'))]);
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
                onLongPress: r.allowDelete ? () => _delete(r) : null,
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(r.status, style: TextStyle(fontWeight: FontWeight.w600, color: _statusColor(r.status, cs))),
                    Text(r.allowDelete ? 'hold to withdraw' : _dmy(r.requested), style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _statusColor(String status, ColorScheme cs) {
    final s = status.toLowerCase();
    if (s.contains('deneg')) return cs.error;
    if (s.contains('autoriz')) return Colors.green.shade600;
    return cs.onSurfaceVariant;
  }
}
