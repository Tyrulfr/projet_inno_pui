function applyTheme(theme) {
  const isDark = theme === 'dark';
  document.body.classList.toggle('dark-mode', isDark);

  const btn = document.querySelector('.theme-btn');
  if (!btn) return;

  btn.innerHTML = isDark
    ? '<i class="fa-solid fa-sun"></i> Mode Jour'
    : '<i class="fa-solid fa-moon"></i> Mode Nuit';
}

function toggleTheme() {
  const isDark = document.body.classList.contains('dark-mode');
  const next = isDark ? 'light' : 'dark';
  localStorage.setItem('theme', next);
  applyTheme(next);
}

window.addEventListener('DOMContentLoaded', () => {
  const saved = localStorage.getItem('theme');
  applyTheme(saved === 'dark' ? 'dark' : 'light');
});
