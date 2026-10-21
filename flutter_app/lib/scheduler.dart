import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:workmanager/workmanager.dart';

import 'api.dart';
import 'settings.dart';

const _autoMaxLate = Duration(minutes: 10); // never auto clock long after the scheduled time
const _autoTask = 'auto-clock';
const _autoUnique = 'auto-clock-next';

final _notifications = FlutterLocalNotificationsPlugin();
var _notifReady = false;

Future<void> _initNotifications() async {
  if (_notifReady) return;
  tzdata.initializeTimeZones();
  await _notifications.initialize(
    settings: const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher')),
  );
  _notifReady = true;
}

const _details = NotificationDetails(
  android: AndroidNotificationDetails(
    'myera_clock',
    'Clock reminders',
    channelDescription: 'Clock in/out reminders and auto clock results',
    importance: Importance.high,
    priority: Priority.high,
  ),
);

Future<void> _notify(int id, String title, String body) async {
  await _initNotifications();
  await _notifications.show(id: id, title: title, body: body, notificationDetails: _details);
}

class ScheduledEvent {
  ScheduledEvent(this.type, this.when);
  final String type; // "in" | "out"
  final DateTime when;
}

/// Scheduled events (Mon-Fri) strictly after [now], looking up to [days] days ahead.
List<ScheduledEvent> upcomingEvents(AppSettings s, DateTime now, {int days = 14}) {
  final out = <ScheduledEvent>[];
  for (var i = 0; i < days; i++) {
    final d = DateTime(now.year, now.month, now.day + i);
    final cfg = s.days[d.weekday];
    if (d.weekday > 5 || cfg == null || !cfg.enabled) continue;
    for (final type in const ['in', 'out']) {
      final t = type == 'in' ? cfg.inTime : cfg.outTime;
      if (!RegExp(r'^\d{2}:\d{2}$').hasMatch(t)) continue;
      final m = toMin(t);
      final when = DateTime(d.year, d.month, d.day, m ~/ 60, m % 60);
      if (when.isAfter(now)) out.add(ScheduledEvent(type, when));
    }
  }
  out.sort((a, b) => a.when.compareTo(b.when));
  return out;
}

/// Re-plans everything from the saved settings: local notifications for the next reminders and
/// one WorkManager task for the next auto clock. Call on app start and when settings change.
Future<void> reschedule() async {
  await _initNotifications();
  final settings = await AppSettings.load();
  await _notifications.cancelAll();
  final wm = Workmanager();
  await wm.cancelByUniqueName(_autoUnique);

  final events = upcomingEvents(settings, DateTime.now());
  if (settings.autoClockActive) {
    if (events.isNotEmpty) {
      final next = events.first;
      await wm.registerOneOffTask(
        _autoUnique,
        _autoTask,
        initialDelay: next.when.difference(DateTime.now()),
        inputData: {'type': next.type, 'when': next.when.millisecondsSinceEpoch},
        existingWorkPolicy: ExistingWorkPolicy.replace,
      );
    }
  } else if (settings.remindersEnabled) {
    // Android caps pending alarms per app, so only plan the next ones.
    var id = 0;
    for (final e in events.take(20)) {
      await _notifications.zonedSchedule(
        id: id++,
        title: e.type == 'in' ? 'Time to clock in' : 'Time to clock out',
        body: 'Open MyEra Clock.',
        scheduledDate: tz.TZDateTime.fromMillisecondsSinceEpoch(tz.UTC, e.when.millisecondsSinceEpoch),
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }
}

/// Auto clock: re-checks the real state in MyEra right before acting, so it never doubles a
/// clocking. "in" only when there are no clockings today; "out" only when the last one is an "in".
Future<void> autoClock(String type, Duration late) async {
  final label = type == 'in' ? 'clock in' : 'clock out';
  const id = 1000;
  if (late > _autoMaxLate) {
    return await _notify(id, 'Auto $label skipped', 'Missed by ${late.inMinutes} min (device was asleep). Please clock manually.');
  }
  try {
    final api = MyEraApi.instance;
    final today = DateTime.now();
    Future<CalendarDay?> state() async {
      final days = await api.calendar(today, today);
      return days.where((d) => d.date == ymd(today)).firstOrNull;
    }

    final before = await state();
    if (before != null && before.off) return await _notify(id, 'Auto $label skipped', 'Today is an absence or holiday.');
    final clockings = before?.clockings ?? const <Clocking>[];
    if (type == 'in' && clockings.isNotEmpty) return await _notify(id, 'Auto clock in skipped', 'There is already a clocking today.');
    if (type == 'out' && !(clockings.isNotEmpty && clockings.last.isIn)) {
      return await _notify(id, 'Auto clock out skipped', 'There is no open clock in (already clocked out, or never clocked in).');
    }

    await api.clock(type == 'in' ? 1 : 2);

    final after = (await state())?.clockings;
    final last = (after != null && after.isNotEmpty) ? after.last : null;
    final confirmed = last != null && last.isIn == (type == 'in');
    await _notify(
      id,
      confirmed ? 'Auto $label done' : 'Auto $label sent, not confirmed',
      confirmed ? 'Clocked $type at ${pad(last.time.hour)}:${pad(last.time.minute)}.' : 'Could not confirm it in MyEra. Please check manually.',
    );
  } catch (e) {
    await _notify(id, 'Auto $label failed', '$e. Please clock manually.');
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, input) async {
    if (task == _autoTask && input != null) {
      final when = DateTime.fromMillisecondsSinceEpoch(input['when'] as int);
      try {
        await autoClock(input['type'] as String, DateTime.now().difference(when));
      } finally {
        await reschedule();
      }
    }
    return true;
  });
}

Future<void> initScheduler() async {
  if (defaultTargetPlatform != TargetPlatform.android) return;
  await _initNotifications();
  await Workmanager().initialize(callbackDispatcher);
  await _notifications
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.requestNotificationsPermission();
  await reschedule();
}
