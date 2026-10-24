-- ============================================================================
-- Warehouse armoury (the test mission's mode): weapon names from DCS, tested
-- once, shelves stocked by base supply and paid for, F10 > Armoury test.
--   python tools/run_lua.py tests/test_armoury.lua
-- ============================================================================

local passed, failed = 0, 0
local function check(name, cond, detail)
  if cond then passed = passed + 1; print("  ok   " .. name)
  else failed = failed + 1; print("  FAIL " .. name .. (detail and (" - " .. tostring(detail)) or "")) end
end

dofile(DCC_ROOT .. "/tests/dcs_mock.lua")
MOCK.writedir = (arg[1] or "/tmp") .. "/dcc_arm_" .. tostring(os.time()) .. "/"
os.execute('mkdir -p "' .. MOCK.writedir .. '"')
local T = DCC_THEATERS.Caucasus
MOCK.buildAirbases(T)
MOCK.addTemplates()

-- What this fake DCS knows: a resource map, and warehouses that refuse unknown names.
local KNOWN = {
  "weapons.missiles.AIM_120C", "weapons.missiles.AIM_9X", "weapons.missiles.AGM_88C", "weapons.missiles.AGM_65D",
  "weapons.missiles.AGM_114K", "weapons.missiles.R_77", "weapons.missiles.R_73", "weapons.missiles.Vikhr_M",
  "weapons.bombs.GBU_12", "weapons.bombs.GBU_38", "weapons.bombs.Mk_82", "weapons.bombs.FAB_500",
  "weapons.nurs.HYDRA_70_M151", "weapons.nurs.S-8KOM", "weapons.droptanks.FuelTank_350L",
}
local known = {}
for _, n in ipairs(KNOWN) do known[n] = true end
Warehouse = { getResourceMap = function()
  local m = {}
  for _, n in ipairs(KNOWN) do m[n] = { wsType = { 4, 4, 7, 1 } } end
  m["weapons.missiles.NOT_IN_THIS_DCS"] = {}
  return m
end }
for _, ab in pairs(MOCK.airbases) do
  local wh = ab.wh
  wh.setItem = function(self, t, n) if known[t] or not t:find("^weapons%.") then self.items[t] = n end end
  wh.getInventory = function(self) return { weapon = {}, aircraft = self.items } end
end
known["weapons.missiles.NOT_IN_THIS_DCS"] = nil

DCC_ARMOURY_MODE = "warehouse"
DCC_TEST_MISSION = true
for _, f in ipairs({ "dcc_persist", "dcc_dcs", "dcc_dcs_supply", "dcc_dcs_ops", "dcc_dcs_intel", "dcc_dcs_radar",
                     "dcc_dcs_world", "dcc_dcs_jtac", "dcc_dcs_public", "dcc_dcs_air", "dcc_dcs_ground",
                     "dcc_dcs_ctld", "dcc_dcs_ext_air", "dcc_dcs_ext_ground", "dcc_dcs_ext2", "dcc_dcs_ext3", "dcc_dcs_ext4", "dcc_dcs_armoury", "dcc_main" }) do
  dofile(DCC_ROOT .. "/src/" .. f .. ".lua")
end
local errors = 0
DCC.util.log = function(fmt, ...)
  local msg = string.format(fmt, ...)
  if msg:find("ERROR") then errors = errors + 1; print("    " .. msg) end
end

print("Test mission set-up")
check("warehouse mode", DCC.config.ext.armoury.mode == "warehouse")
check("own save folder, no rotation", DCC.config.saveFolder == "DCC_test" and DCC.config.rotationEnforce == false)
DCC.start()
local B, war = DCC.dcs, DCC.warObj

print("Weapon names")
check("names come from DCS (getResourceMap)", B.arm.source == "getResourceMap")
check("names DCS refuses are dropped", B.arm.tier["weapons.missiles.NOT_IN_THIS_DCS"] == nil and #B.arm.rejected > 0)
check("the catalogue's guesses are tried too, and dropped when wrong", B.arm.tested > #KNOWN + 1)
check("all 15 real names accepted", B.arm.accepted == #KNOWN, B.arm.accepted)
check("AIM-120 is advanced", B.weaponTier("weapons.missiles.AIM_120C") == "advanced")
check("AIM-9X is guided", B.weaponTier("weapons.missiles.AIM_9X") == "guided")
check("HARM is advanced", B.weaponTier("weapons.missiles.AGM_88C") == "advanced")
check("GBU-12 is guided, GBU-38 (GPS) advanced", B.weaponTier("weapons.bombs.GBU_12") == "guided"
  and B.weaponTier("weapons.bombs.GBU_38") == "advanced")
check("Mk-82, rockets and tanks are basic", B.weaponTier("weapons.bombs.Mk_82") == "basic"
  and B.weaponTier("weapons.nurs.HYDRA_70_M151") == "basic" and B.weaponTier("weapons.droptanks.FuelTank_350L") == "basic")
check("launcher adapters are basic (always on the shelf)", B.weaponTier("weapons.adapters.9M114-PILON") == "basic"
  and B.weaponTier("weapons.adapters.CHAP_HOT3LN") == "basic")
check("a dumb cluster bomb named like a missile stays basic", B.weaponTier("weapons.bombs.AB_250_2_SD_10A") == "basic")
check("pods and tanks are basic", B.weaponTier("weapons.containers.AN_AAQ_28_LITENING") == "basic")
check("APKWS rockets are guided", B.weaponTier("weapons.nurs.AGR_20A") == "guided")
check("R-77 advanced, R-73 and Vikhr guided", B.weaponTier("weapons.missiles.R_77") == "advanced"
  and B.weaponTier("weapons.missiles.R_73") == "guided" and B.weaponTier("weapons.missiles.Vikhr_M") == "guided")

print("Shelves follow supply")
local wh = MOCK.airbases[B.airbases.kutaisi].wh
local ns = war.state.nodes.kutaisi
local cap = war:supplyCap("kutaisi")
local stock = DCC.config.ext.armoury.stock
local big = war.T.nodes.kutaisi.depot and 2 or 1
ns.supply = cap * 0.1
B.restockArmoury()
check("dry base: Mk-82 on the shelf", wh.items["weapons.bombs.Mk_82"] == stock.basic * big)
check("...no GBU-12, no AMRAAM", (wh.items["weapons.bombs.GBU_12"] or 0) == 0 and (wh.items["weapons.missiles.AIM_120C"] or 0) == 0)
ns.supply = cap * 0.3
local s0 = ns.supply
B.restockArmoury()
check("some supply: GBU-12 and AIM-9X arrive", wh.items["weapons.bombs.GBU_12"] == stock.guided * big
  and wh.items["weapons.missiles.AIM_9X"] == stock.guided * big)
check("...stocking the shelf is free", ns.supply == s0)
wh.items["weapons.bombs.GBU_12"] = wh.items["weapons.bombs.GBU_12"] - 4      -- an A-10 took 4
B.restockArmoury()
check("4 GBU-12 taken: paid at the next top-up", math.abs(ns.supply - (s0 - 4 * DCC.config.ext.armoury.guidedSU)) < 0.01, ns.supply)
check("...still no AMRAAM", (wh.items["weapons.missiles.AIM_120C"] or 0) == 0)
ns.supply = cap * 0.9
B.restockArmoury()
check("well supplied: AMRAAMs on the shelf", wh.items["weapons.missiles.AIM_120C"] == stock.advanced * big)
wh.items["weapons.missiles.AIM_120C"] = 3                -- pilots took some
local s1 = ns.supply
B.restockArmoury()
check("restocked to the level, taken missiles paid", wh.items["weapons.missiles.AIM_120C"] == stock.advanced * big
  and math.abs((s1 - ns.supply) - (stock.advanced * big - 3) * DCC.config.ext.armoury.advancedSU) < 0.01)
ns.supply = cap * 0.1
B.restockArmoury()
check("supply runs down: advanced and guided come off the shelf", wh.items["weapons.missiles.AIM_120C"] == 0
  and wh.items["weapons.bombs.GBU_12"] == 0)

print("No recall in warehouse mode")
local viper = MOCK.spawnPlayer(2, "F-16C_50", MOCK.airbases[B.airbases.kutaisi].p.x, MOCK.airbases[B.airbases.kutaisi].p.z, "Morten")
viper.getAmmo = function() return { { count = 2, desc = { category = 1, guidance = 3 } } } end
MOCK.fire({ id = world.event.S_EVENT_TAKEOFF, initiator = viper })
MOCK.advance(3)
check("an aircraft that took off is never removed", viper.alive ~= false)

print("F10 > Armoury test")
local items = {}
for _, it in ipairs(MOCK.menus) do items[it.name] = it end
check("the test menu is there", items["Report: what DCS gave us"] ~= nil and items["All bases 90 % supply (advanced)"] ~= nil)
local n0 = #MOCK.texts
items["Report: what DCS gave us"].fn(items["Report: what DCS gave us"].arg)
local rep = MOCK.texts[#MOCK.texts]
check("report: source, accepted names, tiers", rep:find("getResourceMap", 1, true) and rep:find("accepted 15", 1, true)
  and rep:find("advanced", 1, true), rep)
items["List the names (next page)"].fn()
check("the names can be listed", MOCK.texts[#MOCK.texts]:find("AIM_120C", 1, true) ~= nil)
items["Stock at my side's bases"].fn(items["Stock at my side's bases"].arg)
check("stock per base", MOCK.texts[#MOCK.texts]:find("types on the shelf", 1, true) ~= nil)
local it = items["All bases 90 % supply (advanced)"]
it.fn(it.arg)
check("test button: all bases to 90 %, tier advanced", MOCK.texts[#MOCK.texts]:find("advanced", 1, true) ~= nil)
local other
for _, id in ipairs(war.T.order) do
  if war.state.nodes[id].side == it.arg.side and B.airbases[id] and not war.T.nodes[id].depot then other = id; break end
end
local owh = MOCK.airbases[B.airbases[other]].wh
check("...a plain airbase too, not only the depot: HARMs on its shelf", (owh.items["weapons.missiles.AGM_88C"] or 0) > 0, other)

print("Without getResourceMap: inventory, then the catalogue")
Warehouse = nil
local list = B.discoverWeapons()
check("falls back to the catalogue's list", B.arm.source ~= "none" and #list >= 100, #list)

print("A day")
for _ = 1, 288 do MOCK.advance(300) end
check("no script errors", errors == 0, errors)

print(string.format("\n%d passed, %d failed", passed, failed))
DCC_EXIT_CODE = failed == 0 and 0 or 1
