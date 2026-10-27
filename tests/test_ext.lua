-- ============================================================================
-- Tests: armoury, runways, mobile SAMs, aircrews and prisoners, support on
-- call, minefields, veterancy, industry, partisans, scaling, ranks, wrecks.
--   python tools/run_lua.py tests/test_ext.lua
-- ============================================================================

local passed, failed = 0, 0
local function check(name, cond, detail)
  if cond then passed = passed + 1; print("  ok   " .. name)
  else failed = failed + 1; print("  FAIL " .. name .. (detail and (" - " .. tostring(detail)) or "")) end
end

local T, C, cfg = DCC_THEATERS.Caucasus, DCC_CATALOGS.modern, DCC.config
local X = cfg.ext

-- ===========================================================================
print("War model")
-- ===========================================================================
check("v0.37: by default every tier is on the shelf whatever the supply", cfg.ext.armoury.tiers == false)
cfg.ext.armoury.tiers = true          -- this suite tests the supply tiers (and the take-off mode) themselves
local w = DCC.War.new(T, C, cfg, 11)
w:tick()

-- armoury
local ns = w.state.nodes.kutaisi
local cap = w:supplyCap("kutaisi")
ns.supply = cap * 0.1
check("dry base: basic weapons only", w:armouryTier("kutaisi") == "basic")
ns.supply = cap * 0.3
check("some supply: guided weapons", w:armouryTier("kutaisi") == "guided")
ns.supply = cap * 0.9
check("well supplied: everything", w:armouryTier("kutaisi") == "advanced")
local s0 = ns.supply
local okArm, _, cost = w:armTakeoff("kutaisi", 2, 4)
local AC = cfg.ext.armoury
check("advanced weapons are paid for (2 guided + 4 advanced)", okArm and math.abs(cost - (2 * AC.guidedSU + 4 * AC.advancedSU)) < 0.01
  and math.abs(ns.supply - (s0 - cost)) < 0.01, cost)
ns.supply = cap * 0.1
check("a dry base refuses an AMRAAM loadout", w:armTakeoff("kutaisi", 0, 2) == false)
check("...but guns and rockets are always fine", w:armTakeoff("kutaisi", 0, 0) == true)

-- runways
local rid = "sochi"
for _ = 1, X.runwayHits - 1 do w:runwayHit(rid) end
check("two hits do not close a runway", not w:runwayClosed(rid))
w:runwayHit(rid)
check("the third closes it", w:runwayClosed(rid))
w.state.nodes[rid].supply = 100
check("no airlifts into a closed airfield", w:startCargo("airlift", "red", "maykop", rid, 20) == nil)
local rm
for _, m in ipairs(w.missionGenerators.RUNWAY(w, "blue")) do if m.target == rid then rm = m end end
check("closed: no RUNWAY mission on it", rm == nil)
for _ = 1, X.runwayTicks do w.state.tick = w.state.tick + 1; w:runwaysTick() end
check("repaired after 4 h, for supply", not w:runwayClosed(rid) and w.state.nodes[rid].supply < 100)

-- SAM moved
local samNode
for _, id in ipairs(w.T.order) do if w.state.nodes[id].side == "red" and w.state.nodes[id].sam then samNode = id; break end end
w:addContact("blue", "sam:" .. samNode, { kind = "sam", node = samNode, err = 300 })
w:samMoved(samNode, 2000, 1500, "site")
check("a site that moved: the enemy's fix is off by the distance", w:contact("blue", "sam:" .. samNode).err >= 2500)
check("...and it respawns where it went", w.state.nodes[samNode].sam.off.dx == 2000)

-- aircrews
local did = w:addDowned("red", { x = 0, z = 0 }, "Su-25 crew", "Su-25T", "maykop", nil)
w.state.downed[did].aiRole = "attack"
local pool = w.state.airPool.red.attack
w:rescue(did, "maykop")
check("AI crew rescued: aircraft back in the pool", w.state.airPool.red.attack == pool + 1)
local d2 = w:addDowned("red", { x = 0, z = 0 }, "Ivan", "Su-25T", "maykop", "ivan")
local sm
w:missionsTick()
for _, m in ipairs(w:openMissions("blue")) do if m.type == "SNATCH" and m.target == d2 then sm = m end end
check("enemy pilot down: BLUE gets SNATCH", sm ~= nil and sm.needs == "LIFT")
check("snatched: prisoner, captors learn about his base", w:snatch(d2, "blue", "kutaisi") and
  w.state.intel.blue.maykop ~= nil)
w:missionsTick()
check("SNATCH done", sm and w.state.missions[sm.id].status == "done")

-- engineers
w:bridgeDown("kutaisi", "zestaponi")
check("bridge down: road closed", w:roadClosed("kutaisi", "zestaponi"))
w:repairBridge("kutaisi", "zestaponi", "blue")
check("engineers reopen it", not w:roadClosed("kutaisi", "zestaponi") and w.T.nodes.kutaisi.nb.zestaponi ~= nil)

-- minefields
local mv = { id = "mt", kind = "convoy", side = "red", from = "zugdidi", to = "senaki", cargo = 50, health = 1,
             platoons = {}, progress = 0.5, km = 30, status = "moving" }
w.state.moves.mt = mv
local fBefore = w:moveSpeedFactor(mv)
w:mineRoad("zugdidi", "senaki", "blue")
check("a mined road slows the other side", math.abs(w:moveSpeedFactor(mv) - fBefore * X.mineSpeed) < 0.001)
mv.side = "blue"
check("...not the side that laid it", math.abs(w:moveSpeedFactor(mv) - fBefore) < 0.001)
mv.side = "red"
w:minesTick()
check("a column crossing it takes losses", mv.health < 1 and mv.mineHit)
w.state.moves.mt = nil

-- veterancy
local pid = w.state.nodes.kutaisi.platoons[1]
local pl = w.state.platoons[pid]
pl.health = 1
local p0 = w:power({ pid })
pl.xp = X.veterancy.vetXp
check("veteran platoon fights 10 % harder", math.abs(w:power({ pid }) - p0 * 1.1) < 1e-6)
pl.xp = X.veterancy.eliteXp
check("elite platoon 20 %", math.abs(w:power({ pid }) - p0 * 1.2) < 1e-6)

-- industry
local sites = w:industrySites("red")
check("three industry sites per side, behind the lines", #sites == 3 and #w:industrySites("blue") == 3)
local f0 = w:industryFactor("red")
local im
w:missionsTick()
for _, m in ipairs(w:openMissions("blue")) do if m.type == "INDUSTRY" then im = m end end
check("INDUSTRY mission on the board", im ~= nil)
w:industryHit(sites[1].id)
check("one site down: production -12 %", math.abs(w:industryFactor("red") - (f0 - X.industryFactor)) < 1e-6)
w:missionsTick()
local done = false
for _, m in pairs(w.state.missions) do if m.type == "INDUSTRY" and m.target == sites[1].id and m.status == "done" then done = true end end
check("INDUSTRY done", done)
local base = sites[1].node
w.state.nodes[base].supply = 500
for _ = 1, X.industryRebuildTicks do w.state.tick = w.state.tick + 1 end
w:industryTick()
check("rebuilt after a day, for supply", sites[1].status == "up" and w.state.nodes[base].supply < 500)

-- scaling
w:setPlayers(4, 1)
check("RED outnumbered by 3 players: takes 15 % fewer losses", math.abs(w:scaleBonus("red") - 0.15) < 1e-9
  and w:scaleBonus("blue") == 0)
local rp = w.state.nodes.sochi.platoons[1]
w.state.platoons[rp].health = 1
w:damage({ rp }, 0.5)
check("...in the battle dice", math.abs(w.state.platoons[rp].health - (1 - 0.5 * 0.85)) < 1e-6)
w:setPlayers(0, 0)

-- wrecks
for i = 1, X.wrecks.max + 5 do w:addWreck({ type = "T-72B", x = i, z = i }) end
check("wrecks are capped", #w.state.wrecks == X.wrecks.max)
w.state.tick = w.state.tick + X.wrecks.days * 86400 / cfg.tickSeconds + 1
w:wrecksTick()
check("...and cleared after 3 days", #w.state.wrecks == 0)

-- partisans (Syria)
local sy = DCC.War.new(DCC_THEATERS.Syria, C, cfg, 5)
check("partisans on in Syria, off in the Caucasus", sy:partisansOn() and not w:partisansOn())
local town
local sdist = sy:frontDistance("red")
for _, id in ipairs(sy.T.order) do
  if sy.T.nodes[id].kind == "town" and sy.T.nodes[id].startSide == "blue" then town = id; break end
end
sy.state.nodes[town].side = "red"
for _, p2 in ipairs(DCC.util.copy(sy.state.nodes[town].platoons)) do sy:destroyPlatoon(p2) end
X.partisans.chance = 1
sy.frontDistance = function(self, side) local t = {}; for _, id in ipairs(self.T.order) do t[id] = 3 end; return t end
sy:partisansTick()
X.partisans.chance = 0.004
local cell
for _, c in pairs(sy.state.partisans) do if c.node == town then cell = c end end
check("partisans rise in a town RED took from BLUE", cell ~= nil and cell.side == "blue")
sy.state.nodes[town].supply = 20
sy:partisansTick()
check("they sabotage its supply", sy.state.nodes[town].supply < 20)
sy:missionsTick()
local cm
for _, m in ipairs(sy:openMissions("red")) do if m.type == "COIN" and m.target == cell.id then cm = m end end
check("RED gets a COIN mission", cm ~= nil)
sy:partisanKilled(cell.id, "red")
sy:missionsTick()
check("cell wiped out: COIN done", sy.state.missions[cm.id].status == "done")

-- ===========================================================================
print("DCS bridge")
-- ===========================================================================
dofile(DCC_ROOT .. "/tests/dcs_mock.lua")
dofile(DCC_ROOT .. "/tests/ctld_shim.lua")
MOCK.writedir = (arg[1] or "/tmp") .. "/dcc_ext_" .. tostring(os.time()) .. "/"
os.execute('mkdir -p "' .. MOCK.writedir .. '"')
MOCK.buildAirbases(T)
MOCK.addTemplates()
MOCK.explosions = {}
trigger.action.explosion = function(p, power) MOCK.explosions[#MOCK.explosions + 1] = { p = p, power = power } end
-- runways: 2.5 km long, north-south through the airbase point
for _, ab in pairs(MOCK.airbases) do
  ab.getRunways = function(self) return { { position = { x = self.p.x, y = 0, z = self.p.z }, course = 0, length = 2500, width = 60 } } end
end
DCC_ARMOURY_MODE = "takeoff"     -- this file tests the take-off variant (test_armoury.lua the warehouse one)
MOCK.UnitMT.getAmmo = function(self) return self.ammo end
MOCK.UnitMT.hasAttribute = function(self, a) return self.attrs and self.attrs[a] == true end

for _, f in ipairs({ "dcc_persist", "dcc_dcs", "dcc_dcs_supply", "dcc_dcs_ops", "dcc_dcs_intel", "dcc_dcs_radar",
                     "dcc_dcs_world", "dcc_dcs_jtac", "dcc_dcs_public", "dcc_dcs_air", "dcc_dcs_ground",
                     "dcc_dcs_ctld", "dcc_dcs_ext_air", "dcc_dcs_ext_ground", "dcc_dcs_ext2", "dcc_dcs_ext3", "dcc_dcs_ext4", "dcc_dcs_armoury", "dcc_main" }) do
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
war:tick()

print("Armoury")
local kp = B.nodePos.kutaisi
local ab = MOCK.airbases[B.airbases.kutaisi]
local viper = MOCK.spawnPlayer(BLUE, "F-16C_50", ab.p.x, ab.p.z, "Morten")
local pv = B.players[viper:getName()]
local said = table.concat(MOCK.groupTexts[pv.gid] or {}, "|")
check("the pilot is told what the base can arm him with", said:find("Armoury at Kutaisi", 1, true) ~= nil)
war.state.nodes.kutaisi.supply = 0
viper.ammo = { { count = 4, desc = { category = 1, guidance = 3, missileCategory = 1, typeName = "AIM_120C" } } }
viper.vel = { x = 8, y = 0, z = 0 }
B.detect()
said = table.concat(MOCK.groupTexts[pv.gid] or {}, "|")
check("taxiing with AMRAAMs from a dry base: warned", said:find("WARNING", 1, true) ~= nil)
MOCK.fire({ id = world.event.S_EVENT_TAKEOFF, initiator = viper })
MOCK.advance(3)
check("...and recalled at take-off", viper.alive == false)
local hog = MOCK.spawnPlayer(BLUE, "A-10C_2", ab.p.x + 50, ab.p.z, "Jens")
war.state.nodes.kutaisi.supply = war:supplyCap("kutaisi")
local before = war.state.nodes.kutaisi.supply
hog.ammo = { { count = 2, desc = { category = 3, guidance = 7, typeName = "GBU_12" } },
             { count = 14, desc = { category = 2, typeName = "Hydra" } } }
MOCK.fire({ id = world.event.S_EVENT_TAKEOFF, initiator = hog })
check("a supplied base issues guided bombs and charges for them", hog.alive and
  math.abs(war.state.nodes.kutaisi.supply - (before - 2 * DCC.config.ext.armoury.guidedSU)) < 0.01, war.state.nodes.kutaisi.supply)

print("Runway strike")
local sochiAb = MOCK.airbases[B.airbases.sochi]
local function drop(x, z)
  local w = { alive = true, x = x, z = z }
  w.isExist = function(self) return self.alive end
  w.getPoint = function(self) return { x = self.x, y = 0, z = self.z } end
  w.getDesc = function() return { category = 3, typeName = "Mk_84" } end
  MOCK.fire({ id = world.event.S_EVENT_SHOT, initiator = hog, weapon = w })
  MOCK.advance(1)
  w.alive = false
  MOCK.advance(1)
end
drop(sochiAb.p.x + 500, sochiAb.p.z + 30)
check("a bomb on the runway counts", war.state.runways.sochi and war.state.runways.sochi.hits == 1)
drop(sochiAb.p.x + 300, sochiAb.p.z + 400)
check("a bomb 400 m off the runway does not", war.state.runways.sochi.hits == 1)
drop(sochiAb.p.x - 600, sochiAb.p.z)
drop(sochiAb.p.x, sochiAb.p.z - 20)
check("three hits: Sochi's runway closed", war:runwayClosed("sochi"))
local mig = MOCK.spawnPlayer(RED, "MiG-29S", sochiAb.p.x, sochiAb.p.z, "Ivan")
check("a jet cannot spawn at a closed airfield", mig.alive == false)
local hind = MOCK.spawnPlayer(RED, "Mi-24P", sochiAb.p.x + 30, sochiAb.p.z, "Olga", true)
check("a helicopter can", hind.alive ~= false)

print("Shoot and scoot")
local samNode2
for _, id in ipairs(war.T.order) do
  local n2 = war.state.nodes[id]
  if n2.side == "red" and n2.sam and n2.sam.status == "up" then samNode2 = id; break end
end
local sp = B.nodePos[samNode2]
hog.x, hog.z, hog.alt, hog.air = sp.x - 20000, sp.z, 4000, true
MOCK.advance(31)
B.scanSams()
local rec = B.sams[samNode2]
check("SAM site and its point defence on the map", rec and rec.pd and MOCK.groups[rec.pd] ~= nil)
local pdUnit = MOCK.groups[rec.pd].units[1]
MOCK.fire({ id = world.event.S_EVENT_SHOT, initiator = pdUnit, weapon = MOCK.weapon(2, hog) })
MOCK.advance(25)
check("point defence drives off after firing", MOCK.groups[rec.pd].lastTask and MOCK.groups[rec.pd].lastTask.id == "Mission"
  and war.state.nodes[samNode2].sam.pdOff ~= nil)
local siteUnit = MOCK.groups[rec.group].units[1]
MOCK.fire({ id = world.event.S_EVENT_SHOT, initiator = siteUnit, weapon = MOCK.weapon(4, hog) })
MOCK.advance(35)
check("the SA-11 (mobile) moves too", war.state.nodes[samNode2].sam.off ~= nil)

print("Aircrews")
war.state.airPool.red.attack = 8
local s25 = B.spawnSortie("red", "attack", "CAS", { x = kp.x, y = 0, z = kp.z }, {})
local crew = MOCK.groups[s25].units[1]
war.rng.next = function() return 0.1 end                  -- the crew gets out
local nDown = 0
for _ in pairs(war.state.downed) do nDown = nDown + 1 end
MOCK.fire({ id = world.event.S_EVENT_EJECTION, initiator = crew })
local aiDown
for did2, d in pairs(war.state.downed) do if d.aiRole then aiDown = did2 end end
check("an AI crew that ejects is down on the map", aiDown ~= nil and B.downedGroups[aiDown] ~= nil)
-- a BLUE Huey picks him up
local huey = MOCK.spawnPlayer(BLUE, "UH-1H", 0, 0, "Pedro", true)
local ph = B.players[huey:getName()]
local dpos = war.state.downed[aiDown].pos
huey.x, huey.z, huey.air = dpos.x + 50, dpos.z, false
B.csarCheck(ph, huey, huey:getPoint())
check("enemy pilot on board", ph.prisoners and ph.prisoners[aiDown])
huey.x, huey.z = kp.x + 200, kp.z
B.csarCheck(ph, huey, huey:getPoint())
check("landed at an own base: prisoner taken", war.state.downed[aiDown] == nil and DCC.pilots:get(ph.key).prisoners == 1)

print("Support on call")
local function mark(side, x, z)
  MOCK.fire({ id = 25, coalition = side == "blue" and 2 or 1, pos = { x = x, y = 0, z = z }, text = "target" })
end
local hp = B.players[hog:getName()]
B.callArtillery(hog:getName())
said = table.concat(MOCK.groupTexts[hp.gid] or {}, "|")
check("artillery needs the rank of Captain", said:find("Captain", 1, true) ~= nil)
DCC.pilots:add(hp.key, "missions", 10)                     -- 200 points: Captain
for _, b in ipairs(war:batteries("blue")) do b.status, b.node = "up", "kutaisi" end
war.state.nodes.kutaisi.supply = 100
mark("blue", kp.x + 15000, kp.z)
local nx = #MOCK.explosions
B.callArtillery(hog:getName())
MOCK.advance(80)
check("fire mission on the mark: shells land", #MOCK.explosions >= nx + DCC.config.ext.support.artyRounds)
check("paid from the battery's base", war.state.nodes.kutaisi.supply <= 90)
B.callArtillery(hog:getName())
said = table.concat(MOCK.groupTexts[hp.gid] or {}, "|")
check("then the guns are busy for a while", said:find("busy", 1, true) ~= nil)
B.callCas(hog:getName())
said = table.concat(MOCK.groupTexts[hp.gid] or {}, "|")
check("CAS needs the rank of Major", said:find("Major", 1, true) ~= nil)
DCC.pilots:add(hp.key, "missions", 10)                     -- 400: Major
war.state.airPool.blue.attack = 8
B.callCas(hog:getName())
local casUp = false
for _, s in pairs(B.sorties) do if s.side == "blue" and s.kind == "CAS" then casUp = true end end
check("CAS pair inbound to the mark", casUp)
check("the Support menu is there", (function()
  for _, it in ipairs(MOCK.groupMenus[hp.gid] or {}) do if it.name == "Support" then return true end end
end)() == true)

print("Ranks and FARPs")
local town
for _, id in ipairs(war.T.order) do
  if war.state.nodes[id].side == "blue" and war.T.nodes[id].kind == "town" then town = id; break end
end
war.state.nodes[town].farp = { side = "blue", built = war.state.tick }
local tp = B.nodePos[town]
local rookie = MOCK.spawnPlayer(BLUE, "UH-1H", tp.x + 50, tp.z, "Newbie", true)
check("a Lieutenant cannot spawn at a FARP", rookie.alive == false)

print("Scaling")
MOCK.spawnPlayer(BLUE, "F-16C_50", kp.x, kp.z, "A1")
MOCK.spawnPlayer(BLUE, "F-16C_50", kp.x, kp.z, "A2")
B.opsTick()
check("RED outnumbered: its losses are scaled down", war:scaleBonus("red") > 0)

print("Wrecks")
local tgroup = "DCC_TEST_TANK"
coalition.addGroup(81, Group.Category.GROUND, { name = tgroup, units = { { name = tgroup .. "_1", type = "T-72B",
  x = kp.x + 3000, y = kp.z } } })
local tank = MOCK.groups[tgroup].units[1]
tank.attrs = { ["Armored vehicles"] = true }
tank.alive = false
MOCK.fire({ id = world.event.S_EVENT_DEAD, initiator = tank })
check("a destroyed tank is recorded", #war.state.wrecks >= 1 and war.state.wrecks[#war.state.wrecks].type == "T-72B")
local inf = MOCK.groups[tgroup].units[1]
B.restoreWrecks()
local wrecks = 0
for name, st in pairs(MOCK.statics) do if name:find("^DCC_WRECK_") then wrecks = wrecks + 1 end end
check("restored as a wreck after a restart", wrecks >= 1)

print("Industry and partisans on the map")
B.reconcileIndustry()
local ind = 0
for name in pairs(MOCK.statics) do if name:find("^DCC_IND_") then ind = ind + 1 end end
check("industry sites on the map (3 buildings each)", ind == 18, ind)
local site = war:industrySites("red")[1]
local names = B.industry[site.id].names
MOCK.statics[names[1]].alive = false
MOCK.statics[names[2]].alive = false
B.reconcileIndustry()
check("2 of 3 buildings destroyed: the site is down", site.status == "destroyed")

print("A day of it")
for _ = 1, 288 do MOCK.advance(300) end
check("no script errors", errors == 0, errors)

print(string.format("\n%d passed, %d failed", passed, failed))
DCC_EXIT_CODE = failed == 0 and 0 or 1
