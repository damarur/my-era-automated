// MyEra API helpers, shared by popup.js (script tag) and background.js (importScripts).
const BASE = "https://hcs.eratime.eu/api/proxy";

const baseHeaders = {
  "Content-Type": "application/x-www-form-urlencoded",
  "hcs-application-key": "ERAATTENDANCE",
  "hcs-customer-key": "lufthansa",
};

const pad = (n) => String(n).padStart(2, "0");
const ymd = (d) => `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;

async function login(user, pass) {
  const res = await fetch(`${BASE}/login`, {
    method: "POST",
    headers: { ...baseHeaders, "hcs-user": user, "hcs-pass": pass },
  });
  const token = res.headers.get("hcs-token");
  if (!token) throw new Error(`Login failed (HTTP ${res.status}). Check your user and password.`);
  return { token, refreshToken: res.headers.get("hcs-refresh-token") };
}

async function fetchUserInfo(user, token) {
  const res = await fetch(`${BASE}/flt/myera/feature/user/info`, {
    headers: { ...baseHeaders, "hcs-user-code": user, "hcs-token": token },
  });
  if (!res.ok) throw new Error(`User info failed (HTTP ${res.status})`);
  const { data } = await res.json();
  return { employeeCode: data.employee.code, fullName: data.name.full };
}

// Logs in with the saved credentials and returns {user, token}, or null when none are saved.
async function getSession() {
  const { user, pass } = await chrome.storage.local.get(["user", "pass"]);
  if (!user || !pass) return null;
  const { token, refreshToken } = await login(user, pass);
  if (refreshToken) await chrome.storage.local.set({ refreshToken });
  return { user, token };
}

// start/end are YYYY-MM-DD; returns the calendar array (one entry per day).
async function fetchCalendar(session, employeeCode, start, end) {
  const res = await fetch(
    `${BASE}/flt/myera/feature/calendar/employees/${encodeURIComponent(employeeCode)}?DATE_START=${start}&DATE_END=${end}`,
    { headers: { ...baseHeaders, "hcs-user-code": session.user, "hcs-token": session.token } },
  );
  if (!res.ok) throw new Error(`Calendar failed (HTTP ${res.status})`);
  const { data } = await res.json();
  return data.calendar;
}

// type: 1 = clock in, 2 = clock out
async function postClocking(session, type) {
  const res = await fetch(`${BASE}/flt/myera/feature/clocking?TYPE=${type}`, {
    method: "POST",
    headers: { ...baseHeaders, "hcs-user-code": session.user, "hcs-token": session.token },
  });
  if (!res.ok) throw new Error(`Clocking failed (HTTP ${res.status})`);
}
