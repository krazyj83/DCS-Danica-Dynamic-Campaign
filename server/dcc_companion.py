#!/usr/bin/env python3
"""Danica Dynamic Campaign companion: live web map + Discord feed.

Runs next to the DCS server (plain Python 3.8+, no extra packages). It reads
the files the campaign writes to Saved Games\\DCS\\DCC\\:

  public.json  -> served as a live web map at http://<server>:8088/
                  (front line, base owners, war clock, weather, recent events,
                  top pilots and squadrons; refreshes every 30 s)
  feed.jsonl   -> each new public event is posted to a Discord channel
                  through a webhook (captures, radar/AWACS/ship kills, convoys,
                  missions, weather, war-clock warnings, victory, war report)

Only public information is shown: who owns which base and where the front is.
No garrison sizes, no supply, no enemy positions.

Setup:
  1. Discord: channel settings > Integrations > Webhooks > New webhook > Copy URL.
  2. python dcc_companion.py --dcc "C:\\Users\\you\\Saved Games\\DCS.server\\DCC" --webhook <URL>
     (or put the same in dcc_companion.json next to this script, see --help)
  3. Open http://localhost:8088/ ; open the port in the firewall to share it.

Other modes:
  --once          post new feed lines once and exit (for Windows Task Scheduler)
  --static DIR    write index.html + public.json into DIR and exit (host anywhere)
  --no-web / --no-discord
"""
import argparse
import json
import os
import sys
import threading
import time
import urllib.error
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

HERE = os.path.dirname(os.path.abspath(__file__))

ICONS = {
    "capture": "🚩", "victory": "🏆", "clock": "⏳", "weather": "🌦️", "ewr_destroyed": "📡",
    "awacs_lost": "✈️", "sam_destroyed": "💥", "convoy_lost": "🚚", "airlift_lost": "🛩️",
    "farp_built": "🚁", "ship_sunk": "⚓", "mission_done": "✅", "rescued": "🪂", "report": "📜",
}
DEFAULT_KINDS = list(ICONS.keys())


# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
def default_dcc_folder():
    home = os.path.expanduser("~")
    for name in ("DCS.server", "DCS.openbeta", "DCS"):
        p = os.path.join(home, "Saved Games", name, "DCC")
        if os.path.isdir(p):
            return p
    return os.path.join(home, "Saved Games", "DCS", "DCC")


def load_config(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--config", default=os.path.join(HERE, "dcc_companion.json"),
                    help="JSON file with any of: dcc, webhook, port, interval, kinds, username")
    ap.add_argument("--dcc", help="the campaign folder (Saved Games\\DCS\\DCC)")
    ap.add_argument("--webhook", help="Discord webhook URL")
    ap.add_argument("--port", type=int)
    ap.add_argument("--interval", type=float, help="seconds between feed checks (default 30)")
    ap.add_argument("--once", action="store_true")
    ap.add_argument("--static")
    ap.add_argument("--no-web", action="store_true")
    ap.add_argument("--no-discord", action="store_true")
    a = ap.parse_args(argv)
    cfg = {"dcc": None, "webhook": "", "port": 8088, "interval": 30, "kinds": DEFAULT_KINDS,
           "username": "Danica Dynamic Campaign"}
    if a.config and os.path.exists(a.config):
        with open(a.config, encoding="utf-8") as f:
            cfg.update(json.load(f))
    for k in ("dcc", "webhook", "port", "interval"):
        v = getattr(a, k)
        if v is not None:
            cfg[k] = v
    cfg["dcc"] = cfg["dcc"] or default_dcc_folder()
    cfg["once"], cfg["static"] = a.once, a.static
    cfg["web"], cfg["discord"] = not a.no_web, (not a.no_discord) and bool(cfg["webhook"])
    return cfg


# ---------------------------------------------------------------------------
# Discord feed
# ---------------------------------------------------------------------------
class Feed:
    """Posts new lines of feed.jsonl once. Remembers its place in
    companion_state.json (byte offset + last number per war)."""

    def __init__(self, cfg, post=None):
        self.cfg = cfg
        self.path = os.path.join(cfg["dcc"], "feed.jsonl")
        self.state_path = os.path.join(cfg["dcc"], "companion_state.json")
        self.state = {"offset": 0, "seen": {}}
        if os.path.exists(self.state_path):
            try:
                with open(self.state_path, encoding="utf-8") as f:
                    self.state.update(json.load(f))
            except (OSError, ValueError):
                pass
        self.post = post or self.post_discord

    def save(self):
        tmp = self.state_path + ".tmp"
        with open(tmp, "w", encoding="utf-8") as f:
            json.dump(self.state, f)
        os.replace(tmp, self.state_path)

    def new_events(self):
        if not os.path.exists(self.path):
            return [], self.state["offset"]
        size = os.path.getsize(self.path)
        start = self.state["offset"] if self.state["offset"] <= size else 0   # file replaced: re-read, seq filter stops repeats
        with open(self.path, "rb") as f:
            f.seek(start)
            data = f.read()
        end = start + len(data)
        if not data.endswith(b"\n"):                     # half-written last line: leave it for next time
            cut = data.rfind(b"\n") + 1
            data, end = data[:cut], start + cut
        events = []
        for raw in data.decode("utf-8", "replace").splitlines():
            try:
                ev = json.loads(raw)
            except ValueError:
                continue
            war = str(ev.get("warId"))
            if ev.get("seq", 0) <= self.state["seen"].get(war, 0):
                continue
            events.append(ev)
        return events, end

    @staticmethod
    def format(ev):
        icon = ICONS.get(ev.get("kind"), "•")
        if ev.get("kind") == "report":
            return f"{icon} **War report**\n```\n{ev.get('text', '')}\n```"
        return f"{icon} {ev.get('text', '')}"

    def messages(self, events):
        """Group events into Discord messages (max ~1900 chars each)."""
        out, cur = [], ""
        for ev in events:
            if ev.get("kind") not in self.cfg["kinds"]:
                continue
            line = self.format(ev)
            if ev.get("kind") == "report":
                if cur:
                    out.append(cur)
                    cur = ""
                out.append(line[:1990])
                continue
            if len(cur) + len(line) + 1 > 1900:
                out.append(cur)
                cur = ""
            cur = (cur + "\n" + line) if cur else line
        if cur:
            out.append(cur)
        return out

    def post_discord(self, content):
        body = json.dumps({"content": content, "username": self.cfg.get("username")}).encode("utf-8")
        req = urllib.request.Request(self.cfg["webhook"], data=body,
                                     headers={"Content-Type": "application/json", "User-Agent": "DCC-companion"})
        try:
            with urllib.request.urlopen(req, timeout=15) as r:
                return 200 <= r.status < 300
        except urllib.error.HTTPError as e:
            print(f"discord: HTTP {e.code} {e.reason}")
            return False
        except OSError as e:
            print(f"discord: {e}")
            return False

    def run_once(self):
        events, end = self.new_events()
        for msg in self.messages(events):
            if not self.post(msg):
                return 0                                  # try again next time; nothing marked as posted
            time.sleep(0.5)                               # stay well under Discord's rate limit
        for ev in events:
            war = str(ev.get("warId"))
            self.state["seen"][war] = max(self.state["seen"].get(war, 0), ev.get("seq", 0))
        self.state["offset"] = end
        self.save()
        return len(events)


# ---------------------------------------------------------------------------
# Web map
# ---------------------------------------------------------------------------
PAGE = r"""<!doctype html>
<html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Danica Dynamic Campaign</title>
<link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css">
<style>
:root{--bg:#f4f1ea;--panel:#fffdf8;--ink:#1d2329;--muted:#66707a;--line:#ddd6c8;--blue:#2373F4;--red:#DF301C;--front:#e0a800}
@media (prefers-color-scheme:dark){:root{--bg:#14181c;--panel:#1c2227;--ink:#e8e6e1;--muted:#98a2ab;--line:#2c343b}}
*{box-sizing:border-box}html,body{margin:0;height:100%;background:var(--bg);color:var(--ink);
font:14px/1.4 ui-sans-serif,system-ui,-apple-system,"Segoe UI",sans-serif}
.wrap{display:grid;grid-template-columns:1fr 360px;height:100%}
#map{height:100%;min-height:55vh}
aside{background:var(--panel);border-left:1px solid var(--line);overflow:auto;padding:16px 18px}
h1{font-size:13px;letter-spacing:.12em;text-transform:uppercase;color:var(--muted);margin:0 0 4px}
h2{font-size:12px;letter-spacing:.1em;text-transform:uppercase;color:var(--muted);margin:22px 0 8px;
border-top:1px solid var(--line);padding-top:14px}
.big{font-size:26px;font-weight:700;margin:0}
.clock{font-variant-numeric:tabular-nums;font-size:20px;font-weight:600}
.bar{display:flex;height:10px;border-radius:5px;overflow:hidden;margin:8px 0 4px}
.bar .b{background:var(--blue)}.bar .r{background:var(--red)}
.row{display:flex;justify-content:space-between;gap:8px}.muted{color:var(--muted)}
ol{margin:0;padding-left:20px}li{margin:3px 0}
.ev{margin:6px 0;padding-left:10px;border-left:3px solid var(--line)}
.ev.blue{border-color:var(--blue)}.ev.red{border-color:var(--red)}
.tag{display:inline-block;padding:0 6px;border-radius:4px;font-size:11px;font-weight:700;color:#fff}
.tag.blue{background:var(--blue)}.tag.red{background:var(--red)}
@media (max-width:820px){.wrap{grid-template-columns:1fr;height:auto}#map{height:60vh}aside{border-left:0}}
</style></head><body>
<div class="wrap"><div id="map"></div><aside>
<h1>Danica Dynamic Campaign</h1><p class="big" id="mapname">…</p>
<p class="muted" id="sub"></p>
<div class="row"><span><span class="tag blue">BLUE</span> <b id="nb">0</b> bases</span>
<span><b id="nr">0</b> bases <span class="tag red">RED</span></span></div>
<div class="bar"><div class="b" id="bb"></div><div class="r" id="br"></div></div>
<h2>War clock</h2><div class="clock" id="clock">–</div><div class="muted" id="leader"></div>
<h2>Latest</h2><div id="events"></div>
<h2>Top pilots</h2><ol id="pilots"></ol>
<h2>Squadrons</h2><ol id="squadrons"></ol>
<p class="muted" style="margin-top:24px" id="updated"></p>
</aside></div>
<script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
<script>
const css=n=>getComputedStyle(document.documentElement).getPropertyValue(n).trim();
const map=L.map('map',{zoomControl:true});
L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',{maxZoom:12,attribution:'© OpenStreetMap'}).addTo(map);
const layer=L.layerGroup().addTo(map);let fitted=false;
const esc=s=>String(s??'').replace(/[&<>"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]));
function draw(d){
  layer.clearLayers();
  const pts=[];
  for(const t of d.territory||[]){const c=t.side==='blue'?css('--blue'):css('--red');
    L.polygon(t.poly,{stroke:false,fillColor:c,fillOpacity:.25,interactive:false}).addTo(layer)}
  for(const f of d.front||[]){L.polyline(f,{color:css('--front'),weight:4,opacity:.95,interactive:false}).addTo(layer)}
  for(const n of d.nodes||[]){
    const c=n.side==='blue'?css('--blue'):css('--red');pts.push([n.lat,n.lon]);
    L.circleMarker([n.lat,n.lon],{radius:n.depot?9:(n.kind==='airbase'?7:5),color:'#000',weight:1,
      fillColor:c,fillOpacity:.9}).bindTooltip(esc(n.name)+(n.depot?' (depot)':'')+(n.farp?' – FARP':''))
      .bindPopup(`<b>${esc(n.name)}</b><br>${n.side.toUpperCase()} ${n.depot?'depot':esc(n.kind)}${n.farp?' · FARP':''}`).addTo(layer);
  }
  if(!fitted&&pts.length){map.fitBounds(pts,{padding:[20,20]});fitted=true}
  document.getElementById('mapname').textContent=d.map;
  const w={clear:'clear skies',overcast:'overcast',rain:'rain',storm:'storm'}[d.weather]||d.weather;
  document.getElementById('sub').textContent=`War day ${(d.day||0).toFixed(1)} · ${w}${d.night?' · night':''}`+
    (d.winner?` · ${d.winner.toUpperCase()} WON`:'');
  const b=d.bases.blue,r=d.bases.red;
  document.getElementById('nb').textContent=b;document.getElementById('nr').textContent=r;
  document.getElementById('bb').style.flex=b;document.getElementById('br').style.flex=r;
  if(d.clock){const h=d.clock.hoursLeft;document.getElementById('clock').textContent=
    `${Math.floor(h/24)}d ${String(Math.floor(h%24)).padStart(2,'0')}h ${String(Math.floor(h*60%60)).padStart(2,'0')}m left`;
    document.getElementById('leader').textContent=d.clock.gained?`${d.clock.leader.toUpperCase()} is ahead: +${d.clock.gained} bases since the start`:'Even: no ground gained yet'}
  document.getElementById('events').innerHTML=(d.events||[]).slice(0,15).map(e=>
    `<div class="ev ${e.side||''}">${esc(e.text)}</div>`).join('')||'<p class="muted">Quiet so far.</p>';
  document.getElementById('pilots').innerHTML=(d.pilots||[]).slice(0,10).map(p=>
    `<li><b>${esc(p.name)}</b> <span class="muted">${esc(p.rank)} · ${p.score}</span></li>`).join('')||'<p class="muted">No pilots yet.</p>';
  document.getElementById('squadrons').innerHTML=(d.squadrons||[]).map(s=>
    `<li><b>${esc(s.tag)}</b> <span class="muted">${s.score} pts · ${s.members} pilots · ${s.wins} wins</span></li>`).join('')||
    '<p class="muted">Put [TAG] in front of your name to fly for a squadron.</p>';
  document.getElementById('updated').textContent='Updated '+new Date().toLocaleTimeString();
}
async function load(){try{const r=await fetch('public.json?'+Date.now());if(r.ok)draw(await r.json())}catch(e){}}
load();setInterval(load,30000);
</script></body></html>
"""


def make_handler(cfg):
    class Handler(BaseHTTPRequestHandler):
        def do_GET(self):
            path = self.path.split("?")[0]
            if path in ("/", "/index.html"):
                body, ctype = PAGE.encode("utf-8"), "text/html; charset=utf-8"
            elif path == "/public.json":
                try:
                    with open(os.path.join(cfg["dcc"], "public.json"), "rb") as f:
                        body = f.read()
                except OSError:
                    body = b'{"map":"waiting for the server","nodes":[],"bases":{"blue":0,"red":0}}'
                ctype = "application/json"
            else:
                self.send_error(404)
                return
            self.send_response(200)
            self.send_header("Content-Type", ctype)
            self.send_header("Cache-Control", "no-store")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)

        def log_message(self, *args):
            pass
    return Handler


def write_static(cfg, out_dir):
    os.makedirs(out_dir, exist_ok=True)
    with open(os.path.join(out_dir, "index.html"), "w", encoding="utf-8") as f:
        f.write(PAGE)
    src = os.path.join(cfg["dcc"], "public.json")
    if os.path.exists(src):
        with open(src, "rb") as a, open(os.path.join(out_dir, "public.json"), "wb") as b:
            b.write(a.read())


def main(argv=None):
    cfg = load_config(argv)
    if cfg["static"]:
        write_static(cfg, cfg["static"])
        print(f"wrote {cfg['static']}")
        return 0
    feed = Feed(cfg) if cfg["discord"] else None
    if cfg["once"]:
        n = feed.run_once() if feed else 0
        print(f"posted {n} events")
        return 0
    if cfg["web"]:
        srv = ThreadingHTTPServer(("0.0.0.0", int(cfg["port"])), make_handler(cfg))
        threading.Thread(target=srv.serve_forever, daemon=True).start()
        print(f"web map: http://localhost:{cfg['port']}/   (campaign folder: {cfg['dcc']})")
    if feed:
        print("posting new events to Discord")
    try:
        while True:
            if feed:
                feed.run_once()
            time.sleep(float(cfg["interval"]))
    except KeyboardInterrupt:
        return 0


if __name__ == "__main__":
    sys.exit(main())
