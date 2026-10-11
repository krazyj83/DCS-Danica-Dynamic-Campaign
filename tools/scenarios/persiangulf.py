"""Persian Gulf scenario (modern). Read by tools/make_theater.py (format: see syria.py)."""

SCENARIO = {
    "theater": "PersianGulf",
    "description": """
Scenario (Modern): RED (Iran) has landed on the Musandam peninsula and the
northern Emirates and holds the Gulf islands. BLUE holds the rest of the UAE.
The ground fronts are Umm Al Quwain - Ras Al Khaimah and Al Dhaid / Hatta -
Masafi / Fujairah. Everything else is linked by sea crossings (ferries and
landing craft): those moves run on dice only - fight them at the ports and
islands, and in the air.
""",
    "maxEdgeKm": 200,
    # RED's depot is on the Musandam peninsula (Khasab): with it at Ras Al Khaimah RED won
    # every test war, without one on the beachhead BLUE held 65 %. Khasab gives ~46 % BLUE.
    "airbases": [
        # ---------------- BLUE: UAE ----------------
        ("Al Dhafra AFB", "blue", {"depot": True, "group": "arabia"}),
        ("Al Minhad AFB", "blue", {"depot": True, "group": "arabia"}),
        ("Abu Dhabi Intl", "blue", {"group": "arabia"}),
        ("Al-Bateen", "blue", {"group": "arabia"}),
        ("Sas Al Nakheel", "blue", {"group": "arabia"}),
        ("Liwa AFB", "blue", {"group": "arabia"}),
        ("Al Ain Intl", "blue", {"group": "arabia"}),
        ("Al Maktoum Intl", "blue", {"group": "arabia"}),
        ("Dubai Intl", "blue", {"group": "arabia"}),
        ("Sharjah Intl", "blue", {"group": "arabia"}),
        ("Sir Abu Nuayr", "blue", {"group": "sirabunuayr"}),
        # ---------------- RED: beachhead in the Emirates ----------------
        ("Ras Al Khaimah Intl", "red", {"group": "arabia"}),
        ("Khasab", "red", {"depot": True, "group": "arabia"}),
        ("Fujairah Intl", "red", {"group": "arabia"}),
        # ---------------- RED: islands ----------------
        ("Abu Musa Island", "red", {"group": "abumusa"}),
        ("Tunb Island AFB", "red", {"group": "tunb", "name": "Greater Tunb"}),
        ("Sirri Island", "red", {"group": "sirri"}),
        ("Qeshm Island", "red", {"group": "qeshm"}),
        ("Kish Intl", "red", {"group": "kish"}),
        # ---------------- RED: Iran ----------------
        ("Bandar Abbas Intl", "red", {"depot": True, "group": "iran"}),
        ("Havadarya", "red", {"group": "iran"}),
        ("Bandar Lengeh", "red", {"group": "iran"}),
        ("Lar", "red", {"depot": True, "group": "iran"}),
        ("Jiroft", "red", {"group": "iran"}),
        ("Bandar-e-Jask", "red", {"group": "iran"}),
    ],
    "towns": [
        ("Umm Al Quwain", "blue", 25.5650, 55.5550, {"group": "arabia"}),
        ("Al Dhaid", "blue", 25.2880, 55.8810, {"group": "arabia"}),
        ("Hatta", "blue", 24.8000, 56.1200, {"group": "arabia"}),
        ("Masafi", "red", 25.3160, 56.1660, {"group": "arabia"}),
        ("Dibba", "red", 25.6200, 56.2700, {"group": "arabia"}),
        ("Minab", "red", 27.1460, 57.0800, {"group": "iran"}),
        ("Bandar Khamir", "red", 26.9520, 55.5850, {"group": "iran"}),
    ],
    "noEdges": [],
    "extraEdges": [],
    "seaEdges": [
        ("khasab", "bandar_abbas_intl"),     # Strait of Hormuz: RED's lifeline to the beachhead
        ("khasab", "qeshm_island"),
        ("qeshm_island", "havadarya"),
        ("abu_musa_island", "sharjah_intl"),
        ("abu_musa_island", "tunb_island_afb"),
        ("abu_musa_island", "sirri_island"),
        ("tunb_island_afb", "bandar_lengeh"),
        ("sirri_island", "kish_intl"),
        ("kish_intl", "bandar_lengeh"),
        ("sir_abu_nuayr", "sharjah_intl"),
        ("sir_abu_nuayr", "sirri_island"),
    ],
}
