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

**Script render.py (recommandé)**
```bash
pip install cairosvg Pillow
python3 newsletter/render.py newsletter/covers/ed01-verite-transfert.svg
# → produit ed01-verite-transfert.png (1200×630) + @2x.png (2400×1260)
```
Les fontes Google Fonts (Anton, Archivo, Playfair Display) doivent être
installées localement. Sous Linux : télécharger les `.ttf` depuis Google Fonts,
les copier dans `/usr/local/share/fonts/`, puis `fc-cache -f`.

**Chrome (fallback sans installation de fontes locales)**
1. Ouvrir le SVG dans Chrome (les `@import` Google Fonts se chargent automatiquement).
2. DevTools → `Cmd/Ctrl+Shift+P` → `Capture full-size screenshot`.

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
échoué, silence client UEMOA. Visuel : billet 10 000 FCFA en chute libre,
moitié droite arrachée par un clipPath à bord déchiqueté. Photo source :
`assets/photo-ed01-billet.png`. PNGs exportés : `covers/ed01-verite-transfert.png`
(@1x) et `covers/ed01-verite-transfert@2x.png` (@2x).
