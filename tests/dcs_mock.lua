-- ============================================================================
-- A small fake of the DCS mission scripting API, enough to run the bridge and
-- main loop offline. It is not DCS: units do not fight, and positions use a
-- flat projection. It catches wiring bugs (wrong calls, nil fields, broken
-- save/restore) before a server ever loads the mission.
-- ============================================================================

MOCK = { time = 0, groups = {}, players = {}, marks = {}, texts = {}, flags = {},
         scheduled = {}, handlers = {}, missingTypes = {}, menus = {} }

env = {
  mission = { theatre = "Caucasus" },
  info = function(m) if MOCK.verbose then print(m) end end,
  error = function(m) print("ENV ERROR: " .. m) end,
}

-- Flat projection around 42N 42E, metres. x = north, z = east (like DCS).
coord = {
  LLtoLO = function(lat, lon, alt)
    return { x = (lat - 42) * 111000, y = alt or 0, z = (lon - 42) * 111000 * math.cos(math.rad(42)) }
  end,
}

land = {
  SurfaceType = { LAND = 1, SHALLOW_WATER = 2, WATER = 3, ROAD = 4, RUNWAY = 5 },
  getHeight = function() return 0 end,
  getSurfaceType = function() return 1 end,
  getClosestPointOnRoads = function(_, x, z) return x, z end,
}

timer = {
  getTime = function() return MOCK.time end,
  getAbsTime = function() return 43200 + MOCK.time end,
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
  event = { S_EVENT_MISSION_END = 12, S_EVENT_BIRTH = 15 },
  addEventHandler = function(h) MOCK.handlers[#MOCK.handlers + 1] = h end,
  getAirbases = function()
    local list = {}
    for _, ab in pairs(MOCK.airbases) do list[#list + 1] = ab end
    return list
  end,
}

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
function UnitMT:isExist() return self.alive end
function UnitMT:getLife() return self.alive and 100 or 0 end
function UnitMT:getPoint() return { x = self.x, y = 0, z = self.z } end
function UnitMT:getName() return self.name end
function UnitMT:getID() return self.id or 1 end
function UnitMT:inAir() return self.air == true end
function UnitMT:getCoalition() return self.coal end
function UnitMT:getPlayerName() return self.player end
function UnitMT:destroy() self.alive = false; self.destroyed = true end

local GroupMT = {}
GroupMT.__index = GroupMT
function GroupMT:isExist() return self.exists end
function GroupMT:getUnits() return self.units end
function GroupMT:destroy() self.exists = false; MOCK.groups[self.name] = nil end

Group = { Category = { AIRPLANE = 0, HELICOPTER = 1, GROUND = 2 } }
function Group.getByName(n) return MOCK.groups[n] end

Unit = {}
function Unit.getDescByName(t)
  if MOCK.missingTypes[t] then error("unknown type " .. t) end
  return { typeName = t, fuelMassMax = 20000 }
end

function coalition.addGroup(countryId, category, data)
  assert(type(countryId) == "number", "addGroup: country id must be a number")
  assert(category == Group.Category.GROUND or category == Group.Category.AIRPLANE, "addGroup: bad category")
  assert(data.name and data.units and #data.units > 0, "addGroup: bad group data")
  assert(MOCK.groups[data.name] == nil, "addGroup: duplicate group name " .. data.name)
  local g = setmetatable({ name = data.name, exists = true, units = {}, route = data.route.points,
                          country = countryId, category = category }, GroupMT)
  local coal = (countryId == 80) and 2 or 1
  for i, u in ipairs(data.units) do
    assert(u.type and u.x and u.y, "addGroup: unit needs type, x, y")
    if category == Group.Category.AIRPLANE then
      assert(u.alt and u.payload and u.payload.fuel, "addGroup: aircraft need alt and payload.fuel")
    end
    g.units[i] = setmetatable({ name = u.name, type = u.type, x = u.x, z = u.y, alive = true,
                                coal = coal, air = (category == Group.Category.AIRPLANE) }, UnitMT)
  end
  MOCK.groups[data.name] = g
  return g
end

-- Move every group toward its last waypoint at the waypoint speed.
function MOCK.moveGroups(dt)
  if dt <= 0 then return end
  for _, g in pairs(MOCK.groups) do
    local last = g.route[#g.route]
    local speed = last.speed or 0
    if speed > 0 then
      for _, u in ipairs(g.units) do
        local dx, dz = last.x - u.x, last.y - u.z
        local d = math.sqrt(dx * dx + dz * dz)
        if d > 1 then
          local step = math.min(d, speed * dt)
          u.x, u.z = u.x + dx / d * step, u.z + dz / d * step
        elseif g.category == Group.Category.AIRPLANE then
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

-- ---------------------------------------------------------------------------
-- trigger, missionCommands
-- ---------------------------------------------------------------------------
local function addMark(kind) return function(coal, id, ...) MOCK.marks[id] = { kind = kind, coal = coal, args = { ... } } end end

trigger = {
  action = {
    outText = function(t) MOCK.texts[#MOCK.texts + 1] = t end,
    outTextForCoalition = function(_, t) MOCK.texts[#MOCK.texts + 1] = t end,
    outTextForUnit = function(_, t) MOCK.texts[#MOCK.texts + 1] = t end,
    setUserFlag = function(f, v) MOCK.flags[f] = v end,
    removeMark = function(id) MOCK.marks[id] = nil end,
    lineToAll = addMark("line"),
    circleToAll = addMark("circle"),
    textToAll = addMark("text"),
    arrowToAll = addMark("arrow"),
  },
}

missionCommands = {
  addSubMenuForCoalition = function(c, name) return { c, name } end,
  addCommandForCoalition = function(c, name, parent, fn, arg)
    MOCK.menus[#MOCK.menus + 1] = { coal = c, name = name, fn = fn, arg = arg }
  end,
}

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

function MOCK.countGroups()
  local n = 0
  for _ in pairs(MOCK.groups) do n = n + 1 end
  return n
end

-- A player spawning in a slot: fires the birth event at every handler.
function MOCK.playerBirth(coal, x, z)
  local u = setmetatable({ name = "slot", x = x, z = z, alive = true, coal = coal, player = "Morten" }, UnitMT)
  for _, h in ipairs(MOCK.handlers) do h:onEvent({ id = world.event.S_EVENT_BIRTH, initiator = u }) end
  return u
end

function MOCK.groupsOfCategory(cat)
  local n = 0
  for _, g in pairs(MOCK.groups) do if g.category == cat then n = n + 1 end end
  return n
end
