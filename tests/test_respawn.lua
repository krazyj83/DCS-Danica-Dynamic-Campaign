local passed, failed = 0, 0
local function check(n, c, d) if c then passed = passed + 1; print("  ok   " .. n) else failed = failed + 1; print("  FAIL " .. n .. (d and (" - " .. tostring(d)) or "")) end end
dofile(DCC_ROOT .. "/tests/dcs_mock.lua")
world.event.S_EVENT_UNIT_LOST = 30
local function grp(name, units) return { name = name, groupId = 5, route = { points = { { x = 0, y = 0, speed = 5 } } }, units = units } end
env.mission.coalition = {
  red = { country = { { id = 81,
    vehicle = { group = { grp("SA-6 site", { { name = "SA6-1", type = "Kub 1S91 str", x = 100, y = 200, heading = 1, skill = "High" },
                                            { name = "SA6-2", type = "Kub 2P25 ln", x = 150, y = 200, heading = 1, skill = "High" } }),
                          grp("DCC_g1", { { name = "DCC_g1_1", type = "T-72B", x = 0, y = 0, skill = "Average" } }) } },
    static = { group = { { name = "Bunker", units = { { name = "Bunker", type = "Bunker", category = "Fortifications", x = 5, y = 5, heading = 0 } } } } },
  } } },
  blue = { country = { { id = 80, plane = { group = { grp("Viper", { { name = "Viper-1", type = "F-16C_50", x = 0, y = 0, alt = 100, skill = "Client", payload = { fuel = 1 } } }) } } } } },
}
-- the ME groups exist in the world
local function place(gname, cat, units, coal)
  local g = setmetatable({ name = gname, exists = true, units = {}, route = {}, category = cat, id = 1 }, MOCK.GroupMT)
  for i, u in ipairs(units) do g.units[i] = setmetatable({ name = u, alive = true, x = 0, z = 0, coal = coal, group = g }, MOCK.UnitMT) end
  MOCK.groups[gname] = g
  return g
end
place("SA-6 site", 2, { "SA6-1", "SA6-2" }, 1)
place("DCC_g1", 2, { "DCC_g1_1" }, 1)
dofile(DCC_ROOT .. "/extras/respawn.lua")

print("unit mode")
check("player slots and DCC_ groups ignored", RESPAWN.templates["Viper-1"] == nil and RESPAWN.templates["DCC_g1_1"] == nil)
check("ME units and statics watched", RESPAWN.templates["SA6-1"] ~= nil and RESPAWN.templates["Bunker"] ~= nil)
local u1 = Unit.getByName("SA6-1"); u1.alive = false
MOCK.fire({ id = world.event.S_EVENT_UNIT_LOST, initiator = u1 })
MOCK.fire({ id = world.event.S_EVENT_DEAD, initiator = u1 })          -- same death reported twice
MOCK.advance(299)
check("nothing before 5 min", MOCK.countGroups("SA-6 site #R") == 0)
MOCK.advance(2)
check("back after 5 min, once", MOCK.countGroups("SA-6 site #R") == 1)
local g = MOCK.groups["SA-6 site #R1"]
check("same type and position", g and g.units[1].type == "Kub 1S91 str" and g.data.units[1].x == 100 and g.data.units[1].y == 200 and g.data.units[1].heading == 1, g and (g.units[1].type .. " " .. g.units[1].x .. " " .. g.units[1].z))
-- the respawned unit dies too -> comes back again
g.units[1].alive = false
MOCK.fire({ id = world.event.S_EVENT_DEAD, initiator = g.units[1] })
MOCK.advance(301)
check("a respawned unit respawns again", MOCK.groups["SA-6 site #R2"] ~= nil)
local d = Unit.getByName("DCC_g1_1"); d.alive = false
MOCK.fire({ id = world.event.S_EVENT_DEAD, initiator = d })
MOCK.advance(301)
check("campaign units left alone", MOCK.countGroups("DCC_g1 #R") == 0)
local st = { name = "Bunker", getName = function() return "Bunker" end }
MOCK.fire({ id = world.event.S_EVENT_DEAD, initiator = st })
MOCK.advance(301)
check("static rebuilt", MOCK.statics["Bunker"] ~= nil and MOCK.statics["Bunker"].type == "Bunker")

print("group mode")
RESPAWN.mode = "group"
Unit.getByName("SA6-1").alive = true   -- the group starts complete again
local u2 = Unit.getByName("SA6-2"); u2.alive = false
MOCK.fire({ id = world.event.S_EVENT_DEAD, initiator = u2 })
MOCK.advance(400)
check("no group respawn while a unit lives", MOCK.groups["SA-6 site"].units[2].alive == false and #MOCK.groups["SA-6 site"].units == 2)
-- now kill the rest of the original group
for _, u in ipairs(MOCK.groups["SA-6 site"].units) do u.alive = false end
MOCK.fire({ id = world.event.S_EVENT_DEAD, initiator = MOCK.groups["SA-6 site"].units[1] })
MOCK.advance(305)   -- 2 s check + 5 min
local ng = MOCK.groups["SA-6 site"]
check("whole group back 5 min after the last unit", ng and #ng.units == 2 and ng.units[1].alive and ng.units[2].alive)
print(string.format("\n%d passed, %d failed", passed, failed))
