async function fetchState() {
  const res = await fetch("/state");
  const data = await res.json();
  document.getElementById("score").textContent = data.score;
}

async function click() {
  const res = await fetch("/click", { method: "POST" });
  const data = await res.json();
  document.getElementById("score").textContent = data.score;
}

document.addEventListener("DOMContentLoaded", () => {
  document.getElementById("click-btn").addEventListener("click", click);
  fetchState();
});
