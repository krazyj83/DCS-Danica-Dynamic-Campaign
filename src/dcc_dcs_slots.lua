-- ============================================================================
-- Danica Dynamic Campaign - DCS bridge: player slots (v0.58).
-- Load after dcc_dcs_stats.lua, before dcc_main.lua.
-- ----------------------------------------------------------------------------
-- A player gets his campaign menus (missions, supply crate, support) when the
-- campaign registers him at S_EVENT_BIRTH. That missed some players:
--
--   * Dynamic spawns: the birth can come before the player is in the
--     aircraft (no player name yet) - he flew without a Missions menu.
--     Now S_EVENT_PLAYER_ENTER_UNIT registers him too (slot guards first).
--   * Multicrew (C-130J, CH-47F, AH-64D): a crew member changing seats sends
--     S_EVENT_PLAYER_LEAVE_UNIT for the whole aircraft, and the pilot lost his
--     menus and his mission. With the server's player list at hand, a leave
--     while someone still sits in the aircraft is now only a crew change.
--   * Anything else: every slots.sweepSec the players DCS reports are
--     compared with the campaign's - missing ones are registered, departed
--     ones forgotten (like CTLD's own sweep).
--
-- An ejection on the ground at an own base is how many players leave a slot:
-- it no longer puts a downed pilot and a CSAR mission on the board.
-- Every player entering and leaving is written to dcs.log (slots.logPlayers).
-- ============================================================================

DCC = DCC or {}
local B = DCC.dcs
local U = DCC.util

local function SC() return DCC.config.slots end
local function ok(fn, ...) local s, r = pcall(fn, ...); if s then return r end end
local function alive(u) return u ~= nil and ok(u.isExist, u) == true end

local function isAircraft(u)
  local d = ok(u.getDesc, u)
  return d ~= nil and (d.category == Unit.Category.AIRPLANE or d.category == Unit.Category.HELICOPTER)
end

local function recentlyRemoved(uname)
  local t = B.removed and B.removed[uname]
  return t ~= nil and timer.getTime() - t < 60
end

-- How many players the server has in this aircraft (pilot slot "<unit id>", crew seats "<unit id>_<n>").
-- nil when the server's player list cannot be read.
function B.seatsTaken(u)
  if not (net and net.get_player_list and net.get_player_info) then return nil end
  local id = ok(u.getID, u)
  if not id then return nil end
  id = tostring(id)
  local n = 0
  for _, pid in ipairs(ok(net.get_player_list) or {}) do
    local info = ok(net.get_player_info, pid)
    local slot = info and tostring(info.slot or "") or ""
    if slot == id or slot:sub(1, #id + 1) == id .. "_" then n = n + 1 end
  end
  return n
end

-- A player in an aircraft the campaign does not know yet: slot guards as at birth, then menus.
function B.adoptPlayer(u, why)
  if not alive(u) or not ok(u.getPlayerName, u) or not isAircraft(u) then return nil end
  local uname = ok(u.getName, u)
  if not uname or recentlyRemoved(uname) then return nil end
  if B.players[uname] then return B.players[uname] end
  pcall(B.onBirth, u)
  if not alive(u) or recentlyRemoved(uname) then return nil end
  local s, p = pcall(B.registerPlayer, u)
  if not s then U.log("ERROR adopting %s: %s", uname, tostring(p)); return nil end
  if p and SC().logPlayers then U.log("player %s picked up in %s (%s)", tostring(p.name), uname, why or "?") end
  return p
end

-- Compare DCS's players with the campaign's.
function B.slotSweep()
  local seen = {}
  for _, c in ipairs({ coalition.side.RED, coalition.side.BLUE }) do
    for _, u in ipairs(ok(coalition.getPlayers, c) or {}) do
      local uname = ok(u.getName, u)
      if uname then
        seen[uname] = true
        if not B.players[uname] then B.adoptPlayer(u, "sweep") end
      end
    end
  end
  for uname, p in pairs(B.players) do
    if not p.ground and not seen[uname] then
      local u = ok(Unit.getByName, uname)
      if not alive(u) or not ok(u.getPlayerName, u) then
        if SC().logPlayers then U.log("player %s gone from %s (sweep)", tostring(p.name), uname) end
        B.clearPlayer(uname, "left")
      end
    end
  end
end

-- ---------------------------------------------------------------------------
-- Events
-- ---------------------------------------------------------------------------
local baseOpsEvent = B.onOpsEvent
function B.onOpsEvent(e)
  local ev, u = world.event, e.initiator
  if e.id == ev.S_EVENT_PLAYER_LEAVE_UNIT and u then
    local uname = ok(u.getName, u)
    local p = uname and B.players[uname]
    if p and not p.ground and B.seatsTaken(u) ~= nil then
      -- decide a moment later, when the server's slots have settled: still someone aboard = a crew change
      timer.scheduleFunction(function()
        if B.players[uname] ~= p then return end
        local uu = ok(Unit.getByName, uname)
        local n = alive(uu) and B.seatsTaken(uu) or 0
        if n and n > 0 and ok(uu.getPlayerName, uu) then
          if SC().logPlayers then U.log("crew change in %s: %s keeps it (%d aboard)", uname, tostring(p.name), n) end
          return
        end
        if SC().logPlayers then U.log("player %s left %s", tostring(p.name), uname) end
        B.clearPlayer(uname, "left")
      end, nil, timer.getTime() + 1)
      return
    end
    if p and SC().logPlayers then U.log("player %s left %s", tostring(p.name), uname) end
  end
  baseOpsEvent(e)
  if e.id == ev.S_EVENT_PLAYER_ENTER_UNIT and u then
    local s, err = pcall(B.adoptPlayer, u, "enter")
    if not s then U.log("ERROR player enter: %s", tostring(err)) end
  end
end

local baseRegister = B.registerPlayer
function B.registerPlayer(u)
  local p = baseRegister(u)
  if p and SC().logPlayers then
    U.log("player %s in %s (%s, group %s) at %s", tostring(p.name), tostring(p.unit), tostring(p.type),
      tostring(p.gid), tostring(p.home or "-"))
  end
  return p
end

-- An ejection on the ground at an own base: the player leaving his slot.
local baseEject = B.onEjection
function B.onEjection(u)
  if u and ok(u.getPlayerName, u) and not ok(u.inAir, u) then
    local pos = ok(u.getPoint, u)
    local side = (ok(u.getCoalition, u) == B.COAL.blue) and "blue" or "red"
    local id = pos and B.nearestNodeOf and B.nearestNodeOf(pos, side, SC().groundEjectKm * 1000)
    if id then
      if SC().logPlayers then U.log("player %s ejected on the ground at %s: no CSAR", tostring(ok(u.getPlayerName, u)), id) end
      return
    end
  end
  return baseEject(u)
end

-- The supply crate menu belongs to the aircraft: whoever in it clicks, a lost record is picked up again.
if B.ctldSupplyCrate then
  local baseCrate = B.ctldSupplyCrate
  function B.ctldSupplyCrate(uname)
    if not B.players[uname] then
      local u = ok(Unit.getByName, uname)
      if u then B.adoptPlayer(u, "crate menu") end
    end
    return baseCrate(uname)
  end
end

local basePoll = B.opsPoll
function B.opsPoll()
  basePoll()
  local now = timer.getTime()
  if now - (B.slotSweepAt or -1e9) >= SC().sweepSec then
    B.slotSweepAt = now
    local s, err = pcall(B.slotSweep)
    if not s then U.log("ERROR slot sweep: %s", tostring(err)) end
  end
end

local baseInit = B.init
function B.init(war, theater, catalog)
  baseInit(war, theater, catalog)
  B.removed, B.slotSweepAt = {}, nil
end
