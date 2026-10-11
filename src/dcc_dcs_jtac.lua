-- ============================================================================
-- Danica Dynamic Campaign - DCS bridge: JTAC for CAS missions.
-- Load after dcc_dcs_world.lua.
-- ----------------------------------------------------------------------------
-- When a player takes a CAS mission, a friendly JTAC team (an invisible,
-- immortal light vehicle) sets up jtac.standoffKm from the battle on the
-- friendly side. Every 10 seconds it picks the nearest live enemy vehicle
-- within jtac.searchKm of the battle and keeps a laser (code jtac.laserCode)
-- and an IR pointer on it, following it as it moves and switching when it
-- dies. The pilot's F10 > Missions > JTAC menu: report target (type, MGRS,
-- code), mark with smoke, next target. The team packs up when the mission
-- ends.
-- ============================================================================

DCC = DCC or {}
local B = DCC.dcs
local U = DCC.util

B.jtacs = {}   -- mission id -> { group, side, node, target, laser, ir, code }

local function JC() return DCC.config.jtac end
local function ok(fn, ...) local s, r = pcall(fn, ...); if s then return r end end
local function alive(u) return u ~= nil and ok(u.isExist, u) == true and (ok(u.getLife, u) or 0) >= 1 end
local function dist2D(a, b)
  local dx, dz = a.x - b.x, a.z - b.z
  return math.sqrt(dx * dx + dz * dz)
end

local function friendlyNeighbour(side, node)
  local war = B.war
  local best, bestD
  for nb in pairs(war.T.nodes[node].nb) do
    if war.state.nodes[nb].side == side then
      local d = dist2D(B.nodePos[nb], B.nodePos[node])
      if not bestD or d < bestD then best, bestD = nb, d end
    end
  end
  return best
end

function B.spawnJtac(m)
  if B.jtacs[m.id] then return B.jtacs[m.id] end
  local side, node = m.side, m.target
  local types = B.catalog.jtac and B.catalog.jtac[side] or {}
  local t
  for _, c in ipairs(types) do if B.validType(c) then t = c; break end end
  if not t then return nil end
  local tp = B.nodePos[node]
  local from = friendlyNeighbour(side, node)
  local fp = from and B.nodePos[from] or { x = tp.x - 1, z = tp.z }
  local dx, dz = fp.x - tp.x, fp.z - tp.z
  local len = math.max(1, math.sqrt(dx * dx + dz * dz))
  local s = JC().standoffKm * 1000
  local x, z = tp.x + dx / len * s, tp.z + dz / len * s
  local gname = "DCC_JTAC_" .. m.id
  local data = { name = gname, task = "Ground Nothing",
    units = { { name = gname .. "_1", type = t, skill = "Excellent", x = x, y = z, heading = 0, playerCanDrive = false } },
    route = { points = { { x = x, y = z, type = "Turning Point", action = "Off Road", speed = 0,
                           ETA = 0, ETA_locked = false } } } }
  if not pcall(coalition.addGroup, B.countryId(side), Group.Category.GROUND, data) then return nil end
  local g = ok(Group.getByName, gname)
  local ctl = g and ok(g.getController, g)
  if ctl then
    pcall(ctl.setCommand, ctl, { id = "SetInvisible", params = { value = true } })
    pcall(ctl.setCommand, ctl, { id = "SetImmortal", params = { value = true } })
    if AI and AI.Option and AI.Option.Ground then
      pcall(ctl.setOption, ctl, AI.Option.Ground.id.ROE, AI.Option.Ground.val.ROE.WEAPON_HOLD)
    end
  end
  local rec = { group = gname, side = side, node = node, code = JC().laserCode, mission = m.id }
  B.jtacs[m.id] = rec
  return rec
end

function B.removeJtac(mid)
  local rec = B.jtacs[mid]
  if not rec then return end
  if rec.laser then pcall(rec.laser.destroy, rec.laser) end
  if rec.ir then pcall(rec.ir.destroy, rec.ir) end
  local g = ok(Group.getByName, rec.group)
  if g and ok(g.isExist, g) then g:destroy() end
  B.jtacs[mid] = nil
end

-- Enemy vehicles near the battle: spawned platoons of the other side.
function B.jtacCandidates(rec)
  local war, out = B.war, {}
  local center = B.nodePos[rec.node]
  for pid, srec in pairs(B.spawned) do
    local pl = war.state.platoons[pid]
    if pl and pl.side ~= rec.side then
      local g = ok(Group.getByName, srec.group)
      if g and ok(g.isExist, g) then
        for _, u in ipairs(g:getUnits() or {}) do
          if alive(u) and dist2D(u:getPoint(), center) <= JC().searchKm * 1000 then out[#out + 1] = u end
        end
      end
    end
  end
  return out
end

function B.jtacPick(rec, skipCurrent)
  local g = ok(Group.getByName, rec.group)
  local me = g and g:getUnit(1)
  if not alive(me) then return nil end
  local mp = me:getPoint()
  local best, bestD
  for _, u in ipairs(B.jtacCandidates(rec)) do
    if not (skipCurrent and rec.target == u:getName()) then
      local d = dist2D(mp, u:getPoint())
      if not bestD or d < bestD then best, bestD = u, d end
    end
  end
  return best, me
end

-- Keep the laser on the current target (or a new one).
function B.jtacUpdate(rec, forceNew)
  local target = rec.target and ok(Unit.getByName, rec.target)
  local me
  if forceNew or not alive(target) then
    target, me = B.jtacPick(rec, forceNew)
    rec.target = target and target:getName() or nil
    if rec.laser then pcall(rec.laser.destroy, rec.laser); rec.laser = nil end
    if rec.ir then pcall(rec.ir.destroy, rec.ir); rec.ir = nil end
  end
  if not target then return nil end
  if not me then
    local g = ok(Group.getByName, rec.group)
    me = g and g:getUnit(1)
  end
  if not alive(me) then return nil end
  local p = target:getPoint()
  local aim = { x = p.x, y = p.y + 2, z = p.z }
  if rec.laser then
    pcall(rec.laser.setPoint, rec.laser, aim)
    if rec.ir then pcall(rec.ir.setPoint, rec.ir, aim) end
  elseif Spot then
    rec.laser = ok(Spot.createLaser, me, { x = 0, y = 2, z = 0 }, aim, rec.code)
    rec.ir = ok(Spot.createInfraRed, me, { x = 0, y = 2, z = 0 }, aim)
  end
  return target
end

local function mgrs(p)
  local lat, lon = coord.LOtoLL(p)
  local m = ok(coord.LLtoMGRS, lat, lon)
  if not m then return string.format("%.4f %.4f", lat, lon) end
  return string.format("%s %s %05d %05d", m.UTMZone, m.MGRSDigraph, m.Easting, m.Northing)
end

-- ---------------------------------------------------------------------------
-- Pilot commands
-- ---------------------------------------------------------------------------
local function jtacOf(uname)
  local p = B.players[uname]
  if not p then return nil end
  local m = p.mission and B.war.state.missions[p.mission]
  if not m or m.type ~= "CAS" or m.status ~= "open" then
    trigger.action.outTextForGroup(p.gid, "No JTAC: take a CAS mission first.", 10)
    return nil, p
  end
  return B.jtacs[m.id] or B.spawnJtac(m), p
end

function B.jtacReport(uname)
  local rec, p = jtacOf(uname)
  if not rec then return end
  local t = B.jtacUpdate(rec)
  if not t then
    trigger.action.outTextForGroup(p.gid, "JTAC: no enemy vehicles in sight at " .. B.war:nodeName(rec.node) ..
      " yet. Stand by.", 15)
    return
  end
  trigger.action.outTextForGroup(p.gid, string.format(
    "JTAC: lasing %s, code %d, IR pointer on.\nMGRS %s\n%d hostile vehicles in the area.",
    ok(t.getTypeName, t) or "vehicle", rec.code, mgrs(t:getPoint()), #B.jtacCandidates(rec)), 30)
end

function B.jtacSmoke(uname)
  local rec, p = jtacOf(uname)
  if not rec then return end
  local t = B.jtacUpdate(rec)
  if not t then trigger.action.outTextForGroup(p.gid, "JTAC: nothing to mark.", 10); return end
  local tp = t:getPoint()
  pcall(trigger.action.smoke, { x = tp.x, y = tp.y, z = tp.z }, trigger.smokeColor and trigger.smokeColor.Red or 1)
  trigger.action.outTextForGroup(p.gid, "JTAC: red smoke on the target.", 10)
end

function B.jtacNext(uname)
  local rec, p = jtacOf(uname)
  if not rec then return end
  local t = B.jtacUpdate(rec, true)
  if t then B.jtacReport(uname) else trigger.action.outTextForGroup(p.gid, "JTAC: no other target.", 10) end
end

-- ---------------------------------------------------------------------------
-- Hooks
-- ---------------------------------------------------------------------------
local baseBuildMenu = B.buildMenu
function B.buildMenu(p)
  baseBuildMenu(p)
  if not p.menu then return end
  local m = p.mission and B.war.state.missions[p.mission]
  if m and m.type == "CAS" then
    local j = missionCommands.addSubMenuForGroup(p.gid, "JTAC", p.menu)
    missionCommands.addCommandForGroup(p.gid, "Report target", j, B.jtacReport, p.unit)
    missionCommands.addCommandForGroup(p.gid, "Mark with smoke", j, B.jtacSmoke, p.unit)
    missionCommands.addCommandForGroup(p.gid, "Next target", j, B.jtacNext, p.unit)
  end
end

local baseTake = B.takeMission
function B.takeMission(args)
  baseTake(args)
  local p = B.players[args.unit]
  local m = p and p.mission and B.war.state.missions[p.mission]
  if m and m.type == "CAS" and m.id == args.mid then
    if B.spawnJtac(m) then
      trigger.action.outTextForGroup(p.gid, string.format(
        "JTAC team moving up to %s. Laser code %d. F10 > Missions > JTAC.", B.war:nodeName(m.target),
        JC().laserCode), 15)
    end
  end
end

-- Every 10 s (detection loop): lase; pack up when the mission is over.
function B.jtacTick()
  for mid, rec in pairs(B.jtacs) do
    local m = B.war.state.missions[mid]
    if not m or m.status ~= "open" then B.removeJtac(mid) else B.jtacUpdate(rec) end
  end
end

local baseDetect = B.detect
function B.detect()
  baseDetect()
  B.jtacTick()
end
