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
    local ok, err = pcall(fn, ...)
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
end

-- One war step.
function DCC.onTick()
  local war = DCC.warObj
  local events = war:tick()
  DCC.dcs.announce(events)
  DCC.dcs.syncAirbases()
  DCC.dcs.reconcile()
  DCC.dcs.draw()
  DCC.save()

  if war.state.winner and not DCC.ended then
    DCC.ended = true
    trigger.action.setUserFlag(DCC.config.campaignOverFlag, 1)
    local rot, nextMap = DCC.config.rotation, nil
    for i, m in ipairs(rot) do if m == DCC.theaterName then nextMap = rot[i % #rot + 1] end end
    trigger.action.outText(string.format("The war on %s is over. %s wins.%s",
      DCC.theaterName, war.state.winner:upper(),
      nextMap and (" Next theater: " .. nextMap .. ".") or ""), 120)
    U.log("war over, winner %s, flag %d set", war.state.winner, DCC.config.campaignOverFlag)
  end
end

function DCC.start()
  if DCC.started then return end
  local theater, name = pickTheater()
  if not theater then return end
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

  DCC.dcs.init(war, theater, catalog)
  DCC.dcs.addMenus()
  DCC.dcs.updateLive()
  DCC.dcs.reconcile()
  DCC.dcs.draw()

  -- Save when the mission ends (server stop or restart).
  world.addEventHandler({ onEvent = function(_, e)
    if e.id == world.event.S_EVENT_MISSION_END then safe("save", DCC.save)() end
  end })

  local cfg = DCC.config
  timer.scheduleFunction(function(_, t)
    safe("liveCheck", DCC.dcs.liveCheck)()
    return t + cfg.liveCheckSeconds
  end, nil, timer.getTime() + cfg.liveCheckSeconds)

  timer.scheduleFunction(function(_, t)
    safe("tick", DCC.onTick)()
    return t + cfg.tickSeconds
  end, nil, timer.getTime() + cfg.tickSeconds)

  local s = war:summary()
  trigger.action.outText(string.format("Danica Dynamic Campaign %s - %s, war day %.1f. BLUE %d nodes, RED %d nodes.",
    cfg.version, DCC.theaterName, war.state.tick * cfg.tickSeconds / 86400, s.blue.nodes, s.red.nodes), 20)
end
