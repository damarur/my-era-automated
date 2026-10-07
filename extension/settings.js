// Shared by background.js (importScripts), popup.js and options.js (script tags).
const toMin = (t) => { const [h, m] = (t || "00:00").split(":").map(Number); return h * 60 + m; };
const toHm = (min) => `${String(Math.floor(min / 60) % 24).padStart(2, "0")}:${String(min % 60).padStart(2, "0")}`;

// Days are keyed by Date#getDay(): 1=Mon .. 5=Fri.
// in/out = schedule (reminders and auto clock); break* = unpaid break window, deducted from
// worked time; target = daily hours to complete (informative).

// Preset "Standard": 7h36 per day from `start`, with a break window. Clock out is derived.
const STANDARD_TARGET = "07:36";
function standardPreset({ start = "09:00", breakStart = "13:00", breakEnd = "13:30" } = {}) {
  const breakMin = Math.max(0, toMin(breakEnd) - toMin(breakStart));
  const out = toHm(toMin(start) + toMin(STANDARD_TARGET) + breakMin);
  const days = {};
  for (let d = 1; d <= 5; d++) {
    days[d] = { enabled: true, in: start, out, breakEnabled: true, breakStart, breakEnd, target: STANDARD_TARGET };
  }
  return days;
}

// Preset "Irregular schedule": 8h Mon-Thu (start + 8h + break) and 6h on Fri (start + 6h, no break).
function irregularPreset({ start = "08:00", breakStart = "13:00", breakEnd = "14:00" } = {}) {
  const breakMin = Math.max(0, toMin(breakEnd) - toMin(breakStart));
  const days = {};
  for (let d = 1; d <= 4; d++) {
    days[d] = { enabled: true, in: start, out: toHm(toMin(start) + 8 * 60 + breakMin), breakEnabled: true, breakStart, breakEnd, target: "08:00" };
  }
  days[5] = { enabled: true, in: start, out: toHm(toMin(start) + 6 * 60), breakEnabled: false, breakStart, breakEnd, target: "06:00" };
  return days;
}

const DEFAULT_SETTINGS = {
  remindersEnabled: true,
  // Auto clock only runs when the user has accepted the risks (ack) and switched it on.
  autoClock: { ack: false, enabled: false },
  days: irregularPreset(),
};

async function getSettings() {
  const { settings } = await chrome.storage.local.get("settings");
  const stored = (settings && settings.days) || {};
  const days = {};
  for (const d of Object.keys(DEFAULT_SETTINGS.days)) {
    days[d] = { ...DEFAULT_SETTINGS.days[d], ...stored[d] };
  }
  const autoClock = { ...DEFAULT_SETTINGS.autoClock, ...(settings && settings.autoClock) };
  autoClock.enabled = autoClock.enabled && autoClock.ack;
  return { ...DEFAULT_SETTINGS, ...settings, autoClock, days };
}
