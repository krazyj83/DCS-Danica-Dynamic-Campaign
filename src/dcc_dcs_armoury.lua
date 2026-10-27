-- ============================================================================
-- Danica Dynamic Campaign - DCS bridge: armoury by warehouse stock.
-- Load after dcc_dcs_ext_air.lua.
-- ----------------------------------------------------------------------------
-- ext.armoury.mode = "warehouse" (the mission must have limited munitions):
-- instead of recalling aircraft at take-off, every airbase's and FARP's
-- warehouse is stocked by the base's supply, so the re-arm menu itself only
-- offers what the base has.
--     basic    (bombs, rockets, tanks, pods)       always, free
--     guided   (IR missiles, laser / TV weapons)    from 30 % supply, 0.5 SU each
--     advanced (radar / anti-radiation / GPS ...)   from 60 % supply, 1 SU each
-- Shelves are topped up every 5 min. What pilots took since the last top-up
-- is paid from the base's supply; weapons above the base's tier come off the shelf.
--
-- Weapon names come from DCS itself (Warehouse.getResourceMap, or a
-- warehouse inventory), else from the catalogue's list. Each name is tested
-- once (setItem / getItemCount) and only names DCS accepts are used.
-- F10 > Armoury test shows what was found, so a server test can confirm it.
-- ============================================================================

DCC = DCC or {}
local B = DCC.dcs
local U = DCC.util

local function AC() return DCC.config.ext.armoury end
local function ok(fn, ...) local s, r = pcall(fn, ...); if s then return r end end

B.arm = { names = {}, tier = {}, source = "none", tested = 0, accepted = 0, rejected = {}, page = 1 }

-- if a mission sets DCC_ARMOURY_MODE before loading the engine, it wins
if DCC_ARMOURY_MODE then DCC.config.ext.armoury.mode = DCC_ARMOURY_MODE end
-- a test mission keeps its own saves and pilot records, and ignores the map rotation
if DCC_TEST_MISSION then
  DCC.config.saveFolder = "DCC_test"
  DCC.config.rotationEnforce = false
  DCC.config.ext.armoury.testMenu = true
end

function B.armWarehouseMode() return AC().mode == "warehouse" end

-- ===========================================================================
-- Tier of a weapon by its DCS resource name
-- ===========================================================================
-- Missiles: every missile is at least "guided"; these are "advanced"
-- (radar-guided air-to-air, anti-radiation, anti-ship, cruise, stand-off).
local ADV_MISSILE = { "aim_120", "aim120", "aim-120", "aim_7", "aim7", "aim-7", "aim_54", "aim54", "aim-54", "r_77", "r-77",
              "r_27", "r-27", "sd_10", "sd-10", "pl_12", "pl-12", "r_33", "r-33", "r_37", "r-37", "r_40", "r-40",
              "agm_88", "agm-88", "harm", "kh_58", "kh-58", "x_58", "kh_25mp", "kh-25mp", "x_25mp", "kh_31", "kh-31", "x_31",
              "agm_84", "agm-84", "harpoon", "slam", "kh_35", "kh-35", "x_35", "kh_59", "kh-59", "x_59", "agm_154", "agm-154",
              "c_802", "c-802", "yj_", "yj-", "agm_158", "storm_shadow", "scalp", "aim_260", "aim-260", "meteor", "derby",
              "mica_em", "super_530d", "super530d", "lj_7", "cm-400", "cm_400", "c_701ir" }
-- Bombs: unguided unless they match these; "advanced" first (GPS / glide), then "guided" (laser / TV).
local ADV_BOMB = { "gbu_31", "gbu-31", "gbu_32", "gbu-32", "gbu_38", "gbu-38", "gbu_39", "gbu-39", "gbu_54", "gbu-54",
                   "gbu_53", "jdam", "kab_500s", "kab-500s", "ls_6", "ls-6", "gb_6", "gb-6", "agm_154", "jsow", "lj_7" }
local GUIDED_BOMB = { "gbu_", "gbu-", "kab_", "kab-", "lgb", "paveway", "bgl", "agm_62", "walleye" }
-- Rockets: unguided unless laser-guided
local GUIDED_ROCKET = { "apkws", "agr_20", "agr-20" }

local function has(name, list)
  for _, p in ipairs(list) do if name:find(p, 1, true) then return true end end
  return false
end

-- By DCS's own category first (weapons.<category>.<name>), then by name.
-- Adapters, launchers, pods, tanks, guns and everything else are "basic":
-- always on the shelf, so a loadout never fails for want of a pylon.
function B.weaponTier(name)
  local n = string.lower(name)
  local cat = n:match("^weapons%.([^%.]+)%.") or ""
  if cat == "missiles" then
    return has(n, ADV_MISSILE) and "advanced" or "guided"
  elseif cat == "bombs" then
    if has(n, ADV_BOMB) then return "advanced" end
    if has(n, GUIDED_BOMB) then return "guided" end
    return "basic"
  elseif cat == "nurs" or cat == "rockets" then
    return has(n, GUIDED_ROCKET) and "guided" or "basic"
  end
  return "basic"
end

-- ===========================================================================
-- Finding the names DCS uses
-- ===========================================================================
local function addName(set, list, name)
  if type(name) == "string" and name:find("^weapons%.") and not set[name] then
    set[name] = true
    list[#list + 1] = name
  end
end

local function anyWarehouse()
  for id, name in pairs(B.airbases or {}) do
    local ab = ok(Airbase.getByName, name)
    local w = ab and ok(ab.getWarehouse, ab)
    if w then return w, id end
  end
end

function B.discoverWeapons()
  local set, list = {}, {}
  -- 1. the full resource list, when this DCS version has it
  if Warehouse and Warehouse.getResourceMap then
    local map = ok(Warehouse.getResourceMap)
    if type(map) == "table" then
      for k, v in pairs(map) do
        addName(set, list, k)
        if type(v) == "table" then addName(set, list, v.name or v.typeName) end
      end
      if #list > 0 then B.arm.source = "getResourceMap" end
    end
  end
  -- 2. what a warehouse holds right now
  if #list == 0 then
    local w = anyWarehouse()
    local inv = w and ok(w.getInventory, w)
    if type(inv) == "table" then
      for k in pairs(inv.weapon or inv.weapons or {}) do addName(set, list, k) end
      if #list > 0 then B.arm.source = "inventory" end
    end
  end
  -- 3. the catalogue's list (always added: covers what DCS did not report)
  local before = #list
  for _, n in ipairs((B.catalog.weapons or {}).names or {}) do addName(set, list, n) end
  if B.arm.source == "none" and #list > before then B.arm.source = "catalogue" end
  table.sort(list)
  return list
end

-- Keep only names DCS accepts: set 1, read it back, put it back.
function B.testWeaponNames(list)
  local w = anyWarehouse()
  local okNames, rejected = {}, {}
  if not w then return okNames, list end
  for _, name in ipairs(list) do
    local before = ok(w.getItemCount, w, name) or 0
    ok(w.setItem, w, name, before + 1)
    local after = ok(w.getItemCount, w, name)
    ok(w.setItem, w, name, before)
    if after == before + 1 then okNames[#okNames + 1] = name else rejected[#rejected + 1] = name end
  end
  return okNames, rejected
end

function B.armouryInit()
  local list = B.discoverWeapons()
  local names, rejected = B.testWeaponNames(list)
  B.arm.names, B.arm.rejected, B.arm.tested, B.arm.accepted = names, rejected, #list, #names
  B.arm.tier = {}
  for _, n in ipairs(names) do B.arm.tier[n] = B.weaponTier(n) end
  U.log("armoury: %d weapon names from %s, %d accepted by the warehouse", #list, B.arm.source, #names)
  if #names == 0 then
    U.log("ERROR armoury: no weapon names accepted - the re-arm menu would be empty")
    trigger.action.outText("ARMOURY: no weapon names found. Use the normal mission (unlimited munitions).", 60)
  end
end

-- ===========================================================================
-- Stocking
-- ===========================================================================
local ORDER = { basic = 1, guided = 2, advanced = 3 }

local function warehousesOf(id, side)
  local out = { farp = {} }
  local name = B.airbases and B.airbases[id]
  local ab = name and ok(Airbase.getByName, name)
  local w = ab and ok(ab.getWarehouse, ab)
  if w then out[#out + 1] = w end
  if B.war:canHaveFarp(id) and B.war:farpAt(id) then
    for _, pad in ipairs(B.farpPadNames and B.farpPadNames(id, side) or { "DCC_FARP_" .. id .. "_" .. side }) do
      local fab = ok(Airbase.getByName, pad)
      local fw = fab and ok(fab.getWarehouse, fab)
      if fw then out[#out + 1] = fw; out.farp[#out] = true end
    end
  end
  return out
end

function B.restockArmoury()
  if not B.armWarehouseMode() or #B.arm.names == 0 then return end
  local war, cfg = B.war, AC()
  B.arm.last = B.arm.last or {}
  for _, id in ipairs(war.T.order) do
    local ns = war.state.nodes[id]
    local whs = (ns.side == "blue" or ns.side == "red") and warehousesOf(id, ns.side) or {}
    if #whs > 0 then
      local tier = war:armouryTier(id)
      local big = war.T.nodes[id].depot and (cfg.depotStock or 1) or 1
      for k, w in ipairs(whs) do
        for _, name in ipairs(B.arm.names) do
          local t = B.arm.tier[name]
          local key = id .. "|" .. k .. "|" .. name
          local cur = ok(w.getItemCount, w, name) or 0
          -- what pilots took since the last restock is paid for now
          local taken = math.max(0, (B.arm.last[key] or cur) - cur)
          local each = (t == "advanced" and cfg.advancedSU) or (t == "guided" and cfg.guidedSU) or 0
          if taken > 0 and each > 0 then ns.supply = math.max(0, (ns.supply or 0) - taken * each) end
          local target = (ORDER[t] <= ORDER[tier]) and (cfg.stock[t] or 0) * big or 0
          if whs.farp[k] and war:farpDry(id) then target = 0 end      -- a dry FARP: empty shelves
          if cur ~= target then ok(w.setItem, w, name, target) end   -- top up, or off the shelf
          B.arm.last[key] = target
        end
      end
    end
  end
end

-- the take-off recall is not needed: what is on the shelf is what you get
local baseTakeoff = B.armouryTakeoff
function B.armouryTakeoff(p, u)
  if B.armWarehouseMode() then return end
  return baseTakeoff(p, u)
end
local baseTaxi = B.armouryCheckTaxi
function B.armouryCheckTaxi(p, u)
  if B.armWarehouseMode() then return end
  return baseTaxi(p, u)
end

-- ===========================================================================
-- F10 > Armoury test (warehouse mode only)
-- ===========================================================================
local function tierCounts()
  local c = { basic = 0, guided = 0, advanced = 0 }
  for _, n in ipairs(B.arm.names) do c[B.arm.tier[n]] = c[B.arm.tier[n]] + 1 end
  return c
end

function B.armouryReport()
  local c = tierCounts()
  local lines = {
    "ARMOURY TEST",
    string.format("Warehouse.getResourceMap: %s", (Warehouse and Warehouse.getResourceMap) and "yes" or "no"),
    string.format("Names from: %s. Tested %d, accepted %d, rejected %d.", B.arm.source, B.arm.tested, B.arm.accepted,
      #B.arm.rejected),
    string.format("Tiers: basic %d, guided %d, advanced %d.", c.basic, c.guided, c.advanced),
  }
  for _, t in ipairs({ "guided", "advanced" }) do
    local s = {}
    for _, n in ipairs(B.arm.names) do
      if B.arm.tier[n] == t and #s < 12 then s[#s + 1] = n:gsub("^weapons%.", "") end
    end
    lines[#lines + 1] = t .. ": " .. table.concat(s, ", ")
  end
  if #B.arm.rejected > 0 then
    local s = {}
    for i = 1, math.min(8, #B.arm.rejected) do s[i] = B.arm.rejected[i]:gsub("^weapons%.", "") end
    lines[#lines + 1] = "rejected (sample): " .. table.concat(s, ", ")
  end
  trigger.action.outText(table.concat(lines, "\n"), 60)
end

function B.armouryListPage()
  local per, names = 40, B.arm.names
  local pages = math.max(1, math.ceil(#names / per))
  local pg = ((B.arm.page - 1) % pages) + 1
  local s = {}
  for i = (pg - 1) * per + 1, math.min(#names, pg * per) do
    s[#s + 1] = string.format("%s [%s]", names[i]:gsub("^weapons%.", ""), B.arm.tier[names[i]]:sub(1, 1))
  end
  trigger.action.outText(string.format("ARMOURY names page %d/%d (b/g/a = tier)\n%s", pg, pages, table.concat(s, "\n")), 60)
  B.arm.page = pg + 1
end

function B.armouryBaseReport(side)
  local war = B.war
  local lines = { "ARMOURY STOCK (" .. side:upper() .. " bases)" }
  for _, id in ipairs(war.T.order) do
    local ns = war.state.nodes[id]
    if ns.side == side and B.airbases and B.airbases[id] and #lines < 12 then
      local w = warehousesOf(id, side)[1]
      local c = { basic = 0, guided = 0, advanced = 0 }
      for _, n in ipairs(B.arm.names) do
        if (w and ok(w.getItemCount, w, n) or 0) > 0 then c[B.arm.tier[n]] = c[B.arm.tier[n]] + 1 end
      end
      lines[#lines + 1] = string.format("%s: tier %s, supply %d%% - types on the shelf: %d basic, %d guided, %d advanced",
        war:nodeName(id), war:armouryTier(id), math.floor(100 * (ns.supply or 0) / math.max(1, war:supplyCap(id))),
        c.basic, c.guided, c.advanced)
    end
  end
  trigger.action.outText(table.concat(lines, "\n"), 45)
end

function B.armourySetSupply(args)
  -- test helper: every base of a side to a supply share, restock now
  local war, n = B.war, 0
  for _, id in ipairs(war.T.order) do
    local ns = war.state.nodes[id]
    if ns.side == args.side then
      ns.supply = war:supplyCap(id) * args.share
      n = n + 1
    end
  end
  B.restockArmoury()
  trigger.action.outText(string.format("TEST: all %d %s bases at %d%% supply - tier %s. Re-open the re-arm menu.",
    n, args.side:upper(), math.floor(args.share * 100), args.tier), 20)
end

function B.addArmouryTestMenu()
  if not AC().testMenu then return end
  for side, c in pairs(B.COAL) do
    local root = missionCommands.addSubMenuForCoalition(c, "Armoury test")
    missionCommands.addCommandForCoalition(c, "Report: what DCS gave us", root, B.armouryReport)
    missionCommands.addCommandForCoalition(c, "List the names (next page)", root, B.armouryListPage)
    missionCommands.addCommandForCoalition(c, "Stock at my side's bases", root, B.armouryBaseReport, side)
    missionCommands.addCommandForCoalition(c, "All bases 10 % supply (basic)", root, B.armourySetSupply,
      { side = side, share = 0.1, tier = "basic" })
    missionCommands.addCommandForCoalition(c, "All bases 45 % supply (guided)", root, B.armourySetSupply,
      { side = side, share = 0.45, tier = "guided" })
    missionCommands.addCommandForCoalition(c, "All bases 90 % supply (advanced)", root, B.armourySetSupply,
      { side = side, share = 0.9, tier = "advanced" })
  end
end

-- ===========================================================================
-- Wiring
-- ===========================================================================
local baseInit = B.init
function B.init(war, theater, catalog)
  baseInit(war, theater, catalog)
  B.arm = { names = {}, tier = {}, source = "none", tested = 0, accepted = 0, rejected = {}, page = 1 }
  if B.armWarehouseMode() then
    B.armouryInit()
    B.restockArmoury()
  end
end

local baseAddMenus = B.addMenus
function B.addMenus()
  baseAddMenus()
  if B.armWarehouseMode() then B.addArmouryTestMenu() end
end

local baseTick = B.opsTick
function B.opsTick()
  baseTick()
  if B.armWarehouseMode() then ok(B.restockArmoury) end
end

local baseText = B.armouryText
function B.armouryText(id)
  local t = baseText(id)
  if B.armWarehouseMode() then
    t = t:gsub("Guided weapons cost", "The re-arm menu shows what is on the shelf. Guided weapons cost")
  end
  return t
end
