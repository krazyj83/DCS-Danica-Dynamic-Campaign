-- ============================================================================
-- Every theater pack loads, is playable, and its war runs.
--   python tools/run_lua.py tests/test_theaters.lua
-- ============================================================================

local passed, failed = 0, 0
local function check(name, cond, detail)
  if cond then passed = passed + 1; print("  ok   " .. name)
  else failed = failed + 1; print("  FAIL " .. name .. (detail and (" - " .. tostring(detail)) or "")) end
end

for _, name in ipairs(DCC.config.rotation) do
  print(name)
  local th = DCC_THEATERS[name]
  check(name .. ": pack loaded", th ~= nil)
  if th then
    local war = DCC.War.new(th, DCC_CATALOGS.modern, DCC.config, 7)
    -- connected
    local seen, stack = {}, { war.T.order[1] }
    while #stack > 0 do
      local id = table.remove(stack)
      if not seen[id] then
        seen[id] = true
        for nb in pairs(war.T.nodes[id].nb) do stack[#stack + 1] = nb end
      end
    end
    local n = 0
    for _ in pairs(seen) do n = n + 1 end
    check(name .. ": every node reachable", n == #war.T.order, n .. "/" .. #war.T.order)
    local depots = { blue = 0, red = 0 }
    for _, id in ipairs(war.T.order) do
      if war.T.nodes[id].depot then depots[war.state.nodes[id].side] = depots[war.state.nodes[id].side] + 1 end
    end
    check(name .. ": both sides have a depot", depots.blue > 0 and depots.red > 0)
    local fronts = DCC.front.segments(war)
    check(name .. ": a front at the start", #fronts > 0, #fronts)
    local ok, err = pcall(function() for _ = 1, 600 do war:tick() end end)
    check(name .. ": 600 ticks (2 days) of war", ok, err)
    local caps = war.state.stats.captures
    check(name .. ": the front moves", caps.blue + caps.red > 0, caps.blue .. "/" .. caps.red)
    -- territory: one cell per base; every front point halfway between a BLUE and a RED base
    local terr = DCC.territory.compute(war)
    check(name .. ": a territory cell for every base", #terr.territory == #war.T.order, #terr.territory)
    local worst, pts = 0, 0
    for _, line in ipairs(terr.front) do
      for _, p in ipairs(line) do
        local db, dr = math.huge, math.huge
        for _, id in ipairs(war.T.order) do
          local d = DCC.util.distKm(p, war.T.nodes[id])
          if war.state.nodes[id].side == "blue" then db = math.min(db, d) else dr = math.min(dr, d) end
        end
        worst, pts = math.max(worst, math.abs(db - dr)), pts + 1
      end
    end
    check(name .. ": front lies halfway between the sides", pts > 0 and worst < 0.5, string.format("%d pts, worst %.2f km", pts, worst))
    local cached = DCC.territory.compute(war)
    check(name .. ": territory cached until a base changes hands", cached == terr)
    local flip
    for _, id in ipairs(war.T.order) do if war.state.nodes[id].side == "red" then flip = id; break end end
    war.state.nodes[flip].side = "blue"
    check(name .. ": recomputed after a capture", DCC.territory.compute(war) ~= terr)
    war.state.nodes[flip].side = "red"

    -- sea crossings never spawn
    local seaMoves, live = 0, 0
    for _, mv in pairs(war.state.moves) do
      if war:onSea(mv) then seaMoves = seaMoves + 1; if war:isMoveLive(mv) then live = live + 1 end end
    end
    check(name .. ": sea crossings are never live", live == 0, seaMoves .. " at sea")
  end
end

print(string.format("\n%d passed, %d failed", passed, failed))
DCC_EXIT_CODE = failed == 0 and 0 or 1
