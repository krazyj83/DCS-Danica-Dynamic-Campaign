-- ============================================================================
-- Bridge tests after phase 5: night and weather, AI adaptation, FARPs, ships,
-- JTAC, squadrons and the public files for the web map / Discord.
--   python tools/run_lua.py tests/test_dcs_world.lua
-- ============================================================================

local passed, failed = 0, 0
local function check(name, cond, detail)
  if cond then passed = passed + 1; print("  ok   " .. name)
  else failed = failed + 1; print("  FAIL " .. name .. (detail and (" - " .. tostring(detail)) or "")) end
end

dofile(DCC_ROOT .. "/tests/dcs_mock.lua")
MOCK.writedir = (arg[1] or "/tmp") .. "/dcc_world_" .. tostring(os.time()) .. "/"
os.execute('mkdir -p "' .. MOCK.writedir .. '"')
local TH = DCC_THEATERS.Caucasus
MOCK.buildAirbases(TH)
MOCK.addTemplates()
-- the generated mission has two invisible FARPs per town
for _, n in ipairs(TH.nodes) do
  if n.kind == "town" then
    local p = coord.LLtoLO(n.lat, n.lon, 0)
    MOCK.addFarp("DCC_FARP_" .. n.id .. "_blue", p.x + 1500, p.z, 2)
    MOCK.addFarp("DCC_FARP_" .. n.id .. "_red", p.x - 1500, p.z, 1)
  end
end
-- and, for this test, a BLUE carrier in the Black Sea
TH.naval = { { id = "cvn", side = "blue", name = "CVN-74 John C. Stennis", kind = "carrier", lat = 42.6, lon = 40.6,
               heading = 300, ship = "Stennis", escorts = {}, slots = {} } }
local cvp = coord.LLtoLO(42.6, 40.6, 0)
MOCK.addShipGroup("DCC_NAVAL_cvn", 2, cvp.x, cvp.z, { "Stennis", "USS_Arleigh_Burke_IIa" })

for _, f in ipairs({ "dcc_persist", "dcc_dcs", "dcc_dcs_supply", "dcc_dcs_ops", "dcc_dcs_intel", "dcc_dcs_radar",
                     "dcc_dcs_world", "dcc_dcs_jtac", "dcc_dcs_public", "dcc_main" }) do
  dofile(DCC_ROOT .. "/src/" .. f .. ".lua")
end

local errors = 0
DCC.util.log = function(fmt, ...)
  local msg = string.format(fmt, ...)
  if msg:find("ERROR") then errors = errors + 1; print("    " .. msg) end
end

DCC.start()
local B, war = DCC.dcs, DCC.warObj
local BLUE, RED = 2, 1

print("Night and weather")
check("noon is day", not war:isNight())
MOCK.absBase = 22 * 3600
B.updateNight()
check("22:00 is night", war:isNight())
check("night shortens eyes", B.visualFactor(false) == DCC.config.world.nightVisual)
MOCK.absBase = 43200
B.updateNight()
war.state.weather = { kind = "storm", since = war.state.tick }
B.applyWeather()
check("storm shown as fog", MOCK.fog and MOCK.fog.visibility == DCC.config.world.fog.storm[1])
war.state.weather = { kind = "clear", since = war.state.tick }
B.applyWeather()
check("clear: fog off", MOCK.fog.visibility == 0)
check("weather in the status", table.concat(B.opsStatusLines("blue"), " "):find("Weather: clear skies", 1, true) ~= nil)

print("Storm grounds AI attack sorties")
local kp = B.nodePos.kutaisi
local viper, vg = MOCK.spawnPlayer(BLUE, "F-16C_50", kp.x, kp.z, "[VKG] Morten")
war.state.weather = { kind = "storm", since = war.state.tick }
local attackBefore = 0
for _, s in pairs(B.sorties) do if s.role == "attack" then attackBefore = attackBefore + 1 end end
for _ = 1, 3 do B.planAir() end
local attackAfter = 0
for _, s in pairs(B.sorties) do if s.role == "attack" then attackAfter = attackAfter + 1 end end
check("no new AI attack sorties in a storm", attackAfter == attackBefore)
war.state.weather = { kind = "clear", since = war.state.tick }

print("AI adaptation")
local a, b = "kutaisi", "zestaponi"
for _ = 1, 3 do war:addThreat("blue", a, b, 1) end
B.planAir()
local roadcap
for g, s in pairs(B.sorties) do if s.side == "blue" and s.kind == "ROADCAP" then roadcap = g end end
check("CAP sent over the threatened road", roadcap ~= nil)
local mv = war:startCargo("convoy", "blue", a, b, 20)
check("convoy on it is escorted", mv and mv.aiEscort)
B.liveNodes[a] = true
B.reconcileCargo()
local esc = B.escorts[mv.id]
check("escort vehicle drives with the live convoy", esc and MOCK.groups[esc] ~= nil)
check("escort is air defence", esc and (MOCK.groups[esc].units[1].type == "M1097 Avenger" or MOCK.groups[esc].units[1].type == "Vulcan"))
war:destroyCargo(mv.id, "test")
B.reconcileCargo()
check("escort leaves with the convoy", B.escorts[mv.id] == nil)

print("FARPs")
local town = "gori"
local wh = Airbase.getByName("DCC_FARP_gori_blue"):getWarehouse()
B.reconcileFarps()
check("unbuilt FARP has no helicopters", wh:getItemCount("UH-1H") == 0)
for _ = 1, 3 do war:deliverCrate("blue", town, 10) end
B.reconcileFarps()
check("built FARP stocks BLUE helicopters", wh:getItemCount("UH-1H") == DCC.config.world.farpHelos)
check("RED FARP at the same town stays empty", Airbase.getByName("DCC_FARP_gori_red"):getWarehouse():getItemCount("Mi-8MTV2") == 0)
check("fuel and ammo trucks at the FARP", MOCK.groups["DCC_FARPCREW_gori"] ~= nil and #MOCK.groups["DCC_FARPCREW_gori"].units == 3)
B.draw()
local farpMark = false
for _, id in ipairs(B.marks) do local m = MOCK.marks[id]; if m and m.args[#m.args] == "FARP" then farpMark = true end end
check("FARP on the map", farpMark)
war.state.nodes[town].side = "red"
war:onCaptureOps(town)
B.reconcileFarps()
check("captured: FARP emptied, crew gone", wh:getItemCount("UH-1H") == 0 and MOCK.groups["DCC_FARPCREW_gori"] == nil)
war.state.nodes[town].side = "blue"

print("JTAC")
-- a battle at a live RED node near the fighter
local target
for _, id in ipairs(war.T.order) do
  if war.state.nodes[id].side == "red" and war:frontEstimate("blue", id) and #war.state.nodes[id].platoons > 0 then target = id; break end
end
local tp = B.nodePos[target]
viper.x, viper.z = tp.x - 20000, tp.z
MOCK.advance(31)                                   -- garrison spawns
local cas = { id = "xjtac", side = "blue", type = "CAS", target = target, node = target, label = "test", base = {},
              created = war.state.tick, taken = {}, status = "open", needs = "A2G" }
war.state.missions[cas.id] = cas
B.takeMission({ unit = viper:getName(), mid = cas.id })
local rec = B.jtacs[cas.id]
check("JTAC team spawned for the CAS mission", rec ~= nil and MOCK.groups[rec.group] ~= nil)
check("JTAC is invisible and immortal", rec and MOCK.groups[rec.group].commands
  and MOCK.groups[rec.group].commands.SetInvisible == true and MOCK.groups[rec.group].commands.SetImmortal == true)
local items = table.concat(MOCK.menuItems(vg.id), " | ")
check("JTAC menu for the pilot", items:find("Report target", 1, true) and items:find("Mark with smoke", 1, true))
MOCK.click(vg.id, "Report target")
local laser
for _, sp in pairs(MOCK.spots or {}) do if sp.kind == "laser" then laser = sp end end
check("laser on a target with code 1688", laser and laser.code == 1688)
check("report gives MGRS and code", MOCK.lastGroupText(vg.id):find("code 1688", 1, true) ~= nil, MOCK.lastGroupText(vg.id))
local smokes = MOCK.smokes
MOCK.click(vg.id, "Mark with smoke")
check("smoke on the target", MOCK.smokes == smokes + 1)
-- target dies: laser moves on
local tgtUnit = Unit.getByName(rec.target)
tgtUnit.alive = false
B.jtacTick()
check("laser switches to the next target", rec.target ~= tgtUnit:getName() or rec.target == nil)
cas.status = "done"
B.jtacTick()
check("JTAC packs up when the mission ends", B.jtacs[cas.id] == nil and MOCK.groups[rec.group] == nil)

print("Carrier")
check("carrier tracked", B.naval.cvn ~= nil)
-- RED radar finds it: put a RED AWACS-height radar near it
local found = false
local r = { pos = { x = cvp.x + 150000, y = 9000, z = cvp.z }, agl = 9000, km = 350 }
found = B.radarSees(r, MOCK.groups["DCC_NAVAL_cvn"].units[1])
check("a high radar sees the carrier at 150 km", found)
local low = { pos = { x = cvp.x + 150000, y = 25, z = cvp.z }, agl = 25, km = 180 }
check("a ground radar does not (horizon)", not B.radarSees(low, MOCK.groups["DCC_NAVAL_cvn"].units[1]))
local red = MOCK.spawnPlayer(RED, "Su-27", cvp.x + 20000, cvp.z, "Ivan")
red.air, red.alt = true, 3000
B.intelScan()
check("RED pilot spots the carrier", war:isFresh("red", "ship:cvn"))
B.drawIntel()
local shipMark = false
for _, id in ipairs(B.intelMarks) do
  local m = MOCK.marks[id]
  if m and m.coal == RED and tostring(m.args[#m.args]):find("Stennis", 1, true) then shipMark = true end
end
check("carrier on RED's map", shipMark)
MOCK.killGroup("DCC_NAVAL_cvn")
B.pollNaval()
check("carrier sunk in the save", not war:shipUp("cvn") and B.naval.cvn == nil)
check("status says SUNK", table.concat(B.opsStatusLines("blue"), " "):find("SUNK", 1, true) ~= nil)

print("Public files and squadrons")
DCC.onTick()
local f = io.open(MOCK.writedir .. "DCC\\public.json", "r")
check("public.json written", f ~= nil)
local pub = f and DCC.json.decode(f:read("*a"))
if f then f:close() end
check("public: every base with owner and position", pub and #pub.nodes == #war.T.order and pub.nodes[1].lat ~= nil)
check("public: front line", pub and #pub.front > 0)
check("public: war clock", pub and pub.clock and pub.clock.hoursLeft > 0)
check("public: no garrison or supply numbers", pub and pub.nodes[1].platoons == nil and pub.nodes[1].supply == nil)
check("public: squadron board", pub and pub.squadrons[1] and pub.squadrons[1].tag == "VKG")
check("public: ship status", pub and pub.ships[1] and pub.ships[1].status == "sunk")
local feed = io.open(MOCK.writedir .. "DCC\\feed.jsonl", "r")
local lines = {}
if feed then for l in feed:lines() do lines[#lines + 1] = DCC.json.decode(l) end feed:close() end
check("feed has public events", #lines > 0)
local sunk, secret = false, false
for _, ev in ipairs(lines) do
  if ev.kind == "ship_sunk" then sunk = true end
  if ev.kind == "focus" or ev.kind == "assault" then secret = true end
end
check("ship loss in the feed", sunk)
check("no side secrets in the feed", not secret)
local seqOk = true
for i = 2, #lines do if lines[i].seq ~= lines[i - 1].seq + 1 then seqOk = false end end
check("feed numbered without gaps", seqOk and lines[1].warId == war.state.warId)
B.showSquadrons(viper:getName())
check("squadron leaderboard in the menu", MOCK.lastGroupText(vg.id):find("TOP SQUADRONS", 1, true) ~= nil)

print("A day with all of it")
for _ = 1, 288 do MOCK.advance(300) end
check("no script errors", errors == 0, errors)

print(string.format("\n%d passed, %d failed", passed, failed))
DCC_EXIT_CODE = failed == 0 and 0 or 1
