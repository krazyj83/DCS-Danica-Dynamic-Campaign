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
}
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
