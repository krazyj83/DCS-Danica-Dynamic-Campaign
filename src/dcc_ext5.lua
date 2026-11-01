-- ============================================================================
-- Danica Dynamic Campaign - air assault missions (pure Lua 5.1, v0.49).
-- Load after dcc_ext4.lua.
-- ----------------------------------------------------------------------------
-- AIRASSAULT (transport helicopters): fly troops (CTLD) to a weak enemy base
-- near the front and land them there - they attack it at once (the existing
-- CTLD air assault, War:dropPlatoons). The board names the target and the own
-- base to load at. When a player who took it gets airborne in a helicopter,
-- an AI gunship pair launches to clear the landing zone (bridge,
-- dcc_dcs_ext5.lua). Done when your side's troops land at the target.
-- ============================================================================

DCC = DCC or {}
local U = DCC.util
local War = DCC.War

local function AA(self) return self.cfg.ext5.airAssault end

War.MISSION_NEEDS.AIRASSAULT = "LIFT"
War.MISSION_ORDER[#War.MISSION_ORDER + 1] = "AIRASSAULT"

-- Weak enemy bases (not depots) within reach of an own base that has troops to send.
War.missionGenerators.AIRASSAULT = function(self, side)
  local cfg, enemy, out = AA(self), U.otherSide(side), {}
  for _, id in ipairs(self.T.order) do
    local ns = self.state.nodes[id]
    if ns.side == enemy and not self.T.nodes[id].depot and #ns.platoons <= cfg.maxDefenders then
      local from, fromD
      for _, fid in ipairs(self.T.order) do
        local fs = self.state.nodes[fid]
        if fs.side == side and #fs.platoons >= cfg.minTroops then
          local d = U.distKm(self.T.nodes[fid], self.T.nodes[id])
          if d <= cfg.rangeKm and (not fromD or d < fromD) then from, fromD = fid, d end
        end
      end
      if from then
        out[#out + 1] = { type = "AIRASSAULT", target = id, node = id, base = { from = from },
          prio = #ns.platoons, label = string.format("air assault on %s (troops from %s)", self:nodeName(id),
            self:nodeName(from)) }
      end
    end
  end
  table.sort(out, function(a, b)
    if a.prio ~= b.prio then return a.prio < b.prio end
    return a.target < b.target
  end)
  return out
end

-- Troops landed: an open AIRASSAULT mission on that base is done.
local baseDrop = War.dropPlatoons
function War:dropPlatoons(pids, id, side)
  local before = self.state.nodes[id] and self.state.nodes[id].side
  local r = baseDrop(self, pids, id, side)
  if r and before and before ~= side then          -- landed at an enemy base (an assault, or taken outright)
    for _, m in pairs(self.state.missions or {}) do
      if m.type == "AIRASSAULT" and m.status == "open" and m.side == side and m.target == id then m.landed = true end
    end
  end
  return r
end

local baseOutcome = War.missionOutcome
function War:missionOutcome(m, events)
  if m.type ~= "AIRASSAULT" then return baseOutcome(self, m, events) end
  if m.landed then return "done" end
  local ns = self.state.nodes[m.target]
  if not ns or ns.side == m.side then return "expired" end         -- taken some other way
  if #ns.platoons > AA(self).maxDefenders + 2 then return "expired" end   -- reinforced: no longer a soft target
  return "open"
end
