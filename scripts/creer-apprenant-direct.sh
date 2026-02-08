#!/usr/bin/env bash
# Crée un apprenant "direct" dans Directus et affiche les identifiants à envoyer.
# Mode 1 : si API_BASE_URL et ADMIN_SECRET dans .env -> création via l'API (identifiant + mdp).
# Mode 2 : sinon -> création dans Directus (lien magique + identifiant + mdp).
# Usage : ./scripts/creer-apprenant-direct.sh "apprenant@exemple.com"
#         ./scripts/creer-apprenant-direct.sh "apprenant@exemple.com" "https://mon-site.fr"

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ENV_PATH="$PROJECT_ROOT/.env"

if [[ -z "$1" ]]; then
  echo "Email de l'apprenant : "
  read -r EMAIL
else
  EMAIL="$1"
fi
BASE_URL="${2:-}"

if [[ -z "$EMAIL" ]]; then
  echo "Indiquez l'email : $0 \"apprenant@exemple.com\""
  exit 1
fi

if [[ ! -f "$ENV_PATH" ]]; then
  echo "Fichier .env introuvable. Copiez .env.example en .env et renseignez DIRECTUS_URL et DIRECTUS_TOKEN."
  exit 1
fi

# Charger .env (lignes non vides, non commentées)
export DIRECTUS_URL= DIRECTUS_TOKEN= DIRECTUS_EMAIL= DIRECTUS_PASSWORD= API_BASE_URL= ADMIN_SECRET= SITE_BASE_URL=
while IFS= read -r line; do
  line="${line%%#*}"
  line="${line#"${line%%[![:space:]]*}"}"
  line="${line%"${line##*[![:space:]]}"}"
  [[ -z "$line" ]] && continue
  if [[ "$line" == *=* ]]; then
    key="${line%%=*}"
    key="${key%"${key##*[![:space:]]}"}"
    val="${line#*=}"
    val="${val#"${val%%[![:space:]]*}"}"
    val="${val%"${val##*[![:space:]]}"}"
    val="${val%\"}"
    val="${val#\"}"
    val="${val%\'}"
    val="${val#\'}"
    export "$key=$val"
  fi
done < "$ENV_PATH"

DIRECTUS_URL="${DIRECTUS_URL%/}"
SITE_BASE_URL="${BASE_URL:-$SITE_BASE_URL}"
SITE_BASE_URL="${SITE_BASE_URL%/}"
[[ -z "$SITE_BASE_URL" ]] && SITE_BASE_URL="https://tyrulfr.github.io/projet_inno_pui"

# Générer identifiant et mot de passe (portable macOS/Linux)
chr() { printf '%s' "${1:$2:1}"; }
random_char() { local s="$1"; chr "$s" $((RANDOM % ${#s})); }
LOWER="abcdefghijklmnopqrstuvwxyz0123456789"
MIXED="abcdefghijklmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789"
IDENT="appr_"
for _ in {1..8}; do IDENT+=$(random_char "$LOWER"); done
PWD_GEN=""
for _ in {1..12}; do PWD_GEN+=$(random_char "$MIXED"); done

# --- Mode API (create-apprenant) ---
if [[ -n "$API_BASE_URL" && -n "$ADMIN_SECRET" ]]; then
  API_BASE_URL="${API_BASE_URL%/}"
  BODY=$(printf '{"email":"%s","identifiant":"%s","password":"%s"}' "$EMAIL" "$IDENT" "$PWD_GEN")
  RESP=$(curl -s -X POST "$API_BASE_URL/api/create-apprenant" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $ADMIN_SECRET" \
    -d "$BODY" 2>/dev/null || true)
  EXT_ID=$(echo "$RESP" | grep -o '"external_user_id":"[^"]*"' | cut -d'"' -f4)
  if [[ -n "$EXT_ID" ]]; then
    LOGIN_URL="${SITE_BASE_URL}/pages/apprenant/login.html"
    LINK="${SITE_BASE_URL}/pages/apprenant/portal.html?token=${EXT_ID}"
    echo ""
    echo "==========  A COPIER DANS LE MAIL DE BIENVENUE  =========="
    echo ""
    echo "  Lien d'accès (à ouvrir dans le navigateur) :"
    echo "  $LINK"
    echo ""
    echo "  Identifiant (pour la page Connexion du site) : $IDENT"
    echo "  Mot de passe (pour la page Connexion du site)     : $PWD_GEN"
    echo ""
    echo "  Page de connexion (identifiant + mot de passe) : $LOGIN_URL"
    echo ""
    echo "==========  CONSERVEZ CES INFORMATIONS  =========="
    exit 0
  fi
  echo "Erreur API create-apprenant. Fallback : création dans Directus."
fi

# --- Mode Directus ---
if [[ -z "$DIRECTUS_URL" ]]; then
  echo "Dans .env, renseignez DIRECTUS_URL (et DIRECTUS_TOKEN)."
  exit 1
fi

TOKEN="$DIRECTUS_TOKEN"
if [[ -z "$TOKEN" && -n "$DIRECTUS_EMAIL" && -n "$DIRECTUS_PASSWORD" ]]; then
  LOGIN_BODY=$(printf '{"email":"%s","password":"%s"}' "$DIRECTUS_EMAIL" "$DIRECTUS_PASSWORD")
  LOGIN_RESP=$(curl -s -X POST "$DIRECTUS_URL/auth/login" -H "Content-Type: application/json" -d "$LOGIN_BODY" 2>/dev/null || true)
  TOKEN=$(echo "$LOGIN_RESP" | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)
  if [[ -z "$TOKEN" ]]; then
    echo "Erreur login Directus."
    exit 1
  fi
fi

if [[ -z "$TOKEN" ]]; then
  echo "Dans .env : soit DIRECTUS_TOKEN, soit DIRECTUS_EMAIL + DIRECTUS_PASSWORD."
  exit 1
fi

# UUID pour external_user_id (macOS a uuidgen)
if command -v uuidgen &>/dev/null; then
  EXT_UID=$(uuidgen | tr '[:upper:]' '[:lower:]')
else
  EXT_UID=$(od -x /dev/urandom | head -1 | awk '{OFS="-"; print $2$3,$4,$5,$6,$7$8$9}' | tr '[:upper:]' '[:lower:]')
fi

# Hash du mot de passe (Node + bcryptjs)
PWD_HASH=""
if command -v node &>/dev/null && [[ -f "$SCRIPT_DIR/hash-password.js" ]]; then
  PWD_HASH=$(cd "$PROJECT_ROOT" && node "$SCRIPT_DIR/hash-password.js" "$PWD_GEN" 2>/dev/null | tr -d '\n')
fi

if [[ -n "$PWD_HASH" ]]; then
  BODY=$(printf '{"origin":"direct","external_user_id":"%s","email":"%s","identifiant":"%s","password_hash":"%s"}' "$EXT_UID" "$EMAIL" "$IDENT" "$PWD_HASH")
else
  BODY=$(printf '{"origin":"direct","external_user_id":"%s","email":"%s","identifiant":"%s"}' "$EXT_UID" "$EMAIL" "$IDENT")
fi

CREATED=$(curl -s -X POST "$DIRECTUS_URL/items/apprenants" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "$BODY" 2>/dev/null || true)

if echo "$CREATED" | grep -q '"data"'; then
  : # ok
elif echo "$CREATED" | grep -q '"id"'; then
  : # ok
else
  echo "Erreur API Directus: $CREATED"
  exit 1
fi

LINK="${SITE_BASE_URL}/pages/apprenant/portal.html?token=${EXT_UID}"
LOGIN_URL="${SITE_BASE_URL}/pages/apprenant/login.html"

echo ""
echo "==========  A COPIER DANS LE MAIL DE BIENVENUE  =========="
echo ""
echo "  Lien d'accès (à ouvrir dans le navigateur) :"
echo "  $LINK"
echo ""
echo "  Identifiant (pour la page Connexion du site) : $IDENT"
if [[ -n "$PWD_HASH" ]]; then
  echo "  Mot de passe (pour la page Connexion du site)     : $PWD_GEN"
else
  echo "  Mot de passe : (non généré — exécutez 'npm install' à la racine du projet puis relancez le script)"
fi
echo ""
echo "  Page de connexion (identifiant + mot de passe) : $LOGIN_URL"
echo ""
echo "==========  CONSERVEZ CES INFORMATIONS  =========="
echo ""
echo "L'apprenant peut :"
echo "  - Ouvrir le lien directement pour accéder à son espace ;"
echo "  - Ou aller sur la page Connexion et saisir son identifiant et son mot de passe."
echo "Pour que la connexion (identifiant/mdp) et la progression en base fonctionnent, déployez l'API (dossier api/) et définissez PROGRESS_API_BASE sur le site (voir docs/PROGRESSION_ET_DIRECTUS.md)."
echo ""
echo "Rappel : le mot de passe ne peut pas être récupéré ; conservez-le si vous devez le communiquer à l'apprenant."
