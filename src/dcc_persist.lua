-- ============================================================================
-- Danica Dynamic Campaign - persistence (save / load the war as JSON)
-- ----------------------------------------------------------------------------
-- All file access lives in this one module. DCS sandboxes mission scripts and
-- removes `io` and `lfs` unless the server owner re-enables them in
-- DCS World\Scripts\MissionScripting.lua. If they are missing the campaign
-- still runs, it just cannot remember anything between restarts.
--
-- Files (under Saved Games\DCS\DCC\):
--   <Theater>_war.json          the live save, written every tick
--   <Theater>_war_bak<N>.json   rotating backups (N = tick mod saveSlots)
--   <Theater>_war_final_<T>.json archive of a finished war
--   pilots.json                 pilot records (all maps)
--   rotation.json               which map the server is on / goes to next
-- ============================================================================

DCC = DCC or {}
local U = DCC.util
local P = {}
DCC.persist = P

local warned = false

function P.available()
  local ok = (io ~= nil and io.open ~= nil and lfs ~= nil and lfs.writedir ~= nil)
  if not ok and not warned then
    warned = true
    U.log("persistence OFF: io/lfs are sanitized in MissionScripting.lua - the war will not be saved")
  end
  return ok
end

local function folder()
  local dir = lfs.writedir() .. DCC.config.saveFolder .. "\\"
  pcall(lfs.mkdir, dir)
  return dir
end

local function writeFile(path, text)
  local f, err = io.open(path, "w")
  if not f then U.log("save failed (%s): %s", path, tostring(err)); return false end
  f:write(text)
  f:close()
  return true
end

local function readFile(path)
  local f = io.open(path, "r")
  if not f then return nil end
  local text = f:read("*a")
  f:close()
  return text
end

local function decodeSafe(text)
  if not text or text == "" then return nil end
  local ok, v = pcall(DCC.json.decode, text)
  if ok and type(v) == "table" and v.nodes then return v end
  return nil
end

-- Write the live save plus one rotating backup.
function P.save(theaterName, state)
  if not P.available() then return false end
  local ok, text = pcall(DCC.json.encode, state)
  if not ok then U.log("save encode failed: %s", tostring(text)); return false end
  local dir = folder()
  local main = dir .. theaterName .. "_war.json"
  local slot = (state.tick or 0) % DCC.config.saveSlots
  local done = writeFile(main, text)
  writeFile(dir .. theaterName .. "_war_bak" .. slot .. ".json", text)
  return done
end

-- Load the newest readable save. A corrupt main file falls back to the
-- backup with the highest tick, so a crash mid-write costs one tick at most.
function P.load(theaterName)
  if not P.available() then return nil end
  local dir = folder()
  local best = decodeSafe(readFile(dir .. theaterName .. "_war.json"))
  if best then return best end
  U.log("main save missing or unreadable, trying backups")
  for slot = 0, DCC.config.saveSlots - 1 do
    local s = decodeSafe(readFile(dir .. theaterName .. "_war_bak" .. slot .. ".json"))
    if s and (not best or (s.tick or 0) > (best.tick or 0)) then best = s end
  end
  return best
end

-- Keep a finished war for the record before a new one overwrites the save.
function P.archive(theaterName, state)
  if not P.available() then return end
  local ok, text = pcall(DCC.json.encode, state)
  if ok then
    writeFile(folder() .. theaterName .. "_war_final_" .. tostring(state.tick or 0) .. ".json", text)
  end
end

-- Pilot records live in one file for all theaters (they outlast a war).
function P.savePilots(data)
  if not P.available() then return false end
  local ok, text = pcall(DCC.json.encode, data)
  if not ok then return false end
  return writeFile(folder() .. DCC.config.pilotsFile, text)
end

function P.loadPilots()
  if not P.available() then return nil end
  local text = readFile(folder() .. DCC.config.pilotsFile)
  if not text or text == "" then return nil end
  local ok, v = pcall(DCC.json.decode, text)
  if ok and type(v) == "table" then return v end
  return nil
end

-- Map rotation (phase 5): one small file shared with the server hook
-- (hooks/DCC_rotation_hook.lua), which does the actual mission change.
--   { current = "<map the server should be on>", state = "running" | "ended" | "loading",
--     finished = "<map whose war just ended>", winner = "blue" | "red", next = "<map>" }
function P.readRotation()
  if not P.available() then return nil end
  local text = readFile(folder() .. "rotation.json")
  if not text or text == "" then return nil end
  local ok, v = pcall(DCC.json.decode, text)
  if ok and type(v) == "table" then return v end
  return nil
end

function P.writeRotation(rot)
  if not P.available() then return false end
  local ok, text = pcall(DCC.json.encode, rot)
  if not ok then return false end
  return writeFile(folder() .. "rotation.json", text)
end

-- The end-of-war report as plain text (for Discord, the forum, the record).
function P.writeReport(theaterName, tick, text)
  if not P.available() then return false end
  return writeFile(folder() .. theaterName .. "_war_report_" .. tostring(tick or 0) .. ".txt", text)
end

-- Plain files for the companion tool (web map, Discord): public.json (rewritten)
-- and feed.jsonl (one event per line, appended).
function P.writeFile(name, text)
  if not P.available() then return false end
  return writeFile(folder() .. name, text)
end

function P.appendFile(name, text)
  if not P.available() then return false end
  local f = io.open(folder() .. name, "a")
  if not f then return false end
  f:write(text)
  f:close()
  return true
end
