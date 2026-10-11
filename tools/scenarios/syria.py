"""Syria scenario (modern). Read by tools/make_theater.py.

Format:
  airbases : (DCS airbase name, side, {depot, ewr, id, name, group})
  towns    : (name, side, lat, lon, {depot, ewr, id, group})
  maxEdgeKm: longest generated road link
  noEdges / extraEdges / seaEdges: corrections to the generated road network
"""

SCENARIO = {
    "theater": "Syria",
    "description": """
Scenario (Modern): a BLUE coalition holds Israel, Jordan and southern Lebanon;
RED holds Syria and the Bekaa / northern Lebanon. The opening fronts are the
Golan Heights, the Daraa - Irbid corridor and the Beirut - Bekaa road.
Turkey and Cyprus stay out of the war.
""",
    "maxEdgeKm": 130,
    # Measured offline (16 wars of 7 days, nobody online): RED x1.15 -> BLUE wins 9 of 16 on the clock.
    "balance": {"blue": 1.0, "red": 1.15},
    "airbases": [
        # ---------------- BLUE: Israel ----------------
        ("Ramat David", "blue", {"depot": True}),
        ("Haifa", "blue"),
        ("Megiddo", "blue"),
        ("Eyn Shemer", "blue"),
        ("Rosh Pina", "blue"),
        ("Kiryat Shmona", "blue"),
        # ---------------- BLUE: Jordan ----------------
        ("Marka", "blue", {"depot": True, "name": "Amman-Marka"}),
        ("King Hussein Air College", "blue"),
        ("King Abdullah II", "blue"),
        ("Prince Hassan", "blue"),
        ("Muwaffaq Salti", "blue"),
        ("H4", "blue"),
        # ---------------- BLUE: Lebanon ----------------
        ("Beirut-Rafic Hariri", "blue", {"name": "Beirut"}),
        # ---------------- RED: southern Syria ----------------
        ("Damascus", "red", {"depot": True}),
        ("Mezzeh", "red"),
        ("Marj Ruhayyil", "red"),
        ("Khalkhalah", "red"),
        ("Tha'lah", "red", {"id": "thalah"}),
        ("Al-Dumayr", "red"),
        ("Sayqal", "red"),
        ("Qabr as Sitt", "red"),
        # ---------------- RED: Bekaa and north Lebanon ----------------
        ("Rayak", "red"),
        ("Wujah Al Hajar", "red"),
        ("Rene Mouawad", "red", {"name": "Qlayaat"}),
        # ---------------- RED: central Syria ----------------
        ("Al Qusayr", "red"),
        ("An Nasiriyah", "red"),
        ("Shayrat", "red", {"ewr": True}),
        ("Tiyas", "red"),
        ("Palmyra", "red"),
        ("Hama", "red"),
        # ---------------- RED: coast and north ----------------
        ("Bassel Al-Assad", "red", {"depot": True, "name": "Latakia (Bassel Al-Assad)"}),
        ("Abu al-Duhur", "red"),
        ("Taftanaz", "red"),
        ("Aleppo", "red", {"depot": True}),
        ("Kuweires", "red"),
        ("Jirah", "red"),
        ("Tabqa", "red"),
    ],
    "towns": [
        ("Tyre", "blue", 33.2700, 35.2040),
        ("Sidon", "blue", 33.5630, 35.3690),
        ("Irbid", "blue", 32.5560, 35.8500),
        ("Quneitra", "red", 33.1260, 35.8240),
        ("Daraa", "red", 32.6250, 36.1060),
        ("Zahle", "red", 33.8460, 35.9020),
        ("Homs", "red", 34.7300, 36.7090),
        ("Tartus", "red", 34.8890, 35.8870),
    ],
    "noEdges": [],
    "extraEdges": [
        ("beirut_rafic_hariri", "zahle"),     # Beirut - Damascus highway over the mountains
    ],
}
