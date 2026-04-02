# CXFI — Protocole de Surveillance Active

## Architecture de monitoring

```
TÂCHE PLANIFIÉE (toutes les heures)
        │
        ▼
cxfi-watchdog.sh ─── 5 checks ──► logs/watchdog-YYYY-MM-DD.log
        │                               logs/latest-report.txt
        │                               logs/.prev_count
        ▼
  Niveau détecté
   ┌────┼────┐
🔴 │   🟠   │ 🟢
   ▼         ▼
Hotfix    Rapport
immédiat   seul
```

## Checks automatiques

| # | Check | Méthode | Seuil critique |
|---|-------|---------|----------------|
| 1 | Accessibilité site | HTTP GET cxfi-uemoa.netlify.app | HTTP ≠ 200 |
| 2 | Temps de réponse | curl time_total | > 3s = ⚠️ |
| 3 | Intégrité HTML | grep sur contenu livré | sec-home absent = 🔴 |
| 4 | Données institutions | grep JULAYA/Wave/Ecobank | absent = 🔴 |
| 5 | Config Supabase | grep supabase.co | absent = ⚠️ |
| 6 | Régression bug #1 | grep id="main-content" | présent = 🔴 |
| 7 | Validation form v8.1 | grep tryGoStep2 | absent = ⚠️ |
| 8 | API avis | GET /rest/v1/avis | HTTP ≠ 200/206 = 🔴 |
| 9 | API feedback | GET /rest/v1/feedback | HTTP ≠ 200/206 = 🟠 |
| 10 | Intégrité comptage | content-range delta | diminution = 🔴, +50 = ⚠️ |

## Niveaux de réponse

| Niveau | Situation | Action |
|--------|-----------|--------|
| 🔴 Critique | Site down, API down, régression | Hotfix immédiat + rapport |
| 🟠 Majeur | API partielle, lenteur | Correction dans l'heure + rapport |
| 🟡 Mineur | Anomalie visuelle | Planifié + changelog |
| 🟢 OK | Tout nominal | Rapport silencieux |

## Zones protégées (jamais sans validation Adonis)

- Schéma Supabase (tables, colonnes, RLS)
- Logique de scoring : Score = FCR×0.40 + CES×0.35 + CSAT×0.25
- Anti-fraude : seuils, clés localStorage
- INSTS[] : 116 entrées institutionnelles sur 8 pays
- Seuil de publication : 30 avis minimum par institution/pays

## Format rapport post-fix

```
[CXFI HOTFIX — DATE]
Problème détecté : ...
Impact utilisateur : ...
Correction appliquée : ...
Testé sur : mobile / desktop / API
Statut : ✅ Résolu
```

## Logs

- **Logs journaliers** : `logs/watchdog-YYYY-MM-DD.log`
- **Dernier rapport** : `logs/latest-report.txt`
- **Compteur avis** : `logs/.prev_count` (détection spikes/suppressions)

## Changelog versions

| Version | Date | Description |
|---------|------|-------------|
| v8.0 | avant 30/03/2026 | Version initiale |
| v8.1 | 30/03/2026 | Fix 7 bugs + validations 0 friction + anti-abus localStorage |

### v8.1 — Détail des corrections (30/03/2026)
1. **Bug HTML** : double `id="main-content"` sur `#sec-home` → skip link inaccessible. Fix : `href="#sec-home"`
2. **Bug CSS** : règle orpheline `.inst-item.active` sans accolades → CSS invalide. Fix : `.inst-item.active .inst-meta { color: rgba(247,244,238,0.6) }`
3. **Bug Admin** : `CFG.sheetUrl` undefined → `window.open(undefined)`. Fix : `CFG.adminUrl` + garde `if (!pw) return`
4. **Bug Admin** : `CFG.adminCode = ''` → accès admin sans code. Fix : code défini
5. **Bug UX** : `alert()` natifs dans `sendForm()` → bloquants. Fix : messages inline `#s5Err`
6. **Bug loadStats** : pas de pagination Supabase (>1000 avis tronqués). Fix : `count=exact` + `limit=10000`
7. **Amélioration** : Validation étape 1 inline `tryGoStep2()` — profil + pays requis
8. **Amélioration** : Validation étape 2 inline `tryGoStep3()` — institution + canal requis
9. **Amélioration** : Validation étape 3 inline `tryGoStep4()` — opération + FCR requis
10. **Anti-fraude** : localStorage 90 jours par institution/pays/appareil avec message contextuel
