"""Kneeboard pages for every mission (shown to every aircraft, KNEEBOARD/IMAGES/).

    1. COMMS     - every airbase on the map: owner at the start of the war, tower
                   VHF / UHF; carriers (TACAN, ICLS), tankers, carrier tanker.
    2. MAP       - the campaign map at the start: bases, roads, carriers, lanes.
    3. REFERENCE - F10 menus, mission types, how bases fall, key numbers.

DCS shows kneeboard pages to everyone, so they hold both sides' information (as a
real NOTAM would); what changes during the war is on the F10 map and in
F10 > Other > Campaign status.

Built with Pillow and the DejaVu fonts in tools/fonts (free licence, see there).
"""
import io
import math
import os

from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
W, H = 1024, 1365
BG, INK, DIM = (246, 242, 232), (25, 25, 25), (110, 110, 110)
BLUE, RED, GOLD = (35, 115, 244), (223, 48, 28), (190, 140, 0)


def font(size, bold=False, mono=False):
    name = "DejaVuSansMono.ttf" if mono else ("DejaVuSans-Bold.ttf" if bold else "DejaVuSans.ttf")
    try:
        return ImageFont.truetype(os.path.join(HERE, "fonts", name), size)
    except OSError:
        return ImageFont.load_default()


def page(title, theater_name):
    img = Image.new("RGB", (W, H), BG)
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, W, 70], fill=(40, 48, 60))
    d.text((24, 16), title, font=font(32, bold=True), fill=(255, 255, 255))
    d.text((W - 24, 24), f"DANICA DYNAMIC CAMPAIGN - {theater_name}", font=font(18), fill=(220, 220, 220), anchor="ra")
    return img, d


def png(img):
    b = io.BytesIO()
    img.save(b, "PNG", optimize=True)
    return b.getvalue()


def mhz(hz):
    return f"{hz / 1e6:.3f}".rstrip("0").rstrip(".") if hz else "-"


def comms_pages(theater, theater_name, airports, tankers):
    """airports: [(name, side, atc_radio or None)]; returns list of images."""
    rows = sorted(airports, key=lambda a: (a[1] != "blue", a[0]))
    per = 30
    pages = []
    for start in range(0, max(1, len(rows)), per):
        img, d = page("COMMS & NAV" + (f" ({start // per + 1})" if len(rows) > per else ""), theater_name)
        y = 95
        d.text((24, y), "AIRBASES (owner at the start of the war - captures change it)", font=font(20, bold=True), fill=INK)
        y += 36
        cols = [(24, "AIRBASE"), (470, "SIDE"), (590, "VHF"), (760, "UHF")]
        for x, t in cols:
            d.text((x, y), t, font=font(17, bold=True), fill=DIM)
        y += 28
        for name, side, radio in rows[start:start + per]:
            col = BLUE if side == "blue" else RED
            d.text((24, y), name[:34], font=font(19), fill=INK)
            d.text((470, y), side.upper(), font=font(19, bold=True), fill=col)
            d.text((590, y), mhz(radio.vhf_high_hz) if radio else "-", font=font(19, mono=True), fill=INK)
            d.text((760, y), mhz(radio.uhf_hz) if radio else "-", font=font(19, mono=True), fill=INK)
            y += 29
        if start + per >= len(rows):
            y += 20
            d.line([24, y, W - 24, y], fill=DIM, width=2)
            y += 16
            d.text((24, y), "SHIPS", font=font(20, bold=True), fill=INK)
            y += 34
            for s in theater.get("naval", []) or []:
                col = BLUE if s["side"] == "blue" else RED
                tac = f"TACAN {s['tacan']}X {s.get('tacanCall', '')}" if s.get("tacan", 74) else "no TACAN"
                if s.get("tacan") is None:
                    tac = "TACAN 74X STN"
                icls = f"ICLS {s['icls']}" if s.get("icls", 4) else ""
                if s.get("icls") is None:
                    icls = "ICLS 4"
                d.text((24, y), s["name"], font=font(19, bold=True), fill=col)
                d.text((470, y), f"{tac}   {icls}", font=font(19, mono=True), fill=INK)
                y += 28
                slots = ", ".join(s.get("slots", []) or [])
                d.text((44, y), slots[:90], font=font(15), fill=DIM)
                y += 30
            y += 10
            d.text((24, y), "TANKERS", font=font(20, bold=True), fill=INK)
            y += 34
            for side, text in tankers:
                d.text((24, y), text, font=font(19, mono=True), fill=BLUE if side == "blue" else RED)
                y += 29
        pages.append(img)
    return pages


def map_page(theater, theater_name, carrier_xy=None):
    img, d = page("CAMPAIGN MAP", theater_name)
    d.text((24, 80), "Owner at the start of the war", font=font(16), fill=DIM)
    nodes = {n["id"]: n for n in theater["nodes"]}
    lats = [n["lat"] for n in theater["nodes"]] + [s["lat"] for s in theater.get("naval", []) or []]
    lons = [n["lon"] for n in theater["nodes"]] + [s["lon"] for s in theater.get("naval", []) or []]
    la0, la1, lo0, lo1 = min(lats), max(lats), min(lons), max(lons)
    k = math.cos(math.radians((la0 + la1) / 2))           # degrees of longitude are shorter
    box = (40, 100, W - 40, H - 140)
    sx = (box[2] - box[0]) / max((lo1 - lo0) * k, 1e-6)
    sy = (box[3] - box[1]) / max(la1 - la0, 1e-6)
    s = min(sx, sy) * 0.92
    cx, cy = (box[0] + box[2]) / 2, (box[1] + box[3]) / 2
    mlo, mla = (lo0 + lo1) / 2, (la0 + la1) / 2

    def xy(lat, lon):
        return cx + (lon - mlo) * k * s, cy - (lat - mla) * s

    for e in theater.get("edges", []) or []:
        sea = isinstance(e, dict) and e.get("sea")
        ea, eb = (e[1], e[2]) if isinstance(e, dict) else (e[0], e[1])
        a, b = nodes.get(ea), nodes.get(eb)
        if a and b:
            d.line([xy(a["lat"], a["lon"]), xy(b["lat"], b["lon"])], fill=(150, 150, 150) if not sea else (120, 160, 210),
                   width=2)
    for lane in theater.get("shipping", []) or []:
        d.line([xy(lane["start"]["lat"], lane["start"]["lon"]), xy(lane["dock"]["lat"], lane["dock"]["lon"])],
               fill=(120, 160, 210), width=2)
    for n in theater["nodes"]:
        x, y = xy(n["lat"], n["lon"])
        col = BLUE if n["side"] == "blue" else RED
        r = 9 if n.get("depot") else (7 if n["kind"] == "airbase" else 5)
        if n["kind"] == "airbase":
            d.rectangle([x - r, y - r, x + r, y + r], fill=col, outline=INK)
        else:
            d.ellipse([x - r, y - r, x + r, y + r], fill=col, outline=INK)
        d.text((x + r + 3, y - 8), n["name"][:22], font=font(13), fill=INK)
    for sh in theater.get("naval", []) or []:
        x, y = xy(sh["lat"], sh["lon"])
        col = BLUE if sh["side"] == "blue" else RED
        d.polygon([(x, y - 10), (x + 10, y + 8), (x - 10, y + 8)], fill=col, outline=INK)
        d.text((x + 12, y - 8), sh["name"], font=font(13, bold=True), fill=col)
    y = H - 120
    d.rectangle([40, y + 4, 54, y + 18], fill=BLUE, outline=INK)
    d.text((62, y), "airbase", font=font(16), fill=INK)
    d.ellipse([180, y + 4, 194, y + 18], fill=BLUE, outline=INK)
    d.text((202, y), "town", font=font(16), fill=INK)
    d.rectangle([290, y + 2, 308, y + 20], fill=BLUE, outline=INK)
    d.text((316, y), "depot (larger)", font=font(16), fill=INK)
    d.polygon([(470, y + 2), (480, y + 20), (460, y + 20)], fill=BLUE, outline=INK)
    d.text((488, y), "ship", font=font(16), fill=INK)
    d.line([560, y + 11, 610, y + 11], fill=(150, 150, 150), width=3)
    d.text((618, y), "road", font=font(16), fill=INK)
    d.line([690, y + 11, 740, y + 11], fill=(120, 160, 210), width=3)
    d.text((748, y), "sea lane", font=font(16), fill=INK)
    d.text((40, y + 40), "Live front line, enemy contacts and FARPs: F10 map. Owner here = start of the war.",
           font=font(16), fill=DIM)
    return img


REFERENCE = [
    ("F10 > OTHER", [
        "Missions > Join a flight | Mission board | My mission | Pilot records | Cargo",
        "Support > Artillery / CAS / Illumination on my map mark, AWACS picture, Armoury",
        "CTLD > troops, crates, FARP kit (Chinook / Mi-8), Repair kit (any helo), FOB",
        "Campaign > Campaign status (front, supply, weather, dangerous roads)",
    ]),
    ("MISSION TYPES", [
        "CAS  BAI  STRIKE  SEAD  EWR  ARTY  FORT  BRIDGE  RUNWAY  INDUSTRY  COIN  ANTISHIP",
        "CAP  ESCORT  PKGESCORT  HVAESCORT  INTERCEPT  TANKER  HVAA",
        "RECON (any aircraft, low pass)   SCUD hunt   POPUP (MANPADS / mobile SAM)",
        "Helicopters: CONVOY  CSAR  LOGISTICS  FARP  FARPSUP  MEDEVAC  POW  AMPHIB",
        "Ships: SHIPSTRIKE / SHIPESCORT (supply ships on the sea lanes)",
        "Helicopters see missions within ~60 nm, slow aircraft ~120 nm.",
        "Several pilots can fly one mission: everyone gets the credit (+ team bonus).",
        "QRA: scrambled on the ground? Airborne in 5 min = the INTERCEPT is yours (+10).",
    ]),
    ("HOW A BASE FALLS", [
        "Every defending platoon destroyed while attackers are there.",
        "Defence x1.3 town, x1.5 airbase, x2 depot; +10 % per fortification level.",
        "Out of supply x0.7, cut off from all depots x0.8; cut off + dry + 2 platoons",
        "  or fewer = surrender. CTLD troops / amphibious landings take empty bases.",
        "Help: CAS on the battle, strike fortifications, kill convoys, cut the roads.",
    ]),
    ("SUPPLY AND ARMOURY", [
        "Shelves follow base supply: basic always, guided from 20 %, advanced from 45 %.",
        "Supply comes by road convoy, airlift, helicopter crates and supply ships.",
        "FARP: kit or 3 crates at a friendly town; resupply it or it runs dry.",
        "Repair kit at a friendly base: a building, then SAM, then EWR fixed at once.",
        "Combined Arms: drive platoons; ASSAULT / HOLD / GCONVOY; Support > Artillery, Smoke.",
    ]),
    ("NIGHT AND WEATHER", [
        "Night 20:00-06:00: half visual range, no AI attack aircraft.",
        "Battles at night are lit by flares when you are near; call more:",
        "  Support > Illumination on my map mark.",
        "Weather drifts over hours (forecasts on screen); storms ground helicopters.",
    ]),
]


def reference_page(theater_name):
    img, d = page("QUICK REFERENCE", theater_name)
    y = 95
    for head, lines in REFERENCE:
        d.text((24, y), head, font=font(21, bold=True), fill=GOLD)
        y += 34
        for line in lines:
            d.text((36, y), line, font=font(18), fill=INK)
            y += 27
        y += 16
    return img


def build(theater, theater_name, airports, tankers):
    """Returns {path in the .miz: png bytes}."""
    imgs = comms_pages(theater, theater_name, airports, tankers)
    imgs.append(map_page(theater, theater_name))
    imgs.append(reference_page(theater_name))
    return {f"KNEEBOARD/IMAGES/DCC_{i + 1:02d}.png": png(im) for i, im in enumerate(imgs)}
