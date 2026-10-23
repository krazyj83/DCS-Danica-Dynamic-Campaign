-- ============================================================================
-- v0.25: amphibious assaults, shipping lanes, carrier air wing, SCUDs, pop-up
-- threats. Pure model first, then the bridge on the mock.
--   python tools/run_lua.py tests/test_ext3.lua
-- ============================================================================

local passed, failed = 0, 0
local function check(name, cond, detail)
  if cond then passed = passed + 1; print("  ok   " .. name)
  else failed = failed + 1; print("  FAIL " .. name .. (detail and (" - " .. tostring(detail)) or "")) end
end

local T, C, cfg = DCC_THEATERS.Caucasus, DCC_CATALOGS.modern, DCC.config
local X = cfg.ext3

-- ===========================================================================
print("Pure model")
-- ===========================================================================
local w = DCC.War.new(T, C, cfg, 31)
w:tick()

print(" Amphibious")
local ships = w:amphibShips("blue")
check("Tarawa is BLUE's amphibious ship", #ships == 1 and ships[1].id == "lha")
check("RED lands from the Kuznetsov", #w:amphibShips("red") == 1)
w.state.nodes.gali.platoons = { w.state.nodes.gali.platoons[1] }
local pk = w:amphibLaunched("blue", "lha", "gali", "batumi")
check("marines embark: a landing package with 2 platoons", pk and pk.kind == "amphib" and #pk.platoons == 2)
check("...and the ship needs 12 h before the next", #w:amphibShips("blue") == 0)
w:missionsTick()
local am, ic
for _, m in pairs(w.state.missions) do
  if m.type == "AMPHIB" then am = m end
  if m.type == "INTERCEPT" and m.target == pk.id then ic = m end
end
check("BLUE: AMPHIB escort mission", am ~= nil and am.side == "blue")
w.fogOfWar = false
w:missionsTick()
for _, m in pairs(w.state.missions) do if m.type == "INTERCEPT" and m.target == pk.id then ic = m end end
check("RED: INTERCEPT the landing helicopters", ic ~= nil and ic.label:find("landing", 1, true) ~= nil, ic and ic.label)
am.escortOk = true
w:packageArrived(pk.id)
local landed = false
for _, mv in pairs(w.state.moves) do if mv.to == "gali" and mv.side == "blue" then landed = true end end
check("ashore: the marines attack Gali (or took it)", landed or w.state.nodes.gali.side == "blue")
w:missionsTick()
check("escorted landing: AMPHIB done", w.state.missions[am.id].status == "done")

print(" Shipping")
local w2 = DCC.War.new(T, C, cfg, 32)
w2:tick()
w2.state.nodes.poti.supply = 1
w2.state.tick = X.shipping.everyTicks * 10
w2:planShipping()
local ship
for _, s in pairs(w2.state.shipping) do if s.side == "blue" then ship = s end end
check("a low port gets a supply ship", ship ~= nil and ship.port == "poti", ship and ship.port)
w2:missionsTick()
local strike, esc
for _, m in pairs(w2.state.missions) do
  if m.type == "SHIPSTRIKE" and m.target == ship.id then strike = m end
  if m.type == "SHIPESCORT" and m.target == ship.id then esc = m end
end
check("RED: SHIPSTRIKE, BLUE: SHIPESCORT", strike and strike.side == "red" and esc and esc.side == "blue")
local before = w2.state.nodes.poti.supply
for _ = 1, 200 do w2:shippingTick(); if not w2.state.shipping[ship.id] then break end end
check("it docks and unloads 40 SU", w2.state.nodes.poti.supply >= before + X.shipping.su - 0.01, w2.state.nodes.poti.supply)
esc.escortOk = true
w2:missionsTick()
check("...escort done, strike failed", w2.state.missions[esc.id].status == "done" and w2.state.missions[strike.id].status == "failed")
w2.state.tick = X.shipping.everyTicks * 20
w2.state.nodes.poti.supply = 1
w2:planShipping()
local s2 = next(w2.state.shipping) and w2.state.shipping[next(w2.state.shipping)]
check("a sunk ship: cargo lost", s2 and w2:shippingSunk(s2.id) and w2.state.nodes.poti.supply == 1)

print(" SCUDs")
local w3 = DCC.War.new(T, C, cfg, 33)
w3:tick()
local sc = w3:scuds()[1]
check("RED has SCUD launchers", sc and sc.side == "red" and #w3:scuds() == X.scud.launchers)
sc.last = w3.state.tick - X.scud.everyTicks
w3.newEvents = {}
w3:scudTick()
local fired
for _, ev in ipairs(w3.newEvents) do if ev.kind == "scud" then fired = ev end end
check("a launch: impact at a BLUE base", fired and w3.state.nodes[fired.node].side == "blue", fired and fired.text)
check("...the launch gives the launcher away", w3:isFresh("blue", "scud:" .. sc.id))
w3:missionsTick()
local scm
for _, m in pairs(w3.state.missions) do if m.type == "SCUD" then scm = m end end
check("BLUE: SCUD hunt mission", scm ~= nil and scm.side == "blue")
local spot = sc.node
for _ = 1, X.scud.scootTicks do w3.state.tick = w3.state.tick + 1 end
w3:scudTick()
check("shoot and scoot: it moves on", sc.node ~= spot)
w3:missionsTick()
check("...and the hunt goes cold", w3.state.missions[scm.id].status == "expired")
check("a killed launcher", w3:scudKilled(sc.id) and sc.status == "destroyed")

print(" Pop-ups")
local w4 = DCC.War.new(T, C, cfg, 34)
w4:tick()
local realChance = X.popup.chance
X.popup.chance = 1
w4:popupTick()
X.popup.chance = realChance
local pu
for _, p in pairs(w4.state.popups) do if p.side == "red" then pu = p end end
check("a RED pop-up threat near the front", pu ~= nil)
w4:missionsTick()
local none = true
for _, m in pairs(w4.state.missions) do if m.type == "POPUP" then none = false end end
check("unseen: not on the board", none)
w4:popupSeen(pu.id, "blue", "visual")
w4:missionsTick()
local pm
for _, m in pairs(w4.state.missions) do if m.type == "POPUP" and m.target == pu.id then pm = m end end
check("seen: POPUP mission", pm ~= nil)
w4:popupKilled(pu.id)
w4:missionsTick()
check("killed: done", w4.state.missions[pm.id].status == "done")

-- ===========================================================================
print("Bridge")
-- ===========================================================================
dofile(DCC_ROOT .. "/tests/dcs_mock.lua")
MOCK.writedir = (arg[1] or "/tmp") .. "/dcc_x3_" .. tostring(os.time()) .. "/"
os.execute('mkdir -p "' .. MOCK.writedir .. '"')
MOCK.buildAirbases(T)
MOCK.addTemplates()
for _, s in ipairs(T.naval) do
  local p = coord.LLtoLO(s.lat, s.lon, 0)
  MOCK.addShipGroup("DCC_NAVAL_" .. s.id, s.side == "blue" and 2 or 1, p.x, p.z, { s.ship })
end
for _, f in ipairs({ "dcc_persist", "dcc_dcs", "dcc_dcs_supply", "dcc_dcs_ops", "dcc_dcs_intel", "dcc_dcs_radar",
                     "dcc_dcs_world", "dcc_dcs_jtac", "dcc_dcs_public", "dcc_dcs_air", "dcc_dcs_ground",
                     "dcc_dcs_ext_air", "dcc_dcs_ext_ground", "dcc_dcs_ext2", "dcc_dcs_ext3", "dcc_dcs_armoury",
                     "dcc_main" }) do
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
viper.air = true

print(" Carrier air wing")
local realFind = B.findTemplate
B.findTemplate = function(name)                 -- the mock has no carrier templates: borrow the fighter's
  return realFind(name) or realFind(name:gsub("carriercap", "fighter"):gsub("carriertanker", "tanker"))
end
B.carrierWing()
check("CAP over the Stennis", B.x3.wing["cvn|cap"] and B.x3.wing["cvn|cap"].group ~= nil)
check("recovery tanker over the Stennis", B.x3.wing["cvn|tanker"] and B.x3.wing["cvn|tanker"].group ~= nil)
check("CAP over the Kuznetsov", B.x3.wing["kuz|cap"] and B.x3.wing["kuz|cap"].group ~= nil)
check("no carrier air wing on the Tarawa", B.x3.wing["lha|cap"] == nil)
local cvn = MOCK.groups["DCC_NAVAL_cvn"].units[1]
cvn.x = cvn.x + 30000
B.carrierWing()
local tg = MOCK.groups[B.x3.wing["cvn|tanker"].group]
check("the ship sails on: the tanker follows", math.abs(B.x3.wing["cvn|tanker"].center.x - cvn.x) < 1)
MOCK.killGroup(B.x3.wing["cvn|cap"].group)
B.carrierWing()
check("CAP shot down: a new one only after 30 min", B.x3.wing["cvn|cap"].group == nil)

print(" Shipping")
war.state.nodes.poti.supply = 1
war.state.tick = X.shipping.everyTicks * 50
war:planShipping()
local sid
for id, s in pairs(war.state.shipping) do if s.port == "poti" then sid = id end end
B.reconcileShipping()
check("the supply ship is on the sea", sid and B.x3.ships[sid] and MOCK.groups[B.x3.ships[sid].group] ~= nil)
MOCK.killGroup(B.x3.ships[sid].group)
B.reconcileShipping()
check("sunk in DCS: sunk in the war", war.state.shipping[sid] == nil and war.state.sunkShips[sid] ~= nil)

print(" Amphibious")
war.state.nodes.gali.platoons = { war.state.nodes.gali.platoons[1] }
local lha = MOCK.groups["DCC_NAVAL_lha"].units[1]
local gp = B.nodePos.gali
lha.x, lha.z = gp.x + 20000, gp.z - 20000
war.state.amphibReady = {}
local apk = B.launchAmphib("blue")
check("Tarawa launches a landing", apk ~= nil and B.packages[apk.id] ~= nil)
check("...the helicopters are in the air", apk and MOCK.groups["DCC_AMPHIB_" .. apk.id] ~= nil)

print(" SCUDs")
local b1 = war:scuds()[1]
b1.node = b1.node or "maykop"
B.reconcileScuds()
check("the launcher stands in the rear", B.x3.scuds[b1.id] ~= nil)
MOCK.killGroup(B.x3.scuds[b1.id].group)
B.reconcileScuds()
check("killed in DCS: destroyed in the war", b1.status == "destroyed")

print(" Pop-ups")
X.popup.chance = 1
war:popupTick()
X.popup.chance = realChance
local pid
for id, p in pairs(war.state.popups) do if p.side == "red" then pid = id end end
local ppos = B.popupPos(war.state.popups[pid])
viper.x, viper.z = ppos.x + 20000, ppos.z
B.reconcilePopups()
check("an aircraft 20 km away: the threat is on the map for real", B.x3.pops[pid] ~= nil)
check("...but nobody has seen it yet", not war:isFresh("blue", "popup:" .. pid))
viper.x, viper.z = ppos.x + 3000, ppos.z
B.reconcilePopups()
check("3 km, in sight: spotted", war:isFresh("blue", "popup:" .. pid))
MOCK.killGroup(B.x3.pops[pid].group)
B.reconcilePopups()
check("killed", war.state.popups[pid] == nil)

print(" A day")
B.findTemplate = realFind
for _ = 1, 288 do MOCK.advance(300) end
check("no script errors", errors == 0, errors)

print(string.format("\n%d passed, %d failed", passed, failed))
DCC_EXIT_CODE = failed == 0 and 0 or 1
