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
--
-- DAILY RESTART (v0.48): at DCCR.restart.time (Danish time, 04:00) the hook
-- saves the war and reloads the mission - a 24/7 DCS server builds up memory
-- over the days. Players are warned 30, 10 and 1 minute before (chat and on
-- screen). The war carries on from the save. restart.enabled = false: off.
--
-- SRS VOICE (v0.50): the mission queues what should be spoken (AWACS bogey
-- dope, command news, airfield information); the hook collects it and plays
-- it with SRS's DCS-SR-ExternalAudio.exe. Set srs.dir below to the SRS install
-- folder on the server. Hooks may start programs, so MissionScripting.lua
-- stays sanitized. No SRS found: nothing is played, nothing breaks.
-- ============================================================================

local DCCR = {
  version      = "0.50",
  missionsDir  = lfs.writedir() .. "Missions\\DCC\\",
  stateFile    = lfs.writedir() .. "DCC\\rotation.json",
  adminFile    = lfs.writedir() .. "DCC\\admins.txt",   -- optional UCID list
  adminSlot    = "instructor",  -- DCS slot id of a Game Master starts with this
  reloadDelay  = 15,            -- s between "-dcc restart" / "freshwar" and the reload
  reloadAt     = nil,
  announced    = false,
  restart      = {
    enabled  = true,
    time     = "04:00",              -- HH:MM
    zone     = "Europe/Copenhagen",  -- Danish time (summer time handled); "local" = the server's clock
    warn     = { 30, 10, 1 },        -- minutes before: warnings
    minUp    = 600,                  -- s a mission must have run before a daily restart (no restart loops)
  },
  srs          = {
    enabled  = true,
    dir      = "C:\\Program Files\\DCS-SimpleRadio-Standalone",   -- SRS install folder on the server
    exe      = "DCS-SR-ExternalAudio.exe",
    port     = 5002,                 -- the SRS server's port
    gap      = 1.5,                  -- s of silence between two lines on one frequency
    charsPerSec = 14,                -- speaking speed, to know when a line is done
  },
  srsBusy      = {},                 -- frequency -> real time it is free again
  srsQueue     = {},
  restartDone  = nil,                -- "YYYY-MM-DD" of the last daily restart
  warned       = {},
  loadedAt     = 0,
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

-- ---------------------------------------------------------------------------
-- Daily restart (v0.48)
-- ---------------------------------------------------------------------------
-- Danish time (CET, CEST from the last Sunday of March 01:00 UTC to the last
-- Sunday of October 01:00 UTC), worked out from UTC so the server's own time
-- zone does not matter. zone = "local" uses the server's clock instead.
local function lastSunday(year, month)
  local days = os.date("!*t", os.time({ year = year, month = month + 1, day = 0, hour = 12 })).day
  for d = days, days - 6, -1 do
    if os.date("!*t", os.time({ year = year, month = month, day = d, hour = 12 })).wday == 1 then return d end
  end
end

function DCCR.clock(utc)
  utc = utc or os.time()
  if DCCR.restart.zone == "local" then return os.date("*t", utc) end
  local u = os.date("!*t", utc)
  local offset = 1
  local startD, endD = lastSunday(u.year, 3), lastSunday(u.year, 10)
  local function after(month, day) return u.month > month or (u.month == month and (u.day > day or (u.day == day and u.hour >= 1))) end
  if after(3, startD) and not after(10, endD) then offset = 2 end
  return os.date("!*t", utc + offset * 3600)
end

local function toScreen(text, seconds)
  pcall(net.dostring_in, "server", string.format("trigger.action.outText(%q, %d)", text, seconds))
end

-- minutes until the next restart time (0..1439), and today's date key
function DCCR.restartIn(utc)
  local t = DCCR.clock(utc)
  local h, m = DCCR.restart.time:match("^(%d+):(%d+)$")
  local target = tonumber(h) * 60 + tonumber(m)
  return (target - (t.hour * 60 + t.min)) % 1440, string.format("%04d-%02d-%02d", t.year, t.month, t.day)
end

function DCCR.dailyRestart(now)
  local R = DCCR.restart
  if not R.enabled then return false end
  local left, day = DCCR.restartIn()
  for _, w in ipairs(R.warn) do
    if left == w and not DCCR.warned[day .. "/" .. w] then
      DCCR.warned[day .. "/" .. w] = true
      local text = string.format("[DCC] Daily server restart in %d minute%s (%s). The war is saved and carries on.",
        w, w == 1 and "" or "s", R.time)
      pcall(net.send_chat, text, true)
      toScreen(text, 30)
    end
  end
  if left == 0 and DCCR.restartDone ~= day and now - DCCR.loadedAt >= R.minUp then
    DCCR.restartDone = day
    pcall(net.dostring_in, "server", "if DCC and DCC.save then DCC.save() end")
    local okF, file = pcall(DCS.getMissionFilename)
    if okF and file then
      say("daily restart: reloading " .. file)
      pcall(net.send_chat, "[DCC] Daily restart now.", true)
      net.load_mission(file)
      return true
    end
  end
  return false
end

-- ---------------------------------------------------------------------------
-- SRS voice (v0.50)
-- ---------------------------------------------------------------------------
local function srsExe()
  local S = DCCR.srs
  if S.found == nil then
    S.found = fileExists(S.dir .. "\\" .. S.exe)
    say(S.found and ("SRS text-to-speech found in " .. S.dir) or ("SRS text-to-speech not found: " .. S.dir .. "\\" .. S.exe
      .. " - no voice (set srs.dir in this hook)"))
  end
  return S.found
end

local function clean(text)   -- no shell specials in a command line
  return (tostring(text):gsub('[%"%%%^&|<>]', ""):gsub("[\r\n]+", " "))
end

function DCCR.srsCommand(m)
  local S = DCCR.srs
  return string.format('start "" /min /d "%s" /b "%s" -f %.3f -m %s -c %d -p %d -n "%s" -g %s -l %s -t "%s"',
    S.dir, S.exe, m.freq, m.mod or "AM", m.coal or 2, S.port, clean(m.name or "DCC"), m.gender or "male",
    m.culture or "en-GB", clean(m.text))
end

-- runs a command line; long ones go through a .bat (Windows limits a command line)
function DCCR.run(cmd)
  if #cmd > 250 then
    local tmp = (os.getenv("TEMP") or lfs.writedir()) .. "\\dcc_srs_" .. math.floor(DCS.getRealTime() * 1000) .. ".bat"
    local f = io.open(tmp, "w")
    if not f then return false end
    f:write("@echo off\r\n" .. cmd .. "\r\ndel \"%~f0\"\r\n")
    f:close()
    cmd = '"' .. tmp .. '"'
  end
  return os.execute(cmd)
end

function DCCR.srsTick(now)
  local S = DCCR.srs
  if not S.enabled then return end
  local okP, res = pcall(net.dostring_in, "server", "return (DCC and DCC.srsPop) and DCC.srsPop() or ''")
  if okP and type(res) == "string" and res ~= "" then
    local okJ, list = pcall(net.json2lua, res)
    if okJ and type(list) == "table" then
      for _, m in ipairs(list) do DCCR.srsQueue[#DCCR.srsQueue + 1] = m end
    end
  end
  if #DCCR.srsQueue == 0 or not srsExe() then
    if not S.found then DCCR.srsQueue = {} end
    return
  end
  local keep = {}
  for _, m in ipairs(DCCR.srsQueue) do
    local key = string.format("%.3f/%s", m.freq or 0, tostring(m.coal))
    if (DCCR.srsBusy[key] or 0) <= now then
      DCCR.run(DCCR.srsCommand(m))
      DCCR.srsBusy[key] = now + #tostring(m.text) / S.charsPerSec + S.gap
    else
      keep[#keep + 1] = m
    end
  end
  DCCR.srsQueue = keep
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
  DCCR.loadedAt = DCS.getRealTime()
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

  -- SRS voice
  local okS, errS = pcall(DCCR.srsTick, now)
  if not okS then say("srs: " .. tostring(errS)) end

  -- the daily restart (not while the map is about to change)
  if not DCCR.switchAt and DCCR.dailyRestart(now) then return end

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
