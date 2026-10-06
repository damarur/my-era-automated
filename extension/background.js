importScripts("settings.js");

const MAX_LATE_MS = 30 * 60 * 1000; // skip reminders Chrome delivered very late (e.g. browser was closed)

// Next reminder strictly after `now`, looking up to 14 days ahead.
function nextReminder(settings, now = new Date()) {
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
    if (best) break; // earliest day with a reminder wins
  }
  return best;
}

async function reschedule() {
  await chrome.alarms.clearAll();
  const settings = await getSettings();
  if (!settings.remindersEnabled) return;
  const next = nextReminder(settings);
  if (next) chrome.alarms.create(`${next.type}:${next.when}`, { when: next.when });
}

chrome.alarms.onAlarm.addListener(async (alarm) => {
  const [type, when] = alarm.name.split(":");
  if (Date.now() - Number(when) <= MAX_LATE_MS) {
    chrome.notifications.create("reminder", {
      type: "basic",
      iconUrl: "icon128.png",
      title: type === "in" ? "Time to clock in" : "Time to clock out",
      message: "Click to open MyEra Clock.",
      requireInteraction: true,
    });
  }
  reschedule();
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
