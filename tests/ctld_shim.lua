-- ============================================================================
-- Extra DCS API that real CTLD.lua touches at start-up and in the tests, on
-- top of dcs_mock.lua. Load after dcs_mock.lua, before vendor/ctld/CTLD.lua.
-- ============================================================================
function coalition.getStaticObjects(side)
  local out = {}
  for _, s in pairs(MOCK.statics) do if (s.coal or 0) == side then out[#out + 1] = s end end
  return out
end
function coalition.getGroups(side, cat)
  local out = {}
  for _, g in pairs(MOCK.groups) do
    local c = g.units and g.units[1] and g.units[1].coal
    if c == side and (cat == nil or g.category == cat) then out[#out + 1] = g end
  end
  return out
end
local UnitMT = MOCK.UnitMT
UnitMT.getCategory = UnitMT.getCategory or function(self) return Object.Category.UNIT end
UnitMT.getVelocity = UnitMT.getVelocity or function(self) return self.vel or { x = 0, y = 0, z = 0 } end
UnitMT.getCountry = UnitMT.getCountry or function(self) return self.coal == 2 and 80 or 81 end
UnitMT.getPosition = UnitMT.getPosition or function(self)
  return { p = self:getPoint(), x = { x = 1, y = 0, z = 0 }, y = { x = 0, y = 1, z = 0 }, z = { x = 0, y = 0, z = 1 } }
end
UnitMT.getCallsign = UnitMT.getCallsign or function(self) return self.name end
UnitMT.getAmmo = UnitMT.getAmmo or function() return {} end
UnitMT.getFuel = UnitMT.getFuel or function() return 1 end
UnitMT.getController = UnitMT.getController or function(self) return self.group and self.group:getController() end
UnitMT.getObjectID = UnitMT.getObjectID or function(self) return self:getID() end
local GroupMT = MOCK.GroupMT
GroupMT.getCategory = GroupMT.getCategory or function(self) return self.category end
GroupMT.getCoalition = GroupMT.getCoalition or function(self) return self.units[1] and self.units[1].coal end
GroupMT.getSize = GroupMT.getSize or function(self) return #self.units end
trigger.misc = trigger.misc or {}
trigger.misc.getZone = trigger.misc.getZone or function() return nil end
trigger.misc.getUserFlag = trigger.misc.getUserFlag or function() return 0 end
trigger.action.setUnitInternalCargo = trigger.action.setUnitInternalCargo or function() end
country.name = country.name or { [80] = "CJTF_BLUE", [81] = "CJTF_RED" }
coalition.getCountryCoalition = coalition.getCountryCoalition or function(c)
  return c == 80 and 2 or (c == 81 and 1 or 0)
end
local StaticMT = MOCK.StaticMT
StaticMT.getPoint = StaticMT.getPoint or function(self) return { x = self.x, y = 0, z = self.z } end
StaticMT.getPosition = StaticMT.getPosition or function(self)
  return { p = self:getPoint(), x = { x = 1, y = 0, z = 0 }, y = { x = 0, y = 1, z = 0 }, z = { x = 0, y = 0, z = 1 } }
end
StaticMT.getCoalition = StaticMT.getCoalition or function(self) return self.coal or 0 end
StaticMT.getCategory = StaticMT.getCategory or function(self) return Object.Category.STATIC end
StaticMT.getTypeName = StaticMT.getTypeName or function(self) return self.type end
StaticMT.getID = StaticMT.getID or function(self) return 1 end
StaticMT.getDesc = StaticMT.getDesc or function(self) return { typeName = self.type } end
