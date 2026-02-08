#!/usr/bin/env bash
# OSER POUR INNOVER - Setup Directus (équivalent de run-setup-directus.bat sur Windows).
# Supprime les anciennes collections apprenants et progress puis recrée le modèle MULTI-ORIGINE.
# Prérequis : .env avec DIRECTUS_URL et DIRECTUS_TOKEN (ou DIRECTUS_EMAIL + DIRECTUS_PASSWORD).

set -e
cd "$(dirname "$0")"

echo "============================================"
echo "  OSER POUR INNOVER - Setup Directus"
echo "============================================"
echo ""
echo "Ce script SUPPRIME les anciennes collections apprenants et progress"
echo "(si elles existent), puis recrée le modèle MULTI-ORIGINE via l'API."
echo "Données existantes dans ces collections seront perdues."
echo "Fichier .env requis (DIRECTUS_URL, DIRECTUS_TOKEN)."
echo ""
echo "Nouveau modèle : apprenants (origin, external_user_id, email, date_creation)"
echo "                  progress (apprenant_id, grain_id, module_id, ...)"
echo ""

if [[ ! -f .env ]]; then
  echo "Fichier .env introuvable. Copiez .env.example en .env et renseignez DIRECTUS_URL et DIRECTUS_TOKEN."
  exit 1
fi

if ! command -v node &>/dev/null; then
  echo "Node.js est requis pour ce script. Installez Node.js puis relancez."
  exit 1
fi

node scripts/setup-directus.js
err=$?
echo ""
if [[ $err -ne 0 ]]; then
  echo "Erreur : vérifiez .env (DIRECTUS_URL, DIRECTUS_TOKEN) et la connexion."
  exit $err
else
  echo "Terminé. Vérifiez dans Directus : Paramètres > Data Model."
fi
echo ""
