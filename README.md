# my-era-automated

A Chrome extension to clock in/out on [MyEra](https://hcs.eratime.eu), with weekday reminders, optional auto clock, and a weekly/monthly hours summary.

## Install

`extension/` is a Manifest V3 Chrome extension that clocks in/out from a popup.

1. Open `chrome://extensions` and enable **Developer mode**.
2. **Load unpacked** → select the `extension/` folder.
3. Click the extension icon, enter your **User** and password (the eye icon shows/hides what you typed) and press **Login** or Enter. It only verifies them against MyEra and saves them if valid; if the login fails, the error is shown above the button.
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
| Lunch break | Unpaid window deducted from the worked time (can be switched off per day) | Mon–Thu 13:00–14:00, Fri off |
| Daily target | Hours to complete that day | Mon–Thu 08:00, Fri 06:00 |

Reminders are notifications (click one to open the popup). They only fire while Chrome is running, use the computer's local timezone and never clock for you.

### Presets

At the top of Settings, two presets fill the weekly schedule and save it:

- **Standard 7h 36m**: every day 7h 36m from a start time (default 09:00) with an editable break (default 13:00–13:30), applied to all days. Clock out is calculated (start + 7h 36m + break, i.e. 17:06 by default).
- **Irregular schedule**: 8h Mon–Thu (start + 8h + break) and 6h on Fri without break (start + 6h). Start (default 08:00) and the Mon–Thu break (default 13:00–14:00) are editable, giving 08:00–17:00 Mon–Thu and 08:00–14:00 Fri by default. This is also the initial default.

### Auto clock

> ⚠️ **Use at your own risk.** Auto clock clocks in and out on your behalf and may not work (Chrome closed or asleep, network/MyEra errors, API changes, wrong schedule). You are responsible for your recorded times, so always check MyEra.

Off by default. To enable it you must tick the acceptance checkbox first. It uses the clock in / out times of the weekly schedule (Mon–Fri) and replaces the reminders. Right before acting it asks MyEra for today's clockings:

- **Clock in** only if there is no clocking yet today.
- **Clock out** only if the last clocking is a clock in.
- Skips days with an absence or public holiday.
- Never acts more than 10 minutes after the scheduled time (e.g. Chrome was closed); it notifies you instead.
- After clocking it re-checks MyEra and shows a browser notification with the result (done / not confirmed / failed). You also get a notification when it skips or fails (these stay on screen until dismissed) so you can step in.

It needs Chrome running and the credentials saved in the extension.

### How worked time is computed

Worked time is the sum of the time blocks between consecutive clockings of the day, minus the overlap with the lunch break window. MyEra allows two clock-ins or two clock-outs in a row, so every pair of consecutive clockings counts as one valid block (in → out, in → in and out → out); only out → in is a break. For example, in 08:00, in 09:00, out 17:00 is a single block of 9h, and in 08:00, out 16:00, out 17:00 also counts 9h. If you already clocked out/in during the day, that real gap is used instead and the configured window is ignored. An interval still open today only counts up to now, so a lunch break that hasn't started yet is not deducted.

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

Clocking out later adds to the difference (out at 17:00 → 8h 30m worked, +0h 54m); leaving earlier subtracts from it. To mirror this setup, set the lunch break to 13:00–13:30 in Settings (the defaults are a 1 h break and an 08:00 target).

### Example: different targets per day

Mon–Thu with a 1 h lunch break and a shorter Friday without one:

| Day | In | Out | Lunch break | Worked | Target | Diff |
|---|---|---|---|---|---|---|
| Mon–Thu | 08:00 | 17:00 | 13:00–14:00 (1h) | 9h − 1h = 8h 00m | 8h 00m | +0h 00m |
| Fri | 08:00 | 14:00 | off | 6h 00m | 6h 00m | +0h 00m |

The week adds up to 4 × 8h + 6h = **38h**. In Settings this is: Mon–Thu clock in 08:00, clock out 17:00, lunch break on 13:00–14:00, daily target 08:00; Fri clock in 08:00, clock out 14:00, lunch break off, daily target 06:00.

### Weekly and monthly target

The target of a period is the sum of the daily targets of its working days: 4 × 8h + 6h make a 38h week with the defaults.

When any day of the week is off (MyEra reports an absence or a public holiday, shown as "Absent" / "Holiday"), the per-day targets from Settings are **not applied** for that week. The off day gets a target of 0 and every remaining day gets the daily average, which with the defaults is (4 × 8h + 6h) / 5 = **7h 36m**, so the week never goes over. For example, with a Friday holiday the week becomes 4 × 7h36 = 30h24, and with an absence on a Wednesday, Mon, Tue, Thu and Fri all target 7h36. The average is computed from your configured daily targets, so it changes if you change them.

In the month view this is applied week by week, and the target only counts days up to today, so mid-month you aren't shown hours that are not due yet.
