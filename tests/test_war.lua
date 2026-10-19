-- ============================================================================
-- Tests for the pure war model.   python tools/run_lua.py tests/test_war.lua
-- ============================================================================

local passed, failed = 0, 0
local function check(name, cond, detail)
  if cond then passed = passed + 1; print("  ok   " .. name)
  else failed = failed + 1; print("  FAIL " .. name .. (detail and (" - " .. tostring(detail)) or "")) end
end

local T, C, cfg, J = DCC_THEATERS.Caucasus, DCC_CATALOGS.modern, DCC.config, DCC.json

-- Every platoon must be referenced exactly once: by its node or by its move.
local function invariants(war)
  local seen = {}
  for id, ns in pairs(war.state.nodes) do
    for _, pid in ipairs(ns.platoons) do
      local pl = war.state.platoons[pid]
      if not pl then return false, "node " .. id .. " lists missing platoon " .. pid end
      if pl.node ~= id then return false, pid .. " node mismatch" end
      if seen[pid] then return false, pid .. " listed twice" end
      seen[pid] = true
    end
  end
  for mid, mv in pairs(war.state.moves) do
    for _, pid in ipairs(mv.platoons) do
      local pl = war.state.platoons[pid]
      if not pl then return false, "move " .. mid .. " lists missing platoon " .. pid end
      if pl.move ~= mid then return false, pid .. " move mismatch" end
      if seen[pid] then return false, pid .. " listed twice" end
      seen[pid] = true
    end
  end
  for pid in pairs(war.state.carried or {}) do
    if seen[pid] then return false, pid .. " carried and placed" end
    seen[pid] = true
  end
  for pid, pl in pairs(war.state.platoons) do
    if not seen[pid] then return false, pid .. " is orphaned" end
    if pl.health < cfg.destroyedBelow or pl.health > 1 then return false, pid .. " bad health " .. pl.health end
  end
  return true
end

print("JSON")
do
  local v = { a = 1, b = "x\"y\n", c = { 1, 2.5, { d = true } }, e = {}, f = 0.1 + 0.2 }
  local back = J.decode(J.encode(v))
  check("round trip strings, arrays, nesting", back.b == v.b and back.c[2] == 2.5 and back.c[3].d == true)
  check("floats round trip exactly", back.f == v.f)
  check("pretty output decodes", J.decode(J.encode(v, true)).a == 1)
end

print("Start state")
local war = DCC.War.new(T, C, cfg, 1)
do
  local expected, count = 0, 0
  for _, n in ipairs(T.nodes) do
    local class = n.depot and "depot" or (n.kind == "airbase" and "airbase" or "town")
    expected = expected + cfg.garrisonStart[class]
  end
  for _ in pairs(war.state.platoons) do count = count + 1 end
  check("start garrisons match config", count == expected, count .. " vs " .. expected)
  check("invariants at start", invariants(war))
  local dist = war:frontDistance("blue")
  check("Zugdidi is on the blue front", dist.zugdidi == 1)
  check("Batumi is behind the blue front", dist.batumi > 1)
  check("depots are closed at start", not war:depotsOpen("blue") and not war:depotsOpen("red"))
  check("front line drawn at start", #DCC.front.segments(war) >= 4)
  for _, e in ipairs(war.T.edges) do
    if not e.km or e.km <= 0 or e.km > 400 then check("edge length sane " .. e.a .. "-" .. e.b, false, e.km) end
  end
end

print("Determinism and save/restore")
do
  local a = DCC.War.new(T, C, cfg, 77)
  local b = DCC.War.new(T, C, cfg, 77)
  for _ = 1, 400 do a:tick(); b:tick() end
  check("same seed gives the same war", J.encode(a:snapshot()) == J.encode(b:snapshot()))

  -- A war saved to JSON and restored must continue exactly like one that never stopped.
  local saved = J.decode(J.encode(a:snapshot()))
  local r = DCC.War.restore(T, C, cfg, saved)
  for _ = 1, 400 do a:tick(); r:tick() end
  check("restored war continues identically", J.encode(a:snapshot()) == J.encode(r:snapshot()))
  check("invariants after 800 ticks", invariants(a))
end

print("Long run")
do
  local w = DCC.War.new(T, C, cfg, 5)
  local captures, ok, why = 0, true, nil
  for _ = 1, 3000 do
    for _, ev in ipairs(w:tick()) do if ev.kind == "capture" then captures = captures + 1 end end
    if w.state.tick % 100 == 0 then ok, why = invariants(w); if not ok then break end end
    if w.state.winner then break end
  end
  check("invariants hold over a long run", ok, why)
  check("the front moves (captures happen)", captures > 10, captures)
end

print("Victory")
do
  local w = DCC.War.new(T, C, cfg, 9)
  -- Hand everything to BLUE except the Beslan depot, held by one weak platoon.
  for id, ns in pairs(w.state.nodes) do
    if id ~= "beslan" and ns.side == "red" then
      for i = #ns.platoons, 1, -1 do w:destroyPlatoon(ns.platoons[i]) end
      ns.side = "blue"
      for _ = 1, 3 do w:newPlatoon("blue", "ARMOR_PLT", id) end   -- occupied, not empty
    end
  end
  local mz = w.state.nodes.beslan
  for i = #mz.platoons, 2, -1 do w:destroyPlatoon(mz.platoons[i]) end
  check("depots open when nothing else is reachable", w:depotsOpen("blue"))
  for _ = 1, 2000 do w:tick(); if w.state.winner then break end end
  check("BLUE wins by taking the last depot", w.state.winner == "blue", w.state.winner)
  local redLeft = 0
  for _, pl in pairs(w.state.platoons) do if pl.side == "red" then redLeft = redLeft + 1 end end
  check("loser's stray units removed", redLeft == 0, redLeft)
  local before = w.state.tick
  w:tick()
  check("a finished war does not tick on", w.state.tick == before)
end

print("Live mode")
do
  local w = DCC.War.new(T, C, cfg, 3)
  w.liveFn = function() return true end     -- everything is "spawned"
  local moved = 0
  for _ = 1, 50 do w:tick() end
  for _, mv in pairs(w.state.moves) do if mv.progress > 0 then moved = moved + 1 end end
  check("live moves are not advanced by the model", moved == 0, moved)
  local pid = next(w.state.platoons)
  w:setHealth(pid, 0)
  check("setHealth(0) destroys the platoon", w.state.platoons[pid] == nil)
end

print("Supply (phase 2)")
do
  local w = DCC.War.new(T, C, cfg, 4)
  check("every node starts with supply", (function()
    for _, ns in pairs(w.state.nodes) do if not ns.supply or ns.supply <= 0 then return false end end
    return true end)())
  check("airbases start with their owner's aircraft", w.state.nodes.senaki.air["FA-18C_hornet"] == 4
    and w.state.nodes.senaki.air["Su-27"] == nil)
  local convoys, airlifts = 0, 0
  for _ = 1, 400 do
    w:tick()
    for _, mv in pairs(w.state.moves) do
      if mv.kind == "convoy" then convoys = convoys + 1 elseif mv.kind == "airlift" then airlifts = airlifts + 1 end
    end
  end
  check("convoys run", convoys > 0, convoys)
  check("airlifts fly", airlifts > 0, airlifts)
  check("supply gets delivered", w.state.stats.delivered.blue > 0 and w.state.stats.delivered.red > 0)
  check("invariants with cargo moves", invariants(w))

  -- An assault cannot be launched from a node with no supply.
  local w2 = DCC.War.new(T, C, cfg, 4)
  for _, ns in pairs(w2.state.nodes) do if ns.side == "blue" then ns.supply = 0 end end
  check("no supply, no attack", w2:assaultAffordable("zugdidi") == 0)
  check("out of supply removes the defender bonus", w2:bonusOf("zugdidi") == 1)

  -- Killing the convoys that feed BLUE's main effort weakens BLUE's offensive
  -- (summed over a few wars: a single war is too noisy to judge).
  local function offensive(text, interdict)
    local wx = DCC.War.restore(T, C, cfg, J.decode(text))
    local sent = 0
    for _ = 1, 288 do
      if interdict then
        local f = wx.state.focus and wx.state.focus.blue
        for mid, mv in pairs(wx.state.moves) do
          if f and mv.kind == "convoy" and mv.side == "blue" and wx.T.nodes[f.target].nb[mv.to] then
            wx:destroyCargo(mid, "test")
          end
        end
      end
      for _, ev in ipairs(wx:tick()) do
        if ev.kind == "assault" and ev.side == "blue" then sent = sent + tonumber(ev.text:match("launches (%d+)")) end
      end
    end
    return sent
  end
  local normal, cut = 0, 0
  for _, seed in ipairs({ 303, 11, 42 }) do
    local base = DCC.War.new(T, C, cfg, seed)
    for _ = 1, 300 do base:tick() end
    local text = J.encode(base:snapshot())
    normal, cut = normal + offensive(text, false), cut + offensive(text, true)
  end
  check("killing convoys delays the assault they feed", cut < normal, cut .. " vs " .. normal)
end

print("War clock")
do
  local w = DCC.War.new(T, C, cfg, 4242)
  local warnings, ended = {}, nil
  local limit = math.floor(cfg.warClockDays * 86400 / cfg.tickSeconds + 0.5)
  for t = 1, limit + 5 do
    for _, ev in ipairs(w:tick()) do
      if ev.kind == "clock" then warnings[#warnings + 1] = ev.text end
      if ev.kind == "victory" then ended = { tick = w.state.tick, text = ev.text } end
    end
    if w.state.winner then break end
  end
  check("war ends within " .. cfg.warClockDays .. " days", w.state.winner ~= nil and ended and ended.tick <= limit)
  if w.state.winBy == "clock" then
    check("clock ends it exactly on time", ended.tick == limit, ended.tick)
    check("three warnings: 24 h, 6 h, 1 h", #warnings == 3 and warnings[1]:find("24 hours") and warnings[3]:find("1 hour"),
      #warnings)
    local gb = w:groundGained("blue")
    check("the side that gained ground wins", gb == 0 or ((gb > 0) == (w.state.winner == "blue")), gb)
    check("gains add up to zero", w:groundGained("blue") == -w:groundGained("red"))
    check("victory message says war clock", ended.text:find("war clock", 1, true) ~= nil, ended.text)
  else
    check("(ended by conquest before the clock)", true)
  end
  local frozen = w.state.tick
  w:tick()
  check("a finished war stays finished", w.state.tick == frozen)

  -- an older save restored deep into a war gets a fresh clock
  local old = DCC.War.new(T, C, cfg, 4243)
  old.state.tick = limit * 3
  local r = DCC.War.restore(T, C, cfg, J.decode(J.encode(old:snapshot())))
  r:tick()
  check("restored older save gets a full clock", r.state.winner == nil and r:clockTicksLeft() == limit - 1, r:clockTicksLeft())

  -- clock off
  local cfg2 = setmetatable({ warClockDays = 0 }, { __index = cfg })
  local off = DCC.War.new(T, C, cfg2, 4244)
  check("warClockDays = 0 turns it off", off:clockTicksLeft() == nil)
end

print(string.format("\n%d passed, %d failed", passed, failed))
DCC_EXIT_CODE = failed == 0 and 0 or 1
