-- ============================================================================
-- Danica Dynamic Campaign - DCS bridge, part 4: intel and fog of war
-- ----------------------------------------------------------------------------
-- Turns what each side's units can actually perceive into contacts in the war
-- model (dcc_intel.lua), and draws each side's own picture on the F10 map.
-- Load after dcc_dcs_ops.lua.
--
--   Sources (checked every intel.scanSeconds):
--     visual  - player aircraft see enemy ground units within visualKmGround
--               and aircraft within visualKmAir, if terrain does not block
--               the line of sight (land.isVisible)
--     sensor  - friendly AI (sorties, SAM sites, ground platoons) report what
--               their controllers detect (Controller.getDetectedTargets)
--     elint   - airborne friendly aircraft hear enemy SAM radars that are
--               switched on. The first fix is rough (elintBaseErrM) and every
--               new observation narrows it (x elintShrink, down to elintMinErrM)
--     recon / troops in contact - in the model (dcc_intel.lua)
--
--   SAM radars (EMCON): a site's radar is off until enemy aircraft come within
--   samWakeKm. When an anti-radiation missile is fired at it, it goes dark for
--   harmDarkSeconds - it survives, but it cannot shoot or be heard meanwhile.
--
--   Map layer (redrawn every intel.drawEverySeconds, per coalition):
--     enemy SAM threat ring + ELINT error circle (only when known)
--     enemy columns where they were seen, faded when stale
--     enemy garrisons seen at bases, recon reports, front-line estimates
--     enemy aircraft seen in the last airContactSeconds
--
-- With F10 view "Allies only" in the mission options, this layer is the only
-- way a player sees the enemy on the map.
-- ============================================================================

DCC = DCC or {}
local B = DCC.dcs
local U = DCC.util

B.intelMarks   = {}   -- mark ids of the intel layer
B.airContacts  = { blue = {}, red = {} }  -- unit name -> { pos, type, t } (not saved: aircraft move)
B.samDark      = {}   -- node id -> mission time until which the radar stays off
B.samAlarm     = {}   -- node id -> "red" / "green" last ordered
B.samAwake     = {}   -- node id -> true while enemy aircraft are within samWakeKm

local SIDES = { "blue", "red" }

local function IC() return DCC.config.intel end
local function ok(fn, ...) local s, r = pcall(fn, ...); if s then return r end end
local function alive(u) return u ~= nil and ok(u.isExist, u) == true end
local function dist2D(a, b)
  local dx, dz = a.x - b.x, a.z - b.z
  return math.sqrt(dx * dx + dz * dz)
end
local function v3(p) return { x = p.x, y = ok(land.getHeight, { x = p.x, y = p.z }) or 0, z = p.z } end
local function otherSide(s) return s == "blue" and "red" or "blue" end
local function sideOfCoal(c) return c == B.COAL.blue and "blue" or (c == B.COAL.red and "red" or nil) end

local function aglOf(u)
  local p = u:getPoint()
  return p.y - (ok(land.getHeight, { x = p.x, y = p.z }) or 0)
end

-- ---------------------------------------------------------------------------
-- 1. What exists: every spawned object the campaign knows, by DCS group name
-- ---------------------------------------------------------------------------
-- entry = { side, key, kind, node, mid, air, group }
function B.intelIndex()
  local war, idx = B.war, {}
  for pid, rec in pairs(B.spawned) do
    local pl = war.state.platoons[pid]
    if pl and not rec.failed then
      idx[rec.group] = { side = pl.side, key = rec.key, kind = rec.kind, node = rec.key:match("^g:(.+)"),
                         mid = rec.mid, role = pl.role, group = rec.group }
    end
  end
  for mid, rec in pairs(B.cargo or {}) do
    local mv = war.state.moves[mid]
    if mv then idx[rec.group] = { side = mv.side, key = "m:" .. mid, kind = "move", mid = mid,
                                  air = mv.kind == "airlift", group = rec.group } end
  end
  for id, rec in pairs(B.sams) do
    idx[rec.group] = { side = rec.side, key = "sam:" .. id, kind = "sam", node = id, group = rec.group }
  end
  for gname, s in pairs(B.sorties) do
    idx[gname] = { side = s.side, kind = "air", air = true, group = gname, ai = true }
  end
  return idx
end

-- Alive units of a group (lead first).
local function unitsOf(gname)
  local g = ok(Group.getByName, gname)
  local out = {}
  if g and ok(g.isExist, g) then
    for _, u in ipairs(g:getUnits() or {}) do if alive(u) and u:getLife() >= 1 then out[#out + 1] = u end end
  end
  return out
end

-- Player aircraft of a side (any player unit, registered for missions or not).
local function playerUnits(side)
  local out = {}
  for _, u in ipairs(coalition.getPlayers(B.COAL[side]) or {}) do
    if alive(u) then out[#out + 1] = u end
  end
  return out
end

-- ---------------------------------------------------------------------------
-- 2. Reporting a sighting
-- ---------------------------------------------------------------------------
-- side saw unit u, which belongs to index entry e (or is an enemy player).
function B.report(side, e, u, source)
  local war, pos = B.war, u:getPoint()
  if e and e.side == side then return end
  if not e or e.air then
    local name = u:getName()
    B.airContacts[side][name] = { pos = { x = pos.x, z = pos.z }, alt = pos.y,
      type = ok(u.getTypeName, u) or "aircraft", t = timer.getTime(), source = source }
    if not e or not e.mid then return end
  end
  if e.kind == "move" then
    war:spotMove(side, e.mid, source, { x = pos.x, z = pos.z })
  elseif e.kind == "garrison" then
    local key = "g:" .. e.node
    local c = war:contact(side, key)
    local groups = (c and war:isFresh(side, key) and c.groups) or {}
    groups[e.group] = #unitsOf(e.group)
    local n = 0
    for _, k in pairs(groups) do n = n + k end
    war:addContact(side, key, { kind = "garrison", node = e.node, source = source, groups = groups,
                                label = string.format("%d vehicles seen", n) })
  elseif e.kind == "sam" then
    war:addContact(side, "sam:" .. e.node, { kind = "sam", node = e.node, source = source,
      pos = { x = pos.x, z = pos.z }, err = 200, label = "SAM site" })
  end
end

-- ---------------------------------------------------------------------------
-- 3. Players' eyes
-- ---------------------------------------------------------------------------
function B.scanVisual(idx)
  local cfg = IC()
  -- enemy objects with a position, per side
  for _, side in ipairs(SIDES) do
    local eyes = playerUnits(side)
    if #eyes > 0 then
      local targets = {}
      for _, e in pairs(idx) do
        if e.side ~= side then
          for _, u in ipairs(unitsOf(e.group)) do targets[#targets + 1] = { e = e, u = u } end
        end
      end
      for _, u in ipairs(playerUnits(otherSide(side))) do targets[#targets + 1] = { u = u } end
      for _, eye in ipairs(eyes) do
        local ep = eye:getPoint()
        local from = { x = ep.x, y = ep.y + 2, z = ep.z }
        local seen = {}
        for _, t in ipairs(targets) do
          local gkey = t.e and t.e.group or t.u:getName()
          if not seen[gkey] then
            local tp = t.u:getPoint()
            local isAir = (not t.e) or t.e.air
            local range = (isAir and cfg.visualKmAir or cfg.visualKmGround) * (B.visualFactor and B.visualFactor(isAir) or 1)
            if dist2D(ep, tp) <= range * 1000 and ok(land.isVisible, from, { x = tp.x, y = tp.y + 2, z = tp.z }) then
              seen[gkey] = true
              B.report(side, t.e, t.u, "visual")
            end
          end
        end
      end
    end
  end
end

-- ---------------------------------------------------------------------------
-- 4. AI sensors
-- ---------------------------------------------------------------------------
function B.scanSensors(idx)
  local byUnit = {}
  for _, e in pairs(idx) do
    for _, u in ipairs(unitsOf(e.group)) do byUnit[u:getName()] = e end
  end
  for _, e in pairs(idx) do
    local g = ok(Group.getByName, e.group)
    local ctl = g and ok(g.getController, g)
    local list = ctl and ok(ctl.getDetectedTargets, ctl)
    for _, d in ipairs(list or {}) do
      local o = d.object
      if o and alive(o) and ok(Object.getCategory, o) == Object.Category.UNIT then
        local te = byUnit[o:getName()]
        if te then
          if te.side ~= e.side then B.report(e.side, te, o, "sensor") end
        elseif ok(o.getPlayerName, o) and sideOfCoal(o:getCoalition()) == otherSide(e.side) then
          B.report(e.side, nil, o, "sensor")
        end
      end
    end
  end
end

-- ---------------------------------------------------------------------------
-- 5. SAM radars: wake, dark, ELINT
-- ---------------------------------------------------------------------------
-- Airborne aircraft of a side: players and AI sorties.
local function airborne(side)
  local out = {}
  for _, u in ipairs(playerUnits(side)) do if ok(u.inAir, u) then out[#out + 1] = u end end
  for gname, s in pairs(B.sorties) do
    if s.side == side then for _, u in ipairs(unitsOf(gname)) do out[#out + 1] = u end end
  end
  return out
end

function B.samEmitting(id)
  local ns = B.war.state.nodes[id]
  return ns.sam and ns.sam.status == "up" and B.samAwake[id] == true
         and (B.samDark[id] or 0) <= timer.getTime()
end

local function setAlarm(id, want)
  if B.samAlarm[id] == want then return end
  local rec = B.sams[id]
  local g = rec and ok(Group.getByName, rec.group)
  local ctl = g and ok(g.getController, g)
  if not ctl then return end
  local AO = AI and AI.Option and AI.Option.Ground
  if AO then
    local val = (want == "red") and AO.val.ALARM_STATE.RED or AO.val.ALARM_STATE.GREEN
    pcall(ctl.setOption, ctl, AO.id.ALARM_STATE, val)
  end
  B.samAlarm[id] = want
end

function B.scanSams()
  local war, cfg = B.war, IC()
  local air = { blue = airborne("blue"), red = airborne("red") }
  for _, id in ipairs(war.T.order) do
    local ns = war.state.nodes[id]
    if ns.sam and ns.sam.status ~= "destroyed" then
      local pos, enemy = B.nodePos[id], otherSide(ns.side)
      local awake = false
      -- IADS: with an own early-warning radar or AWACS tracking the aircraft the site
      -- lights up at samWakeKm; on its own it only wakes when they are close (samCueKm)
      local cueKm = (DCC.config.air and DCC.config.air.samCueKm) or cfg.samWakeKm
      for _, u in ipairs(air[enemy]) do
        local d = dist2D(u:getPoint(), pos)
        if d <= cueKm * 1000 or (d <= cfg.samWakeKm * 1000 and (not B.cued or B.cued(ns.side, u))) then
          awake = true; break
        end
      end
      B.samAwake[id] = awake
      if B.sams[id] then setAlarm(id, B.samEmitting(id) and "red" or "green") else B.samAlarm[id] = nil end

      -- ELINT: the enemy's airborne aircraft hear an emitting radar
      if B.samEmitting(id) then
        for _, u in ipairs(air[enemy]) do
          local up = u:getPoint()
          if dist2D(up, pos) <= cfg.elintKm * 1000 and aglOf(u) >= cfg.elintMinAglM then
            B.elintFix(enemy, id)
            break
          end
        end
      end
    end
  end
end

-- One ELINT observation: a better fix than the last one.
function B.elintFix(side, id)
  local war, cfg = B.war, IC()
  local key = "sam:" .. id
  local c = war:contact(side, key)
  local err = cfg.elintBaseErrM
  if c and c.err and war:isFresh(side, key) then err = math.max(cfg.elintMinErrM, c.err * cfg.elintShrink) end
  local pos = B.nodePos[id]
  local a, r = math.random() * 2 * math.pi, math.random() * err
  war:addContact(side, key, { kind = "sam", node = id, source = "elint", err = err,
    pos = { x = pos.x + r * math.cos(a), z = pos.z + r * math.sin(a) }, label = "SAM radar" })
end

-- Anti-radiation missile fired: the targeted site switches off for a while.
function B.onShot(e)
  local w = e.weapon
  local desc = w and ok(w.getDesc, w)
  local passive = (Weapon and Weapon.GuidanceType and Weapon.GuidanceType.RADAR_PASSIVE) or 5
  if not desc or desc.guidance ~= passive then return end
  local shooter = e.initiator
  local sside = shooter and sideOfCoal(ok(shooter.getCoalition, shooter))
  if not sside then return end
  local id
  local tgt = ok(w.getTarget, w)
  local tname = tgt and ok(tgt.getName, tgt)
  if tname then id = tname:match("^DCC_SAM_(.-)_[rls]%d+$") end
  if not id then   -- no lock reported: the nearest emitting enemy site
    local sp, best = shooter:getPoint(), nil
    for _, nid in ipairs(B.war.T.order) do
      local ns = B.war.state.nodes[nid]
      if ns.side ~= sside and B.samEmitting(nid) then
        local d = dist2D(sp, B.nodePos[nid])
        if d <= 150000 and (not best or d < best) then id, best = nid, d end
      end
    end
  end
  if not id then return end
  local lo, hi = IC().harmDarkSeconds[1], IC().harmDarkSeconds[2]
  B.samDark[id] = timer.getTime() + lo + math.random() * (hi - lo)
  if B.sams[id] then setAlarm(id, "green") end
  U.log("SAM at %s goes dark (anti-radiation missile)", id)
end

-- ---------------------------------------------------------------------------
-- 6. The scan loop
-- ---------------------------------------------------------------------------
function B.intelScan()
  if not B.war.fogOfWar then return end
  local idx = B.intelIndex()
  B.scanVisual(idx)
  B.scanSensors(idx)
  B.scanSams()
  local now, keep = timer.getTime(), IC().airContactSeconds
  for _, side in ipairs(SIDES) do
    for name, c in pairs(B.airContacts[side]) do
      if now - c.t > keep then B.airContacts[side][name] = nil end
    end
  end
end

-- ---------------------------------------------------------------------------
-- 7. The map layer
-- ---------------------------------------------------------------------------
local function mark()
  B.nextMark = (B.nextMark or DCC.config.markIdBase) + 1
  B.intelMarks[#B.intelMarks + 1] = B.nextMark
  return B.nextMark
end

local SOURCE = { visual = "seen", sensor = "detected", elint = "ELINT", recon = "recon" }

local function ageText(war, c)
  local min = (war.state.tick - c.seen) * DCC.config.tickSeconds / 60
  if min < 1 then return "now" end
  if min < 90 then return string.format("%d min ago", math.floor(min + 0.5)) end
  return string.format("%.1f h ago", min / 60)
end

-- Where to draw a contact: where it was seen.
function B.contactPos(c)
  if c.pos then return c.pos end
  if c.kind == "move" and c.from and c.to then
    local a, b = B.nodePos[c.from], B.nodePos[c.to]
    local t = c.progress or 0
    return { x = a.x + (b.x - a.x) * t, z = a.z + (b.z - a.z) * t }
  end
  return c.node and B.nodePos[c.node]
end

function B.drawIntel()
  for _, id in ipairs(B.intelMarks) do trigger.action.removeMark(id) end
  B.intelMarks = {}
  local war = B.war
  if not war.fogOfWar then return end
  local cols = DCC.config.colours
  for _, side in ipairs(SIDES) do
    local coal, enemy = B.COAL[side], otherSide(side)
    local ec = cols[enemy]
    local contacts = war.state.contacts[side]

    for _, key in ipairs(U.sortedKeys(contacts)) do
      local c = contacts[key]
      local fresh = war:isFresh(side, key)
      local a = fresh and 1 or 0.45
      local col = { ec[1], ec[2], ec[3], a }
      local p = B.contactPos(c)
      if p then
        local P = v3(p)
        local txt = string.format("%s (%s %s)", c.label or c.kind, SOURCE[c.source] or c.source, ageText(war, c))
        if c.kind == "sam" then
          local ns = war.state.nodes[c.node]
          if ns.side == enemy then
            trigger.action.circleToAll(coal, mark(), P, 25000, col, { 0, 0, 0, 0 }, fresh and 2 or 3, true, "")
            if (c.err or 0) > 1000 then
              trigger.action.circleToAll(coal, mark(), P, c.err, col, { ec[1], ec[2], ec[3], 0.12 }, 3, true, "")
              txt = txt .. string.format(" +/-%.1f km", c.err / 1000)
            end
            trigger.action.textToAll(coal, mark(), { x = P.x - 26000, y = P.y, z = P.z }, col,
              { 0, 0, 0, 0.35 }, 10, true, txt)
          end
        elseif c.kind == "move" then
          trigger.action.circleToAll(coal, mark(), P, 800, col, { ec[1], ec[2], ec[3], 0.3 * a }, 1, true, "")
          trigger.action.textToAll(coal, mark(), { x = P.x + 1200, y = P.y, z = P.z + 800 }, col,
            { 0, 0, 0, 0.35 }, 10, true, txt)
        elseif c.kind == "garrison" or c.kind == "node" then
          if war.state.nodes[c.node].side == enemy then
            local off = (c.kind == "node") and 3000 or -3000
            trigger.action.textToAll(coal, mark(), { x = P.x + 4000 + off, y = P.y, z = P.z + 3000 }, col,
              { 0, 0, 0, 0.5 }, 10, true, (c.kind == "node" and "Recon: " or "") .. txt)
          end
        end
      end
    end

    -- front-line estimates: troops in contact know roughly what faces them
    for _, id in ipairs(war.T.order) do
      local est = war:frontEstimate(side, id)
      if est and not war:isFresh(side, "n:" .. id) then
        local P = B.nodePos[id]
        trigger.action.textToAll(coal, mark(), { x = P.x - 4000, y = P.y, z = P.z + 3000 }, ec,
          { 0, 0, 0, 0.35 }, 10, true, "est. " .. est)
      end
    end

    -- enemy aircraft seen in the last minutes
    local now = timer.getTime()
    for _, name in ipairs(U.sortedKeys(B.airContacts[side])) do
      local c = B.airContacts[side][name]
      local P = v3(c.pos)
      trigger.action.circleToAll(coal, mark(), P, 1500, ec, { 0, 0, 0, 0 }, 1, true, "")
      trigger.action.textToAll(coal, mark(), { x = P.x + 2000, y = P.y, z = P.z }, ec, { 0, 0, 0, 0.35 }, 10, true,
        string.format("%s %d ft (%ds ago)", c.type, math.floor(c.alt * 3.28084 / 1000 + 0.5) * 1000,
          math.floor(now - c.t)))
    end
  end
end

-- Lines for the status message: what this side knows.
function B.intelStatusLines(side)
  local war = B.war
  if not war.fogOfWar then return {} end
  local fresh, stale, sams = 0, 0, 0
  for key, c in pairs(war.state.contacts[side]) do
    if war:isFresh(side, key) then fresh = fresh + 1 else stale = stale + 1 end
    if c.kind == "sam" and war:isFresh(side, key) then sams = sams + 1 end
  end
  local air = 0
  for _ in pairs(B.airContacts[side]) do air = air + 1 end
  return { string.format("Intel: %d fresh contacts (%d SAM sites), %d stale, %d aircraft on the scope",
    fresh, sams, stale, air) }
end
