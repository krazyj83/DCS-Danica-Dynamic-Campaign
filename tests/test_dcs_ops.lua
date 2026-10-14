-- ============================================================================
-- Phase 3 bridge tests against tests/dcs_mock.lua: fly every mission type.
--   python tools/run_lua.py tests/test_dcs_ops.lua
-- ============================================================================

local passed, failed = 0, 0
local function check(name, cond, detail)
  if cond then passed = passed + 1; print("  ok   " .. name)
  else failed = failed + 1; print("  FAIL " .. name .. (detail and (" - " .. tostring(detail)) or "")) end
end

dofile(DCC_ROOT .. "/tests/dcs_mock.lua")
MOCK.writedir = (arg[1] or "/tmp") .. "/dcc_ops_" .. tostring(os.time()) .. "/"
os.execute('mkdir -p "' .. MOCK.writedir .. 'DCC"')
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
dofile(DCC_ROOT .. "/src/dcc_main.lua")

local errors = 0
local realLog = DCC.util.log
DCC.util.log = function(fmt, ...)
  local msg = string.format(fmt, ...)
  if msg:find("ERROR") then errors = errors + 1; print("    " .. msg) end
end

DCC.start()
local B, war = DCC.dcs, DCC.warObj
war.fogOfWar = false          -- phase-3 checks: god's-eye board (fog has its own test file)
war:tick(); war:tick()          -- fill the boards (CAP needs a main effort)
B.opsTick()

local function pos(id) return B.nodePos[id] end
local function at(u, id, dx, dz) local p = pos(id); u.x, u.z = p.x + (dx or 0), p.z + (dz or 0) end
local function rec(u) return B.players[u:getName()] end
local function missionOf(u) local p = rec(u); return p and p.mission and war.state.missions[p.mission] end

print("Players and the mission board")
local kp = pos("kutaisi")
local viper, vg = MOCK.spawnPlayer(2, "F-16C_50", kp.x, kp.z, "Morten")
check("player registered on birth", rec(viper) ~= nil and rec(viper).side == "blue")
check("pilot record created", DCC.pilots.data.pilots["Morten"] ~= nil)
local items = table.concat(MOCK.menuItems(vg.id), " | ")
check("menu lists SEAD for an F-16", items:find("SEAD:", 1, true) ~= nil, items)
check("menu has record and leaderboard", items:find("My pilot record", 1, true) and items:find("Leaderboard", 1, true))
check("no cargo menu for a fighter", items:find("Load supply crate", 1, true) == nil)
local hog, hg = MOCK.spawnPlayer(2, "A-10C_2", kp.x, kp.z, "Jens")
local hogItems = table.concat(MOCK.menuItems(hg.id), " | ")
check("A-10 sees no SEAD or CAP", hogItems:find("SEAD:", 1, true) == nil and hogItems:find("CAP:", 1, true) == nil)

print("SEAD / DEAD")
check("take SEAD from the menu", MOCK.click(vg.id, "SEAD:"))
local m = missionOf(viper)
check("mission assigned", m ~= nil and m.type == "SEAD")
check("briefing has coordinates", MOCK.lastGroupText(vg.id):find("Target:", 1, true) ~= nil)
check("target marked on the F10 map for the group", MOCK.countMarks("groupmark") >= 1)
local samNode = m.target
at(viper, samNode, 30000, 0)
viper.air = true
MOCK.advance(31)
local sg = MOCK.groups["DCC_SAM_" .. samNode]
check("SAM site spawned when a player is within 80 km", sg ~= nil)
if sg then
  for _, u in ipairs(sg.units) do if u.name:find("_r%d+$") then u.alive = false end end
  MOCK.advance(31)
  check("radar kill read back: SAM suppressed", war.state.nodes[samNode].sam.status == "suppressed")
  DCC.onTick()
  check("SEAD mission complete", war.state.missions[m.id].status == "done")
  check("points wait while the pilot is airborne", (DCC.pilots.data.pilots["Morten"].byType.SEAD or 0) == 0)
  -- fly home and land at Kutaisi
  local kp2 = pos("kutaisi")
  viper.x, viper.z, viper.air = kp2.x, kp2.z, false
  MOCK.fire({ id = world.event.S_EVENT_LAND, initiator = viper })
  check("mission credited to the pilot after landing", (DCC.pilots.data.pilots["Morten"].byType.SEAD or 0) == 1)
  viper.air = true
end

print("STRIKE")
check("take STRIKE", MOCK.click(hg.id, "STRIKE:"))
local ms = missionOf(hog)
at(hog, ms.target, 5000, 0)
hog.air = true
MOCK.advance(31)
local statics = 0
for name in pairs(MOCK.statics) do if name:find("DCC_INF_" .. ms.target, 1, true) then statics = statics + 1 end end
check("strike buildings spawned near players", statics == war.state.nodes[ms.target].infra.total, statics)
local victim
for name, s in pairs(MOCK.statics) do if name:find("DCC_INF_" .. ms.target, 1, true) then victim = s; break end end
victim.alive = false
MOCK.advance(31)
check("destroyed building read back", war:infraLost(ms.target) == 1)
DCC.onTick()
check("STRIKE mission complete", war.state.missions[ms.id].status == "done")

print("Kill credit")
MOCK.fire({ id = world.event.S_EVENT_KILL, initiator = hog, target = victim })
check("building kill credited", DCC.pilots.data.pilots["Jens"].kills_structure == 1)
local truck = { name = "DCC_c12_1", getName = function(s) return s.name end,
                getDesc = function() return { category = Unit.Category.GROUND_UNIT } end }
MOCK.fire({ id = world.event.S_EVENT_KILL, initiator = hog, target = truck })
check("convoy truck kill credited", DCC.pilots.data.pilots["Jens"].kills_convoy == 1)

print("RECON")
DCC.onTick()
local reconLabel
for _, mm in ipairs(war:openMissions("blue")) do if mm.type == "RECON" then reconLabel = mm.label; break end end
check("RECON offered", reconLabel ~= nil)
MOCK.click(vg.id, "RECON:")
local mr = missionOf(viper)
at(viper, mr.target, 3000, 0)
viper.alt = 1500
MOCK.advance(11)
check("low pass completes RECON", war.state.missions[mr.id].status == "done")
check("intel recorded for BLUE", war.state.intel.blue[mr.target] ~= nil)
B.draw()
local intelText = false
for _, mk in pairs(MOCK.marks) do
  if mk.kind == "text" and tostring(mk.args[#mk.args]):find("Recon", 1, true) then intelText = true end
end
check("intel drawn on BLUE's map", intelText)

print("CAP")
local capOk = MOCK.click(vg.id, "CAP:")
check("CAP offered", capOk)
if capOk then
  local mc = missionOf(viper)
  at(viper, mc.target, 10000, 0)
  viper.alt = 7000
  MOCK.advance(21 * 60)
  check("20 min on station completes CAP", war.state.missions[mc.id].status == "done")
  check("air superiority over the main effort", war:hasAirCover("blue", mc.target))
end

print("AI air")
local before = war.state.airPool.red.fighter
B.sorties = {}
B.planAir()
local airGroups = MOCK.countGroups("DCC_AIR_")
check("AI sorties launched while players fly", airGroups >= 2, airGroups)
local redCap
for name, so in pairs(B.sorties) do                      -- a live RED CAP sortie (there may be several now)
  if so.side == "red" and so.kind == "CAP" and MOCK.groups[name] then redCap = MOCK.groups[name] end
end
check("RED CAP cloned from its template", redCap ~= nil and redCap.units[1].type == "MiG-29S")
check("cloned group keeps the template loadout", redCap and redCap.data.units[1].payload.pylons[1] ~= nil)
local redFighterSorties = 0
for _, so in pairs(B.sorties) do if so.side == "red" and so.role == "fighter" then redFighterSorties = redFighterSorties + 1 end end
check("pool pays for each sortie", war.state.airPool.red.fighter == before - 2 * redFighterSorties,
  war.state.airPool.red.fighter .. " after " .. redFighterSorties .. " sorties")
local orbit = redCap and redCap.data.route.points[2].task.params.tasks
check("CAP waypoint has engage + orbit tasks", orbit and orbit[1].id == "EngageTargets" and orbit[2].id == "Orbit")
redCap.units[1].alive = false
B.pollSorties()
check("AI loss read back", war.state.stats.airLost.red == 1)
MOCK.advance(3700)
check("sortie ends after its time", MOCK.groups[redCap.name] == nil)   -- (the pool keeps changing: packages fly too)

print("CSAR")
local senaki = pos("senaki")
local down = MOCK.spawnPlayer(2, "F-16C_50", senaki.x + 20000, senaki.z + 20000, "Lars")
MOCK.fire({ id = world.event.S_EVENT_EJECTION, initiator = down })
local did = next(war.state.downed)
check("ejection creates a downed pilot", did ~= nil)
check("downed pilot on the ground in DCS", MOCK.groups["DCC_CSAR_" .. tostring(did)] ~= nil)
check("ejection counted on the record", DCC.pilots.data.pilots["Lars"].ejections == 1)
local huey, hug = MOCK.spawnPlayer(2, "UH-1H", senaki.x, senaki.z, "Heli")
DCC.onTick()
local hueyItems = table.concat(MOCK.menuItems(hug.id), " | ")
check("CSAR on the Huey's board", hueyItems:find("CSAR:", 1, true) ~= nil, hueyItems)
check("cargo menu for the Huey", hueyItems:find("Load supply crate", 1, true) ~= nil)
MOCK.click(hug.id, "CSAR:")
local d = war.state.downed[did]
huey.x, huey.z, huey.air = d.pos.x + 50, d.pos.z, false
MOCK.advance(11)
check("green smoke on approach", MOCK.smokes >= 1)
check("pilot picked up", rec(huey).onboard[did] == true)
check("downed group removed after pickup", MOCK.groups["DCC_CSAR_" .. did] == nil)
local before16 = war.state.nodes.senaki.air["F-16C_50"]
at(huey, "senaki", 300, 0)
MOCK.advance(11)
check("landing at a friendly base rescues the pilot", war.state.downed[did] == nil)
check("aircraft refunded to Senaki", war.state.nodes.senaki.air["F-16C_50"] == before16 + 1)
check("rescue credited", DCC.pilots.data.pilots["Heli"].rescues == 1 and DCC.pilots.data.pilots["Lars"].saved == 1)

print("Logistics")
war.state.nodes.zugdidi.supply = 0
war.state.nodes.zugdidi.outOfSupply = true
DCC.onTick()
local logOk = MOCK.click(hug.id, "LOGISTICS: supply to Zugdidi")
check("LOGISTICS offered for Zugdidi", logOk)
local ml = missionOf(huey)
at(huey, "senaki", 200, 0); huey.air = false
MOCK.click(hug.id, "Load supply crate")
check("crate loaded", rec(huey).crates == 1 and MOCK.cargoMass[huey:getName()] == 1000)
at(huey, "zugdidi", 200, 0)
MOCK.click(hug.id, "Unload")
check("crate unloaded into Zugdidi", war.state.nodes.zugdidi.supply >= DCC.config.ops.crateSU - 1)
DCC.onTick()
check("LOGISTICS mission complete", ml and war.state.missions[ml.id].status == "done", ml and ml.status)
check("logistics credited to the pilot", (DCC.pilots.data.pilots["Heli"].byType.LOGISTICS or 0) == 1)

print("Air assault")
local gali = war.state.nodes.gali
if gali.side == "red" then for i = #gali.platoons, 1, -1 do war:destroyPlatoon(gali.platoons[i]) end end
at(huey, "zugdidi", 200, 0)
MOCK.click(hug.id, "Load troops")
check("troops on board", #rec(huey).troops == 1)
at(huey, "gali", 200, 0)
MOCK.click(hug.id, "Unload")
DCC.onTick()
check("troops dropped on empty Gali take it", war.state.nodes.gali.side == "blue")

print("Convoy escort")
local apache, ag = MOCK.spawnPlayer(2, "AH-64D_BLK_II", senaki.x, senaki.z, "Ole")
war.state.nodes.senaki.supply = 300
local cv = war:startCargo("convoy", "blue", "senaki", "zugdidi", 30)
cv.front = true
DCC.onTick()
local convOk = MOCK.click(ag.id, "CONVOY:")
check("CONVOY offered to an Apache", convOk)
if convOk then
  local mc = missionOf(apache)
  check("ambush spawned on the convoy's road", MOCK.groups["DCC_AMB_" .. mc.id] ~= nil)
  check("escorted convoy forced live", B.forced[mc.target] == true)
end

print("Leaving the slot")
MOCK.click(hug.id, "Load troops")
local carriedPid = rec(huey).troops[1]
MOCK.fire({ id = world.event.S_EVENT_PLAYER_LEAVE_UNIT, initiator = huey })
check("troops go home when the player leaves", carriedPid == nil or war.state.carried[carriedPid] == nil)
check("player record closed", rec(huey) == nil)

print("Pilot records saved")
DCC.save()
local f = io.open(MOCK.writedir .. "DCC\\pilots.json", "r")
check("pilots.json written", f ~= nil)
if f then
  local data = DCC.json.decode(f:read("*a")); f:close()
  check("records survive the file", data.pilots.Morten.byType.SEAD == 1 and data.pilots.Heli.rescues == 1)
end

print("A day of war with players")
MOCK.advance(24 * 3600)
check("no script errors in phase 3 loops", errors == 0, errors)

DCC.util.log = realLog
print(string.format("\n%d passed, %d failed", passed, failed))
DCC_EXIT_CODE = failed == 0 and 0 or 1
