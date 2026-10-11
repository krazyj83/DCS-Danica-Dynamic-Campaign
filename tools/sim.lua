-- ============================================================================
-- Offline war simulation: runs the war model with nobody online (every battle
-- resolved by dice) and writes a history file for tools/plot_war.py.
--
--   python tools/run_lua.py tools/sim.lua [ticks] [seed] [out.json] [red production multiplier]
-- ============================================================================

local ticks = tonumber(arg[1]) or 4000
local seed  = tonumber(arg[2]) or 2026
local out   = arg[3] or (DCC_ROOT .. "/docs/sim_history.json")

local theater = DCC_THEATERS.Caucasus
if arg[4] then theater.balance = { blue = 1.0, red = tonumber(arg[4]) } end -- balance sweep
if arg[5] == "swap" then                                                        -- bias check
  for _, n in ipairs(theater.nodes) do n.side = (n.side == "blue") and "red" or "blue" end
end
local war = DCC.War.new(theater, DCC_CATALOGS.modern, DCC.config, seed)

local history = { theater = "Caucasus", seed = seed, tickMinutes = DCC.config.tickSeconds / 60,
                  nodes = {}, edges = {}, snapshots = {}, events = {} }
for _, id in ipairs(war.T.order) do
  local tn = war.T.nodes[id]
  history.nodes[#history.nodes + 1] = { id = id, name = tn.name, lat = tn.lat, lon = tn.lon,
                                         kind = tn.kind, depot = tn.depot }
end
for _, e in ipairs(war.T.edges) do history.edges[#history.edges + 1] = { e.a, e.b } end

local function snapshot()
  local owners, garrisons = {}, {}
  for _, id in ipairs(war.T.order) do
    owners[id] = war.state.nodes[id].side
    garrisons[id] = #war.state.nodes[id].platoons
  end
  local s = war:summary()
  local sup = war:supplySummary()
  local supplies = {}
  for _, id in ipairs(war.T.order) do supplies[id] = math.floor(war.state.nodes[id].supply + 0.5) end
  history.snapshots[#history.snapshots + 1] = {
    tick = war.state.tick, owners = owners, garrisons = garrisons, supplies = supplies,
    blueSupply = math.floor(sup.blue), redSupply = math.floor(sup.red),
    blueNodes = s.blue.nodes, redNodes = s.red.nodes,
    bluePlatoons = s.blue.platoons, redPlatoons = s.red.platoons,
  }
end

snapshot()
local lastTick = 0
local kinds = {}
for _ = 1, ticks do
  local evs = war:tick()
  for _, ev in ipairs(evs) do
    local k = ev.kind .. ":" .. tostring(ev.side)
    kinds[k] = (kinds[k] or 0) + 1
    if ev.kind == "capture" or ev.kind == "victory" then
      history.events[#history.events + 1] = ev
      print(string.format("[tick %5d, day %5.1f] %s", ev.tick, ev.tick * 5 / 1440, ev.text))
    end
  end
  if war.state.tick % 12 == 0 then snapshot() end
  lastTick = war.state.tick
  if war.state.winner then break end
end
snapshot()

local st = war.state.stats
print(string.format("Ran %d ticks (%.1f days). Winner: %s", lastTick, lastTick * 5 / 1440, tostring(war.state.winner)))
print(string.format("Captures  blue %d / red %d", st.captures.blue, st.captures.red))
print(string.format("Produced  blue %d / red %d", st.produced.blue, st.produced.red))
print(string.format("Lost      blue %d / red %d", st.lost.blue, st.lost.red))
if st.delivered then
  print(string.format("Supply delivered blue %d / red %d, cargo lost blue %d / red %d",
    st.delivered.blue, st.delivered.red, st.cargoLost.blue, st.cargoLost.red))
end
for _, k in ipairs(DCC.util.sortedKeys(kinds)) do io.write(k, "=", kinds[k], "  ") end
print()

local f = assert(io.open(out, "w"))
f:write(DCC.json.encode(history))
f:close()
print("History written to " .. out)
