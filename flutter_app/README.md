# MyEra (Android, Flutter)

Android app for MyEra (`hcs.eratime.eu`, customer `lufthansa`), same API the web app and the Chrome extension use.

Features: login (credentials stored encrypted on device), home with clock in/out and counters, week/month
summary with targets and break deduction, monthly clockings list, planning calendar, requests list with new absence and clocking requests (no attachments),
messages, settings with presets, reminders and auto clock.

Not implemented yet: request attachments, other request types (schedule changes, notes, certificates), manager screens (approvals, team schedule, schedule offers).

```bash
flutter pub get
flutter analyze
flutter run            # needs the Android SDK and a device/emulator
flutter build apk
```

Reminders use local notifications; auto clock uses WorkManager, so Android may delay it (battery saver, doze).
