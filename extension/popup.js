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
  return token;
}

async function clock(type) {
  const user = $("user").value.trim();
  const pass = $("pass").value;
  if (!user || !pass) return setStatus("Enter user and password", false);

  await chrome.storage.local.set({ user, pass });
  $("in").disabled = $("out").disabled = true;
  setStatus("Working...");
  try {
    const token = await login(user, pass);
    const res = await fetch(`${BASE}/flt/myera/feature/clocking?TYPE=${type}`, {
      method: "POST",
      headers: { ...baseHeaders, "hcs-user-code": user, "hcs-token": token },
    });
    if (!res.ok) throw new Error(`Clocking failed (HTTP ${res.status})`);
    const time = new Date().toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" });
    setStatus(`${type === 1 ? "Clocked in" : "Clocked out"} at ${time}`, true);
  } catch (e) {
    setStatus(e.message, false);
  } finally {
    $("in").disabled = $("out").disabled = false;
  }
}

chrome.storage.local.get(["user", "pass"]).then(({ user, pass }) => {
  if (user) $("user").value = user;
  if (pass) $("pass").value = pass;
});
$("in").addEventListener("click", () => clock(1));
$("out").addEventListener("click", () => clock(2));
$("settings").addEventListener("click", (e) => { e.preventDefault(); chrome.runtime.openOptionsPage(); });
