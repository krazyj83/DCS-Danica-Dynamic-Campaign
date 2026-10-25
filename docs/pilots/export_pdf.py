# Pilotguide og briefing som PDF til deling (fx på Discord).
#   pilotguide.md          -> pilotguide.pdf (A4)
#   briefing/slides/*.html -> briefing/briefing.html -> briefing/briefing.pdf (én side pr. slide, 1920×1080)
# Kør:  pip install playwright markdown
#       python docs/pilots/export_pdf.py
# Bruger Playwrights Chromium, eller Google Chrome hvis den ikke er installeret.
import asyncio, os, runpy, tempfile
import markdown
from playwright.async_api import async_playwright

HERE = os.path.dirname(os.path.abspath(__file__))
BRIEF = os.path.join(HERE, "briefing")

GUIDE_CSS = """
@page { size: A4; margin: 18mm 16mm 20mm; }
* { box-sizing: border-box; }
body { font: 10.5pt/1.5 -apple-system, 'Segoe UI', Helvetica, Arial, sans-serif; color: #1b2530; }
h1 { font-size: 24pt; margin: 0 0 4pt; color: #141b22; }
h1 + p { color: #6b7480; margin-top: 0; }
h2 { font-size: 15pt; margin: 18pt 0 6pt; padding-bottom: 3pt; border-bottom: 2px solid #e8a33d; color: #141b22;
     break-after: avoid; }
h3 { font-size: 12pt; margin: 12pt 0 4pt; color: #94570a; break-after: avoid; }
p, li { orphans: 3; widows: 3; }
ul, ol { padding-left: 1.3em; }
table { border-collapse: collapse; width: 100%; margin: 6pt 0 10pt; font-size: 9pt; break-inside: auto; }
tr { break-inside: avoid; }
th { text-align: left; background: #f1ede2; border-bottom: 1.5px solid #c9c2ad; padding: 4pt 6pt; }
td { border-bottom: 1px solid #e2ddd0; padding: 4pt 6pt; vertical-align: top; }
code { font: 9pt 'SF Mono', Menlo, Consolas, monospace; background: #f1ede2; padding: 0 3pt; border-radius: 2pt; }
pre { background: #141b22; color: #eef0ea; padding: 8pt 10pt; border-radius: 4pt; break-inside: avoid; }
pre code { background: none; color: inherit; padding: 0; }
blockquote { margin: 8pt 0; padding: 6pt 10pt; border-left: 3px solid #e8a33d; background: #faf7ef; }
a { color: #94570a; }
"""

SLIDES_CSS = """
@page { size: 1920px 1080px; margin: 0; }
html, body { height: auto !important; overflow: visible !important; background: #0b0f13; }
#stage { position: static !important; transform: none !important; width: 1920px !important; height: auto !important; }
section { position: relative !important; inset: auto !important; break-after: page; }
#notes, #nr { display: none !important; }
"""


async def launch(p):
    try:
        return await p.chromium.launch()
    except Exception:  # Playwrights egen Chromium er ikke installeret: brug Google Chrome
        return await p.chromium.launch(channel="chrome")


async def main():
    src = open(os.path.join(HERE, "pilotguide.md"), encoding="utf-8").read()
    body = markdown.markdown(src, extensions=["tables", "fenced_code"])
    page_html = (f'<!doctype html><html lang="da"><head><meta charset="utf-8">'
                 f'<title>Danica Dynamic Campaign – Pilotguide</title><style>{GUIDE_CSS}</style></head>'
                 f'<body>{body}</body></html>')
    tmp = os.path.join(tempfile.mkdtemp(), "pilotguide.html")
    open(tmp, "w", encoding="utf-8").write(page_html)

    runpy.run_path(os.path.join(BRIEF, "build_briefing.py"))   # slides -> briefing.html

    async with async_playwright() as p:
        b = await launch(p)
        pg = await b.new_page()
        await pg.goto("file://" + tmp)
        out = os.path.join(HERE, "pilotguide.pdf")
        await pg.pdf(path=out, format="A4", print_background=True, display_header_footer=True,
                     header_template="<span></span>",
                     footer_template='<div style="font:8px Helvetica,Arial,sans-serif;color:#888;width:100%;text-align:center">'
                                     'Danica Dynamic Campaign – Pilotguide · <span class="pageNumber"></span>'
                                     ' / <span class="totalPages"></span></div>',
                     margin={"top": "18mm", "bottom": "20mm", "left": "16mm", "right": "16mm"})
        print("pilotguide ->", out)

        pg = await b.new_page(viewport={"width": 1920, "height": 1080})
        await pg.goto("file://" + os.path.join(BRIEF, "briefing.html"), wait_until="networkidle")
        await pg.evaluate("document.querySelectorAll('section').forEach(s => s.classList.add('on'))")
        await pg.add_style_tag(content=SLIDES_CSS)
        await pg.evaluate("document.fonts.ready")
        out = os.path.join(BRIEF, "briefing.pdf")
        await pg.pdf(path=out, width="1920px", height="1080px", print_background=True,
                     margin={"top": "0", "bottom": "0", "left": "0", "right": "0"})
        print("briefing ->", out)
        await b.close()

asyncio.run(main())
