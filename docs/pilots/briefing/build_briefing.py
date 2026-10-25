# Samler slides/*.html (i rækkefølgen fra deck.json) til én briefing.html, der kan
# åbnes i en browser og præsenteres. Piletaster/mellemrum skifter slide, N viser noter.
# Kør:  python docs/pilots/briefing/build_briefing.py
import json, os, re, html

HERE = os.path.dirname(os.path.abspath(__file__))
deck = json.load(open(os.path.join(HERE, "deck.json"), encoding="utf-8"))
fonts = [f["href"] for f in deck.get("faces", {}).values() if "href" in f]


def connectors(sec):
    """<x-connector x1 y1 x2 y2 head=end style="color;border-width;border-style:dashed"> -> SVG-linjer."""
    lines = []
    for m in re.finditer(r"<x-connector([^>]*)>\s*</x-connector>", sec):
        a = dict(re.findall(r'(\w[\w-]*)="([^"]*)"', m.group(1)))
        st = a.get("style", "")
        col = (re.search(r"color:\s*([^;]+)", st) or [None, "#888"])[1]
        w = (re.search(r"border-width:\s*(\d+)", st) or [None, "2"])[1]
        dash = ' stroke-dasharray="10 8"' if "dashed" in st else ""
        mid = f"m{len(lines)}"
        lines.append(
            f'<defs><marker id="{mid}" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="5" markerHeight="5" '
            f'orient="auto"><path d="M0 0L10 5L0 10z" fill="{col}"/></marker></defs>'
            f'<line x1="{a["x1"]}" y1="{a["y1"]}" x2="{a["x2"]}" y2="{a["y2"]}" stroke="{col}" '
            f'stroke-width="{w}"{dash} marker-end="url(#{mid})"/>')
    sec = re.sub(r"<x-connector[^>]*>\s*</x-connector>", "", sec)
    if lines:
        svg = ('<svg style="position:absolute;left:0;top:0;width:1920px;height:1080px;pointer-events:none" '
               'viewBox="0 0 1920 1080">' + "".join(lines) + "</svg>")
        sec = sec.replace("</section>", svg + "</section>")
    return sec


slides, notes = [], []
for sid in deck["order"]:
    sec = open(os.path.join(HERE, "slides", sid + ".html"), encoding="utf-8").read()
    n = re.search(r"<aside>(.*?)</aside>", sec, re.S)
    notes.append(n.group(1).strip() if n else "")
    sec = re.sub(r"<aside>.*?</aside>", "", sec, flags=re.S)
    slides.append(connectors(sec))

links = "".join(f'<link rel="stylesheet" href="{h}">' for h in fonts)
page = f"""<!doctype html><html lang="da"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>{html.escape(deck["title"])}</title>{links}
<style>
*{{box-sizing:border-box;margin:0;padding:0}}
html,body{{height:100%;background:#0b0f13;overflow:hidden}}
#stage{{position:absolute;left:50%;top:50%;width:1920px;height:1080px;transform-origin:0 0}}
section{{position:absolute;inset:0;width:1920px;height:1080px;overflow:hidden}}
section:not(.on){{display:none !important}}

ul,ol{{padding-left:1.2em}} th,td{{padding:.35em .6em;border-bottom:1px solid rgba(127,127,127,.35);text-align:left}}
table{{border-collapse:collapse}}
#notes{{position:fixed;left:0;right:0;bottom:0;max-height:30%;overflow:auto;background:#111a;color:#eee;
 font:16px/1.4 system-ui;padding:12px 20px;display:none;backdrop-filter:blur(6px)}}
#nr{{position:fixed;right:12px;bottom:8px;color:#888;font:13px system-ui}}
</style></head><body><div id="stage">{''.join(slides)}</div>
<div id="notes"></div><div id="nr"></div>
<script>
const S=[...document.querySelectorAll('section')],N={json.dumps(notes, ensure_ascii=False)};
let i=Math.max(0,Math.min(S.length-1,(parseInt(location.hash.slice(1))||1)-1));
const st=document.getElementById('stage'),nt=document.getElementById('notes'),nr=document.getElementById('nr');
function fit(){{const k=Math.min(innerWidth/1920,innerHeight/1080);st.style.transform=`scale(${{k}}) translate(-50%,-50%)`;}}
function show(){{S.forEach((s,j)=>s.classList.toggle('on',j===i));nt.textContent=N[i];nr.textContent=(i+1)+' / '+S.length;location.hash=i+1;}}
addEventListener('resize',fit);
addEventListener('keydown',e=>{{if(['ArrowRight','ArrowDown',' ','PageDown'].includes(e.key))i=Math.min(S.length-1,i+1);
 else if(['ArrowLeft','ArrowUp','PageUp'].includes(e.key))i=Math.max(0,i-1);
 else if(e.key==='n'||e.key==='N')nt.style.display=nt.style.display==='block'?'none':'block';else return;show();}});
addEventListener('click',e=>{{i=e.clientX>innerWidth/2?Math.min(S.length-1,i+1):Math.max(0,i-1);show();}});
fit();show();
</script></body></html>"""
out = os.path.join(HERE, "briefing.html")
open(out, "w", encoding="utf-8").write(page)
print(f"{len(slides)} slides -> {out}")
