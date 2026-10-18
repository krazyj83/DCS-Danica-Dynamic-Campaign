-- ============================================================================
-- Danica Dynamic Campaign - DCS bridge: more ground war.
-- Load after dcc_dcs_ext_air.lua.
-- ----------------------------------------------------------------------------
--   Engineers  - CTLD "Bridge kit" crates: 2 unpacked within 1.5 km of a
--                downed bridge reopen its road.
--   FARP kit   - one heavy CTLD crate (3 t, Chinook / Mi-8 only, 30 SU):
--                set down or unpacked within 3 km of an own town, it makes
--                the town a FARP at once (the FARP mission's quick way).
--   Minefields - a CTLD minefield laid within 1.5 km of a road mines it for
--                24 h: enemy columns slow down and take losses.
--   Industry   - factories, power plants and refineries behind each side's
--                lines, on the map at all times (ruins while destroyed).
--   Partisans  - cells near occupied towns, on the map when the town is live;
--                wiped out = COIN done.
-- ============================================================================

DCC = DCC or {}
local B = DCC.dcs
local U = DCC.util

local function XC() return DCC.config.ext end
local function ok(fn, ...) local s, r = pcall(fn, ...); if s then return r end end
local function dist2D(a, b)
  local dx, dz = a.x - b.x, a.z - b.z
  return math.sqrt(dx * dx + dz * dz)
end
local function sideOfCoal(c) return c == 2 and "blue" or (c == 1 and "red" or nil) end
local function segDist(p, a, b)
  local vx, vz = b.x - a.x, b.z - a.z
  local len2 = vx * vx + vz * vz
  local t = len2 > 0 and U.clamp(((p.x - a.x) * vx + (p.z - a.z) * vz) / len2, 0, 1) or 0
  return dist2D(p, { x = a.x + vx * t, z = a.z + vz * t })
end

B.industry, B.partisanGroups = {}, {}

-- ===========================================================================
-- 6 + 7. Engineers and minefields (CTLD)
-- ===========================================================================
-- the road (a, b) whose straight line passes nearest to p, within maxM
function B.roadNear(p, maxM)
  local war, best, bestD = B.war, nil, nil
  for _, a in ipairs(war.T.order) do
    for b in pairs(war.T.nodes[a].nb) do
      if a < b and B.nodePos[a] and B.nodePos[b] then
        local d = segDist(p, B.nodePos[a], B.nodePos[b])
        if d <= maxM and (not bestD or d < bestD) then best, bestD = { a = a, b = b }, d end
      end
    end
  end
  return best
end

-- a closed road whose bridge is near p
function B.downedBridgeNear(p, maxM)
  local war = B.war
  for _, br in ipairs(war.bridges or {}) do
    if br.pos and war:roadClosed(br.a, br.b) and dist2D(p, br.pos) <= maxM then return br end
  end
end

function B.bridgeKitUnpacked(crate, unpacker)
  local war, cm = B.war, CTLDCrateManager.getInstance()
  local p = crate.position
  local side = sideOfCoal(crate.coalition)
  local function tell(text) trigger.action.outTextForCoalition(crate.coalition, text, 12) end
  local br = p and B.downedBridgeNear(p, XC().bridgeKitKm * 1000)
  if not br then return tell("Bridge kits go next to a destroyed bridge (within 1.5 km).") end
  local kits = {}
  for _, c in ipairs(ok(cm.getCratesInRange, cm, p, 150) or {}) do
    if c.descriptor and c.descriptor.dccBridge and c.coalition == crate.coalition then kits[#kits + 1] = c end
  end
  local need = XC().bridgeKitCrates
  if #kits < need then return tell(string.format("%d of %d bridge kits here - bring more.", #kits, need)) end
  for i = 1, need do ok(cm.destroyCrate, cm, kits[i].crateName) end
  war:repairBridge(br.a, br.b, side)
  tell(string.format("Engineers bridged the road %s - %s.", war:nodeName(br.a), war:nodeName(br.b)))
end

-- the own town nearest to p within maxM that can take a FARP
function B.farpTownNear(p, side, maxM)
  local war, best, bestD = B.war, nil, nil
  for _, id in ipairs(war.T.order) do
    local np = B.nodePos[id]
    if np and war.state.nodes[id].side == side and war:canHaveFarp(id) then
      local d = dist2D(p, np)
      if d <= maxM and (not bestD or d < bestD) then best, bestD = id, d end
    end
  end
  return best
end

-- A FARP kit on the ground (unloaded, sling-dropped or unpacked).
-- loud = tell the crew why nothing happened. Returns true when it was used.
function B.farpKitDown(crate, pos, loud)
  local war, cm = B.war, CTLDCrateManager.getInstance()
  local side = sideOfCoal(crate.coalition)
  local function tell(text) trigger.action.outTextForCoalition(crate.coalition, text, 12) end
  pos = pos or crate.position
  if not (war and side and pos) then return false end
  local km = XC().farpKit.km
  local town = B.farpTownNear(pos, side, km * 1000)
  if not town then
    if loud then tell(string.format("A FARP kit goes down within %d km of a friendly town.", km)) end
    return false
  end
  if war:farpAt(town) then
    if loud then tell(war:nodeName(town) .. " already has a FARP - take the kit somewhere else.") end
    return false
  end
  if not war:buildFarp(town, side, "kit") then return false end
  ok(cm.destroyCrate, cm, crate.crateName)
  tell(string.format("FARP kit delivered: %s is a FARP now - rearm, refuel and helicopter spawns.",
    war:nodeName(town)))
  return true
end

if B.ctldCrateDown then
  local baseDown = B.ctldCrateDown
  function B.ctldCrateDown(crate, pos)
    if crate and crate.descriptor and crate.descriptor.dccFarp then
      local s, r = pcall(B.farpKitDown, crate, pos, true)
      if not s then U.log("ERROR farp kit: %s", tostring(r)) end
      return s and r
    end
    return baseDown(crate, pos)
  end
end

if B.ctldConfigure then
  local baseConfigure = B.ctldConfigure
  function B.ctldConfigure()
    baseConfigure()
    local crates = ctld.gs("spawnableCrates") or {}
    local fk = XC().farpKit
    local only = {}
    for _, t in ipairs(fk.types) do only[t] = true end
    crates["Engineering"] = { { unit = "DCC_BRIDGEKIT", desc = "Bridge kit", weight = 1500.01, cratesRequired = 1,
                                dccBridge = true },
                              { unit = "DCC_FARPKIT", desc = "FARP kit (Chinook / Mi-8)", weight = fk.weight,
                                cratesRequired = 1, dccFarp = true, dccCharge = math.ceil(fk.su / DCC.config.ctld.crateSU),
                                dccOnly = only,
                                dccOnlyMsg = "A FARP kit weighs 3 t - only a Chinook or a Mi-8 can lift it." } }
    CTLDConfig.get():setSetting("spawnableCrates", crates)
  end
end

if B.ctldHook then
  local baseHook = B.ctldHook
  function B.ctldHook()
    local already = B.ctld.hooked
    baseHook()
    if already or B.ctld.extHooked then return end
    B.ctld.extHooked = true
    local CM = CTLDCrateManager
    local baseUnpack = CM.unpackCrate
    CM.unpackCrate = function(self, crateName, unpacker)
      local crate = self.crates and self.crates[crateName]
      if crate and crate.descriptor and crate.descriptor.dccBridge then
        if B.war then ok(B.bridgeKitUnpacked, crate, unpacker) end
        return
      end
      if crate and crate.descriptor and crate.descriptor.dccFarp then
        if B.war then ok(B.farpKitDown, crate, crate.position, true) end
        return
      end
      return baseUnpack(self, crateName, unpacker)
    end
    local baseSU = CM._spawnUnpacked
    if baseSU then
      CM._spawnUnpacked = function(self, desc, ...)
        if desc and (desc.dccBridge or desc.dccFarp) then return nil end
        return baseSU(self, desc, ...)
      end
    end
    -- minefields: CTLD's mineField scene
    local sm = CTLDSceneManager and CTLDSceneManager.getInstance()
    local model = sm and sm._models and sm._models.mineField
    local step = model and model.steps and model.steps[1]
    if step and step.func then
      local baseFunc = step.func
      step.func = function(ctx)
        local okRun, r1, r2 = pcall(baseFunc, ctx)
        if not okRun then U.log("ERROR ctld minefield: %s", tostring(r1)); r1, r2 = false, nil end
        local u = ctx and ctx.unit
        local pos = u and ok(u.getPoint, u)
        local side = u and sideOfCoal(ok(u.getCoalition, u))
        if B.war and pos and side then
          local road = B.roadNear(pos, XC().mineRoadKm * 1000)
          if road then B.war:mineRoad(road.a, road.b, side) end
        end
        return r1, r2
      end
    end
  end
end

-- ===========================================================================
-- 9. Industry
-- ===========================================================================
local DEFAULT_IND = {
  factory = { { "Workshop A", "Fortifications" }, { "Tech combine", "Fortifications" }, { "Workshop A", "Fortifications" } },
  ["power plant"] = { { "Tech combine", "Fortifications" }, { "Chemical tank A", "Fortifications" },
                      { "Chemical tank A", "Fortifications" } },
  refinery = { { "Fuel tank", "Fortifications" }, { "Fuel tank", "Fortifications" }, { "Chemical tank A", "Fortifications" } },
}

local function industrySpot(s, k, i)
  local c = B.nodePos[s.node]
  local ang = (i * 2.4) + k * 0.15
  local r = 3200 + k * 70
  return { x = c.x + math.cos(ang) * r, z = c.z + math.sin(ang) * r }
end

function B.reconcileIndustry()
  local war = B.war
  for _, side in ipairs({ "blue", "red" }) do
    for i, s in ipairs(war:industrySites(side)) do
      local rec = B.industry[s.id]
      local state = s.status == "up" and "up" or "ruin"
      -- poll a standing site
      if rec and rec.state == "up" and s.status == "up" then
        local dead = 0
        for _, name in ipairs(rec.names) do
          local o = ok(StaticObject.getByName, name)
          if not o or not ok(o.isExist, o) or (ok(o.getLife, o) or 0) < 1 then dead = dead + 1 end
        end
        if dead >= 2 then
          war:industryHit(s.id)
          state = "ruin"
        end
      end
      if rec and rec.state ~= state then
        for _, name in ipairs(rec.names) do
          local o = ok(StaticObject.getByName, name)
          if o and ok(o.isExist, o) then ok(o.destroy, o) end
        end
        B.industry[s.id], rec = nil, nil
      end
      if not rec and B.nodePos[s.node] then
        rec = { state = state, names = {} }
        B.industry[s.id] = rec
        B.indN = (B.indN or 0) + 1
        local parts = (B.catalog.industry or DEFAULT_IND)[s.kind] or DEFAULT_IND.factory
        for k, part in ipairs(parts) do
          local sp = industrySpot(s, k, i)
          local name = string.format("DCC_IND_%s_%d_%d", s.id, k, B.indN)
          local okAdd = pcall(coalition.addStaticObject, B.countryId(side), { name = name, type = part[1],
            category = part[2], x = sp.x, y = sp.z, heading = 0, dead = state == "ruin" })
          if okAdd then rec.names[#rec.names + 1] = name end
        end
      end
    end
  end
end

-- ===========================================================================
-- 10. Partisans
-- ===========================================================================
function B.reconcilePartisans()
  local war = B.war
  for cid, gname in pairs(B.partisanGroups) do
    local c = war.state.partisans[cid]
    local g = ok(Group.getByName, gname)
    local n = 0
    if g and ok(g.isExist, g) then
      for _, u in ipairs(ok(g.getUnits, g) or {}) do if ok(u.isExist, u) and (ok(u.getLife, u) or 0) >= 1 then n = n + 1 end end
    end
    if c and n == 0 then
      war:partisanKilled(cid, war.state.nodes[c.node].side)
      B.partisanGroups[cid] = nil
    elseif not c or not B.liveNodes[c.node] then
      if g and ok(g.isExist, g) then ok(g.destroy, g) end
      B.partisanGroups[cid] = nil
    end
  end
  for cid, c in pairs(war.state.partisans) do
    if not B.partisanGroups[cid] and B.liveNodes[c.node] and B.nodePos[c.node] then
      local list = (B.catalog.partisans or {})
      local types = {}
      for _, t in ipairs(list.units or {}) do if B.validType(t) then types[#types + 1] = t end end
      if #types == 0 then
        for _, t in ipairs(list.fallback or { "Infantry AK" }) do if B.validType(t) then types[#types + 1] = t end end
      end
      local c0 = B.nodePos[c.node]
      local ang = (tonumber(cid:match("%d+")) or 1) * 1.7
      local cx, cz = c0.x + math.cos(ang) * 2200, c0.z + math.sin(ang) * 2200
      local units = {}
      for i, t in ipairs(types) do
        units[i] = { name = "DCC_PZ_" .. cid .. "_" .. i, type = t, skill = "Average", x = cx + i * 12, y = cz + (i % 2) * 15,
                     heading = 0, playerCanDrive = false }
      end
      local gname = "DCC_PZ_" .. cid
      if #units > 0 and pcall(coalition.addGroup, B.countryId(c.side), Group.Category.GROUND, { name = gname,
          task = "Ground Nothing", units = units, route = { points = { { x = cx, y = cz, type = "Turning Point",
          action = "Off Road", speed = 0, ETA = 0, ETA_locked = false } } } }) then
        B.partisanGroups[cid] = gname
      end
    end
  end
end

-- ===========================================================================
-- Wiring
-- ===========================================================================
local basePoll = B.opsPoll
function B.opsPoll()
  basePoll()
  ok(B.reconcileIndustry)
  ok(B.reconcilePartisans)
end

local baseInit = B.init
function B.init(war, theater, catalog)
  baseInit(war, theater, catalog)
  B.industry, B.partisanGroups = {}, {}
end

local baseMissionPos = B.missionPos
function B.missionPos(m)
  local war = B.war
  if m.type == "INDUSTRY" then
    for _, side in ipairs({ "blue", "red" }) do
      for i, s in ipairs(war:industrySites(side)) do
        if s.id == m.target then return industrySpot(s, 2, i) end
      end
    end
  elseif m.type == "COIN" then
    local gname = B.partisanGroups[m.target]
    local g = gname and ok(Group.getByName, gname)
    local u = g and ok(function() return g:getUnits()[1] end)
    if u and ok(u.isExist, u) then return u:getPoint() end
  elseif m.type == "SNATCH" then
    local d = war.state.downed[m.target]
    return d and { x = d.pos.x, y = 0, z = d.pos.z }
  end
  return baseMissionPos(m)
end

B.EFFECT.INDUSTRY = "Destroy 2 of its 3 buildings. Each site down cuts that side's production by 12 % until rebuilt (a day, 80 SU)."
B.EFFECT.COIN = "Wipe out the partisan cell near the town. Partisans sabotage supply and ambush columns."

-- New events on screen (both sides) and on the public feed
for _, k in ipairs({ "runway_closed", "industry_hit", "snatched", "partisan_ambush", "partisans_killed" }) do
  B.PUBLIC_KINDS[k] = true
end
-- "all": everyone sees it; "own": only the side it happened to
local LOUD = { runway_closed = "all", runway_open = "own", industry_hit = "all", industry_up = "own", snatched = "all",
               partisans = "all", partisans_killed = "all", partisans_swept = "own", partisan_ambush = "all",
               mined = "own", mine_hit = "all", ctld_vehicle = "own", ctld_aa = "own", helilift = "own" }
local baseAnnounce = B.announce
function B.announce(events)
  baseAnnounce(events)
  for _, ev in ipairs(events) do
    local who = LOUD[ev.kind]
    if who == "all" then trigger.action.outText(ev.text, 15)
    elseif who == "own" and ev.side and B.COAL[ev.side] then
      trigger.action.outTextForCoalition(B.COAL[ev.side], "Command: " .. ev.text, 12)
    end
  end
end
