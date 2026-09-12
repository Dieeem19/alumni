// ============================================================
// SHARED BEHAVIOR — BCP Alumni System Main JS
// ============================================================

// Dark Mode & Light Mode Theme Engine
function initTheme() {
  const savedTheme = localStorage.getItem('bcp_theme') || 'light';
  if (savedTheme === 'dark') {
    document.body.classList.add('dark-theme');
  } else {
    document.body.classList.remove('dark-theme');
  }
  updateThemeBtnIcon(savedTheme);
}

function toggleTheme() {
  const isDark = document.body.classList.toggle('dark-theme');
  const newTheme = isDark ? 'dark' : 'light';
  localStorage.setItem('bcp_theme', newTheme);
  updateThemeBtnIcon(newTheme);
}

function updateThemeBtnIcon(theme) {
  const btns = document.querySelectorAll('#themeToggleBtn, .theme-toggle-btn');
  btns.forEach(btn => {
    btn.innerHTML = `<span class="material-symbols-outlined" style="font-size:1.15rem; vertical-align:middle;">${theme === 'dark' ? 'light_mode' : 'dark_mode'}</span>`;
    btn.title = theme === 'dark' ? 'Switch to Light Mode' : 'Switch to Dark Mode';
  });
}

// Sidebar toggle (mobile / hamburger)
const sidebarToggle = document.getElementById('sidebarToggle');
const sidebar = document.getElementById('sidebar');
if (sidebarToggle && sidebar) {
  sidebarToggle.addEventListener('click', () => {
    sidebar.classList.toggle('open');
  });
}

// Live clock sa topbar
const clockEl = document.getElementById('clock');
function updateClock() {
  if (!clockEl) return;
  const now = new Date();
  clockEl.textContent = now.toLocaleTimeString('en-PH', {
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
    hour12: true
  });
}
if (clockEl) {
  updateClock();
  setInterval(updateClock, 1000);
}

// Show/hide password sa login page
const togglePassword = document.getElementById('togglePassword');
const passwordInput = document.getElementById('password');
if (togglePassword && passwordInput) {
  togglePassword.addEventListener('click', () => {
    const isHidden = passwordInput.type === 'password';
    passwordInput.type = isHidden ? 'text' : 'password';
    togglePassword.innerHTML = `<span class="material-symbols-outlined" style="font-size:1.15rem; vertical-align:middle;">${isHidden ? 'visibility_off' : 'visibility'}</span>`;
  });
}

// Display Logged In User in Topbar and Page Header
document.addEventListener('DOMContentLoaded', () => {
  initTheme();

  const userName = sessionStorage.getItem('bcp_admin_name');
  if (userName) {
    const topbarUserSpan = document.querySelector('.topbar-user span');
    if (topbarUserSpan) topbarUserSpan.textContent = userName;

    const avatar = document.querySelector('.topbar-user .avatar');
    if (avatar) {
      const parts = userName.trim().split(' ');
      const initials = parts.length > 1 ? (parts[0][0] + parts[parts.length - 1][0]).toUpperCase() : userName.substring(0, 2).toUpperCase();
      avatar.textContent = initials;
    }

    const welcomeBanner = document.querySelector('#welcomeBanner span');
    if (welcomeBanner) welcomeBanner.textContent = `Welcome back, ${userName}!`;

    const pageTitle = document.querySelector('.page-title');
    if (pageTitle && pageTitle.textContent.includes('Welcome')) {
      pageTitle.textContent = `Welcome, ${userName}`;
    }
  }
});
