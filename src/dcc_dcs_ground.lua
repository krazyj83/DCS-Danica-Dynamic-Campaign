-- ============================================================================
-- Danica Dynamic Campaign - DCS bridge: ground war additions.
-- Load after dcc_dcs_air.lua.
-- ----------------------------------------------------------------------------
--   Artillery      - batteries the model placed next to a battle are spawned
--                    when their base is live and shell the battle for real
--                    (FireAtPoint every 2 min). Killed: War:batteryHit.
--   Skirmishes     - small fights that always run on contested roads, even far
--                    from players, so CAS pilots always find a front to work.
--                    Rebuilt 30 min after they are wiped out; they follow the front.
--   Fortifications - one bunker per fortification level at live bases.
--                    Destroyed: War:fortHit.
--   Bridges        - real DCS bridges on the roads, found once at mission start
--                    (world.searchObjects). A destroyed bridge closes its road.
-- ============================================================================

DCC = DCC or {}
local B = DCC.dcs
local U = DCC.util

B.batteries  = {}   -- battery id -> { group, node, lastFire }
B.skirmishes = {}   -- road key -> { groups = {blue, red}, born, deadSince }
B.forts      = {}   -- node id -> { names = {k = name}, side }
B.bridgeObjs = {}   -- road key -> scenery object

local SIDES = { "blue", "red" }
local function GC() return DCC.config.ground end
local function ok(fn, ...) local s, r = pcall(fn, ...); if s then return r end end
local function alive(u) return u ~= nil and ok(u.isExist, u) == true and (ok(u.getLife, u) or 0) >= 1 end
local function dist2D(a, b)
  local dx, dz = a.x - b.x, a.z - b.z
  return math.sqrt(dx * dx + dz * dz)
end
local function unitsOf(gname)
  local g = gname and ok(Group.getByName, gname)
  local out = {}
  if g and ok(g.isExist, g) then
    for _, u in ipairs(g:getUnits() or {}) do if alive(u) then out[#out + 1] = u end end
  end
  return out
end
local function destroyGroup(gname)
  local g = gname and ok(Group.getByName, gname)
  if g and ok(g.isExist, g) then g:destroy() end
end
local function firstValid(list)
  local out = {}
  for _, t in ipairs(list or {}) do if B.validType(t) then out[#out + 1] = t end end
  return out
end
local function groundGroup(side, gname, types, x, z, spacing)
  local units = {}
  for i, t in ipairs(types) do
    units[i] = { name = gname .. "_" .. i, type = t, skill = "Average", x = x + (i - 1) * (spacing or 30),
                 y = z + (i % 2) * 20, heading = 0, playerCanDrive = false }
  end
  if #units == 0 then return nil end
  local okAdd = pcall(coalition.addGroup, B.countryId(side), Group.Category.GROUND, { name = gname,
    task = "Ground Nothing", units = units, route = { points = { { x = x, y = z, type = "Turning Point",
    action = "Off Road", speed = 0, ETA = 0, ETA_locked = false } } } })
  return okAdd and gname or nil
end
local function roadKey(a, b) if a < b then return a .. "|" .. b end return b .. "|" .. a end

-- ===========================================================================
-- 1. Artillery
-- ===========================================================================
function B.reconcileArtillery()
  local war = B.war
  for _, side in ipairs(SIDES) do
    for _, b in ipairs(war:batteries(side)) do
      local rec = B.batteries[b.id]
      -- read back
      if rec and #unitsOf(rec.group) == 0 then
        war:batteryHit(b.id)
        destroyGroup(rec.group)
        B.batteries[b.id] = nil
        rec = nil
      end
      local want = b.status == "up" and b.node and B.liveNodes[b.node]
      if rec and (not want or rec.node ~= b.node) then
        destroyGroup(rec.group)
        B.batteries[b.id] = nil
        rec = nil
      end
      if want and not rec then
        local p = B.scatter(b.node, b.id .. "9")
        local g = groundGroup(side, "DCC_ARTY_" .. b.id, firstValid(B.catalog.artillery[side]), p.x, p.z, 60)
        if g then B.batteries[b.id] = { group = g, node = b.node, lastFire = 0 } end
      end
    end
  end
end

-- Shell the battles next to each live battery.
function B.artilleryFire()
  local war, now = B.war, timer.getTime()
  for id, rec in pairs(B.batteries) do
    if now - rec.lastFire >= 120 then
      local side
      for _, s in ipairs(SIDES) do
        for _, b in ipairs(war:batteries(s)) do if b.id == id then side = s end end
      end
      for _, mid in ipairs(U.sortedKeys(war.state.moves)) do
        local mv = war.state.moves[mid]
        local nearBattle = mv.status == "fighting" and (mv.to == rec.node or war.T.nodes[mv.to].nb[rec.node])
        if nearBattle and (mv.side ~= side or war.state.nodes[mv.to].side ~= side) then
          -- aim at the enemy: the attackers if we defend, the garrison if we attack
          local tp = B.nodePos[mv.to]
          if war.state.nodes[mv.to].side == side then
            local a = B.nodePos[mv.from]
            tp = { x = tp.x + (a.x - tp.x) * 0.15, z = tp.z + (a.z - tp.z) * 0.15 }
          end
          local g = ok(Group.getByName, rec.group)
          local ctl = g and ok(g.getController, g)
          if ctl then
            pcall(ctl.pushTask, ctl, { id = "FireAtPoint", params = { point = { x = tp.x, y = tp.z }, radius = 300,
              expendQty = 12, expendQtyEnabled = true } })
            rec.lastFire = now
            rec.firedAt = tp
          end
          break
        end
      end
    end
  end
end

-- ===========================================================================
-- 2. Skirmishes on the front
-- ===========================================================================
function B.frontRoads()
  local war, out = B.war, {}
  for _, e in ipairs(war.T.edges) do
    local sa, sb = war.state.nodes[e.a].side, war.state.nodes[e.b].side
    if sa ~= sb and not e.sea and not war:roadClosed(e.a, e.b) then out[#out + 1] = e end
  end
  table.sort(out, function(x, y) return x.km < y.km end)   -- short roads: the hottest contact
  return out
end

function B.reconcileSkirmishes()
  if not GC().skirmishes then return end
  local war, now = B.war, timer.getTime()
  local want = {}
  for i, e in ipairs(B.frontRoads()) do
    if i > GC().skirmishMax then break end
    want[roadKey(e.a, e.b)] = e
  end
  for k, rec in pairs(B.skirmishes) do
    if not want[k] then
      for _, g in pairs(rec.groups) do destroyGroup(g) end
      B.skirmishes[k] = nil
    end
  end
  for k, e in pairs(want) do
    local rec = B.skirmishes[k]
    local wiped = rec and (#unitsOf(rec.groups.blue) == 0 or #unitsOf(rec.groups.red) == 0)
    if rec and wiped then
      rec.deadSince = rec.deadSince or now
      if now - rec.deadSince >= 1800 then
        for _, g in pairs(rec.groups) do destroyGroup(g) end
        B.skirmishes[k], rec = nil, nil
      end
    end
    if not rec then
      local pa, pb = B.nodePos[e.a], B.nodePos[e.b]
      local mx, mz = (pa.x + pb.x) / 2, (pa.z + pb.z) / 2
      local dx, dz = pb.x - pa.x, pb.z - pa.z
      local len = math.max(1, math.sqrt(dx * dx + dz * dz))
      dx, dz = dx / len, dz / len
      local groups = {}
      B.skirmishSerial = (B.skirmishSerial or 0) + 1
      for _, node in ipairs({ e.a, e.b }) do
        local side = war.state.nodes[node].side
        local sgn = (node == e.a) and -1 or 1
        local types = {}
        local roleTypes = B.unitTypes("MECH_PLT", side)
        for i = 1, GC().skirmishPerSide do types[i] = roleTypes[i] or roleTypes[1] end
        groups[side] = groundGroup(side, string.format("DCC_SKIRM_%d_%s", B.skirmishSerial, side), types,
          mx + sgn * dx * 700, mz + sgn * dz * 700, 40)
      end
      B.skirmishes[k] = { groups = groups, born = now }
    end
  end
end

-- ===========================================================================
-- 3. Fortifications
-- ===========================================================================
function B.reconcileForts()
  local war = B.war
  for _, id in ipairs(war.T.order) do
    local ns = war.state.nodes[id]
    local rec = B.forts[id]
    local want = B.liveNodes[id] and ns.fort > 0
    if rec and (not want or rec.side ~= ns.side) then
      for _, n in pairs(rec.names) do local s = ok(StaticObject.getByName, n); if s then pcall(s.destroy, s) end end
      B.forts[id], rec = nil, nil
    end
    if want then
      rec = rec or { names = {}, side = ns.side }
      B.forts[id] = rec
      local count = 0
      for _ in pairs(rec.names) do count = count + 1 end
      for k = count + 1, ns.fort do
        local types = B.catalog.fortifications or { "Sandbox" }
        local c = B.nodePos[id]
        local ang = k * 2.4
        local name = string.format("DCC_FORT_%s_%d_%d", id, k, war.state.tick)
        if pcall(coalition.addStaticObject, B.countryId(ns.side), { name = name, type = types[(k - 1) % #types + 1],
            category = "Fortifications", x = c.x + 700 * math.cos(ang), y = c.z + 700 * math.sin(ang), heading = ang }) then
          rec.names[k] = name
        end
      end
    end
  end
end

-- a bunker destroyed
function B.onFortDead(name)
  for id, rec in pairs(B.forts) do
    for k, n in pairs(rec.names) do
      if n == name then
        rec.names[k] = nil
        B.war:fortHit(id)
        return true
      end
    end
  end
end

-- ===========================================================================
-- 4. Bridges
-- ===========================================================================
-- Find real bridges along every road once (scenery search, 2 km steps).
function B.findBridges()
  local war = B.war
  war.bridges = {}
  B.bridgeObjs = {}
  if not (world.searchObjects and Object.Category.SCENERY and world.VolumeType) then return 0 end
  for _, e in ipairs(war.T.edges) do
    if not e.sea then
      local na, nb = war.T.nodes[e.a], war.T.nodes[e.b]
      local steps = math.max(1, math.floor(e.km / 2))
      local found
      for i = 1, steps - 1 do
        if found then break end
        local p = U.lerp(na, nb, i / steps)
        local v = coord.LLtoLO(p.lat, p.lon, 0)
        pcall(world.searchObjects, Object.Category.SCENERY,
          { id = world.VolumeType.SPHERE, params = { point = { x = v.x, y = land.getHeight({ x = v.x, y = v.z }), z = v.z }, radius = 1200 } },
          function(obj)
            local t = (ok(obj.getTypeName, obj) or ""):lower()
            if t:find("bridge", 1, true) or t:find("most", 1, true) then found = obj; return false end
            return true
          end)
      end
      if found then
        local p = found:getPoint()
        war.bridges[#war.bridges + 1] = { a = e.a, b = e.b, pos = { x = p.x, z = p.z } }
        B.bridgeObjs[roadKey(e.a, e.b)] = found
      end
    end
  end
  U.log("bridges found on %d roads", #war.bridges)
  return #war.bridges
end

function B.pollBridges()
  local war = B.war
  for k, obj in pairs(B.bridgeObjs) do
    local a, b = k:match("^(.-)|(.+)$")
    local dead = not ok(obj.isExist, obj) or (ok(obj.getLife, obj) or 1) <= 0
    if dead and not war:roadClosed(a, b) and not (B.bridgeSeenDead or {})[k] then
      B.bridgeSeenDead = B.bridgeSeenDead or {}
      B.bridgeSeenDead[k] = true          -- the wreck stays; reopening is the engineers' crossing
      war:bridgeDown(a, b)
    end
  end
end

-- ===========================================================================
-- Hooks
-- ===========================================================================
local baseMissionPos = B.missionPos
function B.missionPos(m)
  if m.type == "BRIDGE" then
    for _, br in ipairs(B.war.bridges or {}) do
      if br.a .. "|" .. br.b == m.target then return { x = br.pos.x, y = 0, z = br.pos.z } end
    end
  elseif m.type == "ARTY" then
    local rec = B.batteries[m.target]
    local u = rec and unitsOf(rec.group)[1]
    if u then return u:getPoint() end
  end
  return baseMissionPos(m)
end

local baseIndex = B.intelIndex
function B.intelIndex()
  local idx = baseIndex()
  for id, rec in pairs(B.batteries) do
    local side
    for _, s in ipairs(SIDES) do for _, b in ipairs(B.war:batteries(s)) do if b.id == id then side = s end end end
    idx[rec.group] = { side = side, kind = "arty", group = rec.group, battery = id }
  end
  for _, rec in pairs(B.skirmishes) do
    for side, g in pairs(rec.groups) do idx[g] = { side = side, kind = "skirmish", group = g } end
  end
  return idx
end

local baseReport = B.report
function B.report(side, e, u, source)
  baseReport(side, e, u, source)
  if e and e.battery and e.side ~= side then
    B.war:addContact(side, "arty:" .. e.battery, { kind = "arty", node = B.batteries[e.battery] and
      B.batteries[e.battery].node, source = source, label = "artillery battery" })
  end
end

local baseOpsEvent = B.onOpsEvent
function B.onOpsEvent(e)
  if e.id == world.event.S_EVENT_DEAD and e.initiator then
    local n = ok(e.initiator.getName, e.initiator)
    if n and n:find("^DCC_FORT_") then B.onFortDead(n) end
  end
  baseOpsEvent(e)
end

local baseStatus = B.opsStatusLines
function B.opsStatusLines(side)
  local lines = baseStatus(side)
  local war = B.war
  local up, cut, forts = 0, 0, 0
  for _, b in ipairs(war:batteries(side)) do if b.status == "up" then up = up + 1 end end
  for _, id in ipairs(war.T.order) do
    local ns = war.state.nodes[id]
    if ns.side == side then
      if war:cutOff(id) then cut = cut + 1 end
      if ns.fort > 0 then forts = forts + 1 end
    end
  end
  lines[#lines + 1] = string.format("Artillery: %d batteries ready. Fortified bases: %d. Cut off: %d.", up, forts, cut)
  return lines
end

local basePoll = B.opsPoll
function B.opsPoll()
  basePoll()
  B.reconcileArtillery()
  B.artilleryFire()
  B.reconcileForts()
  B.pollBridges()
end

local baseTick = B.opsTick
function B.opsTick()
  baseTick()
  B.reconcileSkirmishes()
end

local baseInit = B.init
function B.init(war, theater, catalog)
  baseInit(war, theater, catalog)
  B.batteries, B.skirmishes, B.forts, B.bridgeSeenDead = {}, {}, {}, {}
  B.findBridges()
end
