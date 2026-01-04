/**
 * Gère l'application du thème (Sombre ou Clair)
 * @param {string} theme - 'dark' ou 'light'
 */
function setTheme(theme) {
  const isDark = theme === 'dark';
  document.body.classList.toggle('dark-mode', isDark);

  // On cible le bouton par son ID défini dans le layout
  const btn = document.getElementById('theme-toggle');
  
  if (btn) {
    // On met à jour l'icône et le texte du bouton
    btn.innerHTML = isDark
      ? '<i class="fa-solid fa-sun"></i> MODE JOUR'
      : '<i class="fa-solid fa-moon"></i> MODE NUIT';
  }
}

/**
 * Alterne entre les deux thèmes et sauvegarde le choix
 */
function toggleTheme() {
  const isDark = document.body.classList.contains('dark-mode');
  const nextTheme = isDark ? 'light' : 'dark';
  
  localStorage.setItem('theme', nextTheme);
  setTheme(nextTheme);
}

// Initialisation au chargement de la page
window.addEventListener('DOMContentLoaded', () => {
  // 1. Appliquer le thème sauvegardé ou le thème clair par défaut
  const savedTheme = localStorage.getItem('theme') || 'light';
  setTheme(savedTheme);

  // 2. Attacher l'événement au bouton (CRUCIAL)
  const btn = document.getElementById('theme-toggle');
  if (btn) {
    btn.addEventListener('click', toggleTheme);
  }
});
