-- ============================================================================
-- Danica Dynamic Campaign - DCS bridge: naval and hidden-threat war (v0.25).
-- Load after dcc_dcs_ext2.lua.
-- ----------------------------------------------------------------------------
--   1. Amphibious : landing helicopters (airmobile template) from Tarawa /
--                   Kuznetsov to a weak enemy coastal town.
--   2. Shipping   : real cargo ships on the lanes; sunk = cargo lost; AI
--                   anti-ship strikes on enemy cargo ships.
--   3. Carrier air wing: an AI CAP over each carrier and (BLUE) an S-3B
--                   recovery tanker on TACAN 76X, re-tasked as the ship sails.
--   4. Scuds      : launcher groups in the rear; impacts shown near players.
--   7. Pop-ups    : MANPADS / SHORAD groups spawned when enemy aircraft come
--                   near; seen (or firing) = on the map and the board.
-- ============================================================================

DCC = DCC or {}
local B = DCC.dcs
local U = DCC.util

local function XC() return DCC.config.ext3 end
local function ok(fn, ...) local s, r = pcall(fn, ...); if s then return r end end
local function alive(u) return u ~= nil and ok(u.isExist, u) == true and (ok(u.getLife, u) or 0) >= 1 end
local function dist2D(a, b)
  local dx, dz = a.x - b.x, a.z - b.z
  return math.sqrt(dx * dx + dz * dz)
end
local function otherSide(s) return s == "blue" and "red" or "blue" end
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
local function cat() return B.catalog or {} end
local function ll(p) local v = coord.LLtoLO(p.lat, p.lon, 0); return { x = v.x, y = 0, z = v.z } end
local function wpos(p) return { x = p.x, y = ok(land.getHeight, { x = p.x, y = p.z }) or 0, z = p.z } end
local function enemyPlayersNear(side, pos, km)
  local out = {}
  for _, u in ipairs(coalition.getPlayers(B.COAL[otherSide(side)]) or {}) do
    if alive(u) and dist2D(u:getPoint(), pos) <= km * 1000 then out[#out + 1] = u end
  end
  return out
end
local function combo(tasks)
  for i, t in ipairs(tasks) do t.number, t.auto, t.enabled = i, false, true end
  return { id = "ComboTask", params = { tasks = tasks } }
end
local function wp(x, z, alt, speed, task)
  return { x = x, y = z, alt = alt, alt_type = "BARO", type = "Turning Point", action = "Turning Point",
           speed = speed, speed_locked = true, ETA = 0, ETA_locked = false, task = task or combo({}) }
end
local function say(side, text, t)
  if B.COAL[side] then trigger.action.outTextForCoalition(B.COAL[side], "Command: " .. text, t or 15) end
end
local function shipUnit(id)
  local rec = (B.naval or {})[id]
  return rec and unitsOf(rec.group)[1]
end

local function fresh() return { ships = {}, wing = {}, scuds = {}, pops = {}, n = 0 } end
B.x3 = fresh()
local function nextName(prefix) B.x3.n = B.x3.n + 1; return prefix .. B.x3.n end

-- ===========================================================================
-- 1. Amphibious assault
-- ===========================================================================
function B.launchAmphib(side)
  local war, cfg = B.war, XC().amphib
  if not B.findTemplate("DCC_TPL_" .. side .. "_airmobile") or war:isStorm() then return nil end
  for _, ship in ipairs(war:amphibShips(side)) do
    local u = shipUnit(ship.id)
    if u then
      local sp = u:getPoint()
      local best, bestKey
      for _, id in ipairs(war.T.order) do
        local np = B.nodePos[id]
        if np and war:amphibTargetOk(side, id) and dist2D(np, sp) <= cfg.rangeKm * 1000 then
          local key = #war.state.nodes[id].platoons * 1e6 + dist2D(np, sp)
          if not bestKey or key < bestKey then best, bestKey = id, key end
        end
      end
      local home = best and B.nearestNodeOf(sp, side)
      local pk = home and war:amphibLaunched(side, ship.id, best, home)
      if pk then
        local np = B.nodePos[best]
        local d = math.max(1, dist2D(np, sp))
        local lx, lz = B.landNear(np.x + (sp.x - np.x) / d * 700, np.z + (sp.z - np.z) / d * 700)
        local landing = { x = lx, z = lz }
        local gname = "DCC_AMPHIB_" .. pk.id
        local g = B.spawnFlight(side, "airmobile", gname, { x = sp.x + 300, z = sp.z + 300 }, 150, 60, {
          wp(sp.x + 300, sp.z + 300, 150, 60),
          wp(landing.x, landing.z, 0, 50, combo({ { id = "Land", params = { point = { x = landing.x, y = landing.z },
            durationFlag = true, duration = 600 } } })) }, { helicopter = true, task = "Transport" })
        if not g then war:packageDestroyed(pk.id); return nil end
        B.packages[pk.id] = { strike = gname, target = np, kind = "airmobile", landing = landing }
        say(side, string.format("marines lifting off %s for %s - escort them (Missions > AMPHIB).", ship.name,
          war:nodeName(best)), 20)
        B.refreshMenus()
        return pk
      end
    end
  end
end

-- ===========================================================================
-- 2. Shipping
-- ===========================================================================
function B.shipPos(s)
  local rec = B.x3.ships[s.id]
  local u = rec and unitsOf(rec.group)[1]
  if u then return u:getPoint() end
  local l = B.war:laneOf(s.port)
  if not l then return nil end
  local a, b = ll(l.start), ll(l.dock)
  return { x = a.x + (b.x - a.x) * s.progress, y = 0, z = a.z + (b.z - a.z) * s.progress }
end

function B.reconcileShipping()
  local war, cfg = B.war, XC().shipping
  for id, rec in pairs(B.x3.ships) do
    local s = war.state.shipping[id]
    if not s then
      destroyGroup(rec.group); B.x3.ships[id] = nil              -- docked (or the model lost it)
    elseif #unitsOf(rec.group) == 0 then
      B.x3.ships[id] = nil
      war:shippingSunk(id)
    end
  end
  if not online() then return end
  for _, id in ipairs(U.sortedKeys(war.state.shipping)) do
    local s = war.state.shipping[id]
    local l = war:laneOf(s.port)
    if l and not B.x3.ships[id] then
      local p, dock = B.shipPos(s), ll(l.dock)
      local t = cfg.ships[s.side] or "Dry-cargo ship-1"
      local gname = nextName("DCC_CARGOSHIP_" .. id .. "_")
      local speed = cfg.speedKmh / 3.6
      local hdg = math.atan2(dock.z - p.z, dock.x - p.x)
      if pcall(coalition.addGroup, B.countryId(s.side), Group.Category.SHIP, { name = gname,
          units = { { name = gname .. "_1", type = t, skill = "Average", x = p.x, y = p.z, heading = hdg } },
          route = { points = {
            { x = p.x, y = p.z, type = "Turning Point", action = "Turning Point", speed = speed, ETA = 0,
              ETA_locked = false, speed_locked = true },
            { x = dock.x, y = dock.z, type = "Turning Point", action = "Turning Point", speed = speed, ETA = 0,
              ETA_locked = false, speed_locked = true } } } }) then
        B.x3.ships[id] = { group = gname }
      end
    end
  end
end

function B.planShipStrikes()
  local war = B.war
  if not online() or not war:aiAttackAllowed() then return end
  for id, rec in pairs(B.x3.ships) do
    local s = war.state.shipping[id]
    local u = unitsOf(rec.group)[1]
    if s and u and war.rng:next() < XC().shipping.aiStrikeChance then
      local enemy = otherSide(s.side)
      local busy = false
      for _, so in pairs(B.sorties) do if so.side == enemy and so.kind == "ANTISHIP" then busy = true end end
      local g = ok(u.getGroup, u)
      if not busy and g then
        B.spawnSortie(enemy, "attack", "ANTISHIP", u:getPoint(), { groupId = g:getID(), template = "antiship" })
      end
    end
  end
end

-- ===========================================================================
-- 3. Carrier air wing: CAP and recovery tanker over each carrier
-- ===========================================================================
local function orbitTasks(kind, c, alt, speed)
  if kind == "tanker" then
    return combo({ { id = "Tanker", params = {} },
      { id = "Orbit", params = { pattern = "Race-Track", point = { x = c.x - 12000, y = c.z },
        point2 = { x = c.x + 12000, y = c.z }, altitude = alt, speed = speed } } })
  end
  return combo({ { id = "EngageTargets", params = { targetTypes = { "Air" }, priority = 0, maxDist = 60000 } },
    { id = "Orbit", params = { pattern = "Circle", point = { x = c.x, y = c.z }, altitude = alt, speed = speed } } })
end

function B.carrierWing()
  local war, cfg = B.war, XC().carrier
  local now = timer.getTime()
  for _, ship in ipairs(war.theater.naval or {}) do
    if ship.kind == "carrier" and ship.ship ~= "LHA_Tarawa" then
      for _, kind in ipairs({ "cap", "tanker" }) do
        local key = ship.id .. "|" .. kind
        local rec = B.x3.wing[key]
        local u = shipUnit(ship.id)
        local role = kind == "cap" and "carriercap" or "carriertanker"
        local alt = kind == "cap" and cfg.capAltM or cfg.tankerAltM
        local speed = kind == "cap" and 220 or 140
        if rec and rec.group and (not u or not online() or now - rec.born > cfg.lifeMin * 60) then
          destroyGroup(rec.group)                                  -- relieved (or nothing to guard)
          B.x3.wing[key] = { gone = now - cfg.respawnMin * 60 }
          rec = nil
        elseif rec and rec.group and #unitsOf(rec.group) == 0 then
          B.x3.wing[key] = { gone = now }                          -- shot down: a while until the next
          rec = nil
        end
        rec = B.x3.wing[key]
        if u and online() and (not rec or (not rec.group and now - (rec.gone or 0) >= cfg.respawnMin * 60))
           and B.findTemplate("DCC_TPL_" .. ship.side .. "_" .. role) then
          local c = u:getPoint()
          local gname = nextName("DCC_CVW_" .. ship.id .. "_" .. kind .. "_")
          local g = B.spawnFlight(ship.side, role, gname, { x = c.x - 3000, z = c.z - 3000 }, alt, speed,
            { wp(c.x, c.z, alt, speed, orbitTasks(kind, c, alt, speed)) },
            { task = kind == "cap" and "CAP" or "Refueling", size = kind == "tanker" and 1 or nil })
          if g then
            B.x3.wing[key] = { group = gname, born = now, center = { x = c.x, z = c.z } }
            if kind == "tanker" then
              local tu = unitsOf(gname)[1]
              local ctl = tu and ok(tu.getController, tu)
              if ctl then
                pcall(ctl.setCommand, ctl, { id = "ActivateBeacon", params = { type = 4, system = 4,
                  callsign = cfg.tankerCall, frequency = (1088 + cfg.tankerTacan - 1) * 1000000, AA = true,
                  channel = cfg.tankerTacan, modeChannel = "X", bearing = true, unitId = ok(tu.getID, tu) } })
              end
              say(ship.side, string.format("%s recovery tanker overhead, TACAN %dX.", ship.name, cfg.tankerTacan), 12)
            end
          end
        elseif rec and rec.group and u then
          local c = u:getPoint()
          if dist2D(c, rec.center) > cfg.retaskKm * 1000 then           -- the ship sailed on: follow it
            local g = ok(Group.getByName, rec.group)
            local ctl = g and ok(g.getController, g)
            if ctl then
              pcall(ctl.setTask, ctl, { id = "Mission", params = { route = { points = {
                wp(c.x, c.z, alt, speed, orbitTasks(kind, c, alt, speed)) } } } })
              rec.center = { x = c.x, z = c.z }
            end
          end
        end
      end
    end
  end
end

-- ===========================================================================
-- 4. Scuds
-- ===========================================================================
function B.scudPos(b)
  local np = b.node and B.nodePos[b.node]
  if not np then return nil end
  local x, z = B.landNear(np.x + (b.off and b.off.dx or 0), np.z + (b.off and b.off.dz or 0))
  return { x = x, y = 0, z = z }
end

function B.reconcileScuds()
  local war = B.war
  for _, b in ipairs(war:scuds()) do
    local rec = B.x3.scuds[b.id]
    if rec and (b.status ~= "up" or rec.node ~= b.node) then
      destroyGroup(rec.group); B.x3.scuds[b.id] = nil; rec = nil   -- killed in the model, or it moved on
    elseif rec and #unitsOf(rec.group) == 0 then
      B.x3.scuds[b.id] = nil; rec = nil
      war:scudKilled(b.id)
    end
    if not rec and b.status == "up" and b.node then
      local p = B.scudPos(b)
      local units = {}
      for i, t in ipairs(cat().scud or { "Scud_B" }) do
        if B.validType(t) then
          units[#units + 1] = { name = "DCC_SCUD_" .. b.id .. "_" .. B.x3.n .. "_" .. i, type = t, skill = "Average",
                                x = p.x + i * 25, y = p.z + i * 10, heading = 0, playerCanDrive = false }
        end
      end
      local gname = nextName("DCC_SCUD_" .. b.id .. "_")
      if #units > 0 and pcall(coalition.addGroup, B.countryId(b.side), Group.Category.GROUND, { name = gname,
          task = "Ground Nothing", units = units, route = { points = { { x = p.x, y = p.z, type = "Turning Point",
          action = "Off Road", speed = 0, ETA = 0, ETA_locked = false } } } }) then
        B.x3.scuds[b.id] = { group = gname, node = b.node }
      end
    end
  end
end

function B.scudImpact(node)
  local p = B.nodePos[node]
  if not p then return end
  for _, pp in ipairs(B.playerPositions()) do
    if dist2D(pp, p) <= XC().scud.impactKm * 1000 then
      local a, r = math.random() * 2 * math.pi, math.random() * 1500
      local pt = { x = p.x + math.cos(a) * r, z = p.z + math.sin(a) * r }
      timer.scheduleFunction(function() ok(trigger.action.explosion, wpos(pt), 500) end, nil,
        timer.getTime() + 20 + math.random() * 40)
      return
    end
  end
end

-- ===========================================================================
-- 7. Pop-up threats
-- ===========================================================================
function B.popupPos(p)
  local a, b = B.nodePos[p.node], p.toward and B.nodePos[p.toward]
  if not a then return nil end
  local x, z = a.x, a.z
  if b then
    x, z = a.x + (b.x - a.x) * p.frac, a.z + (b.z - a.z) * p.frac
    local d = math.max(1, dist2D(a, b))
    x, z = x - (b.z - a.z) / d * p.jitter, z + (b.x - a.x) / d * p.jitter      -- off the straight line
  end
  x, z = B.landNear(x, z)
  return { x = x, y = 0, z = z }
end

function B.reconcilePopups()
  local war, cfg = B.war, XC().popup
  for id, rec in pairs(B.x3.pops) do
    local p = war.state.popups[id]
    if not p then
      destroyGroup(rec.group); B.x3.pops[id] = nil
    elseif #unitsOf(rec.group) == 0 then
      B.x3.pops[id] = nil
      war:popupKilled(id)
    elseif #enemyPlayersNear(p.side, rec.pos, cfg.despawnKm) == 0 then
      destroyGroup(rec.group); B.x3.pops[id] = nil                       -- nobody near: back to the model
    else
      for _, eu in ipairs(enemyPlayersNear(p.side, rec.pos, cfg.seeKm)) do
        local e, t = eu:getPoint(), unitsOf(rec.group)[1]
        local tp = t and t:getPoint()
        if tp and ok(land.isVisible, { x = e.x, y = e.y, z = e.z }, { x = tp.x, y = tp.y + 2, z = tp.z }) then
          war:popupSeen(id, otherSide(p.side), "visual")
          break
        end
      end
    end
  end
  for _, id in ipairs(U.sortedKeys(war.state.popups)) do
    local p = war.state.popups[id]
    if not B.x3.pops[id] then
      local pos = B.popupPos(p)
      if pos and #enemyPlayersNear(p.side, pos, cfg.spawnKm) > 0 then
        local types = ((cat().popups or {})[p.kind] or {})[p.side] or {}
        local gname = nextName("DCC_POP_" .. id .. "_")
        local units = {}
        for i, t in ipairs(types) do
          if B.validType(t) then
            units[#units + 1] = { name = gname .. "_" .. i, type = t, skill = "Good", x = pos.x + i * 12,
                                  y = pos.z + i * 6, heading = 0, playerCanDrive = false }
          end
        end
        if #units > 0 and pcall(coalition.addGroup, B.countryId(p.side), Group.Category.GROUND, { name = gname,
            task = "Ground Nothing", units = units, route = { points = { { x = pos.x, y = pos.z,
            type = "Turning Point", action = "Off Road", speed = 0, ETA = 0, ETA_locked = false } } } }) then
          B.x3.pops[id] = { group = gname, pos = pos }
        end
      end
    end
  end
end

-- a pop-up that fires gives itself away
function B.x3OnEvent(e)
  if not e or e.id ~= world.event.S_EVENT_SHOT or not e.initiator then return end
  local g = ok(e.initiator.getGroup, e.initiator)
  local gname = g and ok(g.getName, g) or ""
  for id, rec in pairs(B.x3.pops) do
    if rec.group == gname then
      local p = B.war.state.popups[id]
      if p then B.war:popupSeen(id, otherSide(p.side), "visual") end
    end
  end
end
if world and world.addEventHandler and not B.x3Handler then
  B.x3Handler = { onEvent = function(_, e) pcall(B.x3OnEvent, e) end }
  world.addEventHandler(B.x3Handler)
end

-- ===========================================================================
-- Missions: positions, escort checks, effects
-- ===========================================================================
if B.missionPos then
  local baseMissionPos = B.missionPos
  function B.missionPos(m)
    local war = B.war
    if m.type == "SHIPSTRIKE" or m.type == "SHIPESCORT" then
      local s = war.state.shipping[m.target]
      return s and B.shipPos(s)
    elseif m.type == "AMPHIB" then
      local rec = B.packages and B.packages[m.target]
      local u = rec and unitsOf(rec.strike)[1]
      if u then return u:getPoint() end
      return rec and rec.landing
    elseif m.type == "SCUD" then
      for _, b in ipairs(war:scuds()) do if b.id == m.target then return B.scudPos(b) end end
    elseif m.type == "POPUP" then
      local p = war.state.popups[m.target]
      return p and B.popupPos(p)
    end
    return baseMissionPos(m)
  end
end

local baseDetect = B.detect
function B.detect()
  baseDetect()
  local war = B.war
  for uname, p in pairs(B.players) do
    local m = p.mission and war.state.missions[p.mission]
    local u = ok(Unit.getByName, uname)
    if m and m.status == "open" and alive(u) and not m.escortOk then
      local km = (m.type == "AMPHIB" and XC().amphib.escortKm) or (m.type == "SHIPESCORT" and XC().shipping.escortKm)
      local tp = km and B.missionPos(m)
      if tp and dist2D(u:getPoint(), tp) <= km * 1000 then
        m.escortOk = true
        trigger.action.outTextForGroup(p.gid, "On station - stay with them until they arrive.", 10)
      end
    end
  end
end

if B.EFFECT then
  B.EFFECT.AMPHIB = "Be within 20 km of the landing helicopters before they land. Then support the fight ashore (CAS)."
  B.EFFECT.SHIPSTRIKE = "Sink the supply ship before it docks - its whole cargo is lost."
  B.EFFECT.SHIPESCORT = "Be within 20 km of the supply ship; it counts when the ship docks."
  B.EFFECT.SCUD = "The launcher moves on about 15 min after firing - find it fast (a launcher and its truck)."
  B.EFFECT.POPUP = "Shoulder-launched or mobile SAM: it was seen here. Stay high or out of range until you have it."
end

-- ===========================================================================
-- Map: SCUD and pop-up contacts
-- ===========================================================================
local baseDrawIntel = B.drawIntel
function B.drawIntel()
  baseDrawIntel()
  local war = B.war
  if not war.fogOfWar then return end
  for _, side in ipairs({ "blue", "red" }) do
    for key, c in pairs(war.state.contacts[side]) do
      local p
      if c.kind == "scud" then
        for _, b in ipairs(war:scuds()) do
          if "scud:" .. b.id == key then p = B.scudPos({ node = c.node, off = c.off }) end
        end
      elseif c.kind == "popup" then
        local pp = war.state.popups[c.popup]
        p = pp and B.popupPos(pp)
      end
      if p then
        local isFresh = war:isFresh(side, key)
        local ec = DCC.config.colours[otherSide(side)]
        local col = { ec[1], ec[2], ec[3], isFresh and 1 or 0.45 }
        B.nextMark = (B.nextMark or DCC.config.markIdBase) + 1
        B.intelMarks[#B.intelMarks + 1] = B.nextMark
        trigger.action.circleToAll(B.COAL[side], B.nextMark, { x = p.x, y = 0, z = p.z },
          c.kind == "scud" and 4000 or 5000, col, { ec[1], ec[2], ec[3], 0.12 }, 2, true, "")
        B.nextMark = B.nextMark + 1
        B.intelMarks[#B.intelMarks + 1] = B.nextMark
        trigger.action.textToAll(B.COAL[side], B.nextMark, { x = p.x + 5500, y = 0, z = p.z }, col,
          { 0, 0, 0, 0.35 }, 10, true, (c.label or c.kind) .. (isFresh and "" or " (last seen)"))
      end
    end
  end
end

-- ===========================================================================
-- Announcements
-- ===========================================================================
local OWN = { amphib_ashore = true, shipping_out = true, shipping_in = true, shipping_sunk = true,
              scud_destroyed = true, popup_killed = true }
local baseAnnounce = B.announce
function B.announce(events)
  baseAnnounce(events)
  for _, ev in ipairs(events) do
    if OWN[ev.kind] and ev.side then say(ev.side, ev.text, 12) end
    if ev.kind == "shipping_sunk" and ev.side then say(otherSide(ev.side), ev.text, 12) end
    if ev.kind == "scud" and ev.side then
      say(ev.side, ev.text, 20)
      if ev.node then B.scudImpact(ev.node) end
    end
  end
end

-- ===========================================================================
-- 10. Night illumination
-- ===========================================================================
-- One flare (DCS illumination bomb) above p.
function B.flare(p)
  local c = XC().illum
  local gx, gz = p.x + (math.random() - 0.5) * 800, p.z + (math.random() - 0.5) * 800
  local h = ok(land.getHeight, { x = gx, y = gz }) or 0
  return ok(trigger.action.illuminationBomb, { x = gx, y = h + c.heightM, z = gz }, c.power)
end

-- At night the troops fighting at a base light it up whenever players are near.
function B.autoIllumination()
  local war, c = B.war, XC().illum
  if not war:isNight() then return end
  B.x3.lit = B.x3.lit or {}
  local now, seen = timer.getTime(), {}
  for _, mv in pairs(war.state.moves) do
    local p = mv.status == "fighting" and B.nodePos[mv.to]
    if p and not seen[mv.to] then
      seen[mv.to] = true
      local near = false
      for _, pp in ipairs(B.playerPositions()) do if dist2D(pp, p) <= c.autoKm * 1000 then near = true end end
      if near and now - (B.x3.lit[mv.to] or -1e9) >= c.everySec then
        B.x3.lit[mv.to] = now
        B.flare(p)
      end
    end
  end
end

-- F10 > Support > Illumination on my map mark: mortars / artillery from an own
-- base within 30 km fire a string of flares over the mark.
function B.callIllumination(uname)
  local p = B.players[uname]
  if not p then return end
  local war, c = B.war, XC().illum
  local function tell(t) trigger.action.outTextForGroup(p.gid, t, 12) end
  B.x3.illumAt = B.x3.illumAt or {}
  local left = c.callCooldownMin * 60 - (timer.getTime() - (B.x3.illumAt[p.side] or -1e9))
  if left > 0 then return tell(string.format("The mortars are reloading - %d min.", math.ceil(left / 60))) end
  local m = B.newestMark and B.newestMark(p.side, p)
  if not m then return tell("Put a mark on the F10 map first (your side, within 15 min).") end
  local node = B.nearestNodeOf(m.pos, p.side, c.callKm * 1000)
  if not node then return tell(string.format("No friendly base within %d km of the mark.", c.callKm)) end
  if war.paySupport and not war:paySupport(node, c.callSU) then
    return tell(war:nodeName(node) .. " has no supply to spare for flares.")
  end
  B.x3.illumAt[p.side] = timer.getTime()
  for i = 1, c.callFlares do
    timer.scheduleFunction(function() B.flare(m.pos) end, nil, timer.getTime() + 10 + (i - 1) * 60)
  end
  trigger.action.outTextForCoalition(B.COAL[p.side], string.format(
    "%s: illumination from %s - %d flares over the mark, one a minute.", p.name, war:nodeName(node), c.callFlares), 12)
end

if B.buildSupportMenu then
  local baseSupport = B.buildSupportMenu
  function B.buildSupportMenu(p)
    baseSupport(p)
    if p and p.gid and p.supportMenu then
      missionCommands.addCommandForGroup(p.gid, "Illumination on my map mark", p.supportMenu, B.callIllumination, p.unit)
    end
  end
end

-- ===========================================================================
-- Loops
-- ===========================================================================
local basePoll = B.opsPoll
function B.opsPoll()
  basePoll()
  B.reconcileShipping()
  B.reconcileScuds()
  B.reconcilePopups()
  B.autoIllumination()
end

local baseTick = B.opsTick
function B.opsTick()
  baseTick()
  local war = B.war
  if online() then
    local per = DCC.config.tickSeconds / 60
    for _, side in ipairs({ "blue", "red" }) do
      if war.rng:next() < per / XC().amphib.minutes then B.launchAmphib(side) end
    end
  end
  B.planShipStrikes()
  B.carrierWing()
end

local baseInit = B.init
function B.init(war, theater, catalog)
  baseInit(war, theater, catalog)
  B.x3 = fresh()
end
