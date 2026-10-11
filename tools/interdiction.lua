-- ============================================================================
-- Interdiction experiment: does killing convoys delay the assault they feed?
--
-- For each seed: run a war for a warm-up period, copy it exactly (JSON save +
-- restore), then run both copies on. In copy B, every BLUE convoy heading to
-- one of BLUE's main-effort staging nodes is destroyed on departure - what a
-- player flying BAI on that road would do. Compare BLUE's offensive.
--
--   python tools/run_lua.py tools/interdiction.lua [seeds] [warmup] [ticks]
-- ============================================================================

local seeds  = tonumber(arg[1]) or 8
local warmup = tonumber(arg[2]) or 300
local ticks  = tonumber(arg[3]) or 288          -- one day
local T, C, cfg, J = DCC_THEATERS.Caucasus, DCC_CATALOGS.modern, DCC.config, DCC.json

local function stagingNodes(war)
  local f = war.state.focus and war.state.focus.blue
  local set = {}
  if f then
    for nb in pairs(war.T.nodes[f.target].nb) do
      if war.state.nodes[nb].side == "blue" then set[nb] = true end
    end
  end
  return set
end

local function run(war, interdict)
  local r = { assaultPlatoons = 0, firstAssault = nil, captures = 0, killed = 0 }
  for i = 1, ticks do
    if interdict then
      local staging = stagingNodes(war)
      for mid, mv in pairs(war.state.moves) do
        if mv.kind == "convoy" and mv.side == "blue" and staging[mv.to] then
          war:destroyCargo(mid, "interdicted")
          r.killed = r.killed + 1
        end
      end
    end
    for _, ev in ipairs(war:tick()) do
      if ev.kind == "assault" and ev.side == "blue" then
        r.assaultPlatoons = r.assaultPlatoons + (tonumber(ev.text:match("launches (%d+)")) or 0)
        r.firstAssault = r.firstAssault or i
      elseif ev.kind == "capture" and ev.side == "blue" then
        r.captures = r.captures + 1
      end
    end
  end
  local stag = 0
  for id in pairs(stagingNodes(war)) do stag = stag + war.state.nodes[id].supply end
  r.stagingSupply = stag
  return r
end

local totA, totB, capA, capB, lessCount = 0, 0, 0, 0, 0
print(string.format("%-5s | %-34s | %-34s", "seed", "normal: platoons / 1st / captures", "interdicted: platoons / 1st / captures"))
for s = 1, seeds do
  local base = DCC.War.new(T, C, cfg, s * 101)
  for _ = 1, warmup do base:tick() end
  local text = J.encode(base:snapshot())
  local a = DCC.War.restore(T, C, cfg, J.decode(text))
  local b = DCC.War.restore(T, C, cfg, J.decode(text))
  local ra, rb = run(a, false), run(b, true)
  totA, totB = totA + ra.assaultPlatoons, totB + rb.assaultPlatoons
  capA, capB = capA + ra.captures, capB + rb.captures
  if rb.assaultPlatoons < ra.assaultPlatoons then lessCount = lessCount + 1 end
  print(string.format("%-5d | %8d / %5s / %3d            | %8d / %5s / %3d  (%d convoys killed)", s,
    ra.assaultPlatoons, tostring(ra.firstAssault or "-"), ra.captures,
    rb.assaultPlatoons, tostring(rb.firstAssault or "-"), rb.captures, rb.killed))
end
print(string.format("TOTAL BLUE platoons sent into assaults: normal %d, interdicted %d (%.0f%% fewer)",
  totA, totB, totA > 0 and (1 - totB / totA) * 100 or 0))
print(string.format("TOTAL BLUE captures: normal %d, interdicted %d", capA, capB))
print(string.format("Interdiction reduced BLUE's offensive in %d of %d wars", lessCount, seeds))
DCC_INTERDICTION = { normal = totA, interdicted = totB, less = lessCount, seeds = seeds }
