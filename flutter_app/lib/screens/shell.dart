import 'package:flutter/material.dart';

import '../api.dart';
import '../l10n.dart';
import '../scheduler.dart';
import 'counters_screen.dart';
import 'home_screen.dart';
import 'messages_screen.dart';
import 'requests_screen.dart';
import 'settings_screen.dart';
import 'summary_screen.dart';

class Shell extends StatefulWidget {
  const Shell({super.key, required this.onLogout});
  final VoidCallback onLogout;

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _index = 0;
  String _name = '';
  // Bumped after each clocking so the other tabs reload.
  int _refresh = 0;
  // Bumped after a lunch override edited in the summary, so Home reloads without losing the summary state.
  int _homeRefresh = 0;
  // Bumped after a request is created from Home, so the Requests tab reloads.
  int _requestsRefresh = 0;

  @override
  void initState() {
    super.initState();
    MyEraApi.instance.savedName().then((n) => setState(() => _name = n ?? ''));
  }

  Future<void> _logout() async {
    await MyEraApi.instance.clearCredentials();
    await reschedule().catchError((Object _) {});
    widget.onLogout();
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomeScreen(key: ValueKey('home${_refresh}_$_homeRefresh'), onClocked: () => setState(() => _refresh++), onRequestCreated: () => setState(() => _requestsRefresh++)),
      SummaryScreen(key: ValueKey('sum$_refresh'), onLunchChanged: () => setState(() => _homeRefresh++)),
      RequestsScreen(key: ValueKey('req$_requestsRefresh')),
      const CountersScreen(),
      const SettingsScreen(),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(_name.isEmpty ? 'MyEra' : _name, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.mail_outline),
            tooltip: context.l10n.messages,
            onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const MessagesScreen())),
          ),
          IconButton(icon: const Icon(Icons.logout), tooltip: context.l10n.logOut, onPressed: _logout),
        ],
      ),
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home), label: context.l10n.navHome),
          NavigationDestination(icon: const Icon(Icons.bar_chart_outlined), selectedIcon: const Icon(Icons.bar_chart), label: context.l10n.navSummary),
          NavigationDestination(icon: const Icon(Icons.assignment_outlined), selectedIcon: const Icon(Icons.assignment), label: context.l10n.navRequests),
          NavigationDestination(icon: const Icon(Icons.calculate_outlined), selectedIcon: const Icon(Icons.calculate), label: context.l10n.navCounters),
          NavigationDestination(icon: const Icon(Icons.settings_outlined), selectedIcon: const Icon(Icons.settings), label: context.l10n.navSettings),
        ],
      ),
    );
  }
}
