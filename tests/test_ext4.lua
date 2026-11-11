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
print("Pure model: harbour mines (v0.34)")
-- ===========================================================================
local hm = DCC.War.new(T, C, cfg, 43)
hm:tick()
local bport
for _, l in ipairs(hm:lanes()) do if hm.state.nodes[l.port].side == "blue" and not bport then bport = l.port end end
check("RED mines a BLUE port", hm:layMines("red", bport) and hm:isMined(bport))
check("...not twice, and never its own", not hm:layMines("red", bport))
hm.state.nodes[bport].supply = 1
hm.state.tick = X.mines.everyTicks * 0 + DCC.config.ext3.shipping.everyTicks * 40
hm:planShipping()
local toPort = false
for _, sh in pairs(hm.state.shipping) do if sh.port == bport then toPort = true end end
check("no supply ship sails for a mined port", not toPort)
hm.state.shipping.shX = { id = "shX", side = "blue", port = bport, su = 40, km = 50, progress = 0.9 }
hm:shippingTick()
check("a ship on the approach strikes a mine", hm.state.shipping.shX == nil and hm.state.sunkShips.shX ~= nil)
hm:missionsTick()
local sw
for _, m in pairs(hm.state.missions) do if m.type == "MINESWEEP" and m.target == bport then sw = m end end
check("BLUE gets a MINESWEEP (helicopters)", sw and sw.side == "blue" and sw.needs == "SWEEP")
hm:sweepSample(sw.id, 200)
check("200 s of sweeping: still mined", hm:isMined(bport))
hm:sweepSample(sw.id, 200)
check("5 min: harbour clear", not hm:isMined(bport) and hm:missionOutcome(sw, {}) == "done")
hm:layMines("red", bport)
hm.state.tick = hm.state.seaMines[bport].till
hm:harbourMinesTick()
check("unswept mines clear after 24 h", not hm:isMined(bport))
local laid = 0
for k = 1, 12 do
  hm.state.tick = X.mines.everyTicks * k
  hm:harbourMinesTick()
  for _ in pairs(hm.state.minelayers or {}) do laid = laid + 1 end
  hm.state.minelayers, hm.state.seaMines = {}, {}
end
check("the AI sends minelayers now and then", laid >= 2 and laid <= 20, laid)
print(" Minelayer ships (v0.35)")
hm.state.tick = 5
local mlid = hm:sendMinelayer("red", bport)
local ml = hm.state.minelayers[mlid]
check("RED minelayer sails for the BLUE port", ml and ml.progress == 0 and not ml.seen)
hm:missionsTick()
local mlm
for _, m in pairs(hm.state.missions) do if m.type == "MINELAYER" then mlm = m end end
check("...unseen: no mission yet", mlm == nil)
while not ml.seen do hm:minelayerTick() end
check("coastal radar picks it up at 30 %", ml.progress >= X.mines.detectAt and ml.progress < X.mines.strikeAt)
hm:missionsTick()
for _, m in pairs(hm.state.missions) do if m.type == "MINELAYER" and m.target == mlid then mlm = m end end
check("...BLUE gets a MINELAYER mission (sink it)", mlm and mlm.side == "blue" and mlm.needs == "A2G")
hm:minelayerSunk(mlid)
check("sunk: no mines, mission done", not hm:isMined(bport) and hm:missionOutcome(mlm, {}) == "done")
local ml2 = hm:sendMinelayer("red", bport)
for _ = 1, 200 do if hm.state.minelayers[ml2] then hm:minelayerTick() end end
check("not stopped: it lays the mines and heads home", hm:isMined(bport) and hm.state.minelayers[ml2] == nil)
hm:missionsTick()

-- ===========================================================================
print("Pure model: HQ (v0.38)")
-- ===========================================================================
local hq = DCC.War.new(T, C, cfg, 44)
check("each side has its HQ from the theater pack", hq:mainBase("blue") == "kutaisi" and hq:mainBase("red") == "krasnodar_c")
hq.state.nodes.kutaisi.side = "red"
check("HQ lost: the next own depot takes over", hq:mainBase("blue") == "batumi", hq:mainBase("blue"))
local allMain = true
for _, name in ipairs({ "Syria", "PersianGulf", "GermanyCW" }) do
  local th = DCC_THEATERS[name]
  local w9 = DCC.War.new(th, C, cfg, 45)
  for _, side in ipairs({ "blue", "red" }) do
    local id = w9:mainBase(side)
    if not (id and id == th.main[side] and w9.T.nodes[id].depot and w9.state.nodes[id].side == side) then allMain = false end
  end
end
check("every map: both HQs are own depots", allMain)

-- ===========================================================================
print("Pure model: FARPs from the start (v0.44)")
-- ===========================================================================
local fw = DCC.War.new(T, C, cfg, 46)
local towns, open = 0, 0
for _, id in ipairs(fw.T.order) do
  local ns = fw.state.nodes[id]
  if fw.T.nodes[id].kind == "town" and (ns.side == "blue" or ns.side == "red") then
    towns = towns + 1
    if fw:farpAt(id) and fw:farpStock(id) == cfg.world.farpStock and not fw:farpDry(id) then open = open + 1 end
  end
end
check("new war: every held town is a full FARP", towns > 0 and open == towns, open .. "/" .. towns)
check("airbases are not FARPs", not fw:farpAt("kutaisi"))
local old = fw.state
for _, ns in pairs(old.nodes) do ns.farp = nil end
old.farpsSeeded = nil
local rw = DCC.War.restore(T, C, cfg, old)
local reopened = 0
for _, id in ipairs(rw.T.order) do if rw:farpAt(id) then reopened = reopened + 1 end end
check("an older save gets its FARPs once", reopened == towns and rw.state.farpsSeeded == true)
local gone
for _, id in ipairs(rw.T.order) do if rw:farpAt(id) then gone = id; break end end
rw.state.nodes[gone].farp = nil
DCC.War.restore(T, C, cfg, rw.state)
check("...and only once (a FARP lost later stays lost)", rw.state.nodes[gone].farp == nil)

-- ===========================================================================
print("Pure model: air assault missions (v0.49)")
-- ===========================================================================
local aw = DCC.War.new(T, C, cfg, 47)
aw:tick()
local aaLimit = cfg.missions.perType.AIRASSAULT
cfg.missions.perType.AIRASSAULT = 99
aw:missionsTick()
cfg.missions.perType.AIRASSAULT = aaLimit
local aa, aaOk = nil, true
for _, m in pairs(aw.state.missions) do
  if m.type == "AIRASSAULT" then
    local ns = aw.state.nodes[m.target]
    if ns.side == m.side or aw.T.nodes[m.target].depot or #ns.platoons > cfg.ext5.airAssault.maxDefenders then aaOk = false end
    if m.side == "blue" and not aa then aa = m end
  end
end
check("AIRASSAULT on weak enemy bases (not depots), for transport helicopters", aa and aaOk and aa.needs == "LIFT", aa and aa.label)
check("...the board names where to load the troops", aa and aa.label:find("troops from", 1, true) ~= nil)
check("...still open while nobody landed", aa and aw:missionOutcome(aa, {}) == "open")
local srcNode = aa.base.from
local pid = aw.state.nodes[srcNode].platoons[1]
aw:carryPlatoon(pid, "k1")
aw:takeMission(aa.id, "k1", "Huey")
aw:dropPlatoons({ pid }, aa.target, "blue")
check("troops landed at the target: done", aw:missionOutcome(aa, {}) == "done")
local aa2
for _, m in pairs(aw.state.missions) do if m.type == "AIRASSAULT" and m ~= aa and m.side == "blue" then aa2 = m end end
if aa2 then
  aw.state.nodes[aa2.target].side = "blue"
  check("target taken some other way: expired", aw:missionOutcome(aa2, {}) == "expired")
end

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
                     "dcc_dcs_ext_air", "dcc_dcs_ext_ground", "dcc_dcs_ext2", "dcc_dcs_ext3", "dcc_dcs_ext4", "dcc_dcs_ext5",
                     "dcc_dcs_armoury", "dcc_dcs_admin", "dcc_dcs_srs", "dcc_dcs_stats", "dcc_dcs_slots", "dcc_main" }) do
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
B.groundUnitCount = function() return 650 end      -- v0.57: guard from 550 / 800 units (was 700 / 1000)
B.perfCheck(true)
check("650 units: level 1, smaller bubble", B.x4.perfLevel == 1 and cfg.liveRadiusKm < R0 and cfg.maxLivePlatoons < P0,
  cfg.liveRadiusKm .. " km / " .. cfg.maxLivePlatoons)
check("...and the server is told", (MOCK.texts[#MOCK.texts] or ""):find("Server busy", 1, true) ~= nil)
B.groundUnitCount = function() return 1200 end
B.perfCheck(true)
check("1200 units: level 2", B.x4.perfLevel == 2 and cfg.ground.skirmishMax < S0 and cfg.ext3.popup.max <= U0)
B.groundUnitCount = function() return 750 end
B.perfCheck(true)
check("750 (just below): stays at level 2 (no flicker)", B.x4.perfLevel == 2)
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
local realMoveNear = B.moveNear
B.moveNear = function() return true end             -- v0.57: columns are only spawned near players; here: always
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
print(" Defender smoke (v0.32)")
-- RED at `enemy` sees the BLUE attack's lead tank 1.5 km out
war.state.nodes[enemy].platoons = (#war.state.nodes[enemy].platoons > 0) and war.state.nodes[enemy].platoons
  or { gpid }
B.x4.defSmoke = {}
local smkPilot = MOCK.spawnPlayer(BLUE, "UH-1H", ep2.x + 6000, ep2.z, "Spotter", true)   -- v0.57: live bubble is 25 km
B.liveNodes[enemy] = true
local d0 = #smokes
B.defenseSmokeTick()
MOCK.advance(40)
local toward = #smokes - d0 == X.ground.smokeRounds
for i = d0 + 1, #smokes do
  local sm = smokes[i]
  if not (sm.pt.x > ep2.x and sm.pt.x <= ep2.x + X.aiSmoke.defendOffsetM + 1) then toward = false end
end
check("attack 1.5 km out: the garrison screens itself toward it", toward, #smokes - d0)
smkPilot.alive = false
B.moveNear = realMoveNear
local d1 = #smokes
B.defenseSmokeTick()
MOCK.advance(40)
check("...once per 10 min", #smokes == d1)
war.state.moves.mSMK, B.spawned.pSMK, war.state.platoons.pSMK = nil, nil, nil
if MOCK.groups.DCC_pSMK then MOCK.groups.DCC_pSMK:destroy() end
-- a low RED jet over BLUE's base
local gpos = B.nodePos[gnode]
local su25 = MOCK.spawnPlayer(RED, "Su-25T", gpos.x, gpos.z + 20000, "Ivan")   -- (away from the slot guard)
su25.air, su25.alt, su25.z = true, 400, gpos.z + 4500
local function jetSmoke()
  B.x4.defSmoke = {}
  local n = #smokes
  B.defenseSmokeTick()
  MOCK.advance(40)
  local ok2 = #smokes - n == X.ground.smokeRounds
  for i = n + 1, #smokes do if not (smokes[i].pt.z > gpos.z) then ok2 = false end end
  return ok2, #smokes - n
end
B.x4.shots = {}
local r, n = jetSmoke()
check("low enemy jet just passing: no smoke", n == 0, n)
MOCK.fire({ id = world.event.S_EVENT_SHOT, initiator = su25 })
r, n = jetSmoke()
check("...it fires: smoke between it and the base", r, n)
B.x4.shots = {}
su25.getVelocity = function() return { x = 0, y = -30, z = -150 } end    -- diving at the base
r, n = jetSmoke()
check("...diving at the base: smoke", r, n)
su25.getVelocity = function() return { x = 150, y = -30, z = 0 } end     -- diving, but at something else
r, n = jetSmoke()
check("...diving away from the base: no smoke", n == 0, n)
su25.getVelocity = function() return { x = 0, y = -30, z = -150 } end
su25.alt = 6000
r, n = jetSmoke()
check("...not for a jet at 6000 m", n == 0, n)
su25.getVelocity = nil
su25.alive = false
MOCK.killGroup("TEST_RED_T72")
gp.mission = nil
MOCK.click(bg.id, "Artillery on my objective")
check("no ground mission: no objective to shell", (MOCK.lastGroupText(bg.id) or ""):find("ground mission first", 1, true) ~= nil)

print(" Bogey dope (v0.34)")
viper.x, viper.z, viper.air = kp.x, kp.z, false
B.airContacts.blue = { RED_MIG = { pos = { x = kp.x, z = kp.z + 20 * 1852 }, alt = 6096, type = "MiG-29S",
                                   t = timer.getTime() } }
check("Support menu: Bogey dope", MOCK.click(vg.id, "Bogey dope"))
local bd = MOCK.lastGroupText(vg.id) or ""
check("...BRAA to the nearest contact", bd:find("BRAA 090 / 20 nm / 20000 ft", 1, true) ~= nil, bd)
B.airContacts.blue.RED_MIG.t = timer.getTime() - 300
MOCK.click(vg.id, "Bogey dope")
check("...an old contact does not count: clean", (MOCK.lastGroupText(vg.id) or ""):find("clean", 1, true) ~= nil)
B.airContacts.blue = {}

print(" SRS voice (v0.50)")
DCC.srsQueue = {}
B.airContacts.blue = { RED_MIG = { pos = { x = kp.x, z = kp.z + 20 * 1852 }, alt = 6096, type = "MiG-29S",
                                   t = timer.getTime() } }
MOCK.click(vg.id, "Bogey dope")
local sq = DCC.srsQueue[#DCC.srsQueue]
check("bogey dope also spoken on the AWACS frequency", sq and sq.freq == cfg.srs.freqs.awacs.blue and sq.coal == 2
  and sq.text:find("Morten, Overlord, bra 0 9 0, 20, 20 thousand", 1, true) ~= nil, sq and sq.text)
check("...and still shown as text", (MOCK.lastGroupText(vg.id) or ""):find("BRAA 090", 1, true) ~= nil)
B.airContacts.blue = {}
DCC.srsQueue = {}
B.announce({ { kind = "capture", side = "red", text = "RED captured Gori - BLUE pushed back", node = "gori" },
             { kind = "nosupply", side = "blue", text = "Zugdidi is out of supply" },
             { kind = "convoy_lost", side = "red", text = "not spoken" } })
local cmdB, cmdR, own = 0, 0, false
for _, m in ipairs(DCC.srsQueue) do
  if m.freq == cfg.srs.freqs.command.blue and m.coal == 2 then cmdB = cmdB + 1 end
  if m.coal == 1 then cmdR = cmdR + 1 end
  if m.text:find("out of supply", 1, true) then own = m.coal == 2 end
  if m.text:find("not spoken", 1, true) then cmdB = 99 end
end
check("command net: a capture for both sides, own news for own side only", cmdB == 2 and cmdR == 1 and own, cmdB .. "/" .. cmdR)
DCC.srsQueue = {}
local info = B.airfieldInfo("kutaisi")
check("airfield information: name, runway and stock", info and info:find("^Kutaisi information") and info:find("runway open", 1, true)
  and info:find("aircraft of %d+ types in stock") ~= nil, info)
check("v0.56: ...wind and QNH (DCS gives temperature and pressure as two numbers)", info and info:find("wind 3 6 0 at 8", 1, true)
  and info:find("temperature 15, QNH 1013", 1, true) ~= nil, info)
viper.x, viper.z, viper.air = kp.x + 200, kp.z, false
B.srsInfoAt = {}
B.srsInfoTick()
B.srsInfoTick()
local infos = 0
for _, m in ipairs(DCC.srsQueue) do if m.freq == cfg.srs.freqs.info.blue and m.text:find("Kutaisi information", 1, true) then infos = infos + 1 end end
check("...broadcast when a player sits at the base, once per 15 min", infos == 1, infos)
local js = DCC.srsPop()
check("the hook collects the queue as JSON, then it is empty", js:sub(1, 1) == "[" and #DCC.srsQueue == 0 and DCC.srsPop() == "")
for i = 1, 30 do B.srsSay("blue", "command", "line " .. i) end
check("no hook collecting: only the newest lines are kept", #DCC.srsQueue == cfg.srs.maxQueue
  and DCC.srsQueue[#DCC.srsQueue].text == "line 30")
DCC.srsQueue = {}

print(" Sortie debrief (v0.34)")
p.debrief = nil
viper.air = true
MOCK.fire({ id = world.event.S_EVENT_TAKEOFF, initiator = viper })
DCC.pilots:add(p.key, "kills_air", 2, p.name)
B.onMissionDone({ id = "xdeb", type = "CAS", label = "defend Senaki", taken = { [p.key] = p.name } }, "done")
viper.air = false
MOCK.fire({ id = world.event.S_EVENT_LAND, initiator = viper })
local deb = ""
for _, t in ipairs(MOCK.groupTexts[vg.id] or {}) do if t:find("DEBRIEF", 1, true) then deb = t end end
check("landed at home: debrief", deb ~= "", deb)
check("...kills", deb:find("Kills: 2 air", 1, true) ~= nil, deb)
check("...missions and their effect", deb:find("CAS defend Senaki: COMPLETE - the battle went our way", 1, true) ~= nil)
check("...points", deb:find("Points: +", 1, true) ~= nil)
local rs = (DCC.pilots.data.pilots[p.key].recent or {})[1]
check("v0.51: the sortie is kept in the pilot record", rs and rs.type == "F-16C_50" and rs.kills == 2
  and rs.killsText == "2 air" and rs.missions == 1 and rs.points > 0 and rs.map == "Caucasus" and rs.n >= 1)
for i = 1, 30 do DCC.pilots:get("k" .. i, "Pilot " .. i) end
local pub = B.publicState()
local me
for _, pp in ipairs(pub.pilots) do if pp.name == p.name then me = pp end end
check("public.json: more than 20 pilots, with totals and last sorties", #pub.pilots > 20 and me and me.kills >= 2
  and me.recent[1] and me.recent[1].type == "F-16C_50" and me.hours ~= nil)
check("...and the latest sorties of everyone", pub.sorties[1] and pub.sorties[1].name == p.name)
for i = 1, 8 do p.debrief = { t = timer.getTime(), score = 0, rank = "x", kills = {}, missions = {} }; B.recordSortie(p) end
check("...a pilot keeps his last 5", #DCC.pilots.data.pilots[p.key].recent == cfg.public.sortiesPerPilot)
p.debrief = nil

print(" Mine sweeping (v0.34)")
local sport
for _, l in ipairs(war:lanes()) do if war.state.nodes[l.port].side == "blue" and not sport then sport = l.port end end
war.state.seaMines = {}
war:layMines("red", sport)
war:missionsTick()
local swm
for _, m in pairs(war.state.missions) do if m.type == "MINESWEEP" and m.target == sport then swm = m end end
check("bridge: MINESWEEP on the board", swm ~= nil)
check("...not for a jet", not B.canFly(p, swm))
local c0 = MOCK.countMarks("circle")
B.drawMines()
check("...the mined harbour is on the map", MOCK.countMarks("circle") == c0 + 1)
local huey, hg = MOCK.spawnPlayer(BLUE, "UH-1H", kp.x + 300, kp.z, "Sweeper", true)
local hp = B.players[huey:getName()]
check("...a Huey can take it", B.canFly(hp, swm))
B.takeMission({ unit = huey:getName(), mid = swm.id })
local hpos = B.harbourPos(sport)
huey.x, huey.z, huey.alt, huey.air = hpos.x + 1000, hpos.z, 60, true
B.x4.sweepAt = timer.getTime() - 400
B.sweepTick()
check("low over the harbour 5 min: swept", not war:isMined(sport))
war:missionsTick()
check("...mission complete", war.state.missions[swm.id].status == "done")
B.drawMines()
check("...and off the map", MOCK.countMarks("circle") == c0)
huey.alive = false

print(" Minelayer ships (v0.35)")
war.state.seaMines = {}
local mA = war:sendMinelayer("red", sport)
viper.x, viper.z = kp.x, kp.z
B.reconcileMinelayers()
check("the minelayer is a real ship: Vasily Bykov", B.x4.layers[mA] and B.x4.layers[mA].type == "CHAP_Project22160")
local rawAdd = coalition.addGroup
coalition.addGroup = function(c, cat, data)
  if data.units[1].type == "CHAP_Project22160" then error("unknown type") end
  return rawAdd(c, cat, data)
end
war.state.minelayers[mA] = nil
B.reconcileMinelayers()
local mB = war:sendMinelayer("red", sport)
B.reconcileMinelayers()
coalition.addGroup = rawAdd
check("...server without the mod: falls back to a core ship", B.x4.layers[mB] and B.x4.layers[mB].type == "MOLNIYA",
  B.x4.layers[mB] and B.x4.layers[mB].type)
local lp = B.minelayerPos(war.state.minelayers[mB])
viper.x, viper.z, viper.air = lp.x + 10000, lp.z, true
B.reconcileMinelayers()
check("a BLUE pilot 10 km away spots it", war.state.minelayers[mB].seen)
war:missionsTick()
local hunt
for _, m in pairs(war.state.missions) do if m.type == "MINELAYER" and m.target == mB then hunt = m end end
check("...MINELAYER on BLUE's board, at the ship", hunt and B.missionPos(hunt) ~= nil)
MOCK.killGroup(B.x4.layers[mB].group)
B.reconcileMinelayers()
check("sunk in DCS: sunk in the war, no mines", war.state.minelayers[mB] == nil and not war:isMined(sport))
viper.air = false

print(" HQ on the map (v0.38)")
B.draw()
local hqBlue, hqRed = false, false
for _, id in ipairs(B.marks) do
  local mk = MOCK.marks[id]
  local txt = mk and mk.kind == "text" and tostring(mk.args[#mk.args]) or ""
  if txt:find("BLUE HQ - " .. war:nodeName(war:mainBase("blue")), 1, true) and mk.coal == -1 then hqBlue = true end
  if txt:find("RED HQ - ", 1, true) and mk.coal == -1 then hqRed = true end
end
check("both HQs starred on everyone's map", hqBlue and hqRed)
local st = table.concat(B.opsStatusLines("blue"), "\n")
check("Campaign status names the HQs", st:find("HQ: ", 1, true) ~= nil, st:sub(1, 80))

print(" Air assault gunship escort (v0.49)")
local am = { id = "mAA1", type = "AIRASSAULT", side = "blue", status = "open", target = nil, taken = {}, needs = "LIFT" }
for _, id in ipairs(war.T.order) do
  if war.state.nodes[id].side == "red" and not war.T.nodes[id].depot then am.target = id; break end
end
war.state.missions[am.id] = am
local tp5 = B.nodePos[am.target]
local hu5, hg5 = MOCK.spawnPlayer(BLUE, "UH-60L", kp.x + 400, kp.z, "Lift", true)
local p5 = B.players[hu5:getName()]
p5.mission = am.id
hu5.air = false
B.opsPoll()
check("on the ground: no gunships yet", B.x5.escorts[am.id] == nil)
local poolBefore = war.state.airPool.blue.attack
hu5.air = true
B.opsPoll()
local gsName = B.x5.escorts[am.id]
local gs = gsName and MOCK.groups[gsName]
check("taker airborne: an AI gunship pair launches", gs ~= nil and #gs.units == 2 and gs.units[1].type == "AH-64D_BLK_II", gsName)
check("...as helicopters, low, toward the target", gs and gs.category == Group.Category.HELICOPTER and #gs.route == 3
  and gs.route[3].x == tp5.x and gs.route[3].alt == cfg.ext5.airAssault.altM and gs.route[3].alt_type == "RADIO")
check("...paid from the attack pool", war.state.airPool.blue.attack == poolBefore - 2)
B.opsPoll()
local nGs = 0
for name in pairs(MOCK.groups) do if name:find("^DCC_GUNSHIP_") then nGs = nGs + 1 end end
check("...only one pair per mission", nGs == 1)
local apache = MOCK.spawnPlayer(BLUE, "AH-64D_BLK_II", kp.x + 600, kp.z, "Gunner", true)
local pa = B.players[apache:getName()]
check("v0.55: no BRIDGE missions for helicopters, but other attack missions", pa and pa.heli
  and not B.canFly(pa, { type = "BRIDGE", needs = "A2G" }) and B.canFly(pa, { type = "ARTY", needs = "A2G" })
  and B.canFly(p, { type = "BRIDGE", needs = "A2G" }), pa and tostring(pa.heli))
p5.mission = nil
war.state.missions[am.id] = nil

print(" Fire control: AI ground fights only near players (v0.56)")
-- beta 3 Nov: AI shooting at AI caused massive desync
local fcNode
for _, id in ipairs(war.T.order) do if war.state.nodes[id].side == "red" and B.nodePos[id] then fcNode = id; break end end
local fp = B.nodePos[fcNode]
coalition.addGroup(81, Group.Category.GROUND, { name = "DCC_p9901", units = { { name = "DCC_p9901_1", type = "T-72B",
  x = fp.x, y = fp.z } } })
coalition.addGroup(81, Group.Category.GROUND, { name = "DCC_PICK_test", units = { { name = "DCC_PICK_test_1",
  type = "Soldier AK", x = fp.x, y = fp.z } } })
local fcHeli = MOCK.spawnPlayer(BLUE, "UH-1H", fp.x + 40000, fp.z, "Far", true)
B.fireControlTick()
local ROE = AI.Option.Ground.id.ROE
local gp = MOCK.groups["DCC_p9901"]
check("no player within 15 km: campaign platoons hold fire", gp.options and gp.options[ROE] == AI.Option.Ground.val.ROE.WEAPON_HOLD)
check("...and the battle there is fought on the dice", not war:isNodeLive(fcNode) or not B.x5.fireNodes[fcNode])
check("...groups that are not campaign fighters are left alone", not (MOCK.groups["DCC_PICK_test"].options or {})[ROE])
fcHeli.x = fp.x + 8000
B.fireControlTick()
check("a player within 15 km: they open fire", gp.options[ROE] == AI.Option.Ground.val.ROE.OPEN_FIRE)
check("...and DCS fights that battle (when the node is live)", B.x5.fireNodes[fcNode] == true
  and (war:isNodeLive(fcNode) == (B.liveNodes[fcNode] == true)))

print(" Idle AI off and convoys near players only (v0.57)")
fcHeli.x = fp.x + 60000
B.idleTick(B.playerPositions())
check("no player within 50 km: a standing platoon's AI is off", gp.aiOn == false)
check("...other groups (pickups) are not touched", MOCK.groups["DCC_PICK_test"].aiOn == nil)
fcHeli.x = fp.x + 30000
B.idleTick(B.playerPositions())
check("a player within 50 km: AI back on", gp.aiOn == true)
local cvA, cvB
for _, id in ipairs(war.T.order) do
  if war.state.nodes[id].side == "blue" and B.nodePos[id] then
    if not cvA then cvA = id elseif not cvB then cvB = id end
  end
end
local mvC = { id = "mvx1", kind = "convoy", side = "blue", from = cvA, to = cvB, progress = 0.5, km = 50, platoons = {},
              status = "moving", cargo = true, supply = 10 }
local mp = B.movePos(mvC)
local realPP = B.playerPositions
B.playerPositions = function() return { fcHeli:getPoint() } end   -- only this pilot counts here
fcHeli.x, fcHeli.z = mp.x + 30000, mp.z
check("a convoy 30 km from any player is not spawned (dice)", not B.moveNear(mvC) and not war:isMoveLive(mvC))
fcHeli.x = mp.x + 15000
check("...within 20 km it is", B.moveNear(mvC))
fcHeli.x = mp.x + 23000
check("...and stays until 25 km (no flicker)", B.moveNear(mvC))
fcHeli.x = mp.x + 27000
check("...then goes back to the dice", not B.moveNear(mvC))
B.forced = B.forced or {}
B.forced[mvC.id] = true
check("a convoy on a taken escort mission is always real", B.moveNear(mvC))
B.forced[mvC.id] = nil
B.playerPositions = realPP
check("v0.57 settings: live bubble 25 km, 60 platoons, guard at 550 units, 100 wrecks, flares every 5 min",
  DCC.config.liveRadiusKm == 25 and DCC.config.maxLivePlatoons == 60 and DCC.config.ext4.perf.levels[1].units == 550
  and DCC.config.ext.wrecks.max == 100 and DCC.config.ext3.illum.everySec == 300 and DCC.config.ext3.illum.callEverySec == 300)
fcHeli.alive = false
gp.exists = false
MOCK.groups["DCC_PICK_test"].exists = false

print(" Self-check and Where can I spawn? (v0.47)")
env.mission.forcedOptions = { unrestrictedSATNAV = true }
local scl, scw = B.selfCheck()
local sct = table.concat(scl, "\n")
check("self-check: airbases, HQ stock, GPS and templates OK", sct:find("OK   all %d+ airbases found") ~= nil
  and sct:find("OK   BLUE HQ Kutaisi", 1, true) ~= nil and sct:find("OK   GPS on", 1, true) ~= nil
  and sct:find("OK   AI templates found", 1, true) ~= nil, sct)
check("...this test has no FARP pads and no hook: both warned", sct:find("WARN %d+ of %d+ FARP pads missing") ~= nil
  and sct:find("WARN server hook not seen", 1, true) ~= nil and scw >= 2, scw)
env.mission.forcedOptions = { unrestrictedSATNAV = false }
env.mission.coalitions = { blue = { 80 } }
check("...no GPS: warned (F-16 datalink)", table.concat((B.selfCheck()), "\n"):find("WARN no GPS", 1, true) ~= nil)
env.mission.forcedOptions, env.mission.coalitions = nil, nil
DCC_HOOK_VERSION = "0.47"
local nt = #MOCK.texts
B.runSelfCheck()
check("runSelfCheck: warnings on screen, hook now OK", #MOCK.texts > nt and MOCK.texts[#MOCK.texts]:find("self-check", 1, true)
  and not MOCK.texts[#MOCK.texts]:find("server hook", 1, true))
DCC_HOOK_VERSION = nil
local sl = B.spawnLines("blue")
war.state.nodes.kutaisi.air["F-16C_50"] = 2
war.state.nodes.kutaisi.air["FA-18C_hornet"] = 0
sl = B.spawnLines("blue")
check("Where can I spawn?: HQ first; type count, low and out of stock", sl[1] and sl[1]:find("(HQ)", 1, true) ~= nil
  and sl[1]:find("%d+ types, %d+ aircraft") ~= nil and sl[1]:find("low: F-16C_50 2", 1, true) ~= nil
  and sl[1]:find("OUT: FA-18C_hornet", 1, true) ~= nil, sl[1])
local hl = B.spawnLines("blue", true)
check("...helicopters: open FARPs with their pads and types", hl[1] and hl[1]:find("^FARP ") ~= nil
  and hl[1]:find("2 pads, 10 of each", 1, true) ~= nil and hl[1]:find("UH-1H", 1, true) ~= nil, hl[1])
local spawnMenu = false
for _, it in ipairs(MOCK.menus) do if it.name == "Where can I spawn?" then spawnMenu = true end end
check("...in F10 > Campaign", spawnMenu)

print(" Player slots (v0.58)")
-- a fake server player list (net is only there on a server)
local seats, forced = {}, {}
local function seat(pid, name, slot) seats[pid] = { id = pid, name = name, ucid = "ucid-" .. name, slot = slot } end
net = {
  get_player_list = function() local l = {}; for pid in pairs(seats) do l[#l + 1] = pid end; table.sort(l); return l end,
  get_player_info = function(pid) return seats[pid] end,
  send_chat_to = function() end,
  force_player_slot = function(pid, side, slot)
    forced[#forced + 1] = pid
    if MOCK.forceWorks then
      for _, g in pairs(MOCK.groups) do
        for _, u in ipairs(g.units) do if u.player == seats[pid].name then u.player = nil end end
      end
      seats[pid].slot = ""
    end
    return true
  end,
}
local function aircraft(gname, typeName, x, z, uid, heli)
  MOCK.nextGroupId = MOCK.nextGroupId + 1
  local g = setmetatable({ name = gname, exists = true, units = {}, route = {}, player = true,
                          category = heli and 1 or 0, id = MOCK.nextGroupId }, MOCK.GroupMT)
  local u = setmetatable({ name = gname .. "-1", type = typeName, x = x, z = z, alt = 0, alive = true, coal = BLUE,
                           group = g, air = false, id = uid }, MOCK.UnitMT)
  g.units[1] = u
  MOCK.groups[gname] = g
  return u, g
end
-- 1. a dynamic spawn whose birth comes before the player is in the aircraft
seat(11, "Rode", "5001")
local dyn, dg = aircraft("Kutaisi_F-16CM bl.50_1", "F-16C_50", kp.x + 800, kp.z, 5001)
MOCK.fire({ id = world.event.S_EVENT_BIRTH, initiator = dyn })
check("dynamic spawn: birth without a player name - not registered", B.players[dyn.name] == nil)
dyn.player = "Rode"
table.insert(MOCK.players[BLUE], dyn)
MOCK.fire({ id = world.event.S_EVENT_PLAYER_ENTER_UNIT, initiator = dyn })
check("...registered when he enters the aircraft: Missions menu", B.players[dyn.name] ~= nil
  and #MOCK.menuItems(dg.id) > 0)
check("...under his server key (UCID)", B.players[dyn.name] and B.players[dyn.name].key == "ucid-Rode")
-- 2. the sweep: a player DCS has in an aircraft but the campaign lost
B.clearPlayer(dyn.name, "left")
MOCK.advance(31)
check("sweep: a player in an aircraft the campaign lost gets his menus back", B.players[dyn.name] ~= nil
  and #MOCK.menuItems(dg.id) > 0)
dyn.alive = false
MOCK.advance(31)
check("sweep: a departed player is forgotten", B.players[dyn.name] == nil)
-- 3. a player who may not fly here is sent to spectators, not destroyed (a destroyed dynamic spawn = ghost)
MOCK.forceWorks = true
seat(12, "Ghost", "5002")
local gh = aircraft("Enemy_F-16CM_1", "F-16C_50", ep.x + 300, ep.z, 5002)
gh.player = "Ghost"
table.insert(MOCK.players[BLUE], gh)
MOCK.fire({ id = world.event.S_EVENT_BIRTH, initiator = gh })
check("slot guard: player sent to spectators", forced[#forced] == 12, #forced)
check("...the aircraft is not destroyed under him", gh.alive and not gh.destroyed)
check("...and not picked up again by the sweep", (function() MOCK.advance(31); return B.players[gh.name] == nil end)())
MOCK.forceWorks = false
seat(13, "Stuck", "5003")
local st = aircraft("Enemy_F-16CM_2", "F-16C_50", ep.x + 600, ep.z, 5003)
st.player = "Stuck"
MOCK.fire({ id = world.event.S_EVENT_BIRTH, initiator = st })
check("...still in it after slots.removeCheckSec: the aircraft goes", (function()
  local before = st.alive
  MOCK.advance(DCC.config.slots.removeCheckSec + 1)
  return before and st.destroyed == true end)())
-- 4. grounded after two losses: the deaths are found under the server key
seat(14, "Twice", "5004")
B.recordDeath("ucid-Twice"); B.recordDeath("ucid-Twice")
local tw = aircraft("Kutaisi_FA-18_1", "FA-18C_hornet", kp.x + 900, kp.z, 5004)
tw.player = "Twice"
local nf = #forced
MOCK.fire({ id = world.event.S_EVENT_BIRTH, initiator = tw })
check("two losses within the hour: grounded in multiplayer too", #forced == nf + 1 and forced[#forced] == 14, #forced)
-- 5. multicrew: a crew member changing seats does not take the pilot's menus and mission
seat(15, "Rhino", "5005")
seat(16, "Rook", "5005_2")
local herc, hg2 = aircraft("Kutaisi_C-130J-30_1", "C-130J-30", kp.x + 1200, kp.z, 5005)
herc.player = "Rhino"
table.insert(MOCK.players[BLUE], herc)
MOCK.fire({ id = world.event.S_EVENT_BIRTH, initiator = herc })
local hp = B.players[herc.name]
seats[16].slot = "5005_3"
MOCK.fire({ id = world.event.S_EVENT_PLAYER_LEAVE_UNIT, initiator = herc })
MOCK.advance(2)
check("crew seat change: the pilot keeps his record and menus", hp ~= nil and B.players[herc.name] == hp
  and #MOCK.menuItems(hg2.id) > 0)
seats[15].slot, seats[16].slot, herc.player = "", "", nil
MOCK.fire({ id = world.event.S_EVENT_PLAYER_LEAVE_UNIT, initiator = herc })
MOCK.advance(2)
check("...everyone out: the aircraft is forgotten", B.players[herc.name] == nil)
-- 6. ejecting on the ground at an own base is leaving the slot, not a downed pilot
seat(17, "Eject", "5006")
local ej = aircraft("Kutaisi_F-16CM bl.50_9", "F-16C_50", kp.x + 400, kp.z, 5006)
ej.player = "Eject"
MOCK.fire({ id = world.event.S_EVENT_BIRTH, initiator = ej })
local nd = 0
for _ in pairs(war.state.downed) do nd = nd + 1 end
MOCK.fire({ id = world.event.S_EVENT_EJECTION, initiator = ej })
local nd2 = 0
for _ in pairs(war.state.downed) do nd2 = nd2 + 1 end
check("ejection on the ground at an own base: no downed pilot / CSAR", nd2 == nd, nd2 - nd)
net, MOCK.forceWorks = nil, nil

print(" A day")
viper.air = false
for _ = 1, 288 do MOCK.advance(300) end
check("no script errors", errors == 0, errors)

print(string.format("\n%d passed, %d failed", passed, failed))
DCC_EXIT_CODE = failed == 0 and 0 or 1
