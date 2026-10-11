-- ============================================================================
-- Phase 3 model tests: every mission type writes its effect to the save.
--   python tools/run_lua.py tests/test_ops.lua
-- ============================================================================

local passed, failed = 0, 0
local function check(name, cond, detail)
  if cond then passed = passed + 1; print("  ok   " .. name)
  else failed = failed + 1; print("  FAIL " .. name .. (detail and (" - " .. tostring(detail)) or "")) end
end

local T, C, cfg, J = DCC_THEATERS.Caucasus, DCC_CATALOGS.modern, DCC.config, DCC.json

local function find(war, side, mtype, target)
  for _, m in ipairs(war:openMissions(side)) do
    if m.type == mtype and (target == nil or m.target == target) then return m end
  end
end

local function events(war, kind)
  local n = 0
  for _, ev in ipairs(war.state.events) do if ev.kind == kind then n = n + 1 end end
  return n
end

-- Every mission completion is credited through this hook (the bridge points it at pilot records).
local credited = {}
-- Phase-3 checks run with fog of war off (the god's-eye board); phase-4
-- fog behaviour has its own section at the end.
local function wire(war, fog)
  war.fogOfWar = fog or false
  war.onMissionDone = function(m, outcome)
    if outcome == "done" then for key in pairs(m.taken) do credited[#credited + 1] = key .. ":" .. m.type end end
  end
  return war
end

print("Board")
local war = wire(DCC.War.new(T, C, cfg, 7))
war:tick()
war:tick()   -- the main effort (and with it CAP) is chosen at the end of the first tick
local types = {}
for _, side in ipairs({ "blue", "red" }) do
  for _, m in ipairs(war:openMissions(side)) do types[side .. m.type] = true end
end
check("BLUE board has SEAD, STRIKE, CAP, RECON", types.blueSEAD and types.blueSTRIKE and types.blueCAP and types.blueRECON)
check("RED board has SEAD, STRIKE, CAP, RECON", types.redSEAD and types.redSTRIKE and types.redCAP and types.redRECON)
check("SAM sites at airbases and depots", war.state.nodes.sochi.sam.status == "up" and war.state.nodes.gori.sam == nil)
check("structures at depots and airbases", war.state.nodes.beslan.infra.total == 6 and war.state.nodes.kutaisi.infra.total == 4)
check("air pools start stocked", war.state.airPool.red.fighter == 8 and war.state.airPool.blue.attack == 8)

print("SEAD / DEAD")
local m = find(war, "blue", "SEAD")
war:takeMission(m.id, "ucid1", "Morten")
local target = m.target
war:samHit(target, "radar")
war:tick()
check("radar kill completes SEAD", war.state.missions[m.id].status == "done")
check("SAM suppressed in the save", war.state.nodes[target].sam.status == "suppressed")
check("pilot credited", credited[#credited] == "ucid1:SEAD")
war.state.nodes[target].supply = 200
for _ = 1, 25 do war:tick() end
check("suppressed SAM repaired after ~2 h for supply", war.state.nodes[target].sam.status == "up")
war:samHit(target, "destroyed")
check("destroyed SAM saved", war.state.nodes[target].sam.status == "destroyed")

print("STRIKE")
local w2 = wire(DCC.War.new(T, C, cfg, 8))
w2:tick()
local ms = find(w2, "blue", "STRIKE", "beslan") or find(w2, "blue", "STRIKE")
w2:takeMission(ms.id, "ucid1", "Morten")
local node = ms.target
local before = w2:depotFactor(node)
local sup = w2.state.nodes[node].supply
w2:infraHit(node, 1)
w2:infraHit(node, 2)
w2:tick()
check("building kill completes STRIKE", w2.state.missions[ms.id].status == "done")
check("output cut by damage", w2:depotFactor(node) < before, string.format("%.2f -> %.2f", before, w2:depotFactor(node)))
check("supply burned", w2.state.nodes[node].supply < sup)
check("damage in the save", w2:infraLost(node) == 2)

print("BAI")
local w3 = wire(DCC.War.new(T, C, cfg, 9))
local cv
for _ = 1, 300 do
  w3:tick()
  local mb = find(w3, "blue", "BAI")
  if mb and w3.state.moves[mb.target] and w3.state.moves[mb.target].cargo then cv = mb; break end
end
check("BAI offered on an enemy convoy", cv ~= nil)
if cv then
  w3:takeMission(cv.id, "ucid2", "Jens")
  local lost = w3.state.stats.cargoLost.red
  w3:destroyCargo(cv.target, "player")
  w3:tick()
  check("convoy kill completes BAI", w3.state.missions[cv.id].status == "done")
  check("cargo loss in the save", w3.state.stats.cargoLost.red > lost)
end

print("CAS")
local w4 = wire(DCC.War.new(T, C, cfg, 10))
local cas
for _ = 1, 600 do
  w4:tick()
  cas = find(w4, "blue", "CAS")
  if cas then break end
end
check("CAS offered on a battle", cas ~= nil)
if cas then
  w4:takeMission(cas.id, "ucid1", "Morten")
  local outcome
  for _ = 1, 60 do
    w4:tick()
    local s = w4.state.missions[cas.id] and w4.state.missions[cas.id].status
    if s ~= "open" then outcome = s; break end
  end
  check("CAS resolved by the battle (" .. tostring(outcome) .. ")",
    outcome == "done" or outcome == "failed" or outcome == "expired")
end

print("CAP")
local mc = find(war, "blue", "CAP")
check("CAP offered over the main effort", mc ~= nil)
if mc then
  war:takeMission(mc.id, "ucid1", "Morten")
  war:completeMission(mc.id, true)
  check("CAP gives air cover", war:hasAirCover("blue", mc.target))
  for _ = 1, 13 do war:tick() end
  check("air cover expires after an hour", not war:hasAirCover("blue", mc.target))
end

print("ESCORT and CONVOY")
local w5 = wire(DCC.War.new(T, C, cfg, 11))
w5.state.nodes.batumi.supply = 300
local al = w5:startCargo("airlift", "blue", "batumi", "vaziani", 30)
w5:tick()
local me = find(w5, "blue", "ESCORT", al.id)
check("ESCORT offered on own airlift", me ~= nil)
w5:takeMission(me.id, "ucid3", "Ole")
for _ = 1, 4 do w5:escortSample(me.id, true) end
for _ = 1, 30 do w5:tick(); if w5.state.missions[me.id].status ~= "open" then break end end
check("escorted airlift delivered completes ESCORT", w5.state.missions[me.id].status == "done",
  w5.state.missions[me.id].status)

local w6 = wire(DCC.War.new(T, C, cfg, 12))
w6.state.nodes.senaki.supply = 300
local c6 = w6:startCargo("convoy", "blue", "senaki", "zugdidi", 30)
c6.front = true
w6:tick()
local mcv = find(w6, "blue", "CONVOY", c6.id)
check("CONVOY offered on a front convoy", mcv ~= nil)
w6:takeMission(mcv.id, "ucid4", "Lars")
check("taken convoy is escorted (no ambush)", w6.state.moves[c6.id].escorted == true)
for _ = 1, 4 do w6:escortSample(mcv.id, true) end
for _ = 1, 30 do w6:tick(); if w6.state.missions[mcv.id].status ~= "open" then break end end
check("escorted convoy delivered completes CONVOY", w6.state.missions[mcv.id].status == "done",
  w6.state.missions[mcv.id].status)

-- Ambush risk without escort (abstract): over many unescorted trips some get hit.
local w7 = DCC.War.new(T, C, cfg, 13)
local hits = 0
for i = 1, 200 do
  w7.state.nodes.senaki.supply = 300
  local c = w7:startCargo("convoy", "blue", "senaki", "zugdidi", 30)
  c.front = true
  w7:deliver(c)
  if (c.health or 1) < 1 then hits = hits + 1 end
end
check("unescorted front convoys get ambushed sometimes", hits > 10 and hits < 60, hits)

print("RECON")
local mr = find(war, "blue", "RECON")
war:takeMission(mr.id, "ucid1", "Morten")
war:completeMission(mr.id, true)
local intel = war.state.intel.blue[mr.target]
check("recon writes intel to the save", intel ~= nil and intel.platoons == #war.state.nodes[mr.target].platoons)
check("RECON complete", war.state.missions[mr.id].status == "done")

print("CSAR")
local w8 = wire(DCC.War.new(T, C, cfg, 14))
local did = w8:addDowned("blue", { x = 1, z = 2 }, "Morten", "FA-18C_hornet", "kutaisi")
w8:tick()
local mcs = find(w8, "blue", "CSAR", did)
check("CSAR offered for a downed pilot", mcs ~= nil)
w8:takeMission(mcs.id, "ucid5", "Heli")
w8.state.nodes.senaki.air["FA-18C_hornet"] = 2
w8:rescue(did, "senaki")
w8:tick()
check("rescue completes CSAR", w8.state.missions[mcs.id].status == "done")
check("aircraft refunded where the pilot landed", w8.state.nodes.senaki.air["FA-18C_hornet"] == 3)
local did2 = w8:addDowned("blue", { x = 1, z = 2 }, "Jens", "F-16C_50", "kutaisi")
for _ = 1, 26 do w8:tick() end
check("pilot not rescued in 2 h is captured", w8.state.downed[did2] == nil and events(w8, "captured") >= 1)

print("LOGISTICS and air assault")
local w9 = wire(DCC.War.new(T, C, cfg, 15))
w9.state.nodes.zugdidi.supply = 0
w9.state.nodes.zugdidi.outOfSupply = true
w9:tick()
local ml = find(w9, "blue", "LOGISTICS", "zugdidi")
check("LOGISTICS offered for a node out of supply", ml ~= nil)
w9:takeMission(ml.id, "ucid5", "Heli")
local su = w9:takeCrate("senaki", 10)
w9:deliverCrate("blue", "zugdidi", su)
w9:tick()
check("crate delivered completes LOGISTICS", w9.state.missions[ml.id].status == "done")
check("supply landed in the save", w9.state.nodes.zugdidi.supply > 0)

-- Troops dropped on an empty enemy node take it.
local gali = w9.state.nodes.gali
for i = #gali.platoons, 1, -1 do w9:destroyPlatoon(gali.platoons[i]) end
local pid = w9.state.nodes.zugdidi.platoons[1]
w9:carryPlatoon(pid, "heli1")
check("carried platoon leaves its node", w9.state.platoons[pid].node == nil and w9.state.carried[pid] ~= nil)
w9:dropPlatoons({ pid }, "gali", "blue")
w9:tick()
check("air assault on an empty node captures it", w9.state.nodes.gali.side == "blue")

-- A carried platoon goes home on restart.
local pid2 = w9.state.nodes.senaki.platoons[1]
w9:carryPlatoon(pid2, "heli2")
local saved = J.decode(J.encode(w9:snapshot()))
local r = DCC.War.restore(T, C, cfg, saved)
check("restart returns carried troops home", r.state.platoons[pid2].node == "senaki" and r.state.carried[pid2] == nil)
check("ops state survives save/restore", r.state.nodes.zugdidi.supply > 0 and r.state.missions ~= nil)

print("AI air pools")
local wa = DCC.War.new(T, C, cfg, 16)
wa:airTake("red", "fighter", 2)
wa:airLoss("red", "fighter", 1)
wa:airReturn("red", "fighter", 1)
check("sortie draws and returns aircraft", wa.state.airPool.red.fighter == 7)
wa.state.nodes.beslan.supply = 300
for _ = 1, 24 do wa:tick() end
check("depots buy replacements", wa.state.airPool.red.fighter + wa.state.airPool.red.attack >= 15)

print("Capture side effects")
local wc = DCC.War.new(T, C, cfg, 17)
wc.state.nodes.kutaisi.side = "red"
wc:onCaptureOps("kutaisi")
check("captured SAM site is destroyed", wc.state.nodes.kutaisi.sam.status == "destroyed")

print("Pilot records")
local P = DCC.Pilots.new()
P:sortie("u1", "blue", "Caucasus", "Morten")
P:add("u1", "kills_air", 3)
P:mission("u1", "SEAD")
P:mission("u1", "CAP")
P:add("u1", "rescues", 1)
check("score from kills, missions, rescues", P:score("u1") == 3 * 10 + 2 * 20 + 25, P:score("u1"))
P:add("u1", "missions", 2)
check("rank from score", P:rank("u1") == "Captain", P:rank("u1"))
local back = DCC.Pilots.new(J.decode(J.encode(P.data)))
check("pilot records survive save/load", back:score("u1") == P:score("u1") and back.data.pilots.u1.byType.SEAD == 1)
check("summary text", back:summary("u1"):find("Morten") ~= nil)
check("leaderboard", #back:top(5) == 1)

print("Fog of war")
do
  local wf = wire(DCC.War.new(T, C, cfg, 21), true)
  wf:tick(); wf:tick()
  local function count(side, t)
    local n = 0
    for _, m in ipairs(wf:openMissions(side)) do if m.type == t then n = n + 1 end end
    return n
  end
  check("no SEAD without a known SAM", count("blue", "SEAD") == 0)
  check("no BAI without a seen column", count("blue", "BAI") == 0)
  check("STRIKE on fixed bases still offered", count("blue", "STRIKE") > 0)

  -- an ELINT contact on an enemy SAM puts it on the board, with the error in the label
  local samNode
  for _, id in ipairs(wf.T.order) do
    local ns = wf.state.nodes[id]
    if ns.side == "red" and ns.sam and ns.sam.status == "up" then samNode = id; break end
  end
  wf:addContact("blue", "sam:" .. samNode, { kind = "sam", node = samNode, source = "elint", err = 6000 })
  check("RED never sees BLUE's contacts", wf:contact("red", "sam:" .. samNode) == nil)
  wf:tick()
  local sm
  for _, m in ipairs(wf:openMissions("blue")) do if m.type == "SEAD" and m.target == samNode then sm = m end end
  check("ELINT contact opens SEAD", sm ~= nil)
  check("SEAD label shows ELINT error", sm and sm.label:find("ELINT") ~= nil, sm and sm.label)

  -- a better ELINT fix is kept while fresh, a worse one does not overwrite it
  wf:addContact("blue", "sam:" .. samNode, { kind = "sam", node = samNode, source = "elint", err = 900, pos = { x = 1, z = 1 } })
  wf:addContact("blue", "sam:" .. samNode, { kind = "sam", node = samNode, source = "elint", err = 4000, pos = { x = 9, z = 9 } })
  local c = wf:contact("blue", "sam:" .. samNode)
  check("better ELINT fix kept", c.err == 900 and c.pos.x == 1, c.err)

  -- aging: fresh -> stale -> forgotten
  local I = cfg.intel
  for _ = 1, I.staleTicks do wf:tick() end
  check("contact goes stale", not wf:isFresh("blue", "sam:" .. samNode) and wf:contact("blue", "sam:" .. samNode) ~= nil)
  check("stale SAM reported as stale", wf:samKnown("blue", samNode) == "stale")
  for _ = 1, I.expireTicks do wf:tick() end
  check("old contact forgotten", wf:contact("blue", "sam:" .. samNode) == nil)

  -- recon leaves node and SAM contacts and makes the SAM known
  wf:recordIntel("blue", samNode)
  check("recon leaves a node contact", wf:isFresh("blue", "n:" .. samNode))
  check("recon makes the SAM known", wf:samKnown("blue", samNode) == "known")

  -- BAI only on columns BLUE has seen
  local seenMove
  for _ = 1, 300 do
    wf:tick()
    for _, mid in ipairs(DCC.util.sortedKeys(wf.state.moves)) do
      local mv = wf.state.moves[mid]
      if mv.side == "red" and mv.status == "moving" and mv.kind ~= "airlift" then
        local d = wf:frontDistance("red")
        if math.min(d[mv.to] or 99, d[mv.from] or 99) <= 2 then seenMove = mid; break end
      end
    end
    if seenMove then break end
  end
  if seenMove then
    wf:addContact("blue", "m:" .. seenMove, { kind = "move", source = "visual" })
    wf:tick()
    local found = false
    for _, m in ipairs(wf:openMissions("blue")) do if m.type == "BAI" and m.target == seenMove then found = true end end
    check("seen column gets a BAI", found or wf.state.moves[seenMove] == nil)
  else
    check("found a red column to spot", false)
  end

  -- front estimate: only enemy nodes touching our territory
  local est, rear = 0, 0
  for _, id in ipairs(wf.T.order) do
    if wf.state.nodes[id].side == "red" then
      if wf:frontEstimate("blue", id) then est = est + 1 else rear = rear + 1 end
    end
  end
  check("front estimates only for front nodes", est > 0 and rear > 0, est .. " front / " .. rear .. " rear")

  -- contacts survive save/restore
  local saved = J.decode(J.encode(wf:snapshot()))
  local wr = DCC.War.restore(T, C, cfg, saved)
  check("contacts in the save", wr:contact("blue", "n:" .. samNode) ~= nil)
end

print("Radar stations, AWACS, recon photos")
do
  local function findM(w, side, t, target)
    for _, m in ipairs(w:openMissions(side)) do
      if m.type == t and (target == nil or m.target == target) then return m end
    end
  end
  local wr = wire(DCC.War.new(T, C, cfg, 31))
  check("EWR at depots only", wr.state.nodes.beslan.ewr.status == "up" and wr.state.nodes.gori.ewr == nil)
  check("AWACS pools start stocked", wr.state.airPool.blue.awacs == cfg.radar.awacsPoolStart)
  wr:tick(); wr:tick()
  local me = findM(wr, "blue", "EWR")
  check("EWR strike offered (fog off)", me ~= nil)
  wr:takeMission(me.id, "u9", "Kim")
  wr:ewrHit(me.target)
  wr:tick()
  check("radar kill completes EWR", wr.state.missions[me.id].status == "done")
  wr.state.nodes[me.target].supply = 300
  for _ = 1, cfg.radar.ewrRebuildTicks + 1 do wr:tick() end
  check("destroyed EWR rebuilt after 6 h for supply",
    wr.state.nodes[me.target].side ~= "red" or wr:ewrUp(me.target))

  check("no HVAA while the enemy has no AWACS up", findM(wr, "blue", "HVAA") == nil)
  wr:setAwacs("red", true)
  wr:tick()
  local mh = findM(wr, "blue", "HVAA")
  check("HVAA offered against an airborne AWACS", mh ~= nil)
  wr:takeMission(mh.id, "u9", "Kim")
  local poolBefore = wr.state.stats.airLost and wr.state.stats.airLost.red or 0
  wr:awacsLost("red")
  wr:tick()
  check("AWACS kill completes HVAA", wr.state.missions[mh.id].status == "done")
  check("AWACS loss counted", wr.state.stats.airLost.red == poolBefore + 1)

  local h = DCC.War.radarHorizonM(100, 25)
  check("radar horizon: ~370 m at 100 km", h > 300 and h < 450, h)
  check("radar horizon: nothing hides close in", DCC.War.radarHorizonM(10, 25) == 0)

  -- fog: EWR needs a known site; recon finds it and photographs the base
  local wf = wire(DCC.War.new(T, C, cfg, 32), true)
  wf:tick(); wf:tick()
  check("fog: no EWR strike on an unknown radar", findM(wf, "blue", "EWR") == nil)
  wf:recordIntel("blue", "beslan")
  wf:tick()
  check("recon finds the radar: EWR strike offered", findM(wf, "blue", "EWR", "beslan") ~= nil)
  local n = wf:contact("blue", "n:beslan")
  check("recon photo lists every platoon", n.photo and #n.photo == #wf.state.nodes.beslan.platoons, n.photo and #n.photo)
  check("recon photo names vehicle types", n.photo and n.photo[1] and n.photo[1].text:find("%dx ") ~= nil,
    n.photo and n.photo[1] and n.photo[1].text)
  check("fog: no HVAA on an AWACS nobody has seen", (function() wf:setAwacs("red", true); wf:tick()
    return findM(wf, "blue", "HVAA") == nil end)())

  -- capture destroys the radar
  local wc2 = DCC.War.new(T, C, cfg, 33)
  wc2:onCaptureOps("beslan")
  check("captured radar destroyed", wc2.state.nodes.beslan.ewr.status == "destroyed")
end

print("Long run with ops")
local wl = DCC.War.new(T, C, cfg, 18)
local ok = true
for _ = 1, 1500 do
  local okTick, err = pcall(wl.tick, wl)
  if not okTick then ok = false; print("    " .. tostring(err)); break end
end
check("1500 ticks with the board running", ok)
local open = #wl:openMissions("blue") + #wl:openMissions("red")
check("boards stay populated", open > 8, open)

print(string.format("\n%d passed, %d failed", passed, failed))
DCC_EXIT_CODE = failed == 0 and 0 or 1
