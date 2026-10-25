# Danica DCC kneeboard-kort (dansk) -> png/*.png + DCC_kneeboards.pdf
# Kør:  pip install playwright pillow && python -m playwright install chromium
#       python docs/pilots/kneeboards/make_kneeboards.py
# Indholdet står i CARDS nedenfor; ret teksten der og kør scriptet igen.
import asyncio, os, glob, tempfile
from playwright.async_api import async_playwright

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "png")
os.makedirs(OUT, exist_ok=True)
TMP = tempfile.mkdtemp()
W, H = 1200, 1600

CSS = """
*{box-sizing:border-box;margin:0;padding:0;text-wrap:pretty}
body{width:%dpx;height:%dpx;background:#efe6cf;font-family:Inter,-apple-system,'Segoe UI',Helvetica,Arial,sans-serif;color:#1f1d18}
.card{position:relative;width:100%%;height:100%%;padding:56px 64px 48px;display:flex;flex-direction:column;
 background:radial-gradient(ellipse at 30%% 20%%,#f6efdc 0%%,#ece2c8 70%%,#e3d7b9 100%%)}
.card:before{content:"";position:absolute;inset:22px;border:3px solid #3b362b;border-radius:6px;pointer-events:none}
.hdr{display:flex;justify-content:space-between;align-items:flex-end;border-bottom:4px solid #3b362b;padding-bottom:14px;margin-bottom:26px}
.hdr h1{font-family:'Inter Display',Inter,-apple-system,'Segoe UI',Helvetica,Arial,sans-serif;font-weight:800;font-size:58px;letter-spacing:1px;text-transform:uppercase;line-height:1}
.hdr .tag{font-size:22px;font-weight:600;letter-spacing:3px;color:#6b5f45;text-align:right;line-height:1.3}
.main{flex:1;display:flex;flex-direction:column;gap:20px}
h2{font-family:'Inter Display',Inter,-apple-system,'Segoe UI',Helvetica,Arial,sans-serif;font-weight:700;font-size:30px;text-transform:uppercase;letter-spacing:2px;color:#7a4a0c;margin-top:6px}
table{width:100%%;border-collapse:collapse;font-size:27px}
td{padding:9px 10px;border-bottom:1.5px solid #bfb08a;vertical-align:top;line-height:1.28}
td.k{font-weight:700;white-space:nowrap;width:1%%;padding-right:22px}
td.v{font-weight:700;white-space:nowrap;text-align:right}
.big{font-family:'Inter Display',Inter,-apple-system,'Segoe UI',Helvetica,Arial,sans-serif;font-weight:800;font-size:44px;line-height:1.05}
.sub{font-size:24px;color:#4f4636;line-height:1.3}
.grid{display:grid;grid-template-columns:1fr 1fr;gap:16px}
.box{border:2px solid #3b362b;border-radius:6px;padding:16px 18px;background:rgba(255,255,255,.25)}
.path{font-family:'DejaVu Sans Mono',monospace;font-size:25px;font-weight:700}
.strip{background:#2b2a26;color:#f1ead6;border-radius:6px;padding:20px 26px;margin-top:22px}
.strip h3{font-size:22px;letter-spacing:3px;color:#e8a33d;margin-bottom:8px;text-transform:uppercase}
.strip li{font-size:25px;line-height:1.38;margin-left:26px}
.tips{margin-top:16px;font-size:21px;color:#5d5340;line-height:1.35}
.tips em{font-style:italic}
""" % (W, H)

def card(n, total, title, main, strip, tips):
    lis = "".join(f"<li>{s}</li>" for s in strip)
    return f"""<!doctype html><html><head><meta charset=utf-8><style>{CSS}</style></head><body>
<div class=card><div class=hdr><h1>{title}</h1><div class=tag>DANICA DCC<br>{n}/{total}</div></div>
<div class=main>{main}</div>
<div class=strip><h3>Husk</h3><ul>{lis}</ul></div>
<div class=tips>{tips}</div></div></body></html>"""

def rows(pairs, cls="k"):
    return "<table>" + "".join(
        f"<tr><td class={cls}>{a}</td><td>{b}</td></tr>" for a, b in pairs) + "</table>"

def rows3(trip):
    return "<table>" + "".join(
        f"<tr><td class=k>{a}</td><td>{b}</td><td class=v>{c}</td></tr>" for a, b, c in trip) + "</table>"

CARDS = []

CARDS.append(("Oversigt", f"""
<h2>F10 → Other</h2>
{rows([
 ("Campaign status", "Baser, main effort, SU, konvojer, seneste erobringer"),
 ("Missions → Mission board", "Missioner dit fly kan flyve, pr. type"),
 ("Missions → Join a flight", "Hop med på en mission, andre flyver nu"),
 ("Missions → My mission", "Briefing igen · Abandon mission"),
 ("Missions → Pilot records", "Journal · Leaderboard · Squadron"),
 ("Missions → JTAC", "Report target · Smoke · Next target"),
 ("Support", "Bogey dope · Armoury · lysgranater · artilleri · CAS-par"),
 ("CTLD", "Kasser · tropper · FOB · AA (heli)"),
])}
<h2>Første sortie</h2>
{rows([
 ("1", "Spawn på en base din side ejer"),
 ("2", "Campaign status: main effort, SU, krigsur, seneste erobringer"),
 ("3", "Tag en mission → briefing + kortmærke »TYPE: …« (kun din gruppe)"),
 ("4", "Løs opgaven – hop gerne med via Join a flight"),
 ("5", "LAND på venlig base, FARP eller carrier → point + debrief"),
])}
""", [
 "Point tæller først ved landing – dør du på vej hjem, er de tabt",
 "Skaden på fjenden tæller altid i krigen",
 "Tomt board? BAI og SEAD kræver friske efterretninger",
], "<em>Krigen kører 24/7 og gemmes hvert 5. min. Fire kort i rotation: Caucasus → Syria → Persian Gulf → Cold War Germany.</em>"))

CARDS.append(("Missioner: A2G", f"""
{rows([
 ("CAS", "Angrebet slås tilbage (forsvar) eller basen erobres (angreb). JTAC laser 1688"),
 ("BAI", "Konvoj/kolonne ødelagt → last og enheder når aldrig frem"),
 ("STRIKE", "Brændstof-, ammo- eller lagerbygning → −25 SU, lavere output"),
 ("SEAD/DEAD", "Radar dræbt: offline ~2 t · hele stillingen: genopbygges ~6 t"),
 ("RUNWAY", "3 bomber ≤60 m af centerlinjen → base lukket 4 t"),
 ("INDUSTRY", "2 af 3 bygninger → produktion −12 % i et døgn"),
 ("ARTY", "Artilleribatteri → fjenden mister ildstøtte (6 t)"),
 ("FORT", "Bunkere før et angreb → −10 % forsvar pr. niveau"),
 ("BRIDGE", "Bro på forsyningsvej → vejen lukket 6 t"),
 ("COIN", "Partisancelle (Syria, Golfen) → stopper sabotage"),
 ("EWR", "Fjendtlig radar → halvblind luftbillede, 6 t"),
])}
""", [
 "BAI kun på kolonner set inden for 30 min",
 "SEAD kun på SAM-stillinger din side kender",
 "Slå EWR ud før SAM: uden radar tænder SAM først på 25 km",
], "<em>Kolonner tegnes der, hvor de blev set – ikke der, hvor de er nu. JTAC: tag CAS først, så kører et team frem 4 km fra slaget.</em>"))

CARDS.append(("Missioner: A2A & øvrige", f"""
{rows([
 ("CAP", "20 min på station eller et luftkill → fjendens AI-angrebsfly holdes væk 1 t. Altid på boardet"),
 ("INTERCEPT", "Strike-pakke, helikopterangreb eller forsyningsfly → udebliver"),
 ("HVAA", "Fjendens AWACS → halvblind til en ny er købt (6 t)"),
 ("TANKER", "Fjendens tankfly skudt ned"),
 ("ESCORT", "Egne transportfly/helikoptere lander med dig ≤15 km"),
 ("RECON", "Overflyv ≤8 km, under 4500 m → garnison, SU og SAM synlige 6 t"),
 ("CSAR", "Land ≤150 m (grøn røg), så venlig base → pilot reddet, fly refunderet"),
 ("SNATCH", "Hent fjendtlig pilot → hans hjemmebase afsløret, +15 point"),
 ("LOGISTICS", "Kasse til base med lav SU → +10 SU"),
 ("CONVOY", "Eskorter konvoj (heli) ≤3 km → aldrig baghold"),
 ("FARP", "FARP-kit eller 3 kasser til venlig by → helikopter-spawn"),
 ("MEDEVAC · POW", "Sårede/fanger hjem → garnison +10 % / intel om 2 baser"),
 ("MINELAYER", "Fjendtlig minelægger mod egen havn → sænk den = ingen miner"),
 ("MINESWEEP", "Heli <150 m ≤3 km af mineret havn, 5 min → minerne væk"),
])}
""", [
 "Strike-pakker kommer ca. hvert 45. min – 2 strikers, 2 escorts, evt. 2 SEAD",
 "Helikopterangreb ca. hvert 75. min mod svage baser",
 "CSAR: efter 2 timer er piloten taget til fange",
], "<em>INTERCEPT dukker kun op, når din side har set målet: radar, AWACS eller øjne.</em>"))

CARDS.append(("Fog of war & trusler", f"""
<h2>Kilder til efterretning</h2>
{rows([
 ("Radar", "Egne EWR (180 km) og AWACS (350 km) – kun over radarhorisonten"),
 ("Øjne", "≤6 km til jordenheder, ≤10 km til fly, fri sigtelinje"),
 ("Radarlytning", "Automatisk: over 800 m, ≤110 km fra en tændt SAM-radar · fejlcirkel ±6 km → 300 m"),
 ("RECON", "Hele basen: garnison, SAM, kolonner · gyldig 6 t"),
])}
<h2>Nøgletal</h2>
{rows3([
 ("Kontakt frisk", "kan tildeles som mission", "30 min"),
 ("Kontakt glemt", "falmet → væk", "3 t"),
 ("Radarhorisont", "ved 100 km · ved 150 km", "370 m · 1 km"),
 ("SAM tænder", "med EWR/AWACS-sporing", "60 km"),
 ("SAM tænder", "uden radarstøtte", "25 km"),
 ("HARM", "SAM-radar mørk", "1–2 min"),
 ("Punktforsvar", "flytter sig efter skud", "1,5–4 km"),
 ("Bogey dope", "Support: nærmeste set fjendtlige fly, BRAA", "≤100 nm"),
])}
""", [
 "Lavt og væk fra AWACS = usynlig på fjendens kort",
 "Blind fjenden: EWR → AWACS → SAM – så ser han dig ikke komme",
 "Dræb radaren mens den er tændt – eller brug HARM-vinduet til at komme tæt på",
], "<em>Offentligt for alle: baseejere og frontlinjen. Alt andet skal findes. Nat (20–06) halverer, hvad øjne ser.</em>"))

CARDS.append(("Armoury & SU", f"""
<h2>Våben følger basens SU</h2>
{rows3([
 ("Altid", "Kanon, raketter, ustyrede bomber, pods", "gratis"),
 ("Fra 20 %", "+ IR-missiler, Maverick, Hellfire, GBU-12", "0,25 SU/stk"),
 ("Fra 45 %", "+ AMRAAM, R-77, HARM, JDAM, anti-skib", "0,5 SU/stk"),
])}
<div class=sub style="margin-top:4px">Procent = basens SU af dens maks. Baser starter på 50 %. Se dit flys muligheder i Ground Crew → Rearm and Refuel.</div>
<h2>SU – krigens valuta</h2>
{rows([
 ("Kilde", "Kun depoter producerer SU og nye delinger. Ingen base kan købe selv"),
 ("Transport", "Konvoj 30 · transportfly 30 · skib 40 · heli/kasse 10 SU"),
 ("Forbrug", "Drift af delinger · angreb 2 SU/deling · våben · fly 5 · AI-jager 10"),
 ("Uden SU", "Svagere forsvar · forvitring ~12 t · afskåret base overgiver sig"),
 ("Se SU", "F10: egne baser viser plt | SU · Campaign status: sidens SU"),
])}
""", [
 "Knæk fjendens SU: depoter og transport er de vigtigste mål",
 "Cooldown: 2 dødsfald på 1 t = 15 min uden jetfly (heli altid OK)",
 "Sejrsbonus: 3 sorties / 1 mission for vindersiden → +150 / +50",
], "<em>Armoury at this base viser lageret. Fly pr. base: 4 af hver type, 8 på depoter. Tabte fly erstattes ét i timen.</em>"))

CARDS.append(("Helikopter: CTLD", f"""
{rows([
 ("Hent kasse", "På egen base · koster basen 10 SU (tør base siger nej)"),
 ("Lever kasse", "≤3 km af egen base → +10 SU, fuldfører LOGISTICS"),
 ("FARP", "3 kasser til venlig by eller FOB ≤5 km → spawn, brændstof, ammo"),
 ("Tropper", "10 soldater = 1 deling fra garnisonen (aldrig den sidste)"),
 ("Af ved egen base", "Forstærker garnisonen"),
 ("Af ved fjendens base", "LUFTANGREB med det samme"),
 ("AA-system", "≤3 km af egen base → basen graver sig ét niveau ned"),
 ("Haubits/MLRS", "Pakket ud på egen base → artilleribatteri"),
 ("Bridge kit", "2 kasser ≤1,5 km af ødelagt bro → vej åben straks"),
 ("Minefelt", "≤1,5 km af vej → fjendens kolonner halv fart i 24 t"),
 ("Let køretøj", "Chinook/Mi-8 ≤3 km af fjendtlig base → med i angrebet"),
])}
""", [
 "Skudt ned med tropper om bord = delingerne er tabt",
 "Forlad slottet med tropper om bord → de går hjem",
 "Ingen helikoptermissioner i storm",
], "<em>Alle egne baser er pickup-zoner: 1,5 km om en flyveplads, 600 m om en by. Erobret base = zonen skifter side.</em>"))

CARDS.append(("Frekvenser & tal", f"""
<h2>Navigation</h2>
{rows3([
 ("BLUE tanker", "KC-135MPRS, drogue", "TACAN 51X"),
 ("RED tanker", "IL-78M", "TACAN 52X"),
 ("S-3B tanker", "følger Stennis", "TACAN 76X"),
 ("CVN-74 Stennis", "alle kort, BLUE", "74X · ICLS 4"),
 ("LHA-1 Tarawa", "alle kort, BLUE", "75X · ICLS 5"),
 ("JTAC", "laser + IR-pointer", "1688"),
])}
<h2>Krigen</h2>
{rows3([
 ("Live-zone", "rigtige DCS-enheder omkring spillere", "40 km"),
 ("Krigsur", "mest vundet terræn vinder", "7 dage"),
 ("Tick", "krigen opdateres og gemmes", "5 min"),
 ("Vejr", "glider langsomt, varsler på skærmen", "2–6 t"),
 ("Nat", "AI-angreb flyver ikke", "20–06"),
 ("Strike-pakker", "AI-raid pr. side", "~45 min"),
 ("Runway lukket", "efter 3 bomber ≤60 m", "4 t"),
 ("Vrag", "bliver liggende", "3 døgn"),
])}
""", [
 "Storm: fjendens AI-angrebsfly på jorden, ingen helikoptermissioner",
 "Erobret base: +8 % produktion pr. vundet base",
 "Samme vej igen og igen med angreb = AI sender luftværn og CAP",
], "<em>Eskadrille: sæt tag i dit navn, fx [VKG] Morten. Kilde: github.com/krazyj83/DCS-Danica-Dynamic-Campaign</em>"))

async def main():
    total = len(CARDS)
    async with async_playwright() as p:
        try:
            b = await p.chromium.launch()
        except Exception:  # Playwright's own Chromium not installed: use Google Chrome
            b = await p.chromium.launch(channel="chrome")
        pg = await b.new_page(viewport={"width": W, "height": H})
        for i, (t, m, s, tip) in enumerate(CARDS, 1):
            html = card(i, total, t, m, s, tip)
            path = os.path.join(TMP, f"{i:02d}.html")
            open(path, "w", encoding="utf-8").write(html)
            await pg.goto("file://" + path)
            await pg.wait_for_timeout(150)
            ov = await pg.evaluate("document.querySelector('.card').scrollHeight")
            if ov > H: print("OVERFLOW", i, ov)
            slug = t.lower().replace(" ", "_").replace(":", "").replace("&", "og").replace("ø","oe").replace("å","aa").replace("æ","ae")
            await pg.screenshot(path=os.path.join(OUT, f"DCC_{i:02d}_{slug}.png"))
        await b.close()
    from PIL import Image
    files = sorted(glob.glob(os.path.join(OUT, "DCC_*.png")))
    ims = [Image.open(f).convert("RGB") for f in files]
    ims[0].save(os.path.join(HERE, "DCC_kneeboards.pdf"), save_all=True, append_images=ims[1:])
    print(f"{len(files)} kort -> {OUT} + DCC_kneeboards.pdf")

asyncio.run(main())
