-- ============================================================================
-- Danica Dynamic Campaign - DCS bridge: SRS voice (v0.50).
-- Load after dcc_dcs_admin.lua, before dcc_main.lua.
-- ----------------------------------------------------------------------------
-- The mission cannot start programs (MissionScripting.lua stays sanitized),
-- so it only queues what should be spoken. The server hook
-- (hooks/DCC_rotation_hook.lua) collects the queue every few seconds through
-- DCC.srsPop() and plays each line with SRS's text-to-speech program
-- (DCS-SR-ExternalAudio.exe), one after the other per frequency.
--
-- What is spoken (frequencies in config srs.freqs, per side):
--   awacs    bogey dope answers ("Overlord / Magic")
--   command  captures, repulsed attacks, AWACS losses, surrenders, the war
--            clock and victory, your side's main effort and bases out of supply
--   info     airfield information for an own airbase with a player on the
--            ground nearby: wind, QNH, runway, aircraft in stock (every
--            srs.infoEveryMin minutes per base)
-- ============================================================================

DCC = DCC or {}
local B = DCC.dcs
local U = DCC.util

local function SC() return DCC.config.srs end
local function ok(fn, ...) local s, r = pcall(fn, ...); if s then return r end end

DCC.srsQueue = DCC.srsQueue or {}
B.srsInfoAt = {}

-- Queue one line for side's radio of kind ("awacs" | "command" | "info").
function B.srsSay(side, kind, text, name)
  local cfg = SC()
  if not cfg or not cfg.enabled then return false end
  local f = cfg.freqs[kind] and cfg.freqs[kind][side]
  if not f or not text or text == "" then return false end
  local q = DCC.srsQueue
  if #q >= cfg.maxQueue then table.remove(q, 1) end   -- nobody collects it (no hook): keep only the newest
  q[#q + 1] = { text = text, freq = f, mod = cfg.modulation, coal = B.COAL[side], name = name or cfg.names[kind] or "DCC",
                gender = cfg.gender[kind] or "male", culture = cfg.culture }
  return true
end

-- The hook collects the queue: a JSON array (then the queue is empty).
function DCC.srsPop()
  local q = DCC.srsQueue
  if #q == 0 then return "" end
  DCC.srsQueue = {}
  return DCC.json.encode(q)
end

-- Numbers read out the way pilots say them: 270 -> "2 7 0".
local function digits(n, width)
  local s = string.format("%0" .. (width or 3) .. "d", math.floor(n + 0.5))
  return (s:gsub("(%d)", "%1 "):gsub(" $", ""))
end
B.srsDigits = digits

-- ---------------------------------------------------------------------------
-- Bogey dope: also on the AWACS frequency
-- ---------------------------------------------------------------------------
local baseBogey = B.bogeyDope
if baseBogey then
  function B.bogeyDope(uname)
    local p = B.players and B.players[uname]
    local said
    local realOut = trigger.action.outTextForGroup
    trigger.action.outTextForGroup = function(gid, text, t, clear)
      said = text
      return realOut(gid, text, t, clear)
    end
    local s, err = pcall(baseBogey, uname)
    trigger.action.outTextForGroup = realOut
    if not s then U.log("ERROR bogey dope: %s", tostring(err)) end
    if p and said then
      local call = p.name or "Flight"
      local brg, nm, ft, rest = said:match("BRAA (%d+) / (%d+) nm / (%d+) ft(.-) %- ")
      local spoken
      if brg then
        local asp = rest and rest:match(", (%a+)") or nil
        spoken = string.format("%s, %s, bra %s, %s, %s thousand%s.", call, SC().names.awacs, digits(tonumber(brg)),
          nm, math.floor(tonumber(ft) / 1000 + 0.5), asp and (", " .. asp) or "")
      elseif said:find("clean", 1, true) then
        spoken = string.format("%s, %s, clean.", call, SC().names.awacs)
      end
      if spoken then B.srsSay(p.side, "awacs", spoken) end
    end
  end
end

-- ---------------------------------------------------------------------------
-- Command net: the war's news
-- ---------------------------------------------------------------------------
local BOTH = { capture = true, victory = true, clock = true, repulsed = true, awacs_lost = true, surrender = true }
local OWN = { focus = true, nosupply = true, airassault = true }

local function speakable(text)
  return (tostring(text):gsub("^%u+: ", ""):gsub("%s+%-%s+", ", "):gsub("[%*_#]", ""))
end

local baseAnnounce = B.announce
function B.announce(events)
  baseAnnounce(events)
  if not (SC() and SC().enabled) then return end
  for _, ev in ipairs(events or {}) do
    if BOTH[ev.kind] then
      for _, side in ipairs({ "blue", "red" }) do B.srsSay(side, "command", speakable(ev.text)) end
    elseif OWN[ev.kind] and ev.side then
      B.srsSay(ev.side, "command", speakable(ev.text))
    end
  end
end

-- ---------------------------------------------------------------------------
-- Airfield information
-- ---------------------------------------------------------------------------
function B.airfieldInfo(id)
  local war = B.war
  local p = B.nodePos[id]
  local ns = war.state.nodes[id]
  if not p or not ns then return nil end
  local parts = { string.format("%s information", war:nodeName(id)) }
  local w = atmosphere and atmosphere.getWind and ok(atmosphere.getWind, { x = p.x, y = (p.y or 0) + 10, z = p.z })
  if w then
    local spd = math.sqrt(w.x * w.x + w.z * w.z)
    if spd < 1 then parts[#parts + 1] = "wind calm"
    else
      local from = math.floor((math.deg(math.atan2(-w.z, -w.x)) + 360) % 360 + 0.5)
      if from == 0 then from = 360 end
      parts[#parts + 1] = string.format("wind %s at %d", digits(from), math.floor(spd * 1.944 + 0.5))
    end
  end
  -- DCS returns two numbers: temperature (K) and pressure (Pa) - v0.56 (it was read as a table)
  if atmosphere and atmosphere.getTemperatureAndPressure then
    local s, t, pa = pcall(atmosphere.getTemperatureAndPressure, { x = p.x, y = p.y or 0, z = p.z })
    if s and type(t) == "number" and type(pa) == "number" then
      parts[#parts + 1] = string.format("temperature %d, QNH %d", math.floor(t - 273.15 + 0.5), math.floor(pa / 100 + 0.5))
    end
  end
  parts[#parts + 1] = (war.runwayClosed and war:runwayClosed(id)) and "runway closed, helicopters only" or "runway open"
  local types, total = 0, 0
  for _, n in pairs(ns.air or {}) do if n > 0 then types, total = types + 1, total + n end end
  parts[#parts + 1] = string.format("%d aircraft of %d types in stock", total, types)
  if ns.outOfSupply then parts[#parts + 1] = "out of supply" end
  return table.concat(parts, ", ") .. "."
end

function B.srsInfoTick()
  local cfg = SC()
  if not (cfg and cfg.enabled) then return end
  local now = timer.getTime()
  local war, near = B.war, {}
  for _, pl in pairs(B.players or {}) do
    local u = ok(Unit.getByName, pl.unit)
    if u and not ok(u.inAir, u) then
      local id = B.nearestNodeOf and B.nearestNodeOf(u:getPoint(), pl.side, cfg.infoKm * 1000)
      if id and B.airbases[id] then near[id] = pl.side end
    end
  end
  for id, side in pairs(near) do
    if war.state.nodes[id].side == side and now - (B.srsInfoAt[id] or -1e9) >= cfg.infoEveryMin * 60 then
      B.srsInfoAt[id] = now
      B.srsSay(side, "info", B.airfieldInfo(id), war:nodeName(id) .. " information")
    end
  end
end

local basePoll = B.opsPoll
function B.opsPoll()
  basePoll()
  local s, err = pcall(B.srsInfoTick)
  if not s then U.log("ERROR srs info: %s", tostring(err)) end
end

local baseInit = B.init
function B.init(war, theater, catalog)
  baseInit(war, theater, catalog)
  B.srsInfoAt = {}
end
