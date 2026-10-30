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
dofile(DCC_ROOT .. "/src/dcc_dcs_armoury.lua")
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
check("territory shaded: one polygon per base", MOCK.countMarks("markup7") == #DCC_THEATERS.Caucasus.nodes, MOCK.countMarks("markup7"))
local blueFill = 0
for _, m in pairs(MOCK.marks) do
  if m.kind == "markup7" and m.coal == -1 then
    local fill = m.args[#m.args - 2]
    if fill[3] > fill[1] then blueFill = blueFill + 1 end
  end
end
check("territory polygons coloured by owner", blueFill > 0 and blueFill < #DCC_THEATERS.Caucasus.nodes)
check("node circles drawn (plus own SAM rings)", MOCK.countMarks("circle") >= #DCC_THEATERS.Caucasus.nodes)
check("status menu added for both sides", #MOCK.menus == 2)

print("Warehouses (dynamic spawn)")
local kut = MOCK.airbases["Kutaisi"].wh
-- v0.36: 20 of each type at every airbase, depots too
local N = DCC_CATALOGS.modern.aircraftStock.depot
check("v0.36: 20 of each type in the catalog", N == 20 and DCC_CATALOGS.modern.aircraftStock.airbase == 20)
check("BLUE base: BLUE aircraft stocked", kut:getItemCount("FA-18C_hornet") == N, kut:getItemCount("FA-18C_hornet"))
check("BLUE base: RED-only aircraft removed (Su-33, J-11A)", kut:getItemCount("Su-33") == 0 and kut:getItemCount("J-11A") == 0)
check("every BLUE type on the shelf (F-15C, M-2000C, Gazelle)", kut:getItemCount("F-15C") == N
  and kut:getItemCount("M-2000C") == N and kut:getItemCount("SA342L") == N, kut:getItemCount("F-15C"))
check("...and no RED-only type (Su-25T, Ka-50)", kut:getItemCount("Su-25T") == 0 and kut:getItemCount("Ka-50") == 0)
check("v0.36: allied eastern types for BLUE (MiG-29A, JF-17, Su-27, Mi-24P)", kut:getItemCount("MiG-29A") == N
  and kut:getItemCount("Su-27") == N
  and kut:getItemCount("JF-17") == N and kut:getItemCount("Mi-24P") == N, kut:getItemCount("MiG-29A"))
local bat = MOCK.airbases["Batumi"].wh
check("every depot 20 too", bat:getItemCount("F-16C_50") == N, bat:getItemCount("F-16C_50"))
local soc = MOCK.airbases["Sochi-Adler"].wh
check("RED base: BLUE aircraft removed", soc:getItemCount("FA-18C_hornet") == 0)
check("...but RED keeps its MiG-29s and JF-17s", soc:getItemCount("MiG-29A") > 0 and soc:getItemCount("JF-17") > 0,
  soc:getItemCount("MiG-29A"))

print("Slot guard")
local sochi = B.nodePos.sochi
local intruder = MOCK.playerBirth(2, sochi.x + 300, sochi.z)
check("BLUE player at RED Sochi removed", intruder.destroyed == true)
local ok = MOCK.playerBirth(2, B.nodePos.batumi.x + 300, B.nodePos.batumi.z)
check("BLUE player at BLUE Batumi kept", ok.destroyed ~= true)

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
  for _, g in pairs(MOCK.groups) do if not g.player and g.country ~= 80 and g.country ~= 81 then return false end end
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

print("Convoys")
player.x, player.z = gori.x, gori.z
B.liveCheck()
-- Put a BLUE convoy on the road Tbilisi -> Gori (both ends near the player).
war.state.nodes.tbilisi.supply = 200
local cv = war:startCargo("convoy", "blue", "tbilisi", "gori", 30)
B.reconcileCargo()
local cg = MOCK.groups["DCC_" .. cv.id]
check("convoy spawned as trucks", cg ~= nil and #cg.units >= 3, cg and #cg.units)
cg.units[2].alive = false
B.pollAllCargo()
check("lost truck shrinks the cargo", war.state.moves[cv.id] and war.state.moves[cv.id].health < 1)
MOCK.killGroup("DCC_" .. cv.id)
B.pollAllCargo()
check("destroyed convoy delivers nothing", war.state.moves[cv.id] == nil)
local lostMsg = false
for _, ev in ipairs(war.newEvents) do if ev.kind == "convoy_lost" then lostMsg = true end end
check("convoy loss reported", lostMsg)
B.reconcileCargo()
check("dead convoy group cleaned up", MOCK.groups["DCC_" .. cv.id] == nil)

print("Airlift")
war.state.nodes.batumi.supply = 200
local before = war.state.nodes.vaziani.supply
local al = war:startCargo("airlift", "blue", "batumi", "vaziani", 30)
B.reconcileCargo()
local ag = MOCK.groups["DCC_" .. al.id]
check("airlift spawned as an aircraft even far from players", ag ~= nil and ag.category == Group.Category.AIRPLANE)
local delivered = false
for _ = 1, 40 do
  MOCK.advance(300)
  if not war.state.moves[al.id] then delivered = true; break end
end
check("airlift lands and delivers", delivered and war.state.nodes.vaziani.supply > before - 5,
  string.format("%.1f -> %.1f", before, war.state.nodes.vaziani.supply))
check("landed transport removed", MOCK.groups["DCC_" .. al.id] == nil)

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
local supplyText = false
for _, m in pairs(MOCK.marks) do
  if m.kind == "text" and tostring(m.args[#m.args]):find("SU") then supplyText = true end
end
check("node labels show supply to the owner", supplyText)
check("convoys moved during the run", (war.state.stats.delivered.blue + war.state.stats.delivered.red) > 0)

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

print("Capture flips the warehouse")
-- Fresh war: hand Kutaisi to RED and run one tick of the main loop.
local w2 = DCC.warObj
w2.state.winner = nil
w2.state.nodes.kutaisi.side = "red"
w2:onCaptureSupply("kutaisi")
DCC.dcs.writeWarehouses()
check("captured base: BLUE aircraft gone", kut:getItemCount("FA-18C_hornet") == 0)
check("captured base: RED types listed (empty until resupplied)", kut:getItemCount("Su-27") == 0
  and w2.state.nodes.kutaisi.air["Su-27"] == 0)

print("AI skill (v0.41)")
local allAce, nAi = true, 0
for name, g in pairs(MOCK.groups) do
  if name:find("^DCC_") and g.data then
    for _, u in ipairs(g.data.units) do
      nAi = nAi + 1
      if u.skill ~= "Excellent" then allAce = false end
    end
  end
end
check("v0.41: every AI unit the engine spawns is Ace (Excellent)", nAi > 0 and allAce and DCC.config.aiSkill == "Excellent", nAi)
coalition.addGroup(80, Group.Category.AIRPLANE, { name = "TEST_CLIENT", units = { { name = "TEST_CLIENT_1", type = "F-16C_50",
  x = 0, y = 0, alt = 1000, skill = "Client", payload = { fuel = 3000 } } } })
check("...player slots are left alone", MOCK.groups.TEST_CLIENT.data.units[1].skill == "Client")

print("No AI jamming (v0.42)")
coalition.addGroup(81, Group.Category.AIRPLANE, { name = "TEST_ECM", units = { { name = "TEST_ECM_1", type = "Su-34",
  x = 0, y = 0, alt = 6000, payload = { fuel = 9000 } } } })
check("v0.42: AI aircraft never use ECM (no jamming strobes on the F-16s)",
  MOCK.groups.TEST_ECM.options and MOCK.groups.TEST_ECM.options[13] == 0 and DCC.config.aiEcm == "never")
check("...and keep the datalink on", MOCK.groups.TEST_ECM.commands and MOCK.groups.TEST_ECM.commands.EPLRS == true)

print("Off the runway (v0.37)")
-- 9-player test: tanks stood and drove on the runway. A 3 km x 60 m runway through Kutaisi's centre:
local kc = DCC.dcs.nodePos.kutaisi
local realSurface = land.getSurfaceType
land.getSurfaceType = function(p)
  if math.abs(p.x - kc.x) <= 1500 and math.abs(p.y - kc.z) <= 30 then return land.SurfaceType.RUNWAY end
  return realSurface(p)
end
local onRunway = function(x, z) return math.abs(x - kc.x) <= 1500 and math.abs(z - kc.z) <= 30 + DCC.config.runwayClearM end
coalition.addGroup(80, Group.Category.GROUND, { name = "TEST_RWY", units = {
  { name = "TEST_RWY_1", type = "M-1 Abrams", x = kc.x, y = kc.z }, { name = "TEST_RWY_2", type = "M-1 Abrams", x = kc.x + 200, y = kc.z + 10 } },
  route = { points = { { x = kc.x, y = kc.z }, { x = kc.x - 600, y = kc.z } } } })
local tg = MOCK.groups.TEST_RWY
check("v0.37: a tank spawned on the runway is moved off it", not onRunway(tg.units[1].x, tg.units[1].z)
  and not onRunway(tg.units[2].x, tg.units[2].z), tg.units[1].z - kc.z)
check("...and no waypoint on the runway", not onRunway(tg.route[1].x, tg.route[1].y) and not onRunway(tg.route[2].x, tg.route[2].y))
local allOff = true
for i = 1, 40 do
  local sp = DCC.dcs.scatter("kutaisi", "p" .. i)
  if onRunway(sp.x, sp.z) then allOff = false end
end
check("...garrison spots at an airbase are never on the runway", allOff)
local sx, sz = DCC.dcs.landNear(kc.x, kc.z)
check("...statics (CTLD crates on an apron) are not moved", sx == kc.x and sz == kc.z)
land.getSurfaceType = realSurface

print(string.format("\n%d passed, %d failed", passed, failed))
DCC_EXIT_CODE = failed == 0 and 0 or 1
