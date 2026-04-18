#!/usr/bin/env python3
"""
Rendu SVG → PNG pour couvertures Pulse CX.

Usage :
    python3 newsletter/render.py newsletter/covers/ed01-verite-transfert.svg

Produit :
    <même dossier>/<nom>.png      (1200×630)
    <même dossier>/<nom>@2x.png   (2400×1260)

Dépendances : cairosvg, Pillow (pip install cairosvg Pillow).
Les fontes Google Fonts (Anton, Archivo, Playfair Display) doivent être
installées localement — sinon cairosvg tombe sur une fallback plus large.

    # Linux : déposer les .ttf dans /usr/local/share/fonts puis fc-cache -f
    # macOS : double-clic sur chaque .ttf, « Installer »
"""
from __future__ import annotations

import base64
import re
import sys
from pathlib import Path

import cairosvg


def inline_images(svg_text: str, svg_dir: Path) -> str:
    """Remplace chaque href relatif d'<image> par un data URL base64.
    Rend le SVG auto-portant avant rendu (cairosvg ignore certains file://)."""
    def repl(match: re.Match) -> str:
        href = match.group(1)
        if href.startswith(("data:", "http://", "https://")):
            return match.group(0)
        img_path = (svg_dir / href).resolve()
        mime = "image/png" if img_path.suffix.lower() == ".png" else "image/jpeg"
        b64 = base64.b64encode(img_path.read_bytes()).decode()
        return f'href="data:{mime};base64,{b64}"'

    return re.sub(r'href="([^"]+\.(?:png|jpe?g))"', repl, svg_text)


def render(svg_path: Path) -> None:
    svg_text = svg_path.read_text()
    inlined = inline_images(svg_text, svg_path.parent)
    out_base = svg_path.with_suffix("")
    cairosvg.svg2png(bytestring=inlined.encode(),
                     write_to=f"{out_base}.png",
                     output_width=1200, output_height=630)
    cairosvg.svg2png(bytestring=inlined.encode(),
                     write_to=f"{out_base}@2x.png",
                     output_width=2400, output_height=1260)
    print(f"{out_base}.png  (1200×630)")
    print(f"{out_base}@2x.png  (2400×1260)")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit("usage: render.py <path/to/cover.svg>")
    render(Path(sys.argv[1]))
