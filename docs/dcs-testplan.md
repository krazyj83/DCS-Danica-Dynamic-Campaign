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

- **Efter hver ny version:** kør [røgtesten](#røgtest) (16 test, ca. en aften).
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
| [P-904](#p-904) | F-16 Link 16 synker med GPS (v0.43) |
| [P-707](#p-707) | FARPer fra start (v0.44) |
| [S-308](#s-308) | Selvtjek ved missionsstart (v0.47) |

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

### S-106
**Frisk krig (admin: `-dcc freshwar yes`)**
`Status: RETEST` · Kort: Caucasus · Siden v0.40, ændret v0.47 · Offline: test_rotation

1. Tag et Game Master-slot. Skriv `-dcc freshwar` i chatten, derefter `-dcc freshwar yes`.
2. Vent 15 s på genindlæsningen. Genstart missionen én gang til bagefter.

**Forvent:** Først et svar, der beder om *yes*. Efter *yes*: alle får besked, missionen genindlæses, og beskeden *FRESH
WAR* kommer; kortet er som ved krigens start (Senaki-Kolkhi BLUE). Ingen kortrotation. Anden genstart: krigen
fortsætter. Pilotrekorderne er der stadig.

Feedback: v0.39: C-130J-slottet på Senaki-Kolkhi tog ikke imod spilleren (navnet kom ikke frem). Serveren kørte stadig
den gamle krig, hvor Senaki var tabt.
v0.47.0: fresh-war-switchen (`freshWar`-token) er fjernet; en admin nulstiller krigen med `-dcc freshwar yes`.

### S-107
**Admin-kommandoer fra Game Master**
`Status: IKKE TESTET` · Kort: alle · Siden v0.47 · Offline: test_rotation

1. Installer den nye `DCC_rotation_hook.lua` i serverens `Scripts\Hooks`. Genstart serveren.
2. Som pilot: skriv `-dcc status`. Tag så et Game Master-slot og skriv `-dcc help`, `-dcc status`, `-dcc check`,
   `-dcc save`, `-dcc restock` og `-dcc restart`.

**Forvent:** Piloten får "need a Game Master slot". Game Master får svarene kun til sig selv; ingen andre ser
kommandoerne i chatten. `restart` genindlæser missionen efter 15 s, og krigen fortsætter. Med en
`DCC\admins.txt` (én UCID pr. linje) virker det kun for de UCID'er, der står i den.

Feedback:

### S-108
**Daglig genstart kl. 04:00**
`Status: IKKE TESTET` · Kort: alle · Siden v0.48 · Offline: test_rotation

1. Installer den nye `DCC_rotation_hook.lua`. Lad serveren køre over kl. 04:00 dansk tid (eller sæt `restart.time` i
   hooken til om 35 minutter for at teste nu, og husk at sætte den tilbage).
2. Vær på serveren fra 30 minutter før.

**Forvent:** Advarsel i chat og på skærmen 30, 10 og 1 minut før. Kl. 04:00 genindlæses missionen; krigen fortsætter
med den seneste stilling. Ingen ny genstart samme morgen. I `dcs.log`: `DCC-ROTATION ... daily restart`.

Feedback:

### S-109
**SRS-stemme gennem hooken**
`Status: IKKE TESTET` · Kort: alle · Siden v0.50 · Offline: test_rotation, test_ext4

1. Sæt `srs.dir` i `DCC_rotation_hook.lua` til SRS-mappen på serveren. Installer hooken, genstart serveren.
2. Søg i `dcs.log` efter `SRS text-to-speech`.

**Forvent:** `SRS text-to-speech found in ...`. Ingen sorte kommandovinduer, der bliver stående. Hvis den ikke findes:
ingen stemme, ingen fejl.

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
`Status: RETEST` · Kort: alle · Siden v0.6, ændret v0.51 · Offline: test_companion.py

1. Start `server/start_companion.bat` med en udfyldt `dcc_companion.json`.
2. Åbn webkortet. Vent på en erobring. Flyv en sortie og land hjemme igen. Klik på dit navn i *Leaderboard*.
3. Lad companion køre over mandag kl. 18 (eller sæt `"weekly"` i `dcc_companion.json` til i dag, en time frem).

**Forvent:** Kortet viser fronten og baseejere og virker på telefonen. Erobringen kommer i Discord inden for et
minut. Ingen garnisoner eller SU på webkortet. Din pilotside viser rang, sorties, timer, kills og din sidste
sortie; den står også under *Recent sorties*. Mandag kl. 18: *Week in the war* i Discord med baser, sorties og
ugens bedste piloter (første kørsel tager kun et øjebliksbillede, så opslaget kommer først ugen efter).

Feedback:
v0.51.0: pilotsider, seneste sorties og ugentligt Discord-resumé.

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

### S-308
**Selvtjek ved missionsstart**
`Status: IKKE TESTET` · Kort: alle · Siden v0.47 · Offline: test_ext4

1. Start missionen. Vent 30 s. Åbn `dcs.log` (søg efter `self-check`) og `Saved Games\DCS\DCC\selfcheck.txt`.

**Forvent:** Én linje pr. punkt (OK/WARN): gemning, flyvepladser, HQ-lager, FARP-pads og -lager, våbenlager, GPS,
AI-skabeloner, CTLD og server-hook. Med advarsler kommer de også på skærmen i 60 s. En korrekt opsat server har 0
advarsler.

Feedback:

### S-310
**Missionen åbner uden radiofejl**
`Status: IKKE TESTET` · Kort: alle fire · Siden v0.52 · Offline: –

1. Åbn hver `DCC_<map>.miz` i Mission Editor og gem den.

**Forvent:** Ingen fejl om radiofrekvenser (v0.51: La-7 på Sochi-Adler, "124.00 MHz"). Intet fast La-7-slot;
La-7 kan stadig spawnes dynamisk på RED's baser.

Feedback: v0.51: fejl på La-7's frekvens 124.00 MHz.
Rettet i v0.52.0: La-7 har ikke længere et fast slot (kun dynamic spawn).

---

# P – Pilot

## P-100 · Spawn og slots

### P-101
**Kun egne flytyper på basen**
`Status: RETEST` · Spillere: 1 · Kort: alle · Siden v0.2 · Offline: test_dcs_bridge

1. Åbn dynamic spawn på en base, din side ejer, og på en, fjenden ejer.

2. Lad flere spillere spawne samme type på samme base (især Kutaisi, Batumi, Beslan).

**Forvent:** Egen base: kun din sides typer, 20 af hver (v0.36: før 4 / 8). Flere kan spawne samme type på samme
base. En erobret base skifter liste ved næste tick.

Feedback: v0.36, 9 spillere: på flere baser kunne der ikke spawnes mere end ét fly.
Rettet i v0.37.0: faste klient-slots fyldte hele forpladsen på Kutaisi, Batumi og Beslan, så dynamic spawn ikke
havde ledige pladser. Faste slots må nu højst bruge 25 % af en bases parkering.
v0.37: de store baser havde kun få fly i dynamic spawn.
Rettet i v0.38.0: mindst 2 af hver egen type på alle egne baser, altid (også erobrede baser og nye typer).

### P-102
**Faste slots spawner**
`Status: RETEST` · Spillere: 1 · Kort: alle · Siden v0.21 · Offline: –

1. Se slot-listen for din side. Tag et fast slot, fx C-130J.

**Forvent:** Præcis ét fast slot pr. flytype pr. side (v0.39), først på HQ, så de andre depoter og baser. Flyet
spawner koldt. Alt andet er dynamic spawn med 20 af hver type.

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

### P-106
**Allierede østlige flytyper for BLUE**
`Status: IKKE TESTET` · Spillere: 1 · Kort: alle · Siden v0.36 · Offline: test_dcs_bridge

1. Åbn dynamic spawn på en BLUE-base. Se efter MiG-29, JF-17, Su-27, MiG-21bis, Su-25, L-39, Mi-24P og Mi-8.
2. Spawn i en af dem som BLUE og flyv en mission.

**Forvent:** Typerne står på BLUE's liste (20 af hver) og spawner som BLUE. RED har dem stadig på sine baser.

Feedback:

### P-107
**C-130J spawner**
`Status: RETEST` · Spillere: 1 · Kort: alle · Siden v0.37 · Offline: –

1. Spawn en C-130J-30 på en BLUE-depot, både i det faste slot og via dynamic spawn.

**Forvent:** Flyet spawner på en stor standplads. Hvis ikke: noter basen, slot-typen og linjer fra `dcs.log`.

Feedback: v0.36, 9 spillere: Hercules C-130 loadede ikke (slottet spawnede ikke / hang ved join).
Rettet i v0.37.0: faste slots tog de store standpladser først (pydcs vælger efter navn), så en C-130J ikke fandt
plads. Faste slots står nu på den mindste plads, flyet passer på, og de store pladser er fri til transportfly.

### P-108
**HQ på kortet**
`Status: IKKE TESTET` · Spillere: 1 · Kort: alle · Siden v0.38 · Offline: test_ext4

1. Åbn F10-kortet og *Campaign status*.

**Forvent:** Begge siders HQ har en stjerne og en dobbelt ring (Caucasus: Kutaisi / Krasnodar-Center), og
*Campaign status* nævner dem.

Feedback:

### P-109
**FARP: to helikoptere ad gangen**
`Status: IKKE TESTET` · Spillere: 2 · Kort: alle · Siden v0.38 · Offline: test_dcs_world

1. Byg en FARP. Lad to spillere spawne en helikopter der samtidig.

**Forvent:** Begge spawner (to helipads).

Feedback: v0.37: kun én helikopter kunne spawne på en FARP (én usynlig helipad).

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

### P-208
**Where can I spawn?**
`Status: IKKE TESTET` · Spillere: 1 · Kort: alle · Siden v0.47 · Offline: test_ext4

1. *F10 → Other → Campaign → Where can I spawn?* og *Where can I spawn a helicopter?*

**Forvent:** HQ først, så baserne med flest fly: antal typer og fly, typer med lavt lager (*low*) og typer, der er
udsolgt (*OUT*). Helikoptervalget viser de åbne FARPer med 2 pads og 10 af hver type.

Feedback:

### P-209
**SRS: AWACS, Command og flyvepladsinformation**
`Status: IKKE TESTET` · Spillere: 1 med SRS · Kort: alle · Siden v0.50 · Offline: test_ext4

1. Sæt radioerne på 238.0, 239.0 og 240.0 AM. Sid på en egen flyveplads i et par minutter.
2. Brug *Support → Bogey dope* i luften. Vent på en erobring eller en anden nyhed.

**Forvent:** 240.0: "Kutaisi information, wind ..., runway open, ... aircraft in stock." 238.0: bogey dope læst op
("..., Overlord, bra ..."). 239.0: erobringer og egne nyheder. Kun din sides beskeder; én ad gangen pr. frekvens.

Feedback:

### P-210
**Våbenvejledning i briefingen**
`Status: RETEST` · Spillere: 1 · Kort: alle · Siden v0.53, ændret v0.54 · Offline: test_dcs_ops

1. Tag en BRIDGE-, RUNWAY- og STRIKE-mission fra boardet og læs briefingen.
2. Prøv vejledningen: 4 × Mk-82 (eller 1 × Mk-84) på en bro, 3 × Mk-84 (eller 12 × Mk-82) på en bane.

**Forvent:** Briefingen slutter med en *Weapons:*-linje. Hvert træf giver *Bridge hit (x of 2000 lb)* / *Runway hit
at ... (x of 6000 lb)*; ved 2000 / 6000 lb er broen nede / banen lukket. Skriv i feedback, hvis en mål-type tog mere eller mindre
end vejledningen siger, så tallene kan rettes.

Feedback:
v0.54.0: bro 2000 lb og bane 6000 lb i alt (kampagnen tæller vægten); minelægger 1-2, hangarskib 4 missiler.

## P-300 · Jordkrigen

### P-301
**Live-zonen spawner enheder**
`Status: RETEST` · Spillere: 1 · Kort: alle · Siden v0.1 · Offline: test_dcs_bridge

1. Flyv mod en frontbase. Hold øje inden for 40 km.

**Forvent:** Garnisoner står ved basen, kolonner og konvojer kører på vejene. Intet står i vand eller på
landingsbanen, forpladsen eller taxivejene. Når du flyver væk, forsvinder de igen.

Feedback: v0.36, 9 spillere: kampvogne på landingsbanen.
Rettet i v0.37.0: alle jordenheder og deres waypoints flyttes mindst 60 m væk fra bane, taxivej og forplads.

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

### P-410
**AI på Ace**
`Status: IKKE TESTET` · Spillere: 1 · Kort: alle · Siden v0.41 · Offline: test_dcs_bridge

1. Flyv mod et SAM-anlæg, en AI-CAP og en kolonne. Sammenlign med tidligere.

**Forvent:** AI'en reagerer hurtigere og rammer bedre (skill *Excellent* = Ace). I missionsfilen står skibe og
AI-skabeloner som Ace.

Feedback: v0.40: AI'en var sat til Rookie.

### P-411
**Ingen AI-jamming**
`Status: RETEST` · Spillere: 1 · Kort: alle · Siden v0.42 · Offline: test_dcs_bridge

1. Flyv F-16 mod fjendtlige AI-fly (CAP, strike packages). Se på radar og datalink.

**Forvent:** Ingen jamming-strobes fra AI-fly; datalink-sporene fra AWACS og wingmen bliver stående.

Feedback: v0.41: radar-jammere forstyrrede F-16'ernes datalink.

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
`Status: RETEST` · Spillere: 1 · Kort: alle · Siden v0.13 · Offline: test_armoury, test_ext

1. *Support → Armoury at this base* og *Rearm and Refuel* på en base med høj og én med lav SU.

**Forvent:** 100 af hvert våben, alle typer (også AMRAAM, R-77, AIM-54), på alle baser og FARPs uanset SU (v0.37).
Kun en tør FARP har tomme hylder.

Feedback: v0.36, 9 spillere: flere våbentyper, mest luft-til-luft, manglede, selv om startlageret skulle være 100.
Rettet i v0.37.0: avancerede missiler forsvandt fra hylden, så snart basen kom under 45 % SU. Nu er alle typer
altid på hylden (`ext.armoury.tiers = false`); styrede og avancerede våben koster stadig SU, når de tages.

### P-604
**Rang-støtte**
`Status: IKKE TESTET` · Spillere: 1 med Captain+ · Kort: alle · Siden v0.11 · Offline: test_ext

1. Sæt et kortmærke og brug *Support → Artillery on my map mark*.

**Forvent:** 12 granater, 10 SU, afvist som Lieutenant, og højst hvert 10. minut pr. side.

Feedback:

## P-700 · Helikoptere og CTLD

### P-701
**CTLD-kasse ændrer SU**
`Status: RETEST` · Spillere: 1 · Kort: alle · Siden v0.8 · Offline: test_ctld

1. Land på egen base i en helikopter (eller C-130J). Vælg *F10 → Missions → Supply crate (10 SU)* (v0.37). Load
   kassen med CTLD, og sæt den af inden for 3 km af en anden egen base.

**Forvent:** Første base −10 SU, anden base +10 SU på dit kort. LOGISTICS fuldført, hvis du havde den.

Feedback: v0.36, 9 spillere: ingen mulighed for at lave forsyningskasser.
Rettet i v0.37.0: CTLD's *Supply*-kategori lå dybt i *Request Equipment* og på side 2. Nu ligger *Supply crate*
direkte i *F10 → Missions* for alle CTLD-transporttyper.

### P-702
**FARP af 3 kasser**
`Status: RETEST` · Spillere: 1 · Kort: alle · Siden v0.8 · Offline: test_ctld, test_dcs_world

1. Lever 3 kasser til en venlig by.

**Forvent:** Lastbilerne kommer, og byens FARP tilbyder din sides helikoptere i slot-listen, 10 af hver på hver af de 2 pads (v0.44). (Dynamic spawn på
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

### P-707
**FARPer fra start**
`Status: RETEST` · Spillere: 1 i helikopter · Kort: alle · Siden v0.44 · Offline: test_ext4, test_armoury

1. Start missionen (ny krig, eller genstart af en kørende krig). Åbn slot-listen ved en egen by.
2. Spawn en helikopter på byens FARP (dynamic spawn) - også som ny pilot uden rang (v0.46). Åbn re-arm- og refuel-menuen.

**Forvent:** Hver egen by er FARP på kortet. 2 pads med 10 af hver egen helikoptertype. 50 af hvert helikoptervåben (Hellfire
K/L, APKWS, Hydra, Stinger, dørgevær på CH-47; Vikhr, Shturm/Ataka, S-8 for RED). Ingen jetvåben (AMRAAM, GBU). 1000 t brændstof.

Feedback: v0.43: FARPerne havde ingen dynamic spawn, våben eller brændstof ved missionsstart.
Rettet i v0.44.0: en FARP åbnede først, når spillere havde bygget den, så en ny krig havde ingen. Nu starter hver
egen by som FARP med 10 helikoptere, 50 våben og 1000 t brændstof per pad.
v0.45.0: FARPerne har kun helikoptervåben (`world.farpWeaponMatch`).
v0.46.0: ingen rang kræves for at spawne på en FARP (var Lieutenant Colonel).

### P-708
**AIRASSAULT med gunship-eskorte**
`Status: IKKE TESTET` · Spillere: 1 i transporthelikopter · Kort: alle · Siden v0.49 · Offline: test_ext4, test_ops

1. Tag en AIRASSAULT-mission fra boardet. Lad tropper på den nævnte base (*F10 → CTLD → Load troops*).
2. Let. Flyv mod målet og sæt tropperne af inden for 3 km af det.

**Forvent:** Når du er i luften: beskeden *gunships airborne* og et par AH-64D (RED: Mi-24P), der flyver lavt foran
dig og angriber jordenheder ved målet. Når tropperne er sat af: *Air assault on ...!* og missionen er fuldført
med point. Ingen ekstra gunships, hvis du letter igen.

Feedback:

## P-800 · Søkrig og hangarskibe

### P-801
**Hangarskibe på alle kort**
`Status: RETEST` · Spillere: 1 · Kort: alle fire · Siden v0.24 · Offline: test_dcs_world

1. Spawn på Stennis og Tarawa. Tjek TACAN og ICLS.

2. Åbn dynamic spawn på hangarskibet (v0.37).

**Forvent:** Slots spawner på dækket, og dynamic spawn tilbyder skibets typer (20 af hver). 74X / ICLS 4 og 75X /
ICLS 5. Skibenes ben ligger på åbent vand. S-3B svarer på 76X.

Feedback: v0.36, 9 spillere: ingen dynamic spawn på hangarskibene.
Rettet i v0.37.0: hvert hangarskib har nu sit eget lager med dynamic spawn (20 af hver slot-type, ubegrænset
ammunition og brændstof).

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
`Status: RETEST` · Spillere: 1 · Kort: alle · Siden v0.21 · Offline: test_dcs_radar

1. Med AWACS oppe: se SA-siden (Hornet) eller HSD (Viper) i et fast slot.

**Forvent:** AWACS-spor vises.

Feedback:

### P-904
**F-16 Link 16 synker med GPS**
`Status: IKKE TESTET` · Spillere: 2 · Kort: alle (BLUE) · Siden v0.43 · Offline: –

1. To spillere i F-16C (dynamic spawn og fast slot), flyv sammen med AWACS oppe.
2. DED: LIST → ENTR (NET STATUS). GPS TIME ON.

**Forvent:** SYNC går til FINE inden for et par minutter. Wingman og AWACS-spor bliver på HSD'en. GPS-status på
DED TIME-siden. JDAM rammer med GPS.

Feedback: v0.42: med GPS TIME ON stod SYNC tom, og datalink-symbolerne forsvandt; med GPS slukket virkede det.
Rettet i v0.43.0: BLUE-koalitionen havde ikke USA, så DCS gav ingen GPS. USA er nu med i BLUE (uden enheder), og *Unrestricted SATNAV* er slået til, så begge sider har GPS.

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
