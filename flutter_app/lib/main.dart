import 'package:flutter/material.dart';

import 'api.dart';
import 'scheduler.dart';
import 'theme_controller.dart';
import 'screens/login_screen.dart';
import 'screens/shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeController.instance.load();
  runApp(const MyEraApp());
  // Don't block the first frame on notification permission / WorkManager setup.
  initScheduler().catchError((Object e) => debugPrint('Scheduler init failed: $e'));
}

class MyEraApp extends StatelessWidget {
  const MyEraApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF05164D); // dark navy
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.instance,
      builder: (context, mode, _) => MaterialApp(
        title: 'MyEra',
        debugShowCheckedModeBanner: false,
        themeMode: mode,
        theme: ThemeData(colorSchemeSeed: seed, useMaterial3: true),
        darkTheme: ThemeData(colorSchemeSeed: seed, useMaterial3: true, brightness: Brightness.dark),
        home: const _Root(),
      ),
    );
  }
}

class _Root extends StatefulWidget {
  const _Root();

  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  bool? _loggedIn;

  @override
  void initState() {
    super.initState();
    MyEraApi.instance.hasCredentials().then((v) => setState(() => _loggedIn = v));
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = _loggedIn;
    if (loggedIn == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return loggedIn
        ? Shell(onLogout: () => setState(() => _loggedIn = false))
        : LoginScreen(onLoggedIn: () => setState(() => _loggedIn = true));
  }
}
