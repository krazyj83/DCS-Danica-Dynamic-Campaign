# Pilotmateriale (dansk)

Introduktion til Danica Dynamic Campaign for piloter: hvordan man vinder, hvordan økonomien (SU) virker,
og hvordan ens sorties flytter fronten. Skrevet til v0.33 af kampagnen.

| Mappe / fil | Hvad | Sådan redigeres den |
| --- | --- | --- |
| `pilotguide.md` | Den fulde pilotguide – til dem, der vil dykke ned i "spillet" | Ret Markdown direkte |
| `briefing/slides/*.html` | Pilotbriefingen, én fil pr. slide (1920×1080, inline styles, talernoter i `<aside>`) | Ret HTML'en; rækkefølge og titel står i `briefing/deck.json` |
| `briefing/build_briefing.py` | Samler slides til `briefing/briefing.html`, der kan præsenteres i en browser | `python3 docs/pilots/briefing/build_briefing.py` |
| `kneeboards/make_kneeboards.py` | Kneeboard-kortene – al tekst står i `CARDS` i scriptet | Ret teksten, kør scriptet igen |
| `kneeboards/png/` | Kortene som PNG (1200×1600) til DCS' kneeboard-mappe | Genereres af scriptet |
| `kneeboards/DCC_kneeboards.pdf` | Alle kort samlet | Genereres af scriptet |

## Byg

```bash
python3 docs/pilots/briefing/build_briefing.py      # -> briefing/briefing.html (piletaster, N = noter)

pip install playwright pillow && python3 -m playwright install chromium   # én gang
python3 docs/pilots/kneeboards/make_kneeboards.py   # -> kneeboards/png/*.png + DCC_kneeboards.pdf
```

## Når kampagnen ændrer sig

Tallene i materialet (SU, våbentrin, afstande, tider) kommer fra `README.md` og `src/dcc_config.lua`.
Ændres de i koden, så opdatér pilotguiden, de berørte slides og `CARDS` i kneeboard-scriptet, og byg igen.
Rang-systemet er stadig nævnt i pilotguiden, mens det afklares, om det skal blive.
