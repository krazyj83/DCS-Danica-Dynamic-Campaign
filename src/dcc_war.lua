-- ============================================================================
-- Danica Dynamic Campaign - war model (pure Lua 5.1, no DCS calls)
-- ----------------------------------------------------------------------------
-- This is the whole war as numbers. It knows nodes, roads, platoons, moves and
-- battles, and it advances one "tick" (5 minutes) at a time.
--
-- The DCS bridge sits on top: it spawns the platoons that are near players as
-- real units, and reports back what happened to them. Battles nobody can see
-- are resolved here with dice, so the war keeps moving on an empty server.
--
-- Key concepts
--   node     : a place that can be owned (airbase, town, depot)
--   platoon  : the unit of force; has a side, a role and a health 0..1
--   garrison : the platoons sitting in a node
--   move     : something travelling. kind = "reinforce" (platoons to a
--              friendly node), "assault" (platoons to an enemy node),
--              "convoy" (supply by road) or "airlift" (supply by air).
--              Supply lives in dcc_supply.lua, which adds methods to War.
--   battle   : an assault that has arrived; status = "fighting"
--   live     : a node or move the bridge has spawned as DCS units. The model
--              does not roll dice for live fights - DCS does the fighting.
-- ============================================================================

DCC = DCC or {}
local U = DCC.util

local War = {}
War.__index = War
DCC.War = War

local SIDES = { "blue", "red" }
local ROLE_ORDER = { ARMOR_PLT = 1, MECH_PLT = 2, SHORAD = 3 } -- assault preference

-- ---------------------------------------------------------------------------
-- Theater index: static data the model looks up (positions, road lengths).
-- ---------------------------------------------------------------------------
local function indexTheater(theater)
  local T = { name = theater.name, nodes = {}, order = {}, edges = {}, sea = {} }
  for _, n in ipairs(theater.nodes) do
    assert(n.id and n.lat and n.lon and n.side, "theater node needs id, lat, lon, side")
    T.nodes[n.id] = {
      id = n.id, name = n.name or n.id, kind = n.kind or "town",
      depot = n.depot and true or false,
      lat = n.lat, lon = n.lon, airbase = n.airbase, ewr = n.ewr,
      startSide = n.side, nb = {},
    }
    T.order[#T.order + 1] = n.id
  end
  table.sort(T.order)
  for _, e in ipairs(theater.edges) do
    local a, b = T.nodes[e[1]], T.nodes[e[2]]
    if a and b then
      local km = U.distKm(a, b)
      a.nb[b.id], b.nb[a.id] = km, km
      T.edges[#T.edges + 1] = { a = a.id, b = b.id, km = km, sea = e.sea }
      -- sea crossings (ferries, landing craft): abstract only, never spawned
      if e.sea then T.sea[a.id .. "|" .. b.id], T.sea[b.id .. "|" .. a.id] = true, true end
    else
      U.log("theater %s: edge %s-%s skipped (unknown node)", theater.name, tostring(e[1]), tostring(e[2]))
    end
  end
  return T
end

-- Node class decides garrison size and defender bonus.
local function classOf(tn)
  if tn.depot then return "depot" end
  return tn.kind == "airbase" and "airbase" or "town"
end

-- ---------------------------------------------------------------------------
-- Construction
-- ---------------------------------------------------------------------------
local function base(theater, catalog, cfg)
  return setmetatable({
    T = indexTheater(theater), cat = catalog, cfg = cfg,
    fogOfWar = cfg.intel and cfg.intel.enabled,   -- phase 4: board and map use contacts only
    balance = theater.balance or {},   -- e.g. { red = 1.2 }: production multiplier per side
    liveFn = nil,          -- set by the bridge: function(nodeId) -> bool
    newEvents = {},
  }, War)
end

-- A fresh war from the theater's start positions.
function War.new(theater, catalog, cfg, seed)
  local self = base(theater, catalog, cfg)
  self.rng = U.rng(seed or 12345)
  self.state = {
    version = 1, theater = theater.name, tick = 0, nextId = 1,
    nodes = {}, platoons = {}, moves = {}, events = {},
    stats = { captures = { blue = 0, red = 0 }, lost = { blue = 0, red = 0 },
              produced = { blue = 0, red = 0 } },
  }
  for _, id in ipairs(self.T.order) do
    local tn = self.T.nodes[id]
    self.state.nodes[id] = { side = tn.startSide, platoons = {} }
    for _ = 1, cfg.garrisonStart[classOf(tn)] do
      self:newPlatoon(tn.startSide, self:pickRole("garrison"), id)
    end
  end
  self:initAllSupply()
  if self.initOps then self:initOps() end
  if self.initIntel then self:initIntel() end
  self:log("start", nil, "War begins on " .. theater.name)
  return self
end

-- A war restored from a saved state table.
function War.restore(theater, catalog, cfg, state)
  local self = base(theater, catalog, cfg)
  self.state = state
  self.rng = U.rng(state.rng or 12345)
  state.moves = state.moves or {}
  state.platoons = state.platoons or {}
  state.events = state.events or {}
  -- New nodes added to the theater pack since the save: start them as defined.
  for _, id in ipairs(self.T.order) do
    if not state.nodes[id] then
      state.nodes[id] = { side = self.T.nodes[id].startSide, platoons = {} }
      U.log("restore: new node %s added with no garrison", id)
    end
    state.nodes[id].platoons = state.nodes[id].platoons or {}
  end
  -- Nodes removed from the theater pack: drop them and their platoons.
  for id, ns in pairs(state.nodes) do
    if not self.T.nodes[id] then
      for _, pid in ipairs(ns.platoons) do state.platoons[pid] = nil end
      state.nodes[id] = nil
      U.log("restore: node %s no longer in theater, removed", id)
    end
  end
  for mid, mv in pairs(state.moves) do
    mv.platoons = mv.platoons or {}
    if not (self.T.nodes[mv.from] and self.T.nodes[mv.to]) then
      for _, pid in ipairs(mv.platoons) do state.platoons[pid] = nil end
      state.moves[mid] = nil
    end
  end
  self:initAllSupply()   -- a phase-1 save gets supply and aircraft stock added
  if self.initOps then
    self:initOps()        -- an older save gets SAM sites, structures and air pools added
    self:returnAllCarried() -- a restart lands every helicopter: troops go home
  end
  if self.initIntel then self:initIntel() end
  return self
end

-- The state to save. The RNG position is stored so dice continue after a restart.
function War:snapshot()
  self.state.rng = self.rng.state
  return self.state
end

-- ---------------------------------------------------------------------------
-- Small helpers
-- ---------------------------------------------------------------------------
function War:log(kind, side, text, extra)
  local ev = { tick = self.state.tick, kind = kind, side = side, text = text }
  if extra then for k, v in pairs(extra) do ev[k] = v end end
  local evs = self.state.events
  evs[#evs + 1] = ev
  while #evs > 100 do table.remove(evs, 1) end
  self.newEvents[#self.newEvents + 1] = ev
  U.debug("[%d] %s", self.state.tick, text)
end

function War:pickRole(job)
  return self.rng:weighted(self.cat.mix[job])
end

function War:newId(prefix)
  local n = self.state.nextId
  self.state.nextId = n + 1
  return prefix .. n
end

function War:newPlatoon(side, role, nodeId)
  local pid = self:newId("p")
  self.state.platoons[pid] = { id = pid, side = side, role = role, health = 1, node = nodeId }
  local ns = self.state.nodes[nodeId]
  ns.platoons[#ns.platoons + 1] = pid
  return pid
end

function War:power(pids)
  local p = 0
  for _, pid in ipairs(pids) do
    local pl = self.state.platoons[pid]
    if pl then p = p + pl.health end
  end
  return p
end

function War:nodeName(id) return self.T.nodes[id].name end
function War:classOf(id) return classOf(self.T.nodes[id]) end

function War:countNodes(side)
  local n = 0
  for _, ns in pairs(self.state.nodes) do if ns.side == side then n = n + 1 end end
  return n
end

-- Depots are the backbone of a side. They can only be attacked once the
-- attacker has no other enemy node within reach of its supplied territory:
-- either the enemy holds nothing else, or what it holds sits behind its depots.
function War:depotsOpen(attacker)
  local enemy = U.otherSide(attacker)
  local supplied = self:supplied(attacker)
  for id, ns in pairs(self.state.nodes) do
    if ns.side == enemy and not self.T.nodes[id].depot then
      for nb in pairs(self.T.nodes[id].nb) do
        -- Only counts if our supply can reach the node we would attack from.
        if self.state.nodes[nb].side == attacker and supplied[nb] then return false end
      end
    end
  end
  return true
end

function War:isNodeLive(id) return self.liveFn ~= nil and self.liveFn(id) == true end
-- A ground move across a sea edge (ships / landing craft): runs on dice only.
function War:onSea(mv)
  return mv.kind ~= "airlift" and self.T.sea[mv.from .. "|" .. mv.to] == true
end

function War:isMoveLive(mv)
  if mv.kind == "airlift" then return self.airLive == true end
  if self:onSea(mv) then return false end
  if self.forcedMoveFn and self.forcedMoveFn(mv.id) then return true end   -- a mission target
  return self:isNodeLive(mv.from) or self:isNodeLive(mv.to)
end

-- Steps from each node to the nearest enemy-held node (breadth-first search
-- over the road graph). 1 = on the front, 2 = one step behind, and so on.
function War:frontDistance(side)
  local dist, queue, head = {}, {}, 1
  for id, ns in pairs(self.state.nodes) do
    if ns.side ~= side then dist[id] = 0; queue[#queue + 1] = id end
  end
  table.sort(queue)
  while head <= #queue do
    local id = queue[head]; head = head + 1
    for nb in pairs(self.T.nodes[id].nb) do
      if dist[nb] == nil then dist[nb] = dist[id] + 1; queue[#queue + 1] = nb end
    end
  end
  return dist
end

function War:movesFrom(id, kind)
  local list = {}
  for _, mv in pairs(self.state.moves) do
    if mv.from == id and (kind == nil or mv.kind == kind) then list[#list + 1] = mv end
  end
  return list
end

function War:movesTo(id, side, kind)
  local list = {}
  for _, mv in pairs(self.state.moves) do
    if mv.to == id and mv.side == side and (kind == nil or mv.kind == kind) then list[#list + 1] = mv end
  end
  return list
end

-- ---------------------------------------------------------------------------
-- Platoon lifecycle
-- ---------------------------------------------------------------------------
function War:destroyPlatoon(pid)
  local pl = self.state.platoons[pid]
  if not pl then return end
  if pl.node then U.removeValue(self.state.nodes[pl.node].platoons, pid) end
  if pl.move and self.state.moves[pl.move] then U.removeValue(self.state.moves[pl.move].platoons, pid) end
  self.state.stats.lost[pl.side] = self.state.stats.lost[pl.side] + 1
  self.state.platoons[pid] = nil
end

-- Spread `loss` (in platoon-health units) over a list in 0.25 chunks.
-- `pids` may be a garrison/move list or a combined copy; destroyed platoons
-- are removed from it either way.
function War:damage(pids, loss)
  local guard = 0
  while loss > 1e-6 and #pids > 0 and guard < 200 do
    guard = guard + 1
    local pid = pids[self.rng:int(#pids)]
    local pl = self.state.platoons[pid]
    local d = math.min(0.25, loss)
    pl.health = pl.health - d
    loss = loss - d
    if pl.health < self.cfg.destroyedBelow then
      self:destroyPlatoon(pid)
      U.removeValue(pids, pid)
    end
  end
end

function War:startMove(kind, side, from, to, pids)
  local mid = self:newId("m")
  local mv = { id = mid, kind = kind, side = side, from = from, to = to,
               platoons = {}, progress = 0, km = self.T.nodes[from].nb[to], status = "moving" }
  for _, pid in ipairs(pids) do
    U.removeValue(self.state.nodes[from].platoons, pid)
    local pl = self.state.platoons[pid]
    pl.node, pl.move = nil, mid
    mv.platoons[#mv.platoons + 1] = pid
  end
  self.state.moves[mid] = mv
  return mv
end

-- Platoons of a move settle into a node's garrison.
function War:joinGarrison(mv)
  local ns = self.state.nodes[mv.to]
  for _, pid in ipairs(mv.platoons) do
    local pl = self.state.platoons[pid]
    pl.move, pl.node = nil, mv.to
    ns.platoons[#ns.platoons + 1] = pid
  end
  self.state.moves[mv.id] = nil
end

-- Remember moves destroyed on the road (for BAI missions), for one hour.
function War:markKilled(mid)
  self.state.killedMoves = self.state.killedMoves or {}
  self.state.killedMoves[mid] = self.state.tick
end

-- ---------------------------------------------------------------------------
-- Tick phases
-- ---------------------------------------------------------------------------
-- Production. Each depot earns points every tick; a full point is a new
-- platoon. The rate scales with ground won or lost since the start (start =
-- base rate), which gives momentum: ground won makes the next push easier,
-- so a war ends instead of see-sawing forever.
function War:startCount(side)
  local n = 0
  for _, id in ipairs(self.T.order) do if self.T.nodes[id].startSide == side then n = n + 1 end end
  return math.max(n, 1)
end

-- Each node gained (or lost) since the start moves the rate by the same
-- amount for both sides, whatever their starting size.
function War:productionFactor(side)
  local gained = self:countNodes(side) - self:startCount(side)
  local factor = 1 + self.cfg.productionPerNode * gained
  factor = U.clamp(factor, self.cfg.productionMinFactor, self.cfg.productionMaxFactor)
  return factor * (self.balance[side] or 1)   -- per-theater balance knob
end

-- Depot output also drops with strike damage to its buildings (dcc_ops.lua).
function War:depotFactor(id)
  local side = self.state.nodes[id].side
  local f = self:productionFactor(side)
  if self.infraFactor then f = f * self:infraFactor(id) end
  return f
end

function War:produce()
  self.state.prodPoints = self.state.prodPoints or {}
  for _, id in ipairs(self.T.order) do
    local tn, ns = self.T.nodes[id], self.state.nodes[id]
    if tn.depot then
      local factor = self:depotFactor(id)
      local pts = (self.state.prodPoints[id] or 0) + factor / self.cfg.depotProductionEveryTicks
      while pts >= 1 and #ns.platoons < self.cfg.garrisonMax.depot do
        self:newPlatoon(ns.side, self:pickRole("garrison"), id)
        self.state.stats.produced[ns.side] = self.state.stats.produced[ns.side] + 1
        pts = pts - 1
      end
      self.state.prodPoints[id] = math.min(pts, 1) -- a full depot does not bank points
    end
  end
end

function War:arrive(mv)
  if mv.cargo then return self:deliver(mv) end
  local ns = self.state.nodes[mv.to]
  if ns.side == mv.side then
    self:joinGarrison(mv)
  else
    mv.status, mv.progress = "fighting", 1
    self:log("battle", mv.side, string.format("%s forces attack %s", mv.side:upper(), self:nodeName(mv.to)), { node = mv.to })
  end
end

function War:advanceMoves()
  local kmPerTick = self.cfg.groundSpeedKmh * self.cfg.tickSeconds / 3600
  local airKmPerTick = self.cfg.supply.airliftSpeedKmh * self.cfg.tickSeconds / 3600
  for _, mid in ipairs(U.sortedKeys(self.state.moves)) do
    local mv = self.state.moves[mid]
    if mv and mv.status == "moving" then
      if #mv.platoons == 0 and not mv.cargo then
        self:markKilled(mid)
        self.state.moves[mid] = nil
      else
        -- Live moves are advanced by the bridge from real unit positions.
        local step = (mv.kind == "airlift") and airKmPerTick or kmPerTick
        if not self:isMoveLive(mv) then mv.progress = mv.progress + step / math.max(mv.km, 0.1) end
        if mv.progress >= 1 then self:arrive(mv) end
      end
    end
  end
end

function War:capture(mv, carried)
  local ns = self.state.nodes[mv.to]
  local old = ns.side
  ns.side = mv.side
  self:joinGarrison(mv)
  self:onCaptureSupply(mv.to, carried)
  self.state.stats.captures[mv.side] = self.state.stats.captures[mv.side] + 1
  self:log("capture", mv.side, string.format("%s captured %s from %s",
    mv.side:upper(), self:nodeName(mv.to), old:upper()), { node = mv.to, from = old })
  if self.onCaptureOps then self:onCaptureOps(mv.to) end
end

-- One round of dice for every attacker at a node against its garrison.
-- All assault groups that have arrived fight as one force.
function War:abstractRound(target, attackers)
  local ns = self.state.nodes[target]
  local combined = {}
  for _, mv in ipairs(attackers) do
    for _, pid in ipairs(mv.platoons) do combined[#combined + 1] = pid end
  end
  local bonus = self:bonusOf(target)
  local A = self:power(combined)
  local D = self:power(ns.platoons) * bonus
  local rate = self.cfg.battleLossRate
  local attLoss = D * rate * self.rng:range(0.6, 1.4)
  local defLoss = A * rate * self.rng:range(0.6, 1.4)
  self:damage(combined, attLoss)
  self:damage(ns.platoons, defLoss)
end

-- Decide every fight. Outcomes are logged as events.
function War:resolveBattles()
  -- Group arrived assaults by the node they are attacking.
  local byTarget = {}
  for _, mid in ipairs(U.sortedKeys(self.state.moves)) do
    local mv = self.state.moves[mid]
    if mv.status == "fighting" then
      byTarget[mv.to] = byTarget[mv.to] or {}
      table.insert(byTarget[mv.to], mv)
    end
  end

  for _, target in ipairs(U.sortedKeys(byTarget)) do
    local ns = self.state.nodes[target]
    local attackers = {}
    for _, mv in ipairs(byTarget[target]) do
      if mv.side == ns.side then self:joinGarrison(mv)   -- node is already ours
      else attackers[#attackers + 1] = mv end
    end

    if #attackers > 0 then
      if #ns.platoons > 0 then
        if not self:isNodeLive(target) then
          ns.liveFight = nil
          self:abstractRound(target, attackers)
        else
          -- DCS is fighting this one. If spawned units get stuck and nothing
          -- dies for a while, roll one round of dice so it cannot hang forever.
          ns.liveFight = (ns.liveFight or 0) + 1
          if ns.liveFight % self.cfg.liveStallTicks == 0 then self:abstractRound(target, attackers) end
        end
      end
      local alive = {}
      for _, mv in ipairs(attackers) do
        if #mv.platoons > 0 then alive[#alive + 1] = mv else self.state.moves[mv.id] = nil end
      end
      if #alive == 0 then
        self:log("repulsed", ns.side, string.format("%s held %s against a %s assault",
          ns.side:upper(), self:nodeName(target), attackers[1].side:upper()), { node = target })
      elseif #ns.platoons == 0 then
        local carried = 0
        for _, mv in ipairs(alive) do carried = carried + (mv.carried or 0) end
        self:capture(alive[1], carried)
        for i = 2, #alive do self:joinGarrison(alive[i]) end
      end
    end
  end
end

-- ---------------------------------------------------------------------------
-- Planning: each side's commander. Phase 2 gates it on supply: an attack
-- costs supply at the node it starts from (see dcc_supply.lua).
-- ---------------------------------------------------------------------------
function War:sortedGarrison(id, forAssault)
  local list = {}
  for _, pid in ipairs(self.state.nodes[id].platoons) do list[#list + 1] = pid end
  local P = self.state.platoons
  table.sort(list, function(a, b)
    if forAssault then
      local ra, rb = ROLE_ORDER[P[a].role] or 9, ROLE_ORDER[P[b].role] or 9
      if ra ~= rb then return ra < rb end
    end
    if P[a].health ~= P[b].health then return P[a].health > P[b].health end
    return a < b
  end)
  return list
end

-- Concentration of force: for each enemy node, every friendly neighbour that
-- is not already attacking offers its spare platoons. The target with the
-- best combined odds is attacked from all of them at once; repeat until no
-- target is worth it. Massing on one point is what breaks a stalemate,
-- because the defender has to spread over the whole front.
function War:planAssaults(side, dist, focus)
  local enemy = U.otherSide(side)
  local depotsOpen = self:depotsOpen(side)
  local used = {}

  local function offer(nodeId, isFocus)
    local ns = self.state.nodes[nodeId]
    -- Platoons that can attack: spare ones, and only as many as the node can supply.
    local available = math.min(#ns.platoons - self.cfg.frontKeep, self:assaultAffordable(nodeId))
    if available <= 0 or used[nodeId] or #self:movesFrom(nodeId, "assault") > 0 then return nil end
    -- The main effort commits everything it staged; other attacks are capped.
    local limit = isFocus and available or math.min(self.cfg.assaultMax, available)
    local sorted, picked = self:sortedGarrison(nodeId, true), {}
    for i = 1, limit do picked[i] = sorted[i] end
    return picked
  end

  -- Are the staging areas for the main effort full? Then waiting gains nothing.
  local function stagingFull(target)
    for nb in pairs(self.T.nodes[target].nb) do
      local nns = self.state.nodes[nb]
      if nns.side == side then
        local scap = self.cfg.garrisonMax[self:classOf(nb)] * self.cfg.stagingCapFactor
        if #nns.platoons + self:incoming(nb, side) < scap then return false end
      end
    end
    return true
  end

  while true do
    local best
    for _, target in ipairs(self.T.order) do
      local tns, ttn = self.state.nodes[target], self.T.nodes[target]
      local allowed = tns.side == enemy and (not ttn.depot or depotsOpen)
      if allowed and #self:movesTo(target, side, "assault") == 0 then
        local isFocus = (target == focus)
        local groups, count, A = {}, 0, 0
        for _, nb in ipairs(U.sortedKeys(ttn.nb)) do
          if self.state.nodes[nb].side == side then
            local picked = offer(nb, isFocus)
            if picked then
              groups[#groups + 1] = { from = nb, pids = picked }
              count = count + #picked
              A = A + self:power(picked)
            end
          end
        end
        if count >= self.cfg.assaultMin then
          local odds = A / math.max(self:defenceOf(target), 0.1)
          local need = self.cfg.assaultOdds
          if isFocus then
            -- Attack at lower odds when waiting gains nothing: staging is full,
            -- or the main effort has been building for focusPatienceTicks.
            local f = self.state.focus and self.state.focus[side]
            local age = f and (self.state.tick - f.since) or 0
            if stagingFull(target) or age >= self.cfg.focusPatienceTicks then
              need = self.cfg.assaultOddsStalled
            end
          end
          local score = odds / need
          if not best or score > best.score then
            best = { target = target, groups = groups, odds = odds, count = count, score = score }
          end
        end
      end
    end

    if not best or best.score < 1 then break end
    for _, g in ipairs(best.groups) do
      local carried = self:payAssault(g.from, #g.pids)
      local mv = self:startMove("assault", side, g.from, best.target, g.pids)
      mv.carried = carried
      used[g.from] = true
    end
    self:log("assault", side, string.format("%s launches %d platoons from %d node(s) toward %s (odds %.1f)",
      side:upper(), best.count, #best.groups, self:nodeName(best.target), best.odds))
  end
end

-- ---------------------------------------------------------------------------
-- Main effort ("focus"): each side picks one enemy node to break. Friendly
-- nodes next to it become staging areas that may hold far more than their
-- normal cap, and spare platoons from the whole side flow there. Without a
-- main effort, equal caps plus the defender bonus give a permanent stalemate.
-- ---------------------------------------------------------------------------
function War:defenceOf(target)
  local ns = self.state.nodes[target]
  local d = self:power(ns.platoons)
  for _, rmv in ipairs(self:movesTo(target, ns.side, "reinforce")) do d = d + self:power(rmv.platoons) end
  return d * self:bonusOf(target)
end

-- Nodes a side can supply: reachable from one of its depots over its own nodes.
-- A pocket cut off from every depot gets no reinforcements.
function War:supplied(side)
  local seen, queue, head = {}, {}, 1
  for _, id in ipairs(self.T.order) do
    if self.T.nodes[id].depot and self.state.nodes[id].side == side then
      seen[id] = true; queue[#queue + 1] = id
    end
  end
  while head <= #queue do
    local id = queue[head]; head = head + 1
    for nb in pairs(self.T.nodes[id].nb) do
      if not seen[nb] and self.state.nodes[nb].side == side then seen[nb] = true; queue[#queue + 1] = nb end
    end
  end
  return seen
end

function War:chooseFocus(side)
  self.state.focus = self.state.focus or {}
  local enemy = U.otherSide(side)
  local f = self.state.focus[side]
  local supplied = self:supplied(side)
  -- A main effort must be stageable from a node our supply can reach.
  local function valid(target)
    local tns, ttn = self.state.nodes[target], self.T.nodes[target]
    if not tns or tns.side ~= enemy then return false end
    if ttn.depot and not self:depotsOpen(side) then return false end
    for nb in pairs(ttn.nb) do
      if self.state.nodes[nb].side == side and supplied[nb] then return true end
    end
    return false
  end
  if f and valid(f.target) and self.state.tick - f.since < self.cfg.focusTicks then return f.target end
  -- Weakest reachable enemy node; ties broken by name for reproducible runs.
  local best, bestD
  for _, target in ipairs(self.T.order) do
    if valid(target) then
      local d = self:defenceOf(target) + self.rng:range(0, 0.5) -- a little noise avoids predictability
      if not bestD or d < bestD then best, bestD = target, d end
    end
  end
  self.state.focus[side] = best and { target = best, since = self.state.tick } or nil
  if best and (not f or f.target ~= best) then
    self:log("focus", side, string.format("%s shifts its main effort toward %s", side:upper(), self:nodeName(best)))
  end
  return best
end

-- Friendly steps from each node to the nearest staging node (next to the focus).
function War:stagingDistance(side, focus)
  local dist, queue, head = {}, {}, 1
  if not focus then return dist end
  for nb in pairs(self.T.nodes[focus].nb) do
    if self.state.nodes[nb].side == side then dist[nb] = 0; queue[#queue + 1] = nb end
  end
  table.sort(queue)
  while head <= #queue do
    local id = queue[head]; head = head + 1
    for nb in pairs(self.T.nodes[id].nb) do
      if dist[nb] == nil and self.state.nodes[nb].side == side then
        dist[nb] = dist[id] + 1; queue[#queue + 1] = nb
      end
    end
  end
  return dist
end

function War:incoming(id, side)
  local n = 0
  for _, rmv in ipairs(self:movesTo(id, side, "reinforce")) do n = n + #rmv.platoons end
  return n
end

-- How many platoons a node holds on to before it passes any on.
--   front node : its max plus the front staging allowance
--   staging    : its max x stagingCapFactor (it never passes on)
--   depot      : a small reserve
--   rear node  : a token garrison
function War:keepLevel(id, side, dist, sdist)
  local tn = self.T.nodes[id]
  local max = self.cfg.garrisonMax[classOf(tn)]
  if sdist[id] == 0 then return max * self.cfg.stagingCapFactor end
  if dist[id] == 1 then return max + self.cfg.frontStaging end
  if tn.depot then return self.cfg.rearKeep + 2 end
  return self.cfg.rearKeep
end

-- Reinforcement flow. A node passes on whatever it holds above its keep level:
--   (a) to a neighbour nearer the front that is below ITS keep level, else
--   (b) toward the main effort, to a neighbour nearer the staging nodes.
-- Because (a) only fills a node up to the level at which it would start
-- passing platoons on, a column is never sent straight back (no ping-pong).
function War:planReinforcements(side, dist, focus)
  local sdist = self:stagingDistance(side, focus)
  local cols = self.cfg.reinforceColumnMax
  for _, id in ipairs(self.T.order) do
    local ns, tn = self.state.nodes[id], self.T.nodes[id]
    local d, sd = dist[id], sdist[id]
    if ns.side == side and sd ~= 0 then
      local surplus = #ns.platoons - self:keepLevel(id, side, dist, sdist)
      if surplus > 0 then
        local best, bestKey
        for _, nb in ipairs(U.sortedKeys(tn.nb)) do
          local nns = self.state.nodes[nb]
          if nns.side == side then
            local held = #nns.platoons + self:incoming(nb, side)
            local keep = self:keepLevel(nb, side, dist, sdist)
            -- (a) fill toward the front
            if d and dist[nb] and dist[nb] < d and held < keep then
              local key = dist[nb] * 100 - (keep - held)
              if not bestKey or key < bestKey then best, bestKey = { id = nb, room = keep - held }, key end
            end
            -- (b) toward the main effort; pass-through nodes take a small buffer
            if not best and sd and sdist[nb] and sdist[nb] < sd then
              local room = (sdist[nb] == 0) and (keep - held) or (keep + 2 * cols - held)
              if room > 0 then
                local key = 10000 + sdist[nb] * 100 - room
                if not bestKey or key < bestKey then best, bestKey = { id = nb, room = room }, key end
              end
            end
          end
        end
        if best then
          local n = math.min(surplus, best.room, cols)
          local sorted = self:sortedGarrison(id, true)
          local picked = {}
          for i = 1, n do picked[i] = sorted[i] end
          self:startMove("reinforce", side, id, best.id, picked)
        end
      end
    end
  end
end

function War:checkVictory()
  if self.state.winner then return end
  for _, side in ipairs(SIDES) do
    if self:countNodes(side) == 0 then
      local winner = U.otherSide(side)
      self.state.winner = winner
      -- Stray units of the loser are removed so one lost truck cannot stall the end.
      for pid, pl in pairs(self.state.platoons) do
        if pl.side == side then self:destroyPlatoon(pid) end
      end
      for mid, mv in pairs(self.state.moves) do
        if mv.side == side then self.state.moves[mid] = nil end
      end
      self:log("victory", winner, string.format("%s wins the war on %s after %d ticks",
        winner:upper(), self.T.name, self.state.tick))
    end
  end
end

-- One war step. Returns the events that happened in it, plus any logged
-- since the last tick by the bridge (rescues, crate drops), so missions
-- can be judged on them.
function War:tick()
  if self.state.winner then self.newEvents = {}; return {} end
  self.state.tick = self.state.tick + 1
  self:produce()
  self:produceSupply()
  self:advanceMoves()
  self:resolveBattles()
  self:upkeep()
  self:restockAircraft()
  if self.opsTick then self:opsTick() end
  if self.intelTick then self:intelTick() end
  if self.missionsTick then self:missionsTick() end
  self:checkVictory()
  if not self.state.winner then
    -- Alternate which side plans first so neither always gets first pick.
    local order = (self.state.tick % 2 == 0) and { "blue", "red" } or { "red", "blue" }
    for _, side in ipairs(order) do
      local dist = self:frontDistance(side)
      local focus = self:chooseFocus(side)
      self:planAssaults(side, dist, focus)
      self:planReinforcements(side, dist, focus)
      self:planConvoys(side, dist, focus)
      self:planAirlifts(side, dist, focus)
    end
  end
  local evs = self.newEvents
  self.newEvents = {}
  return evs
end

-- ---------------------------------------------------------------------------
-- Bridge API: how live DCS results flow back into the model
-- ---------------------------------------------------------------------------
-- Health of a spawned platoon after polling its DCS group (0..1).
function War:setHealth(pid, health)
  local pl = self.state.platoons[pid]
  if not pl then return end
  pl.health = math.min(pl.health, health)
  if pl.health < self.cfg.destroyedBelow then self:destroyPlatoon(pid) end
end

-- Progress (0..1) of a live move, measured from its lead vehicle's position.
function War:setProgress(mid, progress)
  local mv = self.state.moves[mid]
  if mv and mv.status == "moving" then mv.progress = U.clamp(progress, mv.progress, 1) end
end

-- Totals per side for status messages.
function War:summary()
  local s = { blue = { nodes = 0, platoons = 0 }, red = { nodes = 0, platoons = 0 } }
  for _, ns in pairs(self.state.nodes) do s[ns.side].nodes = s[ns.side].nodes + 1 end
  for _, pl in pairs(self.state.platoons) do s[pl.side].platoons = s[pl.side].platoons + 1 end
  return s
end
