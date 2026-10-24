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
  [[src\dcc_ops.lua]],
  [[src\dcc_missions.lua]],
  [[src\dcc_pilots.lua]],
  [[src\dcc_intel.lua]],
  [[src\dcc_radar.lua]],
  [[src\dcc_world.lua]],
  [[src\dcc_air.lua]],
  [[src\dcc_ground.lua]],
  [[src\dcc_ext.lua]],
  [[src\dcc_ext2.lua]],
  [[src\dcc_ext3.lua]],
  [[src\dcc_ext4.lua]],
  [[src\dcc_front.lua]],
  [[src\dcc_territory.lua]],
  [[src\dcc_persist.lua]],
  [[src\dcc_dcs.lua]],
  [[src\dcc_dcs_supply.lua]],
  [[src\dcc_dcs_ops.lua]],
  [[src\dcc_dcs_intel.lua]],
  [[src\dcc_dcs_radar.lua]],
  [[src\dcc_dcs_world.lua]],
  [[src\dcc_dcs_jtac.lua]],
  [[src\dcc_dcs_public.lua]],
  [[src\dcc_dcs_air.lua]],
  [[src\dcc_dcs_ground.lua]],
  [[src\dcc_dcs_ctld.lua]],
  [[src\dcc_dcs_ext_air.lua]],
  [[src\dcc_dcs_ext_ground.lua]],
  [[src\dcc_dcs_ext2.lua]],
  [[src\dcc_dcs_ext3.lua]],
  [[src\dcc_dcs_ext4.lua]],
  [[src\dcc_dcs_armoury.lua]],
  [[src\dcc_main.lua]],
  [[catalogs\modern.lua]],
  [[theaters\caucasus.lua]],
  [[theaters\syria.lua]],
  [[theaters\persiangulf.lua]],
  [[theaters\germanycw.lua]],
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
