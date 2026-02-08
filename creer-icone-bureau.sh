#!/usr/bin/env bash
# Crée un raccourci sur le Bureau (Desktop) vers le projet / icône OSER POUR INNOVER.
# Équivalent de creer-icone-bureau.bat sur Windows (sous macOS on copie l'image sur le Bureau).

set -e
cd "$(dirname "$0")"

# Image source (même nom que dans le .ps1, chemin adapté macOS/Linux)
IMG_PATH="assets/image/Visuel Osez pour Innover.png"
if [[ ! -f "$IMG_PATH" ]]; then
  IMG_PATH="assets/images/Visuel Osez pour Innover.png"
fi

if [[ ! -f "$IMG_PATH" ]]; then
  echo "Image introuvable : assets/image/Visuel Osez pour Innover.png"
  exit 1
fi

# Bureau = Desktop sur macOS/Linux
if [[ -n "$HOME" ]]; then
  DESKTOP="$HOME/Desktop"
else
  DESKTOP="$HOME/Desktop"
fi
if [[ -n "$USERPROFILE" ]]; then
  # Windows (Git Bash / WSL)
  [[ -d "$USERPROFILE/Desktop" ]] && DESKTOP="$USERPROFILE/Desktop"
fi

DEST="$DESKTOP/Oser pour Innover.png"
cp "$IMG_PATH" "$DEST"
echo "Image copiée sur le Bureau (Desktop) : $DEST"
echo "Vous pouvez l'utiliser comme raccourci visuel vers le projet."
