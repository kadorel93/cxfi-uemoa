#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════
#  CXFI WATCHDOG — Script de surveillance autonome
#  Vérifie : site, API Supabase, intégrité des données
#  Usage : ./cxfi-watchdog.sh [--silent]
# ══════════════════════════════════════════════════════════════
set -euo pipefail

SITE_URL="https://cxfi-uemoa.netlify.app"
SB_URL="https://yyrjbrwrywbcusiivsgy.supabase.co"
SB_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl5cmpicndyeXdiY3VzaWl2c2d5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM1MTYzNDQsImV4cCI6MjA4OTA5MjM0NH0.PYK_Fiby1t4YIR36HGylDnBKHbu5iGfooF-WHIAlUmQ"
LOG_DIR="$(dirname "$0")/logs"
TIMESTAMP=$(date +"%Y-%m-%dT%H:%M:%S")
SILENT=${1:-""}

mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/watchdog-$(date +%Y-%m-%d).log"
REPORT_FILE="$LOG_DIR/latest-report.txt"

# ── Couleurs pour output terminal ──
RED='\033[0;31m'; ORANGE='\033[0;33m'; GREEN='\033[0;32m'; NC='\033[0m'; BOLD='\033[1m'

ERRORS=()
WARNINGS=()
OK_LIST=()

log() { echo "[$TIMESTAMP] $1" >> "$LOG_FILE"; [[ "$SILENT" != "--silent" ]] && echo "$1"; }
ok()  { OK_LIST+=("$1"); log "✅ $1"; }
warn(){ WARNINGS+=("$1"); log "⚠️  $1"; }
err() { ERRORS+=("$1"); log "🔴 $1"; }

echo "" >> "$LOG_FILE"
log "════════ CXFI WATCHDOG — $TIMESTAMP ════════"

# ──────────────────────────────────────────────
# CHECK 1 : Accessibilité du site
# ──────────────────────────────────────────────
log "→ [1/5] Accessibilité site..."
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$SITE_URL" || echo "000")
RESP_TIME=$(curl -s -o /dev/null -w "%{time_total}" --max-time 10 "$SITE_URL" || echo "99")

if [[ "$HTTP_STATUS" == "200" ]]; then
  ok "Site accessible — HTTP $HTTP_STATUS — ${RESP_TIME}s"
  # Alerte si temps de réponse > 3s
  if (( $(echo "$RESP_TIME > 3.0" | bc -l) )); then
    warn "Temps de réponse lent : ${RESP_TIME}s (seuil : 3s)"
  fi
elif [[ "$HTTP_STATUS" == "000" ]]; then
  err "Site INACCESSIBLE — timeout ou DNS failure"
else
  err "Site répond HTTP $HTTP_STATUS (attendu : 200)"
fi

# ──────────────────────────────────────────────
# CHECK 2 : Contenu HTML critique
# ──────────────────────────────────────────────
log "→ [2/5] Intégrité contenu HTML..."
# Utiliser un fichier temporaire pour éviter les problèmes de gzip/truncation dans les variables bash
HTML_TMP=$(mktemp /tmp/cxfi_html_XXXXXX)
curl -s --compressed --max-time 15 "$SITE_URL" > "$HTML_TMP" 2>/dev/null || true

if grep -q 'id="sec-home"' "$HTML_TMP"; then
  ok "Section #sec-home présente"
else
  err "Section #sec-home MANQUANTE dans le HTML livré"
fi

if grep -qE 'JULAYA|Wave Mobile|Ecobank' "$HTML_TMP"; then
  ok "Institutions INSTS présentes dans le HTML"
else
  err "Données institutions ABSENTES — JavaScript non chargé ou build cassé"
fi

if grep -qE 'supabaseUrl|supabase\.co' "$HTML_TMP"; then
  ok "Configuration Supabase présente"
else
  warn "Configuration Supabase non détectée dans le HTML"
fi

# Vérifier qu'il n'y a pas de double id (régression bug fix #1)
DOUBLE_ID=0
grep -q 'id="main-content"' "$HTML_TMP" && DOUBLE_ID=1 || true
if [[ "$DOUBLE_ID" -gt 0 ]]; then
  err "RÉGRESSION : double id='main-content' redétecté (Bug #1 revenu)"
else
  ok "Pas de double id — Bug #1 stable"
fi

# Vérifier que tryGoStep2 est présent (régression validations form)
if grep -q 'tryGoStep2' "$HTML_TMP"; then
  ok "Validation formulaire v8.1 présente (tryGoStep2)"
else
  warn "tryGoStep2 absent — validation étape 1 peut être manquante"
fi

rm -f "$HTML_TMP"

# ──────────────────────────────────────────────
# CHECK 3 : API Supabase — table avis
# ──────────────────────────────────────────────
log "→ [3/5] Disponibilité API Supabase (table avis)..."
SB_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 \
  -H "apikey: $SB_KEY" \
  -H "Authorization: Bearer $SB_KEY" \
  -H "Prefer: count=exact" \
  -H "Range: 0-0" \
  "$SB_URL/rest/v1/avis?select=id" || echo "000")

if [[ "$SB_RESPONSE" == "200" ]] || [[ "$SB_RESPONSE" == "206" ]]; then
  ok "API Supabase opérationnelle — table avis répond HTTP $SB_RESPONSE"
elif [[ "$SB_RESPONSE" == "000" ]]; then
  err "API Supabase INACCESSIBLE — timeout"
else
  err "API Supabase — HTTP $SB_RESPONSE inattendu sur table avis"
fi

# ──────────────────────────────────────────────
# CHECK 4 : API Supabase — table feedback
# ──────────────────────────────────────────────
log "→ [4/5] Disponibilité API Supabase (table feedback)..."
SB_FB=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 \
  -H "apikey: $SB_KEY" \
  -H "Authorization: Bearer $SB_KEY" \
  -H "Prefer: count=exact" \
  -H "Range: 0-0" \
  "$SB_URL/rest/v1/feedback?select=id" || echo "000")

if [[ "$SB_FB" == "200" ]] || [[ "$SB_FB" == "206" ]]; then
  ok "API Supabase opérationnelle — table feedback répond HTTP $SB_FB"
else
  err "API Supabase — HTTP $SB_FB sur table feedback"
fi

# ──────────────────────────────────────────────
# CHECK 5 : Comptage des avis (détection anomalies)
# ──────────────────────────────────────────────
log "→ [5/5] Intégrité des données — comptage avis..."
COUNT_HEADER=$(curl -s -I --max-time 10 \
  -H "apikey: $SB_KEY" \
  -H "Authorization: Bearer $SB_KEY" \
  -H "Prefer: count=exact" \
  -H "Range: 0-0" \
  "$SB_URL/rest/v1/avis?select=id" 2>/dev/null | grep -i "content-range" || echo "")

if [[ -n "$COUNT_HEADER" ]]; then
  TOTAL=$(echo "$COUNT_HEADER" | grep -oP '/\K[0-9]+' || echo "?")
  ok "Total avis en base : $TOTAL"

  # Enregistrer pour comparaison future
  PREV_COUNT_FILE="$LOG_DIR/.prev_count"
  if [[ -f "$PREV_COUNT_FILE" ]]; then
    PREV=$(cat "$PREV_COUNT_FILE")
    if [[ "$TOTAL" =~ ^[0-9]+$ ]] && [[ "$PREV" =~ ^[0-9]+$ ]]; then
      DIFF=$(( TOTAL - PREV ))
      if [[ $DIFF -gt 50 ]]; then
        warn "Spike détecté : +$DIFF avis depuis le dernier check (possible abus ?)"
      elif [[ $DIFF -lt 0 ]]; then
        err "ANOMALIE : nombre d'avis a DIMINUÉ (était $PREV, maintenant $TOTAL) — possible suppression"
      fi
    fi
  fi
  if [[ "$TOTAL" =~ ^[0-9]+$ ]]; then
    echo "$TOTAL" > "$PREV_COUNT_FILE"
  fi
else
  warn "Impossible de récupérer le count — vérifier les permissions RLS Supabase"
fi

# ──────────────────────────────────────────────
# SYNTHÈSE & RAPPORT
# ──────────────────────────────────────────────
NB_ERR=${#ERRORS[@]}
NB_WARN=${#WARNINGS[@]}
NB_OK=${#OK_LIST[@]}

if [[ $NB_ERR -gt 0 ]]; then
  LEVEL="🔴 CRITIQUE"
  LEVEL_CODE="CRITICAL"
elif [[ $NB_WARN -gt 0 ]]; then
  LEVEL="🟠 MAJEUR"
  LEVEL_CODE="WARNING"
else
  LEVEL="🟢 OK"
  LEVEL_CODE="OK"
fi

REPORT="
══════════════════════════════════════════════
CXFI WATCHDOG REPORT — $TIMESTAMP
Status : $LEVEL
✅ OK      : $NB_OK checks
⚠️  Warnings: $NB_WARN
🔴 Errors  : $NB_ERR
──────────────────────────────────────────────"

if [[ ${#ERRORS[@]} -gt 0 ]]; then
  REPORT+=$'\nERREURS CRITIQUES :'
  for e in "${ERRORS[@]}"; do REPORT+=$'\n  • '"$e"; done
fi
if [[ ${#WARNINGS[@]} -gt 0 ]]; then
  REPORT+=$'\nAVERTISSEMENTS :'
  for w in "${WARNINGS[@]}"; do REPORT+=$'\n  • '"$w"; done
fi
REPORT+=$'\n══════════════════════════════════════════════'

echo "$REPORT" >> "$LOG_FILE"
echo "$REPORT" > "$REPORT_FILE"

if [[ "$SILENT" != "--silent" ]]; then
  echo "$REPORT"
fi

# Exit code selon le niveau
[[ "$LEVEL_CODE" == "CRITICAL" ]] && exit 2
[[ "$LEVEL_CODE" == "WARNING"  ]] && exit 1
exit 0
