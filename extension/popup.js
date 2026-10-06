const BASE = "https://hcs.eratime.eu/api/proxy";
const $ = (id) => document.getElementById(id);

const baseHeaders = {
  "Content-Type": "application/x-www-form-urlencoded",
  "hcs-application-key": "ERAATTENDANCE",
  "hcs-customer-key": "lufthansa",
};

function setStatus(msg, ok) {
  const el = $("status");
  el.textContent = msg;
  el.className = ok === undefined ? "" : ok ? "ok" : "err";
}

async function login(user, pass) {
  const res = await fetch(`${BASE}/login`, {
    method: "POST",
    headers: { ...baseHeaders, "hcs-user": user, "hcs-pass": pass },
  });
  const token = res.headers.get("hcs-token");
  if (!token) throw new Error(`Login failed (HTTP ${res.status})`);
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

async function getSession() {
  const { user, pass } = await chrome.storage.local.get(["user", "pass"]);
  if (!user || !pass) return null;
  const { token, refreshToken } = await login(user, pass);
  if (refreshToken) await chrome.storage.local.set({ refreshToken });
  return { user, token };
}

const pad = (n) => String(n).padStart(2, "0");
const ymd = (d) => `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
const fmt = (ms) => `${Math.floor(ms / 3600000)}h ${pad(Math.floor((ms % 3600000) / 60000))}m`;
const fmtSigned = (ms) => `${ms < 0 ? "−" : "+"}${fmt(Math.abs(ms))}`;
const hmToMs = (t) => { const [h, m] = (t || "00:00").split(":").map(Number); return (h * 60 + m) * 60000; };
const DAYS = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];

// Effective time = sum of in->out intervals minus the overlap with the configured unpaid break
// window. If the day already has a clocked break (out followed by in), the configured window
// is ignored. An interval still open today only counts up to now, so a break that has not
// started yet is not deducted.
function effectiveMs(clockings, key, isToday, cfg) {
  const intervals = [];
  let openAt = null, clockedBreak = false;
  for (const c of clockings) {
    const t = new Date(c.time).getTime();
    if (c.in) {
      if (openAt === null && intervals.length) clockedBreak = true;
      openAt = t;
    } else if (openAt !== null) {
      intervals.push([openAt, t]);
      openAt = null;
    }
  }
  if (openAt !== null && isToday) intervals.push([openAt, Date.now()]);

  const deduct = cfg.breakEnabled && !clockedBreak;
  const bs = new Date(`${key}T${cfg.breakStart}`).getTime();
  const be = new Date(`${key}T${cfg.breakEnd}`).getTime();
  let total = 0;
  for (const [a, b] of intervals) {
    total += b - a;
    if (deduct && be > bs) total -= Math.max(0, Math.min(b, be) - Math.max(a, bs));
  }
  return total;
}

async function loadWeek() {
  const body = $("week").tBodies[0];
  try {
    const { employeeCode } = await chrome.storage.local.get("employeeCode");
    const settings = await getSettings();
    const session = await getSession();
    if (!employeeCode || !session) throw new Error("Missing session, please log in again");

    const now = new Date();
    const monday = new Date(now.getFullYear(), now.getMonth(), now.getDate() - ((now.getDay() + 6) % 7));
    const friday = new Date(monday.getFullYear(), monday.getMonth(), monday.getDate() + 4);
    const end = ymd(now) > ymd(friday) ? now : friday; // weekend: still fetch today for the button state
    const res = await fetch(
      `${BASE}/flt/myera/feature/calendar/employees/${encodeURIComponent(employeeCode)}?DATE_START=${ymd(monday)}&DATE_END=${ymd(end)}`,
      { headers: { ...baseHeaders, "hcs-user-code": session.user, "hcs-token": session.token } },
    );
    if (!res.ok) throw new Error(`Calendar failed (HTTP ${res.status})`);
    const { data } = await res.json();
    const byDate = Object.fromEntries(data.calendar.map((d) => [d.date, d]));

    const today = ymd(now);
    const todayClockings = (byDate[today] && byDate[today].clockings) || [];
    clockState = todayClockings.length && todayClockings[todayClockings.length - 1].in ? "in" : "out";
    updateClockButtons();
    const days = [];
    for (let i = 0; i < 5; i++) {
      const d = new Date(monday.getFullYear(), monday.getMonth(), monday.getDate() + i);
      const key = ymd(d);
      const entry = byDate[key] || {};
      const off = (entry.absences || []).length > 0 ? "Absent" : entry.publicHoliday && entry.publicHoliday.enabled ? "Holiday" : null;
      days.push({ d, key, cfg: settings.days[d.getDay()], clockings: entry.clockings || [], off });
    }

    // Weekly target = average configured daily target x working days. On a normal week each day
    // keeps its own target; when a day is off (absence/holiday) the average is spread over the
    // remaining days so the weekly average does not go over (e.g. 38h/5 = 7h36 per working day).
    const avg = days.reduce((sum, x) => sum + hmToMs(x.cfg.target), 0) / 5;
    const redistribute = days.some((x) => x.off);
    let week = 0, weekTarget = 0;
    body.innerHTML = "";
    for (const x of days) {
      const ms = effectiveMs(x.clockings, x.key, x.key === today, x.cfg);
      const target = x.off ? 0 : redistribute ? avg : hmToMs(x.cfg.target);
      const open = x.clockings.length > 0 && x.clockings[x.clockings.length - 1].in;
      const pending = x.key > today || (x.key === today && (open || !x.clockings.length));
      week += ms;
      weekTarget += target;

      const tr = body.insertRow();
      if (x.key === today) tr.className = "today";
      tr.insertCell().textContent = DAYS[x.d.getDay()];
      tr.insertCell().textContent = `${pad(x.d.getDate())}/${pad(x.d.getMonth() + 1)}`;
      tr.insertCell().textContent = x.clockings.length ? fmt(ms) : "–";
      tr.insertCell().textContent = x.off ? "–" : fmt(target);
      const diff = tr.insertCell();
      if (x.clockings.length) {
        diff.textContent = fmtSigned(ms - target);
        diff.className = pending ? "pending" : ms >= target ? "pos" : "neg";
      } else {
        diff.textContent = x.off || "–";
        if (x.off) diff.className = "pending";
      }
    }
    $("weekTotal").textContent = fmt(week);
    $("weekTarget").textContent = fmt(weekTarget);
    const weekDiff = $("weekDiff");
    weekDiff.textContent = fmtSigned(week - weekTarget);
    weekDiff.className = week >= weekTarget ? "pos" : "neg";
  } catch (e) {
    clockState = "error";
    updateClockButtons();
    setStatus(e.message, false);
  }
}

function showView(user) {
  $("loginView").hidden = !!user;
  $("clockView").hidden = !user;
  $("clear").hidden = !user;
  clockState = null;
  updateClockButtons();
  if (user) {
    $("who").textContent = user;
    loadWeek();
  }
}

// Which clock button is allowed, from today's last clocking: "in" (clocked in -> only out),
// "out" (none or clocked out -> only in), "error" (could not tell -> both), null (still loading).
let clockState = null;
let isBusy = false;

function updateClockButtons() {
  $("in").disabled = isBusy || clockState === null || clockState === "in";
  $("out").disabled = isBusy || clockState === null || clockState === "out";
}

function busy(b) {
  isBusy = b;
  $("login").disabled = $("clear").disabled = b;
  updateClockButtons();
}

async function doLogin() {
  const user = $("user").value.trim();
  const pass = $("pass").value;
  if (!user || !pass) return setStatus("Enter user and password", false);

  busy(true);
  setStatus("Verifying...");
  try {
    const { token, refreshToken } = await login(user, pass);
    const { employeeCode, fullName } = await fetchUserInfo(user, token);
    await chrome.storage.local.set({ user, pass, refreshToken, employeeCode, fullName });
    $("pass").value = "";
    showView(fullName);
    setStatus("Credentials verified and saved", true);
  } catch (e) {
    setStatus(e.message, false);
  } finally {
    busy(false);
  }
}

async function clock(type) {
  busy(true);
  setStatus("Working...");
  try {
    const session = await getSession();
    if (!session) return showView(null);
    const res = await fetch(`${BASE}/flt/myera/feature/clocking?TYPE=${type}`, {
      method: "POST",
      headers: { ...baseHeaders, "hcs-user-code": session.user, "hcs-token": session.token },
    });
    if (!res.ok) throw new Error(`Clocking failed (HTTP ${res.status})`);
    const time = new Date().toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" });
    setStatus(`${type === 1 ? "Clocked in" : "Clocked out"} at ${time}`, true);
    loadWeek();
  } catch (e) {
    setStatus(e.message, false);
  } finally {
    busy(false);
  }
}

async function clearCredentials() {
  await chrome.storage.local.remove(["user", "pass", "refreshToken", "employeeCode", "fullName"]);
  $("user").value = $("pass").value = "";
  showView(null);
  setStatus("Credentials cleared");
}

chrome.storage.local.get(["user", "fullName"]).then(({ user, fullName }) => showView(fullName || user));
$("login").addEventListener("click", doLogin);
$("clear").addEventListener("click", clearCredentials);
$("in").addEventListener("click", () => clock(1));
$("out").addEventListener("click", () => clock(2));
$("settings").addEventListener("click", (e) => { e.preventDefault(); chrome.runtime.openOptionsPage(); });
$("open").addEventListener("click", () => chrome.tabs.create({ url: "https://myera.eratime.eu/" }));
