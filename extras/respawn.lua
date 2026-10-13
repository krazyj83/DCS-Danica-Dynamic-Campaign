-- ============================================================================
-- respawn.lua - respawn any destroyed unit 5 minutes after it dies.
-- ----------------------------------------------------------------------------
-- Standalone DCS mission script (no MOOSE / MIST needed).
--
-- INSTALL: Mission Editor > Triggers > MISSION START > action DO SCRIPT FILE
--          > respawn.lua. Save the mission. That's all.
--
-- HOW IT WORKS
--   * At mission start the script reads every group placed in the Mission
--     Editor (env.mission): vehicles, ships, AI aircraft and helicopters, and
--     static objects. Those are the "templates".
--   * When a unit dies, it waits RESPAWN.delay seconds (300 = 5 min), then
--     puts the unit back exactly as it was placed in the editor: same type,
--     position, heading, skill, route and tasks.
--   * A respawned unit is respawned again when it dies (no limit unless you
--     set RESPAWN.maxPerUnit).
--   * Player and client aircraft are never touched (DCS respawns players).
--
-- MODES (RESPAWN.mode)
--   "unit"  - each dead unit comes back on its own, 5 min after it died
--             (it rejoins as a one-unit group following the original route).
--   "group" - the group comes back complete, 5 min after its LAST unit died.
--             Better for SAM sites and formations that only work together.
--
-- It skips groups whose names start with anything in RESPAWN.skipPrefixes
-- ("DCC_" = units of the Danica Dynamic Campaign, which manages its own).
-- ============================================================================

RESPAWN = {
  delay        = 300,          -- seconds between death and respawn
  mode         = "unit",       -- "unit" or "group"
  categories   = { vehicle = true, ship = true, plane = true, helicopter = true, static = true },
  skipPrefixes = { "DCC_" },   -- group names starting with these are left alone
  onlyPrefixes = nil,          -- e.g. { "RSP_" } to respawn ONLY groups named like that
  maxPerUnit   = 0,            -- 0 = unlimited respawns, otherwise the most per unit
  announce     = false,        -- true: message to all when something respawns
  debug        = false,
}

-- ---------------------------------------------------------------------------
local R = RESPAWN
R.templates = {}   -- unit name   -> { group = groupTemplate, unit = unitTemplate, countryId, cat }
R.groups    = {}   -- group name  -> { group = groupTemplate, countryId, cat, units = {names} }
R.alias     = {}   -- name of a respawned unit -> original unit name
R.count     = {}   -- original unit name -> respawns so far
R.pending   = {}   -- original unit/group name -> true while a respawn is scheduled
R.serial    = 0

local function log(fmt, ...)
  env.info("RESPAWN: " .. string.format(fmt, ...))
end

local function deepCopy(t)
  if type(t) ~= "table" then return t end
  local c = {}
  for k, v in pairs(t) do c[k] = deepCopy(v) end
  return c
end

local function startsWithAny(name, list)
  for _, p in ipairs(list or {}) do
    if name:sub(1, #p) == p then return true end
  end
  return false
end

local function wanted(groupName)
  if startsWithAny(groupName, R.skipPrefixes) then return false end
  if R.onlyPrefixes and not startsWithAny(groupName, R.onlyPrefixes) then return false end
  return true
end

local GROUP_CAT = {
  vehicle = Group.Category.GROUND, ship = Group.Category.SHIP,
  plane = Group.Category.AIRPLANE, helicopter = Group.Category.HELICOPTER,
}

-- ---------------------------------------------------------------------------
-- 1. Read the Mission Editor groups
-- ---------------------------------------------------------------------------
function R.readTemplates()
  local n = 0
  for _, coal in pairs(env.mission.coalition or {}) do
    for _, ctry in ipairs(coal.country or {}) do
      for cat in pairs(R.categories) do
        if R.categories[cat] and ctry[cat] and ctry[cat].group then
          for _, g in ipairs(ctry[cat].group) do
            local isPlayer = false
            for _, u in ipairs(g.units or {}) do
              if u.skill == "Client" or u.skill == "Player" then isPlayer = true end
            end
            if not isPlayer and g.name and wanted(g.name) then
              local rec = { group = g, countryId = ctry.id, cat = cat, units = {} }
              R.groups[g.name] = rec
              for _, u in ipairs(g.units or {}) do
                R.templates[u.name] = { group = g, unit = u, countryId = ctry.id, cat = cat }
                rec.units[#rec.units + 1] = u.name
                n = n + 1
              end
            end
          end
        end
      end
    end
  end
  log("watching %d units (mode %s, delay %d s)", n, R.mode, R.delay)
end

-- ---------------------------------------------------------------------------
-- 2. Respawning
-- ---------------------------------------------------------------------------
local function cleanGroup(g, name)
  local data = deepCopy(g)
  data.name = name
  data.groupId = nil
  data.lateActivation = nil      -- a respawn appears at once
  data.start_time = 0
  return data
end

local function spawnStatic(tpl, name)
  local u = deepCopy(tpl.unit)
  u.name = name
  u.unitId = nil
  u.dead = false
  return pcall(coalition.addStaticObject, tpl.countryId, u)
end

-- one unit back, as a one-unit group following the original route
function R.respawnUnit(origName)
  R.pending[origName] = nil
  local tpl = R.templates[origName]
  if not tpl then return end
  R.count[origName] = (R.count[origName] or 0) + 1
  local ok, err
  local newName
  if tpl.cat == "static" then
    newName = origName                       -- statics: same name replaces the wreck
    ok, err = spawnStatic(tpl, newName)
  else
    R.serial = R.serial + 1
    newName = string.format("%s #R%d", origName, R.serial)
    local data = cleanGroup(tpl.group, string.format("%s #R%d", tpl.group.name, R.serial))
    local u = deepCopy(tpl.unit)
    u.name, u.unitId = newName, nil
    data.units = { u }
    ok, err = pcall(coalition.addGroup, tpl.countryId, GROUP_CAT[tpl.cat], data)
  end
  if ok then
    R.alias[newName] = origName
    if R.debug then log("respawned %s as %s", origName, newName) end
    if R.announce then trigger.action.outText(origName .. " is back.", 10) end
  else
    log("respawn of %s failed: %s", origName, tostring(err))
  end
end

-- the whole group back (same name: DCS replaces any leftovers)
function R.respawnGroup(groupName)
  R.pending[groupName] = nil
  local rec = R.groups[groupName]
  if not rec then return end
  R.count[groupName] = (R.count[groupName] or 0) + 1
  local ok, err
  if rec.cat == "static" then
    ok, err = spawnStatic(R.templates[rec.units[1]], rec.units[1])
  else
    local old = Group.getByName(groupName)          -- clear the wrecks' group first
    if old and old:isExist() then pcall(old.destroy, old) end
    ok, err = pcall(coalition.addGroup, rec.countryId, GROUP_CAT[rec.cat], cleanGroup(rec.group, groupName))
  end
  if ok then
    for _, un in ipairs(rec.units) do R.alias[un] = un end
    if R.debug then log("respawned group %s", groupName) end
    if R.announce then trigger.action.outText(groupName .. " is back.", 10) end
  else
    log("respawn of group %s failed: %s", groupName, tostring(err))
  end
end

local function groupDead(groupName)
  local g = Group.getByName(groupName)
  if not g or not g:isExist() then return true end
  for _, u in ipairs(g:getUnits() or {}) do
    if u:isExist() and u:getLife() >= 1 then return false end
  end
  return true
end

-- ---------------------------------------------------------------------------
-- 3. Deaths
-- ---------------------------------------------------------------------------
function R.onDeath(obj)
  local okName, name = pcall(obj.getName, obj)
  if not okName or not name then return end
  local orig = R.alias[name] or (R.templates[name] and name)
  if not orig then return end
  local tpl = R.templates[orig]

  if R.mode == "group" and tpl.cat ~= "static" then
    local gname = tpl.group.name
    if R.pending[gname] then return end
    if R.maxPerUnit > 0 and (R.count[gname] or 0) >= R.maxPerUnit then return end
    -- wait a moment (the dying unit is still counted), then check the whole group
    timer.scheduleFunction(function()
      if not R.pending[gname] and groupDead(gname) then
        R.pending[gname] = true
        timer.scheduleFunction(function() R.respawnGroup(gname) end, nil, timer.getTime() + R.delay)
        if R.debug then log("group %s dead, back in %d s", gname, R.delay) end
      end
    end, nil, timer.getTime() + 2)
    return
  end

  if R.pending[orig] then return end
  if R.maxPerUnit > 0 and (R.count[orig] or 0) >= R.maxPerUnit then return end
  R.pending[orig] = true
  timer.scheduleFunction(function() R.respawnUnit(orig) end, nil, timer.getTime() + R.delay)
  if R.debug then log("%s died, back in %d s", orig, R.delay) end
end

local DEATH = {}
for _, k in ipairs({ "S_EVENT_DEAD", "S_EVENT_CRASH", "S_EVENT_UNIT_LOST", "S_EVENT_PILOT_DEAD" }) do
  if world.event[k] then DEATH[world.event[k]] = true end
end

world.addEventHandler({ onEvent = function(_, e)
  if DEATH[e.id] and e.initiator then
    local ok, err = pcall(R.onDeath, e.initiator)
    if not ok then log("error: %s", tostring(err)) end
  end
end })

R.readTemplates()
