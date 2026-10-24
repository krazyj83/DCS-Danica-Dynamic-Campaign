-- ============================================================================
-- Danica Dynamic Campaign - territory and front line from Voronoi cells
-- (pure Lua 5.1). Load after dcc_front.lua.
-- ----------------------------------------------------------------------------
-- Idea (as in rurouniJones/frontline, written here from scratch in Lua): give
-- every base the ground that is closer to it than to any other base - its
-- Voronoi cell. A side's territory is the union of its bases' cells, and the
-- front line is every cell border where a BLUE cell meets a RED cell.
--
--   * Cells are capped at territory.reachKm around their base (a 24-gon), so
--     territory does not run out over open sea or off the map. With fillHoles
--     the cap is shared: the convex hull of every base's circle, so there are
--     no holes between bases that are far apart.
--   * Each cell is computed by clipping that cap with the perpendicular
--     bisector against every other base (Sutherland-Hodgman on a convex
--     polygon; ~50 bases = 2,500 clips, a few milliseconds).
--   * Every cell edge remembers which neighbour made it, so the borders
--     between BLUE and RED cells come out as the front, joined into polylines.
--   * Work is in kilometres on a local flat projection around the map's centre
--     (good to well under 1 % over a DCS map); results come back as lat/lon,
--     so the F10 map (coord.LLtoLO) and the web map (Leaflet) both use them.
--   * Cached: recomputed only when a base changes hands.
-- ============================================================================

DCC = DCC or {}
local T = {}
DCC.territory = T

local KM_LAT = 110.574

local function cfg()
  return (DCC.config and DCC.config.territory) or { reachKm = 75, capSides = 24 }
end

-- ---------------------------------------------------------------------------
-- Projection
-- ---------------------------------------------------------------------------
local function projector(nodes)
  local lat0, lon0, n = 0, 0, 0
  for _, nd in ipairs(nodes) do lat0, lon0, n = lat0 + nd.lat, lon0 + nd.lon, n + 1 end
  local c = { lat = lat0 / n, lon = lon0 / n }
  local U = DCC.util
  -- azimuthal equidistant around the map's centre: distance and bearing from
  -- the centre are exact, other distances are off by < 0.1 % within 400 km
  return function(lat, lon)
           local p = { lat = lat, lon = lon }
           local d, b = U.distKm(c, p), math.rad(U.bearing(c, p))
           return d * math.sin(b), d * math.cos(b)
         end,
         function(x, y)
           local p = U.destination(c, math.deg(math.atan2(x, y)), math.sqrt(x * x + y * y))
           return p.lat, p.lon
         end
end

-- ---------------------------------------------------------------------------
-- Clipping a convex polygon (list of {x, y, tag}) by the half-plane that is
-- closer to site s than to site o. Edge tags say which neighbour made an edge
-- (the tag sits on the vertex that STARTS the edge).
-- ---------------------------------------------------------------------------
local function clip(poly, s, o, tag)
  -- keep points p with (p - m) . (o - s) <= 0, m = midpoint
  local mx, my = (s.x + o.x) / 2, (s.y + o.y) / 2
  local nx, ny = o.x - s.x, o.y - s.y
  local function side(p) return (p.x - mx) * nx + (p.y - my) * ny end
  local out = {}
  local n = #poly
  for i = 1, n do
    local a, b = poly[i], poly[i % n + 1]
    local da, db = side(a), side(b)
    if da <= 0 then out[#out + 1] = a end
    if (da <= 0) ~= (db <= 0) then
      local t = da / (da - db)
      local p = { x = a.x + (b.x - a.x) * t, y = a.y + (b.y - a.y) * t }
      if da <= 0 then
        p.tag = tag                -- leaving: the new edge from here on lies on the bisector
      else
        p.tag = a.tag              -- entering: continue the edge we were cutting
      end
      out[#out + 1] = p
    end
  end
  return out
end

-- Convex hull (Andrew's monotone chain) of points {x, y}, counter-clockwise.
local function convexHull(points)
  local p = {}
  for _, q in ipairs(points) do p[#p + 1] = { x = q.x, y = q.y } end
  table.sort(p, function(a, b) if a.x ~= b.x then return a.x < b.x end return a.y < b.y end)
  if #p < 3 then return p end
  local function cross(o, a, b) return (a.x - o.x) * (b.y - o.y) - (a.y - o.y) * (b.x - o.x) end
  local lower, upper = {}, {}
  for _, q in ipairs(p) do
    while #lower >= 2 and cross(lower[#lower - 1], lower[#lower], q) <= 0 do lower[#lower] = nil end
    lower[#lower + 1] = q
  end
  for i = #p, 1, -1 do
    local q = p[i]
    while #upper >= 2 and cross(upper[#upper - 1], upper[#upper], q) <= 0 do upper[#upper] = nil end
    upper[#upper + 1] = q
  end
  lower[#lower] = nil
  upper[#upper] = nil
  for _, q in ipairs(upper) do lower[#lower + 1] = q end
  return lower
end

-- ---------------------------------------------------------------------------
-- Cells
-- ---------------------------------------------------------------------------
-- sites: { {id, lat, lon, side}, ... } -> cells[id] = { side, poly = {{x,y,tag}} }
function T.cells(sites)
  local toXY, toLL = projector(sites)
  local pts = {}
  for i, s in ipairs(sites) do
    local x, y = toXY(s.lat, s.lon)
    pts[i] = { x = x, y = y, id = s.id, side = s.side }
  end
  local reach, k = cfg().reachKm, cfg().capSides
  local fill = cfg().fillHoles ~= false
  local function ring(s)
    local r = {}
    for j = 0, k - 1 do
      local a = 2 * math.pi * j / k
      r[#r + 1] = { x = s.x + reach * math.cos(a), y = s.y + reach * math.sin(a) }
    end
    return r
  end
  -- fillHoles: one cap for everybody, the convex hull of every base's reach circle
  -- (the area spanned by all bases, plus reach around it). Ground between bases
  -- that are far apart is always somebody's - no holes - while the outer edge still
  -- stops at reach beyond the outermost bases.
  local shared
  if fill then
    local all = {}
    for _, s in ipairs(pts) do for _, v in ipairs(ring(s)) do all[#all + 1] = v end end
    shared = convexHull(all)
  end
  local cells = {}
  for i, s in ipairs(pts) do
    local poly = {}
    for _, v in ipairs(shared or ring(s)) do poly[#poly + 1] = { x = v.x, y = v.y, tag = false } end
    local far = 0
    for _, v in ipairs(poly) do far = math.max(far, (v.x - s.x) ^ 2 + (v.y - s.y) ^ 2) end
    for j, o in ipairs(pts) do
      if j ~= i and #poly > 0 then
        local dx, dy = o.x - s.x, o.y - s.y
        if dx * dx + dy * dy < 4 * far then               -- farther sites cannot touch this cell
          poly = clip(poly, s, o, o.id)
        end
      end
    end
    cells[s.id] = { id = s.id, side = s.side, poly = poly, x = s.x, y = s.y }
  end
  return cells, toLL
end

-- ---------------------------------------------------------------------------
-- Front: cell edges made by a neighbour of the other side, joined into lines
-- ---------------------------------------------------------------------------
local function key(p) return string.format("%.2f,%.2f", p.x, p.y) end   -- 10 m: the same corner seen from two cells

local function chains(segs)
  -- join segments that share end points into polylines
  local byEnd, used, out = {}, {}, {}
  for i, s in ipairs(segs) do
    for _, p in ipairs({ s[1], s[2] }) do
      local k = key(p)
      byEnd[k] = byEnd[k] or {}
      table.insert(byEnd[k], i)
    end
  end
  local function nextSeg(p, from)
    for _, j in ipairs(byEnd[key(p)] or {}) do
      if not used[j] and j ~= from then return j end
    end
  end
  -- start from loose ends first, so open lines come out whole
  local order = {}
  for i, s in ipairs(segs) do
    local loose = #(byEnd[key(s[1])]) == 1 or #(byEnd[key(s[2])]) == 1
    table.insert(order, loose and 1 or #order + 1, i)
  end
  for _, i in ipairs(order) do
    if not used[i] then
      used[i] = true
      local s = segs[i]
      local a, b = s[1], s[2]
      if #(byEnd[key(b)]) == 1 and #(byEnd[key(a)]) > 1 then a, b = b, a end
      local line = { a, b }
      local tail, cur = b, i
      while true do
        local j = nextSeg(tail, cur)
        if not j then break end
        used[j] = true
        local t = segs[j]
        tail = (key(t[1]) == key(tail)) and t[2] or t[1]
        line[#line + 1] = tail
        cur = j
      end
      out[#out + 1] = line
    end
  end
  return out
end

-- Everything the map needs, from the war's current ownership.
--   territory = { {side, poly = {{lat,lon},...}}, ... }     one per base
--   front     = { {{lat,lon}, {lat,lon}, ...}, ... }         polylines
function T.compute(war)
  local sig = {}
  for _, id in ipairs(war.T.order) do sig[#sig + 1] = war.state.nodes[id].side:sub(1, 1) end
  sig = table.concat(sig)
  if war._territory and war._territory.sig == sig then return war._territory end

  local sites = {}
  for _, id in ipairs(war.T.order) do
    local tn = war.T.nodes[id]
    sites[#sites + 1] = { id = id, lat = tn.lat, lon = tn.lon, side = war.state.nodes[id].side }
  end
  local cells, toLL = T.cells(sites)
  local function ll(p)
    local lat, lon = toLL(p.x, p.y)
    return { lat = lat, lon = lon }
  end

  local territory, segs = {}, {}
  for _, id in ipairs(war.T.order) do
    local c = cells[id]
    if #c.poly >= 3 then
      local poly = {}
      for _, p in ipairs(c.poly) do poly[#poly + 1] = ll(p) end
      territory[#territory + 1] = { id = id, side = c.side, poly = poly }
      local n = #c.poly
      for i = 1, n do
        local a, b = c.poly[i], c.poly[i % n + 1]
        local nb = a.tag and cells[a.tag]
        -- each BLUE/RED border once: from the BLUE cell
        if nb and nb.side ~= c.side and c.side == "blue" then segs[#segs + 1] = { a, b } end
      end
    end
  end
  local front = {}
  for _, line in ipairs(chains(segs)) do
    local out = {}
    for _, p in ipairs(line) do out[#out + 1] = ll(p) end
    front[#front + 1] = out
  end
  war._territory = { sig = sig, territory = territory, front = front }
  return war._territory
end

-- Length of the front in km (for status and tests).
function T.frontKm(war)
  local km = 0
  for _, line in ipairs(T.compute(war).front) do
    for i = 2, #line do km = km + DCC.util.distKm(line[i - 1], line[i]) end
  end
  return km
end
