import 'package:flutter/material.dart';

import '../api.dart';
import '../scheduler.dart';
import 'home_screen.dart';
import 'messages_screen.dart';
import 'registrations_screen.dart';
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
      HomeScreen(key: ValueKey('home$_refresh'), onClocked: () => setState(() => _refresh++)),
      SummaryScreen(key: ValueKey('sum$_refresh')),
      RegistrationsScreen(key: ValueKey('reg$_refresh')),
      const RequestsScreen(),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(_name.isEmpty ? 'MyEra Clock' : _name, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.mail_outline),
            tooltip: 'Messages',
            onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const MessagesScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const SettingsScreen())),
          ),
          IconButton(icon: const Icon(Icons.logout), tooltip: 'Log out', onPressed: _logout),
        ],
      ),
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: 'Summary'),
          NavigationDestination(icon: Icon(Icons.list_alt_outlined), selectedIcon: Icon(Icons.list_alt), label: 'Fichajes'),
          NavigationDestination(icon: Icon(Icons.assignment_outlined), selectedIcon: Icon(Icons.assignment), label: 'Requests'),
        ],
      ),
    );
  }
}
