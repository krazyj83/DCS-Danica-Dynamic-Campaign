-- ============================================================================
-- Danica Dynamic Campaign - DCS bridge: air assault gunship escort (v0.49).
-- Load after dcc_dcs_ext4.lua.
-- ----------------------------------------------------------------------------
-- When a player who took an AIRASSAULT mission is airborne in a helicopter,
-- an AI gunship pair (template DCC_TPL_<side>_gunship: AH-64D / Mi-24P) takes
-- off from the own base nearest the target, flies low to the landing zone and
-- attacks ground units around it until it is out of time or ammunition. One
-- pair per mission, paid from the side's AI attack pool (lost gunships are
-- gone from it, survivors return to it).
-- ============================================================================

DCC = DCC or {}
local B = DCC.dcs
local U = DCC.util

local function AA() return DCC.config.ext5.airAssault end
local function ok(fn, ...) local s, r = pcall(fn, ...); if s then return r end end
local function alive(u) return u ~= nil and ok(u.isExist, u) == true and (ok(u.getLife, u) or 0) >= 1 end

B.x5 = { escorts = {} }   -- mission id -> gunship group name

local function waypoint(x, z, alt, speed, task)
  return { x = x, y = z, alt = alt, alt_type = "RADIO", type = "Turning Point", action = "Turning Point",
           speed = speed, speed_locked = true, ETA = 0, ETA_locked = false, task = task }
end

local function combo(tasks)
  for i, t in ipairs(tasks) do t.number, t.auto, t.enabled = i, false, true end
  return { id = "ComboTask", params = { tasks = tasks } }
end

-- Own base nearest the target (where the gunships take off from).
local function launchBase(side, target)
  local war, best, bestD = B.war, nil, nil
  for _, id in ipairs(war.T.order) do
    local ns, p = war.state.nodes[id], B.nodePos[id]
    if ns.side == side and p then
      local dx, dz = p.x - target.x, p.z - target.z
      local d = math.sqrt(dx * dx + dz * dz)
      if not bestD or d < bestD then best, bestD = id, d end
    end
  end
  return best
end

-- Spawn the gunship pair for mission m. Returns the group name or nil.
function B.spawnGunships(m)
  local side, cfg = m.side, AA()
  local tpl = B.findTemplate("DCC_TPL_" .. side .. "_gunship")
  if not tpl then
    if not B.x5.warned then U.log("air assault: template DCC_TPL_%s_gunship not found - regenerate the mission", side) end
    B.x5.warned = true
    return nil
  end
  local war = B.war
  if not war:airAvailable(side, "attack", #tpl.units) then return nil end
  local target = B.nodePos[m.target]
  local from = launchBase(side, target)
  local fp = from and B.nodePos[from] or target
  local hdg = math.atan2(target.z - fp.z, target.x - fp.x)
  local sp = { x = fp.x + math.cos(hdg) * 1500, z = fp.z + math.sin(hdg) * 1500 }
  local gname = string.format("DCC_GUNSHIP_%s_%s", side, m.id)
  local data = U.copy(tpl)
  data.name, data.lateActivation, data.groupId, data.task = gname, nil, nil, "CAS"
  for i, u in ipairs(data.units) do
    u.unitId = nil
    u.name = gname .. "_" .. i
    u.x, u.y, u.alt, u.alt_type = sp.x + (i - 1) * 60, sp.z + (i - 1) * 60, cfg.altM, "RADIO"
    u.speed, u.heading = cfg.speedMs, hdg
  end
  -- hold short of the landing zone, then work over it
  local hold = { x = target.x - math.cos(hdg) * cfg.standoffKm * 1000, z = target.z - math.sin(hdg) * cfg.standoffKm * 1000 }
  local attack = combo({
    { id = "EngageTargetsInZone", params = { point = { x = target.x, y = target.z }, zoneRadius = cfg.zoneKm * 1000,
      targetTypes = { "Ground Units" }, priority = 0 } },
    { id = "Orbit", params = { pattern = "Circle", altitude = cfg.altM, speed = cfg.speedMs * 0.6 } } })
  data.route = { points = {
    waypoint(sp.x, sp.z, cfg.altM, cfg.speedMs, combo({})),
    waypoint(hold.x, hold.z, cfg.altM, cfg.speedMs, combo({})),
    waypoint(target.x, target.z, cfg.altM, cfg.speedMs * 0.6, attack) } }
  local s, err = pcall(coalition.addGroup, B.countryId(side), Group.Category.HELICOPTER, data)
  if not s then U.log("air assault: gunship spawn failed: %s", tostring(err)); return nil end
  war:airTake(side, "attack", #data.units)
  B.sorties[gname] = { side = side, role = "attack", kind = "GUNSHIP", born = timer.getTime(), life = cfg.lifeSeconds,
                       size = #data.units, alive = #data.units, node = m.target }
  trigger.action.outTextForCoalition(B.COAL[side], string.format("Command: gunships airborne from %s to cover the air "
    .. "assault on %s.", from and war:nodeName(from) or "the rear", war:nodeName(m.target)), 15)
  return gname
end

-- Launch the escort once a mission taker is airborne in a helicopter.
function B.airAssaultTick()
  for _, p in pairs(B.players or {}) do
    local m = p.heli and p.mission and B.war.state.missions[p.mission]
    if m and m.type == "AIRASSAULT" and m.status == "open" and not B.x5.escorts[m.id] then
      local u = ok(Unit.getByName, p.unit)
      if u and alive(u) and ok(u.inAir, u) then
        B.x5.escorts[m.id] = B.spawnGunships(m) or false   -- false: tried (no template / no aircraft) - not again
      end
    end
  end
end

-- v0.55: a bridge takes 2000 lb of bombs on the span - not a helicopter job (no BRIDGE on their board)
local baseCanFly = B.canFly
function B.canFly(p, m)
  if m and m.type == "BRIDGE" and p and p.heli then return false end
  return baseCanFly(p, m)
end

local basePoll = B.opsPoll
function B.opsPoll()
  basePoll()
  local s, err = pcall(B.airAssaultTick)
  if not s then U.log("ERROR air assault: %s", tostring(err)) end
end

if B.EFFECT then
  B.EFFECT.AIRASSAULT = "Load troops at the named base (F10 > CTLD > Load troops), fly to the target and set them down "
    .. "within 3 km of it: they attack at once. When you are airborne, a pair of AI gunships flies ahead to clear "
    .. "the landing zone. Several helicopters landing there fight as one assault."
end

local baseInit = B.init
function B.init(war, theater, catalog)
  baseInit(war, theater, catalog)
  B.x5 = { escorts = {} }
end
