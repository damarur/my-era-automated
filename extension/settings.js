// Shared by background.js (importScripts) and options.js (script tag).
const DEFAULT_SETTINGS = {
  remindersEnabled: true,
  // key = Date#getDay(): 1=Mon .. 5=Fri. break* = unpaid break window, deducted from worked time; target = daily hours to complete (informative).
  days: {
    1: { enabled: true, in: "08:00", out: "17:00", breakEnabled: true, breakStart: "13:00", breakEnd: "14:00", target: "07:36" },
    2: { enabled: true, in: "08:00", out: "17:00", breakEnabled: true, breakStart: "13:00", breakEnd: "14:00", target: "07:36" },
    3: { enabled: true, in: "08:00", out: "17:00", breakEnabled: true, breakStart: "13:00", breakEnd: "14:00", target: "07:36" },
    4: { enabled: true, in: "08:00", out: "17:00", breakEnabled: true, breakStart: "13:00", breakEnd: "14:00", target: "07:36" },
    5: { enabled: true, in: "08:00", out: "14:00", breakEnabled: true, breakStart: "13:00", breakEnd: "14:00", target: "07:36" },
  },
};

async function getSettings() {
  const { settings } = await chrome.storage.local.get("settings");
  const stored = (settings && settings.days) || {};
  const days = {};
  for (const d of Object.keys(DEFAULT_SETTINGS.days)) {
    days[d] = { ...DEFAULT_SETTINGS.days[d], ...stored[d] };
  }
  return { ...DEFAULT_SETTINGS, ...settings, days };
}
