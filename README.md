# my-era-automated

A Chrome extension to clock in/out on [MyEra](https://hcs.eratime.eu), with weekday reminders and a weekly/monthly hours summary.

## Install

`extension/` is a Manifest V3 Chrome extension that clocks in/out from a popup.

1. Open `chrome://extensions` and enable **Developer mode**.
2. **Load unpacked** → select the `extension/` folder.
3. Click the extension icon, enter user code + password and press **Login**. It only verifies them against MyEra and saves them if valid.
4. Press **Clock in** / **Clock out**. **Clear** removes the saved user and password.

Credentials are stored in `chrome.storage.local` (this browser only, unencrypted) and are only sent to `hcs.eratime.eu`. Nothing goes to any other server.

## Popup

- **Clock in / Clock out**: only the button that makes sense is enabled, based on today's last clocking.
- **Summary table**: for each working day (Mon–Fri) it shows the time worked, the target and the difference (worked − target). The last row totals the period; a negative difference means hours still to do.
- **Week / Month**: the toggle switches the period. The arrows go back in time (up to one year, never into the future) and **Today** jumps back to the current period.

## Settings

Open them from the popup's **Settings** link. Everything is configured per weekday (Mon–Fri):

| Setting | Meaning | Default |
|---|---|---|
| Active | Send reminders that day | on |
| Clock in / Clock out | When the reminder fires | Mon–Thu 08:00 / 17:00, Fri 08:00 / 14:00 |
| Lunch break | Unpaid window deducted from the worked time (can be switched off per day) | 13:00–14:00 |
| Daily target | Hours to complete that day | 07:36 |

Reminders are notifications (click one to open the popup). They only fire while Chrome is running, use the computer's local timezone and never clock for you.

### How worked time is computed

Worked time is the sum of the in → out intervals of the day, minus the overlap with the lunch break window. If you already clocked out/in during the day, that real gap is used instead and the configured window is ignored. An interval still open today only counts up to now, so a lunch break that hasn't started yet is not deducted.

### Example: a "normal" day

Daily target 07:36 and a 30 min lunch break from 13:00 to 13:30:

| | |
|---|---|
| Clock in | 08:00 |
| Clock out | 16:06 |
| Lunch break (deducted) | 13:00–13:30 → 30m |
| **Worked** | 8h 06m − 30m = **7h 36m** |
| Target | 7h 36m |
| **Diff** | **+0h 00m** |

Clocking out later adds to the difference (out at 17:00 → 8h 30m worked, +0h 54m); leaving earlier subtracts from it. To mirror this setup, set the lunch break to 13:00–13:30 in Settings (the default is a 1 h break).

### Example: different targets per day

Mon–Thu with a 1 h lunch break and a shorter Friday without one:

| Day | In | Out | Lunch break | Worked | Target | Diff |
|---|---|---|---|---|---|---|
| Mon–Thu | 08:00 | 17:00 | 13:00–14:00 (1h) | 9h − 1h = 8h 00m | 8h 00m | +0h 00m |
| Fri | 08:00 | 14:00 | off | 6h 00m | 6h 00m | +0h 00m |

The week adds up to 4 × 8h + 6h = **38h**. In Settings this is: Mon–Thu clock in 08:00, clock out 17:00, lunch break on 13:00–14:00, daily target 08:00; Fri clock in 08:00, clock out 14:00, lunch break off, daily target 06:00.

### Weekly and monthly target

The target of a period is the sum of the daily targets of its working days: five days of 07:36 make a 38h week.

When a day is off (MyEra reports an absence or a public holiday, shown as "Absent" / "Holiday") its target is 0 and the weekly average is spread over the remaining days, so the week doesn't go over. For example, a 38h week (7h36 average) with a Friday holiday becomes 4 × 7h36 = 30h24.

In the month view this is applied week by week, and the target only counts days up to today, so mid-month you aren't shown hours that are not due yet.
