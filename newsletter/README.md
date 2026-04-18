# Pulse CX — Couvertures newsletter

Couvertures d'édition de la newsletter **Pulse CX** dans la grammaire des éditions
**Clés des Champs** (Gladwell, Pink) : fond jaune canari, titre blanc condensé en
caps, sous-titre serif italique, photo détourée comme métaphore centrale, logo
Pulse CX en signature.

## Structure

```
newsletter/
├── README.md                      ← ce fichier
├── cover-template.svg             ← template réutilisable (1200×630)
├── assets/
│   ├── pulse-cx-logo.svg          ← logo vectorisé (réutilisable)
│   └── photo-edNN-*.png           ← photos détourées fournies par édition
└── covers/
    └── edNN-slug.svg              ← une couverture par édition
```

## Ajouter une édition

1. `cp cover-template.svg covers/ed02-slug.svg`
2. Ouvrir le fichier, remplacer :
   - `{{EDITION_META}}` → `PULSE CX · ÉDITION 02 · MAI 2026`
   - `{{TITRE_L1..L4}}` → lignes du titre (caps, supprimer les `<text>` L3/L4 si inutiles)
   - `{{SOUS_TITRE}}` → sous-titre une ligne
   - `{{PHOTO_HREF}}` → chemin vers la photo (voir ci-dessous)
3. Commit le SVG dans `covers/`.

## Fournir la photo détourée

Deux options :

**A — Fichier PNG dans `assets/` (recommandé)**
```
assets/photo-ed02-slug.png   (PNG transparent, ~880×940 pour rendu @2x)
```
Dans le SVG, remplacer `{{PHOTO_HREF}}` par `../assets/photo-ed02-slug.png`.

**B — Base64 inline (SVG autonome)**
```bash
base64 -w0 photo.png > photo.b64
# Coller le contenu : href="data:image/png;base64,iVBORw0KGg..."
```
Utile si vous voulez un fichier SVG qui se suffit à lui-même.

## Exporter en PNG 1200×630

**Chrome (le plus fidèle, polices Google Fonts OK)**
1. Ouvrir le SVG dans Chrome.
2. `Cmd+Shift+P` (macOS) / `Ctrl+Shift+P` (Linux) dans DevTools → `Capture full-size screenshot`.

**Inkscape CLI (export @2x)**
```bash
inkscape covers/ed01-verite-transfert.svg \
  --export-type=png \
  --export-width=2400 \
  --export-filename=covers/ed01-verite-transfert.png
```
Note : les polices Google Fonts (Anton, Playfair Display, Montserrat) doivent être
installées localement, sinon Inkscape tombe sur les fallbacks.

**rsvg-convert**
```bash
rsvg-convert -w 2400 covers/ed01-verite-transfert.svg -o ed01.png
```

## Charte figée

- **Fond** : `#FADA00` (jaune canari Gladwell — à calibrer pixel sur la couverture
  de référence avant de figer en production).
- **Titre** : Anton (Google Fonts), blanc `#FFFFFF`, caps, 96px, letter-spacing -1.
- **Sous-titre & meta** : Playfair Display italic, noir `#0F0E0C`.
- **Logo** : Pulse CX en noir `#0F0E0C`, centré bas, ~200px de large.

Ne pas dévier de cette grammaire : seuls le visuel central, le meta et les textes
changent d'une édition à l'autre.

## Édition 01

`covers/ed01-verite-transfert.svg` — PI-SPI, transfert Banque → Mobile Money
échoué, silence client UEMOA. Visuel : billet 10 000 FCFA en chute libre, à
moitié déchiré. **Photo détourée à fournir** dans `assets/photo-ed01-billet.png`.
