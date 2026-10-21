import 'package:flutter/material.dart';

import '../api.dart';
import '../scheduler.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.onLoggedIn});
  final VoidCallback onLoggedIn;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _customer = TextEditingController();
  final _user = TextEditingController();
  final _pass = TextEditingController();
  bool _busy = false;
  bool _show = false;
  String? _error;

  Future<void> _submit() async {
    final customer = _customer.text.trim().toLowerCase();
    final user = _user.text.trim();
    final pass = _pass.text;
    if (customer.isEmpty || user.isEmpty || pass.isEmpty) return setState(() => _error = 'Enter your customer key, user and password');
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await MyEraApi.instance.loginAndSave(customer, user, pass);
      _pass.clear();
      await reschedule().catchError((Object _) {});
      widget.onLoggedIn();
    } catch (e) {
      setState(() => _error = e.toString().contains('SocketException') ? 'Could not reach MyEra. Check your connection.' : e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: AutofillGroup(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Image.asset('assets/icon.png', width: 72, height: 72),
                    const SizedBox(height: 12),
                    Text('MyEra', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 4),
                    const SizedBox(height: 28),
                    TextField(
                      controller: _customer,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      decoration: const InputDecoration(labelText: 'Customer key', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _user,
                      autofillHints: const [AutofillHints.username],
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'User', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _pass,
                      obscureText: !_show,
                      autofillHints: const [AutofillHints.password],
                      onSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(_show ? Icons.visibility_off : Icons.visibility),
                          tooltip: _show ? 'Hide password' : 'Show password',
                          onPressed: () => setState(() => _show = !_show),
                        ),
                      ),
                    ),
                    if (_error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_error!, style: TextStyle(color: cs.error))),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      child: _busy ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Log in'),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Credentials are stored encrypted on this device and only sent to MyEra.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _customer.dispose();
    _user.dispose();
    _pass.dispose();
    super.dispose();
  }
}
