-- ============================================================================
-- Danica Dynamic Campaign - DCS bridge: more air and ground war (v0.18).
-- Load after dcc_dcs_ext_ground.lua.
-- ----------------------------------------------------------------------------
--   2. HVA      : no tanker / AWACS for 2 h after one is lost; enemy fighters
--                 hunt them (HUNT sorties); HVAESCORT = 20 min within 40 km.
--   3. Packages : PKGESCORT = be within 25 km of the target; package bonus.
--   4. Aces     : 3 air kills in one sortie and the enemy sends fighters at you.
--   5. Artillery: shell impacts at a shelled base when players are near.
--   6. Convoys  : a second ambush further down the road; live, unescorted
--                 front convoys near players can be ambushed too.
--   7 + 9. Pick-ups: prisoners / wounded stand at the base; land, pick up,
--                 fly them to an own airbase or depot.
--   8. Heavy    : CTLD > Engineering > Generator / Runway repair kit
--                 (Chinook / Mi-8 only).
--   10. CSAR    : enemy search parties walk / drive to downed pilots.
-- ============================================================================

DCC = DCC or {}
local B = DCC.dcs
local U = DCC.util

local function XC() return DCC.config.ext2 end
local function ok(fn, ...) local s, r = pcall(fn, ...); if s then return r end end
local function alive(u) return u ~= nil and ok(u.isExist, u) == true and (ok(u.getLife, u) or 0) >= 1 end
local function landed(u) return alive(u) and ok(u.inAir, u) == false end
local function dist2D(a, b)
  local dx, dz = a.x - b.x, a.z - b.z
  return math.sqrt(dx * dx + dz * dz)
end
local function otherSide(s) return s == "blue" and "red" or "blue" end
local function sideOfCoal(c) return c == 2 and "blue" or (c == 1 and "red" or nil) end
local function unitsOf(gname)
  local g = gname and ok(Group.getByName, gname)
  local out = {}
  if g and ok(g.isExist, g) then
    for _, u in ipairs(ok(g.getUnits, g) or {}) do if alive(u) then out[#out + 1] = u end end
  end
  return out
end
local function destroyGroup(gname)
  local g = gname and ok(Group.getByName, gname)
  if g and ok(g.isExist, g) then g:destroy() end
end
local function online() return #B.playerPositions() > 0 end
local function say(p, text, t) if p and p.gid then trigger.action.outTextForGroup(p.gid, text, t or 12) end end
local function cat() return B.catalog or {} end
local function wpos(p) return { x = p.x, y = ok(land.getHeight, { x = p.x, y = p.z }) or 0, z = p.z } end

local function fresh()
  return { hunts = {}, amb2 = {}, liveAmb = {}, liveTried = {}, pickGroups = {}, search = {} }
end
B.x2 = fresh()

-- ===========================================================================
-- 2. HVA: grounded after a loss, hunted, escorted
-- ===========================================================================
if B.spawnAsset then
  local baseSpawnAsset = B.spawnAsset
  function B.spawnAsset(side, kind)
    if B.war:hvaGrounded(side, kind) then return nil end
    return baseSpawnAsset(side, kind)
  end
end
if B.spawnAwacs then
  local baseSpawnAwacs = B.spawnAwacs
  function B.spawnAwacs(side)
    if B.war:hvaGrounded(side, "awacs") then return nil end
    return baseSpawnAwacs(side)
  end
end

function B.hvaGroup(side, kind)
  local rec = (kind == "awacs") and (B.awacs or {})[side] or ((B.assets or {})[side] or {})[kind]
  return rec and rec.group
end

local HVA_NAME = { tanker = "tanker", awacs = "AWACS" }

function B.planHunts()
  if not online() then return end
  local war = B.war
  local per = DCC.config.tickSeconds / 60
  for _, hunter in ipairs({ "blue", "red" }) do
    local prey = otherSide(hunter)
    for _, kind in ipairs({ "awacs", "tanker" }) do
      local key = prey .. "|" .. kind
      local gname = B.hvaGroup(prey, kind)
      local u = unitsOf(gname)[1]
      if u and not B.x2.hunts[key] and war.rng:next() < per / XC().huntMinutes then
        local g = ok(u.getGroup, u)
        local gid = g and ok(g.getID, g)
        local s = gid and B.spawnSortie(hunter, "fighter", "HUNT", u:getPoint(), { groupId = gid, life = 2700 })
        if s then
          B.x2.hunts[key] = s
          war:setHvaThreat(prey, kind, true)
          trigger.action.outTextForCoalition(B.COAL[prey], string.format(
            "Command: %s fighters are going after our %s - escort it! (Missions > HVAESCORT)", hunter:upper(),
            HVA_NAME[kind]), 20)
          B.refreshMenus()
        end
      end
    end
  end
end

function B.pollHunts()
  for key, gname in pairs(B.x2.hunts) do
    local prey, kind = key:match("^(.-)|(.+)$")
    if #unitsOf(gname) == 0 or not B.hvaGroup(prey, kind) then
      B.x2.hunts[key] = nil
      B.war:setHvaThreat(prey, kind, false)
    end
  end
end

-- ===========================================================================
-- 3 + 2. Detection for the new escort missions (every 10 s)
-- ===========================================================================
local baseDetect = B.detect
function B.detect()
  baseDetect()
  local war = B.war
  for uname, p in pairs(B.players) do
    local m = p.mission and war.state.missions[p.mission]
    local u = ok(Unit.getByName, uname)
    if m and m.status == "open" and alive(u) then
      local pos = u:getPoint()
      if m.type == "HVAESCORT" then
        local side, kind = m.target:match("^(.-)|(.+)$")
        local a = unitsOf(B.hvaGroup(side, kind))[1]
        if a and dist2D(pos, a:getPoint()) <= XC().hvaEscortKm * 1000 then
          p.hvaSeconds = (p.hvaSeconds or 0) + 10
          if p.hvaSeconds >= XC().hvaEscortMin * 60 then
            p.hvaSeconds = 0
            war:completeMission(m.id, true)
            say(p, string.format("Escort complete - the %s is safe.", HVA_NAME[kind]), 15)
          end
        end
      elseif m.type == "PKGESCORT" then
        local tp = m.node and B.nodePos[m.node]
        if tp and dist2D(pos, tp) <= XC().pkgEscortKm * 1000 and not m.escortOk then
          m.escortOk = true
          say(p, "On station with the strike package - stay until the target is hit.", 10)
        end
      end
    end
  end
end

if B.missionPos then
  local baseMissionPos = B.missionPos
  function B.missionPos(m)
    if m.type == "HVAESCORT" then
      local side, kind = m.target:match("^(.-)|(.+)$")
      local a = unitsOf(B.hvaGroup(side, kind))[1]
      return a and a:getPoint()
    elseif m.type == "MEDEVAC" or m.type == "POW" then
      local q = B.war.state.pickups[m.target]
      return q and B.pickupPos(q)
    end
    return baseMissionPos(m)
  end
end

-- ===========================================================================
-- 4. Aces get hunted
-- ===========================================================================
if B.onKill then
  local baseKill = B.onKill
  function B.onKill(e)
    baseKill(e)
    local shooter, tgt = e.initiator, e.target
    local p = shooter and B.players[ok(shooter.getName, shooter) or ""]
    if not p or not tgt then return end
    local d = ok(tgt.getDesc, tgt)
    if not d or (d.category ~= Unit.Category.AIRPLANE and d.category ~= Unit.Category.HELICOPTER) then return end
    if sideOfCoal(ok(tgt.getCoalition, tgt)) == p.side then return end
    p.airKills = (p.airKills or 0) + 1
    local now = timer.getTime()
    if p.airKills >= XC().aceKills and (not p.huntedAt or now - p.huntedAt >= XC().aceCooldownMin * 60) then
      local g = ok(shooter.getGroup, shooter)
      local gid = g and ok(g.getID, g)
      local s = gid and B.spawnSortie(otherSide(p.side), "fighter", "HUNT", shooter:getPoint(),
        { groupId = gid, life = 2400 })
      if s then
        p.huntedAt = now
        say(p, string.format("%d kills - the enemy has noticed you. Fighters are being vectored onto you.",
          p.airKills), 20)
      end
    end
  end
end

-- ===========================================================================
-- 5. Artillery impacts (only where someone can see them)
-- ===========================================================================
function B.shellImpacts()
  local war = B.war
  for _, side in ipairs({ "blue", "red" }) do
    for _, b in ipairs(war:batteries(side)) do
      local t = b.shelling and B.nodePos[b.shelling]
      local near = false
      if t then
        for _, pp in ipairs(B.playerPositions()) do
          if dist2D(pp, t) <= XC().shellKm * 1000 then near = true end
        end
      end
      if near then
        for i = 1, 6 do
          local a, r = math.random() * 2 * math.pi, 300 + math.random() * 600
          local pt = { x = t.x + math.cos(a) * r, z = t.z + math.sin(a) * r }
          timer.scheduleFunction(function()
            ok(trigger.action.explosion, wpos(pt), 8)
          end, nil, timer.getTime() + 5 + i * 35 + math.random() * 20)
        end
      end
    end
  end
end

-- ===========================================================================
-- 6. Convoys: a second ambush, and ambushes on live convoys
-- ===========================================================================
local function ambushGroup(gname, side, x, z)
  local types = (cat().ambush or {})[side]
  if not types then return nil end
  local units = {}
  for i, ty in ipairs(types) do
    if B.validType(ty) then
      units[#units + 1] = { name = gname .. "_" .. i, type = ty, skill = "Average", x = x + i * 15, y = z + i * 10,
                            heading = 0 }
    end
  end
  if #units == 0 then return nil end
  local data = { name = gname, task = "Ground Nothing", units = units, route = { points = {
    { x = x, y = z, type = "Turning Point", action = "Off Road", speed = 0, ETA = 0, ETA_locked = false,
      speed_locked = true } } } }
  if pcall(coalition.addGroup, B.countryId(side), Group.Category.GROUND, data) then return gname end
end

local function roadPoint(mv, t)
  local a, b = B.nodePos[mv.from], B.nodePos[mv.to]
  if not a or not b then return nil end
  return a.x + (b.x - a.x) * t - 250, a.z + (b.z - a.z) * t + 250
end

if B.spawnAmbush then
  local baseAmbush = B.spawnAmbush
  function B.spawnAmbush(m)
    local had = B.ambushes[m.id]
    baseAmbush(m)
    if had or B.x2.amb2[m.id] then return end
    local mv = B.war.state.moves[m.target]
    if not mv then return end
    local t = math.min(0.92, math.max(mv.progress + 0.25, 0.6) + XC().secondAmbushAt)
    if t <= math.max(mv.progress + 0.25, 0.6) + 0.05 then return end
    local x, z = roadPoint(mv, t)
    if x then B.x2.amb2[m.id] = ambushGroup("DCC_AMB2_" .. m.id, otherSide(m.side), x, z) end
  end
end

if B.cleanAmbushes then
  local baseClean = B.cleanAmbushes
  function B.cleanAmbushes()
    baseClean()
    for mid, gname in pairs(B.x2.amb2) do
      local m = B.war.state.missions[mid]
      if not m or m.status ~= "open" then destroyGroup(gname); B.x2.amb2[mid] = nil end
    end
    for mid, gname in pairs(B.x2.liveAmb) do
      if not B.war.state.moves[mid] then destroyGroup(gname); B.x2.liveAmb[mid] = nil end
    end
  end
end

function B.liveAmbushes()
  local war = B.war
  for _, mid in ipairs(U.sortedKeys(war.state.moves)) do
    local mv = war.state.moves[mid]
    if mv.kind == "convoy" and mv.front and mv.status == "moving" and not mv.escorted and not B.x2.liveTried[mid]
       and not war:onSea(mv) and war:isMoveLive(mv) and mv.progress < 0.7 then
      local pos = B.missionPos({ type = "CONVOY", target = mid })
      local near = false
      if pos then
        for _, pp in ipairs(B.playerPositions()) do if dist2D(pp, pos) <= 30000 then near = true end end
      end
      if near then
        B.x2.liveTried[mid] = true
        if war.rng:next() < XC().liveAmbushChance then
          local x, z = roadPoint(mv, math.min(0.9, mv.progress + 0.2))
          local g = x and ambushGroup("DCC_AMBL_" .. mid, otherSide(mv.side), x, z)
          if g then
            B.x2.liveAmb[mid] = g
            trigger.action.outTextForCoalition(B.COAL[mv.side], string.format(
              "Command: our convoy to %s reports enemy movement ahead on the road.", war:nodeName(mv.to)), 15)
          end
        end
      end
    end
  end
  for mid in pairs(B.x2.liveTried) do if not war.state.moves[mid] then B.x2.liveTried[mid] = nil end end
end

-- ===========================================================================
-- 7 + 9. Pick-ups: prisoners and wounded
-- ===========================================================================
function B.pickupPos(q)
  local p = B.nodePos[q.node]
  return p and { x = p.x + 600, y = 0, z = p.z + 300 }
end

function B.reconcilePickups()
  local war = B.war
  for qid, gname in pairs(B.x2.pickGroups) do
    local q = war.state.pickups[qid]
    if not q or q.onboard then destroyGroup(gname); B.x2.pickGroups[qid] = nil end
  end
  for _, qid in ipairs(U.sortedKeys(war.state.pickups)) do
    local q = war.state.pickups[qid]
    if not q.onboard and not B.x2.pickGroups[qid] then
      local p = B.pickupPos(q)
      local t = (cat().downedPilot or {})[q.side] or "Soldier M4"
      local gname = "DCC_PICK_" .. qid
      local units = {}
      for i = 1, math.min(q.n, 4) do
        units[i] = { name = gname .. "_" .. i, type = t, skill = "Average", x = p.x + i * 4, y = p.z + (i % 2) * 4,
                     heading = 0 }
      end
      if p and #units > 0 and pcall(coalition.addGroup, B.countryId(q.side), Group.Category.GROUND, { name = gname,
          task = "Ground Nothing", units = units, route = { points = { { x = p.x, y = p.z, type = "Turning Point",
          action = "Off Road", speed = 0, ETA = 0, ETA_locked = false, speed_locked = true } } } }) then
        B.x2.pickGroups[qid] = gname
        local g = ok(Group.getByName, gname)
        local c = g and ok(g.getController, g)
        if c and AI then ok(c.setOption, c, AI.Option.Ground.id.ROE, AI.Option.Ground.val.ROE.WEAPON_HOLD) end
      end
    end
  end
end

function B.pickupCheck(p, u, pos)
  local war = B.war
  p.x2pick = p.x2pick or {}
  if landed(u) then
    for _, qid in ipairs(U.sortedKeys(war.state.pickups)) do
      local q = war.state.pickups[qid]
      local qp = B.pickupPos(q)
      if q.side == p.side and not q.onboard and qp and dist2D(pos, qp) <= XC().pickupLandM then
        if war:pickupLoaded(qid) then
          p.x2pick[qid] = true
          destroyGroup(B.x2.pickGroups[qid]); B.x2.pickGroups[qid] = nil
          say(p, string.format("%d %s on board. Fly them to a friendly airbase or depot.", q.n,
            q.kind == "pow" and "prisoners" or "wounded"), 15)
        end
      end
    end
  end
  if next(p.x2pick) and landed(u) then
    local node = B.nearestNodeOf(pos, p.side, 3000)
    if node then
      for qid in pairs(p.x2pick) do
        local q = war.state.pickups[qid]
        if not q then
          p.x2pick[qid] = nil
        elseif war:pickupDropOk(q, node) then
          local kind = q.kind
          if war:pickupDelivered(qid, node) then
            DCC.pilots:add(p.key, kind == "pow" and "pows" or "medevacs", 1, p.name)
            say(p, string.format("%s delivered to %s.", kind == "pow" and "Prisoners" or "Wounded",
              war:nodeName(node)), 15)
            B.refreshMenus()
          end
          p.x2pick[qid] = nil
        elseif node ~= q.node and not p.x2warned then
          p.x2warned = true
          say(p, "Take them to an airbase or depot.", 10)
        end
      end
    end
  end
end

if B.csarCheck then
  local baseCsar = B.csarCheck
  function B.csarCheck(p, u, pos)
    baseCsar(p, u, pos)
    if (cat().lift or {})[p.type] then B.pickupCheck(p, u, pos) end
  end
end

if B.clearPlayer then
  local baseClear = B.clearPlayer
  function B.clearPlayer(uname, how)
    local p = B.players[uname]
    if p and p.x2pick then
      for qid in pairs(p.x2pick) do
        local q = B.war.state.pickups[qid]
        if q then
          if how == "lost" then B.war:pickupLost(qid) else q.onboard = nil end   -- left the slot: they wait again
        end
      end
      p.x2pick = {}
    end
    return baseClear(uname, how)
  end
end

-- ===========================================================================
-- 8. Heavy sling loads (CTLD)
-- ===========================================================================
function B.heavyDown(crate, pos, loud)
  local war, cm = B.war, CTLDCrateManager.getInstance()
  local side = sideOfCoal(crate.coalition)
  local what = crate.descriptor.dccHeavy
  local function tell(text) if loud then trigger.action.outTextForCoalition(crate.coalition, text, 12) end end
  pos = pos or crate.position
  if not (war and side and pos) then return false end
  local km = XC().heavyKm
  local done
  if what == "generator" then
    local node = B.nearestNodeOf(pos, side, km * 1000)
    if not node then tell(string.format("Generators go down within %d km of a friendly base.", km)); return false end
    done = war:installGenerator(node, side)
  else
    local node
    for _, id in ipairs(war.T.order) do
      local np = B.nodePos[id]
      if np and war.state.nodes[id].side == side and war:runwayClosed(id) and dist2D(pos, np) <= km * 1000 then
        node = id
      end
    end
    if not node then tell(string.format("A runway repair kit goes down within %d km of a cratered friendly runway.", km))
      return false end
    done = war:repairRunwayNow(node, side)
  end
  if done then ok(cm.destroyCrate, cm, crate.crateName) end
  return done
end

if B.ctldCrateDown then
  local baseDown = B.ctldCrateDown
  function B.ctldCrateDown(crate, pos)
    if crate and crate.descriptor and crate.descriptor.dccHeavy then
      local s, r = pcall(B.heavyDown, crate, pos, true)
      if not s then U.log("ERROR heavy crate: %s", tostring(r)) end
      return s and r
    end
    return baseDown(crate, pos)
  end
end

if B.ctldConfigure then
  local baseConfigure = B.ctldConfigure
  function B.ctldConfigure()
    baseConfigure()
    local crates = ctld.gs("spawnableCrates") or {}
    local only = {}
    for _, t in ipairs(XC().heavyTypes) do only[t] = true end
    local list = crates["Engineering"] or {}
    local msg = "Heavy lift - only a Chinook or a Mi-8 can carry that."
    list[#list + 1] = { unit = "DCC_GENERATOR", desc = "Generator (Chinook / Mi-8)", weight = 2500.01, cratesRequired = 1,
                        dccHeavy = "generator", dccOnly = only, dccOnlyMsg = msg, dccCharge = 2 }
    list[#list + 1] = { unit = "DCC_RUNWAYKIT", desc = "Runway repair kit (Chinook / Mi-8)", weight = 2500.01,
                        cratesRequired = 1, dccHeavy = "runway", dccOnly = only, dccOnlyMsg = msg, dccCharge = 2 }
    crates["Engineering"] = list
    CTLDConfig.get():setSetting("spawnableCrates", crates)
  end
end

if B.ctldHook then
  local baseHook = B.ctldHook
  function B.ctldHook()
    baseHook()
    if not B.ctld or B.ctld.x2Hooked or not CTLDCrateManager then return end
    B.ctld.x2Hooked = true
    local CM = CTLDCrateManager
    local baseUnpack = CM.unpackCrate
    CM.unpackCrate = function(self, crateName, unpacker)
      local crate = self.crates and self.crates[crateName]
      if crate and crate.descriptor and crate.descriptor.dccHeavy then
        if B.war then ok(B.heavyDown, crate, crate.position, true) end
        return
      end
      return baseUnpack(self, crateName, unpacker)
    end
    local baseSU = CM._spawnUnpacked
    if baseSU then
      CM._spawnUnpacked = function(self, desc, ...)
        if desc and desc.dccHeavy then return nil end
        return baseSU(self, desc, ...)
      end
    end
  end
end

-- ===========================================================================
-- 10. CSAR under fire: search parties
-- ===========================================================================
function B.pollSearch()
  local war, cfg = B.war, XC()
  for did, rec in pairs(B.x2.search) do
    local d = war.state.downed[did]
    if not d or (B.downedGroups or {})[did] == "onboard" then
      destroyGroup(rec.group); B.x2.search[did] = nil
    else
      for _, u in ipairs(unitsOf(rec.group)) do
        if dist2D(u:getPoint(), d.pos) <= cfg.searchCatchM then
          if war:downedCaptured(did, rec.side) then
            destroyGroup((B.downedGroups or {})[did]); B.downedGroups[did] = nil
          end
          destroyGroup(rec.group); B.x2.search[did] = nil
          break
        end
      end
    end
  end
  for _, did in ipairs(U.sortedKeys(war.state.downed)) do
    local d = war.state.downed[did]
    local ageMin = (war.state.tick - d.tick) * DCC.config.tickSeconds / 60
    if not B.x2.search[did] and not d.searched and ageMin >= cfg.searchAfterMin
       and (B.downedGroups or {})[did] ~= "onboard" then
      d.searched = true
      local enemy = otherSide(d.side)
      local node = B.nearestNodeOf(d.pos, enemy, cfg.searchKm * 1000)
      local np = node and B.nodePos[node]
      local types = (cat().ambush or {})[enemy] or {}
      local units = {}
      if np then
        local hdg = math.atan2(d.pos.z - np.z, d.pos.x - np.x)
        local sx, sz = np.x + math.cos(hdg) * 300, np.z + math.sin(hdg) * 300
        for i = 1, math.min(2, #types) do
          if B.validType(types[i]) then
            units[#units + 1] = { name = "DCC_SEARCH_" .. did .. "_" .. i, type = types[i], skill = "Average",
                                  x = sx + i * 10, y = sz, heading = hdg }
          end
        end
        local gname = "DCC_SEARCH_" .. did
        if #units > 0 and pcall(coalition.addGroup, B.countryId(enemy), Group.Category.GROUND, { name = gname,
            task = "Ground Nothing", units = units, route = { points = {
              { x = sx, y = sz, type = "Turning Point", action = "Off Road", speed = cfg.searchSpeed, ETA = 0,
                ETA_locked = false, speed_locked = true },
              { x = d.pos.x, y = d.pos.z, type = "Turning Point", action = "Off Road", speed = cfg.searchSpeed,
                ETA = 0, ETA_locked = false, speed_locked = true } } } }) then
          B.x2.search[did] = { group = gname, side = enemy }
          local km = dist2D({ x = sx, z = sz }, d.pos) / 1000
          trigger.action.outTextForCoalition(B.COAL[d.side], string.format(
            "Command: an enemy search party is moving toward %s from %s (%.0f km, about %d min) - hurry.",
            tostring(d.pilot), war:nodeName(node), km, math.floor(km * 1000 / cfg.searchSpeed / 60 + 0.5)), 20)
        end
      end
    end
  end
end

-- ===========================================================================
-- Announcements and points
-- ===========================================================================
local OWN = { shelling = true, pows = true, casualties = true, pickup_done = true, pickup_lost = true,
              generator = true, package_done = true }
local baseAnnounce = B.announce
function B.announce(events)
  baseAnnounce(events)
  for _, ev in ipairs(events) do
    if OWN[ev.kind] and ev.side and B.COAL[ev.side] then
      trigger.action.outTextForCoalition(B.COAL[ev.side], "Command: " .. ev.text, 12)
    end
    if ev.kind == "package_done" and ev.crew then
      for key, name in pairs(ev.crew) do DCC.pilots:add(key, "packages", 1, name) end
    end
  end
end

if B.EFFECT then
  B.EFFECT.HVAESCORT = "Stay within 40 km of it for 20 minutes. Lose it and there is none for 2 hours."
  B.EFFECT.PKGESCORT = "Be within 25 km of the target while the strike goes in. Package bonus for everyone if it hits."
  B.EFFECT.MEDEVAC = "Land next to the wounded at the base, fly them to a friendly airbase or depot: the garrison recovers."
  B.EFFECT.POW = "Land next to the prisoners, fly them to a friendly airbase or depot: interrogation reveals nearby enemy bases."
end

-- ===========================================================================
-- Loops
-- ===========================================================================
local basePoll = B.opsPoll
function B.opsPoll()
  basePoll()
  B.pollHunts()
  B.reconcilePickups()
  B.pollSearch()
end

local baseTick = B.opsTick
function B.opsTick()
  baseTick()
  B.planHunts()
  B.shellImpacts()
  B.liveAmbushes()
end

local baseInit = B.init
function B.init(war, theater, catalog)
  baseInit(war, theater, catalog)
  B.x2 = fresh()
end
