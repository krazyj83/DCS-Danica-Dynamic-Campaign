-- ============================================================================
-- Danica Dynamic Campaign - DCS bridge: VEAF CTLD v2 as the helicopter
-- logistics layer.  Load after dcc_dcs_ground.lua, before dcc_main.lua.
-- ----------------------------------------------------------------------------
-- The mission loads CTLD.lua (with ctld.dontInitialize = true) before our
-- bundle. When CTLD is there, this module
--   * configures it: no ME zones or pilot-name lists, CTLD's JTAC switched
--     off (ours does CAS), and a "Supply crate" added to the crate list;
--   * gives every own base a CTLD pickup (troops) and logistic (crates)
--     zone, and moves them to the other side when the base is captured;
--   * makes crates cost the base's supply (refused when the base is dry);
--   * turns CTLD actions into war-model events:
--       supply crate unloaded at an own base   -> supply delivered (LOGISTICS)
--       FOB built next to a town               -> the town gets a FARP
--       AA system set up next to an own base   -> base dug in one level
--       vehicle unpacked / set down at own base -> joins the garrison as a
--                                                 platoon (artillery: a battery,
--                                                 trucks: their load as supply)
--       troops picked up at a base             -> a platoon leaves the garrison
--       troops unloaded at an own base         -> reinforcement
--       troops unloaded at an enemy base       -> air assault
--       troops unloaded in the field           -> tracked; lost if killed
--       helicopter lost with troops on board   -> platoon lost
--   * removes our own F10 "Cargo" menu (CTLD's menu replaces it).
-- Without CTLD in the mission nothing here runs and the old Cargo menu stays.
-- ============================================================================

DCC = DCC or {}
local B = DCC.dcs
local U = DCC.util

B.ctld = { zones = {}, zoneNode = {}, field = {}, hooked = false }

local function CC() return DCC.config.ctld end
local function ok(fn, ...) local s, r = pcall(fn, ...); if s then return r end end
local function sideOf(coal) return coal == 2 and "blue" or (coal == 1 and "red" or nil) end
local function coalOf(side) return side == "blue" and 2 or 1 end
local function say(unit, text)
  local g = unit and ok(unit.getGroup, unit)
  local gid = g and ok(g.getID, g)
  if gid then trigger.action.outTextForGroup(gid, text, 12) end
end
local function playerOf(uname) return uname and B.players[uname] end

function B.ctldPresent()
  return DCC.config.ctld.enabled ~= false and type(CTLDConfig) == "table" and type(ctld) == "table"
    and type(ctld.initialize) == "function" and type(CTLDZoneManager) == "table"
end

-- ===========================================================================
-- 1. Configuration (before ctld.initialize)
-- ===========================================================================
local function isJtacGroup(g)
  return type(g) == "table" and (tonumber(g.jtac) or 0) > 0
end

function B.ctldConfigure()
  local cfg = CTLDConfig.get()
  cfg:load()                                         -- idempotent; parses the default YAML
  local set = function(k, v) cfg:setSetting(k, v) end
  -- our missions have no ME zones or named transport slots: every helicopter
  -- type CTLD knows can lift, and zones come from the bases (section 2)
  set("troopZones", {})
  set("logisticUnits", {})
  set("transportPilotNames", {})
  set("wpZones", {})
  set("aiZones", {})
  set("extractableGroups", {})
  -- troops come out of base garrisons only (a CTLD FOB or FARP is not a barracks)
  set("troopPickupAtFOB", false)
  set("troopPickupAtFARP", false)
  -- our JTAC handles CAS; CTLD's JTACs (crates, drones, JTAC troops) are off
  set("JTAC_LIMIT_BLUE", 0)
  set("JTAC_LIMIT_RED", 0)
  set("JTAC_dropEnabled", false)
  local groups = {}
  for _, g in ipairs(ctld.gs("loadableGroups") or {}) do
    if not isJtacGroup(g) then groups[#groups + 1] = g end
  end
  set("loadableGroups", groups)
  local crates = {}
  for cat, list in pairs(ctld.gs("spawnableCrates") or {}) do
    local keep = {}
    for _, c in ipairs(list) do
      if not c.isJTAC then keep[#keep + 1] = c end
    end
    if #keep > 0 then crates[cat] = keep end
  end
  -- RED's light vehicles (BLUE has its Humvees already): the UAZ flies whole, the Tigr in crates
  local cv = crates["Combat Vehicles"] or {}
  local have = {}
  for _, c in ipairs(cv) do have[c.unit] = true end
  if not have["Tigr_233036"] then
    cv[#cv + 1] = { unit = "Tigr_233036", desc = "Tigr - recon", weight = 1000.13, cratesRequired = 2, side = 1 }
  end
  if not have["UAZ-469"] then
    cv[#cv + 1] = { unit = "UAZ-469", desc = "UAZ - light", weight = 1000.14, cratesRequired = 1, side = 1 }
  end
  crates["Combat Vehicles"] = cv
  -- the supply crate: never unpacked; unloaded at an own base it is supply
  crates["Supply"] = { { unit = "DCC_SUPPLY", desc = string.format("Supply crate (%d SU)", CC().supplyCrateSU),
                         weight = CC().supplyWeight, cratesRequired = 1, dccSupply = true } }
  set("spawnableCrates", crates)
  local weights = ctld.gs("groundVehicleWeights") or {}
  for t, kg in pairs(CC().vehicleWeights or {}) do weights[t] = kg end
  set("groundVehicleWeights", weights)
  -- whole vehicles in a helicopter or transport: light vehicles only (no APCs, no tanks)
  local wv = CC().wholeVehicles or {}
  for _, caps in pairs(ctld.gs("capabilitiesByType") or {}) do
    if type(caps) == "table" and caps.loadableVehiclesBLUE then caps.loadableVehiclesBLUE = U.copy(wv.blue or {}) end
    if type(caps) == "table" and caps.loadableVehiclesRED then caps.loadableVehiclesRED = U.copy(wv.red or {}) end
  end
end

-- ===========================================================================
-- 2. Zones follow base ownership
-- ===========================================================================
local function zoneRadius(id)
  return (B.war.T.nodes[id].kind == "airbase") and CC().zoneRadiusAirbaseM or CC().zoneRadiusM
end

function B.ctldSyncZones()
  local zm = CTLDZoneManager.getInstance()
  local war = B.war
  for _, id in ipairs(war.T.order) do
    local ns, kind = war.state.nodes[id], war.T.nodes[id].kind
    local side = ns.side
    local want = (side == "blue" or side == "red") and kind ~= "carrier" and B.nodePos[id] and coalOf(side) or nil
    local have = B.ctld.zones[id]
    if have and have.coal ~= want then
      ok(zm.unregisterLogistic, zm, have.name)
      ok(zm.unregisterTroopZone, zm, have.name)
      B.ctld.zones[id], B.ctld.zoneNode[have.name] = nil, nil
      have = nil
    end
    if want and not have then
      local p = B.nodePos[id]
      local pt = { x = p.x, y = land.getHeight({ x = p.x, y = p.z }), z = p.z }
      local name = war:nodeName(id)
      ok(zm.registerFOBAsLogistic, zm, name, pt, zoneRadius(id), want)
      ok(zm.registerFOBAsTroopZone, zm, name, pt, zoneRadius(id), want)
      B.ctld.zones[id] = { name = name, coal = want }
      B.ctld.zoneNode[name] = id
    end
  end
end

-- The base that pays for a crate requested at this point: our own zone, or
-- the nearest own base behind a FOB.
local function payingNode(pos, side)
  for id, z in pairs(B.ctld.zones) do
    if z.coal == coalOf(side) then
      local p = B.nodePos[id]
      local dx, dz = pos.x - p.x, pos.z - p.z
      if math.sqrt(dx * dx + dz * dz) <= zoneRadius(id) then return id end
    end
  end
  return B.nearestNodeOf(pos, side, CC().fobChargeKm * 1000)
end

-- ===========================================================================
-- 3. Crates
-- ===========================================================================
local function charge(unit, nCrates)
  local side = sideOf(ok(unit.getCoalition, unit))
  local pos = ok(unit.getPoint, unit)
  if not side or not pos then return true end
  local node = payingNode(pos, side)
  if not node then return true end                    -- a mission-maker zone: free
  local su = CC().crateSU * nCrates
  if B.war:takeCrate(node, su) <= 0 then
    say(unit, string.format("%s has no supply to spare (%d SU needed, %d left).", B.war:nodeName(node), su,
      math.floor(B.war.state.nodes[node].supply or 0)))
    return false
  end
  return true, node, su
end

local function refund(node, su)
  if node and su then
    local ns = B.war.state.nodes[node]
    ns.supply = (ns.supply or 0) + su
  end
end

local function isSupply(desc) return type(desc) == "table" and desc.dccSupply == true end

-- A supply crate on the ground near an own base: delivered.
function B.ctldCrateDown(crate, pos)
  if not (crate and isSupply(crate.descriptor) and pos) then return false end
  local side = sideOf(crate.coalition)
  if not side then return false end
  local node = B.nearestNodeOf(pos, side, CC().dropKm * 1000)
  if not node then return false end
  B.war:deliverCrate(side, node, CC().supplyCrateSU)
  local mgr = CTLDCrateManager.getInstance()
  ok(mgr.destroyCrate, mgr, crate.crateName)
  trigger.action.outTextForCoalition(coalOf(side), string.format("Supply crate delivered to %s (+%d SU).",
    B.war:nodeName(node), CC().supplyCrateSU), 10)
  return true
end

-- ===========================================================================
-- 4. Troops
-- ===========================================================================
local function lastInTransit(tm, uname)
  local list = tm._inTransit and tm._inTransit[uname]
  return list and list[#list]
end

local function addToPlayer(uname, pids)
  local p = playerOf(uname)
  if p then for _, pid in ipairs(pids) do p.troops[#p.troops + 1] = pid end end
end

local function removeFromPlayers(pids)
  for _, p in pairs(B.players) do
    for _, pid in ipairs(pids) do U.removeValue(p.troops, pid) end
  end
end

-- Platoons a CTLD troop template stands for: one per ~10 soldiers.
function B.ctldPlatoonsFor(template)
  return math.max(1, math.floor(((template and template.total) or 10) / 10 + 0.5))
end

local function pickPlatoons(node, n)
  local war = B.war
  local list = war:sortedGarrison(node, false)
  local out = {}
  -- mechanised first (they are the ones that ride), never the last platoon
  for i = #list, 1, -1 do
    if #out < n and #list - #out > 1 and war.state.platoons[list[i]].role == "MECH_PLT" then out[#out + 1] = list[i] end
  end
  for i = #list, 1, -1 do
    local taken = false
    for _, p in ipairs(out) do if p == list[i] then taken = true end end
    if not taken and #out < n and #list - #out > 1 then out[#out + 1] = list[i] end
  end
  return out
end

-- Troops are on the ground at pos (landed, fast-roped or by parachute).
function B.ctldTroopsDown(troopGroup, dcsGroup, pos, side)
  local pids = troopGroup and troopGroup._dccPids
  if not pids or troopGroup._dccDone then return end
  troopGroup._dccDone = true
  removeFromPlayers(pids)
  local war = B.war
  local gname = dcsGroup and ok(dcsGroup.getName, dcsGroup)
  local node = pos and B.nearestNodeOf(pos, nil, CC().dropKm * 1000)
  if node then
    local r = war:dropPlatoons(pids, node, side)
    if r == "reinforced" then
      -- they join the garrison: the bubble spawns them with it from now on
      timer.scheduleFunction(function()
        local g = gname and ok(Group.getByName, gname)
        if g and ok(g.isExist, g) then ok(g.destroy, g) end
      end, nil, timer.getTime() + 60)
      trigger.action.outTextForCoalition(coalOf(side), string.format("Troops landed at %s and joined the garrison.",
        war:nodeName(node)), 10)
    elseif r == "assault" then
      trigger.action.outTextForCoalition(coalOf(side), string.format("Air assault on %s!", war:nodeName(node)), 15)
    end
    return
  end
  if gname then B.ctld.field[gname] = pids         -- out in the field: still carried
  else for _, pid in ipairs(pids) do war:returnCarried(pid) end end   -- counted into an ME objective zone
end

-- Field troops killed -> lost; re-embarked -> handled by the embarkFromField hook.
function B.ctldPollField()
  for gname, pids in pairs(B.ctld.field) do
    local g = ok(Group.getByName, gname)
    local n = 0
    if g and ok(g.isExist, g) then
      for _, u in ipairs(ok(g.getUnits, g) or {}) do if ok(u.isExist, u) then n = n + 1 end end
    end
    if n == 0 then
      for _, pid in ipairs(pids) do B.war:loseCarried(pid) end
      B.ctld.field[gname] = nil
    end
  end
end

-- ===========================================================================
-- 5. Hooks into CTLD
-- ===========================================================================
function B.ctldHook()
  if B.ctld.hooked then return end
  B.ctld.hooked = true
  local TM, CM, VS = CTLDTroopManager, CTLDCrateManager, CTLDVehicleSpawner

  -- troops board at one of our bases: platoons leave the garrison
  local baseEmbark = TM.embarkFromTroopZone
  TM.embarkFromTroopZone = function(self, unit, zone, template)
    local node = zone and B.ctld.zoneNode[zone.zoneName or ""]
    if not node or not B.war then return baseEmbark(self, unit, zone, template) end
    local want = B.ctldPlatoonsFor(template)
    local spare = #B.war.state.nodes[node].platoons - 1
    if spare < want then
      say(unit, string.format("%s cannot spare %d platoon(s) (%d to spare).", B.war:nodeName(node), want,
        math.max(0, spare)))
      return false
    end
    if not baseEmbark(self, unit, zone, template) then return false end
    local uname = unit:getName()
    local pids = pickPlatoons(node, want)
    for _, pid in ipairs(pids) do
      local rec = B.spawned[pid]
      if rec then B.despawn(pid, rec) end
      B.war:carryPlatoon(pid, uname)
    end
    local tg = lastInTransit(self, uname)
    if tg then tg._dccPids = pids end
    addToPlayer(uname, pids)
    return true
  end

  -- every way troops leave a helicopter on the ground ends in deploy()
  local baseDeploy = CTLDTroopGroup.deploy
  CTLDTroopGroup.deploy = function(self, dcsGroup)
    local r = baseDeploy(self, dcsGroup)
    if self._dccPids and B.war then
      local u1 = dcsGroup and ok(function() return dcsGroup:getUnits()[1] end)
      local pos = u1 and ok(u1.getPoint, u1)
      local s, e = pcall(B.ctldTroopsDown, self, dcsGroup, pos, sideOf(self.coalitionId))
      if not s then U.log("ERROR ctld deploy: %s", tostring(e)) end
    end
    return r
  end

  -- picked up again from the field
  local baseField = TM.embarkFromField
  TM.embarkFromField = function(self, unit)
    local coal = unit:getCoalition()
    local before = {}
    for _, n in ipairs((self._droppedGroups or {})[coal] or {}) do before[n] = true end
    local r = baseField(self, unit)
    if r then
      local still = {}
      for _, n in ipairs((self._droppedGroups or {})[coal] or {}) do still[n] = true end
      for n in pairs(before) do
        if not still[n] and B.ctld.field[n] then
          local pids = B.ctld.field[n]
          B.ctld.field[n] = nil
          local tg = lastInTransit(self, unit:getName())
          if tg then tg._dccPids, tg._dccDone = pids, nil end
          addToPlayer(unit:getName(), pids)
        end
      end
    end
    return r
  end

  -- "return troops to base" at one of our zones: back into that garrison
  local baseReturn = TM.returnToTroopZone
  TM.returnToTroopZone = function(self, unit, zone)
    local list = self._inTransit and self._inTransit[unit:getName()] or {}
    local pids = {}
    for _, g in ipairs(list) do for _, pid in ipairs(g._dccPids or {}) do pids[#pids + 1] = pid end end
    local r = baseReturn(self, unit, zone)
    if r and B.war and #pids > 0 then
      local node = zone and B.ctld.zoneNode[zone.zoneName or ""]
      removeFromPlayers(pids)
      if node then B.war:dropPlatoons(pids, node, sideOf(unit:getCoalition()))
      else for _, pid in ipairs(pids) do B.war:returnCarried(pid) end end
    end
    return r
  end

  -- crates cost supply at the base they are requested at
  local baseSpawn = CM.spawnCrate
  CM.spawnCrate = function(self, descriptor, position, coal, spawnedBy, spawnMethod, ...)
    local node, su
    if spawnMethod == "menu_ctld" and spawnedBy and B.war then
      local u = ok(Unit.getByName, spawnedBy)
      if u then
        -- some crates (the FARP kit) are only for the heavy lifters, and cost more
        local only = type(descriptor) == "table" and descriptor.dccOnly
        if only and not only[ok(u.getTypeName, u) or ""] then
          say(u, descriptor.dccOnlyMsg or "This aircraft cannot lift that crate.")
          return nil
        end
        local paid
        paid, node, su = charge(u, (type(descriptor) == "table" and descriptor.dccCharge) or 1)
        if not paid then return nil end
      end
    end
    local crate = baseSpawn(self, descriptor, position, coal, spawnedBy, spawnMethod, ...)
    if not crate then refund(node, su) end
    return crate
  end

  if VS and VS.spawnVehicleForTransport then
    local baseVeh = VS.spawnVehicleForTransport
    VS.spawnVehicleForTransport = function(self, vehicleType, spawner, zone)
      local node, su
      if B.war and spawner then
        local d = ok(CM.findDescriptorByTypeName, CM.getInstance(), vehicleType)
        local paid
        paid, node, su = charge(spawner, d and d.cratesRequired or 1)
        if not paid then return false end
      end
      local r = baseVeh(self, vehicleType, spawner, zone)
      if not r then refund(node, su) end
      return r
    end
  end

  -- a supply crate is never unpacked into anything
  local baseUnpack = CM.unpackCrate
  CM.unpackCrate = function(self, crateName, unpacker)
    local crate = self.crates and self.crates[crateName]
    if crate and isSupply(crate.descriptor) then
      if not B.ctldCrateDown(crate, crate.position) then
        say(unpacker, "Supply crates are delivered by unloading them at a friendly base.")
      end
      return
    end
    return baseUnpack(self, crateName, unpacker)
  end
  -- a crate vehicle stands on the map: does it join a base?
  if CM._dispatchPostSpawn then
    local basePost = CM._dispatchPostSpawn
    CM._dispatchPostSpawn = function(self, desc, gname)
      basePost(self, desc, gname)
      if B.war and desc and not desc.isJTAC and (desc.spawnAs == nil or desc.spawnAs == "GROUND") then
        local g = ok(Group.getByName, gname)
        local u1 = g and ok(function() return g:getUnits()[1] end)
        local side = u1 and sideOf(ok(u1.getCoalition, u1))
        local s, e = pcall(B.ctldVehicleDown, desc, gname, side)
        if not s then U.log("ERROR ctld vehicle: %s", tostring(e)) end
      end
    end
  end

  if CM._spawnUnpacked then
    local baseSU = CM._spawnUnpacked
    CM._spawnUnpacked = function(self, desc, ...)
      if isSupply(desc) then return nil end
      return baseSU(self, desc, ...)
    end
  end
end

-- ===========================================================================
-- 4b. Vehicles unpacked at an own base join its garrison
-- ===========================================================================
-- What a CTLD crate vehicle is in the war: a platoon role, an artillery
-- battery, or (trucks) supply. Support trucks (CTLD crate family 1001.xx) first, then the catalogue's
-- unit lists, then CTLD's crate families (1000.xx combat,
-- 1002 artillery, 1003 short-range AA).
function B.ctldRoleOf(desc, side)
  local t = desc.unit
  local fam = math.floor(tonumber(desc.weight) or 0)
  if fam == 1001 then return "SUPPLY" end              -- trucks: their load, not the truck, counts
  for role, spec in pairs(B.catalog.roles or {}) do
    local s = spec[side] or {}
    for _, list in ipairs({ s.units or {}, s.fallback or {} }) do
      for _, u in ipairs(list) do if u == t then return role end end
    end
  end
  if fam == 1000 then
    if t:find("Abrams") or t:find("T%-%d") or t:find("Leopard") or t:find("LAV") then return "ARMOR_PLT" end
    return "MECH_PLT"
  elseif fam == 1002 then return "ARTY"
  elseif fam == 1003 then return "SHORAD"
  end
  return nil
end

function B.ctldVehicleDown(desc, gname, side)
  local war = B.war
  if not (desc and gname and side) or isSupply(desc) then return end
  local g = ok(Group.getByName, gname)
  local u1 = g and ok(function() return g:getUnits()[1] end)
  local pos = u1 and ok(u1.getPoint, u1)
  local su = (desc.cratesRequired or 1) * CC().crateSU
  local role = B.ctldRoleOf(desc, side)
  local node = pos and B.nearestNodeOf(pos, side, CC().dropKm * 1000)
  if not node then
    -- set down at an ENEMY base: the vehicle attacks it (with any troops landed there)
    local target = pos and B.nearestNodeOf(pos, nil, CC().dropKm * 1000)
    if not target or war.state.nodes[target].side == side then return end
    if role ~= "MECH_PLT" and role ~= "ARMOR_PLT" and role ~= "SHORAD" then return end
    local home = B.nearestNodeOf(pos, side)
    if not home then return end
    local pid = war:newPlatoon(side, role, home)
    war.state.platoons[pid].health = math.min(1, su / CC().platoonSU)
    war:carryPlatoon(pid, "ctld:" .. gname)
    war:dropPlatoons({ pid }, target, side)
    trigger.action.outTextForCoalition(coalOf(side), string.format("%s joins the air assault on %s!",
      tostring(desc.desc or desc.unit), war:nodeName(target)), 12)
    return                                             -- it fights where it stands
  end
  if not role then return end
  local what
  if role == "SUPPLY" then
    war:deliverCrate(side, node, su)
    what = string.format("%s handed its load to %s (+%d SU)", tostring(desc.desc or desc.unit), war:nodeName(node), su)
  elseif role == "ARTY" then
    local list, extra, revived = war:batteries(side), 0, false
    for _, b in ipairs(list) do
      if b.status ~= "up" and not revived then b.status, b.since, b.node, revived = "up", war.state.tick, node, true end
      if b.ctld then extra = extra + 1 end
    end
    if not revived then
      if extra >= CC().maxExtraBatteries then return end   -- enough guns: it stays where it is
      list[#list + 1] = { id = war:newId(side:sub(1, 1) .. "a"), status = "up", node = node, ctld = true }
    end
    what = string.format("an artillery battery at %s", war:nodeName(node))
  else
    local pid = war:newPlatoon(side, role, node)
    war.state.platoons[pid].health = math.min(1, su / CC().platoonSU)
    what = string.format("%s joined the garrison of %s", tostring(desc.desc or desc.unit), war:nodeName(node))
  end
  war:log("ctld_vehicle", side, string.format("%s: %s", side:upper(), what), { node = node })
  trigger.action.outTextForCoalition(coalOf(side), what:sub(1, 1):upper() .. what:sub(2) .. ".", 10)
  -- it is part of the base now: the live bubble spawns it with the garrison
  timer.scheduleFunction(function()
    local gg = ok(Group.getByName, gname)
    if gg and ok(gg.isExist, gg) then ok(gg.destroy, gg) end
  end, nil, timer.getTime() + CC().joinDelay)
end

function B.ctldSubscribe()
  local ed = EventDispatcher.getInstance()
  local function on(name, fn)
    ed:subscribe(name, function(ev) if B.war then local s, e = pcall(fn, ev); if not s then U.log("ERROR ctld %s: %s", name, tostring(e)) end end end)
  end
  on("OnCrateUnloaded", function(ev) B.ctldCrateDown(ev.crate, ev.position) end)
  on("OnCrateParachuteLanded", function(ev) B.ctldCrateDown(ev.crate, ev.position or (ev.crate and ev.crate.position)) end)
  on("OnTroopsParachuteLanded", function(ev)
    local tg = ev.troops
    local pos = ev.positions and ev.positions[1]
    if tg then B.ctldTroopsDown(tg, ev.spawnedGroup, pos, sideOf(tg.coalitionId)) end
  end)
  -- a whole vehicle carried by a Chinook / Mi-26 and set down at an own base
  on("OnVehicleUnloaded", function(ev)
    local u = ev.dcsUnitObject
    if not u or (ok(u.inAir, u)) then return end
    local g = ok(u.getGroup, u)
    local gname = g and ok(g.getName, g)
    local desc = CTLDCrateManager.getInstance():findDescriptorByUnitType(ev.vehicleType)
    if gname and desc then B.ctldVehicleDown(desc, gname, sideOf(ok(u.getCoalition, u))) end
  end)
  on("OnFOBDeployed", function(ev)
    local side = sideOf(ev.fob and ev.fob.coalitionId)
    local war = B.war
    local node = side and ev.position and B.nearestNodeOf(ev.position, side, CC().fobFarpKm * 1000)
    if node then war:buildFarp(node, side, "fob", { ctld = ev.fob.name }) end
  end)
  on("OnFOBDestroyed", function(ev)
    local war = B.war
    for _, id in ipairs(war.T.order) do
      local ns = war.state.nodes[id]
      if ns.farp and ns.farp.ctld and ev.fob and ns.farp.ctld == ev.fob.name then
        ns.farp = nil
        war:log("farp_lost", ns.side, string.format("The FOB at %s has been destroyed", war:nodeName(id)), { node = id })
      end
    end
  end)
  on("OnAASystemDeployed", function(ev)
    local side = sideOf(ev.coalition)
    local war = B.war
    local node = side and ev.position and B.nearestNodeOf(ev.position, side, CC().aaDefenceKm * 1000)
    if not node then return end
    local ns = war.state.nodes[node]
    local max = DCC.config.ground.fortMax
    if (ns.fort or 0) < max then
      ns.fort, ns.fortSince = (ns.fort or 0) + 1, war.state.tick
      war:log("ctld_aa", side, string.format("%s set up a %s at %s - defences now level %d", side:upper(),
        tostring(ev.systemName or "AA system"), war:nodeName(node), ns.fort), { node = node })
    end
  end)
end

-- ===========================================================================
-- 6. Start-up and wiring
-- ===========================================================================
function B.ctldSetup()
  B.ctldActive = false
  if not B.ctldPresent() then return false end
  if not ctld._dccInit then
    if CTLDPlayerManager and CTLDPlayerManager._instance then
      U.log("ERROR CTLD started on its own before the campaign set it up (the mission's DO SCRIPT "
        .. "'ctld.dontInitialize = true' did not run) - CTLD keeps its default settings")
    end
    local s, e = pcall(function()
      B.ctldConfigure()
      B.ctldHook()
      ctld.initialize()
      B.ctldSubscribe()
    end)
    if not s then
      U.log("ERROR CTLD start failed, keeping the DCC cargo menu: %s", tostring(e))
      return false
    end
    ctld._dccInit = true
  end
  B.ctldActive = true
  B.ctld.zones, B.ctld.zoneNode, B.ctld.field = {}, {}, {}
  B.ctldSyncZones()
  B.EFFECT.LOGISTICS = "F10 > CTLD: request a Supply crate at a friendly base, fly it to the target and unload it there."
  B.EFFECT.FARP = "Chinook / Mi-8: F10 > CTLD > Engineering > FARP kit, set it down within 3 km of the town. Or bring 3 supply crates (any lift helicopter), or build a CTLD FOB there."
  B.EFFECT.FARPSUP = "F10 > CTLD > load supply crates, set them down within 3 km of the FARP. A FARP kit refills it completely. A dry FARP has no rearm and no helicopter spawns."
  local n = 0
  for _ in pairs(B.ctld.zones) do n = n + 1 end
  U.log("CTLD %s integrated: %d base zones", tostring(ctld.VERSION), n)
  return true
end

local baseInit = B.init
function B.init(war, theater, catalog)
  baseInit(war, theater, catalog)
  B.ctldSetup()
end

local basePoll = B.opsPoll
function B.opsPoll()
  basePoll()
  if B.ctldActive then
    B.ctldSyncZones()
    B.ctldPollField()
  end
end
