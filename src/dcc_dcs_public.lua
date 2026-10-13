-- ============================================================================
-- Danica Dynamic Campaign - public status for the web map and Discord.
-- Load after dcc_dcs_jtac.lua.
-- ----------------------------------------------------------------------------
-- Writes two files to Saved Games\DCS\DCC\ for server/dcc_companion.py:
--
--   public.json  - rewritten every public.everySeconds: map, war clock,
--                  weather, every base (position, owner, FARP), the front line,
--                  recent public events, top pilots and squadrons, ships.
--                  ONLY what both sides know anyway: owners and the front, no
--                  garrison sizes, no supply, no enemy positions.
--   feed.jsonl   - one line per public event (captures, kills of radars,
--                  AWACS, ships, convoys, completed missions, weather, war
--                  clock warnings, victory and the war report), each with a
--                  running number per war so the companion posts it once.
-- ============================================================================

DCC = DCC or {}
local B = DCC.dcs
local U = DCC.util

B.PUBLIC_KINDS = {
  capture = true, victory = true, clock = true, weather = true, ewr_destroyed = true, awacs_lost = true,
  sam_destroyed = true, convoy_lost = true, airlift_lost = true, farp_built = true, ship_sunk = true,
  mission_done = true, rescued = true, report = true,
}

local function ll(p)
  local lat, lon = coord.LOtoLL({ x = p.x, y = 0, z = p.z })
  return { lat = math.floor(lat * 1e5 + 0.5) / 1e5, lon = math.floor(lon * 1e5 + 0.5) / 1e5 }
end

function B.publicState()
  local war, cfg = B.war, DCC.config
  local st = war.state
  local s = war:summary()
  local out = {
    map = war.T.name, version = cfg.version, warId = st.warId, tick = st.tick,
    day = (st.tick - (st.clockStart or 0)) * cfg.tickSeconds / 86400,
    updated = timer.getAbsTime(),
    winner = st.winner, winBy = st.winBy,
    bases = { blue = s.blue.nodes, red = s.red.nodes },
    weather = war:weatherKind(), night = war:isNight(),
    nodes = {}, front = {}, events = {}, pilots = {}, squadrons = {}, ships = {},
  }
  local left = war:clockTicksLeft()
  if left then
    out.clock = { hoursLeft = math.max(0, left) * cfg.tickSeconds / 3600, leader = war:clockLeader(),
                  gained = math.abs(war:groundGained("blue")) }
  end
  for _, id in ipairs(war.T.order) do
    local tn, ns = war.T.nodes[id], st.nodes[id]
    out.nodes[#out.nodes + 1] = { id = id, name = tn.name, lat = tn.lat, lon = tn.lon, kind = tn.kind,
      depot = tn.depot, side = ns.side, farp = war:farpAt(id) or nil }
  end
  local terr = DCC.territory.compute(war)
  local function r5(v) return math.floor(v * 1e5 + 0.5) / 1e5 end
  for _, line in ipairs(terr.front) do
    local pl = {}
    for _, p in ipairs(line) do pl[#pl + 1] = { r5(p.lat), r5(p.lon) } end
    out.front[#out.front + 1] = pl
  end
  out.territory = {}
  for _, cell in ipairs(terr.territory) do
    local pl = {}
    for _, p in ipairs(cell.poly) do pl[#pl + 1] = { r5(p.lat), r5(p.lon) } end
    out.territory[#out.territory + 1] = { side = cell.side, poly = pl }
  end
  local evs = st.events
  for i = #evs, 1, -1 do
    local ev = evs[i]
    if B.PUBLIC_KINDS[ev.kind] then
      out.events[#out.events + 1] = { tick = ev.tick, kind = ev.kind, side = ev.side, text = ev.text }
      if #out.events >= cfg.public.events then break end
    end
  end
  for key, p in pairs(DCC.pilots.data.pilots) do
    out.pilots[#out.pilots + 1] = { name = p.name, score = DCC.pilots:score(key), rank = DCC.pilots:rank(key),
      squadron = p.squadron, sorties = p.sorties }
  end
  table.sort(out.pilots, function(a, b) if a.score ~= b.score then return a.score > b.score end return a.name < b.name end)
  while #out.pilots > 20 do table.remove(out.pilots) end
  for i, sq in ipairs(DCC.pilots:squadrons()) do
    if i > 10 then break end
    out.squadrons[i] = sq
  end
  for _, ship in ipairs(war.theater.naval or {}) do
    out.ships[#out.ships + 1] = { name = ship.name, side = ship.side, status = st.naval[ship.id] and st.naval[ship.id].status }
  end
  return out
end

function B.writePublic()
  local okE, text = pcall(DCC.json.encode, B.publicState())
  if okE then DCC.persist.writeFile("public.json", text) end
end

-- Append public events to the feed (each once: numbered per war).
function B.publishFeed(events)
  local war = B.war
  local st = war.state
  local lines = {}
  for _, ev in ipairs(events or {}) do
    if B.PUBLIC_KINDS[ev.kind] then
      st.feedSeq = (st.feedSeq or 0) + 1
      local okE, line = pcall(DCC.json.encode, { seq = st.feedSeq, warId = st.warId, map = war.T.name,
        tick = ev.tick or st.tick, kind = ev.kind, side = ev.side, text = ev.text })
      if okE then lines[#lines + 1] = line end
    end
  end
  if #lines > 0 then DCC.persist.appendFile("feed.jsonl", table.concat(lines, "\n") .. "\n") end
end

local baseAnnounce = B.announce
function B.announce(events)
  baseAnnounce(events)
  B.publishFeed(events)
  B.writePublic()
end
