-- ============================================================================
-- Danica Dynamic Campaign - intel and fog of war (phase 4, pure Lua 5.1)
-- ----------------------------------------------------------------------------
-- Each side keeps a CONTACT table: what its units have actually seen, when,
-- how, and how precisely. The map and the mission board read this table, never
-- the true positions. Load after dcc_missions.lua.
--
--   contact key   what it is
--   m:<move>      an enemy column or convoy on a road
--   g:<node>      enemy garrison units seen at a node
--   sam:<node>    an enemy air-defence site
--   air:<group>   enemy aircraft
--   n:<node>      a recon report on a whole enemy base (phase 3 intel)
--
--   source        visual (eyes on), sensor (AI radar/optics), elint (radar
--                 emissions; position has an error that shrinks with more
--                 observations), recon (a recon pass)
--
--   age           fresh < staleTicks (30 min) - drawn solid, can be tasked
--                 stale < expireTicks (3 h)   - drawn faded "last seen ..."
--                 older                        - forgotten
--
-- Front-line estimate: every side sees roughly how strong the enemy bases right
-- on the front are (light / medium / heavy) - troops in contact know that much.
-- Exact numbers need recon.
-- ============================================================================

DCC = DCC or {}
local U = DCC.util
local War = DCC.War
local SIDES = { "blue", "red" }

local function I(self) return self.cfg.intel end

function War:initIntel()
  self.state.contacts = self.state.contacts or { blue = {}, red = {} }
end

-- data: { kind, node, pos = {x,z}, label, size, source, err }
function War:addContact(side, key, data)
  local list = self.state.contacts[side]
  local c = list[key]
  local fresh = c and (self.state.tick - c.seen) < I(self).staleTicks
  local oldErr, oldPos = c and c.err, c and c.pos
  c = c or { key = key }
  for k, v in pairs(data) do c[k] = v end
  -- ELINT: keep the better fix if a worse one arrives while the old is fresh
  if data.source == "elint" and fresh and oldErr and data.err and oldErr < data.err then
    c.err, c.pos = oldErr, oldPos
  end
  c.seen = self.state.tick
  list[key] = c
  return c
end

function War:contact(side, key) return self.state.contacts[side][key] end

function War:contactAge(side, key)
  local c = self.state.contacts[side][key]
  return c and (self.state.tick - c.seen) or math.huge
end

function War:isFresh(side, key)
  return self:contactAge(side, key) < I(self).staleTicks
end

function War:pruneContacts()
  for _, side in ipairs(SIDES) do
    for key, c in pairs(self.state.contacts[side]) do
      -- recon reports on whole bases are kept as long as recon intel counts
      local expire = (c.kind == "node") and self.cfg.ops.intelFreshTicks or I(self).expireTicks
      local gone = (c.kind == "move" and not self.state.moves[key:sub(3)])
      if self.state.tick - c.seen > expire or (gone and self.state.tick - c.seen > I(self).staleTicks) then
        self.state.contacts[side][key] = nil
      end
    end
  end
end

-- Rough strength of an enemy base on the front, or nil if not on the front.
function War:frontEstimate(side, id)
  local ns = self.state.nodes[id]
  if ns.side == side then return nil end
  local touching = false
  for nb in pairs(self.T.nodes[id].nb) do
    if self.state.nodes[nb].side == side then touching = true; break end
  end
  if not touching then return nil end
  local n = #ns.platoons
  if n == 0 then return "empty?" end
  if n <= 3 then return "light" end
  if n <= 8 then return "medium" end
  return "heavy"
end

-- What side knows about an enemy SAM site: "known" (fresh contact or recent
-- recon that saw it up), "stale", or nil.
function War:samKnown(side, id)
  local key = "sam:" .. id
  if self:isFresh(side, key) then return "known" end
  local i = self.state.intel[side] and self.state.intel[side][id]
  if i and i.sam == "up" and (self.state.tick - i.tick) < self.cfg.ops.intelFreshTicks then return "known" end
  if self:contact(side, key) then return "stale" end
  return nil
end

-- A contact for an enemy column, with where it was when seen (the map shows
-- that spot, not where the column is now).
function War:moveLabel(mv)
  local what = mv.cargo and "supply convoy" or (mv.kind == "assault" and "assault column" or "reinforcements")
  return string.format("%s (%d)", what, math.max(#mv.platoons, mv.cargo and 1 or 0))
end

function War:spotMove(side, mid, source, pos)
  local mv = self.state.moves[mid]
  if not mv or mv.side == side then return nil end
  return self:addContact(side, "m:" .. mid, { kind = "move", from = mv.from, to = mv.to,
    progress = mv.progress, pos = pos, source = source, label = self:moveLabel(mv) })
end

-- Recon also leaves a node contact (for drawing and aging), and reports the
-- enemy columns on the roads into and out of the base.
local baseRecordIntel = War.recordIntel
function War:recordIntel(side, id)
  baseRecordIntel(self, side, id)
  for _, mid in ipairs(U.sortedKeys(self.state.moves)) do
    local mv = self.state.moves[mid]
    if (mv.from == id or mv.to == id) and mv.kind ~= "airlift" then self:spotMove(side, mid, "recon") end
  end
  local ns = self.state.nodes[id]
  self:addContact(side, "n:" .. id, { kind = "node", node = id, source = "recon",
    label = string.format("%d plt, SAM %s", #ns.platoons, ns.sam and ns.sam.status or "none") })
  if ns.sam and ns.sam.status ~= "destroyed" then
    self:addContact(side, "sam:" .. id, { kind = "sam", node = id, source = "recon",
      label = "SAM site (" .. ns.sam.status .. ")", err = 500 })
  end
end

-- Troops in contact: every base sees enemy columns on the road within
-- groundObsKm of it, and anything attacking it.
function War:groundObservation()
  local km = I(self).groundObsKm or 0
  for _, mid in ipairs(U.sortedKeys(self.state.moves)) do
    local mv = self.state.moves[mid]
    if mv.kind ~= "airlift" then
      local toSide, fromSide = self.state.nodes[mv.to].side, self.state.nodes[mv.from].side
      local toKm, fromKm = mv.km * (1 - mv.progress), mv.km * mv.progress
      if toSide ~= mv.side and (mv.status == "fighting" or toKm <= km) then self:spotMove(toSide, mid, "sensor") end
      if fromSide ~= mv.side and fromKm <= km then self:spotMove(fromSide, mid, "sensor") end
    end
  end
end

function War:intelTick()
  self:groundObservation()
  self:pruneContacts()
end
