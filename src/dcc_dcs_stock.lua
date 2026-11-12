-- ============================================================================
-- Danica Dynamic Campaign - DCS bridge: weapons stock pages (v0.59).
-- Load after dcc_dcs_slots.lua, before dcc_main.lua.
-- ----------------------------------------------------------------------------
-- Players could not tell what a base had on its shelves. Now (warehouse
-- armoury mode):
--   F10 > Support > Weapons stock here   the base you are at (airbase and its
--       FARP pads together): supply, then every weapon family with its count,
--       LOW (below stock.lowShare of a full shelf) or OUT
--   F10 > Support > Where is ... > <group> > <family>   your side's bases
--       holding it, nearest first, with counts and distance
--   the spawn message names what is low or out at your base
-- Counts are read live from the DCS warehouses, so they are exactly what the
-- re-arm menu offers. Families (AIM-120, Hellfire, Hydra 70 ...) are listed in
-- the catalogue (weapons.families).
-- ============================================================================

DCC = DCC or {}
local B = DCC.dcs
local U = DCC.util

local function SC() return DCC.config.stock end
local function ok(fn, ...) local s, r = pcall(fn, ...); if s then return r end end

local function families() return ((B.catalog or {}).weapons or {}).families or {} end

-- Family index of a DCS weapon name (first match, within its DCS category), cached.
B.famOf = {}
function B.familyOf(name)
  local c = B.famOf[name]
  if c ~= nil then return c or nil end
  local n = string.lower(name)
  local cat, rest = n:match("^weapons%.([^%.]+)%.(.+)$")
  local found = false
  if cat then
    for i, f in ipairs(families()) do
      if f[3] == cat then
        for _, pat in ipairs(f[4]) do
          if rest:find(pat, 1, true) then found = i; break end
        end
      end
      if found then break end
    end
  end
  B.famOf[name] = found
  return found or nil
end

-- The names of each family that the armoury uses.
local function familyNames()
  local out = {}
  for _, name in ipairs(B.arm and B.arm.names or {}) do
    local i = B.familyOf(name)
    if i then out[i] = out[i] or {}; table.insert(out[i], name) end
  end
  return out
end

-- Stock of one base: [family] = { count, full }. full = what the last restock put on the shelf.
function B.baseStock(id, side, only)
  local out = {}
  local whs = B.warehousesOf and B.warehousesOf(id, side) or {}
  if #whs == 0 then return out, 0 end
  local names = familyNames()
  for i, list in pairs(names) do
    if not only or only == i then
      local f = { count = 0, full = 0 }
      for k, w in ipairs(whs) do
        for _, name in ipairs(list) do
          local c = ok(w.getItemCount, w, name) or 0
          local last = B.arm.last and B.arm.last[id .. "|" .. k .. "|" .. name]
          f.count = f.count + c
          f.full = f.full + (last or c)
        end
      end
      out[i] = f
    end
  end
  return out, #whs
end

local function state(f)
  if f.full <= 0 and f.count <= 0 then return nil end
  if f.count <= 0 then return "OUT" end
  if f.count < SC().lowShare * f.full then return "LOW" end
  return ""
end

-- "Low: HARM / anti-radar (4). Out: Hellfire." or nil when all is well.
function B.stockShortText(id, side)
  local stock = B.baseStock(id, side)
  local low, out = {}, {}
  for i, f in ipairs(families()) do
    local s = stock[i] and state(stock[i])
    if s == "LOW" then low[#low + 1] = string.format("%s (%d)", f[1], stock[i].count)
    elseif s == "OUT" then out[#out + 1] = f[1] end
  end
  local parts = {}
  if #low > 0 then parts[#parts + 1] = "Low: " .. table.concat(low, ", ") .. "." end
  if #out > 0 then parts[#parts + 1] = "Out: " .. table.concat(out, ", ") .. "." end
  return #parts > 0 and table.concat(parts, " ") or nil
end

function B.stockPage(id, side)
  local war = B.war
  local ns = war.state.nodes[id]
  local stock, nw = B.baseStock(id, side)
  local lines = { string.format("WEAPONS STOCK - %s (supply %d %%)", war:nodeName(id),
    math.floor(100 * (ns.supply or 0) / math.max(1, war:supplyCap(id)) + 0.5)) }
  if nw == 0 then
    lines[#lines + 1] = "No warehouse here (no airfield or FARP)."
    return table.concat(lines, "\n")
  end
  local groups, order = {}, {}
  for i, f in ipairs(families()) do
    local s = stock[i] and state(stock[i])
    if s then
      if not groups[f[2]] then groups[f[2]] = {}; order[#order + 1] = f[2] end
      table.insert(groups[f[2]], string.format("%s %d%s", f[1], stock[i].count, s ~= "" and (" " .. s) or ""))
    end
  end
  if #order == 0 then lines[#lines + 1] = "No weapons on the shelf." end
  for _, g in ipairs(order) do lines[#lines + 1] = g .. ": " .. table.concat(groups[g], " | ") end
  lines[#lines + 1] = "Pods, tanks and guns are always on the shelf. Shelves are topped up every 5 min while the"
  lines[#lines + 1] = "base has supply - bring supply (convoy, airlift, crates) to keep them full."
  return table.concat(lines, "\n")
end

local function playerBase(p, u)
  local pos = ok(u.getPoint, u)
  if not pos then return nil end
  return B.nearestNodeOf(pos, p.side, 5000) or B.nearestNodeOf(pos, p.side)
end

-- F10 > Support > Weapons stock here (replaces the armoury line in warehouse mode)
local baseShow = B.showArmoury
function B.showArmoury(uname)
  if not (B.armWarehouseMode and B.armWarehouseMode()) then return baseShow(uname) end
  local p = B.players[uname]
  local u = p and ok(Unit.getByName, uname)
  local id = u and playerBase(p, u)
  if id then trigger.action.outTextForGroup(p.gid, B.stockPage(id, p.side), SC().showSec) end
end

-- F10 > Support > Where is ... > family
function B.whereIs(args)
  local p = B.players[args.unit]
  local u = p and ok(Unit.getByName, args.unit)
  if not u then return end
  local pos = u:getPoint()
  local war, rows = B.war, {}
  for _, id in ipairs(war.T.order) do
    if war.state.nodes[id].side == p.side and B.nodePos[id] then
      local stock, nw = B.baseStock(id, p.side, args.fam)
      local f = stock[args.fam]
      if nw > 0 and f and f.count > 0 then
        local np = B.nodePos[id]
        local d = math.sqrt((np.x - pos.x) ^ 2 + (np.z - pos.z) ^ 2) / 1000
        rows[#rows + 1] = { id = id, d = d, f = f }
      end
    end
  end
  table.sort(rows, function(a, b) return a.d < b.d end)
  local fam = families()[args.fam]
  local lines = { string.format("WHERE IS %s (%s bases, nearest first)", fam[1], p.side:upper()) }
  for i = 1, math.min(#rows, SC().whereMax) do
    local r = rows[i]
    local s = state(r.f)
    lines[#lines + 1] = string.format("%s, %d km: %d%s", war:nodeName(r.id), math.floor(r.d + 0.5), r.f.count,
      (s and s ~= "") and (" " .. s) or "")
  end
  if #rows == 0 then lines[#lines + 1] = "Not on the shelf at any of your bases." end
  trigger.action.outTextForGroup(p.gid, table.concat(lines, "\n"), SC().showSec)
end

local baseSupport = B.buildSupportMenu
function B.buildSupportMenu(p)
  baseSupport(p)
  if not (p.gid and p.supportMenu and B.armWarehouseMode and B.armWarehouseMode()) then return end
  local fams = families()
  if #fams == 0 then return end
  local where = missionCommands.addSubMenuForGroup(p.gid, "Where is ...", p.supportMenu)
  local subs, n = {}, {}
  for i, f in ipairs(fams) do
    local g = f[2]
    if not subs[g] then subs[g] = missionCommands.addSubMenuForGroup(p.gid, g, where); n[g] = 0 end
    n[g] = n[g] + 1
    if n[g] <= 10 then
      missionCommands.addCommandForGroup(p.gid, f[1], subs[g], B.whereIs, { unit = p.unit, fam = i })
    end
  end
end

-- the spawn message: what is low or out here
local baseText = B.armouryText
function B.armouryText(id)
  local t = baseText(id)
  if SC().onSpawn and B.armWarehouseMode and B.armWarehouseMode() then
    local side = B.war.state.nodes[id].side
    local short = (side == "blue" or side == "red") and B.stockShortText(id, side)
    t = t .. "\n" .. (short or "Every weapon family is well stocked.") ..
      " F10 > Support > Weapons stock here / Where is ..."
  end
  return t
end

local baseInit = B.init
function B.init(war, theater, catalog)
  baseInit(war, theater, catalog)
  B.famOf = {}
end
