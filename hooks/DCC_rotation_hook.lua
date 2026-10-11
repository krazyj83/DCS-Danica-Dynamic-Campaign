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
-- ============================================================================

local DCCR = {
  missionsDir  = lfs.writedir() .. "Missions\\DCC\\",
  stateFile    = lfs.writedir() .. "DCC\\rotation.json",
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

local cb = {}

-- A mission finished loading: is it the map the campaign is on?
function cb.onMissionLoadEnd()
  DCCR.switchAt, DCCR.target = nil, nil
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
