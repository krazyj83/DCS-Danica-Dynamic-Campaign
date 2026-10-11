-- ============================================================================
-- Phase 4 bridge tests: fog of war. Each side's F10 map shows only what that
-- side has detected.   python tools/run_lua.py tests/test_dcs_intel.lua
-- ============================================================================

local passed, failed = 0, 0
local function check(name, cond, detail)
  if cond then passed = passed + 1; print("  ok   " .. name)
  else failed = failed + 1; print("  FAIL " .. name .. (detail and (" - " .. tostring(detail)) or "")) end
end

dofile(DCC_ROOT .. "/tests/dcs_mock.lua")
MOCK.writedir = (arg[1] or "/tmp") .. "/dcc_intel_" .. tostring(os.time()) .. "/"
os.execute('mkdir -p "' .. MOCK.writedir .. 'DCC"')
MOCK.buildAirbases(DCC_THEATERS.Caucasus)
MOCK.addTemplates()

dofile(DCC_ROOT .. "/src/dcc_persist.lua")
dofile(DCC_ROOT .. "/src/dcc_dcs.lua")
dofile(DCC_ROOT .. "/src/dcc_dcs_supply.lua")
dofile(DCC_ROOT .. "/src/dcc_dcs_ops.lua")
dofile(DCC_ROOT .. "/src/dcc_dcs_intel.lua")
dofile(DCC_ROOT .. "/src/dcc_dcs_radar.lua")
dofile(DCC_ROOT .. "/src/dcc_main.lua")

local errors = 0
DCC.util.log = function(fmt, ...)
  local msg = string.format(fmt, ...)
  if msg:find("ERROR") then errors = errors + 1; print("    " .. msg) end
end

DCC.start()
local B, war = DCC.dcs, DCC.warObj
local BLUE, RED = 2, 1

-- Intel-layer marks for one coalition, by kind.
local function intelMarks(coal, kind)
  local list = {}
  for _, id in ipairs(B.intelMarks) do
    local m = MOCK.marks[id]
    if m and m.coal == coal and (not kind or m.kind == kind) then list[#list + 1] = m end
  end
  return list
end
local function texts(coal)
  local out = {}
  for _, m in ipairs(intelMarks(coal, "text")) do out[#out + 1] = m.args[#m.args] end
  return table.concat(out, " | ")
end
local function contactCount(side)
  local n = 0
  for _ in pairs(war.state.contacts[side]) do n = n + 1 end
  return n
end

print("Start: nobody has seen anything")
check("fog of war on", war.fogOfWar == true)
B.intelScan()
B.drawIntel()
check("no enemy circles on BLUE's map", #intelMarks(BLUE, "circle") == 0)
check("no enemy circles on RED's map", #intelMarks(RED, "circle") == 0)
check("front estimates for both sides", texts(BLUE):find("est.", 1, true) and texts(RED):find("est.", 1, true))
-- the strength labels of the node layer go to the owner only, never to everyone
local leaks = 0
for _, m in pairs(MOCK.marks) do
  local t = m.kind == "text" and m.args[#m.args]
  if t and t:find(" plt | ", 1, true) and m.coal == -1 then leaks = leaks + 1 end
end
check("garrison strength never drawn for everyone", leaks == 0, leaks)

-- a RED SAM site to work with
local samNode
for _, id in ipairs(war.T.order) do
  local ns = war.state.nodes[id]
  if ns.side == "red" and ns.sam and ns.sam.status == "up" then samNode = id; break end
end
local sp = B.nodePos[samNode]

print("ELINT")
-- a BLUE fighter 50 km out at 6000 m: outside the live bubble, inside SAM range
local viper, vg = MOCK.spawnPlayer(BLUE, "F-16C_50", sp.x - 50000, sp.z, "Morten")
viper.air, viper.alt = true, 6000
MOCK.advance(31)
local sg = MOCK.groups["DCC_SAM_" .. samNode]
check("SAM site spawned", sg ~= nil)
B.intelScan()
check("SAM wakes up when an enemy aircraft is within 60 km", B.samAwake[samNode] == true)
check("radar ordered to alarm state RED", sg and sg.options and sg.options[9] == 2)
local c = war:contact("blue", "sam:" .. samNode)
check("BLUE hears the radar", c ~= nil and c.source == "elint")
check("ELINT fix is rough (km, not metres)", c and c.err > 1000 and c.err <= DCC.config.intel.elintBaseErrM, c and c.err)
local e1 = c and c.err
B.intelScan()
c = war:contact("blue", "sam:" .. samNode)
check("every observation narrows it", c and c.err < e1, c and c.err)
war:addContact("blue", "sam:" .. samNode, { err = 6000 })   -- back to a rough fix for the map checks
check("RED learned nothing from BLUE's ELINT", war:contact("red", "sam:" .. samNode) == nil)
B.drawIntel()
local function ringCount(coal)
  local ring, errc = 0, 0
  for _, m in ipairs(intelMarks(coal, "circle")) do
    if m.args[2] == 25000 then ring = ring + 1 elseif m.args[2] == 6000 then errc = errc + 1 end
  end
  return ring, errc
end
local function samContacts(side)
  local n = 0
  for key, c in pairs(war.state.contacts[side]) do
    if c.kind == "sam" and war.state.nodes[c.node].side ~= side then n = n + 1 end
  end
  return n
end
local ring, errc = ringCount(BLUE)
check("BLUE map: one threat ring per SAM contact, nothing else", ring == samContacts("blue") and ring >= 1, ring .. " rings")
check("BLUE map: rough ELINT fix drawn as an error circle", errc >= 1)
check("BLUE map label shows ELINT", texts(BLUE):find("ELINT", 1, true) ~= nil, texts(BLUE))
check("RED map has no SAM rings from BLUE's intel", (ringCount(RED)) == 0)
-- SEAD now on the board for BLUE
DCC.onTick()
local seads, unknown = 0, 0
for _, m in ipairs(war:openMissions("blue")) do
  if m.type == "SEAD" then
    seads = seads + 1
    if war:samKnown("blue", m.target) ~= "known" then unknown = unknown + 1 end
  end
end
check("ELINT contacts put SEAD on the board", seads >= 1)
check("every SEAD target is a site BLUE has detected", unknown == 0, unknown)

print("Low fighter does not hear it")
local hog, hg = MOCK.spawnPlayer(BLUE, "A-10C_2", sp.x - 70000, sp.z + 20000, "Jens")
hog.air, hog.alt = true, 300
local before = contactCount("blue")
check("ELINT needs height (A-10 at 300 m is not an emitter receiver)", DCC.config.intel.elintMinAglM > hog.alt)

print("Anti-radiation missile")
local radar = sg.units[1]
MOCK.fire({ id = world.event.S_EVENT_SHOT, initiator = viper, weapon = MOCK.weapon(5, radar) })
check("site goes dark", not B.samEmitting(samNode))
check("radar ordered to alarm state GREEN", sg.options[9] == 1)
local errBefore = war:contact("blue", "sam:" .. samNode).err
B.intelScan()
check("a dark site cannot be heard", war:contact("blue", "sam:" .. samNode).err == errBefore)
MOCK.advance(DCC.config.intel.harmDarkSeconds[2] + 1)
B.intelScan()
check("site comes back on after the dark time", B.samEmitting(samNode))
MOCK.fire({ id = world.event.S_EVENT_SHOT, initiator = viper, weapon = MOCK.weapon(2, radar) })
check("a heat-seeker does not scare the radar", B.samEmitting(samNode))

print("Visual, with line of sight")
-- the A-10 flies right over the base, low: the garrison spawns
hog.x, hog.z, hog.alt = sp.x - 3000, sp.z, 300
MOCK.advance(31)
local garrisonGroup
for pid, rec in pairs(B.spawned) do if rec.key == "g:" .. samNode then garrisonGroup = rec.group end end
check("garrison spawned near the player", garrisonGroup ~= nil)
MOCK.ridges = { { sp.x - 1500, sp.z, 1300 } }   -- a hill between the A-10 and the base
for _, u in ipairs(MOCK.groups[garrisonGroup].units) do u.x, u.z = sp.x, sp.z end
B.intelScan()
check("hill blocks the view: no garrison contact", war:contact("blue", "g:" .. samNode) == nil)
MOCK.ridges = nil
B.intelScan()
local g = war:contact("blue", "g:" .. samNode)
check("clear line of sight: garrison seen", g ~= nil and g.source == "visual")
check("seen vehicles counted", g and g.label:find("vehicles seen", 1, true) ~= nil, g and g.label)
local samSeen = war:contact("blue", "sam:" .. samNode)
check("SAM site seen with the eyes: precise fix", samSeen.err <= 200, samSeen.err)

print("AI sensors")
sg.detected = { viper }
B.intelScan()
check("RED SAM radar reports the BLUE fighter", B.airContacts.red[viper:getName()] ~= nil)
check("BLUE gets nothing from RED's radar", B.airContacts.blue[viper:getName()] == nil)
B.drawIntel()
check("RED map shows the aircraft", texts(RED):find("F-16C_50", 1, true) ~= nil, texts(RED))
check("BLUE map never shows its own aircraft as a contact", texts(BLUE):find("F-16C_50", 1, true) == nil)
sg.detected = nil
local vx = viper.x
viper.x = sp.x - 900000   -- out of reach of every RED radar and AWACS (phase 5)
MOCK.advance(DCC.config.intel.airContactSeconds + 1)
B.intelScan()
check("aircraft contact dropped after 2 min", B.airContacts.red[viper:getName()] == nil)
viper.x = vx

print("Aging on the map")
for _ = 1, DCC.config.intel.staleTicks do war:tick() end
viper.x, hog.x = sp.x - 300000, sp.x - 300000   -- everybody goes home
MOCK.advance(31)
B.intelScan()
B.drawIntel()
check("stale contacts still drawn", #intelMarks(BLUE, "circle") >= 1)
check("stale contacts can no longer be tasked", war:samKnown("blue", samNode) ~= "known" or war:isFresh("blue", "n:" .. samNode))
for _ = 1, DCC.config.intel.expireTicks + 1 do war:tick() end
B.drawIntel()
check("expired contacts gone from the map", #intelMarks(BLUE, "circle") == 0, #intelMarks(BLUE, "circle"))

print("Fog off")
war.fogOfWar = false
B.drawIntel()
check("no intel layer without fog", #B.intelMarks == 0)
war.fogOfWar = true

print("Save and restore")
war:addContact("blue", "sam:" .. samNode, { kind = "sam", node = samNode, source = "elint", err = 900 })
DCC.save()
local saved = DCC.persist.load(DCC.theaterName)
check("contacts in the save file", saved.contacts and saved.contacts.blue["sam:" .. samNode] ~= nil)

print("A day of war with fog")
for _ = 1, 288 do
  MOCK.advance(300)
end
check("no script errors in the intel loops", errors == 0, errors)

print(string.format("\n%d passed, %d failed", passed, failed))
DCC_EXIT_CODE = failed == 0 and 0 or 1
