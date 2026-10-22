import 'package:flutter/material.dart';

import '../api.dart';
import '../l10n.dart';
import 'common.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final _body = GlobalKey<AsyncBodyState<List<Message>>>();

  Future<void> _run(Future<void> Function() action) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      await _body.currentState?.reload();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.messages),
        actions: [IconButton(icon: const Icon(Icons.done_all), tooltip: context.l10n.markAllRead, onPressed: () => _run(MyEraApi.instance.readAllMessages))],
      ),
      body: AsyncBody<List<Message>>(
        key: _body,
        loader: MyEraApi.instance.messages,
        builder: (context, items) {
          if (items.isEmpty) return ListView(children: [const SizedBox(height: 80), Center(child: Text(context.l10n.noMessages))]);
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final m = items[i];
              return ListTile(
                leading: Icon(m.read ? Icons.drafts_outlined : Icons.mail, color: m.read ? null : Theme.of(context).colorScheme.primary),
                title: Text(m.title.isEmpty ? m.body : m.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: m.read ? null : FontWeight.w700)),
                subtitle: Text(m.title.isEmpty ? m.date : m.body, maxLines: 2, overflow: TextOverflow.ellipsis),
                onTap: () {
                  showDialog<void>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text(m.title.isEmpty ? context.l10n.messageTitle : m.title),
                      content: SingleChildScrollView(child: Text(m.body)),
                      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(context.l10n.close))],
                    ),
                  );
                  if (!m.read && m.id.isNotEmpty) _run(() => MyEraApi.instance.setMessageRead(m.id, true));
                },
                trailing: m.read && m.id.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.mark_email_unread_outlined), tooltip: context.l10n.markUnread, onPressed: () => _run(() => MyEraApi.instance.setMessageRead(m.id, false)))
                    : null,
              );
            },
          );
        },
      ),
    );
  }
}
