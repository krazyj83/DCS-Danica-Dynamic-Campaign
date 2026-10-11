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
