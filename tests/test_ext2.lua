-- ============================================================================
-- v0.18 features: HVA escort and hunts, strike packages, aces, artillery
-- duels, convoy ambushes, prisoners, medevac, heavy sling loads, CSAR under
-- fire. Pure model first, then the bridge with the real CTLD on the mock.
--   python tools/run_lua.py tests/test_ext2.lua
-- ============================================================================

local passed, failed = 0, 0
local function check(name, cond, detail)
  if cond then passed = passed + 1; print("  ok   " .. name)
  else failed = failed + 1; print("  FAIL " .. name .. (detail and (" - " .. tostring(detail)) or "")) end
end

local T, C, cfg = DCC_THEATERS.Caucasus, DCC_CATALOGS.modern, DCC.config
local X = cfg.ext2

-- ===========================================================================
print("Pure model")
-- ===========================================================================
local w = DCC.War.new(T, C, cfg, 21)
w:tick()

print(" HVA")
w:setAsset("blue", "tanker", true)
w:missionsTick()
local hv
for _, m in pairs(w.state.missions) do if m.type == "HVAESCORT" and m.target == "blue|tanker" then hv = m end end
check("HVAESCORT offered for our tanker", hv ~= nil)
w:setHvaThreat("blue", "tanker", true)
check("...and flagged when hunters are out", w.missionGenerators.HVAESCORT(w, "blue")[1].label:find("inbound", 1, true) ~= nil)
w:assetLost("blue", "tanker")
w:missionsTick()
check("tanker lost: the escort mission failed", w.state.missions[hv.id].status == "failed")
check("...and no tanker for 2 h", w:hvaGrounded("blue", "tanker"))
for _ = 1, X.hvaDownTicks do w.state.tick = w.state.tick + 1 end
check("after 2 h it may fly again", not w:hvaGrounded("blue", "tanker"))
w:awacsLost("red")
check("AWACS loss grounds the AWACS too", w:hvaGrounded("red", "awacs"))

print(" Strike packages")
w.state.missions = {}
local sid = w:newId("x")
w.state.missions[sid] = { id = sid, side = "blue", type = "STRIKE", target = "sukhumi", node = "sukhumi",
  label = "Sukhumi depot", base = { lost = 0 }, created = w.state.tick, taken = { k1 = "Striker" }, status = "open",
  needs = "A2G" }
local seadId = w:newId("x")
w.state.missions[seadId] = { id = seadId, side = "blue", type = "SEAD", target = "sukhumi", node = "sukhumi",
  label = "air defence", base = {}, created = w.state.tick, taken = { k2 = "Weasel" }, status = "open", needs = "SEAD" }
w:missionsTick()
local pk
for _, m in pairs(w.state.missions) do if m.type == "PKGESCORT" and m.target == sid then pk = m end end
check("PKGESCORT offered with the strike", pk ~= nil, pk and pk.label)
w:takeMission(pk.id, "k3", "Eagle")
pk.escortOk = true
w.newEvents = {}
w:finishMission(w.state.missions[sid], "done")
local bonus
for _, ev in ipairs(w.newEvents) do if ev.kind == "package_done" then bonus = ev end end
check("strike done with SEAD and escort: package bonus", bonus ~= nil and bonus.crew.k1 and bonus.crew.k2 and bonus.crew.k3)
w:missionsTick()
check("...and the escort is done too", w.state.missions[pk.id].status == "done")
local lone = w:newId("x")
w.state.missions = { [lone] = { id = lone, side = "blue", type = "STRIKE", target = "sochi", node = "sochi", label = "x",
  base = {}, created = w.state.tick, taken = { k1 = "Striker" }, status = "open", needs = "A2G" } }
w.newEvents = {}
w:finishMission(w.state.missions[lone], "done")
local none = true
for _, ev in ipairs(w.newEvents) do if ev.kind == "package_done" then none = false end end
check("a strike flown alone: no package bonus", none)

print(" Artillery duels")
local w2 = DCC.War.new(T, C, cfg, 5)
w2:tick()
local b = w2:batteries("red")[1]
local own, target
for _, id in ipairs(w2.T.order) do
  if w2.state.nodes[id].side == "red" then
    for nb in pairs(w2.T.nodes[id].nb) do
      if w2.state.nodes[nb].side == "blue" and not own then own, target = id, nb end
    end
  end
end
b.status, b.node = "up", own
w2.state.moves = {}
local before = w2.state.nodes[target].supply
w2.newEvents = {}
w2:artyHarassTick()
check("a quiet battery shells the enemy base next door", b.shelling ~= nil)
local shelled = b.shelling
check("...which loses supply", w2.state.nodes[shelled].supply < (shelled == target and before or math.huge))
check("...and the flashes give it away (contact)", w2:contact("blue", "arty:" .. b.id) ~= nil)

print(" Prisoners and wounded")
local w3 = DCC.War.new(T, C, cfg, 8)
w3:tick()
local town = "zugdidi"
w3.state.nodes[town].side = "blue"
w3.newEvents = { { kind = "capture", side = "blue", node = town, from = "red" } }
w3:pickupsTick()
local pow, med
for _, q in pairs(w3.state.pickups) do if q.kind == "pow" then pow = q else med = q end end
check("a capture leaves prisoners and wounded", pow ~= nil and med ~= nil)
w3:missionsTick()
local types = {}
for _, m in pairs(w3.state.missions) do types[m.type] = (types[m.type] or 0) + 1 end
check("POW and MEDEVAC missions on the board", types.POW == 1 and types.MEDEVAC == 1)
check("a drop at a town is not accepted", not w3:pickupDropOk(pow, "senaki") or w3.T.nodes.senaki.kind == "airbase")
local rear
for _, id in ipairs(w3.T.order) do
  if w3.state.nodes[id].side == "blue" and w3.T.nodes[id].kind == "airbase" and id ~= town then rear = id end
end
w3:pickupLoaded(pow.id)
local intelBefore = 0
for _ in pairs(w3.state.intel.blue) do intelBefore = intelBefore + 1 end
w3.newEvents = {}
check("prisoners delivered to an airbase", w3:pickupDelivered(pow.id, rear))
local intelAfter = 0
for _ in pairs(w3.state.intel.blue) do intelAfter = intelAfter + 1 end
check("...talk: intel on nearby enemy bases", intelAfter > intelBefore, intelBefore .. " -> " .. intelAfter)
local pl = w3.state.platoons[w3.state.nodes[town].platoons[1]]
if pl then pl.health = 0.5 end
w3:pickupLoaded(med.id)
w3:pickupDelivered(med.id, rear)
check("wounded flown out: the garrison heals", not pl or math.abs(pl.health - (0.5 + X.medevacHeal)) < 1e-6)
w3:missionsTick()
local done = 0
for _, m in pairs(w3.state.missions) do if (m.type == "POW" or m.type == "MEDEVAC") and m.status == "done" then done = done + 1 end end
check("both missions done", done == 2, done)
w3.newEvents = { { kind = "repulsed", side = "blue", node = town } }
w3:pickupsTick()
local q2 = next(w3.state.pickups) and w3.state.pickups[next(w3.state.pickups)]
check("a repulsed assault leaves wounded", q2 and q2.kind == "medevac")
w3.state.tick = w3.state.tick + X.medevacTicks + 1
w3.newEvents = {}
w3:pickupsTick()
check("nobody came: they are taken by road after a while", next(w3.state.pickups) == nil)

print(" Heavy lift and search parties")
local before2 = w3:supplyCap(rear)
w3:installGenerator(rear, "blue")
check("a generator: +25 % supply cap", math.abs(w3:supplyCap(rear) - before2 * (1 + X.generatorBoost)) < 1e-6)
w3.state.runways[rear] = { hits = 0, closedUntil = w3.state.tick + 40 }
check("a runway repair kit reopens a cratered runway", w3:repairRunwayNow(rear, "blue") and not w3:runwayClosed(rear))
local did = w3:addDowned("blue", { x = 0, z = 0 }, "Lars", "F-16C_50", rear, "k9")
check("a search party can capture a downed pilot", w3:downedCaptured(did, "red") and w3.state.downed[did] == nil)

-- ===========================================================================
print("Bridge")
-- ===========================================================================
dofile(DCC_ROOT .. "/tests/dcs_mock.lua")
dofile(DCC_ROOT .. "/tests/ctld_shim.lua")
MOCK.writedir = (arg[1] or "/tmp") .. "/dcc_x2_" .. tostring(os.time()) .. "/"
os.execute('mkdir -p "' .. MOCK.writedir .. '"')
MOCK.buildAirbases(T)
MOCK.addTemplates()
ctld = { dontInitialize = true }
dofile(DCC_ROOT .. "/vendor/ctld/CTLD.lua")
for _, f in ipairs({ "dcc_persist", "dcc_dcs", "dcc_dcs_supply", "dcc_dcs_ops", "dcc_dcs_intel", "dcc_dcs_radar",
                     "dcc_dcs_world", "dcc_dcs_jtac", "dcc_dcs_public", "dcc_dcs_air", "dcc_dcs_ground",
                     "dcc_dcs_ctld", "dcc_dcs_ext_air", "dcc_dcs_ext_ground", "dcc_dcs_ext2", "dcc_dcs_ext3", "dcc_dcs_ext4", "dcc_dcs_armoury",
                     "dcc_main" }) do
  dofile(DCC_ROOT .. "/src/" .. f .. ".lua")
end
local errors = 0
DCC.util.log = function(fmt, ...)
  local msg = string.format(fmt, ...)
  if msg:find("ERROR") then errors = errors + 1; print("    " .. msg) end
end
env.info = function() end
DCC.start()
local B, war = DCC.dcs, DCC.warObj
local BLUE, RED = 2, 1
local cm = CTLDCrateManager.getInstance()
local kp = B.nodePos.kutaisi

print(" HVA hunt and escort")
local viper, vg = MOCK.spawnPlayer(BLUE, "F-16C_50", kp.x, kp.z, "Morten")
viper.air = true
DCC.onTick()
check("BLUE tanker up", B.assets.blue.tanker ~= nil)
check("...on the datalink too", (MOCK.groups[B.assets.blue.tanker.group].commands or {}).EPLRS == true)
local realHunt = X.huntMinutes
X.huntMinutes = 0.0001
B.planHunts()
X.huntMinutes = realHunt
check("RED fighters sent after the BLUE tanker", B.x2.hunts["blue|tanker"] ~= nil)
check("...and the threat is on the board", war.state.hvaThreat["blue|tanker"] ~= nil)
war:missionsTick()
B.refreshMenus()
local ok1 = MOCK.click(vg.id, "HVAESCORT: our tanker")
check("a Viper can take HVAESCORT", ok1)
local tu = MOCK.groups[B.assets.blue.tanker.group].units[1]
for _ = 1, X.hvaEscortMin + 1 do                 -- fly along with it
  viper.x, viper.z = tu.x + 5000, tu.z
  MOCK.advance(60)
end
local hm
for _, m in pairs(war.state.missions) do if m.type == "HVAESCORT" and next(m.taken) then hm = m end end
check("20 min with the tanker: escort complete", hm and hm.status == "done", hm and hm.status)
MOCK.killGroup(B.x2.hunts["blue|tanker"])
B.pollHunts()
check("hunters gone: threat cleared", war.state.hvaThreat["blue|tanker"] == nil)

print(" Aces")
war.state.airPool.red.fighter = 20          -- plenty of RED fighters, whatever the war did so far
war.state.airPool.blue.fighter = 20
local bandits = {}
for i = 1, 3 do
  local g = MOCK.groups[B.spawnSortie("red", "fighter", "CAP", { x = kp.x + 30000, y = 0, z = kp.z }, { node = "kutaisi" })]
  bandits[i] = g.units[1]
end
local before3 = 0
for _ in pairs(B.sorties) do before3 = before3 + 1 end
for i = 1, 3 do MOCK.fire({ id = world.event.S_EVENT_KILL, initiator = viper, target = bandits[i] }) end
local hunts = 0
for _, s in pairs(B.sorties) do if s.kind == "HUNT" and s.side == "red" then hunts = hunts + 1 end end
check("3 kills in a sortie: RED sends fighters at the ace", hunts >= 2, hunts)
check("...and tells him", (MOCK.lastGroupText(vg.id) or ""):find("noticed you", 1, true) ~= nil)

print(" Pick-ups")
local zug = "zugdidi"
war.state.nodes[zug].side = "blue"
war.state.nodes[zug].farp = nil                    -- v0.44: no FARP there (a FARP spawn needs a rank)
local q = war:addPickup("medevac", "blue", zug, 4)
B.reconcilePickups()
check("the wounded stand at the base", MOCK.groups["DCC_PICK_" .. q.id] ~= nil)
local qp = B.pickupPos(q)
local huey, hg = MOCK.spawnPlayer(BLUE, "UH-1H", qp.x + 50, qp.z, "Doc", true)
MOCK.advance(11)
check("landed next to them: on board", war.state.pickups[q.id].onboard == true and MOCK.groups["DCC_PICK_" .. q.id] == nil)
huey.x, huey.z = kp.x + 200, kp.z
MOCK.advance(11)
check("landed at Kutaisi: delivered", war.state.pickups[q.id] == nil)
check("...and logged on the pilot record", (DCC.pilots.data.pilots.Doc.medevacs or 0) == 1)
local q3 = war:addPickup("pow", "blue", zug, 3)
huey.x, huey.z = B.pickupPos(q3).x, B.pickupPos(q3).z
MOCK.advance(11)
MOCK.fire({ id = world.event.S_EVENT_CRASH, initiator = huey })
MOCK.fire({ id = world.event.S_EVENT_PLAYER_LEAVE_UNIT, initiator = huey })
check("shot down with prisoners on board: lost", war.state.pickups[q3.id] == nil or war.state.pickups[q3.id].onboard ~= true)

print(" Heavy lift")
local genDesc, rwDesc
for _, list in pairs(ctld.gs("spawnableCrates")) do
  for _, c in ipairs(list) do
    if c.dccHeavy == "generator" then genDesc = c end
    if c.dccHeavy == "runway" then rwDesc = c end
  end
end
check("Generator and Runway repair kit in CTLD", genDesc ~= nil and rwDesc ~= nil)
war.state.nodes.kutaisi.supply = 200
local h2 = MOCK.spawnPlayer(BLUE, "UH-1H", kp.x + 100, kp.z, "Small", true)
check("a Huey cannot lift a generator", cm:spawnCrate(genDesc, { x = kp.x + 120, y = 0, z = kp.z }, BLUE, h2:getName(), "menu_ctld") == nil)
local rkDesc
for _, list in pairs(ctld.gs("spawnableCrates")) do
  for _, c in ipairs(list) do if c.dccHeavy == "repair" then rkDesc = c end end
end
check("v0.27: Repair kit in CTLD > Engineering", rkDesc ~= nil)
local suK = war.state.nodes.kutaisi.supply
check("...a Huey can lift it, for 20 SU", rkDesc and cm:spawnCrate(rkDesc, { x = kp.x + 140, y = 0, z = kp.z }, BLUE,
  h2:getName(), "menu_ctld") ~= nil and math.abs(war.state.nodes.kutaisi.supply - (suK - 20)) < 0.01)
local hook = MOCK.spawnPlayer(BLUE, "CH-47Fbl1", kp.x + 100, kp.z, "Hook", true)
local gen = cm:spawnCrate(genDesc, { x = kp.x + 130, y = 0, z = kp.z }, BLUE, hook:getName(), "menu_ctld")
check("a Chinook can", gen ~= nil)
local cap0 = war:supplyCap("kutaisi")
B.ctldCrateDown(gen, { x = kp.x + 500, y = 0, z = kp.z })
check("generator set down at Kutaisi: bigger store", war:supplyCap("kutaisi") > cap0)
war.state.runways.kutaisi = { hits = 0, closedUntil = war.state.tick + 40 }
local rk = cm:spawnCrate(rwDesc, { x = kp.x + 140, y = 0, z = kp.z }, BLUE, hook:getName(), "menu_ctld")
cm:unpackCrate(rk.crateName, hook)
check("runway kit unpacked at a cratered runway: open again", not war:runwayClosed("kutaisi"))

print(" CSAR under fire")
local sp = B.nodePos[zug]
war.state.nodes[zug].side = "red"
local lars = MOCK.spawnPlayer(BLUE, "F-16C_50", sp.x + 6000, sp.z, "Lars")
MOCK.fire({ id = world.event.S_EVENT_EJECTION, initiator = lars })
local did2 = next(war.state.downed)
war.state.downed[did2].tick = war.state.tick - 3
B.pollSearch()
check("a RED search party sets out", B.x2.search[did2] ~= nil)
MOCK.advance(1800)
B.pollSearch()
check("...and captures the pilot nobody rescued", war.state.downed[did2] == nil)

print(" Convoys")
war.state.nodes.senaki.supply = 300
war.state.nodes.zugdidi.side = "blue"
local mv = war:startCargo("convoy", "blue", "senaki", "zugdidi", 30)
mv.front = true
local cm2 = { id = "xtestconvoy", type = "CONVOY", side = "blue", target = mv.id, status = "open", taken = {} }
war.state.missions[cm2.id] = cm2
B.spawnAmbush(cm2)
check("escorted convoy: a second ambush further down the road", B.x2.amb2[cm2.id] ~= nil and B.ambushes[cm2.id] ~= nil)

print(" A day")
for _ = 1, 288 do MOCK.advance(300) end
check("no script errors", errors == 0, errors)

print(string.format("\n%d passed, %d failed", passed, failed))
DCC_EXIT_CODE = failed == 0 and 0 or 1
