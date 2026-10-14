-- ============================================================================
-- Danica Dynamic Campaign - DCS bridge: air war additions.
-- Load after dcc_dcs_public.lua.
-- ----------------------------------------------------------------------------
--   Tankers      - each side keeps a tanker orbiting behind its AWACS while
--                  anyone is online (BLUE KC-135MPRS, TACAN 51X; RED IL-78M,
--                  TACAN 52X). Shoot the enemy's down: TANKER mission.
--   Drones       - each side keeps a recon drone over the enemy base it is
--                  attacking; it spots ground units for its side's map.
--   Forward CAP  - the AI covers its own base the enemy is about to attack.
--   Packages     - strike packages (strikers + escort + SEAD) and helicopter
--                  assaults; the defender gets INTERCEPT missions.
--   IADS         - SAM sites only light up early when an own EWR or AWACS is
--                  tracking the target (B.cued), and get short-range point
--                  defence (Avenger / Tor) that stays on when the big radar
--                  goes dark.
--   Credit on landing - mission points are logged once the pilot lands at a
--                  friendly base; lost if they die or eject on the way home.
--   Cooldown     - two deaths within an hour ground a pilot from fast jets
--                  for 15 minutes (helicopters are still fine).
-- ============================================================================

DCC = DCC or {}
local B = DCC.dcs
local U = DCC.util

B.assets   = { blue = {}, red = {} }   -- side -> kind -> { group, born }
B.packages = {}                         -- package id -> { strike, escort, sead, target = pos, kind }
B.deaths   = {}                         -- pilot key -> { times }

local SIDES = { "blue", "red" }
local function AC() return DCC.config.air end
local function ok(fn, ...) local s, r = pcall(fn, ...); if s then return r end end
local function alive(u) return u ~= nil and ok(u.isExist, u) == true and (ok(u.getLife, u) or 0) >= 1 end
local function dist2D(a, b)
  local dx, dz = a.x - b.x, a.z - b.z
  return math.sqrt(dx * dx + dz * dz)
end
local function otherSide(s) return s == "blue" and "red" or "blue" end
local function ground(p) return ok(land.getHeight, { x = p.x, y = p.z }) or 0 end
local function unitsOf(gname)
  local g = gname and ok(Group.getByName, gname)
  local out = {}
  if g and ok(g.isExist, g) then
    for _, u in ipairs(g:getUnits() or {}) do if alive(u) then out[#out + 1] = u end end
  end
  return out
end
local function online() return #B.playerPositions() > 0 end

local TACAN = { blue = { ch = 51, cs = "TKR" }, red = { ch = 52, cs = "TKS" } }

-- ===========================================================================
-- Generic AI flight from a template (planes or helicopters)
-- ===========================================================================
local function wp(x, z, alt, speed, task, typ, action)
  return { x = x, y = z, alt = alt, alt_type = "BARO", type = typ or "Turning Point",
           action = action or "Turning Point", speed = speed, speed_locked = true, ETA = 0, ETA_locked = false,
           task = task or { id = "ComboTask", params = { tasks = {} } } }
end

local function combo(tasks)
  for i, t in ipairs(tasks) do t.number, t.auto, t.enabled = i, false, true end
  return { id = "ComboTask", params = { tasks = tasks } }
end

function B.spawnFlight(side, role, gname, from, alt, speed, points, opts)
  opts = opts or {}
  local tpl = B.findTemplate("DCC_TPL_" .. side .. "_" .. role)
  if not tpl then return nil end
  local data = U.copy(tpl)
  data.name, data.lateActivation, data.groupId = gname, nil, nil
  data.task = opts.task or data.task
  local n = opts.size or #data.units
  local units = {}
  for i = 1, math.min(n, #data.units) do
    local u = data.units[i]
    u.unitId, u.name = nil, gname .. "_" .. i
    u.x, u.y, u.alt, u.alt_type, u.speed, u.skill = from.x + (i - 1) * 150, from.z + (i - 1) * 150, alt, "BARO", speed, "High"
    u.heading = 0
    units[i] = u
  end
  data.units = units
  data.route = { points = points }
  local cat = (tpl.units[1] and opts.helicopter) and Group.Category.HELICOPTER or Group.Category.AIRPLANE
  local s, err = pcall(coalition.addGroup, B.countryId(side), cat, data)
  if not s then U.log("spawn %s failed: %s", gname, tostring(err)); return nil end
  return gname
end

-- ===========================================================================
-- 1. Tankers and drones
-- ===========================================================================
function B.spawnAsset(side, kind)
  local war = B.war
  if (war.state.airPool[side][kind] or 0) < 1 then return nil end
  local gname = string.format("DCC_%s_%s_%d", kind:upper(), side, (B.assetCount or 0) + 1)
  local spawned
  if kind == "tanker" then
    local p, hdg = B.awacsOrbit(side)
    if not p then return nil end
    local ax, az = math.cos(hdg or 0), math.sin(hdg or 0)
    local c = { x = p.x - ax * 40000, z = p.z - az * 40000 }           -- behind the AWACS
    local p1 = { x = c.x - az * 35000, z = c.z + ax * 35000 }
    local p2 = { x = c.x + az * 35000, z = c.z - ax * 35000 }
    local alt, spd = 7000, 200
    spawned = B.spawnFlight(side, "tanker", gname, p1, alt, spd, {
      wp(p1.x, p1.z, alt, spd, combo({ { id = "Tanker", params = {} },
        { id = "Orbit", params = { pattern = "Race-Track", point = { x = p1.x, y = p1.z },
          point2 = { x = p2.x, y = p2.z }, altitude = alt, speed = spd } } })),
      wp(p2.x, p2.z, alt, spd) }, { task = "Refueling", size = 1 })
  else
    -- drone: over the enemy base this side attacks (or its front)
    local f = war.state.focus and war.state.focus[side]
    local node = f and f.target
    if not node then return nil end
    local p, alt, spd = B.nodePos[node], 4500, 60
    spawned = B.spawnFlight(side, "drone", gname, { x = p.x - 15000, z = p.z }, alt, spd, {
      wp(p.x, p.z, alt, spd, combo({ { id = "Orbit", params = { pattern = "Circle", altitude = alt, speed = spd } } })) },
      { task = "Reconnaissance", size = 1 })
  end
  if not spawned then return nil end
  B.assetCount = (B.assetCount or 0) + 1
  war:airTake(side, kind, 1)
  war:setAsset(side, kind, true)
  B.assets[side][kind] = { group = gname, born = timer.getTime() }
  if kind == "tanker" then
    local u = unitsOf(gname)[1]
    local ctl = u and ok(u.getController, u) or (ok(Group.getByName, gname) and Group.getByName(gname):getController())
    local t = TACAN[side]
    if ctl then
      pcall(ctl.setCommand, ctl, { id = "ActivateBeacon", params = { type = 4, system = 4, callsign = t.cs,
        frequency = (1088 + t.ch - 1) * 1000000, AA = true, channel = t.ch, modeChannel = "X", bearing = true,
        unitId = u and ok(u.getID, u) } })
    end
    trigger.action.outTextForCoalition(B.COAL[side], string.format("Command: %s tanker on station, TACAN %dX.",
      side:upper(), t.ch), 10)
  end
  return gname
end

function B.pollAssets()
  local war = B.war
  for _, side in ipairs(SIDES) do
    for kind, rec in pairs(B.assets[side]) do
      local us = unitsOf(rec.group)
      if #us == 0 then
        war:assetLost(side, kind)
        B.assets[side][kind] = nil
      elseif not online() or timer.getTime() - rec.born > 4 * 3600 then
        local g = ok(Group.getByName, rec.group)
        if g then g:destroy() end
        local p = war.state.airPool[side]
        p[kind] = math.min(AC().assetPoolMax[kind], (p[kind] or 0) + 1)
        war:setAsset(side, kind, false)
        B.assets[side][kind] = nil
      end
    end
  end
end

function B.planAssets()
  if not online() then return end
  for _, side in ipairs(SIDES) do
    for _, kind in ipairs({ "tanker", "drone" }) do
      if not B.assets[side][kind] then B.spawnAsset(side, kind) end
    end
  end
end

-- Drones see enemy ground units below them (within 8 km).
function B.scanDrones(idx)
  for _, side in ipairs(SIDES) do
    local rec = B.assets[side].drone
    local d = rec and unitsOf(rec.group)[1]
    if d then
      local dp = d:getPoint()
      for _, e in pairs(idx) do
        if e.side ~= side and not e.air then
          for _, u in ipairs(unitsOf(e.group)) do
            if dist2D(u:getPoint(), dp) <= 8000 then B.report(side, e, u, "sensor"); break end
          end
        end
      end
    end
  end
end

-- ===========================================================================
-- 2. Packages: strike and helicopter assault
-- ===========================================================================
function B.launchStrike(side)
  local war = B.war
  local t = war:pickStrikeTarget(side)
  if not t then return nil end
  if not war:airAvailable(side, "attack", 2) or not war:airAvailable(side, "fighter", 2) then return nil end
  local pk = war:packageLaunched(side, "strike", t)
  if not pk then return nil end
  local tp = B.nodePos[t.node]
  local strike = B.spawnSortie(side, "attack", "STRIKE", tp, { node = t.node, life = 3600,
    task = { { id = "Bombing", params = { point = { x = tp.x, y = tp.z }, expend = "All", attackQty = 1,
      groupAttack = true } } } })
  local escort = B.spawnSortie(side, "fighter", "ESCORT", tp, { node = t.node, life = 3600,
    task = { { id = "EngageTargets", params = { targetTypes = { "Air" }, priority = 0, maxDist = 40000 } },
             { id = "Orbit", params = { pattern = "Circle", altitude = 7000, speed = 220 } } } })
  local sead
  if t.kind == "sam" or (war.state.nodes[t.node].sam and war.state.nodes[t.node].sam.status == "up") then
    sead = B.spawnSortie(side, "attack", "SEAD", tp, { node = t.node, template = "sead", life = 3600,
      task = { { id = "EngageTargets", params = { targetTypes = { "Air Defence" }, priority = 0, maxDist = 60000 } },
               { id = "Orbit", params = { pattern = "Circle", altitude = 6000, speed = 220 } } } })
  end
  if not strike then war:packageDestroyed(pk.id); return nil end
  for _, g in ipairs({ strike, escort, sead }) do if B.sorties[g] then B.sorties[g].pkg = pk.id end end
  B.packages[pk.id] = { strike = strike, escort = escort, sead = sead, target = tp, kind = "strike" }
  return pk
end

function B.launchAirAssault(side)
  local war = B.war
  local t = war:pickAirAssault(side, AC().airAssaultKm)
  if not t then return nil end
  local pk = war:packageLaunched(side, "airmobile", t.to, t.from)
  if not pk then return nil end
  local a, b = B.nodePos[t.from], B.nodePos[t.to]
  local gname = "DCC_AIRASSAULT_" .. pk.id
  local landing = { x = b.x + 600, z = b.z + 600 }
  local g = B.spawnFlight(side, "airmobile", gname, { x = a.x, z = a.z }, 150, 60, {
    wp(a.x, a.z, 150, 60),
    wp(landing.x, landing.z, 0, 50, combo({ { id = "Land", params = { point = { x = landing.x, y = landing.z },
      durationFlag = true, duration = 600 } } })) }, { helicopter = true, task = "Transport" })
  if not g then war:packageDestroyed(pk.id); return nil end
  B.packages[pk.id] = { strike = gname, target = b, kind = "airmobile", landing = landing }
  return pk
end

function B.pollPackages()
  local war = B.war
  for id, rec in pairs(B.packages) do
    local pk = war.state.packages[id]
    if not pk or pk.status ~= "inbound" then
      B.packages[id] = nil
    else
      local us = unitsOf(rec.strike)
      if #us == 0 then
        war:packageDestroyed(id)
        B.packages[id] = nil
      else
        for _, u in ipairs(us) do
          local p = u:getPoint()
          local reached
          if rec.kind == "airmobile" then
            reached = dist2D(p, rec.landing) <= 1500 and (p.y - ground(p)) < 60
          else
            reached = dist2D(p, rec.target) <= 6000
          end
          if reached then
            war:packageArrived(id)
            if rec.kind == "airmobile" then
              local g = ok(Group.getByName, rec.strike)
              -- the helicopters fly home empty: leave them in the sky for a while, then remove
              timer.scheduleFunction(function() if g and ok(g.isExist, g) then g:destroy() end end, nil, timer.getTime() + 600)
            end
            B.packages[id] = nil
            break
          end
        end
      end
    end
  end
end

function B.planPackages()
  if not online() then return end
  local war = B.war
  local per = DCC.config.tickSeconds / 60
  for _, side in ipairs(SIDES) do
    if war:aiAttackAllowed() and war.rng:next() < per / AC().packageMinutes then B.launchStrike(side) end
    if not war:isStorm() and war.rng:next() < per / AC().airAssaultMinutes then B.launchAirAssault(side) end
  end
end

-- ===========================================================================
-- 3. IADS: radar cueing and point defence
-- ===========================================================================
-- Does an own EWR / AWACS track this enemy aircraft?
function B.cued(side, u)
  for _, r in ipairs(B.radarsOf(side)) do
    if B.radarSees(r, u) then return true end
  end
  return false
end

local baseSpawnSam = B.spawnSam
function B.spawnSam(id)
  baseSpawnSam(id)
  local rec = B.sams[id]
  local spec = B.catalog.sam and B.catalog.sam[rec and rec.side or ""]
  if not rec or not spec or not spec.pointDefence then return end
  local c = B.nodePos[id]
  local units = {}
  for i, t in ipairs(spec.pointDefence) do
    if B.validType(t) then
      units[#units + 1] = { name = "DCC_SAMPD_" .. id .. "_" .. i, type = t, skill = "High",
        x = c.x + 900 * math.cos(i * 2.1), y = c.z + 900 * math.sin(i * 2.1), heading = 0, playerCanDrive = false }
    end
  end
  if #units == 0 then return end
  local gname = "DCC_SAMPD_" .. id
  if pcall(coalition.addGroup, B.countryId(rec.side), Group.Category.GROUND, { name = gname, task = "Ground Nothing",
      units = units, route = { points = { { x = units[1].x, y = units[1].y, type = "Turning Point",
      action = "Off Road", speed = 0, ETA = 0, ETA_locked = false } } } }) then
    rec.pd = gname
  end
end

local baseDespawnSam = B.despawnSam
function B.despawnSam(id)
  local rec = B.sams[id]
  if rec and rec.pd then
    local g = ok(Group.getByName, rec.pd)
    if g and ok(g.isExist, g) then g:destroy() end
  end
  baseDespawnSam(id)
end

-- ===========================================================================
-- 4. Forward CAP
-- ===========================================================================
local basePlanAir = B.planAir
function B.planAir()
  basePlanAir()
  local war = B.war
  if not online() or not AC().forwardCap then return end
  for _, side in ipairs(SIDES) do
    local f = war.state.focus and war.state.focus[otherSide(side)]
    local target = f and f.target
    if target and war.state.nodes[target].side == side then
      local busy = false
      for _, s in pairs(B.sorties) do if s.side == side and s.kind == "FWDCAP" then busy = true end end
      if not busy then
        local g = B.spawnSortie(side, "fighter", "CAP", B.nodePos[target], { node = target })
        if g and B.sorties[g] then
          B.sorties[g].kind = "FWDCAP"
          trigger.action.outTextForCoalition(B.COAL[side], string.format(
            "Command: fighters to cover %s - the enemy is massing for an attack there.", war:nodeName(target)), 10)
        end
      end
    end
  end
end

-- ===========================================================================
-- 5. Credit on landing, 6. cooldown
-- ===========================================================================
local function playerByKey(key)
  for uname, p in pairs(B.players) do if p.key == key then return p, uname end end
end

local baseDone = B.onMissionDone
function B.onMissionDone(m, outcome)
  if outcome ~= "done" or not AC().creditOnLanding then return baseDone(m, outcome) end
  -- pilots still in the air: their points wait for the landing (everything else - messages,
  -- photo reports - happens as usual)
  local held = {}
  for key in pairs(m.taken) do
    local p, uname = playerByKey(key)
    local u = uname and ok(Unit.getByName, uname)
    if p and alive(u) and ok(u.inAir, u) then held[key] = p end
  end
  local pilots = DCC.pilots
  local realMission = pilots.mission
  pilots.mission = function(self, key, mtype, name)
    local p = held[key]
    if p then
      p.pendingCredit = p.pendingCredit or {}
      table.insert(p.pendingCredit, { type = mtype, label = m.label })
      return
    end
    return realMission(self, key, mtype, name)
  end
  local okD, err = pcall(baseDone, m, outcome)
  pilots.mission = realMission
  if not okD then error(err) end
  for _, p in pairs(held) do
    trigger.action.outTextForGroup(p.gid, "Land at a friendly base (or your carrier) to log the mission points.", 15)
  end
end

-- landed at a friendly base: log the held missions
function B.creditLanding(u)
  local p = B.players[ok(u.getName, u) or ""]
  if not p or not p.pendingCredit then return end
  local id = B.nearestNode(u:getPoint(), 5000)
  local onCarrier = false
  for _, rec in pairs(B.naval or {}) do
    local cv = unitsOf(rec.group)[1]
    if cv and dist2D(cv:getPoint(), u:getPoint()) < 500 and rec.side == p.side then onCarrier = true end
  end
  if not onCarrier and not (id and B.war.state.nodes[id].side == p.side) then return end
  for _, c in ipairs(p.pendingCredit) do DCC.pilots:mission(p.key, c.type, p.name) end
  trigger.action.outTextForGroup(p.gid, string.format("Welcome back. %d mission(s) logged.", #p.pendingCredit), 15)
  p.pendingCredit = nil
end

function B.recordDeath(key)
  local list = B.deaths[key] or {}
  list[#list + 1] = timer.getTime()
  B.deaths[key] = list
end

-- Minutes this pilot is still grounded from fast jets (0 = free to fly).
function B.groundedFor(key)
  local list, now, cfg = B.deaths[key] or {}, timer.getTime(), AC()
  local recent = {}
  for _, t in ipairs(list) do if now - t <= cfg.cooldownWindowMin * 60 then recent[#recent + 1] = t end end
  B.deaths[key] = recent
  if #recent < cfg.cooldownDeaths then return 0 end
  local left = cfg.cooldownMin * 60 - (now - recent[#recent])
  return left > 0 and math.ceil(left / 60) or 0
end

local function keyOf(u)
  local name = ok(u.getPlayerName, u)
  if not name then return nil end
  local p = B.players[ok(u.getName, u) or ""]
  if p then return p.key end
  for _, pl in pairs(DCC.pilots.data.pilots) do if pl.name == name then return name end end
  return name
end

local baseOnBirth = B.onBirth
function B.onBirth(unit)
  baseOnBirth(unit)
  if not alive(unit) then return end
  local desc = ok(unit.getDesc, unit)
  if not desc or desc.category ~= Unit.Category.AIRPLANE then return end
  local key = keyOf(unit)
  local mins = key and B.groundedFor(key) or 0
  if mins > 0 then
    trigger.action.outTextForUnit(unit:getID(), string.format(
      "Grounded: two losses within the hour. Fast jets again in %d min - helicopters are fine.", mins), 20)
    pcall(function() unit:destroy() end)
  end
end

local baseOpsEvent = B.onOpsEvent
function B.onOpsEvent(e)
  local ev, u = world.event, e.initiator
  if e.id == ev.S_EVENT_PILOT_DEAD or e.id == ev.S_EVENT_EJECTION then
    local p = u and B.players[ok(u.getName, u) or ""]
    if p then
      p.pendingCredit = nil            -- did not make it home
      if e.id == ev.S_EVENT_PILOT_DEAD then B.recordDeath(p.key) end
    end
  elseif e.id == ev.S_EVENT_LAND and u then
    B.creditLanding(u)
  end
  baseOpsEvent(e)
end

-- ===========================================================================
-- Intel, mission positions, hooks
-- ===========================================================================
local baseIndex = B.intelIndex
function B.intelIndex()
  local idx = baseIndex()
  for _, side in ipairs(SIDES) do
    for kind, rec in pairs(B.assets[side]) do
      idx[rec.group] = { side = side, kind = "air", air = true, group = rec.group, asset = kind }
    end
  end
  for id, rec in pairs(B.packages) do
    if rec.kind == "airmobile" then
      idx[rec.strike] = { side = B.war.state.packages[id] and B.war.state.packages[id].side, kind = "air", air = true,
                          group = rec.strike, pkg = id }
    end
  end
  for gname, s in pairs(B.sorties) do
    if s.pkg and idx[gname] then idx[gname].pkg = s.pkg end
  end
  return idx
end

local baseReport = B.report
function B.report(side, e, u, source)
  if e and e.side == side then return end
  baseReport(side, e, u, source)
  if e and e.pkg then
    B.war:addContact(side, "pkg:" .. e.pkg, { kind = "package", source = source, label = "strike package" })
  end
  if e and e.asset == "tanker" then
    local p = u:getPoint()
    B.war:addContact(side, "tanker:" .. e.side, { kind = "tanker", source = source, pos = { x = p.x, z = p.z },
      label = e.side:upper() .. " tanker" })
  end
end

local baseScan = B.intelScan
function B.intelScan()
  baseScan()
  if B.war.fogOfWar then B.scanDrones(B.intelIndex()) end
end

local baseMissionPos = B.missionPos
function B.missionPos(m)
  if m.type == "INTERCEPT" then
    local rec = B.packages[m.target]
    local u = rec and unitsOf(rec.strike)[1]
    if u then return u:getPoint() end
    local crec = B.cargo[m.target]                      -- an enemy airlift / supply helicopters
    u = crec and unitsOf(crec.group)[1]
    if u then return u:getPoint() end
  elseif m.type == "TANKER" then
    local rec = B.assets[m.target] and B.assets[m.target].tanker
    local u = rec and unitsOf(rec.group)[1]
    if u then return u:getPoint() end
  end
  return baseMissionPos(m)
end

local basePoll = B.opsPoll
function B.opsPoll()
  basePoll()
  B.pollAssets()
  B.pollPackages()
end

local baseTick = B.opsTick
function B.opsTick()
  baseTick()
  B.planAssets()
  B.planPackages()
end

local baseInit = B.init
function B.init(war, theater, catalog)
  baseInit(war, theater, catalog)
  B.assets, B.packages = { blue = {}, red = {} }, {}
  -- assets and packages from before a restart are not in the sky any more
  for _, side in ipairs(SIDES) do
    for kind in pairs(war.state.assets[side]) do
      war:setAsset(side, kind, false)
      local p = war.state.airPool[side]
      p[kind] = math.min(AC().assetPoolMax[kind], (p[kind] or 0) + 1)
    end
  end
  for id, pk in pairs(war.state.packages) do
    if pk.status == "inbound" then
      if pk.platoon and war.state.carried[pk.platoon] then
        -- the troops never left: back to their base
        war.state.carried[pk.platoon] = { from = pk.from, by = "ai" }
        war:returnCarried(pk.platoon)
      end
      war.state.packages[id] = nil
    end
  end
end

-- ===========================================================================
-- Helicopter supply runs (war moves with mv.helo): real AI transport
-- helicopters (the airmobile template), low level, landing at the base.
-- Escort them (ESCORT, any aircraft) - the enemy AI and players can shoot
-- them down. On landing the cargo is set down (as CTLD crates when CTLD is
-- in the mission) and the helicopters lift off home a few minutes later.
-- ===========================================================================
local baseSpawnAirlift = B.spawnAirlift
function B.spawnAirlift(mv)
  if not mv.helo then return baseSpawnAirlift(mv) end
  local a, b = B.nodePos[mv.from], B.nodePos[mv.to]
  local p = U.clamp(mv.progress, 0, 0.95)
  local x, z = a.x + (b.x - a.x) * p, a.z + (b.z - a.z) * p
  local landing = { x = b.x + 350, z = b.z + 350 }
  local speed = DCC.config.supply.heliliftSpeedKmh / 3.6
  local gname = "DCC_" .. mv.id
  local g = B.spawnFlight(mv.side, "airmobile", gname, { x = x, z = z }, 150, speed, {
    wp(x, z, 150, speed),
    wp(landing.x, landing.z, 0, speed, combo({ { id = "Land", params = { point = { x = landing.x, y = landing.z },
      durationFlag = true, duration = 900 } } })) }, { helicopter = true, task = "Transport" })
  local n = g and #(unitsOf(gname)) or 1
  B.cargo[mv.id] = { group = gname, size = math.max(1, n), base = mv.health or 1, kind = "airlift", helo = true,
                     landing = landing, side = mv.side, failed = g == nil, born = timer.getTime() }
end

local baseDespawn = B.despawnCargo
function B.despawnCargo(mid, rec)
  local war = B.war
  local delivered = rec.helo and war.state.deliveredMoves and war.state.deliveredMoves[mid]
  if not delivered then return baseDespawn(mid, rec) end
  -- landed and unloaded: crates on the ground, helicopters stay a while, then go
  B.cargo[mid] = nil
  local lead = unitsOf(rec.group)[1]
  local pos = lead and ok(lead.getPoint, lead) or rec.landing
  ok(B.heliCargoDown, rec.side, pos, war.cfg.supply.heliliftCapacity)
  timer.scheduleFunction(function()
    local g = ok(Group.getByName, rec.group)
    if g and ok(g.isExist, g) then g:destroy() end
  end, nil, timer.getTime() + 180)
end

-- The cargo, set down next to the helicopter: one crate per 10 SU (scenery -
-- the supply is already in the base's stock).
function B.heliCargoDown(side, pos, su)
  local names = {}
  B.heliCrateN = (B.heliCrateN or 0) + 1
  for i = 1, math.max(1, math.min(4, math.floor(su / 10))) do
    local name = string.format("DCC_HELICARGO_%d_%d", B.heliCrateN, i)
    local s = pcall(coalition.addStaticObject, B.countryId(side), { name = name, type = "ammo_cargo",
      category = "Cargos", x = pos.x + 25 + i * 6, y = pos.z + 20, heading = 0, canCargo = false, mass = 1000 })
    if s then names[#names + 1] = name end
  end
  timer.scheduleFunction(function()
    for _, n in ipairs(names) do
      local o = ok(StaticObject.getByName, n)
      if o and ok(o.isExist, o) then o:destroy() end
    end
  end, nil, timer.getTime() + DCC.config.supply.heliCargoMinutes * 60)
  return names
end

B.EFFECT.INTERCEPT = "Shoot them down before they get there. A package or air assault stopped does no harm; "
  .. "an airlift or supply helicopters shot down lose their supply. \"My mission\" gives its latest position."
