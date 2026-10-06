const DAY_NAMES = { 1: "Monday", 2: "Tuesday", 3: "Wednesday", 4: "Thursday", 5: "Friday" };
const ORDER = [1, 2, 3, 4, 5];
const $ = (id) => document.getElementById(id);

function render(settings) {
  $("enabled").checked = settings.remindersEnabled;
  $("days").innerHTML = "";
  for (const d of ORDER) {
    const cfg = settings.days[d];
    const tr = document.createElement("tr");
    tr.dataset.day = d;
    tr.innerHTML = `
      <td>${DAY_NAMES[d]}</td>
      <td><input type="checkbox" class="en" ${cfg.enabled ? "checked" : ""}></td>
      <td><input type="time" class="in" value="${cfg.in}"></td>
      <td><input type="time" class="out" value="${cfg.out}"></td>
      <td><input type="checkbox" class="bon" ${cfg.breakEnabled ? "checked" : ""}></td>
      <td><input type="time" class="bs" value="${cfg.breakStart}"></td>
      <td><input type="time" class="be" value="${cfg.breakEnd}"></td>
      <td><input type="time" class="tg" value="${cfg.target}"></td>`;
    $("days").appendChild(tr);
  }
}

function collect() {
  const days = {};
  for (const tr of $("days").children) {
    days[tr.dataset.day] = {
      enabled: tr.querySelector(".en").checked,
      in: tr.querySelector(".in").value,
      out: tr.querySelector(".out").value,
      breakEnabled: tr.querySelector(".bon").checked,
      breakStart: tr.querySelector(".bs").value,
      breakEnd: tr.querySelector(".be").value,
      target: tr.querySelector(".tg").value || "00:00",
    };
  }
  return { remindersEnabled: $("enabled").checked, days };
}

const minutes = (t) => { const [h, m] = t.split(":").map(Number); return h * 60 + m; };

function flash(msg) {
  $("status").textContent = msg;
  setTimeout(() => ($("status").textContent = ""), 4000);
}

$("save").addEventListener("click", async () => {
  const settings = collect();
  await chrome.storage.local.set({ settings });
  const short = ORDER.filter((d) => {
    const c = settings.days[d];
    return c.breakEnabled && minutes(c.breakEnd) - minutes(c.breakStart) < 30;
  });
  flash(short.length ? `Saved. Warning: break under 30 min on ${short.map((d) => DAY_NAMES[d]).join(", ")}` : "Saved");
});
$("reset").addEventListener("click", async () => {
  await chrome.storage.local.remove("settings");
  render(await getSettings());
  flash("Reset");
});

getSettings().then(render);
