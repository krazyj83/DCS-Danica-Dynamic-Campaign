-- ============================================================================
-- Danica Dynamic Campaign - DCS bridge: more air war, support, ranks, scaling,
-- wrecks.  Load after dcc_dcs_ctld.lua.
-- ----------------------------------------------------------------------------
--   Armoury   - what a base can arm aircraft with follows its supply. Taxi
--               out with weapons the base cannot supply and you are warned;
--               take off with them and you are recalled (aircraft removed).
--               Guided and advanced weapons are paid from the base's supply.
--   Runways   - bombs that land on an enemy runway count; 3 close it.
--               Fixed-wing slots at a closed airfield are refused.
--   SAM moves - point defence (and mobile long-range sites) drive to a new
--               spot after they fire or a HARM comes their way.
--   AI crews  - AI aircrews eject; CSAR for their side, SNATCH for the enemy
--               (enemy player pilots too). Land by the pilot, bring him home.
--   Support   - F10 > Support: artillery or a CAS pair on your newest F10
--               map mark, AWACS picture, the base armoury. Gated by rank.
--   Scaling   - the side outnumbered in players takes fewer losses and its
--               AI flies more strike packages.
--   Ranks     - Captain: artillery, Major: CAS, Lt Col: FARP spawns,
--               Colonel: AWACS picture.
--   Wrecks    - destroyed vehicles stay as wrecks through restarts (3 days),
--               destroyed buildings stay destroyed.
-- ============================================================================

DCC = DCC or {}
local B = DCC.dcs
local U = DCC.util

local function XC() return DCC.config.ext end
local function ok(fn, ...) local s, r = pcall(fn, ...); if s then return r end end
local function alive(u) return u ~= nil and ok(u.isExist, u) == true end
local function dist2D(a, b)
  local dx, dz = a.x - b.x, a.z - b.z
  return math.sqrt(dx * dx + dz * dz)
end
local function sideOfCoal(c) return c == 2 and "blue" or (c == 1 and "red" or nil) end
local function sideOf(u) return sideOfCoal(ok(u.getCoalition, u)) end
local function say(p, text, t) if p and p.gid then trigger.action.outTextForGroup(p.gid, text, t or 12) end end
local function isHeli(u)
  local d = ok(u.getDesc, u)
  return d and d.category == (Unit.Category and Unit.Category.HELICOPTER or 1)
end

B.ext = { warned = {}, tracked = {}, moved = {}, marks = {}, cooldown = { blue = {}, red = {} }, wreckN = 0 }

-- ===========================================================================
-- 1. Armoury
-- ===========================================================================
local W_MISSILE, W_BOMB = 1, 3
local G_INS, G_RADAR_A, G_RADAR_SA, G_RADAR_P = 1, 3, 4, 5
local MC_ANTISHIP, MC_CRUISE = 4, 5

-- guided and advanced weapons on board
function B.classifyAmmo(u)
  local guided, adv = 0, 0
  for _, a in ipairs(ok(u.getAmmo, u) or {}) do
    local d, n = a.desc or {}, a.count or 0
    if d.category == W_MISSILE then
      local g, mc = d.guidance, d.missileCategory
      if g == G_INS or g == G_RADAR_A or g == G_RADAR_SA or g == G_RADAR_P or mc == MC_ANTISHIP or mc == MC_CRUISE then
        adv = adv + n
      else
        guided = guided + n
      end
    elseif d.category == W_BOMB and d.guidance then
      if d.guidance == G_INS then adv = adv + n else guided = guided + n end
    end
  end
  return guided, adv
end

local TIER_TEXT = { basic = "guns, rockets and unguided bombs", guided = "guided weapons (IR missiles, laser and TV)",
                    advanced = "everything (radar missiles, anti-radiation, GPS)" }

local function ownBase(u, side)
  local pos = ok(u.getPoint, u)
  local id = pos and B.nearestNodeOf(pos, side, 5000)
  return id
end

function B.armouryText(id)
  local war = B.war
  local tier = war:armouryTier(id)
  local a = XC().armoury
  return string.format("Armoury at %s: %s.\nGuided weapons cost %.1f SU each, advanced %.1f SU (supply %d of %d).",
    war:nodeName(id), TIER_TEXT[tier], a.guidedSU, a.advancedSU, math.floor(war.state.nodes[id].supply or 0),
    math.floor(war:supplyCap(id)))
end

-- taxiing: warn once if the loadout is more than the base can supply
function B.armouryCheckTaxi(p, u)
  if not XC().armoury.enforce or ok(u.inAir, u) ~= false then return end
  local v = ok(u.getVelocity, u)
  if not v or math.sqrt(v.x * v.x + v.z * v.z) < 2 then return end
  local id = ownBase(u, p.side)
  if not id then return end
  local g, a = B.classifyAmmo(u)
  local need = (a > 0 and 3) or (g > 0 and 2) or 1
  local tier = B.war:armouryTier(id)
  if B.war.ARMOURY_TIER[tier] < need and not B.ext.warned[p.unit] then
    B.ext.warned[p.unit] = true
    say(p, string.format("WARNING: %s is short of supply and only has %s.\nRe-arm before take-off or you will be recalled.",
      B.war:nodeName(id), TIER_TEXT[tier]), 20)
  end
end

function B.armouryTakeoff(p, u)
  local id = ownBase(u, p.side)
  if not id then return end
  local g, a = B.classifyAmmo(u)
  local war = B.war
  local okArm, tier, cost = war:armTakeoff(id, g, a)
  if okArm then
    if cost and cost > 0 then say(p, string.format("%s issued your weapons: %.1f SU.", war:nodeName(id), cost), 8) end
    return
  end
  if not XC().armoury.enforce then return end
  say(p, string.format("RECALLED: %s cannot supply your weapons (only %s). Pick a slot again and re-arm.",
    war:nodeName(id), TIER_TEXT[tier]), 20)
  timer.scheduleFunction(function() if alive(u) then ok(u.destroy, u) end end, nil, timer.getTime() + 2)
end

-- ===========================================================================
-- 2. Runways
-- ===========================================================================
local function segDist(p, a, b)
  local vx, vz = b.x - a.x, b.z - a.z
  local len2 = vx * vx + vz * vz
  local t = len2 > 0 and U.clamp(((p.x - a.x) * vx + (p.z - a.z) * vz) / len2, 0, 1) or 0
  return dist2D(p, { x = a.x + vx * t, z = a.z + vz * t })
end

-- distance from p to the nearest runway of airbase node id (nil: unknown)
function B.runwayDist(id, p)
  local name = B.airbases[id]
  local ab = name and ok(Airbase.getByName, name)
  local rws = ab and ab.getRunways and ok(ab.getRunways, ab)
  if not rws or #rws == 0 then return nil end
  local best
  for _, r in ipairs(rws) do
    local c, half = r.position, (r.length or 2500) / 2
    for _, crs in ipairs({ r.course or 0, -(r.course or 0) }) do
      local a = { x = c.x + math.cos(crs) * half, z = c.z + math.sin(crs) * half }
      local b = { x = c.x - math.cos(crs) * half, z = c.z - math.sin(crs) * half }
      local d = segDist(p, a, b)
      if not best or d < best then best = d end
    end
  end
  return best
end

function B.bombImpact(side, p)
  local war = B.war
  for _, id in ipairs(war.T.order) do
    local ns, tn = war.state.nodes[id], war.T.nodes[id]
    if tn.kind == "airbase" and ns.side ~= side and B.nodePos[id] and dist2D(p, B.nodePos[id]) < 5000 then
      local d = B.runwayDist(id, p)
      local hit = (d and d <= XC().runwayHitM) or (not d and dist2D(p, B.nodePos[id]) <= 800)
      if hit then
        local closed = war:runwayHit(id)
        local r = war.state.runways[id]
        trigger.action.outTextForCoalition(B.COAL[side], closed and string.format("Runway at %s closed!", war:nodeName(id))
          or string.format("Runway hit at %s (%d of %d).", war:nodeName(id), r and r.hits or 0, XC().runwayHits), 10)
        return id
      end
    end
  end
end

function B.trackBomb(w, side)
  local last
  local born = timer.getTime()
  local function step(_, t)
    if alive(w) then
      last = ok(w.getPoint, w) or last
      if t - born < 180 then return t + 0.5 end
      return nil
    end
    if last then ok(B.bombImpact, side, last) end
    return nil
  end
  timer.scheduleFunction(step, nil, timer.getTime() + 0.5)
end

-- ===========================================================================
-- 3. SAM sites on the move
-- ===========================================================================
function B.relocateSam(id, which)
  local war = B.war
  local ns = war.state.nodes[id]
  if not ns or not ns.sam then return false end
  local k = id .. ":" .. which
  local now = timer.getTime()
  if B.ext.moved[k] and now - B.ext.moved[k] < XC().samMoveCooldown then return false end
  local rec = B.sams[id]
  local gname = which == "pd" and (rec and rec.pd) or (rec and rec.group)
  local g = gname and ok(Group.getByName, gname)
  if not g or not ok(g.isExist, g) then return false end
  B.ext.moved[k] = now
  local lo, hi = XC().samMoveKm[1], XC().samMoveKm[2]
  local ang = war.rng:next() * 2 * math.pi
  local r = (lo + (hi - lo) * war.rng:next()) * 1000
  local dx, dz = math.cos(ang) * r, math.sin(ang) * r
  local c = B.nodePos[id]
  local u1 = ok(function() return g:getUnits()[1] end)
  local from = u1 and ok(u1.getPoint, u1) or c
  local route = { id = "Mission", params = { route = { points = {
    { x = from.x, y = from.z, type = "Turning Point", action = "Off Road", speed = 12, ETA = 0, ETA_locked = false },
    { x = c.x + dx, y = c.z + dz, type = "Turning Point", action = "Off Road", speed = 12, ETA = 0, ETA_locked = false } } } } }
  local ctl = ok(g.getController, g)
  if ctl then ok(ctl.setTask, ctl, route) end
  war:samMoved(id, dx, dz, which)
  U.log("SAM %s at %s relocating %.1f km", which, id, r / 1000)
  return true
end

-- ===========================================================================
-- 4. AI crews, prisoners
-- ===========================================================================
local baseEject = B.onEjection
function B.onEjection(u)
  if ok(u.getPlayerName, u) then return baseEject(u) end
  local g = ok(u.getGroup, u)
  local gname = g and ok(g.getName, g)
  local s = gname and B.sorties[gname]
  if not s then return end
  local war = B.war
  if war.rng:next() > XC().aiCrewChance then return end
  local pos = ok(u.getPoint, u)
  if not pos then return end
  local t = land.getSurfaceType({ x = pos.x, y = pos.z })
  if t == land.SurfaceType.WATER or t == land.SurfaceType.SHALLOW_WATER then return end
  local callsign = string.format("%s crew (%s)", ok(u.getTypeName, u) or "AI", s.side:upper())
  local did = war:addDowned(s.side, { x = pos.x + 150, z = pos.z + 150 }, callsign, ok(u.getTypeName, u),
    B.nearestNodeOf(pos, s.side), nil)
  war.state.downed[did].aiRole = s.role
  B.spawnDowned(did)
  trigger.action.outTextForCoalition(B.COAL[s.side], string.format("MAYDAY - %s down. CSAR on the board.", callsign), 15)
  trigger.action.outTextForCoalition(B.COAL[U.otherSide(s.side)], string.format(
    "Enemy aircrew down (%s). SNATCH on the board - bring him in.", callsign), 15)
  B.refreshMenus()
end

local baseCsar = B.csarCheck
function B.csarCheck(p, u, pos)
  baseCsar(p, u, pos)
  local lift = (B.catalog.lift or {})[p.type]
  if not lift then return end
  local war = B.war
  local landed = ok(u.inAir, u) == false
  p.prisoners = p.prisoners or {}
  if landed then
    for did, d in pairs(war.state.downed) do
      if d.side ~= p.side and not p.prisoners[did] and dist2D(pos, { x = d.pos.x, z = d.pos.z }) <= 150 then
        p.prisoners[did] = true
        local gname = B.downedGroups[did]
        local g = gname and ok(Group.getByName, gname)
        if g and ok(g.isExist, g) then g:destroy() end
        B.downedGroups[did] = "onboard"
        say(p, string.format("Enemy pilot %s on board. Land at a friendly base.", tostring(d.pilot)), 15)
      end
    end
    if next(p.prisoners) then
      local node = B.nearestNodeOf(pos, p.side, 3000)
      if node then
        for did in pairs(p.prisoners) do
          local d = war.state.downed[did]
          if d and war:snatch(did, p.side, node) then
            DCC.pilots:add(p.key, "prisoners", 1, p.name)
            if d.key then DCC.pilots:add(d.key, "captured", 1) end
            trigger.action.outTextForCoalition(B.COAL[p.side], string.format("%s brought in enemy pilot %s.",
              p.name, tostring(d.pilot)), 15)
          end
          p.prisoners[did] = nil
        end
      end
    end
  end
end

-- ===========================================================================
-- 5. Support on call
-- ===========================================================================
function B.newestMark(side, p)
  local list = B.ext.marks[side] or {}
  local maxAge = XC().support.markMinutes * 60
  local now, best = timer.getTime(), nil
  for _, m in ipairs(list) do
    if now - m.t <= maxAge and (not best or (m.by == p.unit and best.by ~= p.unit) or
       ((m.by == p.unit) == (best.by == p.unit) and m.t > best.t)) then best = m end
  end
  return best
end

local function rankOk(p, what)
  local need = XC().ranks[what]
  if not need then return true end
  return DCC.pilots:rankIndex(p.key) >= DCC.Pilots.rankIndexOf(need), need
end

local function cooldownLeft(side, what, minutes)
  local last = B.ext.cooldown[side][what]
  local left = last and (last + minutes * 60 - timer.getTime()) or 0
  return left > 0 and left or 0
end

function B.callArtillery(uname)
  local p = B.players[uname]
  if not p then return end
  local okRank, need = rankOk(p, "arty")
  if not okRank then return say(p, "Artillery on call needs the rank of " .. need .. ".") end
  local sc = XC().support
  local left = cooldownLeft(p.side, "arty", sc.artyCooldownMin)
  if left > 0 then return say(p, string.format("The guns are busy - %d min.", math.ceil(left / 60))) end
  local m = B.newestMark(p.side, p)
  if not m then return say(p, "Put a mark on the F10 map first (your side, within 15 min).") end
  local war = B.war
  local battery
  for _, b in ipairs(war:batteries(p.side)) do
    if b.status == "up" and b.node and dist2D(B.nodePos[b.node], m.pos) <= sc.artyRangeKm * 1000 then battery = b; break end
  end
  if not battery then return say(p, string.format("No battery within %d km of the mark.", sc.artyRangeKm)) end
  if not war:paySupport(battery.node, sc.artySU) then
    return say(p, war:nodeName(battery.node) .. " has no supply for a fire mission.")
  end
  B.ext.cooldown[p.side].arty = timer.getTime()
  local rec = B.batteries and B.batteries[battery.id]
  local g = rec and ok(Group.getByName, rec.group)
  local ctl = g and ok(g.getController, g)
  if ctl then
    ok(ctl.pushTask, ctl, { id = "FireAtPoint", params = { point = { x = m.pos.x, y = m.pos.z }, radius = 150,
      expendQty = sc.artyRounds, expendQtyEnabled = true } })
  else
    -- the battery is not on the map near you: its shells are
    for i = 1, sc.artyRounds do
      timer.scheduleFunction(function()
        local a = war.rng:next() * 2 * math.pi
        local r = war.rng:next() * 150
        local x, z = m.pos.x + math.cos(a) * r, m.pos.z + math.sin(a) * r
        ok(trigger.action.explosion, { x = x, y = land.getHeight({ x = x, y = z }), z = z }, 60)
      end, nil, timer.getTime() + 20 + i * 3)
    end
  end
  trigger.action.outTextForCoalition(B.COAL[p.side], string.format("%s: fire mission from %s, %d rounds, shot - splash in 20 s.",
    p.name, war:nodeName(battery.node), sc.artyRounds), 12)
end

function B.callCas(uname)
  local p = B.players[uname]
  if not p then return end
  local okRank, need = rankOk(p, "cas")
  if not okRank then return say(p, "CAS on call needs the rank of " .. need .. ".") end
  local sc = XC().support
  local left = cooldownLeft(p.side, "cas", sc.casCooldownMin)
  if left > 0 then return say(p, string.format("No CAS available - %d min.", math.ceil(left / 60))) end
  local m = B.newestMark(p.side, p)
  if not m then return say(p, "Put a mark on the F10 map first (your side, within 15 min).") end
  local node = B.nearestNodeOf(m.pos, p.side)
  if not node or not B.war:paySupport(node, sc.casSU) then return say(p, "No supply to pay for a CAS sortie.") end
  local g = B.spawnSortie(p.side, "attack", "CAS", { x = m.pos.x, y = 0, z = m.pos.z }, {})
  if not g then
    local ns = B.war.state.nodes[node]
    ns.supply = ns.supply + sc.casSU
    return say(p, "No attack aircraft available.")
  end
  B.ext.cooldown[p.side].cas = timer.getTime()
  say(p, "CAS pair inbound to your mark.", 12)
end

function B.picture(uname)
  local p = B.players[uname]
  if not p then return end
  local okRank, need = rankOk(p, "picture")
  if not okRank then return say(p, "The AWACS picture needs the rank of " .. need .. ".") end
  local u = ok(Unit.getByName, uname)
  local me = u and ok(u.getPoint, u)
  if not me then return end
  local list = {}
  for name, c in pairs(B.airContacts[p.side] or {}) do
    if c.pos then list[#list + 1] = { name = name, c = c, d = dist2D(me, c.pos) } end
  end
  table.sort(list, function(a, b) return a.d < b.d end)
  local lines = { "PICTURE" }
  for i = 1, math.min(5, #list) do
    local c = list[i].c
    local brg = (math.deg(math.atan2(c.pos.z - me.z, c.pos.x - me.x)) + 360) % 360
    lines[#lines + 1] = string.format("%s  BRA %03d / %d nm / %d ft", c.type, math.floor(brg + 0.5),
      math.floor(list[i].d / 1852 + 0.5), math.floor((c.alt or 0) * 3.28 / 1000 + 0.5) * 1000)
  end
  if #list == 0 then lines[#lines + 1] = "Clean - no contacts." end
  say(p, table.concat(lines, "\n"), 20)
end

function B.showArmoury(uname)
  local p = B.players[uname]
  if not p then return end
  local u = ok(Unit.getByName, uname)
  local id = u and ownBase(u, p.side)
  if not id then id = u and B.nearestNodeOf(u:getPoint(), p.side) end
  if id then say(p, B.armouryText(id), 15) end
end

function B.buildSupportMenu(p)
  if not p.gid then return end
  if p.supportMenu then ok(missionCommands.removeItemForGroup, p.gid, p.supportMenu) end
  local root = missionCommands.addSubMenuForGroup(p.gid, "Support")
  p.supportMenu = root
  missionCommands.addCommandForGroup(p.gid, "Artillery on my map mark", root, B.callArtillery, p.unit)
  missionCommands.addCommandForGroup(p.gid, "CAS pair on my map mark", root, B.callCas, p.unit)
  missionCommands.addCommandForGroup(p.gid, "AWACS picture", root, B.picture, p.unit)
  missionCommands.addCommandForGroup(p.gid, "Armoury at this base", root, B.showArmoury, p.unit)
end

local baseRegister = B.registerPlayer
function B.registerPlayer(u)
  local p = baseRegister(u)
  if p then
    B.buildSupportMenu(p)
    local id = ownBase(u, p.side)
    if id then say(p, B.armouryText(id), 10) end
  end
  return p
end

local baseClear = B.clearPlayer
function B.clearPlayer(uname, how)
  local p = B.players[uname]
  if p and p.supportMenu then ok(missionCommands.removeItemForGroup, p.gid, p.supportMenu) end
  if p and p.prisoners then
    for did in pairs(p.prisoners) do if B.downedGroups[did] == "onboard" then B.downedGroups[did] = nil end end
  end
  B.ext.warned[uname] = nil
  return baseClear(uname, how)
end

-- ===========================================================================
-- 13 + 14. Scaling, rank-gated FARP spawns, runway slot guard
-- ===========================================================================
function B.playerCounts()
  local n = { blue = 0, red = 0 }
  for _, p in pairs(B.players) do n[p.side] = (n[p.side] or 0) + 1 end
  return n
end

local basePlanPackages = B.planPackages
function B.planPackages()
  basePlanPackages()
  if #B.playerPositions() == 0 then return end
  local war, sc = B.war, XC().scaling
  local n = B.playerCounts()
  local per = DCC.config.tickSeconds / 60
  for _, side in ipairs({ "blue", "red" }) do
    local diff = (n[U.otherSide(side)] or 0) - (n[side] or 0)
    if diff > 0 and war:aiAttackAllowed() then
      local extra = math.min(sc.airMax, sc.airPerPlayer * diff)
      if war.rng:next() < per / DCC.config.air.packageMinutes * extra then B.launchStrike(side) end
    end
  end
end

local baseBirth = B.onBirth
function B.onBirth(unit)
  baseBirth(unit)
  if not alive(unit) or not ok(unit.getPlayerName, unit) then return end
  local war, side = B.war, sideOf(unit)
  local pos = ok(unit.getPoint, unit)
  if not side or not pos then return end
  local id = B.nearestNodeOf(pos, side, 5000)
  if not id then return end
  local heli = isHeli(unit)
  local reason
  if not heli and war:runwayClosed(id) then
    reason = string.format("The runway at %s is closed. Pick a helicopter, or another base.", war:nodeName(id))
  elseif heli and war.T.nodes[id].kind == "town" and war:farpAt(id) then
    local name = ok(unit.getPlayerName, unit)
    local key = (B.players[unit:getName()] or {}).key or name
    local need = XC().ranks.farp
    if need and DCC.pilots:rankIndex(key) < DCC.Pilots.rankIndexOf(need) then
      reason = string.format("FARP spawns need the rank of %s. Spawn at an airbase.", need)
    end
  end
  if reason then
    trigger.action.outTextForUnit(unit:getID(), reason, 20)
    B.clearPlayer(unit:getName(), "left")
    ok(unit.destroy, unit)
  end
end

local baseOpsTick = B.opsTick
function B.opsTick()
  local n = B.playerCounts()
  B.war:setPlayers(n.blue, n.red)
  baseOpsTick()
end

-- ===========================================================================
-- 15. Wrecks
-- ===========================================================================
local function wreckCategory(u)
  if ok(u.hasAttribute, u, "Infantry") then return nil end
  if ok(u.hasAttribute, u, "Air Defence") then return "Air Defence" end
  if ok(u.hasAttribute, u, "Armored vehicles") then return "Armor" end
  return "Unarmed"
end

function B.recordWreck(o)
  local war = B.war
  local cat = ok(Object.getCategory, o)
  local pos = ok(o.getPoint, o)
  if not pos then return end
  if cat == Object.Category.UNIT then
    local d = ok(o.getDesc, o)
    if not d or d.category ~= (Unit.Category and Unit.Category.GROUND_UNIT or 2) then return end
    local wc = wreckCategory(o)
    if not wc then return end
    local p = ok(o.getPosition, o)
    local hdg = p and p.x and math.atan2(p.x.z, p.x.x) or 0
    war:addWreck({ type = ok(o.getTypeName, o), cat = wc, x = pos.x, z = pos.z, hdg = hdg, coal = ok(o.getCoalition, o) })
  elseif cat == (Object.Category.SCENERY or 5) and XC().wrecks.scenery then
    war:addWreck({ scenery = true, x = pos.x, z = pos.z })
  end
end

-- at start: put them back
function B.restoreWrecks()
  local war = B.war
  for _, w in ipairs(war.state.wrecks or {}) do
    if w.scenery then
      ok(trigger.action.explosion, { x = w.x, y = land.getHeight({ x = w.x, y = w.z }), z = w.z }, 120)
    elseif w.type then
      B.ext.wreckN = B.ext.wreckN + 1
      local country = B.countryId(w.coal == 2 and "blue" or "red")
      ok(coalition.addStaticObject, country, { name = "DCC_WRECK_" .. B.ext.wreckN, type = w.type, category = w.cat,
        x = w.x, y = w.z, heading = w.hdg or 0, dead = true })
    end
  end
end

-- ===========================================================================
-- Events and wiring
-- ===========================================================================
local MARK_ADDED, MARK_CHANGE = 25, 26

local baseOps = B.onOpsEvent
function B.onOpsEvent(e)
  baseOps(e)
  local ev, u = world.event, e.initiator
  if e.id == (ev.S_EVENT_MARK_ADDED or MARK_ADDED) or e.id == (ev.S_EVENT_MARK_CHANGE or MARK_CHANGE) then
    local side = sideOfCoal(e.coalition)
    if side and e.pos then
      local list = B.ext.marks[side] or {}
      B.ext.marks[side] = list
      list[#list + 1] = { pos = { x = e.pos.x, z = e.pos.z }, t = timer.getTime(), text = e.text,
                          by = u and ok(u.getName, u) }
      while #list > 20 do table.remove(list, 1) end
    end
  elseif e.id == ev.S_EVENT_TAKEOFF then
    local p = u and B.players[ok(u.getName, u) or ""]
    if p then B.armouryTakeoff(p, u) end
  elseif e.id == ev.S_EVENT_DEAD then
    if u then ok(B.recordWreck, u) end
  end
end

local baseShot = B.onShot
function B.onShot(e)
  if baseShot then baseShot(e) end
  local w, s = e.weapon, e.initiator
  local d = w and ok(w.getDesc, w)
  local side = s and sideOf(s)
  if d and side and d.category == W_BOMB then B.trackBomb(w, side) end
  -- SAMs that fired move
  local sname = s and ok(s.getName, s)
  if sname then
    local pd = sname:match("^DCC_SAMPD_(.-)_%d+$")
    local site = sname:match("^DCC_SAM_(.-)_[rls]%d+$")
    if pd then
      timer.scheduleFunction(function() ok(B.relocateSam, pd, "pd") end, nil, timer.getTime() + 20)
    elseif site then
      local spec = B.catalog.sam and B.catalog.sam[B.war.state.nodes[site].side]
      if spec and spec.mobile then
        timer.scheduleFunction(function() ok(B.relocateSam, site, "site") end, nil, timer.getTime() + 30)
      end
    end
  end
  -- a HARM at a site: mobile sites and its point defence scoot
  if d and d.guidance == G_RADAR_P then
    local tgt = ok(w.getTarget, w)
    local tname = tgt and ok(tgt.getName, tgt)
    local id = tname and (tname:match("^DCC_SAM_(.-)_[rls]%d+$") or tname:match("^DCC_SAMPD_(.-)_%d+$"))
    if id then
      local spec = B.catalog.sam and B.catalog.sam[B.war.state.nodes[id].side]
      if spec and spec.mobile then ok(B.relocateSam, id, "site") end
      ok(B.relocateSam, id, "pd")
    end
  end
end

local baseDetect = B.detect
function B.detect()
  baseDetect()
  for _, p in pairs(B.players) do
    local u = ok(Unit.getByName, p.unit)
    if alive(u) then ok(B.armouryCheckTaxi, p, u) end
  end
end

local baseInit = B.init
function B.init(war, theater, catalog)
  baseInit(war, theater, catalog)
  B.ext = { warned = {}, tracked = {}, moved = {}, marks = {}, cooldown = { blue = {}, red = {} }, wreckN = 0 }
  B.restoreWrecks()
end

B.EFFECT.RUNWAY = "Put 3 bombs on the runway (centre line, 60 m). The airfield closes for 4 h: no airlifts, no fixed-wing spawns."
B.EFFECT.SNATCH = "Land within 150 m of the enemy pilot, then at a friendly base. He talks: your side learns about his base."
