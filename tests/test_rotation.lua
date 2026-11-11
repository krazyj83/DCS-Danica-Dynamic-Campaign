-- ============================================================================
-- Phase 5: a war won on one map loads the next map unattended.
-- Runs the mission side (against tests/dcs_mock.lua) and the server hook
-- (hooks/DCC_rotation_hook.lua, against a fake GameGUI API) together.
--   python tools/run_lua.py tests/test_rotation.lua
-- ============================================================================

local passed, failed = 0, 0
local function check(name, cond, detail)
  if cond then passed = passed + 1; print("  ok   " .. name)
  else failed = failed + 1; print("  FAIL " .. name .. (detail and (" - " .. tostring(detail)) or "")) end
end

dofile(DCC_ROOT .. "/tests/dcs_mock.lua")
MOCK.writedir = (arg[1] or "/tmp") .. "/dcc_rot_" .. tostring(os.time()) .. "/"
os.execute('mkdir -p "' .. MOCK.writedir .. '"')
MOCK.buildAirbases(DCC_THEATERS.Caucasus)
MOCK.addTemplates()

dofile(DCC_ROOT .. "/src/dcc_persist.lua")
dofile(DCC_ROOT .. "/src/dcc_dcs.lua")
dofile(DCC_ROOT .. "/src/dcc_dcs_supply.lua")
dofile(DCC_ROOT .. "/src/dcc_dcs_ops.lua")
dofile(DCC_ROOT .. "/src/dcc_dcs_intel.lua")
dofile(DCC_ROOT .. "/src/dcc_dcs_radar.lua")
dofile(DCC_ROOT .. "/src/dcc_dcs_world.lua")
dofile(DCC_ROOT .. "/src/dcc_dcs_jtac.lua")
dofile(DCC_ROOT .. "/src/dcc_dcs_public.lua")
dofile(DCC_ROOT .. "/src/dcc_dcs_air.lua")
dofile(DCC_ROOT .. "/src/dcc_dcs_ground.lua")
dofile(DCC_ROOT .. "/src/dcc_dcs_ctld.lua")
dofile(DCC_ROOT .. "/src/dcc_dcs_ext_air.lua")
dofile(DCC_ROOT .. "/src/dcc_dcs_ext_ground.lua")
dofile(DCC_ROOT .. "/src/dcc_dcs_ext2.lua")
dofile(DCC_ROOT .. "/src/dcc_dcs_ext3.lua")
dofile(DCC_ROOT .. "/src/dcc_dcs_ext4.lua")
dofile(DCC_ROOT .. "/src/dcc_dcs_ext5.lua")
dofile(DCC_ROOT .. "/src/dcc_dcs_armoury.lua")
dofile(DCC_ROOT .. "/src/dcc_dcs_admin.lua")
dofile(DCC_ROOT .. "/src/dcc_dcs_srs.lua")
dofile(DCC_ROOT .. "/src/dcc_dcs_stats.lua")
dofile(DCC_ROOT .. "/src/dcc_dcs_slots.lua")
dofile(DCC_ROOT .. "/src/dcc_dcs_stock.lua")
dofile(DCC_ROOT .. "/src/dcc_main.lua")

local errors = 0
DCC.util.log = function(fmt, ...)
  local msg = string.format(fmt, ...)
  if msg:find("ERROR") then errors = errors + 1; print("    " .. msg) end
end

-- ---------------------------------------------------------------- fake server
local SRV = { rt = 0, theatre = "Caucasus", file = "C:\\Missions\\DCC\\DCC_Caucasus.miz", loaded = {}, chat = {} }
DCS = {
  setUserCallbacks = function(cb) SRV.cb = cb end,
  getRealTime = function() return SRV.rt end,
  getCurrentMission = function() return { mission = { theatre = SRV.theatre } } end,
  getMissionFilename = function() return SRV.file end,
}
net = {
  json2lua = function(t) return DCC.json.decode(t) end,
  lua2json = function(t) return DCC.json.encode(t) end,
  load_mission = function(p) SRV.loaded[#SRV.loaded + 1] = p; return true end,
  send_chat = function(t) SRV.chat[#SRV.chat + 1] = t end,
  -- v0.47: admin commands
  dostring_in = function(state, code) return assert(loadstring(code))() end,   -- "server" = the mission here
  get_player_info = function(id, key) return (SRV.players[id] or {})[key] end,
  send_chat_to = function(t, id) SRV.told[#SRV.told + 1] = { id = id, text = t } end,
}
SRV.players, SRV.told = {}, {}
local function frames(seconds)
  for _ = 1, seconds do SRV.rt = SRV.rt + 1; SRV.cb.onSimulationFrame() end
end
-- the four missions in Saved Games\DCS\Missions\DCC\
local missionsDir = MOCK.writedir .. "Missions\\DCC\\"
for _, m in ipairs({ "Caucasus", "Syria", "GermanyCW" }) do   -- PersianGulf left out on purpose
  local f = io.open(missionsDir .. "DCC_" .. m .. ".miz", "w"); f:write("miz"); f:close()
end
dofile(DCC_ROOT .. "/hooks/DCC_rotation_hook.lua")
check("hook registered its callbacks", SRV.cb and SRV.cb.onSimulationFrame and SRV.cb.onMissionLoadEnd)
local HK = DCC_ROTATION_HOOK.state
HK.restart.enabled = false          -- the daily restart is tested on its own (it reads the real clock)

-- ------------------------------------------------------------------ the war
print("Caucasus war running")
SRV.cb.onMissionLoadEnd()
DCC.start()
local war = DCC.warObj
local rot = DCC.persist.readRotation()
check("mission records the map it runs", rot and rot.current == "Caucasus" and rot.state == "running")
frames(300)
check("nothing loads while the war runs", #SRV.loaded == 0)

print("BLUE wins")
for _, ns in pairs(war.state.nodes) do ns.side = "blue" end
for mid, mv in pairs(war.state.moves) do if mv.side == "red" then war.state.moves[mid] = nil end end
DCC.onTick()
check("war over", war.state.winner == "blue")
rot = DCC.persist.readRotation()
check("rotation file says: ended, next Syria", rot.state == "ended" and rot.next == "Syria" and rot.finished == "Caucasus")
frames(60)
check("players get the warning first", #SRV.chat == 1 and SRV.chat[1]:find("Syria", 1, true) ~= nil, SRV.chat[1])
check("no map change during the delay", #SRV.loaded == 0)
frames(80)
check("Syria mission loaded unattended", SRV.loaded[1] == missionsDir .. "DCC_Syria.miz", SRV.loaded[1])
check("rotation file says loading Syria", DCC.persist.readRotation().state == "loading")

print("Syria starts")
SRV.theatre, SRV.file = "Syria", "C:\\Missions\\DCC\\DCC_Syria.miz"
SRV.cb.onMissionLoadEnd()
MOCK.airbases = {}
MOCK.buildAirbases(DCC_THEATERS.Syria)
DCC.started, DCC.ended = false, false
env.mission.theatre = "Syria"
DCC.start()
check("a new war starts on Syria", DCC.started and DCC.warObj and DCC.warObj.T.name == "Syria")
rot = DCC.persist.readRotation()
check("rotation file: running on Syria", rot.current == "Syria" and rot.state == "running")
frames(300)
check("hook leaves a running Syria war alone", #SRV.loaded == 1)
local okTick = pcall(DCC.onTick)
check("Syria war ticks", okTick)

print("Server restart on the wrong mission")
SRV.theatre, SRV.file = "Caucasus", "C:\\Missions\\DCC\\DCC_Caucasus.miz"
SRV.cb.onMissionLoadEnd()
DCC.started = false
env.mission.theatre = "Caucasus"
DCC.start()
check("Caucasus mission does not start a war", not DCC.started and DCC.waitingForRotation == "Syria")
frames(15)
check("hook loads Syria again", SRV.loaded[2] == missionsDir .. "DCC_Syria.miz", SRV.loaded[2])

print("Other missions are left alone")
SRV.theatre, SRV.file = "Caucasus", "C:\\Missions\\Training.miz"
SRV.cb.onMissionLoadEnd()
frames(60)
check("non-DCC mission untouched", #SRV.loaded == 2)

print("Missing mission file")
DCC.persist.writeRotation({ current = "PersianGulf", state = "ended", finished = "Syria", next = "PersianGulf", winner = "red" })
SRV.theatre, SRV.file = "Syria", "C:\\Missions\\DCC\\DCC_Syria.miz"
SRV.cb.onMissionLoadEnd()
frames(200)
check("no load without the file", #SRV.loaded == 2)
check("rotation marked as error, server told", DCC.persist.readRotation().state == "error"
  and SRV.chat[#SRV.chat]:find("not found", 1, true) ~= nil)

print("The full rotation")
local m, seen = "Caucasus", {}
for _ = 1, 4 do seen[#seen + 1] = m; m = DCC.nextMap(m) end
check("Caucasus > Syria > Persian Gulf > Germany > Caucasus",
  table.concat(seen, ">") == "Caucasus>Syria>PersianGulf>GermanyCW" and m == "Caucasus")
print("Every map starts and runs in (fake) DCS")
for _, map in ipairs({ "PersianGulf", "GermanyCW" }) do
  DCC.persist.writeRotation({ current = map, state = "loading" })
  MOCK.airbases = {}
  MOCK.buildAirbases(DCC_THEATERS[map])
  DCC.started, DCC.ended = false, false
  env.mission.theatre = map
  DCC.start()
  check(map .. ": war started", DCC.started and DCC.warObj.T.name == map)
  local okT, err = pcall(function() for _ = 1, 12 do DCC.onTick() end end)
  check(map .. ": an hour of war in DCS", okT, err)
end
print("Admin commands from a Game Master (v0.47, replaces the fresh-war switch)")
do
  DCC.persist.writeRotation({ current = "Caucasus", state = "running" })
  MOCK.airbases = {}
  MOCK.buildAirbases(DCC_THEATERS.Caucasus)
  SRV.theatre, SRV.file = "Caucasus", "C:\\Missions\\DCC\\DCC_Caucasus.miz"
  local function restart()
    DCC.started, DCC.ended = false, false
    env.mission.theatre = "Caucasus"
    DCC.start()
    return DCC.warObj
  end
  SRV.cb.onMissionLoadEnd()
  local w = restart()
  frames(6)
  check("the hook tells the mission it is installed", DCC_HOOK_VERSION ~= nil)
  SRV.players[2] = { name = "Pilot", slot = "12", ucid = "aa11" }
  SRV.players[3] = { name = "GM", slot = "instructor_blue_1", ucid = "bb22" }
  local function say(id, msg)
    local n = #SRV.told
    local r = SRV.cb.onPlayerTrySendChat(id, msg, true)
    local out = {}
    for i = n + 1, #SRV.told do out[#out + 1] = SRV.told[i].text end
    return r, table.concat(out, "\n")
  end
  local r1, t1 = say(2, "-dcc status")
  check("a pilot cannot use admin commands", r1 == "" and t1:find("Game Master", 1, true) ~= nil, t1)
  local rn = SRV.cb.onPlayerTrySendChat(2, "hello all", true)
  check("normal chat is untouched", rn == "hello all")
  local r2, t2 = say(3, "-dcc status")
  check("Game Master: status, only to him, chat line hidden", r2 == "" and t2:find("Caucasus", 1, true) ~= nil
    and SRV.told[#SRV.told].id == 3, t2)
  local _, th = say(1, "-dcc help")
  check("the server host may too; help lists the commands", th:find("freshwar", 1, true) ~= nil, th)
  local _, tc = say(3, "-dcc check")
  check("check: the self-check report", tc:find("Self-check", 1, true) ~= nil and tc:find("FARP", 1, true) ~= nil, tc)
  w.state.nodes.senaki.side = "red"
  local _, ts = say(3, "-dcc save")
  check("save", ts:find("saved", 1, true) ~= nil)
  check("restart: the war carries on (Senaki still RED)", restart().state.nodes.senaki.side == "red")
  local nLoad = #SRV.loaded
  local _, tr = say(3, "-dcc restart")
  check("restart: the hook reloads the same mission after the delay", #SRV.loaded == nLoad)
  frames(20)
  check("...reloaded", #SRV.loaded == nLoad + 1 and SRV.loaded[#SRV.loaded] == SRV.file, SRV.loaded[#SRV.loaded])
  SRV.cb.onMissionLoadEnd()
  local w2 = restart()
  local _, tf = say(3, "-dcc freshwar")
  check("freshwar asks for 'yes' first", tf:find("freshwar yes", 1, true) ~= nil and w2.state.winner == nil, tf)
  local t0 = #MOCK.texts
  say(3, "-dcc freshwar yes")
  check("freshwar yes: no more war ticks, no map rotation", DCC.resetPending and (pcall(DCC.onTick))
    and DCC.persist.readRotation().state == "running")
  frames(20)
  SRV.cb.onMissionLoadEnd()
  local w3 = restart()
  check("after the reload: a fresh war (Senaki BLUE again)", w3.state.nodes.senaki.side == "blue" and w3.state.tick <= 1)
  local told = false
  for i = t0 + 1, #MOCK.texts do if MOCK.texts[i]:find("FRESH WAR", 1, true) then told = true end end
  check("...everyone is told", told)
  local f = io.open(MOCK.writedir .. "DCC\\admins.txt", "w")
  if f then f:write("cc33\n"); f:close() end
  local r4, t4 = say(3, "-dcc status")
  check("admins.txt: a Game Master not on the list is refused", r4 == "" and t4:find("Game Master", 1, true) ~= nil, t4)
  SRV.players[3].ucid = "CC33"
  local _, t5 = say(3, "-dcc status")
  check("...one on the list may", t5:find("Caucasus", 1, true) ~= nil, t5)
  os.remove(MOCK.writedir .. "DCC\\admins.txt")
end

print("Daily restart at 04:00 Danish time (v0.48)")
do
  local function utc(y, mo, d, h, mi)                -- seconds since 1970 for a UTC time (any host time zone)
    local e = os.time({ year = y, month = mo, day = d, hour = h, min = mi })
    local g = os.date("!*t", e)
    g.isdst = nil
    return e - (os.time(g) - e)
  end
  local function hm(t) return string.format("%02d:%02d", t.hour, t.min) end
  check("winter: 03:00 UTC is 04:00 in Denmark", hm(HK.clock(utc(2026, 1, 15, 3, 0))) == "04:00",
    hm(HK.clock(utc(2026, 1, 15, 3, 0))))
  check("summer: 02:00 UTC is 04:00 in Denmark", hm(HK.clock(utc(2026, 7, 1, 2, 0))) == "04:00")
  check("summer time ends the last Sunday of October at 01:00 UTC", hm(HK.clock(utc(2026, 10, 25, 0, 59))) == "02:59"
    and hm(HK.clock(utc(2026, 10, 25, 1, 0))) == "02:00")
  check("...and starts the last Sunday of March", hm(HK.clock(utc(2026, 3, 29, 0, 59))) == "01:59"
    and hm(HK.clock(utc(2026, 3, 29, 1, 0))) == "03:00")
  check("minutes to the restart", HK.restartIn(utc(2026, 1, 15, 2, 30)) == 30 and HK.restartIn(utc(2026, 1, 15, 3, 0)) == 0)

  DCC.persist.writeRotation({ current = "Caucasus", state = "running" })
  SRV.theatre, SRV.file = "Caucasus", "C:\\Missions\\DCC\\DCC_Caucasus.miz"
  SRV.cb.onMissionLoadEnd()
  DCC.started, DCC.ended = false, false
  env.mission.theatre = "Caucasus"
  DCC.start()
  local realClock, fake = HK.clock, { year = 2026, month = 1, day = 15, hour = 3, min = 29 }
  HK.clock = function() return fake end
  HK.restart.enabled = true
  local nChat, nLoad, nText = #SRV.chat, #SRV.loaded, #MOCK.texts
  frames(10)
  check("03:29: no warning yet", #SRV.chat == nChat)
  fake.min = 30; frames(10)
  check("03:30: 30-minute warning in chat and on screen", #SRV.chat == nChat + 1 and SRV.chat[#SRV.chat]:find("30 minutes", 1, true)
    and #MOCK.texts > nText and MOCK.texts[#MOCK.texts]:find("restart", 1, true), SRV.chat[#SRV.chat])
  frames(30)
  check("...only once", #SRV.chat == nChat + 1)
  fake.min = 50; frames(10)
  fake.min = 59; frames(10)
  check("10 and 1 minute warnings", #SRV.chat == nChat + 3 and SRV.chat[#SRV.chat]:find("1 minute ", 1, true), SRV.chat[#SRV.chat])
  DCC.warObj.state.nodes.senaki.side = "red"
  fake.hour, fake.min = 4, 0
  SRV.rt = SRV.rt + 700                               -- the mission has run long enough
  frames(10)
  check("04:00: the war is saved and the mission reloads", #SRV.loaded == nLoad + 1 and SRV.loaded[#SRV.loaded] == SRV.file)
  check("...the save has the latest state", DCC.persist.load("Caucasus").nodes.senaki.side == "red")
  SRV.cb.onMissionLoadEnd()
  frames(30)
  check("...not again the same morning", #SRV.loaded == nLoad + 1)
  fake.day = 16
  frames(10)
  check("...nor right after a reload (mission must run 10 min)", #SRV.loaded == nLoad + 1)
  SRV.rt = SRV.rt + 700
  frames(10)
  check("next day: again", #SRV.loaded == nLoad + 2)
  -- v0.61: the weather versions of the map
  for _, v in ipairs({ "_wx2", "_wx3" }) do
    local f = io.open(missionsDir .. "DCC_Caucasus" .. v .. ".miz", "w"); f:write("miz"); f:close()
  end
  local base = missionsDir .. "DCC_Caucasus.miz"
  check("weather versions: the base mission goes to _wx2", HK.nextWeatherFile(base) == missionsDir .. "DCC_Caucasus_wx2.miz",
    HK.nextWeatherFile(base))
  check("..._wx2 to _wx3, the last back to the base", HK.nextWeatherFile(missionsDir .. "DCC_Caucasus_wx2.miz")
    == missionsDir .. "DCC_Caucasus_wx3.miz" and HK.nextWeatherFile(missionsDir .. "DCC_Caucasus_wx3.miz") == base)
  check("...a map without versions, or the test mission: the same file", HK.nextWeatherFile(missionsDir .. "DCC_Syria.miz")
    == missionsDir .. "DCC_Syria.miz" and HK.nextWeatherFile(missionsDir .. "DCC_Caucasus_ArmouryTest.miz")
    == missionsDir .. "DCC_Caucasus_ArmouryTest.miz")
  SRV.file = base
  fake.day = 17
  SRV.rt = SRV.rt + 700
  frames(10)
  check("daily restart loads the next weather", SRV.loaded[#SRV.loaded] == missionsDir .. "DCC_Caucasus_wx2.miz"
    and SRV.chat[#SRV.chat]:find("new weather", 1, true), SRV.loaded[#SRV.loaded])
  for _, v in ipairs({ "_wx2", "_wx3" }) do os.remove(missionsDir .. "DCC_Caucasus" .. v .. ".miz") end
  HK.clock, HK.restart.enabled = realClock, false
end

print("SRS voice through the hook (v0.50)")
do
  DCC.persist.writeRotation({ current = "Caucasus", state = "running" })
  SRV.theatre, SRV.file = "Caucasus", "C:\\Missions\\DCC\\DCC_Caucasus.miz"
  SRV.cb.onMissionLoadEnd()
  DCC.started, DCC.ended = false, false
  env.mission.theatre = "Caucasus"
  DCC.start()
  local ran = {}
  local realRun = HK.run
  HK.run = function(cmd) ran[#ran + 1] = cmd; return true end
  HK.srs.found = false
  DCC.srsQueue = {}
  DCC.dcs.srsSay("blue", "command", "Test one")
  frames(6)
  check("no SRS on the server: nothing played, queue dropped", #ran == 0 and #HK.srsQueue == 0 and #DCC.srsQueue == 0)
  HK.srs.found = true
  DCC.dcs.srsSay("blue", "command", "Kutaisi captured")
  DCC.dcs.srsSay("blue", "command", 'Second "line" & more')
  DCC.dcs.srsSay("red", "awacs", "Clean")
  frames(6)
  check("the hook collects the mission's lines and plays them", #ran == 2, #ran)
  check("...with SRS's text-to-speech: frequency, AM, coalition, port, voice", ran[1] and ran[1]:find("DCS-SR-ExternalAudio.exe", 1, true)
    and ran[1]:find(string.format("-f %.3f -m AM -c 2 -p 5002", DCC.config.srs.freqs.command.blue), 1, true) and ran[1]:find('-t "Kutaisi captured"', 1, true), ran[1])
  check("...one line at a time per frequency (the second waits)", #HK.srsQueue == 1)
  frames(10)
  check("...then the next, without shell specials", #ran == 3 and ran[3]:find('-t "Second line  more"', 1, true) ~= nil, ran[3])
  HK.run = realRun
end

print("War clock ends a war and rotates too")
do
  DCC.persist.writeRotation({ current = "Syria", state = "running" })
  MOCK.airbases = {}
  MOCK.buildAirbases(DCC_THEATERS.Syria)
  DCC.started, DCC.ended = false, false
  env.mission.theatre = "Syria"
  DCC.start()
  local w = DCC.warObj
  w.state.clockStart = w.state.tick - w:clockTicksLeft() - (w.state.tick - (w.state.clockStart or 0)) + 1
  -- Morten flies three sorties for the side that is ahead (the minimum for the bonus)
  local lead = w:clockLeader()
  local someNode
  for _, id in ipairs(w.T.order) do if w.state.nodes[id].side == lead then someNode = id; break end end
  local np = DCC.dcs.nodePos[someNode]
  local u = MOCK.spawnPlayer(DCC.dcs.COAL[lead], "F-16C_50", np.x, np.z, "Morten")
  u.air = true
  for _ = 1, 3 do
    MOCK.fire({ id = world.event.S_EVENT_TAKEOFF, initiator = u })
    MOCK.fire({ id = world.event.S_EVENT_LAND, initiator = u })
  end
  check("sorties on the war roster", (function() for _, r in pairs(w.state.roster or {}) do
    if r.name == "Morten" and r[lead] == 3 then return true end end return false end)())
  check("one tick left on the clock", w:clockTicksLeft() == 1, w:clockTicksLeft())
  DCC.onTick()
  check("clock victory", w.state.winner ~= nil and w.state.winBy == "clock")
  local r = DCC.persist.readRotation()
  check("rotation: ended on Syria, next Persian Gulf", r.state == "ended" and r.finished == "Syria" and r.next == "PersianGulf")
  check("flag 9900 set", MOCK.flags[DCC.config.campaignOverFlag] == 1)
  local text = table.concat(MOCK.texts, "\n")
  check("victory bonus announced for the roster", text:find("Victory bonus (+50 points, war clock)", 1, true) ~= nil
    and text:find("Morten", 1, true) ~= nil)
  local key
  for k, p in pairs(DCC.pilots.data.pilots) do if p.name == "Morten" then key = k end end
  check("war report shown", text:find("=== WAR REPORT - Syria ===", 1, true) ~= nil
    and text:find("Top pilots (1 flew in this war)", 1, true) ~= nil)
  local f = io.open(MOCK.writedir .. "DCC\\Syria_war_report_" .. w.state.tick .. ".txt", "r")
  check("war report saved as a text file", f ~= nil)
  if f then f:close() end
  check("bonus saved in pilots.json", key and DCC.persist.loadPilots().pilots[key].wins_clock == 1)
end
print("A server without file access (io/lfs sanitized)")
do
  local realLfs = lfs
  lfs = nil
  MOCK.airbases = {}
  MOCK.buildAirbases(DCC_THEATERS.Caucasus)
  DCC.started, DCC.ended = false, false
  env.mission.theatre = "Caucasus"
  DCC.start()
  local w = DCC.warObj
  check("campaign still starts", DCC.started and w.T.name == "Caucasus")
  check("knows it cannot save", w.noSave == true)
  check("war clock shortened to warClockDaysNoSave", w:clockTicksLeft() ==
    math.floor(DCC.config.warClockDaysNoSave * 86400 / DCC.config.tickSeconds + 0.5))
  local said = false
  for _, t in ipairs(MOCK.texts) do if t:find("cannot save the campaign", 1, true) then said = true end end
  check("players are told", said)
  for _, ns in pairs(w.state.nodes) do ns.side = "red" end
  for mid, mv in pairs(w.state.moves) do if mv.side == "blue" then w.state.moves[mid] = nil end end
  MOCK.flags[DCC.config.endMissionFlag] = nil
  DCC.onTick()
  check("RED wins", w.state.winner == "red")
  MOCK.advance(60)
  check("mission not ended before 2 min", MOCK.flags[DCC.config.endMissionFlag] == nil)
  MOCK.advance(65)
  check("end-mission flag set: the server loads the next mission in its list", MOCK.flags[DCC.config.endMissionFlag] == 1)
  lfs = realLfs
end
check("no script errors", errors == 0, errors)

print(string.format("\n%d passed, %d failed", passed, failed))
DCC_EXIT_CODE = failed == 0 and 0 or 1
