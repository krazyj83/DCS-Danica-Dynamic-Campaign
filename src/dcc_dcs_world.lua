-- ============================================================================
-- Danica Dynamic Campaign - DCS bridge: weather, night, AI adaptation,
-- FARPs and ships. Load after dcc_dcs_radar.lua.
-- ----------------------------------------------------------------------------
--   Weather/night - tells the model when it is night (mission clock), and
--                   shows rain and storms as fog where DCS allows it
--                   (world.weather fog functions, DCS 2.9.10+). Clouds and rain
--                   themselves cannot be changed while a mission runs.
--   Adaptation    - convoys the model marked aiEscort get an air-defence
--                   vehicle driving with them; the AI sends a CAP pair over
--                   its most threatened road; storms and night ground AI
--                   attack sorties.
--   FARPs         - each town has two invisible FARPs in the mission (one per
--                   coalition) with an empty helicopter stock. A FARP the
--                   players built gets the owner's helicopters, a fuel truck,
--                   an ammo truck and a map mark; a lost one is emptied.
--   Ships         - naval groups from the theater pack (placed by the mission
--                   generator). Polled for losses, turned around at the end
--                   of their leg, found by enemy radars, attacked by enemy AI.
-- ============================================================================

DCC = DCC or {}
local B = DCC.dcs
local U = DCC.util

local SIDES = { "blue", "red" }
local function WC() return DCC.config.world end
local function ok(fn, ...) local s, r = pcall(fn, ...); if s then return r end end
local function alive(u) return u ~= nil and ok(u.isExist, u) == true end
local function dist2D(a, b)
  local dx, dz = a.x - b.x, a.z - b.z
  return math.sqrt(dx * dx + dz * dz)
end
local function otherSide(s) return s == "blue" and "red" or "blue" end
local function firstValid(list)
  for _, t in ipairs(list or {}) do if B.validType(t) then return t end end
  return nil
end
local function unitsOf(gname)
  local g = ok(Group.getByName, gname)
  local out = {}
  if g and ok(g.isExist, g) then
    for _, u in ipairs(g:getUnits() or {}) do if alive(u) and u:getLife() >= 1 then out[#out + 1] = u end end
  end
  return out
end

B.escorts  = {}   -- convoy move id -> escort group name
B.farps    = {}   -- node id -> { side, crew = group name, mark }
B.naval    = {}   -- ship id -> { group, side, leg }
B.fogNow   = nil

-- ===========================================================================
-- 1. Night and weather
-- ===========================================================================
function B.hourOfDay()
  return math.floor((timer.getAbsTime() % 86400) / 3600)
end

function B.updateNight()
  local h, cfg = B.hourOfDay(), WC()
  B.war.night = (h >= cfg.nightStartHour or h < cfg.nightEndHour)
end

-- Fog for a weather severity: none up to fogFromSev, then thickening through
-- the rain value (at rain severity) to the storm value (at 1).
function B.fogAt(sev)
  local cfg, S = WC(), DCC.War.WEATHER_SEV
  local from = cfg.fogFromSev or 0.45
  if sev <= from then return 0, 0 end
  local rain, storm = cfg.fog.rain, cfg.fog.storm
  if sev <= S.rain then
    local f = (sev - from) / (S.rain - from)
    return 10000 + (rain[1] - 10000) * f, 100 + (rain[2] - 100) * f
  end
  local f = math.min(1, (sev - S.rain) / (S.storm - S.rain))
  return rain[1] + (storm[1] - rain[1]) * f, rain[2] + (storm[2] - rain[2]) * f
end

-- Every tick: the fog follows the weather severity. Where DCS can animate fog
-- (world.weather.setFogAnimation) it eases to the new value over the tick, so
-- it rolls in and lifts instead of jumping.
function B.applyWeather()
  local wx = world and world.weather
  if not wx or not wx.setFogVisibilityDistance then return end   -- older DCS: nothing to do
  local vis, thick = B.fogAt(B.war:weatherSeverity())
  vis, thick = math.floor(vis + 0.5), math.floor(thick + 0.5)
  local last = B.fogNow
  if last and last.vis == vis and last.thick == thick then return end
  B.fogNow = { vis = vis, thick = thick }
  if wx.setFogAnimation and last then
    -- one key after the tick: DCS eases from the fog as it is now (0 = no fog)
    local okA = pcall(wx.setFogAnimation, { { DCC.config.tickSeconds, vis, thick } })
    if okA then return end
  end
  pcall(wx.setFogThickness, thick)
  pcall(wx.setFogVisibilityDistance, vis)
end

-- ===========================================================================
-- 2. AI adaptation
-- ===========================================================================
local baseSpawnConvoy = B.spawnConvoy
function B.spawnConvoy(mv)
  baseSpawnConvoy(mv)
  if not mv.aiEscort or not B.cargo[mv.id] then return end
  local t = firstValid(B.catalog.escortAD and B.catalog.escortAD[mv.side])
  local rec = B.cargo[mv.id]
  local g = ok(Group.getByName, rec.group)
  if not t or not g then return end
  local route = g.data and g.data.route or nil
  local lead = g:getUnit(1)
  if not alive(lead) then return end
  local p = lead:getPoint()
  local b = B.nodePos[mv.to]
  local gname = rec.group .. "_esc"
  local s = DCC.config.liveSpeedMps * 0.8
  local data = { name = gname, task = "Ground Nothing",
    units = { { name = gname .. "_1", type = t, skill = "Good", x = p.x - 60, y = p.z, heading = 0,
                playerCanDrive = false } },
    route = route or { points = {
      { x = p.x, y = p.z, type = "Turning Point", action = "On Road", speed = s, ETA = 0, ETA_locked = false },
      { x = b.x, y = b.z, type = "Turning Point", action = "Off Road", speed = s, ETA = 0, ETA_locked = false } } } }
  if pcall(coalition.addGroup, B.countryId(mv.side), Group.Category.GROUND, data) then B.escorts[mv.id] = gname end
end

local baseDespawnCargo = B.despawnCargo
function B.despawnCargo(mid, rec)
  baseDespawnCargo(mid, rec)
  local e = B.escorts[mid]
  if e then
    local g = ok(Group.getByName, e)
    if g and ok(g.isExist, g) then g:destroy() end
    B.escorts[mid] = nil
  end
end

local basePlanAir = B.planAir
function B.planAir()
  local war = B.war
  -- storms and night: no AI attack sorties (fighters still fly CAP)
  local spawn = B.spawnSortie
  if not war:aiAttackAllowed() then
    B.spawnSortie = function(side, role, kind, target, extra)
      if role == "attack" then return nil end
      return spawn(side, role, kind, target, extra)
    end
  end
  local okP, err = pcall(basePlanAir)
  B.spawnSortie = spawn
  if not okP then error(err) end
  if #B.playerPositions() == 0 then return end
  -- CAP over the worst threatened road
  for _, side in ipairs(SIDES) do
    local a, b = war:worstRoad(side)
    if a then
      local busy = false
      for _, s in pairs(B.sorties) do if s.side == side and s.kind == "ROADCAP" then busy = true end end
      if not busy then
        local pa, pb = B.nodePos[a], B.nodePos[b]
        local mid = { x = (pa.x + pb.x) / 2, y = 0, z = (pa.z + pb.z) / 2 }
        local gname = B.spawnSortie(side, "fighter", "CAP", mid, { node = a })
        if gname and B.sorties[gname] then
          B.sorties[gname].kind = "ROADCAP"
          trigger.action.outTextForCoalition(B.COAL[side], string.format(
            "Command: fighters to cover the road %s - %s (convoys lost there).", war:nodeName(a), war:nodeName(b)), 10)
        end
      end
    end
  end
  -- AI strike on a known enemy ship, now and then
  for _, ship in ipairs(war.theater.naval or {}) do
    local side = otherSide(ship.side)
    local rec = B.naval[ship.id]
    if rec and war:shipUp(ship.id) and war:isFresh(side, "ship:" .. ship.id) and war:aiAttackAllowed() then
      local busy = false
      for _, s in pairs(B.sorties) do if s.side == side and s.kind == "ANTISHIP" then busy = true end end
      if not busy and war.rng:next() < WC().antishipChance then
        local g = ok(Group.getByName, rec.group)
        local u = g and g:getUnit(1)
        if alive(u) then
          B.spawnSortie(side, "attack", "ANTISHIP", u:getPoint(), { groupId = g:getID(), template = "antiship" })
        end
      end
    end
  end
end

-- ===========================================================================
-- 3. FARPs
-- ===========================================================================
-- A FARP's helipads (v0.38: farpPads of them, so more than one helicopter can spawn).
function B.farpPadNames(id, side)
  local out = { "DCC_FARP_" .. id .. "_" .. side }
  for k = 2, WC().farpPads or 1 do out[#out + 1] = "DCC_FARP_" .. id .. "_" .. side .. "_" .. k end
  return out
end

local function farpWarehouse(id, side)
  local ab = ok(Airbase.getByName, "DCC_FARP_" .. id .. "_" .. side)
  return ab and ok(ab.getWarehouse, ab), ab
end

-- Stock the right FARPs; spawn or remove ground crews.
function B.reconcileFarps()
  local war = B.war
  for _, id in ipairs(war.T.order) do
    if war:canHaveFarp(id) then
      local ns = war.state.nodes[id]
      for _, side in ipairs(SIDES) do
        local wh, ab = farpWarehouse(id, side)
        local want = war:farpAt(id) and ns.side == side
        local n = (want and not war:farpDry(id)) and WC().farpHelos or 0   -- a dry FARP spawns nothing
        for _, pad in ipairs(B.farpPadNames(id, side)) do
          local pab = ok(Airbase.getByName, pad)
          local pwh = pab and ok(pab.getWarehouse, pab)
          if pwh then
            for _, t in ipairs(B.catalog.aircraft[side].helicopters or {}) do pcall(pwh.setItem, pwh, t, n) end
          end
        end
        local rec = B.farps[id]
        if want and (not rec or rec.side ~= side) then
          if rec then B.removeFarpCrew(id) end
          B.spawnFarpCrew(id, side, ab)
        elseif not want and rec and rec.side == side then
          B.removeFarpCrew(id)
        end
      end
    end
  end
end

function B.spawnFarpCrew(id, side, ab)
  local p = (ab and ok(ab.getPoint, ab)) or B.nodePos[id]
  local units = {}
  for i, list in ipairs({ { B.catalog.farpCrew[side][1] }, { B.catalog.farpCrew[side][2] }, { B.catalog.farpCrew[side][3] } }) do
    local t = firstValid(list)
    if t then
      units[#units + 1] = { name = "DCC_FARPCREW_" .. id .. "_" .. i, type = t, skill = "Average",
                            x = p.x + 40 + i * 15, y = p.z + 40, heading = 0, playerCanDrive = false }
    end
  end
  local gname = "DCC_FARPCREW_" .. id
  if #units > 0 then
    pcall(coalition.addGroup, B.countryId(side), Group.Category.GROUND, { name = gname, task = "Ground Nothing",
      units = units, route = { points = { { x = units[1].x, y = units[1].y, type = "Turning Point", action = "Off Road",
      speed = 0, ETA = 0, ETA_locked = false } } } })
  end
  B.farps[id] = { side = side, crew = gname }
  U.log("FARP at %s ready for %s", id, side)
end

function B.removeFarpCrew(id)
  local rec = B.farps[id]
  if not rec then return end
  local g = ok(Group.getByName, rec.crew)
  if g and ok(g.isExist, g) then g:destroy() end
  B.farps[id] = nil
end

-- ===========================================================================
-- 4. Ships
-- ===========================================================================
function B.initNaval()
  local war = B.war
  for _, ship in ipairs(war.theater.naval or {}) do
    local gname = "DCC_NAVAL_" .. ship.id
    local g = ok(Group.getByName, gname)
    if g then
      if not war:shipUp(ship.id) then
        g:destroy()          -- sunk earlier in this war: it stays sunk after a restart
      else
        B.naval[ship.id] = { group = gname, side = ship.side, leg = 0,
          start = (g:getUnit(1) and g:getUnit(1):getPoint()) or B.navalPos(ship) }
      end
    end
  end
end

function B.navalPos(ship)
  local p = coord.LLtoLO(ship.lat, ship.lon, 0)
  return { x = p.x, y = 0, z = p.z }
end

-- Carrier dead -> sunk; at the end of a leg, sail back (DCS ships stop at their last waypoint).
function B.pollNaval()
  local war = B.war
  for id, rec in pairs(B.naval) do
    local g = ok(Group.getByName, rec.group)
    local main = g and g:getUnit(1)
    if not alive(main) or main:getLife() < 1 then
      war:shipLost(id)
      B.naval[id] = nil
    elseif timer.getTime() - (rec.turned or 0) > 1800 then
      local p = main:getPoint()
      local ship
      for _, s in ipairs(war.theater.naval or {}) do if s.id == id then ship = s end end
      local home = rec.start
      local leg = (ship.legKm or 80) * 1000                      -- narrow seas: shorter legs
      local far = { x = home.x + math.cos(math.rad(ship.heading)) * leg, z = home.z + math.sin(math.rad(ship.heading)) * leg }
      local target = (dist2D(p, far) < 8000) and home or ((dist2D(p, home) < 8000) and far or nil)
      if target then
        local ctl = g:getController()
        pcall(ctl.setTask, ctl, { id = "Mission", params = { route = { points = {
          { x = p.x, y = p.z, type = "Turning Point", action = "Turning Point", speed = 12.8 },
          { x = target.x, y = target.z, type = "Turning Point", action = "Turning Point", speed = 12.8 } } } } })
        rec.turned = timer.getTime()
      end
    end
  end
end

-- Enemy radars and eyes find ships (they sit on the sea: radar horizon applies).
function B.scanShips()
  local war = B.war
  for id, rec in pairs(B.naval) do
    local enemy = otherSide(rec.side)
    local g = ok(Group.getByName, rec.group)
    local u = g and g:getUnit(1)
    if alive(u) then
      local seen = false
      for _, r in ipairs(B.radarsOf(enemy)) do
        if B.radarSees(r, u) then seen = "radar"; break end
      end
      if not seen then
        for _, pu in ipairs(coalition.getPlayers(B.COAL[enemy]) or {}) do
          if alive(pu) and dist2D(pu:getPoint(), u:getPoint()) <= 40000 then seen = "visual"; break end
        end
      end
      if seen then
        local p = u:getPoint()
        local name = id
        for _, s in ipairs(war.theater.naval or {}) do if s.id == id then name = s.name end end
        war:addContact(enemy, "ship:" .. id, { kind = "ship", source = seen, pos = { x = p.x, z = p.z }, label = name })
      end
    end
  end
end

-- Ships: radar horizon for something on the sea surface.
local baseRadarSees = B.radarSees
function B.radarSees(r, u)
  local desc = ok(u.getDesc, u)
  if desc and desc.category == 3 then          -- Unit.Category.SHIP
    local p = u:getPoint()
    local d = dist2D(r.pos, p)
    if d > r.km * 1000 then return false end
    local need = DCC.War.radarHorizonM(d / 1000, r.agl)
    return need <= 40                            -- a carrier's island is ~40 m tall
  end
  return baseRadarSees(r, u)
end

-- ===========================================================================
-- 5. Map, status, hooks
-- ===========================================================================
local baseDrawIntel = B.drawIntel
function B.drawIntel()
  baseDrawIntel()
  local war = B.war
  if not war.fogOfWar then return end
  for _, side in ipairs(SIDES) do
    for key, c in pairs(war.state.contacts[side]) do
      if c.kind == "ship" and c.pos then
        local fresh = war:isFresh(side, key)
        local ec = DCC.config.colours[otherSide(side)]
        local col = { ec[1], ec[2], ec[3], fresh and 1 or 0.45 }
        B.nextMark = (B.nextMark or DCC.config.markIdBase) + 1
        B.intelMarks[#B.intelMarks + 1] = B.nextMark
        trigger.action.circleToAll(B.COAL[side], B.nextMark, { x = c.pos.x, y = 0, z = c.pos.z }, 5000, col,
          { ec[1], ec[2], ec[3], 0.15 }, 1, true, "")
        B.nextMark = B.nextMark + 1
        B.intelMarks[#B.intelMarks + 1] = B.nextMark
        trigger.action.textToAll(B.COAL[side], B.nextMark, { x = c.pos.x + 5500, y = 0, z = c.pos.z }, col,
          { 0, 0, 0, 0.35 }, 11, true, (c.label or "ship") .. (fresh and "" or " (last seen)"))
      end
    end
  end
end

local baseDrawOps = B.drawOps
function B.drawOps(newMark, toVec3)
  baseDrawOps(newMark, toVec3)
  local war = B.war
  for _, id in ipairs(war.T.order) do
    local ns = war.state.nodes[id]
    if war:farpAt(id) then
      local p = B.nodePos[id]
      local col = DCC.config.colours[ns.side]
      local st, max = war:farpStock(id), WC().farpStock
      local txt = st <= 0 and "FARP (DRY)" or (st < max * WC().farpLowShare
        and string.format("FARP %d/%d", math.floor(st + 0.5), max) or "FARP")
      trigger.action.textToAll(-1, newMark(), { x = p.x + 2500, y = p.y, z = p.z + 2500 }, col, { 0, 0, 0, 0.35 },
        11, true, txt)
    elseif ns.farpSU then
      local p = B.nodePos[id]
      trigger.action.textToAll(B.COAL[ns.side], newMark(), { x = p.x + 2500, y = p.y, z = p.z + 2500 },
        DCC.config.colours[ns.side], { 0, 0, 0, 0.35 }, 10, true,
        string.format("FARP %d/%d SU", math.floor(ns.farpSU), WC().farpBuildSU))
    end
  end
end

local baseStatus = B.opsStatusLines
function B.opsStatusLines(side)
  local lines = baseStatus(side)
  local war = B.war
  local trend = war:weatherTrend()
  lines[#lines + 1] = string.format("Weather: %s%s%s.", DCC.War.WEATHER_TEXT[war:weatherKind()],
    trend ~= "" and (", " .. trend) or "", war:isNight() and ", night" or "")
  local a, b, v = war:worstRoad(side)
  if a then lines[#lines + 1] = string.format("Most dangerous road: %s - %s (AI escorts and CAP there)",
    war:nodeName(a), war:nodeName(b)) end
  for _, ship in ipairs(war.theater.naval or {}) do
    if ship.side == side then
      lines[#lines + 1] = string.format("%s: %s", ship.name, war:shipUp(ship.id) and "on station" or "SUNK")
    end
  end
  return lines
end

-- AI sortie templates by name (antiship uses the "antiship" template, attack pool).
local baseSpawnSortie = B.spawnSortie
function B.spawnSortie(side, role, kind, target, extra)
  if extra and extra.template then
    local find = B.findTemplate
    B.findTemplate = function(name)
      return find("DCC_TPL_" .. side .. "_" .. extra.template) or find(name)
    end
    local okS, r = pcall(baseSpawnSortie, side, role, kind, target, extra)
    B.findTemplate = find
    return okS and r or nil
  end
  return baseSpawnSortie(side, role, kind, target, extra)
end

local basePoll = B.opsPoll
function B.opsPoll()
  basePoll()
  B.pollNaval()
  B.reconcileFarps()
end

local baseTick = B.opsTick
function B.opsTick()
  B.updateNight()
  B.applyWeather()
  baseTick()
end

local baseScan = B.intelScan
function B.intelScan()
  baseScan()
  if B.war.fogOfWar then B.scanShips() end
end

-- eyes see less in bad weather and at night
B.visualFactor = function(air) return B.war:visualFactor(air) end

local baseInit = B.init
function B.init(war, theater, catalog)
  baseInit(war, theater, catalog)
  B.escorts, B.farps, B.naval, B.fogNow = {}, {}, {}, nil
  B.updateNight()
  B.initNaval()
end
