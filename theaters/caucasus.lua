-- ============================================================================
-- Danica Dynamic Campaign - theater pack: Caucasus
-- ----------------------------------------------------------------------------
-- A theater pack is pure data. The engine never names a place in code; every
-- map gets one of these files instead.
--
--   nodes  : places that can be owned (airbases, towns, depots)
--   edges  : road links between nodes (assaults and reinforcements move on them)
--
-- Positions are real-world latitude/longitude. In DCS the engine converts them
-- with coord.LLtoLO(), so the same file format works on every map.
-- If a node has `airbase`, the engine snaps it to that DCS airbase and keeps the
-- airbase coalition in sync with the node owner.
--
-- Scenario (Modern): BLUE holds Georgia, RED holds the north and Abkhazia /
-- South Ossetia. The opening front runs Zugdidi-Gali, Gori-Tskhinvali and
-- the Military Georgian Road.
-- BLUE's depots are Batumi and Kutaisi (with Tbilisi as a depot BLUE gained
-- ground in 11 of 12 empty-server test wars; with Kutaisi it is 5 of 12).
-- ============================================================================

DCC_THEATERS = DCC_THEATERS or {}

DCC_THEATERS.Caucasus = {
  name    = "Caucasus",
  era     = "modern",
  -- Country used for spawned units. CJTF countries accept any unit type.
  country = { blue = "CJTF_BLUE", red = "CJTF_RED" },
  balance = { blue = 1.0, red = 1.0 },

  nodes = {
    -- ---------------- BLUE (Georgia) ----------------
    { id = "batumi",     name = "Batumi",          kind = "airbase", side = "blue", lat = 41.6103, lon = 41.5997, airbase = "Batumi", depot = true },
    { id = "kobuleti",   name = "Kobuleti",        kind = "airbase", side = "blue", lat = 41.9300, lon = 41.8639, airbase = "Kobuleti" },
    { id = "poti",       name = "Poti",            kind = "town",    side = "blue", lat = 42.1460, lon = 41.6720 },
    { id = "senaki",     name = "Senaki-Kolkhi",   kind = "airbase", side = "blue", lat = 42.2410, lon = 42.0480, airbase = "Senaki-Kolkhi" },
    { id = "zugdidi",    name = "Zugdidi",         kind = "town",    side = "blue", lat = 42.5088, lon = 41.8709 },
    { id = "kutaisi",    name = "Kutaisi",         kind = "airbase", side = "blue", lat = 42.1767, lon = 42.4826, airbase = "Kutaisi", depot = true },
    { id = "zestaponi",  name = "Zestaponi",       kind = "town",    side = "blue", lat = 42.1100, lon = 43.0520 },
    { id = "ambrolauri", name = "Ambrolauri",      kind = "town",    side = "blue", lat = 42.5210, lon = 43.1500 },
    { id = "khashuri",   name = "Khashuri",        kind = "town",    side = "blue", lat = 41.9930, lon = 43.6000 },
    { id = "gori",       name = "Gori",            kind = "town",    side = "blue", lat = 41.9840, lon = 44.1100 },
    { id = "pasanauri",  name = "Pasanauri",       kind = "town",    side = "blue", lat = 42.3500, lon = 44.6900 },
    { id = "tbilisi",    name = "Tbilisi-Lochini", kind = "airbase", side = "blue", lat = 41.6692, lon = 44.9547, airbase = "Tbilisi-Lochini" },
    { id = "soganlug",   name = "Soganlug",        kind = "airbase", side = "blue", lat = 41.6460, lon = 44.9370, airbase = "Soganlug" },
    { id = "vaziani",    name = "Vaziani",         kind = "airbase", side = "blue", lat = 41.6290, lon = 45.0270, airbase = "Vaziani" },

    -- ---------------- RED (north, Abkhazia, South Ossetia) ----------------
    { id = "gali",       name = "Gali",            kind = "town",    side = "red",  lat = 42.6260, lon = 41.7340 },
    { id = "ochamchire", name = "Ochamchire",      kind = "town",    side = "red",  lat = 42.7120, lon = 41.4680 },
    { id = "sukhumi",    name = "Sukhumi-Babushara", kind = "airbase", side = "red", lat = 42.8582, lon = 41.1281, airbase = "Sukhumi-Babushara" },
    { id = "gudauta",    name = "Gudauta",         kind = "airbase", side = "red",  lat = 43.1040, lon = 40.5790, airbase = "Gudauta" },
    { id = "sochi",      name = "Sochi-Adler",     kind = "airbase", side = "red",  lat = 43.4499, lon = 39.9566, airbase = "Sochi-Adler", depot = true },
    { id = "tuapse",     name = "Tuapse",          kind = "town",    side = "red",  lat = 44.0960, lon = 39.0740 },
    { id = "oni",        name = "Oni",             kind = "town",    side = "red",  lat = 42.5790, lon = 43.4420 },
    { id = "tskhinvali", name = "Tskhinvali",      kind = "town",    side = "red",  lat = 42.2270, lon = 43.9690 },
    { id = "kazbegi",    name = "Kazbegi",         kind = "town",    side = "red",  lat = 42.6570, lon = 44.6440 },
    { id = "alagir",     name = "Alagir",          kind = "town",    side = "red",  lat = 43.0410, lon = 44.2200 },
    { id = "vladikavkaz",name = "Vladikavkaz",     kind = "town",    side = "red",  lat = 43.0370, lon = 44.6680 },
    { id = "beslan",     name = "Beslan",          kind = "airbase", side = "red",  lat = 43.2051, lon = 44.6066, airbase = "Beslan", depot = true },
    { id = "mozdok",     name = "Mozdok",          kind = "airbase", side = "red",  lat = 43.7880, lon = 44.6190, airbase = "Mozdok" },
    { id = "nalchik",    name = "Nalchik",         kind = "airbase", side = "red",  lat = 43.5129, lon = 43.6366, airbase = "Nalchik" },
    { id = "pyatigorsk", name = "Pyatigorsk",      kind = "town",    side = "red",  lat = 44.0480, lon = 43.0590 },
    { id = "minvody",    name = "Mineralnye Vody", kind = "airbase", side = "red",  lat = 44.2251, lon = 43.0819, airbase = "Mineralnye Vody" },
    { id = "cherkessk",  name = "Cherkessk",       kind = "town",    side = "red",  lat = 44.2230, lon = 42.0580 },
    { id = "armavir",    name = "Armavir",         kind = "town",    side = "red",  lat = 44.9990, lon = 41.1290 },
    { id = "maykop",     name = "Maykop-Khanskaya",kind = "airbase", side = "red",  lat = 44.6710, lon = 40.0210, airbase = "Maykop-Khanskaya" },
    { id = "krasnodar_p",name = "Krasnodar-Pashkovsky", kind = "airbase", side = "red", lat = 45.0347, lon = 39.1705, airbase = "Krasnodar-Pashkovsky" },
    { id = "krasnodar_c",name = "Krasnodar-Center",kind = "airbase", side = "red",  lat = 45.0850, lon = 38.9250, airbase = "Krasnodar-Center", depot = true },
    { id = "krymsk",     name = "Krymsk",          kind = "airbase", side = "red",  lat = 44.9610, lon = 37.9850, airbase = "Krymsk" },
    { id = "anapa",      name = "Anapa-Vityazevo", kind = "airbase", side = "red",  lat = 45.0021, lon = 37.3473, airbase = "Anapa-Vityazevo" },
    { id = "novorossiysk",name = "Novorossiysk",   kind = "airbase", side = "red",  lat = 44.6660, lon = 37.7860, airbase = "Novorossiysk" },
    { id = "gelendzhik", name = "Gelendzhik",      kind = "airbase", side = "red",  lat = 44.5670, lon = 38.0040, airbase = "Gelendzhik" },
  },

  -- Road links (undirected). Keep them on real roads: DCS ground AI drives
  -- "On Road" between the two ends, so a link with no road gets units stuck.
  edges = {
    -- Georgian coast and west
    { "batumi", "kobuleti" }, { "kobuleti", "poti" }, { "poti", "senaki" },
    { "senaki", "zugdidi" }, { "senaki", "kutaisi" },
    -- Georgian interior
    { "kutaisi", "zestaponi" }, { "zestaponi", "khashuri" }, { "khashuri", "gori" },
    { "gori", "tbilisi" }, { "tbilisi", "soganlug" }, { "tbilisi", "vaziani" },
    { "kutaisi", "ambrolauri" }, { "tbilisi", "pasanauri" },
    -- Opening front lines
    { "zugdidi", "gali" }, { "ambrolauri", "oni" }, { "gori", "tskhinvali" },
    { "pasanauri", "kazbegi" },
    -- Abkhazia and Black Sea coast
    { "gali", "ochamchire" }, { "ochamchire", "sukhumi" }, { "sukhumi", "gudauta" },
    { "gudauta", "sochi" }, { "sochi", "tuapse" },
    { "tuapse", "maykop" }, { "tuapse", "gelendzhik" },
    -- Kuban
    { "gelendzhik", "novorossiysk" }, { "novorossiysk", "krymsk" }, { "novorossiysk", "anapa" },
    { "krymsk", "anapa" }, { "krymsk", "krasnodar_c" }, { "krasnodar_c", "krasnodar_p" },
    { "krasnodar_p", "maykop" }, { "krasnodar_p", "armavir" }, { "maykop", "armavir" },
    -- North Caucasus
    { "armavir", "cherkessk" }, { "cherkessk", "minvody" }, { "minvody", "pyatigorsk" },
    { "pyatigorsk", "nalchik" }, { "minvody", "mozdok" }, { "nalchik", "beslan" },
    { "beslan", "vladikavkaz" }, { "beslan", "mozdok" }, { "vladikavkaz", "alagir" },
    { "vladikavkaz", "kazbegi" }, { "alagir", "tskhinvali" }, { "oni", "alagir" },
  },

  -- Naval groups: placed by tools/make_mission.py (client slots on carriers). Each
  -- sails 80 km on its heading and turns around; sunk = its air wing is gone.
  --   tacan / icls: beacon channels (false = none). The tankers use 51X/52X.
  naval = {
    { id = "cvn", side = "blue", name = "CVN-74 John C. Stennis", kind = "carrier", lat = 42.0000, lon = 40.8500,
      heading = 300, ship = "Stennis", escorts = { "USS_Arleigh_Burke_IIa", "USS_Arleigh_Burke_IIa", "TICONDEROG" },
      tacan = 74, tacanCall = "STN", icls = 4,
      slots = { "FA-18C_hornet", "FA-18C_hornet", "F-14B", "F-14B", "F-14BU", "F-14A-135-GR" } },
    { id = "lha", side = "blue", name = "LHA-1 Tarawa", kind = "carrier", lat = 41.7500, lon = 41.2500,
      heading = 300, ship = "LHA_Tarawa", escorts = { "PERRY" },
      tacan = 75, tacanCall = "TAR", icls = 5,
      slots = { "AV8BNA", "AV8BNA", "UH-1H", "AH-64D_BLK_II", "SA342M" } },
    { id = "kuz", side = "red", name = "Admiral Kuznetsov", kind = "carrier", lat = 44.2000, lon = 37.6000,
      heading = 250, ship = "KUZNECOW", escorts = { "MOSCOW", "REZKY", "NEUSTRASH" },
      tacan = false, icls = false,
      slots = { "Su-33", "Su-33", "Su-33", "Su-33", "Ka-50_3" } },
  },
}
