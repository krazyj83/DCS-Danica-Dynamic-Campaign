# DCS-testplan

Alt det, der kun kan bekræftes i et rigtigt DCS. De offline tests (`tools/run_lua.py tests/…`) kører mod en
falsk DCS (`tests/dcs_mock.lua`). De fanger fejl i koden, men ikke om enheder faktisk kører på vejene, om
menuerne ser rigtige ud, eller om DCS opfører sig, som vi tror.

Testene er delt i to:

- **S – Server:** kræver adgang til serveren: filer i `Saved Games\DCS\DCC\`, `dcs.log`, genstart, missionslisten
  eller Mission Editor.
- **P – Pilot:** kan testes af en pilot, der er logget på serveren i multiplayer. Nogle kræver to spillere, én på
  hver side.

---

## Sådan bruger du den

### 1. Vælg hvad du tester

- **Efter hver ny version:** kør [røgtesten](#røgtest) (13 test, ca. en aften).
- **Når noget er rettet:** kør alle test med `Status: RETEST`.
- **Når der er tid:** tag test med `Status: IKKE TESTET`, fx ét område ad gangen.

### 2. Test og skriv feedback

Ret direkte i denne fil under testen:

```markdown
Status: FEJL · Testet: v0.34.0, 2026-10-26, Caucasus
Feedback: Missionen blev ikke fuldført, selvom jeg fløj 20 min over Senaki. Var i F-16, ca. 6000 m.
Fik ingen besked. dcs.log 21:14: "DCC: ERROR in opsPoll: ..."
```

| Status | Betyder |
| --- | --- |
| `IKKE TESTET` | Ingen har prøvet den endnu |
| `OK` | Virker som forventet |
| `DELVIS` | Virker, men noget er forkert eller mangler. Skriv hvad |
| `FEJL` | Virker ikke |
| `RETEST` | Claude har rettet noget. Test igen |
| `SPRUNGET OVER` | Kunne ikke testes. Skriv hvorfor |

God feedback har: hvad du gjorde, hvad du forventede, hvad der skete, kort og flytype, cirka klokkeslæt, og
gerne linjer fra `dcs.log`, der starter med `DCC:`. Ved fejl kan du finde dem med:

```
findstr "DCC:" "%USERPROFILE%\Saved Games\DCS\Logs\dcs.log"
```

### 3. Giv den til Claude

Skriv fx *"Jeg har testet, se docs/dcs-testplan.md"*. Claude:

1. læser alle test med `FEJL` og `DELVIS`,
2. genskaber fejlen i den offline suite, der står under **Offline**, så den ikke kan komme igen,
3. retter koden, kører alle suiter, hæver versionen, skriver i CHANGELOG og bygger `dist/` igen,
4. sætter testen til `Status: RETEST` og skriver under **Rettet** hvad der blev ændret.

Så tester du igen med den nye mission fra `dist/`.

### 4. Testplanen følger koden

- En **ny feature** får en ny test her med det samme, i samme commit som koden.
- En **ændret feature** sætter de berørte test til `RETEST`.
- Test-ID'er ændres aldrig. Nye test får næste ledige nummer i deres område.

---

## Røgtest

Kør disse efter hver ny version. De rører de vigtigste dele af motoren.

| Test | Hvad |
| --- | --- |
| [S-101](#s-101) | Krigen gemmes |
| [S-102](#s-102) | Genstart fortsætter krigen |
| [S-301](#s-301) | Ingen fejl i dcs.log |
| [P-101](#p-101) | Kun egne flytyper på basen |
| [P-201](#p-201) | Campaign status |
| [P-202](#p-202) | Mission board og briefing |
| [P-205](#p-205) | Point først ved landing |
| [P-301](#p-301) | Live-zonen spawner enheder |
| [P-303](#p-303) | En konvoj kan rammes |
| [P-401](#p-401) | SAM-stilling og radar |
| [P-501](#p-501) | Fog of war: kun det, din side har set |
| [P-701](#p-701) | CTLD-kasse ændrer SU |
| [P-1101](#p-1101) | Bogey dope og debrief (v0.34) |

---

# S – Server

## S-100 · Gem og genstart

### S-101
**Krigen gemmes**
`Status: IKKE TESTET` · Kort: alle · Siden v0.1 · Offline: test_war, test_dcs_bridge

1. Tjek at `io` og `lfs` er kommenteret ud i `<DCS>\Scripts\MissionScripting.lua`.
2. Start missionen og vent 10 minutter.

**Forvent:** Startbeskeden siger *ikke*, at krigen ikke kan gemmes. `dcs.log` har ingen `persistence OFF`.
`Saved Games\DCS\DCC\Caucasus_war.json` findes og får nyt tidsstempel hvert 5. minut. Der kommer
`Caucasus_war_bak<N>.json`-filer.

Feedback:

### S-102
**Genstart fortsætter krigen**
`Status: IKKE TESTET` · Kort: alle · Siden v0.1 · Offline: test_dcs_bridge, test_respawn

1. Lad krigen køre mindst 30 minutter. Notér *Campaign status* (antal baser, main effort, seneste erobringer).
2. Ødelæg nogle køretøjer i en garnison, mens du er i live-zonen.
3. Genstart missionen.

**Forvent:** `dcs.log` siger `war restored on Caucasus at tick N`. *Campaign status* er som før. Garnisonen har
stadig færre køretøjer, og vragene ligger der stadig.

Feedback:

### S-103
**Korrupt gemmefil falder tilbage til backup**
`Status: IKKE TESTET` · Kort: Caucasus · Siden v0.1 · Offline: ingen endnu (`dcc_persist.lua` har ingen test)

1. Stop serveren. Kopiér `Caucasus_war.json` et sikkert sted hen.
2. Åbn filen og slet den sidste halvdel, så den ikke er gyldig JSON.
3. Start serveren.

**Forvent:** Krigen fortsætter fra den nyeste backup, ikke fra en ny krig. Læg din kopi tilbage bagefter.

Feedback:

### S-104
**Pilotjournaler overlever genstart og nye krige**
`Status: IKKE TESTET` · Kort: alle · Siden v0.3 · Offline: test_dcs_ops, test_rotation

1. Flyv en sortie og land. Se *Pilot records*.
2. Genstart missionen og se *Pilot records* igen.

**Forvent:** Samme tal. `Saved Games\DCS\DCC\pilots.json` er opdateret.

Feedback:

### S-105
**Krigen kører uden spillere**
`Status: IKKE TESTET` · Kort: alle · Siden v0.1 · Offline: test_war

1. Tjek at serverindstillingen *Pause without clients* er slået fra.
2. Lad serveren køre en time uden spillere.

**Forvent:** Gemmefilen opdateres hvert 5. minut, og tick-tallet i den stiger. Ved næste login er fronten flyttet
sig eller garnisonerne ændret.

Feedback:

## S-200 · Kort og rotation

### S-201
**Alle fire kort starter**
`Status: IKKE TESTET` · Kort: Syria, PersianGulf, GermanyCW · Siden v0.5 · Offline: test_theaters

1. Indlæs `DCC_Syria.miz`, `DCC_PersianGulf.miz` og `DCC_GermanyCW.miz` én ad gangen.

**Forvent:** Hver starter en krig, sætter flyvepladsernes ejere, tegner territorium og front på F10 og spawner
enheder, når en spiller kommer tæt på. Ingen `DCC: ERROR` i loggen.

Feedback:

### S-202
**Rotation efter sejr**
`Status: IKKE TESTET` · Kort: Caucasus → Syria · Siden v0.5 · Offline: test_rotation

1. Installér `hooks/DCC_rotation_hook.lua` og læg de fire missioner i `Missions\DCC\`.
2. Stop serveren. Fjern alle RED-noder undtagen én fra gemmefilen (eller sæt `garrisonStart` meget lavt).
3. Start og lad BLUE vinde.

**Forvent:** Krigsrapport i chatten og varsel om næste kort. To minutter senere loader serveren
`DCC_Syria.miz`. `dcs.log` har `DCC-ROTATION`-linjer. `rotation.json` ender med `state = "running"` og
`current = "Syria"`. Flag 9900 er sat.

Feedback:

### S-203
**Forkert mission efter genstart**
`Status: IKKE TESTET` · Kort: alle · Siden v0.5 · Offline: test_rotation

1. Med `rotation.json` på `current = "Syria"`: start serveren med `DCC_Caucasus.miz` først i missionslisten.

**Forvent:** Missionen skriver *"the campaign has moved on to Syria"* og rører ikke Caucasus-krigen. Hooken
loader Syria.

Feedback:

### S-204
**Server uden filadgang**
`Status: IKKE TESTET` · Kort: alle · Siden v0.7 · Offline: test_rotation

1. Slå `io`/`lfs` til igen i `MissionScripting.lua` (standard-DCS), eller brug en hostet server.
2. Start missionen.

**Forvent:** Startbeskeden siger, at krigen ikke kan gemmes, og at den varer 24 timer. Efter en sejr slutter
missionen efter 2 minutter, og den næste mission i serverens liste loader.

Feedback:

## S-300 · Log, mission og værktøjer

### S-301
**Ingen fejl i dcs.log**
`Status: IKKE TESTET` · Kort: alle · Siden v0.1 · Offline: alle bridge-suiter

1. Efter en testaften: søg i `dcs.log` efter `DCC: ERROR`.

**Forvent:** Ingen. Er der nogen, så kopiér hele linjen og stack-tracen ind under Feedback.

Feedback:

### S-302
**Missionsindstillinger**
`Status: IKKE TESTET` · Kort: alle · Siden v0.14 · Offline: –

1. Åbn en mission fra `dist/` i Mission Editor. Se Options → F10 view.

**Forvent:** *Fog of war*. Civil trafik er slået fra. Der er én MISSION START-trigger med CTLD og
`dcc_bundle.lua`.

Feedback:

### S-303
**Missioner uden mods**
`Status: IKKE TESTET` · Kort: alle · Siden v0.21 · Offline: –

1. Byg med `python tools/make_mission.py --no-mods` og start på en server uden A-4E-C og UH-60L.

**Forvent:** Missionen loader uden fejl om manglende typer, og der er ingen slots til de to mods.

Feedback:

### S-304
**Armoury-testmissionen**
`Status: IKKE TESTET` · Kort: Caucasus · Siden v0.12 · Offline: test_armoury

1. Start `dist/DCC_Caucasus_ArmouryTest.miz`. Brug *F10 → Armoury test*.

**Forvent:** Menuen viser de våbennavne, DCS fandt, fordelt på trin. Knapperne sætter alle sidens baser til et
SU-niveau, og hylderne i *Rearm and Refuel* følger med.

Feedback:

### S-305
**Webkort og Discord**
`Status: IKKE TESTET` · Kort: alle · Siden v0.6 · Offline: test_companion.py

1. Start `server/start_companion.bat` med en udfyldt `dcc_companion.json`.
2. Åbn webkortet. Vent på en erobring.

**Forvent:** Kortet viser fronten og baseejere og virker på telefonen. Erobringen kommer i Discord inden for et
minut. Ingen garnisoner eller SU på webkortet.

Feedback:

### S-306
**Performance guard**
`Status: IKKE TESTET` · Kort: Germany (flest baser) · Siden v0.27 · Offline: test_ext4

1. Få mange spillere spredt over fronten, eller sæt `ext4.perf.levels` lavt i en testbuild.

**Forvent:** Over 700 jordenheder: alle får *"Server busy …"*, live-zonen skrumper, og færre delinger spawner.
Når tallet falder 15 % under grænsen, kommer det tilbage.

Feedback:

### S-307
**Minelægger uden Currenthill-mod**
`Status: IKKE TESTET` · Kort: alle med søruter · Siden v0.35 · Offline: test_ext4

1. Start en mission på en server uden Currenthill-asset-mod'en. Vent på en RED-minelægger.

**Forvent:** RED's minelægger er en Molniya-korvet i stedet for Vasily Bykov. Ingen `DCC: ERROR` om ukendt type.

Feedback:

---

# P – Pilot

## P-100 · Spawn og slots

### P-101
**Kun egne flytyper på basen**
`Status: IKKE TESTET` · Spillere: 1 · Kort: alle · Siden v0.2 · Offline: test_dcs_bridge

1. Åbn dynamic spawn på en base, din side ejer, og på en, fjenden ejer.

**Forvent:** Egen base: kun din sides typer, 4 af hver (8 på depoter). En erobret base skifter liste ved næste
tick.

Feedback:

### P-102
**Faste slots spawner**
`Status: IKKE TESTET` · Spillere: 1 · Kort: alle · Siden v0.21 · Offline: –

1. Tag et fast slot på et depot.

**Forvent:** Flyet spawner koldt på depotet.

Feedback:

### P-103
**Slot guard på fjendtlig base**
`Status: IKKE TESTET` · Spillere: 1 · Kort: alle · Siden v0.2 · Offline: test_dcs_bridge

1. Spawn et fly på en base, din side ikke ejer (fx et fast slot på en base, der lige er erobret).

**Forvent:** Du bliver fjernet med en besked.

Feedback:

### P-104
**Tabte fly genopfyldes**
`Status: IKKE TESTET` · Spillere: 1 · Kort: alle · Siden v0.2 · Offline: test_dcs_bridge

1. Notér antallet af en flytype på en base. Tag ét og crash det.
2. Se lageret efter en time.

**Forvent:** Én færre lige efter, og ét tilbage efter cirka en time, hvis basen har SU.

Feedback:

### P-105
**Cooldown efter to dødsfald**
`Status: IKKE TESTET` · Spillere: 1 · Kort: alle · Siden v0.7 · Offline: test_dcs_airground

1. Dø to gange inden for en time i et jetfly. Prøv at spawne et jetfly og derefter en helikopter.

**Forvent:** Jetfly afvist i 15 minutter med besked. Helikopteren er tilladt.

Feedback:

## P-200 · F10-menuer og missioner

### P-201
**Campaign status**
`Status: IKKE TESTET` · Spillere: 1 · Kort: alle · Siden v0.1 · Offline: test_dcs_bridge

1. *F10 → Other → Campaign → Campaign status*.

**Forvent:** Baser pr. side, main effort, din sides SU, konvojer og airlifts, baser uden forsyning, krigsur,
luftvåben, antal missioner og de seneste erobringer. Teksten bliver mindst 10 sekunder.

Feedback:

### P-202
**Mission board og briefing**
`Status: IKKE TESTET` · Spillere: 1 · Kort: alle · Siden v0.3 · Offline: test_dcs_ops

1. *Missions → Mission board* i et luft-til-jord-fly og derefter i et luft-til-luft-fly. Tag en mission.

**Forvent:** Kun typer, flyet kan flyve. Højst 10 punkter pr. menu-niveau (*More missions* for resten).
Briefing med koordinater (DM, DMS, MGRS), højde, kurs og afstand. Kortmærke »TYPE: …«, som kun din gruppe ser.

Feedback:

### P-203
**My mission og Abandon**
`Status: IKKE TESTET` · Spillere: 1 · Kort: alle · Siden v0.3 · Offline: test_dcs_ops

1. Tag en mission, brug *My mission* og derefter *Abandon mission*.

**Forvent:** Briefingen gentages. Efter Abandon er kortmærket væk, og du kan tage en ny.

Feedback:

### P-204
**Flyv sammen**
`Status: IKKE TESTET` · Spillere: 2 (samme side) · Kort: alle · Siden v0.19 · Offline: test_dcs_ops

1. Spiller A tager en mission. Spiller B bruger *Join a flight*.
2. Fuldfør missionen og land begge.

**Forvent:** Boardet viser `[2: A, B]`. A får besked, da B kommer med. Briefingen lister begge. Begge får
pointene plus 5 i teambonus.

Feedback:

### P-205
**Point først ved landing**
`Status: IKKE TESTET` · Spillere: 1 · Kort: alle · Siden v0.7 · Offline: test_dcs_airground

1. Fuldfør en mission. Se *Pilot records* før og efter landing på venlig base.
2. Gentag, men skyd dig ud på vej hjem.

**Forvent:** Pointene kommer først ved landing. Ved udskydning får du ingen point, men effekten i krigen står.

Feedback:

### P-206
**Lokale missioner til helikoptere**
`Status: IKKE TESTET` · Spillere: 1 · Kort: alle · Siden v0.15 · Offline: test_dcs_ops

1. Spawn en helikopter på en base bag linjen. Åbn boardet.

**Forvent:** Kun missioner inden for 60 nm, nærmeste først, og mindst én opgave tæt på (forsyning, eskorte,
FARP).

Feedback:

### P-207
**Pilot records og eskadrille**
`Status: IKKE TESTET` · Spillere: 1 · Kort: alle · Siden v0.6 · Offline: test_dcs_ops

1. Flyv med et tag i navnet, fx `[VKG] Mark`. Land efter en sortie. Se *Pilot records*.

**Forvent:** Din journal, leaderboard, og eskadrillen på *Squadron leaderboard*.

Feedback:

## P-300 · Jordkrigen

### P-301
**Live-zonen spawner enheder**
`Status: IKKE TESTET` · Spillere: 1 · Kort: alle · Siden v0.1 · Offline: test_dcs_bridge

1. Flyv mod en frontbase. Hold øje inden for 40 km.

**Forvent:** Garnisoner står ved basen, kolonner og konvojer kører på vejene. Intet står i vand. Når du flyver
væk, forsvinder de igen.

Feedback:

### P-302
**Kills tæller i krigen**
`Status: IKKE TESTET` · Spillere: 1 · Kort: alle · Siden v0.1 · Offline: test_dcs_bridge

1. Ødelæg halvdelen af en garnison. Flyv væk og kom tilbage.

**Forvent:** Garnisonen er stadig mindre. Vragene ligger der.

Feedback:

### P-303
**En konvoj kan rammes**
`Status: IKKE TESTET` · Spillere: 1 · Kort: alle · Siden v0.2 · Offline: test_dcs_bridge, test_ops

1. Find en konvoj (eller tag en BAI-mission) og ødelæg den.

**Forvent:** Beskeden *"… convoy … destroyed"*. Målbasens SU stiger ikke med lasten.

Feedback:

### P-304
**Artilleri**
`Status: IKKE TESTET` · Spillere: 1 · Kort: alle · Siden v0.7 · Offline: test_dcs_airground

1. Flyv nær et slag, hvor et batteri er i nærheden.

**Forvent:** Batteriet skyder, og granaterne slår ned ved basen.

Feedback:

### P-305
**Frontsammenstød**
`Status: IKKE TESTET` · Spillere: 1 · Kort: alle · Siden v0.7 · Offline: test_dcs_airground

1. Flyv langs fronten væk fra baserne.

**Forvent:** Små grupper (2 køretøjer pr. side) kæmper på frontvejene.

Feedback:

### P-306
**Broer**
`Status: IKKE TESTET` · Spillere: 1 · Kort: Caucasus · Siden v0.7 · Offline: test_dcs_airground

1. Tag en BRIDGE-mission og ødelæg broen.

**Forvent:** *"Bridge on the road … destroyed"*. Kolonner på vejen stopper eller tager en anden vej.

Feedback:

### P-307
**AI-angreb lægger røg**
`Status: IKKE TESTET` · Spillere: 1 · Kort: alle · Siden v0.31 · Offline: test_ext4

1. Vær i nærheden, når en AI-kolonne angriber en base (live).

**Forvent:** Når angriberne er inden for 2 km, kommer et røgtæppe mellem dem og basen.

Feedback:

### P-308
**Forsvarere lægger røg kun mod angribende fly**
`Status: IKKE TESTET` · Spillere: 1 · Kort: alle · Siden v0.33 · Offline: test_ext4

1. Flyv lavt forbi en fjendtlig base uden at skyde.
2. Dyk mod basen under 2500 m, eller skyd inden for 6 km.

**Forvent:** Ingen røg ved 1. Røg ca. 300 m ude mod dig ved 2. Højst hvert 10. minut pr. base.

Feedback:

### P-309
**Airlift med transportfly**
`Status: IKKE TESTET` · Spillere: 1 · Kort: alle · Siden v0.2 · Offline: test_dcs_bridge

1. Vent til *Campaign status* melder en airlift. Find transportflyet.

**Forvent:** En C-130 / Il-76 er i luften mellem de to flyvepladser og lander på destinationen. Skydes den ned,
når lasten aldrig frem.

Feedback:

## P-400 · Luftforsvar og luftkrig

### P-401
**SAM-stilling og radar**
`Status: IKKE TESTET` · Spillere: 1 · Kort: alle · Siden v0.3 · Offline: test_dcs_ops

1. Flyv mod en fjendtlig flyveplads eller depot. Ødelæg SAM-radaren.

**Forvent:** Stillingen spawner inden for 80 km. Beskeden *"radar … knocked out"*.

Feedback:

### P-402
**SAM tænder sent uden EWR**
`Status: IKKE TESTET` · Spillere: 1 · Kort: alle · Siden v0.7 · Offline: test_dcs_airground

1. Flyv mod en SAM, mens fjendens EWR er oppe. Notér hvornår RWR'en viser den.
2. Ødelæg EWR'en (EWR-mission) og gentag.

**Forvent:** Ca. 60 km med EWR, ca. 25 km uden.

Feedback:

### P-403
**HARM gør SAM'en mørk**
`Status: IKKE TESTET` · Spillere: 1 · Kort: alle · Siden v0.4 · Offline: test_dcs_intel

1. Skyd en HARM mod en tændt SAM-radar.

**Forvent:** Radaren slukker i 1–2 minutter.

Feedback:

### P-404
**AI-par flyver**
`Status: IKKE TESTET` · Spillere: 1 · Kort: alle · Siden v0.3 · Offline: test_dcs_ops

1. Vent på *"Command: … CAP sortie airborne"*. Find parret.

**Forvent:** Det flyver en bane eller angriber, og står ikke bare stille i luften.

Feedback:

### P-405
**Strike-pakke bliver til INTERCEPT**
`Status: IKKE TESTET` · Spillere: 2 (begge sider) eller 1 + ventetid · Kort: alle · Siden v0.7 · Offline: test_dcs_airground

1. Vent på *"Command: RED STRIKE sortie airborne"* (ca. hvert 45. min). Se BLUE's board.

**Forvent:** En INTERCEPT-mission, når BLUE har set pakken.

Feedback:

### P-406
**AWACS og tankfly**
`Status: IKKE TESTET` · Spillere: 1 · Kort: alle · Siden v0.5 · Offline: test_dcs_radar, test_dcs_airground

1. Vent på *"Command: … AWACS on station"*. Find tankflyet på TACAN 51X og tank.

**Forvent:** AWACS flyver en race-track bag fronten. Tankning fra KC-135MPRS (drogue) virker.

Feedback:

### P-407
**EWR ved depoterne**
`Status: IKKE TESTET` · Spillere: 1 · Kort: alle · Siden v0.5 · Offline: test_dcs_radar

1. Flyv inden for 80 km af et fjendtligt depot. Ødelæg EWR'en.

**Forvent:** En FPS-117 / 1L13 står ved depotet. Beskeden *"early-warning radar … destroyed"*.

Feedback:

### P-408
**QRA-scramble**
`Status: IKKE TESTET` · Spillere: 1 · Kort: alle · Siden v0.27 · Offline: test_ext4

1. Stå på jorden i et luft-til-luft-fly uden mission. Vent på en ny INTERCEPT inden for 150 km.
2. Vær i luften inden for 5 minutter. Skyd pakken ned og land.

**Forvent:** Scramble-besked med kurs og afstand. INTERCEPT'en bliver din. +10 QRA-point.

Feedback:

### P-409
**Strike-bygninger**
`Status: IKKE TESTET` · Spillere: 1 · Kort: alle · Siden v0.3 · Offline: test_dcs_ops

1. Tag en STRIKE-mission og ødelæg en brændstof-, ammo- eller lagerbygning.

**Forvent:** Bygningerne står nær flyvepladsen, ikke på den. Beskeden *"… destroyed (1 of N)"*. Basen mister 25 SU.

Feedback:

## P-500 · Fog of war og efterretning

### P-501
**Fog of war: kun det, din side har set**
`Status: IKKE TESTET` · Spillere: 2 (begge sider) · Kort: alle · Siden v0.4 · Offline: test_dcs_intel

1. Spiller A flyver højt mod et fjendtligt depot. Spiller B (anden side) ser F10.
2. A flyver lavt 100 km væk.

**Forvent:** B ser A ved 1, men ikke ved 2. Fjendtlige enheder vises kun, mens en venlig enhed ser dem.

Feedback:

### P-502
**ELINT-cirkel bliver mindre**
`Status: IKKE TESTET` · Spillere: 1 · Kort: alle · Siden v0.4 · Offline: test_dcs_intel

1. Flyv i 6000 m mod en fjendtlig flyveplads med tændt SAM.

**Forvent:** Inden for 60 km kommer en rød SAM-ring med fejlcirkel, og cirklen bliver mindre over nogle minutter.

Feedback:

### P-503
**Øjne og sigtelinje**
`Status: IKKE TESTET` · Spillere: 1 · Kort: alle · Siden v0.4 · Offline: test_dcs_intel

1. Lav et lavt forbifløj over en fjendtlig base. Gentag med en bakke imellem.

**Forvent:** *"N vehicles seen"* ved basen første gang, ikke anden gang.

Feedback:

### P-504
**RECON og fotos**
`Status: IKKE TESTET` · Spillere: 1 · Kort: alle · Siden v0.5 · Offline: test_dcs_radar

1. Tag en RECON-mission. Overflyv basen inden for 8 km under 4500 m.

**Forvent:** Fotorapport til dig. `[photo]`-mærker pr. deling på din sides kort i 6 timer.

Feedback:

### P-505
**Tilskuere ser kun fronten**
`Status: IKKE TESTET` · Spillere: 1 · Kort: alle · Siden v0.4 · Offline: test_dcs_intel

1. Gå i spectator-slot og se F10.

**Forvent:** Kun frontlinjen og baseejere.

Feedback:

## P-600 · Støtte og rang

### P-601
**JTAC-laser**
`Status: IKKE TESTET` · Spillere: 1 · Kort: alle · Siden v0.6 · Offline: test_dcs_world

1. Tag en CAS-mission. *Missions → JTAC → Report target*.

**Forvent:** Laser på kode 1688 i din pod. *Mark with smoke* og *Next target* virker.

Feedback:

### P-602
**Lysgranater på kortmærke**
`Status: IKKE TESTET` · Spillere: 1 · Kort: alle · Siden v0.26 · Offline: test_ext3

1. Om natten: sæt et kortmærke inden for 30 km af egen base. *Support → Illumination on my map mark*.

**Forvent:** 4 lysgranater, én i minuttet, lyse nok til at se mål.

Feedback:

### P-603
**Armoury at this base**
`Status: IKKE TESTET` · Spillere: 1 · Kort: alle · Siden v0.13 · Offline: test_armoury, test_ext

1. *Support → Armoury at this base* og *Rearm and Refuel* på en base med høj og én med lav SU.

**Forvent:** Høj SU: alt på hylden. Under 20 %: kun ustyret. Det, der mangler, står som NOT AVAILABLE.

Feedback:

### P-604
**Rang-støtte**
`Status: IKKE TESTET` · Spillere: 1 med Captain+ · Kort: alle · Siden v0.11 · Offline: test_ext

1. Sæt et kortmærke og brug *Support → Artillery on my map mark*.

**Forvent:** 12 granater, 10 SU, afvist som Lieutenant, og højst hvert 10. minut pr. side.

Feedback:

## P-700 · Helikoptere og CTLD

### P-701
**CTLD-kasse ændrer SU**
`Status: IKKE TESTET` · Spillere: 1 · Kort: alle · Siden v0.8 · Offline: test_ctld

1. Hent en forsyningskasse på egen base. Sæt den af inden for 3 km af en anden egen base.

**Forvent:** Første base −10 SU, anden base +10 SU på dit kort. LOGISTICS fuldført, hvis du havde den.

Feedback:

### P-702
**FARP af 3 kasser**
`Status: IKKE TESTET` · Spillere: 1 · Kort: alle · Siden v0.8 · Offline: test_ctld, test_dcs_world

1. Lever 3 kasser til en venlig by.

**Forvent:** Lastbilerne kommer, og byens FARP tilbyder din sides helikoptere i slot-listen. (Dynamic spawn på
script-oprettede FARPs er den mindst testede DCS-feature.)

Feedback:

### P-703
**Tropper og luftangreb**
`Status: IKKE TESTET` · Spillere: 1 · Kort: alle · Siden v0.8 · Offline: test_ctld

1. Lad tropper på egen base. Sæt dem af ved en fjendtlig base.

**Forvent:** Garnisonen hjemme har én deling færre. Angrebet starter med det samme.

Feedback:

### P-704
**CSAR**
`Status: IKKE TESTET` · Spillere: 2 eller 1 + udskydning · Kort: alle · Siden v0.3 · Offline: test_dcs_ops, test_ext2

1. En pilot skyder sig ud. Land en Huey inden for 150 m (grøn røg), og flyv til venlig base.

**Forvent:** Piloten er reddet, og flyet refunderes. Fjendens søgehold går mod piloten.

Feedback:

### P-705
**Repair kit**
`Status: IKKE TESTET` · Spillere: 1 · Kort: alle · Siden v0.27 · Offline: test_ext4

1. *CTLD → Engineering → Repair kit* til en egen base med en ødelagt bygning, SAM eller radar.

**Forvent:** Én ting repareres straks i rækkefølgen bygning, SAM, EWR.

Feedback:

### P-706
**FARP-kit og tung last**
`Status: IKKE TESTET` · Spillere: 1 i Chinook/Mi-8 · Kort: alle · Siden v0.16 · Offline: test_ctld, test_ext2

1. *CTLD → Engineering → FARP kit* til en venlig by. Prøv også *Generator* og *Runway repair kit*.

**Forvent:** Byen er FARP med det samme. Generator: +25 % lager. Runway kit åbner en kraterramt bane.

Feedback:

## P-800 · Søkrig og hangarskibe

### P-801
**Hangarskibe på alle kort**
`Status: IKKE TESTET` · Spillere: 1 · Kort: alle fire · Siden v0.24 · Offline: test_dcs_world

1. Spawn på Stennis og Tarawa. Tjek TACAN og ICLS.

**Forvent:** Slots spawner på dækket. 74X / ICLS 4 og 75X / ICLS 5. Skibenes ben ligger på åbent vand. S-3B
svarer på 76X.

Feedback:

### P-802
**Forsyningsskibe går ikke på grund**
`Status: IKKE TESTET` · Spillere: 1 · Kort: PersianGulf, GermanyCW · Siden v0.25 · Offline: test_ext3

1. Følg et forsyningsskib på sin rute (især Hormuz og Tyske Bugt).

**Forvent:** Det når havnen uden at sidde fast.

Feedback:

### P-803
**Havneminer og MINESWEEP**
`Status: IKKE TESTET` · Spillere: 1 i helikopter · Kort: alle med søruter · Siden v0.34, ændret v0.35 · Offline: test_ext4

1. Vent på en orange MINES-cirkel ved en egen havn (fra v0.35 lagt af en minelægger, se P-804). Tag MINESWEEP.
   Flyv under 150 m inden for 3 km af havnen i 5 minutter.

**Forvent:** Missionen fuldføres, og cirklen forsvinder. Mens havnen er mineret, sejler ingen forsyningsskibe dertil.

Feedback:

### P-804
**Minelægger og MINELAYER**
`Status: IKKE TESTET` · Spillere: 1 i A2G-fly eller kamphelikopter · Kort: alle med søruter · Siden v0.35 · Offline: test_ext4

1. Vent på en fjendtlig minelægger på vej mod en egen havn (BLUE: Castle class, RED: Vasily Bykov). Den kan tage
   op til 6 timer at komme.
2. Når den er opdaget: tag MINELAYER og sænk den.
3. Lad en anden minelægger nå havnen.

**Forvent:** Skibet sejler sørutens vej uden at gå på grund. Det kommer på din sides kort (*MINELAYER > havn*) og
board, når det er en tredjedel inde, eller når en pilot er inden for 20 km. Sænket: ingen miner. Når det når 85 %
af ruten: MINES-cirkel ved havnen, og skibet sejler hjem.

Feedback:

## P-900 · Navigation, kneeboard og datalink

### P-901
**Kneeboard**
`Status: IKKE TESTET` · Spillere: 1 · Kort: alle · Siden v0.26 · Offline: –

1. Åbn kneeboardet i et par forskellige fly.

**Forvent:** 3–4 sider: frekvenser, kampagnekort og quick reference.

Feedback:

### P-902
**DTC i Hornet og Viper**
`Status: IKKE TESTET` · Spillere: 1 · Kort: alle · Siden v0.18 · Offline: –

1. Tag et fast F/A-18C-slot. Load DTC'en.

**Forvent:** Radiopresets og alle flyvepladser og byer som navngivne steerpoints.

Feedback:

### P-903
**Datalink fra AWACS**
`Status: IKKE TESTET` · Spillere: 1 · Kort: alle · Siden v0.21 · Offline: test_dcs_radar

1. Med AWACS oppe: se SA-siden (Hornet) eller HSD (Viper) i et fast slot.

**Forvent:** AWACS-spor vises.

Feedback:

## P-1000 · Vejr, nat og Combined Arms

### P-1001
**Storm og tåge**
`Status: IKKE TESTET` · Spillere: 1 · Kort: alle · Siden v0.22 · Offline: test_ops, test_dcs_world

1. Når *Campaign status* siger storm: se ud.

**Forvent:** Tågen lukker ind (DCS 2.9.10+). Ingen helikoptermissioner. Varsler fra *"Met office"* før skiftet.

Feedback:

### P-1002
**Lysgranater over slag om natten**
`Status: IKKE TESTET` · Spillere: 1 · Kort: alle · Siden v0.26 · Offline: test_ext3

1. Om natten (20–06): flyv inden for 25 km af et slag.

**Forvent:** En lysgranat i 650 m hvert 2. minut. Lys nok til at se målene.

Feedback:

### P-1003
**Combined Arms: kør en deling**
`Status: IKKE TESTET` · Spillere: 1 med CA · Kort: alle · Siden v0.27 · Offline: test_ext4

1. Tag et Tactical Commander-slot. Overtag en deling, en konvoj eller et batteri.

**Forvent:** Den kan køres og bliver spawnet, hvor du tager den. Ingen pilotmenuer, ingen slot guard.

Feedback:

### P-1004
**Jordmissioner**
`Status: IKKE TESTET` · Spillere: 1 med CA · Kort: alle · Siden v0.28 · Offline: test_ext4

1. I et køretøj: *Missions*. Tag ASSAULT, HOLD eller GCONVOY. Vær inden for 5 km af målet i 5 minutter.

**Forvent:** Kun jordmissioner inden for 60 km. Point i pilotjournalen, når missionen lykkes.

Feedback:

### P-1005
**Ildstøtte og røgtæppe for jordspillere**
`Status: IKKE TESTET` · Spillere: 1 med CA · Kort: alle · Siden v0.30 · Offline: test_ext4

1. I et køretøj: *Support → Artillery on the nearest enemy in sight* og *Smoke screen ahead*.

**Forvent:** Artilleri på målet (ikke inden for 300 m af dig). Røgtæppe 400 m bredt 500 m foran efter ca. 20 s,
i 3 minutter.

Feedback:

## P-1100 · Nyt i v0.34

### P-1101
**Bogey dope og debrief**
`Status: IKKE TESTET` · Spillere: 1 · Kort: alle · Siden v0.34 · Offline: test_ext4

1. I luften, med fjendtlige fly i nærheden: *F10 → Support → Bogey dope*.
2. Land på venlig base, FARP eller eget hangarskib.

**Forvent:** 1: BRAA og aspekt til nærmeste fjendtlige fly, din side har set inden for det seneste minut, inden
for 100 nm. 2: Debrief med flyvetid, kills, fuldførte missioner med deres effekt, point og forfremmelser.

Feedback:

---

## Testrunder

Én linje pr. testaften, så vi kan se hvad der er testet på hvilken version.

| Dato | Version | Kort | Hvem | Test | Resultat |
| --- | --- | --- | --- | --- | --- |
| | | | | | |
