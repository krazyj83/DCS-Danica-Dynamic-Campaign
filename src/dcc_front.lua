-- ============================================================================
-- Danica Dynamic Campaign - front-line geometry (pure Lua 5.1)
-- ----------------------------------------------------------------------------
-- The front is not hand-drawn. It is computed from ownership: every road edge
-- whose two ends belong to different sides is "contested", and the front
-- crosses it at its midpoint, at right angles to the road. Joined together,
-- those crossings trace the line between the two sides on any map.
-- ============================================================================

DCC = DCC or {}
local U = DCC.util
local F = {}
DCC.front = F

-- Returns a list of { a = {lat,lon}, b = {lat,lon}, edge = {a, b, km} }.
function F.segments(war)
  local segs = {}
  for _, e in ipairs(war.T.edges) do
    local sa, sb = war.state.nodes[e.a].side, war.state.nodes[e.b].side
    if sa ~= sb then
      local na, nb = war.T.nodes[e.a], war.T.nodes[e.b]
      local mid = U.lerp(na, nb, 0.5)
      local brg = U.bearing(na, nb)
      local half = U.clamp(e.km * 0.35, 4, 15)
      segs[#segs + 1] = {
        a = U.destination(mid, brg - 90, half),
        b = U.destination(mid, brg + 90, half),
        edge = e,
      }
    end
  end
  return segs
end
