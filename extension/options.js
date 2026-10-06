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
      <td><input type="time" class="out" value="${cfg.out}"></td>`;
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
    };
  }
  return { remindersEnabled: $("enabled").checked, days };
}

function flash(msg) {
  $("status").textContent = msg;
  setTimeout(() => ($("status").textContent = ""), 2000);
}

$("save").addEventListener("click", async () => {
  await chrome.storage.local.set({ settings: collect() });
  flash("Saved");
});
$("reset").addEventListener("click", async () => {
  await chrome.storage.local.remove("settings");
  render(await getSettings());
  flash("Reset");
});

getSettings().then(render);
