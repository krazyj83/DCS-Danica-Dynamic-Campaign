-- ============================================================================
-- Danica Dynamic Campaign - DCS bridge, phase 2: logistics and warehouses
-- ----------------------------------------------------------------------------
-- Load after dcc_dcs.lua. Adds to DCC.dcs:
--
--   * Convoys  - a supply convoy on a road touching a live node is spawned as
--                real trucks (catalog.convoy). Every 30 s the trucks are
--                polled: dead trucks shrink the cargo, a dead convoy delivers
--                nothing. Its lead truck's position is its progress.
--   * Airlifts - always spawned as a real transport aircraft (catalog.transport)
--                in the air over its origin, flying to land at its destination.
--                Shot down = cargo lost. Landed = cargo delivered.
--   * Warehouses (dynamic spawn) - each airbase's DCS warehouse holds the
--                OWNER's player aircraft at the model's counts and 0 of the
--                enemy's. Read before each tick (players took or brought
--                aircraft), written after (captures, restocks).
--   * Slot guard - a player who spawns at a base their side does not own is
--                removed with a message (protects fixed slots after a capture).
-- ============================================================================

DCC = DCC or {}
local U = DCC.util
local B = DCC.dcs
B.cargo = {}           -- move id -> { group, size, base, kind, failed, born }

local function dist2D(a, b)
  local dx, dz = a.x - b.x, a.z - b.z
  return math.sqrt(dx * dx + dz * dz)
end

local function wp(x, z, action, speed, extra)
  local p = { x = x, y = z, type = "Turning Point", action = action, speed = speed,
              speed_locked = true, ETA = 0, ETA_locked = false, formation_template = "" }
  if extra then for k, v in pairs(extra) do p[k] = v end end
  return p
end

local function roadPoint(x, z)
  local ok, rx, rz = pcall(land.getClosestPointOnRoads, "roads", x, z)
  if ok and rx and rz then return rx, rz end
  return x, z
end

-- ---------------------------------------------------------------------------
-- Which cargo moves should exist in DCS
-- ---------------------------------------------------------------------------
function B.desiredCargo()
  local want = {}
  for mid, mv in pairs(B.war.state.moves) do
    if mv.cargo then
      if mv.kind == "airlift" then want[mid] = mv
      elseif B.liveNodes[mv.from] or B.liveNodes[mv.to] or (B.forced and B.forced[mid]) then want[mid] = mv end
    end
  end
  return want
end

-- ---------------------------------------------------------------------------
-- Spawning
-- ---------------------------------------------------------------------------
function B.convoyTypes(side)
  local entry = B.catalog.convoy[side]
  for _, t in ipairs(entry.units) do
    if not B.validType(t) then return entry.fallback end
  end
  return entry.units
end

function B.spawnConvoy(mv)
  local types = B.convoyTypes(mv.side)
  local n = math.max(1, math.ceil(#types * (mv.health or 1) - 1e-6))
  local a, b = B.nodePos[mv.from], B.nodePos[mv.to]
  local start = { x = a.x + (b.x - a.x) * mv.progress, z = a.z + (b.z - a.z) * mv.progress }
  local s = DCC.config.liveSpeedMps * 0.8      -- loaded trucks are a bit slower
  local r1x, r1z = roadPoint(start.x, start.z)
  local r2x, r2z = roadPoint(b.x, b.z)
  local gname = "DCC_" .. mv.id
  local units = {}
  for i = 1, n do
    units[i] = { name = gname .. "_" .. i, type = types[i], skill = "Average",
                 x = start.x + (i - 1) * 25, y = start.z, heading = 0, playerCanDrive = false }
  end
  local data = { name = gname, task = "Ground Nothing", units = units, route = { points = {
    wp(start.x, start.z, "Off Road", s), wp(r1x, r1z, "On Road", s),
    wp(r2x, r2z, "On Road", s), wp(b.x, b.z, "Off Road", s) } } }
  local ok, err = pcall(coalition.addGroup, B.countryId(mv.side), Group.Category.GROUND, data)
  B.cargo[mv.id] = { group = gname, size = n, base = mv.health or 1, kind = "convoy",
                     failed = not ok, born = timer.getTime() }
  if not ok then U.log("convoy spawn %s failed: %s", mv.id, tostring(err)) end
end

function B.transportType(side)
  local entry = B.catalog.transport[side]
  if B.validType(entry.type) then return entry.type end
  return entry.fallback
end

function B.spawnAirlift(mv)
  local t = B.transportType(mv.side)
  local a, b = B.nodePos[mv.from], B.nodePos[mv.to]
  local p = U.clamp(mv.progress, 0, 0.95)
  local x, z = a.x + (b.x - a.x) * p, a.z + (b.z - a.z) * p
  local alt = math.max(a.y, b.y) + 2500
  local speed = DCC.config.supply.airliftSpeedKmh / 3.6
  local fuel = 10000
  local ok, desc = pcall(Unit.getDescByName, t)
  if ok and type(desc) == "table" and desc.fuelMassMax then fuel = desc.fuelMassMax end
  local abName = B.airbases[mv.to]
  local ab = abName and Airbase.getByName(abName)
  local landing = { type = "Land", action = "Landing", alt = 0, alt_type = "RADIO" }
  if ab then landing.airdromeId = ab:getID() end
  local gname = "DCC_" .. mv.id
  local heading = math.atan2(b.z - z, b.x - x)
  local data = {
    name = gname, task = "Transport",
    units = { { name = gname .. "_1", type = t, skill = "High", x = x, y = z, alt = alt, alt_type = "BARO",
                speed = speed, heading = heading, payload = { fuel = fuel, flare = 60, chaff = 60, gun = 100 },
                callsign = { 1, 1, 1, ["name"] = "Ford11" }, onboard_num = "010" } },
    route = { points = {
      wp(x, z, "Turning Point", speed, { alt = alt, alt_type = "BARO" }),
      wp(b.x, b.z, "Landing", speed, landing),
    } },
  }
  local okAdd, err = pcall(coalition.addGroup, B.countryId(mv.side), Group.Category.AIRPLANE, data)
  B.cargo[mv.id] = { group = gname, size = 1, base = mv.health or 1, kind = "airlift",
                     failed = not okAdd, born = timer.getTime() }
  if not okAdd then U.log("airlift spawn %s failed: %s", mv.id, tostring(err)) end
end

function B.despawnCargo(mid, rec)
  local g = Group.getByName(rec.group)
  if g and g:isExist() then g:destroy() end
  B.cargo[mid] = nil
end

-- ---------------------------------------------------------------------------
-- Read-back
-- ---------------------------------------------------------------------------
function B.pollCargo(mid, rec)
  local war = B.war
  local mv = war.state.moves[mid]
  if not mv or rec.failed then return end
  local g = Group.getByName(rec.group)
  local alive, lead = 0, nil
  if g and g:isExist() then
    for _, u in ipairs(g:getUnits() or {}) do
      if u:isExist() and u:getLife() >= 1 then alive = alive + 1; lead = lead or u end
    end
  end
  war:setCargoHealth(mid, rec.base * alive / rec.size)
  mv = war.state.moves[mid]
  if not mv or not lead then return end

  local a, b = B.nodePos[mv.from], B.nodePos[mv.to]
  local d = dist2D(lead:getPoint(), b)
  local total = math.max(dist2D(a, b), 1)
  local p = 1 - d / total
  if rec.kind == "airlift" then
    -- Delivered once the transport is down near the destination.
    local landed = lead.inAir and not lead:inAir()
    if landed and d < 6000 then p = 1 else p = math.min(p, 0.97) end
    -- Safety: a transport circling for 3x its flight time delivers anyway.
    local expect = total / (DCC.config.supply.airliftSpeedKmh / 3.6)
    if timer.getTime() - rec.born > 3 * expect + 600 then p = 1 end
  elseif d <= DCC.config.captureRadiusKm * 1000 then
    p = 1
  end
  war:setProgress(mid, p)
end

function B.reconcileCargo()
  local want = B.desiredCargo()
  for mid, rec in pairs(B.cargo) do
    if not want[mid] then
      if B.war.state.moves[mid] then B.pollCargo(mid, rec) end   -- keep its losses
      B.despawnCargo(mid, rec)
    end
  end
  for mid, mv in pairs(want) do
    if not B.cargo[mid] and B.war.state.moves[mid] then
      if mv.kind == "airlift" then B.spawnAirlift(mv) else B.spawnConvoy(mv) end
    end
  end
end

function B.pollAllCargo()
  for mid, rec in pairs(B.cargo) do B.pollCargo(mid, rec) end
end

-- ---------------------------------------------------------------------------
-- Warehouses: player aircraft per airbase follow the owner
-- ---------------------------------------------------------------------------
local function warehouseOf(id)
  local name = B.airbases[id]
  local ab = name and Airbase.getByName(name)
  if not ab or not ab.getWarehouse then return nil end
  local ok, w = pcall(ab.getWarehouse, ab)
  return ok and w or nil
end

-- DCS -> model: what players took off with or landed.
function B.readWarehouses()
  local war = B.war
  for id in pairs(B.airbases) do
    local ns, w = war.state.nodes[id], warehouseOf(id)
    if w and ns.air then
      for t in pairs(ns.air) do
        local ok, n = pcall(w.getItemCount, w, t)
        if ok and type(n) == "number" then war:setAircraft(id, t, n) end
      end
    end
  end
end

-- model -> DCS: owner's types at the model's counts, enemy's types at 0.
function B.writeWarehouses()
  local war = B.war
  for id in pairs(B.airbases) do
    local ns, w = war.state.nodes[id], warehouseOf(id)
    if w and ns.air then
      local enemy = U.otherSide(ns.side)
      for _, t in ipairs(war:aircraftTypes(enemy)) do
        if ns.air[t] == nil then pcall(w.setItem, w, t, 0) end   -- shared types stay
      end
      for t, n in pairs(ns.air) do pcall(w.setItem, w, t, n) end
    end
  end
end

-- ---------------------------------------------------------------------------
-- Slot guard
-- ---------------------------------------------------------------------------
function B.nearestNode(pos, maxM)
  local best, bestD
  for id, p in pairs(B.nodePos) do
    local d = dist2D(pos, p)
    if d <= maxM and (not bestD or d < bestD) then best, bestD = id, d end
  end
  return best
end

function B.onBirth(unit)
  if not unit or not unit.getPlayerName then return end
  local ok, pname = pcall(unit.getPlayerName, unit)
  if not ok or not pname then return end
  local id = B.nearestNode(unit:getPoint(), 5000)
  if not id then return end
  local side = (unit:getCoalition() == B.COAL.blue) and "blue" or "red"
  if B.war.state.nodes[id].side ~= side then
    trigger.action.outTextForUnit(unit:getID(), string.format(
      "%s is held by %s. Pick a slot at a base your side owns.", B.war:nodeName(id),
      B.war.state.nodes[id].side:upper()), 20)
    pcall(function() unit:destroy() end)
    U.log("slot guard: removed %s at enemy-held %s", tostring(pname), id)
  end
end

-- ---------------------------------------------------------------------------
-- Status text extensions
-- ---------------------------------------------------------------------------
function B.supplyLines(side)
  local war = B.war
  local lines = {}
  lines[#lines + 1] = string.format("Your supply: %d SU in stock", math.floor(war:supplySummary()[side]))
  local convoys, lifts, dry = 0, 0, {}
  for _, mv in pairs(war.state.moves) do
    if mv.side == side and mv.kind == "convoy" then convoys = convoys + 1 end
    if mv.side == side and mv.kind == "airlift" then lifts = lifts + 1 end
  end
  for _, id in ipairs(war.T.order) do
    local ns = war.state.nodes[id]
    if ns.side == side and ns.outOfSupply then dry[#dry + 1] = war:nodeName(id) end
  end
  lines[#lines + 1] = string.format("On the move: %d convoys, %d airlifts", convoys, lifts)
  if #dry > 0 then lines[#lines + 1] = "OUT OF SUPPLY: " .. table.concat(dry, ", ") end
  return lines
end
