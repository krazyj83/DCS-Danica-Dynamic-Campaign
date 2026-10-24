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
check("...and gets no pilot menus", B.players.CA_TANK_1 == nil)

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

print(" A day")
viper.air = false
for _ = 1, 288 do MOCK.advance(300) end
check("no script errors", errors == 0, errors)

print(string.format("\n%d passed, %d failed", passed, failed))
DCC_EXIT_CODE = failed == 0 and 0 or 1
