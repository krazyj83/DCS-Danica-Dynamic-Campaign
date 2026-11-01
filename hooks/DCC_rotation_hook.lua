-- ============================================================================
-- Danica Dynamic Campaign - map rotation server hook (phase 5)
-- ----------------------------------------------------------------------------
-- INSTALL: copy this file to   Saved Games\DCS[.server]\Scripts\Hooks\
--          copy the missions to Saved Games\DCS[.server]\Missions\DCC\
--              DCC_Caucasus.miz, DCC_Syria.miz, DCC_PersianGulf.miz, DCC_GermanyCW.miz
--          put DCC_Caucasus.miz (or any of them) in the server's mission list.
--
-- Why a hook: a mission script cannot load another mission. Server hooks run
-- in the DCS "GameGUI" environment, which can (net.load_mission). The two talk
-- through one file, Saved Games\DCS\DCC\rotation.json:
--
--   mission: war won   -> { state = "ended", finished = "Caucasus", next = "Syria", current = "Syria" }
--   hook   : sees it   -> announces, waits delaySeconds, loads DCC_Syria.miz, state = "loading"
--   mission: starts    -> { state = "running", current = "Syria" }
--
-- After a server restart that loads the wrong DCC mission (e.g. the mission
-- list still starts on Caucasus while the war has moved on to Syria), the hook
-- loads the right one. Non-DCC missions are never touched.
--
-- The server must keep running with nobody online (Server settings: untick
-- "Pause without clients") - the war needs that anyway.
--
-- ADMIN COMMANDS (v0.47): a player in a Game Master slot (or the server host)
-- types "-dcc help" in chat. The hook runs the command in the mission
-- (DCC.admin) and sends the reply to that player only; the chat line itself is
-- not shown to anyone else. Optional: Saved Games\DCS\DCC\admins.txt with one
-- DCS UCID per line - then only those Game Masters may use the commands.
-- The hook also tells the mission it is installed (the self-check reports it).
-- ============================================================================

local DCCR = {
  version      = "0.47",
  missionsDir  = lfs.writedir() .. "Missions\\DCC\\",
  stateFile    = lfs.writedir() .. "DCC\\rotation.json",
  adminFile    = lfs.writedir() .. "DCC\\admins.txt",   -- optional UCID list
  adminSlot    = "instructor",  -- DCS slot id of a Game Master starts with this
  reloadDelay  = 15,            -- s between "-dcc restart" / "freshwar" and the reload
  reloadAt     = nil,
  announced    = false,
  delaySeconds = 120,   -- time between "war over" and the map change (players read the result)
  fixDelay     = 10,    -- wrong map after a restart: switch after this many seconds
  checkEvery   = 5,     -- seconds between checks
  nextCheck    = 0,
  switchAt     = nil,
  target       = nil,
}

local function say(msg)
  if log and log.write then pcall(log.write, "DCC-ROTATION", log.INFO, msg)
  elseif net and net.log then pcall(net.log, "DCC-ROTATION: " .. msg) end
end

local function readState()
  local f = io.open(DCCR.stateFile, "r")
  if not f then return nil end
  local text = f:read("*a")
  f:close()
  if not text or text == "" then return nil end
  local ok, v = pcall(net.json2lua, text)
  if ok and type(v) == "table" then return v end
  return nil
end

local function writeState(t)
  local ok, text = pcall(net.lua2json, t)
  if not ok then return end
  local f = io.open(DCCR.stateFile, "w")
  if f then f:write(text); f:close() end
end

local function fileExists(path)
  local f = io.open(path, "r")
  if f then f:close(); return true end
  return false
end

local function currentTheatre()
  local ok, m = pcall(DCS.getCurrentMission)
  return ok and m and m.mission and m.mission.theatre or nil
end

local function isDccMission()
  local ok, name = pcall(DCS.getMissionFilename)
  return ok and type(name) == "string" and name:find("DCC_", 1, true) ~= nil
end

local function missionFor(map) return DCCR.missionsDir .. "DCC_" .. map .. ".miz" end

local function load(map, why)
  local path = missionFor(map)
  if not fileExists(path) then
    say("cannot rotate to " .. map .. ": " .. path .. " not found - fix it and set state to \"ended\" again")
    local st = readState() or {}
    st.state = "error"
    writeState(st)
    pcall(net.send_chat, "[DCC] Map rotation failed: " .. path .. " not found.", true)
    return false
  end
  say("loading " .. path .. " (" .. why .. ")")
  local st = readState() or {}
  st.state, st.current = "loading", map
  writeState(st)
  return net.load_mission(path)
end

-- ---------------------------------------------------------------------------
-- Admin commands
-- ---------------------------------------------------------------------------
local function adminList()
  local f = io.open(DCCR.adminFile, "r")
  if not f then return nil end
  local list = {}
  for line in f:lines() do
    local u = line:match("^%s*(%x+)%s*$")
    if u then list[u:lower()] = true end
  end
  f:close()
  return list
end

local function isAdmin(id)
  if id == 1 then return true end                         -- the server host
  local okS, slot = pcall(net.get_player_info, id, "slot")
  if not okS or type(slot) ~= "string" or slot:sub(1, #DCCR.adminSlot) ~= DCCR.adminSlot then return false end
  local list = adminList()
  if not list then return true end
  local okU, ucid = pcall(net.get_player_info, id, "ucid")
  return okU and type(ucid) == "string" and list[ucid:lower()] == true
end

local function tell(id, text)
  for line in tostring(text):gmatch("[^\n]+") do pcall(net.send_chat_to, line, id) end
end

-- runs "-dcc <rest>" in the mission and returns the reply
function DCCR.runAdmin(rest, who)
  local code = string.format("return (DCC and DCC.admin) and DCC.admin(%q, %q) or 'DCC is not running on this mission.'",
    rest, who or "?")
  local okR, res = pcall(net.dostring_in, "server", code)
  if not okR then return "Error: " .. tostring(res) end
  return tostring(res or "")
end

local cb = {}

function cb.onPlayerTrySendChat(id, msg, all)
  local rest = type(msg) == "string" and msg:match("^%s*%-dcc%s*(.*)$")
  if not rest then return msg end
  if not isDccMission() then return msg end
  if not isAdmin(id) then
    tell(id, "[DCC] Admin commands need a Game Master slot.")
    return ""
  end
  local okN, name = pcall(net.get_player_info, id, "name")
  local reply = DCCR.runAdmin(rest, okN and name or tostring(id))
  if reply:find("\nRELOAD$") then
    reply = reply:gsub("\nRELOAD$", "")
    DCCR.reloadAt = DCS.getRealTime() + DCCR.reloadDelay
    pcall(net.send_chat, "[DCC] The mission reloads in " .. DCCR.reloadDelay .. " seconds (admin).", true)
    say("admin reload requested by " .. tostring(okN and name or id))
  end
  tell(id, "[DCC] " .. reply)
  return ""
end

-- A mission finished loading: is it the map the campaign is on?
function cb.onMissionLoadEnd()
  DCCR.switchAt, DCCR.target, DCCR.reloadAt, DCCR.announced = nil, nil, nil, false
  if not isDccMission() then return end
  local st, here = readState(), currentTheatre()
  if st and st.current and here and st.current ~= here then
    DCCR.target, DCCR.why = st.current, "wrong map after a restart"
    DCCR.switchAt = DCS.getRealTime() + DCCR.fixDelay
    say(string.format("server is on %s but the campaign is on %s", here, st.current))
  end
end

function cb.onSimulationFrame()
  local now = DCS.getRealTime()
  if now < DCCR.nextCheck then return end
  DCCR.nextCheck = now + DCCR.checkEvery
  if not isDccMission() then return end

  -- tell the mission the hook is here (its self-check reports it)
  if not DCCR.announced then
    local okA = pcall(net.dostring_in, "server", "DCC_HOOK_VERSION = " .. string.format("%q", DCCR.version))
    DCCR.announced = okA
  end

  -- an admin's restart / fresh war
  if DCCR.reloadAt and now >= DCCR.reloadAt then
    DCCR.reloadAt = nil
    local okF, file = pcall(DCS.getMissionFilename)
    if okF and file then say("admin reload of " .. file); net.load_mission(file) end
    return
  end

  if not DCCR.switchAt then
    local st = readState()
    if st and st.state == "ended" and st.next and st.finished == currentTheatre() then
      DCCR.target, DCCR.why = st.next, "war on " .. st.finished .. " won by " .. tostring(st.winner)
      DCCR.switchAt = now + DCCR.delaySeconds
      pcall(net.send_chat, string.format("[DCC] The war on %s is over. The campaign moves to %s in %d seconds.",
        st.finished, st.next, DCCR.delaySeconds), true)
      say("war over, rotating to " .. st.next)
    end
  elseif now >= DCCR.switchAt then
    local target, why = DCCR.target, DCCR.why
    DCCR.switchAt, DCCR.target = nil, nil
    load(target, why)
  end
end

DCS.setUserCallbacks(cb)
say("rotation hook loaded")

DCC_ROTATION_HOOK = { state = DCCR, callbacks = cb }   -- for the offline test
