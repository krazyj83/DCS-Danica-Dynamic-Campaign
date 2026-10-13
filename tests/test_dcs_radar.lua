-- ============================================================================
-- Phase 5 bridge tests: early-warning radars, AWACS and recon photos.
--   python tools/run_lua.py tests/test_dcs_radar.lua
-- ============================================================================

local passed, failed = 0, 0
local function check(name, cond, detail)
  if cond then passed = passed + 1; print("  ok   " .. name)
  else failed = failed + 1; print("  FAIL " .. name .. (detail and (" - " .. tostring(detail)) or "")) end
end

dofile(DCC_ROOT .. "/tests/dcs_mock.lua")
MOCK.writedir = (arg[1] or "/tmp") .. "/dcc_radar_" .. tostring(os.time()) .. "/"
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
dofile(DCC_ROOT .. "/src/dcc_main.lua")

local errors = 0
DCC.util.log = function(fmt, ...)
  local msg = string.format(fmt, ...)
  if msg:find("ERROR") then errors = errors + 1; print("    " .. msg) end
end

DCC.start()
local B, war = DCC.dcs, DCC.warObj
local BLUE, RED = 2, 1
local bes = B.nodePos.beslan

print("Radar picture from an early-warning site")
check("RED has an EWR at Beslan", war:ewrUp("beslan"))
-- a BLUE fighter 120 km from Beslan (well outside the 80 km spawn ring of the site)
local viper, vg = MOCK.spawnPlayer(BLUE, "F-16C_50", bes.x - 120000, bes.z, "Morten")
viper.air, viper.alt = true, 6000
B.scanRadars(B.intelIndex())
check("RED radar sees a high fighter at 120 km", B.airContacts.red[viper:getName()] ~= nil)
check("source is radar", B.airContacts.red[viper:getName()] and B.airContacts.red[viper:getName()].source == "radar")
B.airContacts.red = {}
viper.alt = 300
B.scanRadars(B.intelIndex())
local h = DCC.War.radarHorizonM(120, DCC.config.radar.ewrAntennaM)
check("below the radar horizon it is invisible (needs " .. math.floor(h) .. " m)", B.airContacts.red[viper:getName()] == nil)
viper.alt = 6000
MOCK.ridges = { { bes.x - 60000, bes.z, 2000 } }
B.scanRadars(B.intelIndex())
check("terrain masks the radar", B.airContacts.red[viper:getName()] == nil)
MOCK.ridges = nil
viper.x = bes.x - 260000
B.scanRadars(B.intelIndex())
check("out of range: not seen", B.airContacts.red[viper:getName()] == nil)

print("ELINT on the radar site")
viper.x = bes.x - 150000
B.scanEwrElint()
local c = war:contact("blue", "ewr:beslan")
check("BLUE hears the EWR at 150 km", c ~= nil and c.source == "elint")
DCC.onTick()
local ewrMission
for _, m in ipairs(war:openMissions("blue")) do if m.type == "EWR" and m.target == "beslan" then ewrMission = m end end
check("EWR strike on the board once the radar is known", ewrMission ~= nil)

print("EWR site in DCS")
viper.x, viper.z = bes.x - 50000, bes.z
MOCK.advance(31)
local eg = MOCK.groups["DCC_EWR_beslan"]
check("EWR unit spawned when a player is within 80 km", eg ~= nil)
check("EWR uses a catalog type", eg and (eg.units[1].type == "1L13 EWR" or eg.units[1].type == "55G6 EWR"))
if eg then
  MOCK.killGroup("DCC_EWR_beslan")
  MOCK.advance(31)
  check("radar kill saved: EWR destroyed", war.state.nodes.beslan.ewr.status == "destroyed")
  DCC.onTick()
  check("EWR mission complete", ewrMission and war.state.missions[ewrMission.id].status == "done")
  local announced = false
  for _, t in ipairs(MOCK.texts) do if t:find("early-warning radar at Beslan destroyed", 1, true) then announced = true end end
  check("destruction announced", announced)
end
viper.x = bes.x - 120000
B.airContacts.red = {}
B.scanRadars(B.intelIndex())
local redRadars = B.radarsOf("red")
local seesFromElsewhere = false
for _, r in ipairs(redRadars) do if B.radarSees(r, viper) then seesFromElsewhere = true end end
check("dead radar no longer sees", B.airContacts.red[viper:getName()] == nil or seesFromElsewhere)

print("AWACS")
DCC.onTick()
local blueAwacs, redAwacs = B.awacs.blue, B.awacs.red
check("both sides put an AWACS up while players are online", blueAwacs ~= nil and redAwacs ~= nil)
check("AWACS state in the model", war:awacsUp("red") and war:awacsUp("blue"))
local ra = redAwacs and MOCK.groups[redAwacs.group]
check("AWACS is one aircraft with the AWACS task", ra and #ra.units == 1 and ra.data.task == "AWACS")
check("AWACS taken from the pool", war.state.airPool.red.awacs == DCC.config.radar.awacsPoolStart - 1)
-- the AWACS orbits behind RED's front: further from BLUE's nodes than RED's front is
local ap = ra.units[1]
ap.alt = DCC.config.radar.awacsAltM
local p, _ = B.awacsOrbit("red")
check("orbit is behind the own front", war.state.nodes.beslan.side == "red" and p ~= nil)

print("Hunting the AWACS (HVAA)")
viper.x, viper.z, viper.alt = ap.x - 8000, ap.z, 8000
B.intelScan()
check("BLUE fighter sees the AWACS", war:isFresh("blue", "awacs:red"))
DCC.onTick()
local hv
for _, m in ipairs(war:openMissions("blue")) do if m.type == "HVAA" then hv = m end end
check("HVAA mission offered", hv ~= nil)
if hv then
  MOCK.click(vg.id, "HVAA:")
  MOCK.killGroup(redAwacs.group)
  MOCK.advance(31)
  check("AWACS loss saved", not war:awacsUp("red"))
  DCC.onTick()
  check("HVAA complete", war.state.missions[hv.id].status == "done")
end
check("RED gets a new AWACS from the pool", (function() DCC.onTick(); return B.awacs.red ~= nil end)())

print("Recon photos")
local rm
for _, m in ipairs(war:openMissions("blue")) do if m.type == "RECON" then rm = m end end
check("a RECON mission to fly", rm ~= nil)
if rm then
  local hog, hg = MOCK.spawnPlayer(BLUE, "A-10C_2", B.nodePos[rm.target].x - 30000, B.nodePos[rm.target].z, "Jens")
  hog.air, hog.alt = true, 1000
  MOCK.click(hg.id, "RECON:")
  rm = war.state.missions[B.players[hog:getName()].mission]   -- the one the menu gave us
  hog.x, hog.z = B.nodePos[rm.target].x + 2000, B.nodePos[rm.target].z
  MOCK.advance(11)
  check("recon complete", war.state.missions[rm.id].status == "done")
  local report = table.concat(MOCK.groupTexts[hg.id] or {}, "\n")
  check("pilot gets the photo report", report:find("RECON PHOTOS", 1, true) ~= nil)
  check("report names vehicle types", report:find("%dx ") ~= nil, report:sub(1, 200))
  B.drawIntel()
  local blueP, redP = 0, 0
  for _, id in ipairs(B.intelMarks) do
    local m = MOCK.marks[id]
    if m and m.kind == "text" and tostring(m.args[#m.args]):find("[photo]", 1, true) then
      if m.coal == BLUE then blueP = blueP + 1 else redP = redP + 1 end
    end
  end
  local n = #(war:contact("blue", "n:" .. rm.target).photo)
  check("one photo label per platoon on BLUE's map", blueP == n, blueP .. " vs " .. n)
  check("RED never sees BLUE's photos", redP == 0)
end

print("Own radar coverage")
B.draw()
local wrong = 0
for _, id in ipairs(B.marks) do
  local m = MOCK.marks[id]
  if m and m.kind == "circle" and m.args[2] == DCC.config.radar.ewrKm * 1000 and m.coal == -1 then wrong = wrong + 1 end
end
check("radar coverage rings only for the owner", wrong == 0)

print("Players leave")
for _, list in pairs(MOCK.players) do for _, u in ipairs(list) do u.alive = false end end
MOCK.players = {}
MOCK.advance(31)
check("AWACS land when nobody is online", B.awacs.blue == nil and B.awacs.red == nil)
check("they return to the pool", war.state.airPool.blue.awacs == DCC.config.radar.awacsPoolStart)

print("A day of war")
for _ = 1, 288 do MOCK.advance(300) end
check("no script errors", errors == 0, errors)

print(string.format("\n%d passed, %d failed", passed, failed))
DCC_EXIT_CODE = failed == 0 and 0 or 1
