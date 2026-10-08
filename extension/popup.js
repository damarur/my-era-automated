const $ = (id) => document.getElementById(id);

function setStatus(msg, ok) {
  const el = $("status");
  el.textContent = msg;
  el.className = ok === undefined ? "" : ok ? "ok" : "err";
}

const fmt = (ms) => `${Math.floor(ms / 3600000)}h ${pad(Math.floor((ms % 3600000) / 60000))}m`;
const fmtSigned = (ms) => `${ms < 0 ? "−" : "+"}${fmt(Math.abs(ms))}`;
const hmToMs = (t) => { const [h, m] = (t || "00:00").split(":").map(Number); return (h * 60 + m) * 60000; };
const DAYS = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];

// Effective time = sum of the time blocks between consecutive clockings, minus the overlap with
// the configured lunch break window. Every pair of consecutive clockings is a valid block
// (in->out, but also in->in and out->out, since MyEra allows repeated clockings of the same
// type), except out->in, which is a break. If the day already has a clocked break, the
// configured window is ignored. A block still open today (last clocking is an "in") only counts
// up to now, so a break that has not started yet is not deducted.
function effectiveMs(clockings, key, isToday, cfg) {
  const intervals = [];
  let clockedBreak = false;
  let prev = null;
  for (const c of clockings) {
    const cur = { in: c.in, t: new Date(c.time).getTime() };
    if (prev) {
      if (!prev.in && cur.in) clockedBreak = clockedBreak || intervals.length > 0;
      else intervals.push([prev.t, cur.t]);
    }
    prev = cur;
  }
  if (prev && prev.in && isToday) intervals.push([prev.t, Date.now()]);

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

// Navigation state: view is "week" or "month", offset counts periods back from the current one
// (0 = current, never positive). History is limited to one year.
let view = "week";
let offset = 0;
let loadId = 0;
const MONTHS = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];

function periodRange(now, off) {
  if (view === "week") {
    const start = new Date(now.getFullYear(), now.getMonth(), now.getDate() - ((now.getDay() + 6) % 7) + 7 * off);
    return { start, end: new Date(start.getFullYear(), start.getMonth(), start.getDate() + 6) };
  }
  return {
    start: new Date(now.getFullYear(), now.getMonth() + off, 1),
    end: new Date(now.getFullYear(), now.getMonth() + off + 1, 0),
  };
}

function updateNav(now) {
  const { start, end } = periodRange(now, offset);
  const dm = (d) => `${pad(d.getDate())}/${pad(d.getMonth() + 1)}`;
  $("periodLabel").textContent = view === "week" ? `${dm(start)} – ${dm(end)}` : `${MONTHS[start.getMonth()]} ${start.getFullYear()}`;
  $("weekBtn").classList.toggle("active", view === "week");
  $("monthBtn").classList.toggle("active", view === "month");
  $("totalLabel").textContent = view === "week" ? "Week" : "Month";
  $("next").disabled = offset >= 0;
  $("today").style.visibility = offset >= 0 ? "hidden" : "visible";
  const limit = new Date(now.getFullYear() - 1, now.getMonth(), now.getDate());
  $("prev").disabled = periodRange(now, offset - 1).end < limit;
}

async function loadPeriod() {
  const id = ++loadId;
  const body = $("week").tBodies[0];
  const now = new Date();
  updateNav(now);
  try {
    const { employeeCode } = await chrome.storage.local.get("employeeCode");
    const settings = await getSettings();
    const session = await getSession();
    if (!employeeCode || !session) throw new Error("Missing session, please log in again");

    const { start, end } = periodRange(now, offset);
    // Fetch whole Mon-Fri weeks so targets can be redistributed per week even when the period
    // starts or ends mid-week; days outside the period are only used for that.
    const first = new Date(start.getFullYear(), start.getMonth(), start.getDate() - ((start.getDay() + 6) % 7));
    const last = new Date(end.getFullYear(), end.getMonth(), end.getDate() - ((end.getDay() + 6) % 7) + 4);
    const fetchEnd = offset === 0 && ymd(now) > ymd(last) ? now : last; // weekend: still fetch today for the button state
    const calendar = await fetchCalendar(session, employeeCode, ymd(first), ymd(fetchEnd));
    if (id !== loadId) return;
    const byDate = Object.fromEntries(calendar.map((d) => [d.date, d]));

    const today = ymd(now);
    if (offset === 0) {
      const todayClockings = (byDate[today] && byDate[today].clockings) || [];
      clockState = todayClockings.length && todayClockings[todayClockings.length - 1].in ? "in" : "out";
      updateClockButtons();
    }

    // Target per day: the average configured daily target x working days is spread over the
    // week. On a normal week each day keeps its own target; when a day is off (absence/holiday)
    // the average is spread over the remaining days so the weekly average does not go over
    // (e.g. 38h/5 = 7h36 per working day).
    const rows = [];
    for (let w = new Date(first); w <= last; w.setDate(w.getDate() + 7)) {
      const days = [];
      for (let i = 0; i < 5; i++) {
        const d = new Date(w.getFullYear(), w.getMonth(), w.getDate() + i);
        const key = ymd(d);
        const entry = byDate[key] || {};
        const off = (entry.absences || []).length > 0 ? "Absent" : entry.publicHoliday && entry.publicHoliday.enabled ? "Holiday" : null;
        days.push({ d, key, cfg: settings.days[d.getDay()], clockings: entry.clockings || [], off });
      }
      const avg = days.reduce((sum, x) => sum + hmToMs(x.cfg.target), 0) / 5;
      const redistribute = days.some((x) => x.off);
      for (const x of days) {
        x.target = x.off ? 0 : redistribute ? avg : hmToMs(x.cfg.target);
        if (x.d >= start && x.d <= end) rows.push(x);
      }
    }

    let total = 0, totalTarget = 0;
    body.innerHTML = "";
    for (const x of rows) {
      const ms = effectiveMs(x.clockings, x.key, x.key === today, x.cfg);
      const open = x.clockings.length > 0 && x.clockings[x.clockings.length - 1].in;
      const pending = x.key > today || (x.key === today && (open || !x.clockings.length));
      total += ms;
      // The week view keeps the full weekly target; in the month view days not due yet are left out.
      totalTarget += view === "month" && x.key > today ? 0 : x.target;

      const tr = body.insertRow();
      if (x.key === today) tr.className = "today";
      if (x.d.getDay() === 1) tr.classList.add("monday");
      tr.insertCell().textContent = DAYS[x.d.getDay()];
      tr.insertCell().textContent = `${pad(x.d.getDate())}/${pad(x.d.getMonth() + 1)}`;
      tr.insertCell().textContent = x.clockings.length ? fmt(ms) : "–";
      tr.insertCell().textContent = x.off ? "–" : fmt(x.target);
      const diff = tr.insertCell();
      if (x.clockings.length) {
        diff.textContent = fmtSigned(ms - x.target);
        diff.className = pending ? "pending" : ms >= x.target ? "pos" : "neg";
      } else {
        diff.textContent = x.off || "–";
        if (x.off) diff.className = "pending";
      }
    }
    $("weekTotal").textContent = fmt(total);
    $("weekTarget").textContent = fmt(totalTarget);
    const weekDiff = $("weekDiff");
    weekDiff.textContent = fmtSigned(total - totalTarget);
    weekDiff.className = total >= totalTarget ? "pos" : "neg";
    setStatus("");
  } catch (e) {
    if (id !== loadId) return;
    if (offset === 0) {
      clockState = "error";
      updateClockButtons();
    }
    setStatus(e.message, false);
  }
}

function setView(v) {
  view = v;
  offset = 0;
  chrome.storage.local.set({ view });
  loadPeriod();
}

function showView(user) {
  $("loginView").hidden = !!user;
  $("clockView").hidden = !user;
  $("clear").hidden = !user;
  if (!user) $("loginError").textContent = "";
  clockState = null;
  updateClockButtons();
  if (user) {
    $("who").textContent = user;
    loadPeriod();
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
  const error = (msg) => { $("loginError").textContent = msg; };
  error("");
  if (!user || !pass) return error("Enter your user and password");

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
    setStatus("");
    error(e.message === "Failed to fetch" ? "Could not reach MyEra. Check your connection." : e.message);
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
    await postClocking(session, type);
    const time = new Date().toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" });
    setStatus(`${type === 1 ? "Clocked in" : "Clocked out"} at ${time}`, true);
    loadPeriod();
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

chrome.storage.local.get(["user", "fullName", "view"]).then(({ user, fullName, view: saved }) => {
  if (saved === "week" || saved === "month") view = saved;
  showView(fullName || user);
});
$("weekBtn").addEventListener("click", () => setView("week"));
$("monthBtn").addEventListener("click", () => setView("month"));
$("today").addEventListener("click", () => { offset = 0; loadPeriod(); });
$("prev").addEventListener("click", () => { offset--; loadPeriod(); });
$("next").addEventListener("click", () => { if (offset < 0) { offset++; loadPeriod(); } });
$("loginView").addEventListener("submit", (e) => { e.preventDefault(); doLogin(); });
$("eye").addEventListener("click", () => {
  const show = $("pass").type === "password";
  $("pass").type = show ? "text" : "password";
  $("eye").classList.toggle("shown", show);
  $("eye").title = $("eye").ariaLabel = show ? "Hide password" : "Show password";
});
$("clear").addEventListener("click", clearCredentials);
$("in").addEventListener("click", () => clock(1));
$("out").addEventListener("click", () => clock(2));
$("settings").addEventListener("click", (e) => { e.preventDefault(); chrome.runtime.openOptionsPage(); });
$("open").addEventListener("click", () => chrome.tabs.create({ url: "https://myera.eratime.eu/" }));
