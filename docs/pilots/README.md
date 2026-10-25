# Pilotmateriale (dansk)

Introduktion til Danica Dynamic Campaign for piloter: hvordan man vinder, hvordan økonomien (SU) virker,
og hvordan ens sorties flytter fronten. Opdateret til v0.35 af kampagnen.

**Til Discord:** `pilotguide.pdf`, `briefing/briefing.pdf`, `kneeboards/DCC_kneeboards.pdf` og
`kneeboards/png/*.png` (læg PNG'erne i `Saved Games\DCS\Kneeboard\` for at have dem i alle fly).

| Mappe / fil | Hvad | Sådan redigeres den |
| --- | --- | --- |
| `pilotguide.md` | Den fulde pilotguide – til dem, der vil dykke ned i "spillet" | Ret Markdown direkte |
| `briefing/slides/*.html` | Pilotbriefingen, én fil pr. slide (1920×1080, inline styles, talernoter i `<aside>`) | Ret HTML'en; rækkefølge og titel står i `briefing/deck.json` |
| `briefing/build_briefing.py` | Samler slides til `briefing/briefing.html`, der kan præsenteres i en browser | `python3 docs/pilots/briefing/build_briefing.py` |
| `kneeboards/make_kneeboards.py` | Kneeboard-kortene – al tekst står i `CARDS` i scriptet | Ret teksten, kør scriptet igen |
| `kneeboards/png/` | Kortene som PNG (1200×1600) til DCS' kneeboard-mappe | Genereres af scriptet |
| `kneeboards/DCC_kneeboards.pdf` | Alle kort samlet | Genereres af scriptet |
| `export_pdf.py` | Laver `pilotguide.pdf` og `briefing/briefing.pdf` til deling | `python docs/pilots/export_pdf.py` |

## Byg

Brug repoets `.venv` (se CLAUDE.md). Scripts bruger Google Chrome, hvis Playwrights egen Chromium ikke er installeret.

```bash
pip install playwright pillow markdown              # én gang

python docs/pilots/briefing/build_briefing.py       # -> briefing/briefing.html (piletaster, N = noter)
python docs/pilots/kneeboards/make_kneeboards.py    # -> kneeboards/png/*.png + DCC_kneeboards.pdf
python docs/pilots/export_pdf.py                    # -> pilotguide.pdf + briefing/briefing.pdf
```

## Når kampagnen ændrer sig

Tallene i materialet (SU, våbentrin, afstande, tider) kommer fra `README.md` og `src/dcc_config.lua`.
Ændres de i koden, så opdatér pilotguiden, de berørte slides og `CARDS` i kneeboard-scriptet, og byg igen.
Rang-systemet er stadig nævnt i pilotguiden, mens det afklares, om det skal blive.
