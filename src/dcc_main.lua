-- ============================================================================
-- Danica Dynamic Campaign - main: start-up and the two loops
-- ----------------------------------------------------------------------------
--   DCC.start()  is called once at mission start (by the loader or bundle).
--   Every liveCheckSeconds (30 s): poll spawned units, update the live bubble.
--   Every tickSeconds (5 min):     advance the war one step, redraw, save.
--
-- Both loops run through timer.scheduleFunction and are wrapped in pcall, so a
-- script error is logged to dcs.log instead of silently stopping the war.
-- ============================================================================

DCC = DCC or {}
local U = DCC.util

local function safe(name, fn)
  return function(...)
    local args = { ... }
    local ok, err = xpcall(function() return fn(unpack(args)) end, debug.traceback)
    if not ok then U.log("ERROR in %s: %s", name, tostring(err)) end
  end
end

local function pickTheater()
  local name = DCC.config.theater
  if name == "auto" then name = env.mission and env.mission.theatre end
  local t = DCC_THEATERS and DCC_THEATERS[name]
  if not t then
    local msg = "DCC: no theater pack for map '" .. tostring(name) .. "'. Campaign not started."
    U.log(msg)
    trigger.action.outText(msg, 60)
  end
  return t, name
end

local function newSeed()
  -- os is sanitized in missions; mission clock + absolute time is unique enough
  return math.floor((timer.getAbsTime() * 1000 + timer.getTime() * 7919) % 2147483646) + 1
end

function DCC.save()
  if DCC.warObj then DCC.persist.save(DCC.theaterName, DCC.warObj:snapshot()) end
  if DCC.pilots and DCC.pilots.dirty then
    if DCC.persist.savePilots(DCC.pilots.data) then DCC.pilots.dirty = false end
  end
end

-- One war step.
function DCC.onTick()
  local war = DCC.warObj
  DCC.dcs.readWarehouses()          -- aircraft players took off with or landed
  local events = war:tick()
  DCC.dcs.announce(events)
  DCC.dcs.syncAirbases()
  DCC.dcs.writeWarehouses()         -- captures and restocks
  DCC.dcs.reconcile()
  DCC.dcs.reconcileCargo()
  DCC.dcs.opsTick()                 -- mission targets, AI air, menus
  DCC.dcs.draw()
  DCC.save()

  if war.state.winner and not DCC.ended then
    DCC.ended = true
    trigger.action.setUserFlag(DCC.config.campaignOverFlag, 1)
    local nextMap = DCC.nextMap(DCC.theaterName)
    -- the war report (scores before the bonus), then the victory bonus
    local report = DCC.warReport(war)
    local names, pts = DCC.pilots:warWon(war.state.roster, war.state.winner, war.state.winBy,
      DCC.config.victoryMinSorties)
    if #names > 0 then
      report = report .. string.format("\n\nVictory bonus (+%d points, %s) for %d %s pilots: %s", pts,
        war.state.winBy == "conquest" and "conquest" or "war clock", #names, war.state.winner:upper(),
        table.concat(names, ", "))
    end
    trigger.action.outText(report, 90)
    DCC.persist.writeReport(DCC.theaterName, war.state.tick, report)
    if DCC.dcs.publishFeed then DCC.dcs.publishFeed({ { kind = "report", text = report } }); DCC.dcs.writePublic() end
    DCC.save()
    -- the server hook sees this and loads the next map's mission
    DCC.persist.writeRotation({ current = nextMap, state = "ended", finished = DCC.theaterName,
                                winner = war.state.winner, next = nextMap, tick = war.state.tick })
    trigger.action.outText(string.format("The war on %s is over. %s wins.%s",
      DCC.theaterName, war.state.winner:upper(),
      nextMap and (" Next theater: " .. nextMap .. ".") or ""), 120)
    U.log("war over, winner %s, flag %d set", war.state.winner, DCC.config.campaignOverFlag)
  end
end

-- End-of-war report: how it ended, what it cost each side, the best pilots.
function DCC.warReport(war)
  local st, cfg = war.state, DCC.config
  local s, stats = war:summary(), st.stats
  local function two(t) t = t or {}; return string.format("BLUE %d / RED %d", math.floor((t.blue or 0) + 0.5),
    math.floor((t.red or 0) + 0.5)) end
  local days = (st.tick - (st.clockStart or 0)) * cfg.tickSeconds / 86400
  local lines = {
    string.format("=== WAR REPORT - %s ===", war.T.name),
    string.format("%s won %s after %.1f days.", st.winner:upper(),
      st.winBy == "conquest" and "by conquest" or "on the war clock", days),
    "Bases held at the end:   " .. two({ blue = s.blue.nodes, red = s.red.nodes }),
    "Bases captured:          " .. two(stats.captures),
    "Platoons lost:           " .. two(stats.lost),
    "Supply delivered (SU):   " .. two(stats.delivered),
    "Supply destroyed (SU):   " .. two(stats.cargoLost),
    "AI aircraft lost:        " .. two(stats.airLost),
  }
  -- best pilots of this war: points scored since their first sortie here
  local best = {}
  for key, r in pairs(st.roster or {}) do
    local gained = DCC.pilots:score(key) - (r.start or 0)
    local side = (r.blue or 0) >= (r.red or 0) and "BLUE" or "RED"
    best[#best + 1] = { key = key, name = r.name or key, pts = gained, side = side,
                        sorties = (r.blue or 0) + (r.red or 0),
                        missions = (r.blue_missions or 0) + (r.red_missions or 0) }
  end
  table.sort(best, function(a, b) if a.pts ~= b.pts then return a.pts > b.pts end return a.key < b.key end)
  if #best > 0 then
    lines[#lines + 1] = string.format("Top pilots (%d flew in this war):", #best)
    for i = 1, math.min(5, #best) do
      local b = best[i]
      lines[#lines + 1] = string.format("  %d. %s (%s) - %d points, %d sorties, %d missions",
        i, b.name, b.side, b.pts, b.sorties, b.missions)
    end
    local sq, sqList = {}, {}
    for _, b in ipairs(best) do
      local tag = DCC.Pilots.squadronOf(b.name)
      if tag then
        sq[tag] = sq[tag] or { tag = tag, pts = 0, n = 0 }
        sq[tag].pts, sq[tag].n = sq[tag].pts + b.pts, sq[tag].n + 1
      end
    end
    for _, s in pairs(sq) do sqList[#sqList + 1] = s end
    table.sort(sqList, function(a, b) if a.pts ~= b.pts then return a.pts > b.pts end return a.tag < b.tag end)
    if #sqList > 0 then
      lines[#lines + 1] = "Top squadrons:"
      for i = 1, math.min(3, #sqList) do
        lines[#lines + 1] = string.format("  %d. %s - %d points (%d pilots)", i, sqList[i].tag, sqList[i].pts, sqList[i].n)
      end
    end
  else
    lines[#lines + 1] = "No pilots flew in this war - the generals fought it alone."
  end
  return table.concat(lines, "\n")
end

-- The map after this one in the fixed rotation.
function DCC.nextMap(current)
  local rot = DCC.config.rotation
  for i, m in ipairs(rot) do if m == current then return rot[i % #rot + 1] end end
  return rot[1]
end

function DCC.start()
  if DCC.started then return end
  local theater, name = pickTheater()
  if not theater then return end

  -- Map rotation: if the server should be on another map (a restart loaded
  -- the wrong mission), do not touch this map's war - the hook switches over.
  local rot = DCC.persist.readRotation()
  if DCC.config.rotationEnforce and rot and rot.current and rot.current ~= (theater.name or name) then
    DCC.waitingForRotation = rot.current
    local msg = string.format("DCC: the campaign has moved on to %s. Loading it...", rot.current)
    U.log(msg)
    trigger.action.outText(msg, 120)
    return
  end
  DCC.persist.writeRotation({ current = theater.name or name, state = "running" })
  local catalog = DCC_CATALOGS and DCC_CATALOGS[DCC.config.era]
  if not catalog then U.log("no catalog for era %s", tostring(DCC.config.era)); return end
  DCC.theaterName = theater.name or name

  -- Restore the running war, or start a new one (also after a finished war).
  local state = DCC.persist.load(DCC.theaterName)
  local war
  if state and not state.winner then
    war = DCC.War.restore(theater, catalog, DCC.config, state)
    U.log("war restored on %s at tick %d", DCC.theaterName, state.tick or 0)
  else
    if state and state.winner then DCC.persist.archive(DCC.theaterName, state) end
    war = DCC.War.new(theater, catalog, DCC.config, newSeed())
    U.log("new war started on %s", DCC.theaterName)
  end
  DCC.warObj = war
  DCC.started = true
  DCC.pilots = DCC.Pilots.new(DCC.persist.loadPilots())   -- kept across wars and maps
  war.onMissionDone = function(m, outcome) DCC.dcs.onMissionDone(m, outcome) end

  DCC.dcs.init(war, theater, catalog)
  DCC.dcs.writeWarehouses()         -- enemy aircraft off every base before anyone slots
  DCC.dcs.addMenus()
  DCC.dcs.updateLive()
  DCC.dcs.reconcile()
  DCC.dcs.reconcileCargo()
  DCC.dcs.opsPoll()
  DCC.dcs.opsTick()
  DCC.dcs.draw()
  if DCC.dcs.writePublic then DCC.dcs.writePublic() end

  -- Save when the mission ends; guard player slots; pilot records and missions.
  world.addEventHandler({ onEvent = function(_, e)
    if e.id == world.event.S_EVENT_MISSION_END then safe("save", DCC.save)()
    else
      if e.id == world.event.S_EVENT_BIRTH and e.initiator then
        safe("slotGuard", DCC.dcs.onBirth)(e.initiator)
      end
      safe("opsEvent", DCC.dcs.onOpsEvent)(e)
    end
  end })

  local cfg = DCC.config
  timer.scheduleFunction(function(_, t)
    safe("liveCheck", DCC.dcs.liveCheck)()
    safe("opsPoll", DCC.dcs.opsPoll)()
    return t + cfg.liveCheckSeconds
  end, nil, timer.getTime() + cfg.liveCheckSeconds)

  timer.scheduleFunction(function(_, t)
    safe("detect", DCC.dcs.detect)()
    return t + 10
  end, nil, timer.getTime() + 10)

  if DCC.dcs.intelScan then
    timer.scheduleFunction(function(_, t)
      safe("intelScan", DCC.dcs.intelScan)()
      return t + cfg.intel.scanSeconds
    end, nil, timer.getTime() + 5)
    timer.scheduleFunction(function(_, t)
      safe("drawIntel", DCC.dcs.drawIntel)()
      return t + cfg.intel.drawEverySeconds
    end, nil, timer.getTime() + 6)
  end

  timer.scheduleFunction(function(_, t)
    safe("tick", DCC.onTick)()
    return t + cfg.tickSeconds
  end, nil, timer.getTime() + cfg.tickSeconds)

  local s = war:summary()
  trigger.action.outText(string.format("Danica Dynamic Campaign %s - %s, war day %.1f. BLUE %d nodes, RED %d nodes.",
    cfg.version, DCC.theaterName, war.state.tick * cfg.tickSeconds / 86400, s.blue.nodes, s.red.nodes), 20)
end
