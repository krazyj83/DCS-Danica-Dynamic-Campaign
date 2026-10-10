-- ============================================================================
-- Danica Dynamic Campaign - utilities (pure Lua 5.1, no DCS calls)
-- ----------------------------------------------------------------------------
-- Geography on lat/lon, a seeded random generator and table helpers.
-- Nothing here touches DCS, so it runs in offline tests too.
-- ============================================================================

DCC = DCC or {}
local U = {}
DCC.util = U

local rad, deg = math.rad, math.deg
local sin, cos, atan2, asin, sqrt = math.sin, math.cos, math.atan2, math.asin, math.sqrt
local EARTH_KM = 6371.0

-- Great-circle distance in km between two {lat, lon} points.
function U.distKm(a, b)
  local dLat = rad(b.lat - a.lat)
  local dLon = rad(b.lon - a.lon)
  local h = sin(dLat / 2) ^ 2 + cos(rad(a.lat)) * cos(rad(b.lat)) * sin(dLon / 2) ^ 2
  return 2 * EARTH_KM * asin(math.min(1, sqrt(h)))
end

-- Initial bearing in degrees from a to b.
function U.bearing(a, b)
  local p1, p2 = rad(a.lat), rad(b.lat)
  local dLon = rad(b.lon - a.lon)
  local y = sin(dLon) * cos(p2)
  local x = cos(p1) * sin(p2) - sin(p1) * cos(p2) * cos(dLon)
  return (deg(atan2(y, x)) + 360) % 360
end

-- Point reached travelling `km` from p on bearing `brg` (degrees).
function U.destination(p, brg, km)
  local d = km / EARTH_KM
  local b = rad(brg)
  local p1, l1 = rad(p.lat), rad(p.lon)
  local p2 = asin(sin(p1) * cos(d) + cos(p1) * sin(d) * cos(b))
  local l2 = l1 + atan2(sin(b) * sin(d) * cos(p1), cos(d) - sin(p1) * sin(p2))
  return { lat = deg(p2), lon = deg(l2) }
end

-- Straight-line interpolation (fine for the short distances between nodes).
function U.lerp(a, b, t)
  return { lat = a.lat + (b.lat - a.lat) * t, lon = a.lon + (b.lon - a.lon) * t }
end

function U.clamp(v, lo, hi)
  if v < lo then return lo end
  if v > hi then return hi end
  return v
end

-- ----------------------------------------------------------------------------
-- Seeded random generator (Park-Miller). The state is a plain number, so it is
-- saved with the campaign and a restored war continues the same sequence.
-- ----------------------------------------------------------------------------
local RNG = {}
RNG.__index = RNG

function U.rng(seed)
  local s = math.floor(tonumber(seed) or 12345) % 2147483647
  if s <= 0 then s = s + 2147483646 end
  return setmetatable({ state = s }, RNG)
end

-- Uniform float in [0, 1).
function RNG:next()
  self.state = (self.state * 16807) % 2147483647
  return (self.state - 1) / 2147483646
end

-- Uniform float in [lo, hi).
function RNG:range(lo, hi)
  return lo + (hi - lo) * self:next()
end

-- Integer in [1, n].
function RNG:int(n)
  return math.floor(self:next() * n) + 1
end

-- Pick a key from a { key = weight } table.
function RNG:weighted(weights)
  local keys, total = {}, 0
  for k, w in pairs(weights) do keys[#keys + 1] = k; total = total + w end
  table.sort(keys) -- pairs() order is not stable; sorting keeps runs reproducible
  local r = self:next() * total
  for _, k in ipairs(keys) do
    r = r - weights[k]
    if r < 0 then return k end
  end
  return keys[#keys]
end

-- ----------------------------------------------------------------------------
-- Table helpers
-- ----------------------------------------------------------------------------
function U.copy(t)
  if type(t) ~= "table" then return t end
  local c = {}
  for k, v in pairs(t) do c[k] = U.copy(v) end
  return c
end

function U.removeValue(list, value)
  for i = #list, 1, -1 do
    if list[i] == value then table.remove(list, i); return true end
  end
  return false
end

function U.sortedKeys(t)
  local keys = {}
  for k in pairs(t) do keys[#keys + 1] = k end
  table.sort(keys)
  return keys
end

function U.otherSide(side)
  return side == "blue" and "red" or "blue"
end

-- Logging goes to dcs.log inside DCS, to stdout offline.
function U.log(fmt, ...)
  local msg = "DCC: " .. string.format(fmt, ...)
  if env and env.info then env.info(msg) else print(msg) end
end

function U.debug(fmt, ...)
  if DCC.config and DCC.config.debug then U.log(fmt, ...) end
end
