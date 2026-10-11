-- ============================================================================
-- Danica Dynamic Campaign - development loader
-- ----------------------------------------------------------------------------
-- Use this during development: the mission's single MISSION START trigger runs
-- DO SCRIPT FILE on this file, and it loads the real scripts from
--     Saved Games\DCS\Scripts\DCC\
-- so you can edit them and restart the mission without re-saving the .miz.
-- Needs `lfs` (enabled in MissionScripting.lua, as persistence already needs).
--
-- For a server release, use dist/dcc_bundle.lua instead (one file, embedded
-- in the mission by DO SCRIPT FILE). Build it with tools/build_bundle.py.
-- ============================================================================

local base = lfs.writedir() .. [[Scripts\DCC\]]

local files = {
  [[src\dcc_config.lua]],
  [[src\dcc_util.lua]],
  [[src\dcc_json.lua]],
  [[src\dcc_war.lua]],
  [[src\dcc_supply.lua]],
  [[src\dcc_front.lua]],
  [[src\dcc_persist.lua]],
  [[src\dcc_dcs.lua]],
  [[src\dcc_dcs_supply.lua]],
  [[src\dcc_main.lua]],
  [[catalogs\modern.lua]],
  [[theaters\caucasus.lua]],
}

for _, f in ipairs(files) do
  local ok, err = pcall(dofile, base .. f)
  if not ok then
    env.error("DCC loader: failed to load " .. f .. ": " .. tostring(err))
    trigger.action.outText("DCC loader: failed to load " .. f .. " - see dcs.log", 60)
    return
  end
end

DCC.start()
