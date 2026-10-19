-- ============================================================================
-- Danica Dynamic Campaign - persistent pilot records (phase 3, pure Lua 5.1)
-- ----------------------------------------------------------------------------
-- One record per player, kept in its own file (Saved Games\DCS\DCC\pilots.json)
-- so it survives the end of a war and the move to the next map.
--
-- A player is identified by their DCS UCID when the server can read it, and
-- by their player name otherwise.
-- ============================================================================

DCC = DCC or {}
local U = DCC.util

local Pilots = {}
Pilots.__index = Pilots
DCC.Pilots = Pilots

-- Points per achievement. Score decides rank.
Pilots.POINTS = {
  kills_air = 10, kills_ground = 3, kills_convoy = 2, kills_sam = 8, kills_structure = 5,
  missions = 20, rescues = 25, deaths = -10, captured = -5, prisoners = 15,
  packages = 10, medevacs = 15, pows = 10,
  wins_conquest = 150,   -- flew for the side that conquered the whole map
  wins_clock = 50,       -- flew for the side that was ahead when the war clock ran out
}

Pilots.RANKS = {
  { 0, "Lieutenant" }, { 100, "Captain" }, { 300, "Major" },
  { 700, "Lieutenant Colonel" }, { 1500, "Colonel" }, { 3000, "General" },
}

function Pilots.new(data)
  local self = setmetatable({ data = data or { version = 1, pilots = {} }, dirty = false }, Pilots)
  self.data.pilots = self.data.pilots or {}
  return self
end

local FIELDS = { "sorties", "flightMinutes", "kills_air", "kills_ground", "kills_convoy", "kills_sam",
                 "kills_structure", "missions", "rescues", "deaths", "ejections", "captured", "saved",
                 "wins_conquest", "wins_clock", "prisoners", "packages", "medevacs", "pows" }

-- Squadron tag from a player name: "[VKG] Morten", "VKG | Morten", "-=VKG=- Morten",
-- "Morten [VKG]". Tags are 2-8 letters/digits; returned upper-case, or nil.
function Pilots.squadronOf(name)
  if type(name) ~= "string" then return nil end
  local tag = name:match("^%s*%[([%w_%-]+)%]") or name:match("^%s*([%w_%-]+)%s*|")
           or name:match("^%s*%-=([%w_]+)=%-") or name:match("%[([%w_%-]+)%]%s*$")
  if tag and #tag >= 2 and #tag <= 8 then return tag:upper() end
  return nil
end

function Pilots:get(key, name)
  local p = self.data.pilots[key]
  if not p then
    p = { name = name or key, sides = { blue = 0, red = 0 }, byType = {}, wars = {} }
    for _, f in ipairs(FIELDS) do p[f] = 0 end
    self.data.pilots[key] = p
    self.dirty = true
  end
  if name and p.name ~= name then p.name = name; self.dirty = true end
  local sq = Pilots.squadronOf(p.name)
  if sq ~= p.squadron then p.squadron = sq; self.dirty = true end
  return p
end

function Pilots:add(key, field, n, name)
  local p = self:get(key, name)
  p[field] = (p[field] or 0) + (n or 1)
  self.dirty = true
  return p
end

-- A completed mission, by type.
function Pilots:mission(key, mtype, name)
  local p = self:add(key, "missions", 1, name)
  p.byType[mtype] = (p.byType[mtype] or 0) + 1
end

function Pilots:sortie(key, side, theater, name)
  local p = self:add(key, "sorties", 1, name)
  p.sides[side] = (p.sides[side] or 0) + 1
  p.wars[theater] = true
end

-- War won: every pilot who did enough for the winner in this war - at least
-- minSorties sorties, or one completed mission, for that side.
-- roster = war.state.roster ({ [key] = { name, blue = sorties, red = sorties } }).
-- Returns the names that got the bonus.
function Pilots:warWon(roster, winner, how, minSorties)
  local field = (how == "conquest") and "wins_conquest" or "wins_clock"
  local names = {}
  for _, key in ipairs(U.sortedKeys(roster or {})) do
    local r = roster[key]
    if DCC.War.earnedVictory(r, winner, minSorties) then
      self:add(key, field, 1, r.name)
      names[#names + 1] = r.name or key
    end
  end
  return names, Pilots.POINTS[field]
end

function Pilots:score(key)
  local p = self.data.pilots[key]
  if not p then return 0 end
  local s = 0
  for f, pts in pairs(Pilots.POINTS) do s = s + (p[f] or 0) * pts end
  return s
end

function Pilots:rank(key)
  local s, r = self:score(key), Pilots.RANKS[1][2]
  for _, step in ipairs(Pilots.RANKS) do if s >= step[1] then r = step[2] end end
  return r
end

-- Position of a rank name in RANKS (1 = Lieutenant), or of a pilot's rank.
function Pilots.rankIndexOf(name)
  for i, step in ipairs(Pilots.RANKS) do if step[2] == name then return i end end
  return 1
end

function Pilots:rankIndex(key) return Pilots.rankIndexOf(self:rank(key)) end

function Pilots:summary(key)
  local p = self.data.pilots[key]
  if not p then return "No record yet - fly a sortie." end
  local types = {}
  for _, t in ipairs(U.sortedKeys(p.byType)) do types[#types + 1] = t .. " " .. p.byType[t] end
  local wars = U.sortedKeys(p.wars)
  return table.concat({
    string.format("%s %s  -  %d points%s", self:rank(key), p.name, self:score(key),
      p.squadron and ("  (squadron " .. p.squadron .. ")") or ""),
    string.format("Sorties %d (BLUE %d, RED %d), %d h %02d min in the air", p.sorties, p.sides.blue or 0,
      p.sides.red or 0, math.floor(p.flightMinutes / 60), math.floor(p.flightMinutes % 60)),
    string.format("Kills: air %d, ground %d, convoy trucks %d, SAM %d, buildings %d",
      p.kills_air, p.kills_ground, p.kills_convoy, p.kills_sam, p.kills_structure),
    string.format("Missions %d%s", p.missions, #types > 0 and (" (" .. table.concat(types, ", ") .. ")") or ""),
    string.format("Rescues flown %d, rescued %d times, ejections %d, deaths %d, captured %d",
      p.rescues, p.saved, p.ejections, p.deaths, p.captured),
    string.format("Wars won: %d by conquest, %d on the war clock", p.wins_conquest or 0, p.wins_clock or 0),
    "Theaters: " .. (#wars > 0 and table.concat(wars, ", ") or "-"),
  }, "\n")
end

-- Squadrons: members' scores added up, plus wars won by any member.
function Pilots:squadrons()
  local by = {}
  for key, p in pairs(self.data.pilots) do
    local sq = p.squadron or Pilots.squadronOf(p.name)
    if sq then
      local s = by[sq] or { tag = sq, score = 0, members = 0, wins = 0 }
      s.score = s.score + self:score(key)
      s.members = s.members + 1
      s.wins = s.wins + (p.wins_conquest or 0) + (p.wins_clock or 0)
      by[sq] = s
    end
  end
  local list = {}
  for _, s in pairs(by) do list[#list + 1] = s end
  table.sort(list, function(a, b) if a.score ~= b.score then return a.score > b.score end return a.tag < b.tag end)
  return list
end

function Pilots:topSquadrons(n)
  local out = {}
  for i, s in ipairs(self:squadrons()) do
    if i > n then break end
    out[i] = string.format("%2d. %-8s %6d points, %d pilots, %d war wins", i, s.tag, s.score, s.members, s.wins)
  end
  if #out == 0 then out[1] = "No squadrons yet. Put your tag in your name: [TAG] Name" end
  return out
end

-- Top N by score, for the leaderboard.
function Pilots:top(n)
  local list = {}
  for key in pairs(self.data.pilots) do list[#list + 1] = key end
  table.sort(list, function(a, b)
    local sa, sb = self:score(a), self:score(b)
    if sa ~= sb then return sa > sb end
    return a < b
  end)
  local out = {}
  for i = 1, math.min(n, #list) do
    local k = list[i]
    out[i] = string.format("%2d. %-12s %-20s %5d", i, self:rank(k), self.data.pilots[k].name, self:score(k))
  end
  return out
end
