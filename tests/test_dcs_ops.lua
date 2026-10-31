-- ============================================================================
-- Phase 3 bridge tests against tests/dcs_mock.lua: fly every mission type.
--   python tools/run_lua.py tests/test_dcs_ops.lua
-- ============================================================================

local passed, failed = 0, 0
local function check(name, cond, detail)
  if cond then passed = passed + 1; print("  ok   " .. name)
  else failed = failed + 1; print("  FAIL " .. name .. (detail and (" - " .. tostring(detail)) or "")) end
end

dofile(DCC_ROOT .. "/tests/dcs_mock.lua")
MOCK.writedir = (arg[1] or "/tmp") .. "/dcc_ops_" .. tostring(os.time()) .. "/"
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
dofile(DCC_ROOT .. "/src/dcc_dcs_ctld.lua")
dofile(DCC_ROOT .. "/src/dcc_dcs_ext_air.lua")
dofile(DCC_ROOT .. "/src/dcc_dcs_ext_ground.lua")
dofile(DCC_ROOT .. "/src/dcc_dcs_ext2.lua")
dofile(DCC_ROOT .. "/src/dcc_dcs_ext3.lua")
dofile(DCC_ROOT .. "/src/dcc_dcs_ext4.lua")
dofile(DCC_ROOT .. "/src/dcc_dcs_armoury.lua")
dofile(DCC_ROOT .. "/src/dcc_main.lua")

local errors = 0
local realLog = DCC.util.log
DCC.util.log = function(fmt, ...)
  local msg = string.format(fmt, ...)
  if msg:find("ERROR") then errors = errors + 1; print("    " .. msg) end
end

DCC.start()
local B, war = DCC.dcs, DCC.warObj
war.fogOfWar = false          -- phase-3 checks: god's-eye board (fog has its own test file)
war:tick(); war:tick()          -- fill the boards (CAP needs a main effort)
B.opsTick()

local function pos(id) return B.nodePos[id] end
local function at(u, id, dx, dz) local p = pos(id); u.x, u.z = p.x + (dx or 0), p.z + (dz or 0) end
local function rec(u) return B.players[u:getName()] end
local function missionOf(u) local p = rec(u); return p and p.mission and war.state.missions[p.mission] end

print("Players and the mission board")
local kp = pos("kutaisi")
local viper, vg = MOCK.spawnPlayer(2, "F-16C_50", kp.x, kp.z, "Morten")
check("player registered on birth", rec(viper) ~= nil and rec(viper).side == "blue")
check("pilot record created", DCC.pilots.data.pilots["Morten"] ~= nil)
local items = table.concat(MOCK.menuItems(vg.id), " | ")
check("menu lists SEAD for an F-16", items:find("SEAD:", 1, true) ~= nil, items)
check("menu has record and leaderboard", items:find("My pilot record", 1, true) and items:find("Leaderboard", 1, true))
check("no cargo menu for a fighter", items:find("Load supply crate", 1, true) == nil)
local hog, hg = MOCK.spawnPlayer(2, "A-10C_2", kp.x, kp.z, "Jens")
local hogItems = table.concat(MOCK.menuItems(hg.id), " | ")
check("A-10 sees no SEAD or CAP", hogItems:find("SEAD:", 1, true) == nil and hogItems:find("CAP:", 1, true) == nil)

print("SEAD / DEAD")
check("take SEAD from the menu", MOCK.click(vg.id, "SEAD:"))
local m = missionOf(viper)
check("mission assigned", m ~= nil and m.type == "SEAD")
check("briefing has coordinates", MOCK.lastGroupText(vg.id):find("Target:", 1, true) ~= nil)
check("target marked on the F10 map for the group", MOCK.countMarks("groupmark") >= 1)
local samNode = m.target
at(viper, samNode, 30000, 0)
viper.air = true
MOCK.advance(31)
local sg = MOCK.groups["DCC_SAM_" .. samNode]
check("SAM site spawned when a player is within 80 km", sg ~= nil)
if sg then
  for _, u in ipairs(sg.units) do if u.name:find("_r%d+$") then u.alive = false end end
  MOCK.advance(31)
  check("radar kill read back: SAM suppressed", war.state.nodes[samNode].sam.status == "suppressed")
  DCC.onTick()
  check("SEAD mission complete", war.state.missions[m.id].status == "done")
  check("points wait while the pilot is airborne", (DCC.pilots.data.pilots["Morten"].byType.SEAD or 0) == 0)
  -- fly home and land at Kutaisi
  local kp2 = pos("kutaisi")
  viper.x, viper.z, viper.air = kp2.x, kp2.z, false
  MOCK.fire({ id = world.event.S_EVENT_LAND, initiator = viper })
  check("mission credited to the pilot after landing", (DCC.pilots.data.pilots["Morten"].byType.SEAD or 0) == 1)
  viper.air = true
end

print("STRIKE")
check("take STRIKE", MOCK.click(hg.id, "STRIKE:"))
local ms = missionOf(hog)
at(hog, ms.target, 5000, 0)
hog.air = true
MOCK.advance(31)
local statics = 0
for name in pairs(MOCK.statics) do if name:find("DCC_INF_" .. ms.target, 1, true) then statics = statics + 1 end end
check("strike buildings spawned near players", statics == war.state.nodes[ms.target].infra.total, statics)
local victim
for name, s in pairs(MOCK.statics) do if name:find("DCC_INF_" .. ms.target, 1, true) then victim = s; break end end
victim.alive = false
MOCK.advance(31)
check("destroyed building read back", war:infraLost(ms.target) == 1)
DCC.onTick()
check("STRIKE mission complete", war.state.missions[ms.id].status == "done")

print("Kill credit")
MOCK.fire({ id = world.event.S_EVENT_KILL, initiator = hog, target = victim })
check("building kill credited", DCC.pilots.data.pilots["Jens"].kills_structure == 1)
local truck = { name = "DCC_c12_1", getName = function(s) return s.name end,
                getDesc = function() return { category = Unit.Category.GROUND_UNIT } end }
MOCK.fire({ id = world.event.S_EVENT_KILL, initiator = hog, target = truck })
check("convoy truck kill credited", DCC.pilots.data.pilots["Jens"].kills_convoy == 1)

print("RECON")
DCC.onTick()
local reconLabel
for _, mm in ipairs(war:openMissions("blue")) do if mm.type == "RECON" then reconLabel = mm.label; break end end
check("RECON offered", reconLabel ~= nil)
MOCK.click(vg.id, "RECON:")
local mr = missionOf(viper)
at(viper, mr.target, 3000, 0)
viper.alt = 1500
MOCK.advance(11)
check("low pass completes RECON", war.state.missions[mr.id].status == "done")
check("intel recorded for BLUE", war.state.intel.blue[mr.target] ~= nil)
B.draw()
local intelText = false
for _, mk in pairs(MOCK.marks) do
  if mk.kind == "text" and tostring(mk.args[#mk.args]):find("Recon", 1, true) then intelText = true end
end
check("intel drawn on BLUE's map", intelText)

print("CAP")
local capOk = MOCK.click(vg.id, "CAP:")
check("CAP offered", capOk)
if capOk then
  local mc = missionOf(viper)
  at(viper, mc.target, 10000, 0)
  viper.alt = 7000
  MOCK.advance(21 * 60)
  check("20 min on station completes CAP", war.state.missions[mc.id].status == "done")
  check("air superiority over the main effort", war:hasAirCover("blue", mc.target))
end

print("AI air")
local before = war.state.airPool.red.fighter
B.sorties = {}
B.planAir()
local airGroups = MOCK.countGroups("DCC_AIR_")
check("AI sorties launched while players fly", airGroups >= 2, airGroups)
local redCap
for name, so in pairs(B.sorties) do                      -- a live RED CAP sortie (there may be several now)
  if so.side == "red" and so.kind == "CAP" and MOCK.groups[name] then redCap = MOCK.groups[name] end
end
check("RED CAP cloned from its template", redCap ~= nil and redCap.units[1].type == "MiG-29S")
check("cloned group keeps the template loadout", redCap and redCap.data.units[1].payload.pylons[1] ~= nil)
local redFighterSorties = 0
for _, so in pairs(B.sorties) do if so.side == "red" and so.role == "fighter" then redFighterSorties = redFighterSorties + 1 end end
check("pool pays for each sortie", war.state.airPool.red.fighter == before - 2 * redFighterSorties,
  war.state.airPool.red.fighter .. " after " .. redFighterSorties .. " sorties")
local orbit = redCap and redCap.data.route.points[2].task.params.tasks
check("CAP waypoint has engage + orbit tasks", orbit and orbit[1].id == "EngageTargets" and orbit[2].id == "Orbit")
redCap.units[1].alive = false
B.pollSorties()
check("AI loss read back", war.state.stats.airLost.red == 1)
MOCK.advance(3700)
check("sortie ends after its time", MOCK.groups[redCap.name] == nil)   -- (the pool keeps changing: packages fly too)

print("CSAR")
local senaki = pos("senaki")
local down = MOCK.spawnPlayer(2, "F-16C_50", senaki.x + 20000, senaki.z + 20000, "Lars")
MOCK.fire({ id = world.event.S_EVENT_EJECTION, initiator = down })
local did = next(war.state.downed)
check("ejection creates a downed pilot", did ~= nil)
check("downed pilot on the ground in DCS", MOCK.groups["DCC_CSAR_" .. tostring(did)] ~= nil)
check("ejection counted on the record", DCC.pilots.data.pilots["Lars"].ejections == 1)
local huey, hug = MOCK.spawnPlayer(2, "UH-1H", senaki.x, senaki.z, "Heli")
DCC.onTick()
local hueyItems = table.concat(MOCK.menuItems(hug.id), " | ")
check("CSAR on the Huey's board", hueyItems:find("CSAR:", 1, true) ~= nil, hueyItems)
check("cargo menu for the Huey", hueyItems:find("Load supply crate", 1, true) ~= nil)
MOCK.click(hug.id, "CSAR:")
local d = war.state.downed[did]
huey.x, huey.z, huey.air = d.pos.x + 50, d.pos.z, false
MOCK.advance(11)
check("green smoke on approach", MOCK.smokes >= 1)
check("pilot picked up", rec(huey).onboard[did] == true)
check("downed group removed after pickup", MOCK.groups["DCC_CSAR_" .. did] == nil)
local before16 = war.state.nodes.senaki.air["F-16C_50"]
at(huey, "senaki", 300, 0)
MOCK.advance(11)
check("landing at a friendly base rescues the pilot", war.state.downed[did] == nil)
check("aircraft refunded to Senaki", war.state.nodes.senaki.air["F-16C_50"] == before16 + 1)
check("rescue credited", DCC.pilots.data.pilots["Heli"].rescues == 1 and DCC.pilots.data.pilots["Lars"].saved == 1)

print("Logistics")
war.state.nodes.zugdidi.supply = 0
war.state.nodes.zugdidi.outOfSupply = true
war.state.nodes.zugdidi.farp = nil                -- v0.44: no FARP there (crates would top up the FARP first)
DCC.onTick()
local logOk = MOCK.click(hug.id, "LOGISTICS: supply to Zugdidi")
check("LOGISTICS offered for Zugdidi", logOk)
local ml = missionOf(huey)
at(huey, "senaki", 200, 0); huey.air = false
MOCK.click(hug.id, "Load supply crate")
check("crate loaded", rec(huey).crates == 1 and MOCK.cargoMass[huey:getName()] == 1000)
at(huey, "zugdidi", 200, 0)
MOCK.click(hug.id, "Unload")
check("crate unloaded into Zugdidi", war.state.nodes.zugdidi.supply >= DCC.config.ops.crateSU - 1)
DCC.onTick()
check("LOGISTICS mission complete", ml and war.state.missions[ml.id].status == "done", ml and ml.status)
check("logistics credited to the pilot", (DCC.pilots.data.pilots["Heli"].byType.LOGISTICS or 0) == 1)

print("Air assault")
local gali = war.state.nodes.gali
if gali.side == "red" then for i = #gali.platoons, 1, -1 do war:destroyPlatoon(gali.platoons[i]) end end
at(huey, "zugdidi", 200, 0)
MOCK.click(hug.id, "Load troops")
check("troops on board", #rec(huey).troops == 1)
at(huey, "gali", 200, 0)
MOCK.click(hug.id, "Unload")
DCC.onTick()
check("troops dropped on empty Gali take it", war.state.nodes.gali.side == "blue")

print("Convoy escort")
local apache, ag = MOCK.spawnPlayer(2, "AH-64D_BLK_II", senaki.x, senaki.z, "Ole")
war.state.nodes.senaki.supply = 300
local cv = war:startCargo("convoy", "blue", "senaki", "zugdidi", 30)
cv.front = true
DCC.onTick()
local convOk = MOCK.click(ag.id, "CONVOY:")
check("CONVOY offered to an Apache", convOk)
if convOk then
  local mc = missionOf(apache)
  check("ambush spawned on the convoy's road", MOCK.groups["DCC_AMB_" .. mc.id] ~= nil)
  check("escorted convoy forced live", B.forced[mc.target] == true)
end

print("Helicopter missions stay near the helicopter")
do
  local far = MOCK.spawnPlayer(2, "UH-1H", senaki.x + 600000, senaki.z, "Faraway", true)
  local fp = rec(far)
  check("a helicopter is recognised", fp.heli == true)
  local list = B.missionsFor(fp)
  local maxNm = 0
  for _, m in ipairs(list) do maxNm = math.max(maxNm, m._nm or 0) end
  check("nothing in range: only the 3 nearest are offered", #list <= 3, #list)
  local ap = rec(apache)
  ap.heli = true                        -- (spawned above as a plain group)
  local nearList = B.missionsFor(ap)
  local allIn = #nearList > 0
  for _, m in ipairs(nearList) do
    if m._nm > DCC.config.missions.heloRangeKm / 1.852 + 1 then allIn = false end
  end
  check("Apache at Senaki: every mission within range, distance shown", allIn, #nearList)
  for i = 2, #nearList do if nearList[i]._nm < nearList[i - 1]._nm then allIn = false end end
  check("...nearest first", allIn)
  B.brief(ap, nearList[1])
  local gt = MOCK.groupTexts[ap.gid] or {}
  local last = gt[#gt] or ""
  check("the brief gives DDM, DMS, MGRS and elevation for the jet / DTC", last:find("DMS N", 1, true)
    and last:find("Elev", 1, true) and last:find("MGRS", 1, true), last)
  check("a jet still sees the whole board", #B.missionsFor(rec(viper)) == #(function()
    local n = {} for _, m in ipairs(war:openMissions("blue")) do if B.canFly(rec(viper), m) then n[#n + 1] = m end end return n end)())
  check("the distance label does not leak into the war state", (function()
    for _, m in pairs(war.state.missions) do if rawget(m, "_nm") then return false end end return true end)())
  MOCK.fire({ id = world.event.S_EVENT_PLAYER_LEAVE_UNIT, initiator = far })

  -- a Huey at the base furthest from the front still gets local work
  local dist, rear = war:frontDistance("blue"), nil
  for _, id in ipairs(war.T.order) do
    if war.state.nodes[id].side == "blue" and B.nodePos[id]
       and (not rear or (dist[id] or 0) > (dist[rear] or 0)) then rear = id end
  end
  local rp = B.nodePos[rear]
  local rh = MOCK.spawnPlayer(2, "UH-1H", rp.x + 300, rp.z, "Rear", true)
  local local_, hubN = B.missionsFor(rec(rh)), 0
  local inRange = #local_ > 0
  for _, m in ipairs(local_) do
    if m.hub then hubN = hubN + 1 end
    if m._nm > DCC.config.missions.heloRangeKm / 1.852 + 1 then inRange = false end
  end
  check("rear-base Huey: local missions made for it at once", hubN > 0 and inRange, rear .. " " .. #local_)
  local kinds = {}
  for _, m in ipairs(local_) do kinds[m.type] = true end
  check("...only types a Huey can fly (no CAS/BAI)", not kinds.CAS and not kinds.BAI)
  MOCK.fire({ id = world.event.S_EVENT_PLAYER_LEAVE_UNIT, initiator = rh })
  local left = 0
  for _, m in pairs(war.state.missions) do if m.hub == rear and m.status == "open" then left = left + 1 end end
  check("...and withdrawn when it leaves (nobody took them)", left == 0, left)
  check("an A-10 is a slow mover with a 120 nm board", rec(hog).slow == true and B.localRangeKm(rec(hog)) == 222)
  check("a Viper is not limited", B.localRangeKm(rec(viper)) == nil)
end

print("Flying together")
do
  war.state.runways = {}                      -- a SCUD may have cratered Kutaisi by now: jets could not spawn
  local a, ag = MOCK.spawnPlayer(2, "F-16C_50", kp.x + 50, kp.z, "Anna")
  local b, bg = MOCK.spawnPlayer(2, "F-16C_50", kp.x + 80, kp.z, "Bo")
  local m
  for _, om in ipairs(war:openMissions("blue")) do
    if not m and om.type ~= "CAP" and B.canFly(rec(a), om) and not next(om.taken) then m = om end
  end
  B.takeMission({ unit = a:getName(), mid = m.id })
  local items = table.concat(MOCK.menuItems(bg.id), " | ")
  check("Bo's board: Join a flight, with Anna on it", items:find("Join a flight (", 1, true) ~= nil
    and items:find("[1: Anna]", 1, true) ~= nil, items)
  check("Bo joins with one click", MOCK.click(bg.id, "[1: Anna]") and m.taken[rec(b).key] ~= nil
    and m.taken[rec(a).key] ~= nil)
  local annaTexts = table.concat(MOCK.groupTexts[ag.id] or {}, " / ")
  check("Anna is told Bo joined", annaTexts:find("Bo (F-16C_50) joined", 1, true) ~= nil)
  local boTexts = table.concat(MOCK.groupTexts[bg.id] or {}, " / ")
  check("Bo is told who he flies with", boTexts:find("Flying with: Anna", 1, true) ~= nil)
  check("the brief lists the flight", boTexts:find("Flight: Anna (F-16C_50), Bo (F-16C_50)", 1, true) ~= nil)
  local c, cg = MOCK.spawnPlayer(2, "F-16C_50", kp.x + 90, kp.z, "Cid")
  B.takeMission({ unit = c:getName(), mid = m.id })
  B.abandon(c:getName())
  check("leaving is announced to the flight", MOCK.lastGroupText(ag.id):find("Cid left your", 1, true) ~= nil)
  check("...and Cid is off the mission", m.taken[rec(c).key] == nil)
  war:finishMission(m, "done")
  check("done together: both credited, team bonus", DCC.pilots.data.pilots.Anna.team == 1
    and DCC.pilots.data.pilots.Bo.team == 1 and (DCC.pilots.data.pilots.Cid.team or 0) == 0)
  check("...and told", MOCK.lastGroupText(bg.id):find("Team bonus - 2 pilots", 1, true) ~= nil, MOCK.lastGroupText(bg.id))
  for _, u in ipairs({ a, b, c }) do MOCK.fire({ id = world.event.S_EVENT_PLAYER_LEAVE_UNIT, initiator = u }) end
end

print("F10 menu never more than 10 items per level")
do
  war.state.runways = {}
  local v2, vg2 = MOCK.spawnPlayer(2, "F-16C_50", kp.x + 60, kp.z, "Pager")
  local types = { "CAS", "BAI", "STRIKE", "SEAD", "CAP", "ESCORT", "PKGESCORT", "HVAESCORT", "INTERCEPT", "TANKER",
                  "HVAA", "EWR", "ARTY", "FORT", "BRIDGE", "RUNWAY", "INDUSTRY", "COIN", "RECON" }
  local fake = {}
  for i, t in ipairs(types) do
    for k = 1, 12 do
      local id = "xpage" .. i .. "_" .. k
      war.state.missions[id] = { id = id, side = "blue", type = t, target = id, node = "kutaisi", label = "test " .. k,
        base = {}, created = war.state.tick, taken = {}, status = "open" }
      war.state.missions[id].needs = DCC.War.MISSION_NEEDS[t] or "ANY"
      fake[#fake + 1] = id
    end
  end
  B.buildMenu(rec(v2))
  local count, worst = {}, 0
  for _, it in ipairs(MOCK.groupMenus[vg2.id] or {}) do
    local key = it.parent or "root"
    count[key] = (count[key] or 0) + 1
    worst = math.max(worst, count[key])
  end
  check("19 mission types x 12: still at most 10 per menu level", worst <= 10, worst)
  local items = table.concat(MOCK.menuItems(vg2.id), " | ")
  check("...with 'More missions' paging", items:find("More missions", 1, true) ~= nil)
  for _, id in ipairs(fake) do war.state.missions[id] = nil end
  MOCK.fire({ id = world.event.S_EVENT_PLAYER_LEAVE_UNIT, initiator = v2 })
end

print("Nothing spawns in the water")
do
  local realSurface = land.getSurfaceType
  land.getSurfaceType = function(p) return (p.x < -1e6) and land.SurfaceType.WATER or land.SurfaceType.LAND end
  coalition.addGroup(B.countryId("blue"), Group.Category.GROUND, { name = "WETGROUP", task = "Ground Nothing",
    units = { { name = "WET_1", type = "Soldier M4", x = -1e6 - 300, y = 5000, heading = 0 } },
    route = { points = { { x = -1e6 - 300, y = 5000, type = "Turning Point", action = "Off Road", speed = 0 } } } })
  local u = MOCK.groups.WETGROUP.units[1]
  check("a ground unit spawned in the sea is moved ashore", u.x >= -1e6, u.x)
  land.getSurfaceType = realSurface
end

print("Leaving the slot")
MOCK.click(hug.id, "Load troops")
local carriedPid = rec(huey).troops[1]
MOCK.fire({ id = world.event.S_EVENT_PLAYER_LEAVE_UNIT, initiator = huey })
check("troops go home when the player leaves", carriedPid == nil or war.state.carried[carriedPid] == nil)
check("player record closed", rec(huey) == nil)

print("Pilot records saved")
DCC.save()
local f = io.open(MOCK.writedir .. "DCC\\pilots.json", "r")
check("pilots.json written", f ~= nil)
if f then
  local data = DCC.json.decode(f:read("*a")); f:close()
  check("records survive the file", data.pilots.Morten.byType.SEAD == 1 and data.pilots.Heli.rescues == 1)
end

print("A day of war with players")
MOCK.advance(24 * 3600)
check("no script errors in phase 3 loops", errors == 0, errors)

DCC.util.log = realLog
print(string.format("\n%d passed, %d failed", passed, failed))
DCC_EXIT_CODE = failed == 0 and 0 or 1
