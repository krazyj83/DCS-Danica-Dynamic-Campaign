-- ============================================================================
-- Danica Dynamic Campaign - DCS bridge: self-check, "Where can I spawn?" and
-- admin commands (v0.47). Load after dcc_dcs_armoury.lua, before dcc_main.lua.
-- ----------------------------------------------------------------------------
-- Self-check: 30 s after the mission starts the bridge checks what beta tests
-- kept tripping over (FARP pads and stock, airbases, GPS, AI templates, the
-- armoury, saving, the server hook) and writes one report to dcs.log and to
-- Saved Games\DCS\DCC\selfcheck.txt. Warnings are also shown on screen.
--
-- Where can I spawn?: F10 > Campaign lists your side's bases and open FARPs
-- with the aircraft still in stock there.
--
-- Admin: DCC.admin(line, player) runs a chat command and returns the reply.
-- The server hook (hooks/DCC_rotation_hook.lua) calls it for "-dcc ..." chat
-- lines from a Game Master slot or the server host, sends the reply back to
-- that player, and reloads the mission when the reply asks for it (RELOAD).
-- ============================================================================

DCC = DCC or {}
local B = DCC.dcs
local U = DCC.util

local function AC() return DCC.config.admin end
local function ok(fn, ...) local s, r = pcall(fn, ...); if s then return r end end

-- ===========================================================================
-- Self-check
-- ===========================================================================
local function warehouseOfName(name)
  local ab = ok(Airbase.getByName, name)
  return ab and ok(ab.getWarehouse, ab), ab
end

local function hasGps()
  local mis = env and env.mission
  if not mis then return nil end
  local fo = mis.forcedOptions or {}
  if fo.unrestrictedSATNAV then return true end
  for _, c in pairs(((mis.coalitions or {}).blue) or {}) do if c == 2 then return true end end   -- USA in BLUE
  if mis.forcedOptions == nil and mis.coalitions == nil then return nil end
  return false
end

-- Returns lines (each "OK ..." or "WARN ...") and the number of warnings.
function B.selfCheck()
  local war, lines, warns = B.war, {}, 0
  local function okL(fmt, ...) lines[#lines + 1] = "OK   " .. string.format(fmt, ...) end
  local function warn(fmt, ...) lines[#lines + 1] = "WARN " .. string.format(fmt, ...); warns = warns + 1 end

  -- saving
  if war.noSave then warn("the war cannot be saved (io/lfs sanitized?) - it restarts with the mission")
  else okL("war is saved to Saved Games\\DCS\\%s", DCC.config.saveFolder or "DCC") end

  -- airbases in the theater pack found in DCS
  local need, found, missing = 0, 0, {}
  for _, id in ipairs(war.T.order) do
    local tn = war.T.nodes[id]
    if tn.airbase and tn.kind == "airbase" then
      need = need + 1
      if B.airbases[id] then found = found + 1 else missing[#missing + 1] = war:nodeName(id) end
    end
  end
  if #missing > 0 then warn("%d of %d airbases not found in DCS: %s", #missing, need, table.concat(missing, ", "))
  else okL("all %d airbases found", need) end

  -- dynamic spawn at the HQs
  for _, side in ipairs({ "blue", "red" }) do
    local hq = war.mainBase and war:mainBase(side)
    local ns = hq and war.state.nodes[hq]
    local n = 0
    for _, c in pairs((ns and ns.air) or {}) do n = n + c end
    if hq and B.airbases[hq] then
      if n > 0 then okL("%s HQ %s: %d aircraft for dynamic spawn", side:upper(), war:nodeName(hq), n)
      else warn("%s HQ %s has no aircraft in stock", side:upper(), war:nodeName(hq)) end
    end
  end

  -- FARP pads, and the open FARPs stocked
  local pads, padsMissing, open, empty = 0, 0, 0, {}
  for _, id in ipairs(war.T.order) do
    if war:canHaveFarp(id) then
      for _, side in ipairs({ "blue", "red" }) do
        for _, pad in ipairs(B.farpPadNames(id, side)) do
          pads = pads + 1
          local w = warehouseOfName(pad)
          if not w then padsMissing = padsMissing + 1
          elseif war:farpAt(id) and war.state.nodes[id].side == side and not war:farpDry(id) then
            local t = (B.catalog.aircraft[side].helicopters or {})[1]
            if t and (ok(w.getItemCount, w, t) or 0) < 1 then empty[#empty + 1] = war:nodeName(id) end
          end
        end
      end
      if war:farpAt(id) then open = open + 1 end
    end
  end
  if padsMissing > 0 then warn("%d of %d FARP pads missing in the mission (rebuild it with make_mission.py)",
    padsMissing, pads)
  else okL("all %d FARP pads found", pads) end
  if #empty > 0 then warn("open FARPs without helicopters: %s", table.concat(empty, ", "))
  else okL("%d FARPs open and stocked", open) end

  -- armoury
  if B.armWarehouseMode and B.armWarehouseMode() then
    if #B.arm.names > 0 then okL("armoury: %d weapon types on the shelves", #B.arm.names)
    else warn("armoury: no weapon names accepted - the re-arm menus are empty") end
  end

  -- GPS (F-16 Link 16 needs it, v0.43)
  local gps = hasGps()
  if gps == false then warn("no GPS for BLUE: F-16 datalink will not sync (rebuild the mission, v0.43+)")
  elseif gps then okL("GPS on") end

  -- AI templates
  local tplMissing = {}
  for _, side in ipairs({ "blue", "red" }) do
    for _, role in ipairs(AC().templates or {}) do
      local name = "DCC_TPL_" .. side .. "_" .. role
      if not B.findTemplate(name) then tplMissing[#tplMissing + 1] = name end
    end
  end
  if #tplMissing > 0 then warn("AI templates missing: %s", table.concat(tplMissing, ", "))
  else okL("AI templates found") end

  -- CTLD
  if DCC.config.ctld and DCC.config.ctld.enabled ~= false then
    if ctld then okL("CTLD loaded") else warn("CTLD not loaded - no crates, troops or FOBs") end
  end

  -- the server hook (rotation, admin commands, daily restart)
  if DCC_HOOK_VERSION then okL("server hook %s", tostring(DCC_HOOK_VERSION))
  else warn("server hook not seen - no admin commands or map rotation (copy hooks\\DCC_rotation_hook.lua)") end

  return lines, warns
end

function B.runSelfCheck()
  local lines, warns = B.selfCheck()
  local head = string.format("DCC %s self-check on %s: %d warning(s)", DCC.config.version, DCC.theaterName or "?", warns)
  U.log("%s", head)
  for _, l in ipairs(lines) do U.log("self-check: %s", l) end
  if DCC.persist.writeFile then ok(DCC.persist.writeFile, "selfcheck.txt", head .. "\n" .. table.concat(lines, "\n") .. "\n") end
  if warns > 0 then
    local w = {}
    for _, l in ipairs(lines) do if l:find("^WARN") then w[#w + 1] = l end end
    trigger.action.outText(head .. "\n" .. table.concat(w, "\n"), AC().selfCheckShowSeconds)
  end
  B.lastSelfCheck = { lines = lines, warns = warns }
  return warns
end

-- ===========================================================================
-- Where can I spawn?
-- ===========================================================================
-- A base holds dozens of types: say how many, then the ones that are out or running low.
local function short(list)
  local max = AC().spawnListTypes
  table.sort(list)
  local out = {}
  for i = 1, math.min(#list, max) do out[i] = list[i] end
  if #list > max then out[#out + 1] = string.format("+%d more", #list - max) end
  return table.concat(out, ", ")
end

local function listTypes(counts)
  local have, total, out, low = 0, 0, {}, {}
  for t, n in pairs(counts) do
    if n > 0 then
      have, total = have + 1, total + n
      if n <= AC().spawnLowStock then low[#low + 1] = string.format("%s %d", t, n) end
    else out[#out + 1] = t end
  end
  local txt = string.format("%d types, %d aircraft", have, total)
  if #low > 0 then txt = txt .. "; low: " .. short(low) end
  if #out > 0 then txt = txt .. "; OUT: " .. short(out) end
  return txt, have
end

function B.spawnLines(side, helosOnly)
  local war = B.war
  local hq = war.mainBase and war:mainBase(side)
  local rows = {}
  if not helosOnly then
    for _, id in ipairs(war.T.order) do
      local ns = war.state.nodes[id]
      if ns.side == side and B.airbases[id] and ns.air then
        local counts, total = {}, 0
        for t, n in pairs(ns.air) do counts[t] = n; total = total + n end
        if war.runwayClosed and war:runwayClosed(id) then      -- cratered runway: helicopters only
          local heli = {}
          for _, t in ipairs(B.catalog.aircraft[side].helicopters or {}) do heli[t] = true end
          for t in pairs(counts) do if not heli[t] then counts[t] = 0 end end
        end
        local txt, k = listTypes(counts)
        if k > 0 then
          rows[#rows + 1] = { hq = id == hq, total = total, text = string.format("%s%s: %s",
            war:nodeName(id), id == hq and " (HQ)" or "", txt) }
        end
      end
    end
  end
  local helos = B.catalog.aircraft[side].helicopters or {}
  local pads = DCC.config.world.farpPads or 1
  for _, id in ipairs(war.T.order) do
    local ns = war.state.nodes[id]
    if war:canHaveFarp(id) and ns.side == side and war:farpAt(id) and not war:farpDry(id) and #helos > 0 then
      rows[#rows + 1] = { total = 0, text = string.format("FARP %s: %d pads, %d of each: %s", war:nodeName(id), pads,
        DCC.config.world.farpHelos, table.concat(helos, ", ")) }
    end
  end
  table.sort(rows, function(a, b)
    if a.hq ~= b.hq then return a.hq == true end
    if a.total ~= b.total then return a.total > b.total end
    return a.text < b.text
  end)
  local out = {}
  for i = 1, math.min(#rows, AC().spawnListRows) do out[i] = rows[i].text end
  if #rows > AC().spawnListRows then out[#out + 1] = string.format("... and %d more", #rows - AC().spawnListRows) end
  return out
end

function B.showSpawns(args)
  local lines = B.spawnLines(args.side, args.helos)
  local head = args.helos and "WHERE CAN I SPAWN A HELICOPTER? (open FARPs)" or "WHERE CAN I SPAWN? (aircraft in stock)"
  if #lines == 0 then lines = { "Nothing in stock right now." } end
  trigger.action.outTextForCoalition(B.COAL[args.side], head .. "\n" .. table.concat(lines, "\n"), 40)
end

local baseAddMenus = B.addMenus
function B.addMenus()
  baseAddMenus()
  for side, c in pairs(B.COAL) do
    local root = B.campaignRoot and B.campaignRoot[side]
    missionCommands.addCommandForCoalition(c, "Where can I spawn?", root, B.showSpawns, { side = side })
    missionCommands.addCommandForCoalition(c, "Where can I spawn a helicopter?", root, B.showSpawns,
      { side = side, helos = true })
  end
end

-- ===========================================================================
-- Admin commands (called by the server hook)
-- ===========================================================================
local HELP = {
  "-dcc status            war, map, players",
  "-dcc check             run the self-check again",
  "-dcc save              save the war now",
  "-dcc restock           refill aircraft, FARPs and weapon shelves now",
  "-dcc restart           save and reload the mission",
  "-dcc freshwar yes      archive this war and start a new one on this map",
}

local CMD = {}

function CMD.help() return "DCC admin commands:\n" .. table.concat(HELP, "\n") end

function CMD.status()
  local war = DCC.warObj
  local s = war:summary()
  local players = 0
  for _ in pairs(B.players or {}) do players = players + 1 end
  return string.format("DCC %s on %s - war day %.1f (tick %d). BLUE %d nodes, RED %d nodes. %d player(s) in aircraft.%s",
    DCC.config.version, DCC.theaterName, war.state.tick * DCC.config.tickSeconds / 86400, war.state.tick,
    s.blue.nodes, s.red.nodes, players, war.noSave and " NOT SAVING." or "")
end

function CMD.check()
  local warns = B.runSelfCheck()
  local l = B.lastSelfCheck.lines
  return string.format("Self-check: %d warning(s)\n%s", warns, table.concat(l, "\n"))
end

function CMD.save()
  DCC.save()
  return "War saved."
end

function CMD.restock()
  ok(B.writeWarehouses)
  if B.reconcileFarps then ok(B.reconcileFarps) end
  if B.restockArmoury then ok(B.restockArmoury) end
  return "Aircraft, FARPs and weapon shelves restocked."
end

function CMD.restart()
  DCC.save()
  return "War saved. Reloading the mission in " .. AC().reloadDelay .. " s.\nRELOAD"
end

function CMD.freshwar(args)
  if args[1] ~= "yes" then
    return "This throws the running war away (it is archived) and starts a new one.\nType: -dcc freshwar yes"
  end
  local war = DCC.warObj
  war.state.winner = "reset"            -- the next start archives it and begins a new war
  DCC.save()
  war.noSave = true                     -- nothing may overwrite it before the reload
  DCC.resetPending = true               -- no more ticks (no victory, no map rotation)
  trigger.action.outText("DCC: the admin has reset the war. A new war starts when the mission reloads.", 30)
  return "War archived. Reloading the mission in " .. AC().reloadDelay .. " s - a new war starts.\nRELOAD"
end

-- line: the chat text after "-dcc"; who: the player's name (for the log)
function DCC.admin(line, who)
  if not DCC.started or not DCC.warObj then return "DCC is not running on this mission." end
  local words = {}
  for w in tostring(line or ""):gmatch("%S+") do words[#words + 1] = w:lower() end
  local cmd = table.remove(words, 1) or "help"
  local fn = CMD[cmd]
  if not fn then return "Unknown command '" .. cmd .. "'. " .. CMD.help() end
  U.log("admin: %s ran '%s'", tostring(who), tostring(line))
  local s, r = pcall(fn, words)
  if not s then U.log("ERROR admin %s: %s", cmd, tostring(r)); return "Error: " .. tostring(r) end
  return r
end
