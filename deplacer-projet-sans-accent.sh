#!/usr/bin/env bash
# Copie le projet vers un chemin sans accent (pour éviter les soucis avec certains outils).
# Équivalent de deplacer-projet-sans-accent.bat sur Windows.
# Sous macOS, destination par défaut : $HOME/projet_inno_pui

set -e
SRC="$(cd "$(dirname "$0")" && pwd)"
DEST="${1:-$HOME/projet_inno_pui}"

echo ""
echo "Ce script copie le projet vers $DEST (chemin sans accent)."
echo "IMPORTANT : Fermez Cursor avant de lancer ce script si vous ouvrez le projet depuis ce dossier."
echo ""
read -p "Appuyez sur Entrée pour continuer (ou Ctrl+C pour annuler)..."

mkdir -p "$DEST"
echo "Copie en cours..."
if command -v rsync &>/dev/null; then
  rsync -a --exclude='.git' --exclude='node_modules' --exclude='_site' "$SRC/" "$DEST/"
else
  cp -R "$SRC"/* "$DEST/" 2>/dev/null || true
  cp "$SRC"/.env "$DEST/" 2>/dev/null || true
  cp "$SRC"/.env.example "$DEST/" 2>/dev/null || true
  cp "$SRC"/.gitignore "$DEST/" 2>/dev/null || true
fi

echo ""
echo "Terminé. Ouvrez Cursor puis : Fichier > Ouvrir un dossier > $DEST"
echo "L'ancien dossier peut être supprimé plus tard si vous voulez."
echo ""
