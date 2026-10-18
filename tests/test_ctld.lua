-- ============================================================================
-- CTLD integration tests: the real vendor/ctld/CTLD.lua running on the DCS
-- mock, driven through CTLD's own API (the calls its F10 menu makes).
--   python tools/run_lua.py tests/test_ctld.lua
-- ============================================================================

local passed, failed = 0, 0
local function check(name, cond, detail)
  if cond then passed = passed + 1; print("  ok   " .. name)
  else failed = failed + 1; print("  FAIL " .. name .. (detail and (" - " .. tostring(detail)) or "")) end
end

dofile(DCC_ROOT .. "/tests/dcs_mock.lua")
dofile(DCC_ROOT .. "/tests/ctld_shim.lua")
MOCK.writedir = (arg[1] or "/tmp") .. "/dcc_ctld_" .. tostring(os.time()) .. "/"
os.execute('mkdir -p "' .. MOCK.writedir .. '"')
local TH = DCC_THEATERS.Caucasus
MOCK.buildAirbases(TH)
MOCK.addTemplates()

-- what the mission's first DO SCRIPT does, then CTLD.lua itself
ctld = { dontInitialize = true }
local loaded, lerr = pcall(dofile, DCC_ROOT .. "/vendor/ctld/CTLD.lua")
for _, f in ipairs({ "dcc_persist", "dcc_dcs", "dcc_dcs_supply", "dcc_dcs_ops", "dcc_dcs_intel", "dcc_dcs_radar",
                     "dcc_dcs_world", "dcc_dcs_jtac", "dcc_dcs_public", "dcc_dcs_air", "dcc_dcs_ground",
                     "dcc_dcs_ctld", "dcc_dcs_ext_air", "dcc_dcs_ext_ground", "dcc_dcs_armoury", "dcc_main" }) do
  dofile(DCC_ROOT .. "/src/" .. f .. ".lua")
end

local errors = 0
DCC.util.log = function(fmt, ...)
  local msg = string.format(fmt, ...)
  if msg:find("ERROR") then errors = errors + 1; print("    " .. msg) end
end
local ctldErrors = 0
local baseInfo = env.info
env.info = function(m)
  if tostring(m):find("%[ERROR%]") then ctldErrors = ctldErrors + 1; print("    " .. m)
  elseif MOCK.ctldVerbose then print("    " .. m) end
end

print("Start-up")
check("CTLD.lua loads under Lua 5.1", loaded, lerr)
DCC.start()
local B, war = DCC.dcs, DCC.warObj
local BLUE, RED = 2, 1
check("CTLD integrated", B.ctldActive == true)
local zm, tm, cm = CTLDZoneManager.getInstance(), CTLDTroopManager.getInstance(), CTLDCrateManager.getInstance()
check("CTLD's JTAC switched off", ctld.gs("JTAC_LIMIT_BLUE") == 0 and ctld.gs("JTAC_dropEnabled") == false)
local jtacCrates = #cm:getJTACDescriptors(BLUE) + #cm:getJTACDescriptors(RED)
check("no JTAC crates on offer", jtacCrates == 0, jtacCrates)
local jtacTroops = 0
for _, t in ipairs(tm._templates) do if (t.jtac or 0) > 0 then jtacTroops = jtacTroops + 1 end end
check("no JTAC troop teams", jtacTroops == 0, jtacTroops)
local supplyDesc = cm:findDescriptorByWeight(DCC.config.ctld.supplyWeight)
check("a Supply crate in CTLD's catalogue", supplyDesc and supplyDesc.dccSupply == true)

print("Zones follow the bases")
local kz = zm:getLogisticZone("Kutaisi")
check("Kutaisi (BLUE) has a BLUE logistic zone", kz and kz.coalition == BLUE)
local tz = zm:getTroopZone("Kutaisi")
check("...and a BLUE troop pickup zone", tz and tz.coalition == BLUE and tz:hasPickup())
local rz = zm:getLogisticZone(war:nodeName("sochi"))
check("Sochi (RED) has a RED zone", rz and rz.coalition == RED)

-- a player helicopter on the ground at Kutaisi
local kp = B.nodePos.kutaisi
local heli = MOCK.spawnPlayer(BLUE, "UH-1H", kp.x + 100, kp.z, "Pedro", true)
local p = B.players[heli:getName()]
MOCK.advance(5)                                      -- CTLD builds menus on its own scheduler
check("the pilot is registered", p ~= nil)
local cargoMenu, ctldMenu, missions = false, false, false
for _, item in ipairs(MOCK.groupMenus[p.gid] or {}) do
  if item.name == "Cargo" then cargoMenu = true end
  if item.name == "Missions" then missions = true end
  if tostring(item.name):find("CTLD") then ctldMenu = true end
end
check("no DCC Cargo submenu, the Missions menu is still there", not cargoMenu and missions)
check("CTLD built its own menu for the helicopter", ctldMenu)

print("Crates cost supply")
local ns = war.state.nodes.kutaisi
ns.supply = 50
local crate = cm:spawnCrate(supplyDesc, { x = kp.x + 120, y = 0, z = kp.z }, BLUE, heli:getName(), "menu_ctld")
check("crate requested at Kutaisi", crate ~= nil)
check("Kutaisi paid 10 SU", math.abs(ns.supply - 40) < 0.01, ns.supply)
ns.supply = 5
local none = cm:spawnCrate(supplyDesc, { x = kp.x + 130, y = 0, z = kp.z }, BLUE, heli:getName(), "menu_ctld")
check("a dry base refuses the crate", none == nil and math.abs(ns.supply - 5) < 0.01)
ns.supply = 50

print("Supply crate delivered")
-- a friendly town to fly it to
local dest
for _, id in ipairs(war.T.order) do
  if war.state.nodes[id].side == "blue" and id ~= "kutaisi" and war.T.nodes[id].kind == "town" then dest = id; break end
end
cm:loadCrate(crate.crateName, heli)
check("crate on board", crate:isOnGround() == false)
local dp = B.nodePos[dest]
heli.x, heli.z = dp.x + 200, dp.z
local before = war.state.nodes[dest].supply
local farpSU = war.state.nodes[dest].farpSU or 0
cm:unloadCrate(crate.crateName, { x = dp.x + 210, y = 0, z = dp.z }, "menu_ctld")
check("unloaded at an own base: supply delivered", war.state.nodes[dest].supply > before,
  before .. " -> " .. war.state.nodes[dest].supply)
check("...towards a FARP at the town", (war.state.nodes[dest].farpSU or 0) > farpSU or war:farpAt(dest))
check("...and the crate is used up", cm:getCrateByName(crate.crateName) == nil)
check("counted as a helicopter delivery (completes LOGISTICS)", war.state.stats.delivered.blue >= DCC.config.ctld.supplyCrateSU)

print("Troops: pick up, reinforce")
heli.x, heli.z = kp.x + 100, kp.z
local std = tm:_findTemplate("Standard Group")
local n0 = #ns.platoons
local okEmbark = tm:embarkFromTroopZone(heli, tz, std)
check("troops board at Kutaisi", okEmbark == true)
check("one platoon left the garrison", #ns.platoons == n0 - 1, #ns.platoons)
check("...and rides with the pilot", #p.troops == 1 and war.state.carried[p.troops[1]] ~= nil)
local pid1 = p.troops[1]
heli.x, heli.z = dp.x + 200, dp.z
local d0 = #war.state.nodes[dest].platoons
check("unloaded at an own town", tm:disembark(heli) == true)
check("the platoon joins that garrison", #war.state.nodes[dest].platoons == d0 + 1 and war.state.platoons[pid1].node == dest)
check("nothing left on board", #p.troops == 0 and war.state.carried[pid1] == nil)

print("Troops: air assault")
heli.x, heli.z = kp.x + 100, kp.z
tm:embarkFromTroopZone(heli, tz, std)
local pid2 = p.troops[1]
local enemy
for _, id in ipairs(war.T.order) do
  if war.state.nodes[id].side == "red" and war.T.nodes[id].kind == "town" then enemy = id; break end
end
local ep = B.nodePos[enemy]
heli.x, heli.z = ep.x + 300, ep.z
tm:disembark(heli)
local assault
for _, mv in pairs(war.state.moves) do if mv.airAssault and mv.to == enemy then assault = mv end end
check("unloaded at an enemy town: air assault", assault ~= nil and war.state.platoons[pid2].move == assault.id)

print("Troops: in the field")
heli.x, heli.z = kp.x + 100, kp.z
tm:embarkFromTroopZone(heli, tz, std)
local pid3 = p.troops[1]
heli.x, heli.z = kp.x + 30000, kp.z + 30000          -- nowhere near a base
tm:disembark(heli)
local fieldName = next(B.ctld.field)
check("troops in the field are tracked", fieldName ~= nil and B.ctld.field[fieldName][1] == pid3)
check("...still counted as carried", war.state.carried[pid3] ~= nil)
check("picked up again from the field", tm:embarkFromField(heli) == true and #p.troops == 1 and p.troops[1] == pid3)
check("...no longer in the field", B.ctld.field[fieldName] == nil)
tm:disembark(heli)
fieldName = next(B.ctld.field)
MOCK.killGroup(fieldName)
B.ctldPollField()
check("killed in the field: platoon lost", war.state.platoons[pid3] == nil and B.ctld.field[fieldName] == nil)

print("Big lifts")
heli.x, heli.z = kp.x + 100, kp.z
local big = tm:_findTemplate("3x - Standard Groups")
while #ns.platoons > 2 do war:destroyPlatoon(ns.platoons[#ns.platoons]) end
check("a base with 1 platoon to spare refuses a 3-platoon lift", tm:embarkFromTroopZone(heli, tz, big) == false and #ns.platoons == 2)
for _ = 1, 4 do war:newPlatoon("blue", "MECH_PLT", "kutaisi") end
local chinook = MOCK.spawnPlayer(BLUE, "CH-47Fbl1", kp.x + 150, kp.z, "Hank", true)
local pc = B.players[chinook:getName()]
local okBig = tm:embarkFromTroopZone(chinook, tz, big)
check("a Chinook takes 3 platoons for '3x - Standard Groups'", okBig and #pc.troops == 3 and #ns.platoons == 3,
  tostring(okBig) .. " " .. #pc.troops)

print("Helicopter lost with troops")
tm:embarkFromTroopZone(heli, tz, std)
local pid4 = p.troops[1]
MOCK.fire({ id = world.event.S_EVENT_DEAD, initiator = heli })
heli.alive = false
MOCK.fire({ id = world.event.S_EVENT_CRASH, initiator = heli })
check("platoon lost with the helicopter", pid4 ~= nil and war.state.platoons[pid4] == nil and war.state.carried[pid4] == nil)

print("Capture moves the zones")
local town = dest
war.state.nodes[town].side = "red"
B.opsPoll()
local tzz = zm:getLogisticZone(war:nodeName(town))
check("captured town: its zone now RED", tzz and tzz.coalition == RED)
war.state.nodes[town].side = "blue"
B.opsPoll()

print("FOB and AA systems")
local ed = EventDispatcher.getInstance()
local town2
for _, id in ipairs(war.T.order) do
  if war.state.nodes[id].side == "blue" and war.T.nodes[id].kind == "town" and not war:farpAt(id) then town2 = id; break end
end
local tp = B.nodePos[town2]
ed:publish("OnFOBDeployed", { fob = { fobId = 1, name = "FOB #1", coalitionId = BLUE },
  position = { x = tp.x + 1500, y = 0, z = tp.z } })
check("FOB next to a town: the town is a FARP", war:farpAt(town2))
ed:publish("OnFOBDestroyed", { fob = { fobId = 1, name = "FOB #1", coalitionId = BLUE }, position = tp })
check("FOB destroyed: FARP gone", not war:farpAt(town2))
local f0 = ns.fort
ns.fort = 0
ed:publish("OnAASystemDeployed", { systemName = "HAWK", groupName = "x", coalition = BLUE,
  position = { x = kp.x + 800, y = 0, z = kp.z } })
check("AA system at an own base: dug in one level", ns.fort == 1)

print("Crate vehicles join the base")
local function unpackAt(unitType, x, z)
  local d = cm:findDescriptorByUnitType(unitType)
  local before = {}
  for n in pairs(MOCK.groups) do before[n] = true end
  cm:_spawnUnpacked(d, { x = x, y = 0, z = z }, BLUE, 80, nil)
  for n in pairs(MOCK.groups) do if not before[n] then return d, n end end
  return d, nil
end
local np = #ns.platoons
local abrams, ag = unpackAt("M-1 Abrams", kp.x + 400, kp.z)
local newest = war.state.platoons[ns.platoons[#ns.platoons]]
check("an Abrams unpacked at Kutaisi joins its garrison", #ns.platoons == np + 1 and newest.role == "ARMOR_PLT")
check("...at the strength its crates paid for (4 crates = 0.67)", math.abs(newest.health - 40 / 60) < 0.01, newest.health)
check("the CTLD vehicle stays a minute", ag and MOCK.groups[ag] ~= nil)
MOCK.advance(DCC.config.ctld.joinDelay + 5)
check("...then leaves the map (it is in the garrison now)", MOCK.groups[ag] == nil)
local np2 = #ns.platoons
local _, fg = unpackAt("M1043 HMMWV Armament", kp.x + 30000, kp.z + 30000)
check("unpacked in the field: stays a CTLD unit, no platoon", #ns.platoons == np2 and fg and MOCK.groups[fg] ~= nil)
local bat = war:batteries("blue")
local nb = #bat
for _, b in ipairs(bat) do b.status = "up" end
unpackAt("M-109", kp.x + 500, kp.z)
check("a howitzer unpacked at a base: a new artillery battery there", #bat == nb + 1 and bat[#bat].node == "kutaisi")
ns.supply = 10
local sup0 = ns.supply
unpackAt("M 818", kp.x + 600, kp.z)
check("an ammo truck unpacked at a base: its load becomes supply", ns.supply > sup0, sup0 .. " -> " .. ns.supply)
-- a whole vehicle carried by a Chinook and set down at an own base
local npv = #ns.platoons
coalition.addGroup(80, Group.Category.GROUND, { name = "CTLD_VEH_test", units = { { name = "CTLD_VEH_test",
  type = "M1045 HMMWV TOW", x = kp.x + 300, y = kp.z + 300 } } })
ed:publish("OnVehicleUnloaded", { dcsUnitObject = MOCK.groups["CTLD_VEH_test"].units[1], vehicleType = "M1045 HMMWV TOW",
  position = { x = kp.x + 300, y = 0, z = kp.z + 300 } })
check("a vehicle flown in whole joins the garrison too", #ns.platoons == npv + 1)

print("Chinooks carry light vehicles only")
local caps = ctld.gs("capabilitiesByType")["CH-47Fbl1"]
local wv = DCC.config.ctld.wholeVehicles
check("BLUE Chinook: only the Humvees", table.concat(caps.loadableVehiclesBLUE, ",") == table.concat(wv.blue, ","),
  table.concat(caps.loadableVehiclesBLUE, ","))
check("RED: the UAZ only (BRDM-2, Tigr, BTR-D are ~7-8 t)", table.concat(caps.loadableVehiclesRED, ",") == "UAZ-469")
check("UAZ and Tigr in CTLD's crate list for RED", cm:findDescriptorByTypeName("UAZ-469") ~= nil
  and cm:findDescriptorByTypeName("Tigr_233036") ~= nil)
local wts = ctld.gs("groundVehicleWeights")
check("CTLD knows the real weights (Tigr 7.2 t, too heavy for a Mi-8)", wts["Tigr_233036"] == 7200 and wts["UAZ-469"] == 1600)

print("Vehicles into an air assault")
local enemy2
for _, id in ipairs(war.T.order) do
  if war.state.nodes[id].side == "red" and war.T.nodes[id].kind == "town" and id ~= enemy then enemy2 = id; break end
end
local e2 = B.nodePos[enemy2]
coalition.addGroup(80, Group.Category.GROUND, { name = "CTLD_VEH_raid", units = { { name = "CTLD_VEH_raid",
  type = "M1043 HMMWV Armament", x = e2.x + 400, y = e2.z } } })
ed:publish("OnVehicleUnloaded", { dcsUnitObject = MOCK.groups["CTLD_VEH_raid"].units[1], vehicleType = "M1043 HMMWV Armament",
  position = { x = e2.x + 400, y = 0, z = e2.z } })
local raid
for _, mv in pairs(war.state.moves) do if mv.airAssault and mv.to == enemy2 and mv.side == "blue" then raid = mv end end
check("a Humvee set down at an enemy town attacks it", raid ~= nil and #raid.platoons == 1)
check("...and stays on the map to fight", MOCK.groups["CTLD_VEH_raid"] ~= nil)
-- troops landed at the same town join the same assault
local heli2 = MOCK.spawnPlayer(BLUE, "UH-1H", kp.x + 120, kp.z, "Rita", true)
for _ = 1, 3 do war:newPlatoon("blue", "MECH_PLT", "kutaisi") end
tm:embarkFromTroopZone(heli2, tz, std)
heli2.x, heli2.z = e2.x + 300, e2.z
tm:disembark(heli2)
local n = 0
for _, mv in pairs(war.state.moves) do if mv.airAssault and mv.to == enemy2 and mv.side == "blue" then n = n + 1 end end
check("troops landed there fight in the same assault", n == 1 and raid and #raid.platoons == 2, raid and #raid.platoons)

print("Engineers and minefields")
local kitDesc
for _, list in pairs(ctld.gs("spawnableCrates")) do
  for _, c in ipairs(list) do if c.dccBridge then kitDesc = c end end
end
check("a Bridge kit crate in CTLD's catalogue", kitDesc ~= nil)
war:bridgeDown("kutaisi", "zestaponi")
local ka, kb = B.nodePos.kutaisi, B.nodePos.zestaponi
local bpos = { x = (ka.x + kb.x) / 2, z = (ka.z + kb.z) / 2 }
war.bridges = { { a = "kutaisi", b = "zestaponi", pos = bpos } }
local k1 = cm:spawnCrate(kitDesc, { x = bpos.x + 300, y = 0, z = bpos.z }, BLUE, nil, "crate_spawn")
cm:unpackCrate(k1.crateName, heli2)
check("one kit is not enough", war:roadClosed("kutaisi", "zestaponi"))
cm:spawnCrate(kitDesc, { x = bpos.x + 310, y = 0, z = bpos.z }, BLUE, nil, "crate_spawn")
cm:unpackCrate(k1.crateName, heli2)
check("two kits next to the downed bridge: road reopened", not war:roadClosed("kutaisi", "zestaponi"))
local mf = CTLDSceneManager.getInstance():getModel("mineField")
local layer = MOCK.spawnPlayer(BLUE, "UH-1H", bpos.x + 200, bpos.z, "Sapper", true)
pcall(mf.steps[1].func, { unit = layer })
local mined = false
for k, m in pairs(war.state.mines) do if m.side == "blue" and k:find("kutaisi") then mined = true end end
check("a CTLD minefield next to a road mines that road", mined)

print("FARP kit (Chinook / Mi-8)")
local farpDesc
for _, list in pairs(ctld.gs("spawnableCrates")) do
  for _, c in ipairs(list) do if c.dccFarp then farpDesc = c end end
end
check("a FARP kit crate in CTLD's catalogue", farpDesc ~= nil)
local town
for _, id in ipairs(war.T.order) do
  if war.state.nodes[id].side == "blue" and war:canHaveFarp(id) and not war:farpAt(id) and B.nodePos[id] then
    town = id; break
  end
end
local kpos = B.nodePos.kutaisi
war.state.nodes.kutaisi.supply = 200
local hueyK = MOCK.spawnPlayer(BLUE, "UH-1H", kpos.x + 100, kpos.z, "Kit Huey", true)
local refused = cm:spawnCrate(farpDesc, { x = kpos.x + 120, y = 0, z = kpos.z }, BLUE, hueyK:getName(), "menu_ctld")
check("a Huey cannot load a FARP kit", refused == nil)
local hook = MOCK.spawnPlayer(BLUE, "CH-47Fbl1", kpos.x + 100, kpos.z, "Kit Hook", true)
local s0 = war.state.nodes.kutaisi.supply
local kit = cm:spawnCrate(farpDesc, { x = kpos.x + 130, y = 0, z = kpos.z }, BLUE, hook:getName(), "menu_ctld")
check("a Chinook can, and it costs 30 SU", kit ~= nil and math.abs((s0 - war.state.nodes.kutaisi.supply) - 30) < 0.01,
  s0 - war.state.nodes.kutaisi.supply)
-- unpacked in the middle of nowhere: nothing
kit.position = { x = kpos.x + 90000, y = 0, z = kpos.z + 90000 }
cm:unpackCrate(kit.crateName, hook)
check("far from a town: no FARP", not war:farpAt(town))
local tp = B.nodePos[town]
kit.position = { x = tp.x + 1500, y = 0, z = tp.z }
B.ctldCrateDown(kit, kit.position)
check("set down 1.5 km from " .. town .. ": it is a FARP now", war:farpAt(town) and war.state.nodes[town].farp.how == "kit")
local mk = MOCK.spawnPlayer(BLUE, "Mi-8MT", kpos.x + 100, kpos.z, "Kit Hip", true)
check("a Mi-8 can lift one too", cm:spawnCrate(farpDesc, { x = kpos.x + 140, y = 0, z = kpos.z }, BLUE, mk:getName(),
  "menu_ctld") ~= nil)

print("A day of war with CTLD")
for _ = 1, 288 do MOCK.advance(300) end
check("no DCC script errors", errors == 0, errors)
check("no CTLD errors", ctldErrors == 0, ctldErrors)

print(string.format("\n%d passed, %d failed", passed, failed))
DCC_EXIT_CODE = failed == 0 and 0 or 1
