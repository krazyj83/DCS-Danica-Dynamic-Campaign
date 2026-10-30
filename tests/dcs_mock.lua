-- ============================================================================
-- A small fake of the DCS mission scripting API, enough to run the bridge and
-- main loop offline. It is not DCS: units do not fight, and positions use a
-- flat projection. It catches wiring bugs (wrong calls, nil fields, broken
-- save/restore) before a server ever loads the mission.
-- ============================================================================

MOCK = { time = 0, groups = {}, statics = {}, players = {}, marks = {}, texts = {}, groupTexts = {},
         flags = {}, scheduled = {}, handlers = {}, missingTypes = {}, menus = {}, groupMenus = {},
         cargoMass = {}, smokes = 0, nextGroupId = 100 }

env = {
  mission = { theatre = "Caucasus", coalition = {} },
  info = function(m) if MOCK.verbose then print(m) end end,
  error = function(m) print("ENV ERROR: " .. m) end,
}

-- Flat projection around 42N 42E, metres. x = north, z = east (like DCS).
local KX, KZ = 111000, 111000 * math.cos(math.rad(42))
coord = {
  LLtoLO = function(lat, lon, alt) return { x = (lat - 42) * KX, y = alt or 0, z = (lon - 42) * KZ } end,
  LOtoLL = function(p) return 42 + p.x / KX, 42 + p.z / KZ, p.y or 0 end,
  LLtoMGRS = function() return { UTMZone = "38T", MGRSDigraph = "KM", Easting = 12345, Northing = 67890 } end,
}

land = {
  SurfaceType = { LAND = 1, SHALLOW_WATER = 2, WATER = 3, ROAD = 4, RUNWAY = 5 },
  getHeight = function() return 0 end,
  getSurfaceType = function() return 1 end,
  getClosestPointOnRoads = function(_, x, z) return x, z end,
  -- line of sight: open unless a test puts a "ridge" in the way (MOCK.ridges = { {x, z, r} })
  isVisible = function(a, b)
    for _, r in ipairs(MOCK.ridges or {}) do
      for i = 1, 19 do
        local t = i / 20
        local x, z = a.x + (b.x - a.x) * t, a.z + (b.z - a.z) * t
        if (x - r[1]) ^ 2 + (z - r[2]) ^ 2 <= r[3] ^ 2 then return false end
      end
    end
    return true
  end,
}

-- AI options and weapons (phase 4)
AI = { Option = { Ground = { id = { ROE = 0, ALARM_STATE = 9 },
  val = { ROE = { OPEN_FIRE = 2, RETURN_FIRE = 3, WEAPON_HOLD = 4 }, ALARM_STATE = { AUTO = 0, GREEN = 1, RED = 2 } } },
  Air = { id = { ECM_USING = 13 }, val = { ECM_USING = { NEVER_USE = 0, USE_IF_ONLY_LOCK_BY_RADAR = 1,
    USE_IF_DETECTED_LOCK_BY_RADAR = 2, ALWAYS_USE = 3 } } } } }
Weapon = { GuidanceType = { INS = 1, IR = 2, RADAR_ACTIVE = 3, RADAR_SEMI_ACTIVE = 4, RADAR_PASSIVE = 5 } }
function MOCK.weapon(guidance, target)
  return { getDesc = function() return { guidance = guidance } end, getTarget = function() return target end }
end

timer = {
  getTime = function() return MOCK.time end,
  getAbsTime = function() return (MOCK.absBase or 43200) + MOCK.time end,   -- noon unless a test says otherwise
  scheduleFunction = function(fn, arg, t)
    MOCK.scheduled[#MOCK.scheduled + 1] = { fn = fn, arg = arg, t = t }
  end,
}

-- Advance mission time, running scheduled functions and moving groups.
function MOCK.advance(seconds)
  local target = MOCK.time + seconds
  while true do
    table.sort(MOCK.scheduled, function(a, b) return a.t < b.t end)
    local nxt = MOCK.scheduled[1]
    if not nxt or nxt.t > target then break end
    table.remove(MOCK.scheduled, 1)
    MOCK.moveGroups(nxt.t - MOCK.time)
    MOCK.time = nxt.t
    local again = nxt.fn(nxt.arg, nxt.t)
    if again then MOCK.scheduled[#MOCK.scheduled + 1] = { fn = nxt.fn, arg = nxt.arg, t = again } end
  end
  MOCK.moveGroups(target - MOCK.time)
  MOCK.time = target
end

world = {
  event = { S_EVENT_TAKEOFF = 3, S_EVENT_LAND = 4, S_EVENT_CRASH = 5, S_EVENT_EJECTION = 6, S_EVENT_DEAD = 8,
            S_EVENT_PILOT_DEAD = 9, S_EVENT_MISSION_END = 12, S_EVENT_BIRTH = 15, S_EVENT_PLAYER_LEAVE_UNIT = 21,
            S_EVENT_KILL = 28, S_EVENT_SHOT = 1, S_EVENT_PLAYER_ENTER_UNIT = 20, S_EVENT_HIT = 2,
            S_EVENT_UNIT_LOST = 30, S_EVENT_ENGINE_STARTUP = 18, S_EVENT_ENGINE_SHUTDOWN = 19 },
  addEventHandler = function(h) MOCK.handlers[#MOCK.handlers + 1] = h end,
  getAirbases = function()
    local list = {}
    for _, ab in pairs(MOCK.airbases) do list[#list + 1] = ab end
    return list
  end,
}

function MOCK.fire(e)
  for _, h in ipairs(MOCK.handlers) do h:onEvent(e) end
end

Object = { Category = { UNIT = 1, WEAPON = 2, STATIC = 3, BASE = 4 } }
function Object.getCategory(o) return o.objCat or Object.Category.UNIT end

-- ---------------------------------------------------------------------------
-- Airbases: created from the theater pack, one deliberately renamed to test
-- the nearest-airfield fallback.
-- ---------------------------------------------------------------------------
local AB = {}
AB.__index = AB
function AB:getPoint() return { x = self.p.x, y = 0, z = self.p.z } end
function AB:getName() return self.name end
function AB:getDesc() return { category = 0 } end
function AB:getCoalition() return self.coalition end
function AB:setCoalition(c) self.coalition = c end
function AB:autoCapture(v) self.auto = v end
function AB:getID() return self.id end

local WH = {}
WH.__index = WH
function WH:getItemCount(t) return self.items[t] or 0 end
function WH:setItem(t, n) self.items[t] = n end
function WH:addItem(t, n) self.items[t] = (self.items[t] or 0) + n end
function AB:getWarehouse() return self.wh end

Airbase = { Category = { AIRDROME = 0 } }
function Airbase.getByName(n) return MOCK.airbases[n] end

function MOCK.buildAirbases(theater)
  MOCK.airbases = {}
  for _, n in ipairs(theater.nodes) do
    if n.airbase then
      local name = n.airbase
      if name == "Mineralnye Vody" then name = "Mineralnye Vody Airport" end -- renamed on purpose
      local p = coord.LLtoLO(n.lat + 0.01, n.lon, 0) -- ~1 km off the node position
      MOCK.abId = (MOCK.abId or 0) + 1
      -- Like the generated mission: every player type listed, 1 of each.
      local items = {}
      for _, side in ipairs({ "blue", "red" }) do
        local air = DCC_CATALOGS.modern.aircraft[side]
        for _, t in ipairs(air.planes) do items[t] = 1 end
        for _, t in ipairs(air.helicopters) do items[t] = 1 end
      end
      MOCK.airbases[name] = setmetatable({ name = name, p = p, coalition = 0, id = MOCK.abId,
                                           wh = setmetatable({ items = items }, WH) }, AB)
    end
  end
end

-- AI templates as the generated mission has them (late-activated groups).
function MOCK.addTemplates()
  local function tpl(name, t, n)
    local units = {}
    for i = 1, n or 2 do
      units[i] = { name = name .. " Pilot #" .. i, type = t, unitId = i, x = 0, y = 0, alt = 6000,
                   payload = { fuel = 3000, pylons = { [1] = { CLSID = "{X}" } } } }
    end
    return { name = name, lateActivation = true, groupId = 999, task = "CAP", units = units, route = { points = {} } }
  end
  local coal = {}
  for side, cid in pairs({ blue = 80, red = 81 }) do
    local planes, helos = {}, {}
    for role, spec in pairs(DCC_CATALOGS.modern.aiAir[side]) do
      local list = spec.helicopter and helos or planes
      list[#list + 1] = tpl("DCC_TPL_" .. side .. "_" .. role, spec.type, spec.size or 2)
    end
    coal[side] = { country = { { id = cid, plane = { group = planes }, helicopter = { group = helos } } } }
  end
  env.mission.coalition = coal
end

-- ---------------------------------------------------------------------------
-- Groups and units
-- ---------------------------------------------------------------------------
country = { id = { CJTF_BLUE = 80, CJTF_RED = 81 } }
coalition = {
  side = { NEUTRAL = 0, RED = 1, BLUE = 2 },
  getPlayers = function(side) return MOCK.players[side] or {} end,
}

local UnitMT = {}
UnitMT.__index = UnitMT
MOCK.UnitMT = UnitMT
function UnitMT:isExist() return self.alive end
function UnitMT:getLife() return self.alive and 100 or 0 end
function UnitMT:getPoint() return { x = self.x, y = self.alt or 0, z = self.z } end
function UnitMT:getName() return self.name end
function UnitMT:getID() return self.id or 1 end
function UnitMT:inAir() return self.air == true end
function UnitMT:getCoalition() return self.coal end
function UnitMT:getPlayerName() return self.player end
function UnitMT:getTypeName() return self.type or "F-16C_50" end
function UnitMT:getGroup() return self.group end
function UnitMT:getDesc()
  local c = (self.group and self.group.category == 0) and Unit.Category.AIRPLANE
         or (self.group and self.group.category == 1) and Unit.Category.HELICOPTER
         or (self.group and self.group.category == 3) and Unit.Category.SHIP or Unit.Category.GROUND_UNIT
  return { category = c, typeName = self.type }
end
function UnitMT:destroy() self.alive = false; self.destroyed = true end

local GroupMT = {}
GroupMT.__index = GroupMT
MOCK.GroupMT = GroupMT
function GroupMT:isExist() return self.exists end
function GroupMT:getUnits() return self.units end
function GroupMT:getUnit(i) return self.units[i] end
function GroupMT:getID() return self.id end
function GroupMT:getName() return self.name end
-- One controller per group: records options, reports what a test says it detects (g.detected = { unit, ... }).
function GroupMT:getController()
  local g = self
  g.ctl = g.ctl or {
    setOption = function(_, id, v) g.options = g.options or {}; g.options[id] = v end,
    setCommand = function(_, c) g.commands = g.commands or {}; g.commands[c.id] = c.params and c.params.value end,
    setTask = function(_, t) g.lastTask = t end,
    pushTask = function(_, t) g.pushed = g.pushed or {}; table.insert(g.pushed, t) end,
    getDetectedTargets = function()
      local out = {}
      for _, u in ipairs(g.detected or {}) do out[#out + 1] = { object = u, visible = true } end
      return out
    end,
  }
  return g.ctl
end
function GroupMT:destroy() self.exists = false; MOCK.groups[self.name] = nil end

Group = { Category = { AIRPLANE = 0, HELICOPTER = 1, GROUND = 2, SHIP = 3 } }
function Group.getByName(n) return MOCK.groups[n] end

Unit = { Category = { AIRPLANE = 0, HELICOPTER = 1, GROUND_UNIT = 2, SHIP = 3 } }
function Unit.getDescByName(t)
  if MOCK.missingTypes[t] then error("unknown type " .. t) end
  return { typeName = t, fuelMassMax = 20000 }
end
function Unit.getByName(n)
  for _, g in pairs(MOCK.groups) do
    for _, u in ipairs(g.units) do if u.name == n then return u end end
  end
  for _, list in pairs(MOCK.players) do
    for _, u in ipairs(list) do if u.name == n then return u end end
  end
end

function coalition.addGroup(countryId, category, data)
  assert(type(countryId) == "number", "addGroup: country id must be a number")
  assert(category == Group.Category.GROUND or category == Group.Category.AIRPLANE or category == Group.Category.SHIP
    or category == Group.Category.HELICOPTER,
    "addGroup: bad category")
  assert(data.name and data.units and #data.units > 0, "addGroup: bad group data")
  assert(MOCK.groups[data.name] == nil, "addGroup: duplicate group name " .. data.name)
  assert(not data.lateActivation, "addGroup: a cloned template must not stay late-activated")
  MOCK.nextGroupId = MOCK.nextGroupId + 1
  local g = setmetatable({ name = data.name, exists = true, units = {}, route = data.route and data.route.points or {},
                          country = countryId, category = category, id = MOCK.nextGroupId, data = data }, GroupMT)
  local coal = (countryId == 80) and 2 or 1
  for i, u in ipairs(data.units) do
    assert(u.type and u.x and u.y, "addGroup: unit needs type, x, y")
    assert(u.name, "addGroup: unit needs a name")
    if category == Group.Category.AIRPLANE then
      assert(u.alt and u.payload and u.payload.fuel, "addGroup: aircraft need alt and payload.fuel")
    end
    g.units[i] = setmetatable({ name = u.name, type = u.type, x = u.x, z = u.y, alive = true, group = g,
                                coal = coal, air = (category == Group.Category.AIRPLANE or category == Group.Category.HELICOPTER),
                                alt = u.alt }, UnitMT)
  end
  MOCK.groups[data.name] = g
  return g
end

-- Groups of a coalition and category (AI and player groups).
function coalition.getGroups(coal, cat)
  local out = {}
  for _, g in pairs(MOCK.groups) do
    local u = g.units[1]
    if g.exists and u and u.coal == coal and (cat == nil or g.category == cat) then out[#out + 1] = g end
  end
  return out
end

-- Static objects (strike targets)
local StaticMT = {}
StaticMT.__index = StaticMT
MOCK.StaticMT = StaticMT
function StaticMT:isExist() return self.alive end
function StaticMT:getLife() return self.alive and 100 or 0 end
function StaticMT:getName() return self.name end
function StaticMT:destroy() self.alive = false; MOCK.statics[self.name] = nil end
StaticObject = {}
function StaticObject.getByName(n) return MOCK.statics[n] end
function coalition.addStaticObject(countryId, data)
  assert(type(countryId) == "number" and data.name and data.type and data.category and data.x and data.y,
    "addStaticObject: bad data")
  assert(MOCK.statics[data.name] == nil, "addStaticObject: duplicate name " .. data.name)
  local s = setmetatable({ name = data.name, type = data.type, x = data.x, z = data.y, alive = true,
                           coal = (countryId == 80) and 2 or ((countryId == 81) and 1 or 0),
                           objCat = Object.Category.STATIC }, StaticMT)
  MOCK.statics[data.name] = s
  return s
end

-- Move every group toward its last waypoint at the waypoint speed.
function MOCK.moveGroups(dt)
  if dt <= 0 then return end
  for _, g in pairs(MOCK.groups) do
    local last = g.route and g.route[#g.route]
    local speed = last and last.speed or 0
    if speed > 0 and not g.player then
      for _, u in ipairs(g.units) do
        local dx, dz = last.x - u.x, last.y - u.z
        local d = math.sqrt(dx * dx + dz * dz)
        if d > 1 then
          local step = math.min(d, speed * dt)
          u.x, u.z = u.x + dx / d * step, u.z + dz / d * step
        elseif g.category == Group.Category.AIRPLANE and last.type == "Land" then
          u.air = false                                  -- reached the airfield: landed
        end
      end
    end
  end
end

function MOCK.killGroup(name)
  local g = MOCK.groups[name]
  for _, u in ipairs(g.units) do u.alive = false end
end

function MOCK.addPlayer(side, x, z)
  MOCK.players[side] = MOCK.players[side] or {}
  local u = setmetatable({ name = "player", x = x, z = z, alive = true }, UnitMT)
  table.insert(MOCK.players[side], u)
  return u
end

-- A real player aircraft: own group, player name, fires the birth event.
function MOCK.spawnPlayer(coal, typeName, x, z, name, heli)
  MOCK.nextGroupId = MOCK.nextGroupId + 1
  local gname = "PLAYER_" .. MOCK.nextGroupId
  local g = setmetatable({ name = gname, exists = true, units = {}, route = {}, player = true,
                          category = heli and 1 or 0, id = MOCK.nextGroupId }, GroupMT)
  local u = setmetatable({ name = gname .. "_1", type = typeName, x = x, z = z, alt = 0, alive = true, coal = coal,
                           player = name or "Morten", group = g, air = false }, UnitMT)
  g.units[1] = u
  MOCK.groups[gname] = g
  MOCK.players[coal] = MOCK.players[coal] or {}
  table.insert(MOCK.players[coal], u)
  MOCK.fire({ id = world.event.S_EVENT_BIRTH, initiator = u })
  return u, g
end

-- ---------------------------------------------------------------------------
-- trigger, missionCommands
-- ---------------------------------------------------------------------------
local function addMark(kind) return function(coal, id, ...) MOCK.marks[id] = { kind = kind, coal = coal, args = { ... } } end end

trigger = {
  smokeColor = { Green = 0, Red = 1, White = 2, Orange = 3, Blue = 4 },
  action = {
    outText = function(t) MOCK.texts[#MOCK.texts + 1] = t end,
    outTextForCoalition = function(_, t) MOCK.texts[#MOCK.texts + 1] = t end,
    outTextForUnit = function(_, t) MOCK.texts[#MOCK.texts + 1] = t end,
    outTextForGroup = function(gid, t)
      MOCK.groupTexts[gid] = MOCK.groupTexts[gid] or {}
      table.insert(MOCK.groupTexts[gid], t)
      MOCK.texts[#MOCK.texts + 1] = t
    end,
    setUserFlag = function(f, v) MOCK.flags[f] = v end,
    removeMark = function(id) MOCK.marks[id] = nil end,
    lineToAll = addMark("line"),
    markupToAll = function(shape, coal, id, ...) MOCK.marks[id] = { kind = "markup" .. shape, coal = coal, args = { ... } } end,
    circleToAll = addMark("circle"),
    textToAll = addMark("text"),
    arrowToAll = addMark("arrow"),
    markToGroup = function(id, text, pos, gid) MOCK.marks[id] = { kind = "groupmark", gid = gid, args = { text } } end,
    smoke = function() MOCK.smokes = MOCK.smokes + 1 end,
    setUnitInternalCargo = function(name, mass) MOCK.cargoMass[name] = mass end,
  },
}

-- Group menus are kept as a tree so tests can "click" them.
missionCommands = {
  addSubMenuForCoalition = function(c, name) return { c, name } end,
  addCommandForCoalition = function(c, name, parent, fn, arg)
    MOCK.menus[#MOCK.menus + 1] = { coal = c, name = name, fn = fn, arg = arg }
  end,
  addSubMenuForGroup = function(gid, name, parent)
    MOCK.groupMenus[gid] = MOCK.groupMenus[gid] or {}
    local path = { gid = gid, name = name, parent = parent }
    table.insert(MOCK.groupMenus[gid], { sub = true, name = name, path = path, parent = parent })
    return path
  end,
  addCommandForGroup = function(gid, name, parent, fn, arg)
    MOCK.groupMenus[gid] = MOCK.groupMenus[gid] or {}
    table.insert(MOCK.groupMenus[gid], { name = name, parent = parent, fn = fn, arg = arg })
  end,
  removeItemForGroup = function(gid, path)
    local list = MOCK.groupMenus[gid] or {}
    local function under(item)
      local p = item.parent
      while p do if p == path then return true end; p = p.parent end
      return item.path == path
    end
    for i = #list, 1, -1 do if under(list[i]) then table.remove(list, i) end end
  end,
}

-- Click the first command in a group's menu whose text contains `text`.
function MOCK.click(gid, text)
  for _, item in ipairs(MOCK.groupMenus[gid] or {}) do
    if item.fn and item.name:find(text, 1, true) then item.fn(item.arg); return true end
  end
  return false
end

function MOCK.menuItems(gid)
  local out = {}
  for _, item in ipairs(MOCK.groupMenus[gid] or {}) do out[#out + 1] = item.name end
  return out
end

function MOCK.lastGroupText(gid)
  local l = MOCK.groupTexts[gid]
  return l and l[#l] or ""
end

-- File system: real files in a temp folder.
lfs = {
  writedir = function() return MOCK.writedir end,
  mkdir = function() return true end,
}

function MOCK.countMarks(kind)
  local n = 0
  for _, m in pairs(MOCK.marks) do if not kind or m.kind == kind then n = n + 1 end end
  return n
end

function MOCK.countGroups(prefix)
  local n = 0
  for name in pairs(MOCK.groups) do if not prefix or name:find(prefix, 1, true) == 1 then n = n + 1 end end
  return n
end

-- A player spawning in a slot (slot-guard test).
function MOCK.playerBirth(coal, x, z)
  local u, g = MOCK.spawnPlayer(coal, "F-16C_50", x, z, "Morten")
  return u
end

function MOCK.groupsOfCategory(cat)
  local n = 0
  for _, g in pairs(MOCK.groups) do if g.category == cat and not g.player then n = n + 1 end end
  return n
end

-- Lasers and IR pointers (JTAC)
Spot = {}
local SpotMT = {}
SpotMT.__index = SpotMT
function SpotMT:setPoint(p) self.point = p end
function SpotMT:destroy() self.dead = true; MOCK.spots[self.id] = nil end
local function newSpot(kind, src, off, p, code)
  MOCK.spots = MOCK.spots or {}
  MOCK.spotId = (MOCK.spotId or 0) + 1
  local sp = setmetatable({ id = MOCK.spotId, kind = kind, source = src, point = p, code = code }, SpotMT)
  MOCK.spots[sp.id] = sp
  return sp
end
function Spot.createLaser(src, off, p, code) return newSpot("laser", src, off, p, code) end
function Spot.createInfraRed(src, off, p) return newSpot("ir", src, off, p) end

-- Fog (DCS 2.9.10+)
world.weather = {
  setFogThickness = function(t) MOCK.fog = MOCK.fog or {}; MOCK.fog.thickness = t end,
  setFogVisibilityDistance = function(v) MOCK.fog = MOCK.fog or {}; MOCK.fog.visibility = v end,
}

-- A FARP (an Airbase object with a warehouse), as the generated mission has them.
function MOCK.addFarp(name, x, z, coal)
  MOCK.abId = (MOCK.abId or 0) + 1
  local wh = setmetatable({ items = {} }, getmetatable(MOCK.airbases[next(MOCK.airbases)].wh))
  for _, t in ipairs(DCC_CATALOGS.modern.aircraft[coal == 2 and "blue" or "red"].helicopters) do wh.items[t] = 1 end
  MOCK.airbases[name] = setmetatable({ name = name, p = { x = x, z = z }, coalition = coal, id = MOCK.abId,
                                       wh = wh, farp = true }, getmetatable(MOCK.airbases[next(MOCK.airbases)]))
  return MOCK.airbases[name]
end

-- A ship group placed in the mission editor.
function MOCK.addShipGroup(name, coal, x, z, types)
  MOCK.nextGroupId = MOCK.nextGroupId + 1
  local g = { name = name, exists = true, units = {}, route = {}, category = 3, id = MOCK.nextGroupId }
  setmetatable(g, MOCK.GroupMT)
  for i, t in ipairs(types) do
    local u = { name = name .. "_" .. i, type = t, x = x + i * 500, z = z, alive = true, coal = coal, group = g }
    g.units[i] = setmetatable(u, MOCK.UnitMT)
  end
  MOCK.groups[name] = g
  return g
end

-- Scenery (bridges): MOCK.scenery = { obj, ... } with getTypeName/getPoint/isExist/getLife
Object.Category.SCENERY = 5
world.VolumeType = { SPHERE = 2 }
function world.searchObjects(cat, vol, fn)
  for _, o in ipairs(MOCK.scenery or {}) do
    local p, c = o:getPoint(), vol.params.point
    if (p.x - c.x) ^ 2 + (p.z - c.z) ^ 2 <= vol.params.radius ^ 2 then
      if fn(o) == false then break end
    end
  end
end
function MOCK.addBridge(x, z)
  MOCK.scenery = MOCK.scenery or {}
  local b = { x = x, z = z, alive = true }
  function b:getTypeName() return "Bridge_Concrete" end
  function b:getPoint() return { x = self.x, y = 0, z = self.z } end
  function b:isExist() return self.alive end
  function b:getLife() return self.alive and 100 or 0 end
  table.insert(MOCK.scenery, b)
  return b
end
