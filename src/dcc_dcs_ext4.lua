-- ============================================================================
-- Danica Dynamic Campaign - DCS bridge: Combined Arms, QRA, engineers and the
-- performance guard (v0.27). Load after dcc_dcs_ext3.lua.
-- ----------------------------------------------------------------------------
--   6. Combined Arms : campaign platoons, supply convoys, artillery and
--                      skirmish groups can be driven by CA commanders / JTACs
--                      (slots come from make_mission.py). A player in a ground
--                      vehicle is never slot-guarded and gets ground missions
--                      (ASSAULT, HOLD, GCONVOY, v0.28): credit for being there.
--   7. QRA           : a new INTERCEPT scrambles that side's grounded fighter
--                      pilots (heading and range to the threat). Airborne
--                      within 5 min = the mission is theirs, +10 QRA bonus
--                      when it is done.
--  15. Engineers     : CTLD > Engineering > Repair kit (any lift helicopter,
--                      20 SU) set down at an own base: one building, the SAM
--                      or the EWR is repaired at once.
--  16. Performance   : counts the ground units in DCS every minute; above 700
--                      / 1000 the live radius, live platoons, skirmishes and
--                      pop-ups shrink; back to normal when the load drops.
-- ============================================================================

DCC = DCC or {}
local B = DCC.dcs
local U = DCC.util

local function XC() return DCC.config.ext4 end
local function ok(fn, ...) local s, r = pcall(fn, ...); if s then return r end end
local function alive(u) return u ~= nil and ok(u.isExist, u) == true and (ok(u.getLife, u) or 0) >= 1 end
local function dist2D(a, b)
  local dx, dz = a.x - b.x, a.z - b.z
  return math.sqrt(dx * dx + dz * dz)
end
local function sideOfCoal(c) return c == 2 and "blue" or (c == 1 and "red" or nil) end
local function isGroundUnit(u)
  local d = u and ok(u.getDesc, u)
  return d ~= nil and Unit and Unit.Category and d.category == Unit.Category.GROUND_UNIT
end

local function fresh() return { qraSeen = {}, qraCrew = {}, perfLevel = 0, perfBase = nil, perfNext = 0 } end
B.x4 = fresh()

-- ===========================================================================
-- 6. Combined Arms
-- ===========================================================================
function B.caDrivable(name)
  if type(name) ~= "string" then return false end
  for _, pat in ipairs(XC().ca.patterns or {}) do
    if name:find(pat) then return true end
  end
  return false
end

if coalition and coalition.addGroup and not coalition.dccCA then
  local rawAdd = coalition.addGroup
  coalition.addGroup = function(country, category, data)
    if XC().ca.playerCanDrive and Group and category == Group.Category.GROUND and type(data) == "table"
       and B.caDrivable(data.name) then
      for _, u in ipairs(data.units or {}) do u.playerCanDrive = true end
    end
    return rawAdd(country, category, data)
  end
  coalition.dccCA = true
end

-- A CA player taking over a vehicle is not slot-guarded (the tank may be
-- attacking an enemy base).
local baseOnBirth = B.onBirth
function B.onBirth(unit)
  if isGroundUnit(unit) then return end
  return baseOnBirth(unit)
end

-- ...and is a "ground player": the Missions menu shows only ground missions
-- (ASSAULT, HOLD, GCONVOY) within ext4.ground.rangeKm of the vehicle.
local baseRegister = B.registerPlayer
function B.registerPlayer(u)
  local p = baseRegister(u)
  if p and isGroundUnit(u) then
    p.ground, p.heli, p.slow = true, false, false
    B.buildMenu(p)
    if B.buildSupportMenu then B.buildSupportMenu(p) end
  end
  return p
end

local baseCaps = B.caps
function B.caps(p)
  if p and p.ground then return { GROUND = true } end
  return baseCaps(p)
end

local baseCanFly = B.canFly
function B.canFly(p, m)
  if p and p.ground then return m.needs == "GROUND" end
  return baseCanFly(p, m)
end

local baseMissionsFor = B.missionsFor
function B.missionsFor(p)
  if not (p and p.ground) then return baseMissionsFor(p) end
  local u = ok(Unit.getByName, p.unit)
  local here = alive(u) and u:getPoint() or p.spawn
  local range = XC().ground.rangeKm * 1000
  local list = {}
  for _, m in ipairs(B.war:openMissions(p.side)) do
    if m.needs == "GROUND" then
      local pos = B.missionPos(m)
      local d = (pos and here) and dist2D(pos, here) or math.huge
      if d <= range then list[#list + 1] = { m = m, d = d } end
    end
  end
  table.sort(list, function(a, b) return a.d < b.d end)
  local out = {}
  for _, e in ipairs(list) do
    out[#out + 1] = setmetatable({ _nm = math.floor(e.d / 1852 + 0.5) }, { __index = e.m })
  end
  return out
end

local baseMissionPos = B.missionPos
function B.missionPos(m)
  if m.type == "GCONVOY" then return baseMissionPos({ type = "CONVOY", target = m.target }) end
  return baseMissionPos(m)
end

if B.EFFECT then
  B.EFFECT.ASSAULT = "Drive with the attack and take the base. Be within 5 km of it for 5 min to get the credit."
  B.EFFECT.HOLD = "Hold the base until the attack breaks. Be within 5 km of it for 5 min to get the credit."
  B.EFFECT.GCONVOY = "Escort the supply convoy by road until it arrives. Stay within 5 km of it for 5 min for the credit."
end

-- Fire support for ground players (v0.29): the same artillery as the pilots'
-- Support menu (rank, 10 min cooldown per side, 10 SU from a battery within
-- 35 km), aimed without a map mark: the nearest enemy in sight, or the base of
-- the ground mission. Never within dangerCloseM of the caller.
local function enemyInSight(p, u)
  local here = u:getPoint()
  local eye = { x = here.x, y = here.y + 2.5, z = here.z }
  local enemyCoal = p.side == "blue" and 1 or 2
  local best, bestD
  for _, g in ipairs(ok(coalition.getGroups, enemyCoal, Group.Category.GROUND) or {}) do
    for _, e in ipairs(ok(g.getUnits, g) or {}) do
      if alive(e) then
        local ep = e:getPoint()
        local d = dist2D(here, ep)
        if d <= XC().ground.artyKm * 1000 and (not bestD or d < bestD) then
          local seen = ok(land.isVisible, eye, { x = ep.x, y = ep.y + 1.5, z = ep.z })
          if seen ~= false then best, bestD = ep, d end
        end
      end
    end
  end
  return best, bestD
end

function B.groundFire(uname, how)
  local p = B.players[uname]
  local u = p and ok(Unit.getByName, uname)
  if not (p and alive(u)) then return end
  local function tell(t) trigger.action.outTextForGroup(p.gid, t, 12) end
  local pos, what
  if how == "enemy" then
    local d
    pos, d = enemyInSight(p, u)
    if not pos then return tell(string.format("No enemy in sight within %d km.", XC().ground.artyKm)) end
    what = string.format("nearest enemy, %d m", math.floor(d / 10 + 0.5) * 10)
  else
    local m = p.mission and B.war.state.missions[p.mission]
    if not (m and m.status == "open" and m.needs == "GROUND") then
      return tell("Take a ground mission first (F10 > Missions).")
    end
    pos = B.missionPos(m)
    if not pos then return tell("The objective cannot be located right now.") end
    what = m.type .. " " .. m.label
  end
  if dist2D(u:getPoint(), pos) < XC().ground.dangerCloseM then
    return tell("Danger close - the target is too near you. Pull back first.")
  end
  tell("Fire mission: " .. what .. ".")
  local realMark, ranks = B.newestMark, DCC.config.ext.ranks
  local realRank = ranks.arty
  B.newestMark = function() return { pos = { x = pos.x, y = 0, z = pos.z }, t = timer.getTime(), by = uname } end
  ranks.arty = XC().ground.artyRank           -- nil: tank crews need no rank for their own fire missions
  local s, err = pcall(B.callArtillery, uname)
  B.newestMark, ranks.arty = realMark, realRank
  if not s then U.log("ERROR ground fire mission: %s", tostring(err)) end
end

-- Smoke screen (v0.30): a battery within artyRangeKm fires smoke rounds that
-- build a curtain smokeAheadM in front of the vehicle, across its heading.
-- Cheap (smokeSU) and on its own cooldown per player, not the side's guns.
local function forwardOf(u, p)
  local pos = ok(u.getPosition, u)
  if pos and pos.x and (pos.x.x ~= 0 or pos.x.z ~= 0) then
    local l = math.sqrt(pos.x.x ^ 2 + pos.x.z ^ 2)
    return { x = pos.x.x / l, z = pos.x.z / l }
  end
  local here, tgt = u:getPoint(), enemyInSight(p, u)        -- no heading: toward the enemy, else north
  if tgt then
    local d = math.max(1, dist2D(here, tgt))
    return { x = (tgt.x - here.x) / d, z = (tgt.z - here.z) / d }
  end
  return { x = 1, z = 0 }
end

-- A curtain of smoke rounds centred on c, across direction f (unit vector).
function B.smokeCurtain(c, f)
  local gc, now = XC().ground, timer.getTime()
  B.x4.smokeN = (B.x4.smokeN or 0) + 1
  local n, w = gc.smokeRounds, gc.smokeWidthM
  local names = {}
  for i = 1, n do
    local off = (n == 1) and 0 or (-w / 2 + w * (i - 1) / (n - 1))
    local x, z = c.x - f.z * off, c.z + f.x * off                 -- across the heading
    local pt = { x = x, y = ok(land.getHeight, { x = x, y = z }) or 0, z = z }
    local name = string.format("DCC_SMOKE_%d_%d", B.x4.smokeN, i)
    names[#names + 1] = name
    timer.scheduleFunction(function()
      ok(trigger.action.explosion, pt, 2)                            -- the shell bursting
      ok(trigger.action.effectSmokeBig, pt, gc.smokePreset, 0.6, name)
    end, nil, now + 20 + i * 2)
  end
  timer.scheduleFunction(function()
    for _, name in ipairs(names) do ok(trigger.action.effectSmokeStop, name) end
  end, nil, now + 20 + gc.smokeMinutes * 60)
end

-- A battery of side within artillery range of c that can pay, or nil.
local function smokeBattery(side, c, su)
  local war, range = B.war, DCC.config.ext.support.artyRangeKm * 1000
  for _, b in ipairs(war:batteries(side) or {}) do
    if b.status == "up" and b.node and B.nodePos[b.node] and dist2D(B.nodePos[b.node], c) <= range
       and war:paySupport(b.node, su) then return b end
  end
end

-- AI smoke (v0.30): an attack in the live bubble lays a curtain between its lead
-- vehicles and the base once they are within withinKm, again every everyMin.
function B.aiSmokeTick()
  local cfg, gc, war = XC().aiSmoke, XC().ground, B.war
  if not (cfg and cfg.enabled and war) then return end
  local now = timer.getTime()
  B.x4.aiSmoke = B.x4.aiSmoke or {}
  for _, mid in ipairs(U.sortedKeys(war.state.moves)) do
    local mv = war.state.moves[mid]
    local np = B.nodePos[mv.to]
    if mv.kind == "assault" and np and (B.liveNodes[mv.to] or B.liveNodes[mv.from])
       and now - (B.x4.aiSmoke[mid] or -math.huge) >= cfg.everyMin * 60 then
      local lead
      for _, pid in ipairs(mv.platoons or {}) do
        local rec = B.spawned[pid]
        local g = rec and ok(Group.getByName, rec.group)
        for _, u in ipairs(g and ok(g.getUnits, g) or {}) do
          if alive(u) then
            local d = dist2D(u:getPoint(), np)
            if d <= cfg.withinKm * 1000 and (not lead or d < lead.d) then lead = { p = u:getPoint(), d = d } end
          end
        end
      end
      if lead and lead.d > gc.dangerCloseM then
        local f = { x = (np.x - lead.p.x) / lead.d, z = (np.z - lead.p.z) / lead.d }
        local ahead = math.min(gc.smokeAheadM, lead.d / 2)
        local c = { x = lead.p.x + f.x * ahead, z = lead.p.z + f.z * ahead }
        if smokeBattery(mv.side, c, gc.smokeSU) then
          B.x4.aiSmoke[mid] = now
          B.smokeCurtain(c, f)
          U.log("AI smoke: %s attack on %s", mv.side, tostring(mv.to))
        end
      end
    end
  end
  for mid in pairs(B.x4.aiSmoke) do if not war.state.moves[mid] then B.x4.aiSmoke[mid] = nil end end
end

-- Defender smoke (v0.32): a live garrison screens itself with its own smoke
-- grenades (free, no battery) when an enemy attack's lead vehicles are within
-- defendKm, or an enemy aircraft is within airKm and below airMaxAltM. The
-- curtain goes defendOffsetM out from the base, toward the threat.
-- Only aircraft that attack set it off (v0.33): one that fired in the last
-- shotSec seconds, or one diving at the base (sinking faster than diveMps while
-- flying toward it).
function B.isAttacking(u, np, d)
  local cfg = XC().aiSmoke
  local name = ok(u.getName, u)
  local t = name and (B.x4.shots or {})[name]
  if t and timer.getTime() - t <= cfg.shotSec then return true end
  local v = ok(u.getVelocity, u)
  if not (v and v.y) then return false end
  local h = math.sqrt(v.x * v.x + v.z * v.z)
  if v.y > -cfg.diveMps or h < 1 then return false end
  local up = u:getPoint()
  local tx, tz = (np.x - up.x) / math.max(d, 1), (np.z - up.z) / math.max(d, 1)
  return (v.x * tx + v.z * tz) / h >= 0.7                  -- heading within ~45 deg of the base
end

local function enemyAircraftNear(side, np, cfg)
  local coal = side == "blue" and 1 or 2
  local best
  for _, cat in ipairs({ Group.Category.AIRPLANE, Group.Category.HELICOPTER }) do
    for _, g in ipairs(ok(coalition.getGroups, coal, cat) or {}) do
      for _, u in ipairs(ok(g.getUnits, g) or {}) do
        if alive(u) and ok(u.inAir, u) then
          local up = u:getPoint()
          local agl = up.y - (ok(land.getHeight, { x = up.x, y = up.z }) or 0)
          local d = dist2D(up, np)
          if d <= cfg.airKm * 1000 and agl <= cfg.airMaxAltM and (not best or d < best.d)
             and B.isAttacking(u, np, d) then
            best = { p = up, d = d }
          end
        end
      end
    end
  end
  return best
end

local function enemyLeadNear(side, id, np, km)
  local best
  for _, mv in pairs(B.war.state.moves) do
    if mv.kind == "assault" and mv.to == id and mv.side ~= side then
      for _, pid in ipairs(mv.platoons or {}) do
        local rec = B.spawned[pid]
        local g = rec and ok(Group.getByName, rec.group)
        for _, u in ipairs(g and ok(g.getUnits, g) or {}) do
          if alive(u) then
            local d = dist2D(u:getPoint(), np)
            if d <= km * 1000 and (not best or d < best.d) then best = { p = u:getPoint(), d = d } end
          end
        end
      end
    end
  end
  return best
end

function B.defenseSmokeTick()
  local cfg, war = XC().aiSmoke, B.war
  if not (cfg and cfg.enabled and cfg.defend and war) then return end
  local now = timer.getTime()
  B.x4.defSmoke = B.x4.defSmoke or {}
  for _, id in ipairs(war.T.order) do
    local ns, np = war.state.nodes[id], B.nodePos[id]
    if np and B.liveNodes[id] and #ns.platoons > 0
       and now - (B.x4.defSmoke[id] or -math.huge) >= cfg.defendEveryMin * 60 then
      local threat, why = enemyLeadNear(ns.side, id, np, cfg.defendKm), "attack"
      if not threat then threat, why = enemyAircraftNear(ns.side, np, cfg), "aircraft" end
      if threat and threat.d > 1 then
        local f = { x = (threat.p.x - np.x) / threat.d, z = (threat.p.z - np.z) / threat.d }
        local off = math.min(cfg.defendOffsetM, threat.d / 2)
        B.x4.defSmoke[id] = now
        B.smokeCurtain({ x = np.x + f.x * off, z = np.z + f.z * off }, f)
        U.log("defender smoke at %s (%s)", id, why)
      end
    end
  end
end

function B.groundSmoke(uname)
  local p = B.players[uname]
  local u = p and ok(Unit.getByName, uname)
  if not (p and alive(u)) then return end
  local function tell(t) trigger.action.outTextForGroup(p.gid, t, 12) end
  local gc, war = XC().ground, B.war
  local now = timer.getTime()
  B.x4.smokeAt = B.x4.smokeAt or {}
  local left = (B.x4.smokeAt[p.key] or -math.huge) + gc.smokeCooldownMin * 60 - now
  if left > 0 then return tell(string.format("Smoke rounds reloading - %d min.", math.ceil(left / 60))) end
  local here, f = u:getPoint(), forwardOf(u, p)
  local c = { x = here.x + f.x * gc.smokeAheadM, z = here.z + f.z * gc.smokeAheadM }
  local battery = smokeBattery(p.side, c, gc.smokeSU)
  if not battery then
    return tell(string.format("No battery with supply within %d km for smoke.", DCC.config.ext.support.artyRangeKm))
  end
  B.x4.smokeAt[p.key] = now
  B.smokeCurtain(c, f)
  tell(string.format("Smoke screen %d m ahead from %s - rounds on the way, curtain in 20 s for %d min.",
    gc.smokeAheadM, war:nodeName(battery.node), gc.smokeMinutes))
end

if B.buildSupportMenu then
  local baseSupportMenu = B.buildSupportMenu
  function B.buildSupportMenu(p)
    if not (p and p.ground) then return baseSupportMenu(p) end
    if not p.gid then return end
    if p.supportMenu then ok(missionCommands.removeItemForGroup, p.gid, p.supportMenu) end
    local root = missionCommands.addSubMenuForGroup(p.gid, "Support")
    p.supportMenu = root
    missionCommands.addCommandForGroup(p.gid, "Artillery on the nearest enemy in sight", root,
      function(uname) B.groundFire(uname, "enemy") end, p.unit)
    missionCommands.addCommandForGroup(p.gid, "Artillery on my objective", root,
      function(uname) B.groundFire(uname, "objective") end, p.unit)
    missionCommands.addCommandForGroup(p.gid, "Smoke screen ahead", root, B.groundSmoke, p.unit)
    if B.callArtillery then missionCommands.addCommandForGroup(p.gid, "Artillery on my map mark", root, B.callArtillery, p.unit) end
    if B.callCas then missionCommands.addCommandForGroup(p.gid, "CAS pair on my map mark", root, B.callCas, p.unit) end
    if B.callIllumination then
      missionCommands.addCommandForGroup(p.gid, "Illumination on my map mark", root, B.callIllumination, p.unit)
    end
  end
end

-- Who was there: one sample per poll for every ground player on a ground mission.
function B.groundPresenceTick()
  local now = timer.getTime()
  local dt = now - (B.x4.presenceAt or now)
  B.x4.presenceAt = now
  if dt <= 0 then return end
  local km = XC().ground.presenceKm * 1000
  for _, p in pairs(B.players or {}) do
    local m = p.ground and p.mission and B.war.state.missions[p.mission]
    local u = m and ok(Unit.getByName, p.unit)
    if m and m.status == "open" and alive(u) then
      local pos = B.missionPos(m)
      if pos and dist2D(u:getPoint(), pos) <= km then B.war:groundPresence(m.id, p.key, dt) end
    end
  end
end

-- A platoon a player is driving stays spawned, wherever he takes it.
local baseUpdateLive = B.updateLive
function B.updateLive()
  baseUpdateLive()
  local st = B.war.state
  for _, p in pairs(B.players or {}) do
    local u = p.ground and ok(Unit.getByName, p.unit)
    local g = u and ok(u.getGroup, u)
    local pid = g and (ok(g.getName, g) or ""):match("^DCC_(p%d+)$")
    if pid then
      for _, id in ipairs(B.war.T.order) do
        for _, x in ipairs(st.nodes[id].platoons) do if x == pid then B.liveNodes[id] = true end end
      end
      for _, mv in pairs(st.moves) do
        for _, x in ipairs(mv.platoons or {}) do
          if x == pid then B.liveNodes[mv.from], B.liveNodes[mv.to] = true, true end
        end
      end
    end
  end
end

-- ===========================================================================
-- 7. Quick reaction alert
-- ===========================================================================
local function bearing(from, to)
  local deg = math.deg(math.atan2(to.z - from.z, to.x - from.x))   -- DCS: x north, z east
  return math.floor((deg % 360) + 0.5) % 360
end

function B.qraScan()
  local war, cfg = B.war, XC().qra
  if not (war and war.state.missions) then return end
  local now = timer.getTime()
  for _, mid in ipairs(U.sortedKeys(war.state.missions)) do
    local m = war.state.missions[mid]
    if m.type == "INTERCEPT" and m.status == "open" and not B.x4.qraSeen[mid] then
      B.x4.qraSeen[mid] = true
      local tp = B.missionPos(m)
      if tp then
        for _, p in pairs(B.players or {}) do
          local u = ok(Unit.getByName, p.unit)
          if p.side == m.side and not p.mission and not p.heli and alive(u) and not ok(u.inAir, u)
             and B.canFly(p, m) then
            local up = u:getPoint()
            local d = dist2D(up, tp)
            if d <= cfg.km * 1000 then
              p.qra = { mid = mid, t = now }
              trigger.action.outTextForGroup(p.gid, string.format(
                "QRA - SCRAMBLE! %s.\nIntercept heading %03d (true), %d nm.\nAirborne within %d min: the INTERCEPT is yours, +%d QRA bonus when it is done.",
                m.label, bearing(up, tp), math.floor(d / 1852 + 0.5), cfg.minutes, DCC.Pilots.POINTS.qra), 20)
            end
          end
        end
      end
    end
  end
  for mid in pairs(B.x4.qraSeen) do
    if not war.state.missions[mid] then B.x4.qraSeen[mid] = nil end
  end
end

function B.qraTakeoff(p)
  local q = p and p.qra
  if not q then return end
  p.qra = nil
  local m = B.war.state.missions[q.mid]
  if timer.getTime() - q.t > XC().qra.minutes * 60 or not m or m.status ~= "open" then return end
  if p.mission and p.mission ~= q.mid then return end
  if p.mission ~= q.mid then B.takeMission({ unit = p.unit, mid = q.mid }) end
  if p.mission == q.mid then
    B.x4.qraCrew[q.mid] = B.x4.qraCrew[q.mid] or {}
    B.x4.qraCrew[q.mid][p.key] = true
    trigger.action.outTextForGroup(p.gid, "QRA: airborne in time - the intercept is yours. Good hunting.", 12)
  end
end

local baseOpsEvent = B.onOpsEvent
function B.onOpsEvent(e)
  baseOpsEvent(e)
  if e.id == world.event.S_EVENT_SHOT and e.initiator then           -- who has fired (defender smoke)
    local d = ok(e.initiator.getDesc, e.initiator)
    if d and (d.category == Unit.Category.AIRPLANE or d.category == Unit.Category.HELICOPTER) then
      B.x4.shots = B.x4.shots or {}
      B.x4.shots[ok(e.initiator.getName, e.initiator) or "?"] = timer.getTime()
    end
  end
  -- a CA player taking over a vehicle that already exists (no birth event)
  if e.id == world.event.S_EVENT_PLAYER_ENTER_UNIT and e.initiator and isGroundUnit(e.initiator)
     and ok(e.initiator.getPlayerName, e.initiator) and not B.players[ok(e.initiator.getName, e.initiator) or ""] then
    B.registerPlayer(e.initiator)
  end
  if e.id == world.event.S_EVENT_TAKEOFF and e.initiator then
    local p = B.players[ok(e.initiator.getName, e.initiator) or ""]
    if p then B.qraTakeoff(p) end
  end
end

local baseDone = B.onMissionDone
function B.onMissionDone(m, outcome)
  local crew = B.x4.qraCrew[m.id]
  B.x4.qraCrew[m.id] = nil
  if crew and outcome == "done" then
    for key in pairs(crew) do
      local name = m.taken and m.taken[key]
      if name then
        DCC.pilots:add(key, "qra", 1, name)
        for _, p in pairs(B.players) do
          if p.key == key then
            trigger.action.outTextForGroup(p.gid, string.format("QRA bonus: +%d.", DCC.Pilots.POINTS.qra), 12)
          end
        end
      end
    end
  end
  return baseDone(m, outcome)
end

-- ===========================================================================
-- 15. Engineer repair kit
-- ===========================================================================
function B.repairDown(crate, pos, loud)
  local war = B.war
  local side = sideOfCoal(crate.coalition)
  local function tell(text) if loud then trigger.action.outTextForCoalition(crate.coalition, text, 12) end end
  pos = pos or crate.position
  if not (war and side and pos) then return false end
  local km = XC().repair.km
  local best, bestD
  for _, id in ipairs(war.T.order) do
    local np = B.nodePos[id]
    if np and war.state.nodes[id].side == side then
      local d = dist2D(pos, np)
      if d <= km * 1000 and (not bestD or d < bestD) then best, bestD = id, d end
    end
  end
  if not best then tell(string.format("A repair kit goes down within %d km of a friendly base.", km)); return false end
  if not war:repairNeed(best) then
    tell(string.format("Nothing to repair at %s - the kit stays on the ground for later.", war:nodeName(best)))
    return false
  end
  local text = war:engineerRepair(best, side)
  if not text then return false end
  tell(text .. ".")
  local cm = CTLDCrateManager and CTLDCrateManager.getInstance()
  if cm then ok(cm.destroyCrate, cm, crate.crateName) end
  if B.reconcileStatics then ok(B.reconcileStatics) end      -- the building / site is back at once
  if B.reconcileSams then ok(B.reconcileSams) end
  return true
end

if B.heavyDown then
  local baseHeavy = B.heavyDown
  function B.heavyDown(crate, pos, loud)
    if crate and crate.descriptor and crate.descriptor.dccHeavy == "repair" then
      return B.repairDown(crate, pos, loud)
    end
    return baseHeavy(crate, pos, loud)
  end
end

if B.ctldConfigure then
  local baseConfigure = B.ctldConfigure
  function B.ctldConfigure()
    baseConfigure()
    local crates = ctld.gs("spawnableCrates") or {}
    local list = crates["Engineering"] or {}
    local r = XC().repair
    list[#list + 1] = { unit = "DCC_REPAIRKIT", desc = "Repair kit (buildings, SAM, EWR)", weight = r.weight,
                        cratesRequired = 1, dccHeavy = "repair", dccCharge = r.charge }
    crates["Engineering"] = list
    CTLDConfig.get():setSetting("spawnableCrates", crates)
  end
end

-- ===========================================================================
-- 16. Performance guard
-- ===========================================================================
function B.groundUnitCount()
  if not (coalition and coalition.getGroups and Group) then return 0 end
  local n = 0
  for _, c in ipairs({ 1, 2 }) do
    for _, g in ipairs(ok(coalition.getGroups, c, Group.Category.GROUND) or {}) do
      for _, u in ipairs(ok(g.getUnits, g) or {}) do if alive(u) then n = n + 1 end end
    end
  end
  return n
end

local function applyLevel(level)
  local cfg, pc = DCC.config, XC().perf
  local base = B.x4.perfBase
  if not base then
    base = { radius = cfg.liveRadiusKm, platoons = cfg.maxLivePlatoons, skirm = cfg.ground.skirmishMax,
             popups = cfg.ext3 and cfg.ext3.popup.max }
    B.x4.perfBase = base
  end
  local s = level > 0 and pc.levels[level].scale or 1
  cfg.liveRadiusKm = math.max(pc.minRadiusKm, math.floor(base.radius * (0.5 + 0.5 * s) + 0.5))
  cfg.maxLivePlatoons = math.max(10, math.floor(base.platoons * s))
  cfg.ground.skirmishMax = math.floor(base.skirm * s)
  if base.popups then cfg.ext3.popup.max = math.max(1, math.floor(base.popups * s)) end
  B.x4.perfLevel = level
end

function B.perfCheck(force)
  local pc = XC().perf
  local now = timer.getTime()
  if not force and now < B.x4.perfNext then return end
  B.x4.perfNext = now + pc.everySec
  local n = B.groundUnitCount()
  local cur, level = B.x4.perfLevel, 0
  for i, l in ipairs(pc.levels) do if n >= l.units then level = i end end
  -- step down only once clearly below the current level (no flicker)
  if level < cur and n >= pc.levels[cur].units * pc.restore then level = cur end
  if level == cur then return end
  applyLevel(level)
  local cfg = DCC.config
  if level > 0 then
    trigger.action.outText(string.format(
      "Server busy (%d ground units): fewer units in the field - live radius %d km, up to %d platoons, %d skirmishes.",
      n, cfg.liveRadiusKm, cfg.maxLivePlatoons, cfg.ground.skirmishMax), 15)
  else
    trigger.action.outText("Server load back to normal: full live radius and battles again.", 15)
  end
  U.log("performance guard: level %d (%d ground units)", level, n)
end

-- ===========================================================================
-- 1. Bogey dope (v0.34)
-- ===========================================================================
-- The nearest enemy aircraft your side has seen (radars, AWACS, eyes - the same
-- fog-of-war picture as the map) in the last staleSec: BRAA and aspect.
local function aspectOf(c, u, me)
  local v = u and ok(u.getVelocity, u)
  if not (v and v.x and (math.abs(v.x) + math.abs(v.z)) > 5) then return nil end
  local h = math.sqrt(v.x * v.x + v.z * v.z)
  local tx, tz = me.x - c.pos.x, me.z - c.pos.z
  local d = math.max(1, math.sqrt(tx * tx + tz * tz))
  local cosA = (v.x * tx + v.z * tz) / (h * d)                 -- 1 = flying straight at you
  if cosA >= 0.866 then return "HOT" elseif cosA >= 0.26 then return "FLANKING"
  elseif cosA >= -0.5 then return "BEAM" else return "DRAG" end
end

function B.bogeyDope(uname)
  local p = B.players[uname]
  local u = p and ok(Unit.getByName, uname)
  if not (p and alive(u)) then return end
  local me, cfg, now = u:getPoint(), XC().bogey, timer.getTime()
  local best
  for name, c in pairs(B.airContacts and B.airContacts[p.side] or {}) do
    if c.pos and now - (c.t or 0) <= cfg.staleSec then
      local d = dist2D(me, c.pos)
      if d <= cfg.maxNm * 1852 and (not best or d < best.d) then best = { name = name, c = c, d = d } end
    end
  end
  if not best then
    return trigger.action.outTextForGroup(p.gid, string.format("BOGEY DOPE: clean - no contacts within %d nm.", cfg.maxNm), 12)
  end
  local c = best.c
  local brg = (math.deg(math.atan2(c.pos.z - me.z, c.pos.x - me.x)) + 360) % 360
  local asp = aspectOf(c, ok(Unit.getByName, best.name), me)
  trigger.action.outTextForGroup(p.gid, string.format("BOGEY DOPE: BRAA %03d / %d nm / %d ft%s - %s (%d s old)",
    math.floor(brg + 0.5) % 360, math.floor(best.d / 1852 + 0.5), math.floor((c.alt or 0) * 3.28084 / 1000 + 0.5) * 1000,
    asp and (", " .. asp) or "", c.type or "aircraft", math.floor(now - (c.t or now))), 15)
end

if B.buildSupportMenu then
  local baseSupport4 = B.buildSupportMenu
  function B.buildSupportMenu(p)
    baseSupport4(p)
    if p and not p.ground and p.gid and p.supportMenu then
      missionCommands.addCommandForGroup(p.gid, "Bogey dope", p.supportMenu, B.bogeyDope, p.unit)
    end
  end
end

-- ===========================================================================
-- 2. Sortie debrief (v0.34)
-- ===========================================================================
-- From take-off to landing at a friendly base / FARP / own carrier: flight
-- time, kills, missions and what they did, points and rank.
local KILLS = { { "kills_air", "air" }, { "kills_ground", "ground" }, { "kills_convoy", "convoy" },
                { "kills_sam", "SAM" }, { "kills_structure", "buildings" } }
local EFFECT_DONE = {
  CAS = "the battle went our way", BAI = "the column will never arrive", STRIKE = "base output cut",
  SEAD = "air defence down", CAP = "1 h of air cover", ESCORT = "delivered", CONVOY = "delivered, no ambush",
  RECON = "intel on the map", CSAR = "pilot home, aircraft refunded", LOGISTICS = "supply delivered",
  INTERCEPT = "the attack never arrived", TANKER = "enemy tanker down", EWR = "radar off the air",
  ARTY = "battery silenced", FORT = "defences weakened", BRIDGE = "road cut", RUNWAY = "runway closed",
  FARP = "new FARP open", FARPSUP = "FARP stocked", MEDEVAC = "wounded home", POW = "prisoners home",
  SHIPSTRIKE = "cargo sunk", SHIPESCORT = "ship docked", SCUD = "launcher destroyed", POPUP = "threat cleared",
  ANTISHIP = "ship hit", HVAA = "enemy AWACS down", MINESWEEP = "harbour open again",
}

local function snapshot(p)
  local rec = DCC.pilots:get(p.key, p.name)
  local s = { t = timer.getTime(), score = DCC.pilots:score(p.key), rank = DCC.pilots:rank(p.key), kills = {}, missions = {} }
  for _, k in ipairs(KILLS) do s.kills[k[1]] = rec[k[1]] or 0 end
  return s
end

local function atHome(p, u)
  local pos = u:getPoint()
  if B.nearestNodeOf(pos, p.side, 5000) then return true end
  for _, rec in pairs(B.naval or {}) do
    local g = ok(Group.getByName, rec.group)
    local cv = g and ok(g.getUnit, g, 1)
    if rec.side == p.side and alive(cv) and dist2D(cv:getPoint(), pos) < 800 then return true end
  end
  return false
end

function B.debrief(p)
  local s = p.debrief
  if not s then return end
  p.debrief = nil
  local rec = DCC.pilots:get(p.key, p.name)
  local lines = { string.format("DEBRIEF - %d min", math.floor((timer.getTime() - s.t) / 60 + 0.5)) }
  local kills = {}
  for _, k in ipairs(KILLS) do
    local n = (rec[k[1]] or 0) - s.kills[k[1]]
    if n > 0 then kills[#kills + 1] = n .. " " .. k[2] end
  end
  lines[#lines + 1] = "Kills: " .. (#kills > 0 and table.concat(kills, ", ") or "none")
  if #s.missions == 0 then lines[#lines + 1] = "Missions: none finished" end
  for _, m in ipairs(s.missions) do
    lines[#lines + 1] = string.format("%s %s: %s%s", m.type, m.label, m.outcome == "done" and "COMPLETE" or m.outcome:upper(),
      (m.outcome == "done" and EFFECT_DONE[m.type]) and (" - " .. EFFECT_DONE[m.type]) or "")
  end
  local score, rank = DCC.pilots:score(p.key), DCC.pilots:rank(p.key)
  lines[#lines + 1] = string.format("Points: %+d (total %d)%s", score - s.score, score,
    rank ~= s.rank and string.format(" - PROMOTED: %s -> %s!", s.rank, rank) or "")
  trigger.action.outTextForGroup(p.gid, table.concat(lines, "\n"), 30)
end

local baseOps5 = B.onOpsEvent
function B.onOpsEvent(e)
  baseOps5(e)
  local u = e.initiator
  local p = u and B.players[ok(u.getName, u) or ""]
  if not p or p.ground then return end
  if e.id == world.event.S_EVENT_TAKEOFF then
    if not p.debrief then p.debrief = snapshot(p) end
  elseif e.id == world.event.S_EVENT_LAND and p.debrief and alive(u) and atHome(p, u) then
    B.debrief(p)
  end
end

local baseDone5 = B.onMissionDone
function B.onMissionDone(m, outcome)
  for key in pairs(m.taken or {}) do
    for _, p in pairs(B.players) do
      if p.key == key and p.debrief then
        table.insert(p.debrief.missions, { type = m.type, label = m.label, outcome = outcome })
      end
    end
  end
  return baseDone5(m, outcome)
end

-- ===========================================================================
-- 8. Harbour mines (v0.34)
-- ===========================================================================
local function llv(p) local v = coord.LLtoLO(p.lat, p.lon, 0); return { x = v.x, y = 0, z = v.z } end
function B.harbourPos(port)
  local l = B.war:laneOf(port)
  return l and llv(l.dock)
end

local baseCanFly5 = B.canFly
function B.canFly(p, m)
  if m and m.needs == "SWEEP" then return p and p.heli == true and not p.ground end
  return baseCanFly5(p, m)
end

local baseMissionPos5 = B.missionPos
function B.missionPos(m)
  if m.type == "MINESWEEP" then return B.harbourPos(m.target) or baseMissionPos5(m) end
  return baseMissionPos5(m)
end

if B.EFFECT then
  B.EFFECT.MINESWEEP = "Fly a helicopter below 150 m within 3 km of the harbour (the orange circle) for 5 min in total "
    .. "- several helicopters sweep faster. No supply ship sails for a mined port."
end

function B.sweepTick()
  local now = timer.getTime()
  local dt = now - (B.x4.sweepAt or now)
  B.x4.sweepAt = now
  if dt <= 0 then return end
  local cfg = XC().mines
  for _, p in pairs(B.players or {}) do
    local m = p.heli and p.mission and B.war.state.missions[p.mission]
    local u = m and m.type == "MINESWEEP" and ok(Unit.getByName, p.unit)
    if u and alive(u) and ok(u.inAir, u) then
      local up, hp = u:getPoint(), B.harbourPos(m.target)
      local agl = up.y - (ok(land.getHeight, { x = up.x, y = up.z }) or 0)
      if hp and agl <= cfg.sweepAglM and dist2D(up, hp) <= cfg.sweepKm * 1000 then B.war:sweepSample(m.id, dt) end
    end
  end
end

function B.drawMines()
  B.x4.mineMarks = B.x4.mineMarks or {}
  local mined = B.war:minedPorts()
  for port, ids in pairs(B.x4.mineMarks) do
    if not mined[port] then
      for _, id in ipairs(ids) do ok(trigger.action.removeMark, id) end
      B.x4.mineMarks[port] = nil
    end
  end
  for port in pairs(mined) do
    local hp = B.harbourPos(port)
    if hp and not B.x4.mineMarks[port] then
      B.x4.mineN = (B.x4.mineN or 0) + 1
      local id = DCC.config.markIdBase + 950000 + B.x4.mineN * 2
      ok(trigger.action.circleToAll, -1, id, hp, XC().mines.sweepKm * 1000, { 1, 0.55, 0, 1 }, { 1, 0.55, 0, 0.15 }, 2, true)
      ok(trigger.action.textToAll, -1, id + 1, hp, { 1, 0.55, 0, 1 }, { 0, 0, 0, 0 }, 14, true, "MINES")
      B.x4.mineMarks[port] = { id, id + 1 }
    end
  end
end

local baseAnnounce5 = B.announce
function B.announce(events)
  baseAnnounce5(events)
  for _, ev in ipairs(events) do
    if ev.kind == "mines_laid" or ev.kind == "mines_cleared" or ev.kind == "mine_strike" then
      if B.COAL[ev.side] then trigger.action.outTextForCoalition(B.COAL[ev.side], "Command: " .. ev.text, 15) end
      if ev.kind == "mines_laid" and ev.layer and B.COAL[ev.layer] then
        trigger.action.outTextForCoalition(B.COAL[ev.layer], string.format("Command: our minelayers have mined %s.",
          B.war:nodeName(ev.node)), 15)
      end
      if ev.kind == "mine_strike" then
        local hp = B.harbourPos(ev.node)
        if hp then ok(trigger.action.explosion, { x = hp.x, y = 0, z = hp.z }, 300) end
      end
    end
  end
end

local baseTick5 = B.opsTick
function B.opsTick()
  baseTick5()
  B.drawMines()
end

-- ===========================================================================
-- Loops
-- ===========================================================================
local basePoll = B.opsPoll
function B.opsPoll()
  basePoll()
  B.groundPresenceTick()
  B.sweepTick()
  B.aiSmokeTick()
  B.defenseSmokeTick()
  B.qraScan()
  B.perfCheck()
end

local baseInit = B.init
function B.init(war, theater, catalog)
  if B.x4.perfBase then applyLevel(0) end          -- a new war starts at the full settings
  baseInit(war, theater, catalog)
  B.x4 = fresh()
end
