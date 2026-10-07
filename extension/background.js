importScripts("settings.js", "api.js");

const MAX_LATE_MS = 30 * 60 * 1000; // skip reminders Chrome delivered very late (e.g. browser was closed)
const AUTO_MAX_LATE_MS = 10 * 60 * 1000; // never auto clock long after the scheduled time

// Next scheduled event strictly after `now`, looking up to 14 days ahead.
function nextEvent(settings, now = new Date()) {
  let best = null;
  for (let i = 0; i < 14; i++) {
    const d = new Date(now.getFullYear(), now.getMonth(), now.getDate() + i);
    const cfg = settings.days[d.getDay()];
    if (d.getDay() === 0 || d.getDay() === 6 || !cfg || !cfg.enabled) continue; // Mon-Fri only
    for (const type of ["in", "out"]) {
      if (!/^\d{2}:\d{2}$/.test(cfg[type] || "")) continue;
      const [h, m] = cfg[type].split(":").map(Number);
      const when = new Date(d.getFullYear(), d.getMonth(), d.getDate(), h, m).getTime();
      if (when > now.getTime() && (!best || when < best.when)) best = { type, when };
    }
    if (best) break; // earliest day with an event wins
  }
  return best;
}

async function reschedule() {
  await chrome.alarms.clearAll();
  const settings = await getSettings();
  if (!settings.remindersEnabled && !settings.autoClock.enabled) return;
  const next = nextEvent(settings);
  if (next) chrome.alarms.create(`${next.type}:${next.when}`, { when: next.when });
}

function notify(id, title, message, requireInteraction = false) {
  chrome.notifications.create(id, { type: "basic", iconUrl: "icon128.png", title, message, requireInteraction });
}

const lastClocking = (clockings) => clockings[clockings.length - 1];

// Auto clock: re-checks the real state in MyEra right before acting, so it never doubles a
// clocking. "in" only when there are no clockings today; "out" only when the last one is an "in".
async function autoClock(type, lateMs) {
  const label = type === "in" ? "clock in" : "clock out";
  const id = `auto-${Date.now()}`;
  if (lateMs > AUTO_MAX_LATE_MS) {
    return notify(id, `Auto ${label} skipped`, `Missed by ${Math.round(lateMs / 60000)} min (Chrome was closed or asleep). Please clock manually.`, true);
  }
  try {
    const { employeeCode } = await chrome.storage.local.get("employeeCode");
    const session = await getSession();
    if (!session || !employeeCode) throw new Error("No saved credentials");

    const today = ymd(new Date());
    const state = async () => {
      const entry = (await fetchCalendar(session, employeeCode, today, today)).find((d) => d.date === today) || {};
      return { entry, clockings: entry.clockings || [] };
    };

    const before = await state();
    if ((before.entry.absences || []).length || (before.entry.publicHoliday && before.entry.publicHoliday.enabled)) {
      return notify(id, `Auto ${label} skipped`, "Today is an absence or holiday.");
    }
    const last = lastClocking(before.clockings);
    if (type === "in" && before.clockings.length) {
      return notify(id, "Auto clock in skipped", "There is already a clocking today.");
    }
    if (type === "out" && !(last && last.in)) {
      return notify(id, "Auto clock out skipped", "There is no open clock in (already clocked out, or never clocked in).");
    }

    await postClocking(session, type === "in" ? 1 : 2);

    const after = lastClocking((await state()).clockings);
    const confirmed = after && after.in === (type === "in");
    notify(
      id,
      confirmed ? `Auto ${label} done` : `Auto ${label} sent, not confirmed`,
      confirmed ? `Clocked ${type} at ${after.time.slice(11)}.` : "Could not confirm it in MyEra. Please check manually.",
      !confirmed,
    );
  } catch (e) {
    notify(id, `Auto ${label} failed`, `${e.message}. Please clock manually.`, true);
  }
}

chrome.alarms.onAlarm.addListener(async (alarm) => {
  const [type, when] = alarm.name.split(":");
  const lateMs = Date.now() - Number(when);
  try {
    const settings = await getSettings();
    if (settings.autoClock.enabled) {
      await autoClock(type, lateMs);
    } else if (settings.remindersEnabled && lateMs <= MAX_LATE_MS) {
      notify("reminder", type === "in" ? "Time to clock in" : "Time to clock out", "Click to open MyEra Clock.", true);
    }
  } finally {
    reschedule();
  }
});

chrome.notifications.onClicked.addListener((id) => {
  chrome.notifications.clear(id);
  chrome.action.openPopup().catch(() => {});
});

chrome.runtime.onInstalled.addListener(reschedule);
chrome.runtime.onStartup.addListener(reschedule);
chrome.storage.onChanged.addListener((changes, area) => {
  if (area === "local" && changes.settings) reschedule();
});
