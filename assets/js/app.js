(() => {
  const btn = document.getElementById("toggleTheme");
  if (!btn) return;

  btn.addEventListener("click", () => {
    document.documentElement.classList.toggle("light");
  });
})();
