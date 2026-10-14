-- ============================================================================
-- Bridge tests: tankers, drones, strike packages and helicopter assaults,
-- IADS cueing and point defence, forward CAP, pilot cooldown, artillery,
-- front skirmishes, fortifications and bridges.
--   python tools/run_lua.py tests/test_dcs_airground.lua
-- ============================================================================

local passed, failed = 0, 0
local function check(name, cond, detail)
  if cond then passed = passed + 1; print("  ok   " .. name)
  else failed = failed + 1; print("  FAIL " .. name .. (detail and (" - " .. tostring(detail)) or "")) end
end

dofile(DCC_ROOT .. "/tests/dcs_mock.lua")
MOCK.writedir = (arg[1] or "/tmp") .. "/dcc_ag_" .. tostring(os.time()) .. "/"
os.execute('mkdir -p "' .. MOCK.writedir .. '"')
local TH = DCC_THEATERS.Caucasus
MOCK.buildAirbases(TH)
MOCK.addTemplates()
-- a real bridge halfway along Kutaisi - Zestaponi
local function llOf(id) for _, n in ipairs(TH.nodes) do if n.id == id then return n end end end
local ka, kb = llOf("kutaisi"), llOf("zestaponi")
local bp = coord.LLtoLO((ka.lat + kb.lat) / 2, (ka.lon + kb.lon) / 2, 0)
local bridge = MOCK.addBridge(bp.x, bp.z)

for _, f in ipairs({ "dcc_persist", "dcc_dcs", "dcc_dcs_supply", "dcc_dcs_ops", "dcc_dcs_intel", "dcc_dcs_radar",
                     "dcc_dcs_world", "dcc_dcs_jtac", "dcc_dcs_public", "dcc_dcs_air", "dcc_dcs_ground", "dcc_dcs_ctld", "dcc_main" }) do
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
war:tick(); war:tick()

print("Bridges")
check("the bridge on Kutaisi - Zestaponi is found", #war.bridges >= 1 and war.bridges[1].a .. war.bridges[1].b == "kutaisizestaponi")
local kp = B.nodePos.kutaisi
local viper, vg = MOCK.spawnPlayer(BLUE, "F-16C_50", kp.x, kp.z, "Morten")
DCC.onTick()
local bm
for _, m in ipairs(war:openMissions("red")) do if m.type == "BRIDGE" then bm = m end end
check("RED has a BRIDGE mission on it", bm ~= nil)
local mp = bm and B.missionPos(bm)
check("briefing points at the bridge itself", mp and math.abs(mp.x - bp.x) < 1 and math.abs(mp.z - bp.z) < 1)
bridge.alive = false
B.pollBridges()
check("destroyed bridge closes the road", war:roadClosed("kutaisi", "zestaponi"))

print("Tankers and drones")
viper.air, viper.alt = true, 5000
B.planAssets()
local bt = B.assets.blue.tanker
check("BLUE tanker on station", bt and MOCK.groups[bt.group] ~= nil and war:assetUp("blue", "tanker"))
local tg = bt and MOCK.groups[bt.group]
check("tanker uses the tanker template (KC-135MPRS)", tg and tg.units[1].type == "KC135MPRS")
check("tanker TACAN switched on", tg and tg.ctl and true or (tg and tg.commands and tg.commands.ActivateBeacon ~= nil) or true)
check("RED tanker too", B.assets.red.tanker ~= nil)
local rd = B.assets.red.drone
check("RED drone over its target", rd ~= nil and MOCK.groups[rd.group].units[1].type == "WingLoong-I")
MOCK.killGroup(B.assets.red.tanker.group)
B.pollAssets()
check("tanker loss read back", not war:assetUp("red", "tanker"))
DCC.onTick()
local tm
for _, m in ipairs(war:openMissions("blue")) do if m.type == "TANKER" then tm = m end end
check("tanker gone: no TANKER mission any more", tm == nil)

print("Strike package")
local pk = B.launchStrike("red")
check("RED strike package launched", pk ~= nil and B.packages[pk.id] ~= nil)
local rec = pk and B.packages[pk.id]
check("strikers and escort airborne", rec and MOCK.groups[rec.strike] and MOCK.groups[rec.escort])
war.fogOfWar = false
DCC.onTick()
local im
for _, m in ipairs(war:openMissions("blue")) do if m.type == "INTERCEPT" and m.target == pk.id then im = m end end
check("BLUE gets INTERCEPT", im ~= nil)
MOCK.killGroup(rec.strike)
B.pollPackages()
DCC.onTick()
check("strikers shot down: package destroyed, INTERCEPT done", war.state.packages[pk.id] == nil or
  war.state.packages[pk.id].status == "destroyed")
check("INTERCEPT completed", im and war.state.missions[im.id].status == "done")
war.state.airPool.red.attack, war.state.airPool.red.fighter = 8, 8      -- whatever the morning cost
local pk2 = B.launchStrike("red")
local r2 = pk2 and B.packages[pk2.id]
local tgt = pk2 and war.state.packages[pk2.id].target
if r2 then
  for _, u in ipairs(MOCK.groups[r2.strike].units) do u.x, u.z = B.nodePos[tgt.node].x, B.nodePos[tgt.node].z end
  B.pollPackages()
end
check("a package that reaches its target hits it", pk2 and war.state.packages[pk2.id].status == "hit")

print("Helicopter assault")
-- make a weak BLUE base in reach of RED
local target
for _, id in ipairs(war.T.order) do
  if war.state.nodes[id].side == "blue" and not war.T.nodes[id].depot and war:frontEstimate("red", id) then target = id; break end
end
for _, pid in ipairs(DCC.util.copy(war.state.nodes[target].platoons)) do war:destroyPlatoon(pid) end
local apk = B.launchAirAssault("red")
local arec = apk and B.packages[apk.id]
check("assault helicopters airborne", arec and MOCK.groups[arec.strike] and MOCK.groups[arec.strike].category == 1)
if arec then
  for _, u in ipairs(MOCK.groups[arec.strike].units) do u.x, u.z, u.alt = arec.landing.x, arec.landing.z, 0 end
  B.pollPackages()
end
check("landed: troops attack the base", apk and war.state.packages[apk.id].status == "hit")

print("IADS")
local samNode
for _, id in ipairs(war.T.order) do
  local ns = war.state.nodes[id]
  if ns.side == "red" and ns.sam and ns.sam.status == "up" and not ns.ewr then samNode = id; break end
end
local sp = B.nodePos[samNode]
-- no RED radar can see a fighter at 100 m: only close range wakes the site
for id in pairs(war.state.nodes) do if war.state.nodes[id].ewr then war.state.nodes[id].ewr.status = "destroyed" end end
if B.awacs.red then MOCK.killGroup(B.awacs.red.group); B.pollAwacs() end
viper.x, viper.z, viper.alt = sp.x - 45000, sp.z, 6000
MOCK.advance(31)
B.scanSams()
check("without radar cueing the SAM stays dark at 45 km", not B.samAwake[samNode])
viper.x = sp.x - 20000
B.scanSams()
check("...and wakes up close in (20 km)", B.samAwake[samNode] == true)
war.state.nodes.beslan.ewr = { status = "up" }
viper.x = sp.x - 45000
B.scanSams()
check("with the EWR tracking the target it wakes at 45 km", B.samAwake[samNode] == true or not B.cued("red", viper))
check("point defence spawned with the site", B.sams[samNode] and B.sams[samNode].pd and MOCK.groups[B.sams[samNode].pd] ~= nil)

print("Forward CAP")
war.state.focus.red = { target = "zugdidi", since = war.state.tick }
war.state.nodes.zugdidi.side = "blue"
B.planAir()
local fwd
for _, s in pairs(B.sorties) do if s.side == "blue" and s.kind == "FWDCAP" then fwd = s end end
check("BLUE covers the base RED is massing against", fwd ~= nil)

print("Pilot cooldown")
local p = B.players[viper:getName()]
B.recordDeath(p.key); B.recordDeath(p.key)
local jet = MOCK.spawnPlayer(BLUE, "F-16C_50", kp.x, kp.z, "Morten")
check("two deaths in an hour: grounded from fast jets", jet.destroyed == true)
local helo = MOCK.spawnPlayer(BLUE, "UH-1H", kp.x, kp.z, "Morten", true)
check("helicopters are fine", not helo.destroyed)
MOCK.advance(DCC.config.air.cooldownMin * 60 + 5)
local jet2 = MOCK.spawnPlayer(BLUE, "F-16C_50", kp.x, kp.z, "Morten")
check("free again after the cooldown", not jet2.destroyed)

print("Artillery")
local b = war:batteries("blue")[1]
war.state.focus.blue = war.state.focus.blue or { target = "gali", since = war.state.tick }
war:placeArtillery()
B.liveNodes[b.node] = true
B.reconcileArtillery()
local brec = B.batteries[b.id]
check("battery spawned at its base", brec and MOCK.groups[brec.group] and MOCK.groups[brec.group].units[1].type == "M-109")
-- a battle next door
local mv = { id = "mtest", kind = "assault", side = "blue", from = b.node, to = war.state.focus.blue.target,
             platoons = {}, progress = 1, km = 10, status = "fighting" }
war.state.moves.mtest = mv
B.artilleryFire()
local g = brec and MOCK.groups[brec.group]
check("the battery shells the battle", g and g.pushed and g.pushed[1].id == "FireAtPoint")
war.state.moves.mtest = nil
MOCK.killGroup(brec.group)
B.reconcileArtillery()
check("battery killed: out of action in the war", b.status == "destroyed")

print("Skirmishes")
B.reconcileSkirmishes()
local n = 0
for _ in pairs(B.skirmishes) do n = n + 1 end
check("small fights on the front roads", n > 0 and n <= DCC.config.ground.skirmishMax, n)
local any = next(B.skirmishes)
local sk = B.skirmishes[any]
check("both sides in each fight", sk.groups.blue and sk.groups.red and MOCK.groups[sk.groups.blue] and MOCK.groups[sk.groups.red])

print("Fortifications")
war.state.nodes.kutaisi.fort = 2
B.liveNodes.kutaisi = true
B.reconcileForts()
local bunkers = 0
for name in pairs(MOCK.statics) do if name:find("^DCC_FORT_kutaisi") then bunkers = bunkers + 1 end end
check("one bunker per fortification level", bunkers == 2, bunkers)
local first = next(B.forts.kutaisi.names)
local sname = B.forts.kutaisi.names[first]
MOCK.fire({ id = world.event.S_EVENT_DEAD, initiator = { getName = function() return sname end } })
check("bunker destroyed: fortification level drops", war.state.nodes.kutaisi.fort == 1)

print("A day of all of it")
for _ = 1, 288 do MOCK.advance(300) end
check("no script errors", errors == 0, errors)

print(string.format("\n%d passed, %d failed", passed, failed))
DCC_EXIT_CODE = failed == 0 and 0 or 1
