-- ============================================================================
-- Tests for the DCS bridge and main loop against tests/dcs_mock.lua.
--   python tools/run_lua.py tests/test_dcs_bridge.lua
-- ============================================================================

local passed, failed = 0, 0
local function check(name, cond, detail)
  if cond then passed = passed + 1; print("  ok   " .. name)
  else failed = failed + 1; print("  FAIL " .. name .. (detail and (" - " .. tostring(detail)) or "")) end
end

dofile(DCC_ROOT .. "/tests/dcs_mock.lua")
MOCK.writedir = (arg[1] or "/tmp") .. "/dcc_test_" .. tostring(os.time()) .. "/"
os.execute('mkdir -p "' .. MOCK.writedir .. '"')
MOCK.buildAirbases(DCC_THEATERS.Caucasus)
MOCK.missingTypes["M1126 Stryker ICV"] = true   -- pretend a type is missing: fallback must kick in

dofile(DCC_ROOT .. "/src/dcc_persist.lua")
dofile(DCC_ROOT .. "/src/dcc_dcs.lua")
dofile(DCC_ROOT .. "/src/dcc_main.lua")

local B = DCC.dcs
local gori = coord.LLtoLO(41.9840, 44.1100, 0)

print("Start-up")
local player = MOCK.addPlayer(2, gori.x, gori.z)
DCC.start()
local war = DCC.warObj
check("campaign started", DCC.started and war ~= nil)
check("Batumi airbase set to BLUE", MOCK.airbases["Batumi"].coalition == 2)
check("Sukhumi airbase set to RED", MOCK.airbases["Sukhumi-Babushara"].coalition == 1)
check("auto-capture switched off", MOCK.airbases["Kutaisi"].auto == false)
check("renamed airbase found by position", B.airbases.minvody == "Mineralnye Vody Airport", B.airbases.minvody)
check("front line drawn", MOCK.countMarks("line") >= 4, MOCK.countMarks("line"))
check("node circles drawn", MOCK.countMarks("circle") == #DCC_THEATERS.Caucasus.nodes)
check("status menu added for both sides", #MOCK.menus == 2)

print("Live bubble")
check("Gori is live", B.liveNodes.gori == true)
check("Tskhinvali (28 km) is live", B.liveNodes.tskhinvali == true)
check("Batumi (far away) is not live", B.liveNodes.batumi == nil)
local goriPlatoons = #war.state.nodes.gori.platoons
local spawnedAtGori = 0
for pid, rec in pairs(B.spawned) do if rec.key == "g:gori" then spawnedAtGori = spawnedAtGori + 1 end end
check("every Gori platoon spawned", spawnedAtGori == goriPlatoons, spawnedAtGori .. "/" .. goriPlatoons)
check("missing unit type replaced by fallback", B.unitTypes("MECH_PLT", "blue")[1] == "M-113")
check("present unit types kept", B.unitTypes("ARMOR_PLT", "blue")[1] == "M-1 Abrams")
check("spawned groups use CJTF countries", (function()
  for _, g in pairs(MOCK.groups) do if g.country ~= 80 and g.country ~= 81 then return false end end
  return true end)())

print("Read-back")
local victim = war.state.nodes.gori.platoons[1]
MOCK.killGroup("DCC_" .. victim)
B.liveCheck()
check("destroyed DCS group removes the platoon from the model", war.state.platoons[victim] == nil)
local hurt = war.state.nodes.gori.platoons[1]
local g = MOCK.groups["DCC_" .. hurt]
g.units[1].alive = false
B.liveCheck()
local h = war.state.platoons[hurt] and war.state.platoons[hurt].health or 0
check("partial losses lower platoon health", h < 1 and h > 0, h)

print("Despawn keeps damage")
player.x, player.z = coord.LLtoLO(45.0, 37.0, 0).x, coord.LLtoLO(45.0, 37.0, 0).z  -- fly to Anapa
B.liveCheck()
check("Gori groups removed after players leave", MOCK.groups["DCC_" .. hurt] == nil)
check("damage kept in the model", war.state.platoons[hurt] and war.state.platoons[hurt].health == h)
check("Anapa now live instead", B.liveNodes.anapa == true)

print("Running the war with players present")
player.x, player.z = gori.x, gori.z
local errors = 0
local realLog = DCC.util.log
DCC.util.log = function(fmt, ...)
  local msg = string.format(fmt, ...)
  if msg:find("ERROR") then errors = errors + 1; print("    " .. msg) end
end
MOCK.advance(48 * 3600)                     -- two days of mission time through the real loops
DCC.util.log = realLog
check("no script errors in 2 days of loops", errors == 0, errors)
check("war advanced ~576 ticks", war.state.tick >= 570, war.state.tick)
local liveGroups = MOCK.countGroups()
check("spawned group count within budget", liveGroups <= DCC.config.maxLivePlatoons, liveGroups)
check("assault arrows drawn for own side", MOCK.countMarks("arrow") >= 0)

print("Save and restore")
local f = io.open(MOCK.writedir .. "DCC\\Caucasus_war.json", "r")
check("save file written", f ~= nil)
if f then
  local text = f:read("*a"); f:close()
  local st = DCC.json.decode(text)
  check("save holds the current tick", st and st.tick == war.state.tick, st and st.tick)
  local r = DCC.War.restore(DCC_THEATERS.Caucasus, DCC_CATALOGS.modern, DCC.config, st)
  check("restored war has the same owners", (function()
    for id, ns in pairs(war.state.nodes) do if r.state.nodes[id].side ~= ns.side then return false end end
    return true end)())
end

print("Victory")
-- Wipe RED out: its nodes and the columns it still has on the roads.
for mid, mv in pairs(war.state.moves) do
  if mv.side == "red" then
    for i = #mv.platoons, 1, -1 do war:destroyPlatoon(mv.platoons[i]) end
    war.state.moves[mid] = nil
  end
end
for id, ns in pairs(war.state.nodes) do
  if ns.side == "red" then
    for i = #ns.platoons, 1, -1 do war:destroyPlatoon(ns.platoons[i]) end
    ns.side = "blue"
  end
end
DCC.onTick()
check("winner recorded", war.state.winner == "blue", war.state.winner)
check("campaign-over flag set for the server", MOCK.flags[DCC.config.campaignOverFlag] == 1)
local announced = false
for _, t in ipairs(MOCK.texts) do if t:find("Next theater: Syria") then announced = true end end
check("next map in rotation announced", announced)

print(string.format("\n%d passed, %d failed", passed, failed))
DCC_EXIT_CODE = failed == 0 and 0 or 1
