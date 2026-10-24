-- ============================================================================
-- v0.27: Combined Arms, QRA scramble, engineer repair kit, performance guard.
--   python tools/run_lua.py tests/test_ext4.lua
-- ============================================================================

local passed, failed = 0, 0
local function check(name, cond, detail)
  if cond then passed = passed + 1; print("  ok   " .. name)
  else failed = failed + 1; print("  FAIL " .. name .. (detail and (" - " .. tostring(detail)) or "")) end
end

local T, C, cfg = DCC_THEATERS.Caucasus, DCC_CATALOGS.modern, DCC.config
local X = cfg.ext4

-- ===========================================================================
print("Pure model: engineers")
-- ===========================================================================
local w = DCC.War.new(T, C, cfg, 41)
w:tick()
local base
for _, id in ipairs(w.T.order) do
  local ns = w.state.nodes[id]
  if ns.side == "blue" and ns.infra and ns.sam and not base then base = id end
end
check("a BLUE base with buildings and air defence", base ~= nil)
local ns = w.state.nodes[base]
ns.sam = { status = "up" }
if ns.ewr then ns.ewr = { status = "up" } end
check("nothing broken: nothing to repair", w:repairNeed(base) == nil)
w:infraHit(base, 1)
w:samHit(base, "radar")
check("a building down: that first", w:repairNeed(base) == "infra")
check("RED engineers cannot repair a BLUE base", w:engineerRepair(base, "red") == nil)
local su0 = ns.supply
local txt = w:engineerRepair(base, "blue")
check("the kit rebuilds the fuel store", txt and txt:find("fuel store", 1, true) and next(ns.infra.lost) == nil, txt)
check("...then the air defence", w:repairNeed(base) == "sam" and w:engineerRepair(base, "blue") and ns.sam.status == "up")
if ns.ewr then
  ns.ewr = { status = "destroyed", since = w.state.tick }
  check("...then the radar", w:engineerRepair(base, "blue") and ns.ewr.status == "up")
end
check("no supply spent here (the crate is paid for where it is loaded)", ns.supply == su0)


-- ===========================================================================
print("Pure model: ground missions (v0.28)")
-- ===========================================================================
local g = DCC.War.new(T, C, cfg, 42)
g:tick()
local bnode, rnode
for _, id in ipairs(g.T.order) do
  local n = g.state.nodes[id]
  if n.side == "blue" and not bnode then bnode = id end
  if n.side == "red" and not rnode then rnode = id end
end
g.state.moves.mA = { id = "mA", kind = "assault", side = "blue", from = bnode, to = rnode, status = "fighting",
                     platoons = {}, progress = 1, km = 10 }
g.state.moves.mC = { id = "mC", kind = "convoy", side = "blue", from = bnode, to = bnode, status = "moving",
                     platoons = {}, progress = 0.2, km = 30, supply = 10 }
local gcLimit = cfg.missions.perType.GCONVOY
cfg.missions.perType.GCONVOY = 99
g:missionsTick()
cfg.missions.perType.GCONVOY = gcLimit
local asl, hold, gcv
for _, m in pairs(g.state.missions) do
  if m.type == "ASSAULT" and m.target == rnode then asl = m end
  if m.type == "HOLD" and m.target == rnode then hold = m end
  if m.type == "GCONVOY" and m.target == "mC" then gcv = m end
end
check("own attack: ASSAULT for BLUE", asl and asl.side == "blue" and asl.needs == "GROUND")
check("under attack: HOLD for RED", hold and hold.side == "red")
check("own supply convoy: GCONVOY", gcv and gcv.side == "blue")
g:takeMission(asl.id, "k1", "Tanker")
g:takeMission(asl.id, "k2", "Tourist")
g:groundPresence(asl.id, "k1", 400)
g:groundPresence(asl.id, "k2", 60)
local evs = { { kind = "capture", side = "blue", node = rnode } }
check("base taken: ASSAULT done", g:missionOutcome(asl, evs) == "done")
check("...credit only for who was there 5 min", asl.taken.k1 and not asl.taken.k2)
check("...and RED's HOLD failed", g:missionOutcome(hold, evs) == "failed")
g.state.moves.mC = nil
g.state.deliveredMoves.mC = { tick = g.state.tick, health = 1 }
check("convoy arrived: GCONVOY done", g:missionOutcome(gcv, {}) == "done")

-- ===========================================================================
print("Bridge")
-- ===========================================================================
dofile(DCC_ROOT .. "/tests/dcs_mock.lua")
MOCK.writedir = (arg[1] or "/tmp") .. "/dcc_x4_" .. tostring(os.time()) .. "/"
os.execute('mkdir -p "' .. MOCK.writedir .. '"')
MOCK.buildAirbases(T)
MOCK.addTemplates()
for _, s in ipairs(T.naval) do
  local p = coord.LLtoLO(s.lat, s.lon, 0)
  MOCK.addShipGroup("DCC_NAVAL_" .. s.id, s.side == "blue" and 2 or 1, p.x, p.z, { s.ship })
end
for _, f in ipairs({ "dcc_persist", "dcc_dcs", "dcc_dcs_supply", "dcc_dcs_ops", "dcc_dcs_intel", "dcc_dcs_radar",
                     "dcc_dcs_world", "dcc_dcs_jtac", "dcc_dcs_public", "dcc_dcs_air", "dcc_dcs_ground",
                     "dcc_dcs_ext_air", "dcc_dcs_ext_ground", "dcc_dcs_ext2", "dcc_dcs_ext3", "dcc_dcs_ext4",
                     "dcc_dcs_armoury", "dcc_main" }) do
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
local kp = B.nodePos.kutaisi
local viper, vg = MOCK.spawnPlayer(BLUE, "F-16C_50", kp.x, kp.z, "Morten")

print(" Combined Arms")
B.updateLive(); B.reconcile()
local plat, other
for name, g in pairs(MOCK.groups) do
  if name:find("^DCC_p%d+$") then plat = g end
  if name:find("^DCC_SAM") or name:find("^DCC_EWR") then other = g end
end
check("campaign platoons can be driven by CA players", plat and plat.data.units[1].playerCanDrive == true)
check("SAM / EWR sites stay AI only", other == nil or other.data.units[1].playerCanDrive ~= true)
check("patterns: convoys, artillery, skirmishes", B.caDrivable("DCC_c12") and B.caDrivable("DCC_ARTY_kutaisi")
  and B.caDrivable("DCC_SKIRM_3_blue") and not B.caDrivable("DCC_SAM_kutaisi"))
-- a CA player jumps into a tank next to an enemy base: not removed, not a pilot
local enemy
for _, id in ipairs(war.T.order) do if war.state.nodes[id].side == "red" and not enemy then enemy = id end end
local ep = B.nodePos[enemy]
MOCK.nextGroupId = MOCK.nextGroupId + 1
local tg = setmetatable({ name = "CA_TANK", exists = true, units = {}, route = {}, player = true, category = 2,
                          id = MOCK.nextGroupId }, MOCK.GroupMT)
local tank = setmetatable({ name = "CA_TANK_1", type = "M-1 Abrams", x = ep.x + 500, z = ep.z, alive = true,
                            coal = BLUE, player = "Tanker", group = tg }, MOCK.UnitMT)
tg.units[1] = tank
MOCK.groups.CA_TANK = tg
MOCK.fire({ id = world.event.S_EVENT_BIRTH, initiator = tank })
check("CA player in a tank at an enemy base: not slot-guarded", tank.alive and not tank.destroyed)
check("...and is a ground player (ground missions only)", B.players.CA_TANK_1 and B.players.CA_TANK_1.ground)

print(" QRA")
local p = B.players[viper:getName()]
war.fogOfWar = false
war.state.packages.ktest = { id = "ktest", side = "red", kind = "strike", status = "inbound",
                             target = { node = "kutaisi" } }
B.packages.ktest = nil
war:missionsTick()
local ic
for _, m in pairs(war.state.missions) do
  if m.type == "INTERCEPT" and m.target == "ktest" and m.side == "blue" then ic = m end
end
check("RED package detected: BLUE INTERCEPT", ic ~= nil)
B.qraScan()
local msg = MOCK.lastGroupText(vg.id) or ""
check("grounded F-16 pilot is scrambled", msg:find("SCRAMBLE", 1, true) ~= nil, msg)
check("...with heading and range", msg:find("heading %d%d%d") ~= nil and msg:find("nm", 1, true) ~= nil)
B.qraScan()
check("scrambled once per threat", MOCK.lastGroupText(vg.id) == msg)
viper.air = true
MOCK.fire({ id = world.event.S_EVENT_TAKEOFF, initiator = viper })
check("airborne within 5 min: the intercept is his", p.mission == ic.id, p.mission)
check("...and he is QRA crew", B.x4.qraCrew[ic.id] and B.x4.qraCrew[ic.id][p.key])
-- a second pilot who took too long
local hornet, hg = MOCK.spawnPlayer(BLUE, "FA-18C_hornet", kp.x + 200, kp.z, "Kasper")
local p2 = B.players[hornet:getName()]
p2.qra = { mid = ic.id, t = timer.getTime() - (X.qra.minutes * 60 + 30) }
hornet.air = true
MOCK.fire({ id = world.event.S_EVENT_TAKEOFF, initiator = hornet })
check("airborne after 5 min: no automatic mission", p2.mission == nil and p2.qra == nil)
local before = DCC.pilots:get(p.key).qra or 0
war.state.packages.ktest.status = "destroyed"
war:missionsTick()
check("intercept done: +1 QRA", (DCC.pilots:get(p.key).qra or 0) == before + 1)
war.fogOfWar = true

print(" Engineer repair kit")
local rb
for _, id in ipairs(war.T.order) do
  local n = war.state.nodes[id]
  if n.side == "blue" and n.infra and not rb then rb = id end
end
war:infraHit(rb, 1)
local rp = B.nodePos[rb]
local crate = { coalition = BLUE, crateName = "kit1", position = { x = rp.x + 4000, y = 0, z = rp.z },
                descriptor = { dccHeavy = "repair" } }
check("set down 4 km out: refused", B.heavyDown(crate, crate.position, true) == false)
crate.position = { x = rp.x + 500, y = 0, z = rp.z }
check("at the base: repaired", B.heavyDown(crate, crate.position, true) == true and next(war.state.nodes[rb].infra.lost) == nil)
check("nothing broken: the kit waits", B.heavyDown(crate, crate.position, true) == false)

print(" Performance guard")
check("counts the ground units in DCS", B.groundUnitCount() > 0, B.groundUnitCount())
local realCount = B.groundUnitCount
local R0, P0, S0, U0 = cfg.liveRadiusKm, cfg.maxLivePlatoons, cfg.ground.skirmishMax, cfg.ext3.popup.max
B.groundUnitCount = function() return 800 end
B.perfCheck(true)
check("800 units: level 1, smaller bubble", B.x4.perfLevel == 1 and cfg.liveRadiusKm < R0 and cfg.maxLivePlatoons < P0,
  cfg.liveRadiusKm .. " km / " .. cfg.maxLivePlatoons)
check("...and the server is told", (MOCK.texts[#MOCK.texts] or ""):find("Server busy", 1, true) ~= nil)
B.groundUnitCount = function() return 1200 end
B.perfCheck(true)
check("1200 units: level 2", B.x4.perfLevel == 2 and cfg.ground.skirmishMax < S0 and cfg.ext3.popup.max <= U0)
B.groundUnitCount = function() return 900 end
B.perfCheck(true)
check("900 (just below): stays at level 2 (no flicker)", B.x4.perfLevel == 2)
B.groundUnitCount = function() return 300 end
B.perfCheck(true)
check("300: everything back", B.x4.perfLevel == 0 and cfg.liveRadiusKm == R0 and cfg.maxLivePlatoons == P0
  and cfg.ground.skirmishMax == S0 and cfg.ext3.popup.max == U0)
B.groundUnitCount = realCount

print(" Ground missions (v0.28)")
local bg
for name, grp in pairs(MOCK.groups) do
  if name:find("^DCC_p%d+$") and grp.units[1].coal == BLUE and not bg then bg = grp end
end
local gpid = bg.name:match("^DCC_(p%d+)$")
local gnode
for _, id in ipairs(war.T.order) do
  for _, x in ipairs(war.state.nodes[id].platoons) do if x == gpid then gnode = id end end
end
local driver = bg.units[1]
driver.player = "Tanker"
table.insert(MOCK.players[BLUE], driver)
MOCK.fire({ id = world.event.S_EVENT_PLAYER_ENTER_UNIT, initiator = driver })
local gp = B.players[driver.name]
check("CA player takes over a platoon tank: a ground player", gp and gp.ground == true)
war.state.moves.mG = { id = "mG", kind = "assault", side = "red", from = enemy, to = gnode, status = "fighting",
                       platoons = {}, progress = 1, km = 10 }
war:missionsTick()
local list = B.missionsFor(gp)
local onlyGround, hm = #list > 0, nil
for _, m in ipairs(list) do
  if m.needs ~= "GROUND" then onlyGround = false end
  if m.type == "HOLD" and m.target == gnode then hm = m end
end
check("his board: only ground missions, nearby", onlyGround, #list)
check("...HOLD his own base", hm ~= nil)
local airOnly = true
for _, m in ipairs(B.missionsFor(p)) do if m.needs == "GROUND" then airOnly = false end end
check("pilots never see ground missions", airOnly)
B.takeMission({ unit = driver.name, mid = hm.id })
B.x4.presenceAt = timer.getTime() - 400
B.groundPresenceTick()
local hmr = war.state.missions[hm.id]
check("near the base: presence counted", (hmr.presence or {})[gp.key] and hmr.presence[gp.key] >= 300)
local m0 = DCC.pilots:get(gp.key).missions or 0
war:finishMission(hmr, war:missionOutcome(hmr, { { kind = "repulsed", side = "blue", node = gnode } }))
check("attack repulsed: mission points for the tank crew", (DCC.pilots:get(gp.key).missions or 0) == m0 + 1)
war.state.moves.mG = nil
driver.x, driver.z = driver.x + 150000, driver.z
B.updateLive()
check("driven 150 km away: his platoon stays spawned", B.liveNodes[gnode] == true)
driver.x, driver.z = driver.x - 150000, driver.z

print(" Artillery for ground players (v0.29)")
local items = table.concat(MOCK.menuItems(bg.id), " | ")
check("Support menu: artillery on the nearest enemy / objective", items:find("Artillery on the nearest enemy in sight", 1, true)
  and items:find("Artillery on my objective", 1, true))
check("...no AWACS picture or armoury for a tank", not items:find("AWACS picture", 1, true))
local bat = war:batteries("blue")[1]
bat.node, bat.status = gnode, "up"
war.state.nodes[gnode].supply = 100
B.ext.cooldown.blue.arty = nil
coalition.addGroup(81, Group.Category.GROUND, { name = "TEST_RED_T72", units = {
  { name = "TEST_RED_T72_1", type = "T-72B", x = driver.x + 2000, y = driver.z } } })
local su0 = war.state.nodes[gnode].supply
MOCK.click(bg.id, "Artillery on the nearest enemy in sight")
check("enemy 2 km away in sight: fire mission for 10 SU, no rank needed",
  math.abs(war.state.nodes[gnode].supply - (su0 - DCC.config.ext.support.artySU)) < 0.01, war.state.nodes[gnode].supply)
check("...the side hears it", (MOCK.texts[#MOCK.texts] or ""):find("fire mission", 1, true) ~= nil, MOCK.texts[#MOCK.texts])
MOCK.click(bg.id, "Artillery on the nearest enemy in sight")
check("...then the guns are busy", (MOCK.lastGroupText(bg.id) or ""):find("busy", 1, true) ~= nil, MOCK.lastGroupText(bg.id))
B.ext.cooldown.blue.arty = nil
MOCK.groups.TEST_RED_T72.units[1].x = driver.x + 150
MOCK.click(bg.id, "Artillery on the nearest enemy in sight")
check("enemy 150 m away: danger close, no fire", (MOCK.lastGroupText(bg.id) or ""):find("Danger close", 1, true) ~= nil)
-- smoke screen ahead
local smokes, stops = {}, 0
trigger.action.effectSmokeBig = function(pt, preset, dens, name) smokes[#smokes + 1] = { pt = pt, name = name } end
trigger.action.effectSmokeStop = function() stops = stops + 1 end
driver.getPosition = function(self) return { x = { x = 0, y = 0, z = 1 }, p = self:getPoint() } end   -- heading east
local sSU = war.state.nodes[gnode].supply
MOCK.click(bg.id, "Smoke screen ahead")
check("smoke screen: 2 SU from the battery", math.abs(war.state.nodes[gnode].supply - (sSU - X.ground.smokeSU)) < 0.01)
MOCK.advance(40)
local allAhead = #smokes == X.ground.smokeRounds
for _, sm in ipairs(smokes) do
  if math.abs(sm.pt.z - (driver.z + X.ground.smokeAheadM)) > 1 or math.abs(sm.pt.x - driver.x) > X.ground.smokeWidthM / 2 + 1 then
    allAhead = false
  end
end
check("...5 smoke rounds in a curtain 500 m ahead, across the heading", allAhead, #smokes)
MOCK.click(bg.id, "Smoke screen ahead")
check("...own reload (artillery cooldown untouched)", (MOCK.lastGroupText(bg.id) or ""):find("reloading", 1, true) ~= nil)
MOCK.advance(X.ground.smokeMinutes * 60)
check("...the smoke clears after 3 min", stops == X.ground.smokeRounds)
driver.getPosition = nil

print(" AI smoke (v0.30)")
local ep2 = B.nodePos[enemy]
coalition.addGroup(80, Group.Category.GROUND, { name = "DCC_pSMK", units = {
  { name = "DCC_pSMK_1", type = "M-1 Abrams", x = ep2.x + 1500, y = ep2.z } } })
B.spawned.pSMK = { group = "DCC_pSMK", size = 1, base = 1, key = "m:mSMK", kind = "assault", mid = "mSMK" }
local tmpl = war.state.platoons[gpid]
war.state.platoons.pSMK = { id = "pSMK", side = "blue", role = tmpl.role, health = 1, xp = 0 }
war.state.moves.mSMK = { id = "mSMK", kind = "assault", side = "blue", from = gnode, to = enemy, status = "fighting",
                         platoons = { "pSMK" }, progress = 1, km = 10 }
B.liveNodes[enemy] = true
bat.node = enemy
war.state.nodes[enemy].supply = 50
local n0 = #smokes
B.aiSmokeTick()
MOCK.advance(40)
local between = #smokes - n0 == X.ground.smokeRounds
for i = n0 + 1, #smokes do
  local sm = smokes[i]
  if not (sm.pt.x > ep2.x and sm.pt.x < ep2.x + 1500) then between = false end
end
check("attack 1.5 km from the base: AI lays smoke between it and the base", between, #smokes - n0)
local n1 = #smokes
B.aiSmokeTick()
MOCK.advance(40)
check("...not again for 10 min", #smokes == n1)
war.state.moves.mSMK, B.spawned.pSMK, war.state.platoons.pSMK = nil, nil, nil
if MOCK.groups.DCC_pSMK then MOCK.groups.DCC_pSMK:destroy() end
MOCK.killGroup("TEST_RED_T72")
gp.mission = nil
MOCK.click(bg.id, "Artillery on my objective")
check("no ground mission: no objective to shell", (MOCK.lastGroupText(bg.id) or ""):find("ground mission first", 1, true) ~= nil)

print(" A day")
viper.air = false
for _ = 1, 288 do MOCK.advance(300) end
check("no script errors", errors == 0, errors)

print(string.format("\n%d passed, %d failed", passed, failed))
DCC_EXIT_CODE = failed == 0 and 0 or 1
