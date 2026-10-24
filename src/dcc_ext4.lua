-- ============================================================================
-- Danica Dynamic Campaign - engineers (pure Lua 5.1, v0.27).
-- Load after dcc_ext3.lua.
-- ----------------------------------------------------------------------------
--  15. Engineer repair: a CTLD repair kit set down at an own base fixes one
--      thing at once instead of waiting hours for the base to do it:
--        1. a destroyed strike building (fuel, ammo, warehouse ...), else
--        2. the air defence (suppressed or destroyed SAM), else
--        3. a destroyed early-warning radar.
--      The kit is paid for when it is requested (CTLD), so no supply here.
--  (6 Combined Arms, 7 QRA and 16 performance guard are bridge-only:
--   dcc_dcs_ext4.lua)
-- ============================================================================

DCC = DCC or {}
local U = DCC.util
local War = DCC.War

-- What a repair kit would fix at base id, or nil: "infra", "sam" or "ewr".
function War:repairNeed(id)
  local ns = self.state.nodes[id]
  if not ns then return nil end
  if ns.infra and next(ns.infra.lost or {}) then return "infra" end
  if ns.sam and ns.sam.status ~= "up" then return "sam" end
  if ns.ewr and ns.ewr.status == "destroyed" then return "ewr" end
  return nil
end

-- Engineers repair one thing at base id (held by side). Returns a text or nil.
function War:engineerRepair(id, side)
  local ns = self.state.nodes[id]
  if not ns or ns.side ~= side then return nil end
  local need = self:repairNeed(id)
  local name = self:nodeName(id)
  local text
  if need == "infra" then
    local k = U.sortedKeys(ns.infra.lost)[1]
    ns.infra.lost[k] = nil
    ns.infra.repairAt = next(ns.infra.lost) and ns.infra.repairAt or nil
    text = string.format("Engineers rebuilt the %s at %s", k == "1" and "fuel store" or "supply building", name)
  elseif need == "sam" then
    ns.sam = { status = "up" }
    text = string.format("Engineers put the air defence at %s back up", name)
  elseif need == "ewr" then
    ns.ewr = { status = "up" }
    text = string.format("Engineers put the early-warning radar at %s back on the air", name)
  else
    return nil
  end
  self:log("engineer_repair", side, side:upper() .. ": " .. text, { node = id, what = need })
  return text
end
