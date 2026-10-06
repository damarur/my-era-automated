// Shared by background.js (importScripts) and options.js (script tag).
const DEFAULT_SETTINGS = {
  remindersEnabled: true,
  // key = Date#getDay(): 1=Mon .. 5=Fri
  days: {
    1: { enabled: true, in: "08:00", out: "17:00" },
    2: { enabled: true, in: "08:00", out: "17:00" },
    3: { enabled: true, in: "08:00", out: "17:00" },
    4: { enabled: true, in: "08:00", out: "17:00" },
    5: { enabled: true, in: "08:00", out: "14:00" },
  },
};

async function getSettings() {
  const { settings } = await chrome.storage.local.get("settings");
  return {
    ...DEFAULT_SETTINGS,
    ...settings,
    days: { ...DEFAULT_SETTINGS.days, ...(settings && settings.days) },
  };
}
