"""Cold War Germany map, modern scenario. Read by tools/make_theater.py (format: see syria.py)."""

SCENARIO = {
    "theater": "GermanyCW",
    "description": """
Scenario (Modern forces on the Cold War Germany map): BLUE holds the west,
RED the east, with the front on the old inner-German border from the Baltic
coast to the Fulda Gap. Berlin is not in play.
""",
    "maxEdgeKm": 120,
    # Measured offline: RED x1.15 -> BLUE wins 7 of 16 wars on the 7-day clock (even production: 1 of 8).
    "balance": {"blue": 1.0, "red": 1.10},
    "main": {"blue": "frankfurt", "red": "schonefeld"},
    "airbases": [
        # ---------------- BLUE: north ----------------
        ("Kiel", "blue"),
        ("Lubeck", "blue"),
        ("Hamburg", "blue"),
        ("Bremen", "blue"),
        ("Nordholz", "blue", {"ewr": True}),
        ("Luneburg", "blue"),
        ("Uelzen", "blue"),
        ("Fassberg", "blue"),
        ("Celle", "blue"),
        # ---------------- BLUE: centre ----------------
        ("Hannover", "blue", {"depot": True}),
        ("Wunstorf", "blue"),
        ("Buckeburg", "blue"),
        ("Braunschweig", "blue"),
        ("Hildesheim", "blue"),
        ("Gutersloh", "blue"),
        ("Fritzlar", "blue"),
        # ---------------- BLUE: south ----------------
        ("Fulda", "blue"),
        ("Frankfurt", "blue", {"depot": True}),
        ("Wiesbaden", "blue"),
        ("Giebelstadt", "blue"),
        ("Schweinfurt", "blue"),
        ("Hahn", "blue"),
        ("Ramstein", "blue"),
        # ---------------- RED: north ----------------
        ("Wismar", "red"),
        ("Laage", "red"),
        ("Parchim", "red"),
        ("Pinnow", "red", {"name": "Schwerin-Pinnow"}),
        ("Wittstock", "red"),
        ("Neuruppin", "red"),
        # ---------------- RED: centre ----------------
        ("Stendal", "red"),
        ("Gardelegen", "red"),
        ("Mahlwinkel", "red"),
        ("Cochstedt", "red"),
        ("Zerbst", "red"),
        ("Dessau", "red"),
        ("Kothen", "red"),
        ("Schonefeld", "red", {"depot": True, "name": "Berlin-Schonefeld"}),
        ("Briest", "red"),
        ("Altes Lager", "red"),
        # ---------------- RED: south ----------------
        ("Allstedt", "red"),
        ("Obermehler Schlotheim", "red"),
        ("Bindersleben", "red", {"name": "Erfurt-Bindersleben"}),
        ("Haina", "red"),
        ("Merseburg", "red"),
        ("Schkeuditz", "red", {"name": "Leipzig-Schkeuditz"}),
        ("Brandis", "red", {"depot": True}),
        ("Holzdorf", "red"),
    ],
    "towns": [
        ("Wolfsburg", "blue", 52.4230, 10.7870),
        ("Helmstedt", "blue", 52.2270, 11.0100),
        ("Gottingen", "blue", 51.5410, 9.9160),
        ("Kassel", "blue", 51.3130, 9.4790),
        ("Salzwedel", "red", 52.8500, 11.1500),
        ("Magdeburg", "red", 52.1310, 11.6400),
        ("Eisenach", "red", 50.9740, 10.3200),
        ("Nordhausen", "red", 51.5050, 10.7910),
    ],
    "noEdges": [],
    "extraEdges": [],
}
