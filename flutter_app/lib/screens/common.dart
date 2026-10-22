import 'package:flutter/material.dart';

import '../l10n.dart';


/// Loads [loader] and shows loading / error (with retry) / [builder] with pull-to-refresh.
class AsyncBody<T> extends StatefulWidget {
  const AsyncBody({super.key, required this.loader, required this.builder});
  final Future<T> Function() loader;
  final Widget Function(BuildContext, T) builder;

  @override
  State<AsyncBody<T>> createState() => AsyncBodyState<T>();
}

class AsyncBodyState<T> extends State<AsyncBody<T>> {
  late Future<T> _future = widget.loader();

  Future<void> reload() async {
    final f = widget.loader();
    setState(() {
      _future = f;
    });
    try {
      await f;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
        if (snap.hasError) {
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 60),
              Icon(Icons.error_outline, size: 40, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 12),
              Text(snap.error.toString(), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Center(child: OutlinedButton(onPressed: reload, child: Text(context.l10n.retry))),
            ],
          );
        }
        return RefreshIndicator(onRefresh: reload, child: widget.builder(context, snap.data as T));
      },
    );
  }
}

/// Previous / next / label row used by the period based screens.
class PeriodNav extends StatelessWidget {
  const PeriodNav({super.key, required this.label, required this.onPrev, required this.onNext, this.onToday, this.trailing});
  final String label;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final VoidCallback? onToday;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: onPrev),
          Expanded(child: Text(label, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium)),
          if (onToday != null) TextButton(onPressed: onToday, child: Text(context.l10n.today)),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: onNext),
          ?trailing,
        ],
      ),
    );
  }
}

Color? diffColor(BuildContext context, {required bool pending, required bool ok}) {
  if (pending) return Theme.of(context).colorScheme.onSurfaceVariant;
  return ok ? Colors.green.shade600 : Theme.of(context).colorScheme.error;
}

Color hexColor(String? hex, Color fallback) {
  if (hex == null || hex.length != 6) return fallback;
  final v = int.tryParse(hex, radix: 16);
  return v == null ? fallback : Color(0xFF000000 | v);
}

/// Rounded pill with a signed difference or a short label, coloured by result.
class DiffChip extends StatelessWidget {
  const DiffChip({super.key, required this.text, required this.color, this.big = false});
  final String text;
  final Color? color;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: big ? 14 : 10, vertical: big ? 6 : 4),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(color: c, fontWeight: FontWeight.w700, fontSize: big ? 16 : 13)),
    );
  }
}
