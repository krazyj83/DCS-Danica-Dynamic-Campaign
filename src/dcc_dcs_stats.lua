-- ============================================================================
-- Danica Dynamic Campaign - DCS bridge: sortie history for the squadron pages
-- (v0.51). Load after dcc_dcs_srs.lua, before dcc_main.lua.
-- ----------------------------------------------------------------------------
-- Every debriefed sortie (landed at an own base, FARP or carrier) is kept in
-- the pilot's record (pilots.json, the newest public.sortiesPerPilot), with a
-- running number so sorties from all maps sort in order. public.json then
-- carries up to public.pilots pilots with their totals and last sorties, and
-- the latest sorties of everyone - the companion's web map shows them, and its
-- weekly Discord summary compares the scores week to week.
-- ============================================================================

DCC = DCC or {}
local B = DCC.dcs

local function PC() return DCC.config.public end

local KILLS = { "kills_air", "kills_ground", "kills_convoy", "kills_sam", "kills_structure" }
local KILL_WORD = { kills_air = "air", kills_ground = "ground", kills_convoy = "convoy", kills_sam = "SAM",
                    kills_structure = "buildings" }

-- Record the sortie p is being debriefed for (before the debrief clears p.debrief).
function B.recordSortie(p)
  local s = p and p.debrief
  if not s then return nil end
  local pilots = DCC.pilots
  local rec = pilots:get(p.key, p.name)
  local kills, n = {}, 0
  for _, k in ipairs(KILLS) do
    local d = (rec[k] or 0) - (s.kills[k] or 0)
    if d > 0 then kills[#kills + 1] = d .. " " .. KILL_WORD[k]; n = n + d end
  end
  local done = 0
  for _, m in ipairs(s.missions or {}) do if m.outcome == "done" then done = done + 1 end end
  pilots.data.sortieSeq = (pilots.data.sortieSeq or 0) + 1
  local war = B.war
  local entry = {
    n = pilots.data.sortieSeq, map = DCC.theaterName, side = p.side, type = p.type,
    day = math.floor(war.state.tick * DCC.config.tickSeconds / 8640 + 0.5) / 10,
    minutes = math.floor((timer.getTime() - s.t) / 60 + 0.5),
    kills = n, killsText = #kills > 0 and table.concat(kills, ", ") or "none",
    missions = done, points = pilots:score(p.key) - (s.score or 0),
  }
  rec.recent = rec.recent or {}
  table.insert(rec.recent, 1, entry)
  while #rec.recent > PC().sortiesPerPilot do table.remove(rec.recent) end
  pilots.dirty = true
  return entry
end

local baseDebrief = B.debrief
if baseDebrief then
  function B.debrief(p)
    pcall(B.recordSortie, p)
    return baseDebrief(p)
  end
end

local function totalKills(p)
  local n = 0
  for _, k in ipairs(KILLS) do n = n + (p[k] or 0) end
  return n
end

local basePublic = B.publicState
function B.publicState()
  local out = basePublic()
  local cfg, pilots = PC(), DCC.pilots
  local list, all = {}, {}
  for key, p in pairs(pilots.data.pilots) do
    list[#list + 1] = { name = p.name, score = pilots:score(key), rank = pilots:rank(key), squadron = p.squadron,
      sorties = p.sorties or 0, hours = math.floor((p.flightMinutes or 0) / 6 + 0.5) / 10, kills = totalKills(p),
      missions = p.missions or 0, rescues = p.rescues or 0, deaths = p.deaths or 0, recent = p.recent or {} }
    for _, r in ipairs(p.recent or {}) do
      all[#all + 1] = { n = r.n, name = p.name, map = r.map, side = r.side, type = r.type, day = r.day,
        minutes = r.minutes, kills = r.kills, killsText = r.killsText, missions = r.missions, points = r.points }
    end
  end
  table.sort(list, function(a, b) if a.score ~= b.score then return a.score > b.score end return a.name < b.name end)
  while #list > cfg.pilots do table.remove(list) end
  table.sort(all, function(a, b) return (a.n or 0) > (b.n or 0) end)
  while #all > cfg.sorties do table.remove(all) end
  out.pilots, out.sorties = list, all
  return out
end
