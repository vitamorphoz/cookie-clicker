// Update statistics display
function updateStats(data) {
  document.getElementById("score").textContent = data.score;
  document.getElementById("best-score").textContent = data.best_score;
  document.getElementById("cps").textContent = data.cps.toFixed(1);
  
  // Format session time
  const time = data.session_time;
  const minutes = Math.floor(time / 60);
  const seconds = time % 60;
  const timeStr = minutes > 0 ? `${minutes}м ${seconds}с` : `${seconds}с`;
  document.getElementById("session-time").textContent = timeStr;
  
  // Trigger pulse animation on stat values
  document.querySelectorAll('.stat-value').forEach(el => {
    el.style.animation = 'none';
    setTimeout(() => el.style.animation = 'pulse 0.3s ease', 10);
  });
}

// Fetch current state
async function fetchState() {
  try {
    const res = await fetch("/state", { credentials: "include" });
    const data = await res.json();
    updateStats(data);
  } catch (error) {
    console.error("Error fetching state:", error);
  }
}

// Create floating +1 number
function createFloatingNumber(x, y) {
  const number = document.createElement('div');
  number.className = 'floating-number';
  number.textContent = '+1';
  number.style.left = x + 'px';
  number.style.top = y + 'px';
  
  document.getElementById('floating-numbers').appendChild(number);
  
  // Remove after animation
  setTimeout(() => number.remove(), 1000);
}

// Create particle explosion
function createParticles(x, y) {
  const particleCount = 8;
  const container = document.getElementById('floating-numbers');
  
  for (let i = 0; i < particleCount; i++) {
    const particle = document.createElement('div');
    particle.className = 'particle';
    
    const angle = (Math.PI * 2 * i) / particleCount;
    const distance = 50 + Math.random() * 30;
    const tx = Math.cos(angle) * distance;
    const ty = Math.sin(angle) * distance;
    
    particle.style.left = x + 'px';
    particle.style.top = y + 'px';
    particle.style.setProperty('--tx', tx + 'px');
    particle.style.setProperty('--ty', ty + 'px');
    
    container.appendChild(particle);
    
    setTimeout(() => particle.remove(), 800);
  }
}

// Handle click
async function click(event) {
  try {
    const res = await fetch("/click", { method: "POST", credentials: "include" });
    const data = await res.json();
    updateStats(data);
    
    // Get click position relative to app container
    const rect = document.querySelector('.app').getBoundingClientRect();
    const x = event.clientX - rect.left;
    const y = event.clientY - rect.top;
    
    // Create floating number
    createFloatingNumber(x, y);
    
    // Create particles every 5 clicks
    if (data.score % 5 === 0) {
      createParticles(x, y);
    }
    
    // Add click animation to cookie
    const cookie = document.getElementById('click-cookie');
    cookie.classList.remove('clicked');
    setTimeout(() => cookie.classList.add('clicked'), 10);
    setTimeout(() => cookie.classList.remove('clicked'), 300);
    
  } catch (error) {
    console.error("Error clicking:", error);
  }
}

// Initialize
document.addEventListener("DOMContentLoaded", () => {
  const cookie = document.getElementById("click-cookie");
  cookie.addEventListener("click", click);
  
  // Fetch initial state
  fetchState();
  
  // Update state periodically
  setInterval(fetchState, 5000);
});
