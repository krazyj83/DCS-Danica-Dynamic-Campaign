# Danica Dynamic Campaign – Pilotguide

Oct 22, 2026 · @Mark

## Velkommen

Danica Dynamic Campaign er en krig, der aldrig holder pause: den kører døgnet rundt på serveren, også når ingen er online, og alt hvad du ødelægger, forbliver ødelagt. Du flyver ikke en færdigskrevet mission – du flyver ind i en front, der flytter sig efter hvad både AI'en og andre piloter har gjort, siden du sidst var på.

- **Én vedvarende krig pr. kort.** Baser skifter ejer, konvojer kører forsyninger frem, og fronten tegnes live på F10-kortet.
- **Fire kort i rotation:** Caucasus → Syria → Persian Gulf → Cold War Germany → Caucasus. Når en side har vundet, skifter serveren selv kort efter to minutter.
- **En krig slutter** når én side har mistet sin sidste base (erobring) – eller når krigsuret løber ud efter 7 dage. Så vinder den side, der har vundet mest terræn siden start.
- **Din pilotjournal følger dig** på tværs af krige og kort: sorties, kills, missioner, rang og point.

Den vigtigste ting at forstå: **spillerne afgør krigene.** Uden spillere står AI-siderne nogenlunde lige og når sjældent en afgørelse. Hver konvoj, SAM-stilling, forsyningsdepot og transportfly du rammer, flytter balancen målbart.

> Kører serveren uden adgang til at gemme filer, starter krigen forfra ved hver genstart, og en krig varer kun 24 timer. Det får du at vide ved start.

## Spillet: sådan vinder man, og hvorfor du skal være med

En side vinder kortet på to måder, og begge afgøres af spillerne – ikke af AI'en.

| Sejr | Hvornår |
| --- | --- |
| **Erobring** | En side tager fjendens sidste base. Kortet er vundet med det samme. |
| **Krigsuret** | Efter 7 dage vinder siden, der har vundet flest baser siden start (uafgjort: den stærkeste hær, derefter den største SU-beholdning). |

**Hvorfor flyve med – og helst sammen med andre:**

- **AI'en alene står lige.** Testet offline over 14 lange krige sluttede ingen af sig selv. Det er spillerne, der vipper krigen.
- **Sammen tæller mere.** Flere piloter kan tage samme mission. Lykkes den, får alle pointene plus 5 i teambonus. En strike-pakke med eskorte (PKGESCORT) giver +10 til alle i pakken.
- **Din pilotjournal følger dig** på tværs af krige og kort: sorties, flyvetid, kills, missioner, redninger, udskydninger og tilfangetagelser.
- **Du kan flyve for begge sider.** Har du fløjet 3 sorties eller fuldført 1 mission for den side, der vinder, får du sejrsbonus: +150 ved erobring, +50 ved sejr på krigsuret. Gør du nok for begge sider, får du bonussen, uanset hvem der vinder.

Én pilot kan vinde et slag. En eskadrille, der følger sidens main effort og fordeler rollerne, vinder krigen.

## Kom i gang: din første sortie

Din første sortie handler om én ting: tag en mission fra boardet, løs den, og land på en venlig base – først da tæller pointene.

1. **Vælg side og fly.** Spawn på en base, din side ejer. Du kan kun vælge din sides flytyper – og kun dem, basen har på lager (4 af hver type, 8 på depoter). Erobres en base, får den den nye ejers fly. Spawner du på en base, din side ikke ejer, bliver du fjernet med en besked.
2. **Læs situationen.** *F10 → Other → Campaign → Campaign status* viser: antal baser pr. side, dine delinger, din sides **main effort**, din sides samlede SU, konvojer og airlifts på vej, baser uden forsyning, krigsuret og hvem der fører, dit luftvåben (jagere og angrebsfly), antal åbne missioner og de 5 seneste erobringer og tab. Kig også på F10-kortet: fronten er den gule linje, og dine egne baser viser `plt | SU`.
3. **Tjek dine våben.** Ved spawn får du at vide, hvad basen kan bevæbne dig med. Det nemmeste overblik får du i Ground Crew → Rearm and Refuel.
4. **Tag en mission.** *F10 → Other → Missions → Mission board* viser kun det, dit fly kan flyve, sorteret efter type (9 pr. side, *More missions* for resten). Du får en briefing med målets koordinater (grader/decimalminutter, DMS og MGRS), målets højde, kurs og afstand fra dig, og hvad succes gør. På F10-kortet kommer et DCS-kortmærke med missionens navn, fx »CAS: …« – kun synligt for din gruppe.
5. **Flyv sammen.** *Join a flight* viser missioner, som andre piloter på din side flyver lige nu, uanset afstand. Ét klik, og du er med.
6. **Løs opgaven og flyv hjem.** Missionspoint krediteres først, når du lander på en venlig base eller dit hangarskib. Dør du eller skyder dig ud på vejen hjem, mister du pointene – men skaden på fjenden tæller stadig i krigen.

*My mission* gentager briefingen, og *Abandon mission* frigiver dig. Fortryder du et valg, er det helt fint at opgive og tage en anden.

## Økonomien: SU er nøglen til at knække fjenden

SU (supply units) er brændstof, ammunition og reservedele i ét tal, og hver base har sin egen beholdning. Kan en side ikke få SU frem, kan den ikke angribe, og dens baser bliver svagere – derfor er fjendens depoter og transport de vigtigste mål, du kan ramme.

**Ingen side kan købe ind, som den vil.** Kun depoterne producerer: SU løbende og én ny deling pr. depot hvert kvarter. Det tempo stiger 8 % for hver base, siden har vundet siden start, og falder 8 % for hver tabt base. STRIKE på depoternes bygninger og INDUSTRY skærer yderligere i det. En base ved fronten kan ikke købe noget selv – al SU skal transporteres derhen.

| SU kommer frem med | Pr. tur |
| --- | --- |
| Lastbilkonvoj (vej for vej, fra depot mod fronten) | 30 SU |
| Transportfly (C-130 / Il-76, mellem flyvepladser) | 30 SU |
| Forsyningsskib (til havne) | 40 SU |
| AI-forsyningshelikopter (kun i nødsituationer) | 10 SU |
| Spillerens CTLD-kasse | 10 SU |

| SU bruges til | Pris |
| --- | --- |
| Drift af hver deling | En smule hvert 5. minut (en by med 18 delinger: ca. 11 SU i timen) |
| Angreb | 2 SU pr. angribende deling, betalt på basen angrebet starter fra |
| Dine styrede våben | 0,25–0,5 SU pr. våben (se Forsyning og våben) |
| Et tabt spillerfly erstattes | 5 SU (ét i timen pr. base) |
| En ny AI-jager eller -angrebsfly | 10 SU fra et depot (højst ét i timen pr. side) |
| Reparation af SAM, radar og bygninger | 10–60 SU |

**Delinger, der dør i et slag, er væk for altid.** AI'en køber ikke enheder for SU: erstatningerne produceres på depoterne og skal køre hele vejen til fronten – som kolonner, du kan ramme med BAI.

**Uden SU** forsvarer en base sig uden sin forsvarsbonus, delingerne forvitrer på ca. 12 timer, og en base, der er afskåret, uden SU og nede på 2 delinger, overgiver sig.

**Her ser du SU:** dine egne baser på F10-kortet viser `plt | SU` (antal delinger og SU), og `NO SUPPLY` når de er tørre. *Campaign status* viser din sides samlede SU, konvojer og airlifts på vej, og baser uden forsyning. Fjendens SU ser du kun med en RECON-mission.

## Sådan udvikler krigen sig

Krigen er en forsyningskæde: depoter producerer, transport fører frem, AI'en samler styrker til et angreb, og slaget afgør hvem der ejer basen. Hver ny base giver mere produktion – og hvert led kan du ramme.

&#91;embedded content: krigens kredsløb · 4 led, og hvor du griber ind\]

- **Noder og veje.** Kortet består af baser (flyvepladser, byer og depoter) forbundet af veje. Al jordbevægelse følger vejene. Depoter kan først angribes, når intet andet fra den side er inden for rækkevidde.
- **Main effort** er hver sides éne hovedmål: den fjendtlige base, AI'en stabler delinger og SU op ved siden af, inden den angriber med det, den har samlet. Der er ikke et særligt mærke på kortet – du ser det i *Campaign status* (»Main effort: …«), i beskeder til din side, og som pile på F10-kortet, når angrebet rulles ud. CAP-missioner over det er mærket »(main effort)«. Er intet erobret i 12 timer, vælges et nyt.
- **Live-zonen** er ikke det samme som main effort. Inden for 40 km af enhver spiller spawner garnisoner, kolonner og konvojer som rigtige DCS-enheder, og DCS afgør kampene. Alle andre steder kører krigen på terninger. Zonen følger spillerne – det, du ødelægger i den, er væk fra krigen.
- **Slaget.** Uden for live-zonen afgøres et angreb af styrke, forsyning og forsvarsbonus: by ×1,3, flyveplads ×1,5, depot ×2,0 – kun mens forsvareren har SU. Artilleri, befæstninger og veteraner trækker også.
- **Når ingen er online** fortsætter jordkrigen på terninger: depoter producerer, konvojer kører, baser angribes og erobres. AI-fly (CAP, strike-pakker, tankfly, AWACS) flyver kun, mens nogen er online. Det bedste, du kan gøre for din side, er at knække fjendens forsyning og holde din egen kørende – så står den stærkt, også når du er logget af.
- **Krigen tikker hvert 5. minut** og gemmes løbende, så en genstart mister intet. Ødelagte køretøjer ligger som vrag i 3 dage.
- **AI-fly starter i luften.** Begge sider flyver CAP-par, strike-pakker ca. hvert 45. min, helikopterangreb, tankfly, AWACS og droner. De spawner i luften nær en egen base og dukker op som INTERCEPT-missioner, når din side har set dem.

## Dine handlinger flytter fronten

Hver mission peger på noget virkeligt i krigens gemte tilstand, og effekten skrives direkte ind i krigen. Testet offline: at ødelægge konvojerne til fjendens main effort skar 31 % af de enheder, de kunne sende i angreb.

| Mission | Hvem | Succes når | Effekt i krigen |
| --- | --- | --- | --- |
| **CAS** | Luft-til-jord | Angrebet på basen slås tilbage (forsvar), eller basen erobres (angreb) | Afgør hvem der holder basen; hvert kill er permanent. JTAC laser på kode 1688 |
| **BAI** | Luft-til-jord | Konvoj eller kolonne ødelagt | Last eller enheder når aldrig frem |
| **STRIKE** | Luft-til-jord | En brændstof-, ammo- eller lagerbygning ødelagt | −25 SU og lavere output fra basen |
| **SEAD/DEAD** | SEAD | SAM-radar eller hele stillingen dræbt | Radar: offline ca. 2 t. Hele stillingen: genopbygges efter ca. 6 t |
| **RUNWAY** | Luft-til-jord | 3 bomber inden for 60 m af banens midterlinje | Flyveplads lukket 4 t: ingen airlifts eller fly-spawns |
| **INDUSTRY** | Luft-til-jord | 2 af 3 bygninger på fabrik, kraftværk eller raffinaderi | Sidens produktion −12 % pr. anlæg i et døgn |
| **ARTY / FORT / BRIDGE** | Luft-til-jord | Batteri, bunkere eller bro ødelagt | Fjenden mister ildstøtte, forsvar eller en vej i 6 t |
| **CAP** | Luft-til-luft | 20 min på station eller et kill i området | Fjendens AI-angrebsfly holdes væk fra området i 1 t. CAP står altid på boardet, og hver nedskudt AI-jager koster fjenden 10 SU at erstatte (højst én i timen) |
| **INTERCEPT** | Luft-til-luft | Fjendens strike-pakke, helikopterangreb eller forsyningsfly skudt ned | Angrebet eller forsyningen når aldrig frem |
| **HVAA / TANKER** | Luft-til-luft | Fjendens AWACS eller tankfly skudt ned | Fjenden er halvblind, til en ny er købt |
| **ESCORT** | Alle | Dit transportfly eller dine helikoptere lander med dig i nærheden | Lasten leveres |
| **RECON** | Alle | Overflyvning inden for 8 km under 4500 m | Fjendens garnison, forsyning og SAM vises på din sides kort i 6 t |
| **CSAR / SNATCH** | Transporthelikoptere | Land ved piloten (150 m), derefter på venlig base | Egen pilot reddet (fly refunderet) / fange taget |
| **LOGISTICS / CONVOY / FARP** | Helikoptere | Kasser leveret eller konvoj eskorteret | +10 SU pr. kasse; tre kasser gør en by til FARP |

Boardet bygger på efterretninger: BAI tilbydes kun på kolonner set inden for 30 min, og SEAD kun på SAM-stillinger, din side kender. Ser boardet tomt ud, så flyv RECON eller lyt efter radarer først.

### Flyv sammen

Et vilkårligt antal piloter kan tage den samme mission. Boardet viser, hvem der er på (`SEAD: air defence at Sukhumi [2: Anna, Bo]`), flighten får besked, når nogen kommer til eller forlader den, og briefingen lister flighten. Lykkes missionen, får **alle** pointene plus **5 i teambonus**, når I er 2 eller flere. Eskorterer du en STRIKE-, INDUSTRY-, EWR- eller RUNWAY-mission (PKGESCORT), får alle i pakken **+10 i pakkebonus**.

### Lokale missioner til helikoptere og langsomme fly

Helikoptere ser kun missioner inden for **60 nm** af, hvor de spawnede, og langsomme fly (A-10, Su-25, træningsfly, warbirds) inden for **120 nm**, nærmeste først. Kampagnen laver også opgaver tæt på dem i det øjeblik, de spawner – forsyningsture, konvojeskorte, FARP-byggeri, MEDEVAC og fanger – så en base bag linjen altid har arbejde.

### Alle de øvrige missionstyper

Boardet har 36 missionstyper i alt. Ud over dem ovenfor:

| Mission | Hvem | Mål | Succes når | Effekt i krigen |
| --- | --- | --- | --- | --- |
| **EWR** | Luft-til-jord | Fjendtlig early-warning-radar | Den er ødelagt | Fjenden mister sit luftbillede der i 6 t (40 SU at genopbygge) |
| **PKGESCORT** | Luft-til-luft | Din sides STRIKE, INDUSTRY, EWR eller RUNWAY | Du er inden for 25 km, når målet rammes | +10 pakkebonus til strikers, SEAD og eskorte |
| **HVAESCORT** | Luft-til-luft | Dit tankfly eller AWACS, når fjendens jagere jager det | 20 min inden for 40 km | Holder det i live – et tabt er væk i 2 t |
| **AMPHIB** | Alle | Dine marinesoldaters landgangshelikoptere fra Tarawa/Kuznetsov | Du er inden for 20 km, før de lander | Marinesoldaterne angriber en kystby |
| **ANTISHIP** | Luft-til-jord | Fjendens hangarskibsgruppe (når den er fundet) | Sunket | Dens luftvinge er væk resten af krigen |
| **SHIPSTRIKE / SHIPESCORT** | Luft-til-jord / alle | Et forsyningsskib på en sørute | Sunket / det lægger til med dig i nærheden | 40 SU tabt / leveret |
| **SCUD** | Luft-til-jord | En RED SCUD-launcher, der lige har skudt | Ødelagt, inden den flytter sig (\~15 min) | Ingen SCUD-nedslag fra den i 12 t |
| **POPUP** | Luft-til-jord | En MANPADS-gruppe eller mobil SAM, nogen har set | Ødelagt | Én skjult trussel mindre ved fronten |
| **COIN** | Luft-til-jord | Partisancelle ved en by, du holder (Syria, Golfen) | Gruppen er udslettet | Stopper sabotage og baghold omkring byen |
| **FARPSUP** | Transporthelikoptere | Din FARP under halvt lager | Kasser leveret | Holder den kørende – en tør FARP har ingen spawns |
| **MEDEVAC** | Transporthelikoptere | Sårede efter et slag | Hentet og fløjet til egen flyveplads eller depot | Garnisonen +10 % styrke; +15 point |
| **POW** | Transporthelikoptere | Fanger efter en erobring eller overgivelse | Fløjet til egen flyveplads eller depot | Efterretning om de 2 nærmeste fjendtlige baser; +10 point |

## Luftkrigen: hvad AI'en flyver, og hvordan du møder det

Begge sider har en pulje af AI-jagere og -angrebsfly: 16 af hver ved krigens start, ét nyt købt hver time for 10 SU fra et depot (højst 24). Nedskudte AI-fly er væk fra puljen for altid. Alt AI-flyvning sker kun, mens mindst én spiller er online, og flyene spawner i luften nær en egen base.

| Hvad | Hvad sker der | Din mission |
| --- | --- | --- |
| **Strike-pakker** | Cirka hvert 45. min sender hver side et raid mod et rigtigt mål: 2 strikers, 2 eskorter og 2 SEAD-fly (HARM / Kh-31P), hvis målet har en SAM. Når strikerne kommer inden for 6 km, rammes målet: et lager brænder, SAM-radar eller EWR går ned, eller FARP'en er væk. | **INTERCEPT** (når den er opdaget) – skyd strikerne ned, inden de når frem |
| **Helikopterangreb** | Cirka hvert 75. min flyver en side en deling i to UH-60 / Mi-8 mod en svag fjendtlig base (højst 2 delinger) inden for 70 km. Lander de, angriber tropperne; skydes de ned, er delingen tabt. | **INTERCEPT** – samme mission, på helikoptere |
| **CAP-par** | Hver side holder et CAP-par over sit main effort og dækker sin egen base, fjenden masser sig mod. | **CAP** for at holde dem og deres angrebsfly væk |
| **CAS-par** | Angrebspar sendes til slag tæt på spillere – men ikke ind i fjendtlig luftdækning (en fuldført CAP) eller under en aktiv SAM. | CAP og SEAD over dit eget slag |
| **Tankfly** | BLUE KC-135MPRS (drogue, TACAN 51X), RED IL-78M (52X), i bane bag AWACS. | **TANKER** – skyd fjendens ned |
| **AWACS** | E-3A / A-50 i 9 km højde, 120 km bag fronten. Ser fly ud til 350 km. Afløses hver 4. time. To pr. side; et tabt erstattes efter 6 t for 40 SU. | **HVAA** – skyd den ned, så er siden halvblind |
| **Recon-droner** | MQ-9 / Wing Loong over den base, en side angriber. Spotter jordenheder inden for 8 km. | Skyd den ned for at blinde dem |
| **HVA-jagt** | Cirka hvert 90. min går fjendens jagere efter dit tankfly eller AWACS – din side bliver advaret. Et tabt er ikke erstattet i 2 t. | **HVAESCORT** |
| **Esser bliver jaget** | 3 luftkills i én sortie, og fjenden vektorerer et jagerpar mod dig (højst hver 30. min). | Overlev det |
| **Lagdelt luftforsvar** | En SAM tænder først på 60 km, når sidens EWR eller AWACS sporer dig; ellers venter den til 25 km. Hver stilling har punktforsvar (Avenger / Tor), der bliver tændt, når hovedradaren går mørk. | EWR først, så SEAD |

**QRA (quick reaction alert).** Når en ny INTERCEPT åbner, får alle på din side, der står på jorden i et luft-til-luft-fly uden mission inden for 150 km, en scramble-besked med kurs og afstand. Er du i luften inden for **5 minutter**, er INTERCEPT'en din, og alle, der nåede det, får **+10 point**, når pakken er skudt ned. Helikoptere scrambles aldrig.

**Datalink.** Alle script-spawnede fly (AWACS, tankfly, AI-jagere, CTLD-helikoptere) har EPLRS tændt, så Link 16- og SADL-brugere ser AWACS-sporene. Faste slots har Mission Editorens datalink-opsætning og unikke Link 16 STN'er.

**Skalering.** Den side med færrest spillere online tager op til 15 % færre tab i kamp, og dens AI flyver flere strike-pakker (5 % og +25 % pr. spiller i forskel). Det holder krigen fair, når spillere skifter side.

## Jordkrigen: det der sker på vejene

| Hvad | Hvad sker der | Din mission |
| --- | --- | --- |
| **Artilleri** | 2 batterier pr. side (M109 / 2S19) rykker frem bag main effort og ved baser under angreb. Et batteri ved et slag får fjenden til at miste 30 % mere. Uden slag beskyder det nærmeste fjendtlige base, som mister SU hvert 5. minut. Mundingsglimtet afslører det. | **ARTY** – genopbygges efter 6 t |
| **Frontsammenstød** | Små kampe (2 køretøjer pr. side) kører altid på op til 8 frontveje, så der altid er noget til CAS. De kommer igen 30 min efter at være udslettet. | CAS overalt på fronten |
| **Befæstninger** | En base, ingen angriber, graver sig ned: ét niveau hver 6. time (10 SU), op til 3, +10 % forsvar pr. niveau. Bunkere dukker op, når du er tæt på. | **FORT** – ødelæg bunkerne før et angreb |
| **Broer** | Rigtige DCS-broer på vejene. En ødelagt bro lukker vejen i 6 t: kolonner stopper, og AI'en finder en anden vej. | **BRIDGE** på fjendens forsyningsveje |
| **Moral** | En base uden SU forsvarer sig på 70 %, en afskåret base på 80 %. Afskåret, uden SU og nede på 2 delinger: den overgiver sig. | Omring og sult |
| **SCUD'er (RED)** | 2 launchere bag linjen skyder mod BLUE-depoter og -flyvepladser cirka hver 2,5 time (−15 SU, 35 % chance for lukket bane). Affyringen afslører dem; 15 min efter flytter de sig. | **SCUD**-jagt |
| **Pop-up-trusler** | MANPADS og mobile SAM'er (Stinger / Avenger, Igla / Strela) dukker op ved fronten, op til 3 pr. side i ca. 1,5 t. På kortet først, når nogen har set en (8 km) eller den skyder. | **POPUP** |
| **Veteraner** | Delinger på en base, der holdes eller tages, får erfaring: veteran kæmper 10 % hårdere, elite 20 %. | – |
| **Partisaner** (Syria, Golfen) | Celler rejser sig i byer væk fra fronten og saboterer forsyning og overfalder kolonner. | **COIN** |
| **Baghold på konvojer** | En eskorteret konvoj møder et andet baghold længere nede ad vejen, og en uescorteret frontkonvoj nær spillere kan blive overfaldet (30 %). | **CONVOY** |
| **Minefelter** | Lagt med CTLD inden for 1,5 km af en vej: fjendens kolonner kører halv fart i 24 t og mister 15 % én gang. | – |
| **Vrag** | Ødelagte køretøjer ligger som vrag gennem genstarter (3 dage, højst 300), og ødelagte bygninger forbliver ødelagte. | – |

**Røg på slagmarken – vigtigt for CAS.** Når et live angreb er inden for 2 km af basen, lægger angriberens artilleri et røgtæppe mellem dem og basen. Forsvarerne kaster også selv røg, når angrebet er inden for 2 km, eller når et fjendtligt fly **angriber** inden for 6 km og under 2500 m (har skudt inden for det seneste minut, eller dykker mod basen). Fly, der bare flyver forbi, sætter det ikke i gang. Kommer du lavt ind og dykker, kan du altså forvente røg, der gør målene sværere at se.

**Nat.** Om natten bliver hvert slag med en spiller inden for 25 km oplyst af en lysgranat hvert 2. minut. Flere kan kaldes via *Support → Illumination on my map mark* (4 lysgranater, 2 SU).

## Søkrigen og hangarskibene

Alle fire kort har hangarskibsgrupper til begge sider.

| Kort | BLUE | RED |
| --- | --- | --- |
| Caucasus | Stennis ud for Poti, Tarawa ud for Batumi | Kuznetsov ud for Novorossiysk |
| Syria | Stennis vest for Haifa/Beirut, Tarawa ud for Haifa | Kuznetsov ud for Tartus |
| Persian Gulf | Stennis i Omanbugten, Tarawa ud for Fujairah | Kuznetsov vest for Kish |
| Germany | Stennis i Tyske Bugt | Kuznetsov i Mecklenburger Bucht |

| Skib | TACAN / ICLS | Spillerslots |
| --- | --- | --- |
| **CVN-74 Stennis** (+3 eskorter) | 74X STN / 4 | 2× F/A-18C, 2× F-14B, F-14B(U), F-14A |
| **LHA-1 Tarawa** (+ fregat) | 75X TAR / 5 | 2× AV-8B, UH-1H, AH-64D, Gazelle |
| **Admiral Kuznetsov** (+3 eskorter) | – | 4× Su-33, Ka-50 III |

- **Luftvinge:** en AI-CAP over hvert hangarskib og en BLUE S-3B recovery tanker på TACAN 76X, der følger skibet.
- **Når en gruppe er fundet** med radar eller øjne, får fjenden ANTISHIP-missioner, og hans AI slår til en gang imellem (RED Su-34 med Kh-31A, BLUE Hornets med 4 Harpoons). **Sunket = væk resten af krigen** med hele luftvingen, også efter en genstart.
- **Landgang:** cirka hver 2. time sender Tarawa eller Kuznetsov 2 delinger marinesoldater med helikopter mod den svageste fjendtlige kystby inden for 70 km. Egen side: AMPHIB-eskorte. Fjenden: INTERCEPT på landgangshelikopterne.
- **Søruter:** hvert kort har 5–8 ruter fra åbent hav til en havn. Hver 3. time sender en side et forsyningsskib (40 SU, 10 knob, 2–4 t) til sin laveste havn. Fjenden: SHIPSTRIKE. Ejeren: SHIPESCORT.

## Fog of war: du ser kun det, din side har fundet

F10-kortet viser ikke fjenden af sig selv – kun de kontakter, din side faktisk har opdaget. Ejerskab af baser og frontlinjen er offentlige; alt andet skal findes.

| Kilde | Hvad den giver |
| --- | --- |
| **Radar** (egne EWR og AWACS) | Fjendtlige fly over radarhorisonten |
| **Øjne** (et spillerfly inden for 6 km af jordenheder / 10 km af fly, fri sigtelinje) | Kolonner, garnisoner, SAM-stillinger med præcis position |
| **AI-sensorer** (egne SAM, jagere, deling) | Fly og jordenheder nær dem |
| **ELINT** – radarlytning, sker af sig selv: dit fly over 800 m inden for 110 km af en tændt SAM-radar opfanger signalet | SAM-position med fejlcirkel: ±6 km først, ned til 300 m jo længere du lytter |
| **RECON-mission** | Hele basen: garnison, SAM-status, kolonner. Gælder 6 t |

**Kontakter ældes.** Frisk i 30 min (fuldt optrukket, kan tildeles som mission), derefter forældet (falmet, "last seen"), glemt efter 3 timer. Kolonner tegnes der, hvor de blev set – ikke der, hvor de er nu.

**Lavtflyvning virker.** Radaren ser kun over horisonten: 100 km væk skal du over ca. 370 m for at blive set, 150 km væk over ca. 1 km. Lavt og væk fra AWACS er du usynlig på fjendens kort, medmindre nogen ser dig.

**SAM-stillinger holder radaren slukket** til du er inden for 60 km – men kun 25 km, hvis fjendens EWR eller AWACS ikke sporer dig. Slå derfor EWR'erne ud først. En HARM tvinger en radar til at slukke i 1–2 minutter: brug vinduet til at komme tæt på. Punktforsvar (Avenger/Tor) flytter sig 1,5–4 km efter at have skudt.

**Flere kilder, du får gratis:**

- **Troops in contact:** hver af dine baser ser fjendtlige kolonner inden for 8 km på sine veje og alt, der angriber den. Det giver BAI-mål på kolonner, der er ved at ramme dig.
- **Frontvurdering:** fjendens frontbaser viser altid et skøn – *est. light / medium / heavy*.
- **Recon-fotos:** en fuldført RECON fotograferer basen: hver deling med køretøjstyper (`[photo] 4x T-72B3`) som mærker på din sides kort, plus en fotorapport til piloten med alle delinger, SAM- og radarstatus.
- **POW:** fanger fløjet hjem giver efterretning om de 2 nærmeste fjendtlige baser.

| Efterretning | Hvor længe kan du stole på den |
| --- | --- |
| Fjendtlige fly (radar, øjne, sensorer) | Vises i 2 min efter sidste kontakt |
| Kolonner, garnisoner, SAM set med øjne eller sensorer | Frisk i 30 min (kan blive til en mission), forældet til 3 t, derefter glemt |
| SAM fundet ved radarlytning | Fejlcirklen bliver mindre, jo længere nogen lytter – men punktforsvar og SA-11 flytter sig 1,5–4 km efter at have skudt |
| RECON af en hel base | 6 timer |

**F10-visning:** missionerne tvinger DCS' *Fog of war*-visning: dine egne enheder, plus fjendtlige enheder kun mens en venlig enhed kan se dem. Kampagnens eget efterretningslag lægger de sidst kendte positioner oven på. Tilskuere ser kun frontlinjen og hvem der ejer baserne.

**AI'en planlægger med fuld viden.** Fog of war gælder kun spillerne – AI-kommandanterne ser alt.

### Radarerne

| Hvad | Sådan virker den | Sådan rammer du den |
| --- | --- | --- |
| **Early-warning-radar (EWR)** | Én ved hvert depot. Ser fjendtlige fly inden for 180 km – men kun over radarhorisonten, og terræn blokerer. Din egen dækning er en svag ring på dit kort. | Den sender altid, så fjendtlige fly hører den (200 km), og en **EWR**-mission dukker op. Ødelagt = 6 t og 40 SU at genopbygge. Erobret = ødelagt. |
| **AWACS** (E-3A / A-50) | Mens nogen er online: én i bane 120 km bag fronten i 9 km højde, ser fly ud til 350 km. Lander, når serveren tømmes. | Er den set, får fjenden en **HVAA**-mission. Skudt ned = siden er halvblind, til en ny er købt (6 t, 40 SU). |

## Forsyning og våben: hvad du kan læsse afhænger af basen

En base kan kun bevæbne dig med det, dens forsyning (SU) rækker til – og hvert styret våben du tager, betales af basens forsyning.

| Basens SU (af hvad den kan rumme) | Tilgængelige våben | Trækker fra basens SU |
| --- | --- | --- |
| Altid | Kanon, raketter, ustyrede bomber, pods, tanke | Intet |
| Fra 20 % | + IR-missiler, laser-/TV-styrede (Hellfire, Maverick, GBU-12) | 0,25 SU pr. stk. |
| Fra 45 % | + radarmissiler (AMRAAM, R-77), anti-radar, GPS-bomber, anti-skib, krydsermissiler | 0,5 SU pr. stk. |

Baser starter krigen på 50 %, så alt er på hylden, indtil fjenden skærer forsyningen over.

- *F10 → Other → Support → Armoury at this base* viser, hvad basen har. Det nemmeste overblik for dit eget fly får du i Ground Crew → Rearm and Refuel: det, der ikke er på hylden, står som "NOT AVAILABLE".
- **Depoter har dobbelt lager.** Mangler du AMRAAM eller HARM, så flyt til en base længere tilbage.
- **Fly er også begrænsede:** hver base har et lager af hver type (4, eller 8 på depoter). Mistede fly erstattes ét i timen og koster forsyning.
- **Cooldown:** to dødsfald inden for en time giver 15 minutters flyveforbud i hurtige jetfly. Helikoptere er altid tilladt.

Den økonomiske pointe: hver AMRAAM, du skyder ud i det blå, er forsyning, som fronten ikke får. Flyv med det, opgaven kræver.

## Kun for helikoptere: logistik er krigsførelse

Helikopterpiloter flytter krigen lige så meget som jetpiloter: de holder baser i live, bygger FARPs og flyver tropper ind i angreb. Al last går gennem *F10 → Other → CTLD*.

| Du gør (CTLD) | Det sker i krigen |
| --- | --- |
| Henter en **forsyningskasse** på en egen base | Basen betaler 10 SU; en tør base siger nej |
| Leverer kassen inden for 3 km af en egen base | +10 SU dér og fuldfører LOGISTICS |
| **3 kasser** til en venlig by (eller en FOB inden for 5 km) | Byen bliver **FARP**: helikopter-spawn, brændstof og ammo |
| Laster **tropper** (10 soldater = 1 deling fra garnisonen) | Sæt af ved egen base: forstærkning. Ved fjendens base: **luftangreb** med det samme |
| Bliver skudt ned med tropper om bord | Delingerne er tabt. Forlad slottet med tropper om bord, og de går hjem |
| Sætter et **AA-system** op inden for 3 km af egen base | Basen graver sig et niveau ned (maks. 3) |
| Pakker **haubits/MLRS** ud på egen base | Nyt artilleribatteri |
| **Bridge kit** (2 kasser) ved en ødelagt bro / **minefelt** ved en vej | Vejen genåbnes straks / fjendens kolonner kører halv fart |

**Flere helikoptermissioner (v0.33):**

- **FARP-kit** (Chinook/Mi-8, CTLD → Engineering, 30 SU): sat ned inden for 3 km af en venlig by gør den til FARP med det samme. En FARP har sit eget lager (40 SU), der holder ca. 13 timer; under halvt tilbydes **FARPSUP**.
- **MEDEVAC:** sårede efter et slag flyves til egen flyveplads eller depot → garnisonen +10 %.
- **POW:** fanger efter en erobring flyves hjem → efterretning om de 2 nærmeste fjendtlige baser.
- **Repair kit** (1 t, 20 SU): sat ned inden for 3 km af egen base reparerer det straks en bygning, en SAM eller en radar.
- **Lokale opgaver:** helikoptere ser kun missioner inden for 60 nm af, hvor de spawnede, og kampagnen laver opgaver tæt på dem, så en base bag linjen altid har arbejde.

**CSAR:** når en pilot skyder sig ud, får hans side en redningsmission. Land inden for 150 m (grøn røg), og flyv ham hjem: han er reddet, og flyet refunderes. Efter 2 timer bliver han taget til fange. **SNATCH** er det omvendte: hent en fjendtlig pilot, og din side lærer hans hjemmebase at kende.

I storm tilbydes ingen helikoptermissioner.

**CTLD i detaljer:**

- Alle egne baser er pickup- og logistikzoner: 1,5 km om en flyveplads, 600 m om en by. En erobret base skifter zone.
- Tropper, der sættes af i terrænet, er stadig dine – dræbes de der, er de tabt. Saml dem op igen med CTLD.
- **Lette køretøjer** (Chinook, Mi-8: Humvee, MG/TOW-Humvee, UAZ-469) fløjet ind hele og sat ned inden for 3 km af en fjendtlig base kæmper med i luftangrebet.
- **Køretøjer i kasser** pakket ud inden for 3 km af egen base bliver en deling i garnisonen, med den styrke kasserne betalte (fx en Abrams på 4 kasser = 0,67 deling).
- **Ammo- eller brændstoflastbil** pakket ud på egen base bliver til SU (kasser × 10).
- **Generator** (Chinook/Mi-8, 20 SU) på egen base: +25 % lagerplads i 24 t.
- **Runway repair kit** (Chinook/Mi-8, 20 SU) på en kraterramt bane: banen er åben igen med det samme.
- **Repair kit** reparerer i rækkefølgen: ødelagt lagerbygning → luftforsvar → EWR. Uden det reparerer basen sig selv langsomt for SU (bygning hver 3. time, SAM 2–6 t, EWR 6 t).
- **UH-60L** (mod) kan også løfte last. En Chinook bærer kun lette køretøjer; BRDM-2 og tungere kommer i kasser.

## Combined Arms: kør selv i krigen

Har du Combined Arms-modulet, har hver side 2 Tactical Commander-, 2 JTAC- og 2 Observer-slots. Kampagnens egne jordstyrker spawner, så spillere kan køre dem: garnisoner, kolonner, forsyningskonvojer, artilleribatterier og frontsammenstød (SAM, EWR og JTAC-hold forbliver AI). En deling, du kører, bliver spawnet, hvor du tager den, og du tæller som spiller til live-zonen.

| Jordmission | Mål | Færdig når |
| --- | --- | --- |
| **ASSAULT** | Din sides angreb på en fjendtlig base | Basen er erobret |
| **HOLD** | Din base under angreb | Angrebet er slået tilbage |
| **GCONVOY** | Din forsyningskonvoj på vejen | Den når frem |

Point går til alle på missionen, der har været **inden for 5 km af målet i 5 minutter** i alt; teambonus gælder også. Missionerne vises inden for 60 km af køretøjet. Piloter ser aldrig jordmissioner og omvendt.

**Ildstøtte for jordspillere** (*F10 → Support* i køretøjet, ingen rang krævet): artilleri på nærmeste fjende i sigte (inden for 6 km), på dit mål eller på dit kortmærke (12 granater, 10 SU, én ildopgave pr. side hver 10. min, intet tættere end 300 m – *danger close*), CAS-par og lysgranater som for piloter, og **røgtæppe** 500 m foran køretøjet (400 m bredt, 3 min, 2 SU, egen genladning på 5 min).

## Point, rang og eskadriller

Din score afgør din rang, og rangen låser op for støtte, du selv kan kalde ind. Se den under *F10 → Other → Missions → Pilot records*.

| Rang | Point | Låser op |
| --- | --- | --- |
| Lieutenant | 0 | Alle missioner |
| Captain | 100 | Artilleri på din kortmarkør (12 granater, hver 10. min pr. side) |
| Major | 300 | AI CAS-par på din kortmarkør (hver 20. min pr. side) |
| Lieutenant Colonel | 700 | Spawn helikoptere på FARPs |
| Colonel | 1500 | AWACS-billede: de 5 nærmeste fjendtlige fly |
| General | 3000 | – |

Støtte kaldes via *F10 → Other → Support*: sæt først en markør på F10-kortet (din koalition), vælg derefter kommandoen.

- **Sejrsbonus:** flyver du mindst 3 sorties eller fuldfører 1 mission for den vindende side, får du +150 point ved erobring eller +50 ved sejr på krigsuret. Du må gerne skifte side – gør du nok for begge, får du bonussen, uanset hvem der vinder.
- **Eskadriller:** sæt et tag i dit DCS-navn – `[VKG] Morten`, `VKG | Morten` eller `Morten [VKG]` – så tæller din score med på *Squadron leaderboard*.
- **Krigsrapport:** når en krig slutter, viser serveren en rapport med baser, tab, forsyning og top-piloter for den krig.

## Tips til en god oplevelse

De bedste aftener opstår, når piloterne flyver efter sidens main effort og arbejder sammen – ikke når alle jager kills hver for sig.

**Før du letter**

- Tjek *Campaign status* og find din sides **main effort**. Missioner, der støtter den, flytter fronten mest.
- Aftal roller i gruppen: én på CAP, et par på SEAD, resten på strike eller CAS. CAP holder fjendens AI-angreb væk i en time.
- Vælg base med omtanke: en base med lav forsyning giver kun ustyrede våben.

**Rækkefølgen der virker**

1. Find målene (RECON, radarlytning eller bare øjne på fronten).
2. Blind fjenden (EWR → AWACS → SAM). Uden radar ser han dig ikke komme: hans SAM tænder først på 25 km i stedet for 60, og hans piloter får ingen INTERCEPT mod dine fly.
3. Sult fjenden (BAI på konvojer, BRIDGE, RUNWAY, STRIKE på depoter).
4. Tag basen (CAS med JTAC, tropper ind med helikopter).

**Typiske fejl**

- *Glemmer at lande.* Point uden landing er tabte point.
- *Flyver højt ind mod fjenden.* Radaren og SAM'en vågner allerede 60 km ude.
- *Spørger hvorfor der ikke er BAI eller SEAD.* Boardet kræver friske efterretninger – flyv RECON først.
- *Dør to gange på en time.* Så venter der 15 minutter uden jetfly; tag en helikopter imens.

**Vejr og nat:** vejret glider langsomt mellem klart, overskyet, regn og storm, med varsler på skærmen ("Met office: rain within about 3 h"). I regn og storm kører kolonner langsommere, og sigten falder. I storm står fjendens AI-angrebsfly på jorden. Om natten (20–06) halveres sigten, og AI-angreb flyver ikke – jagere og AWACS gør. Godt vindue for natkvalificerede piloter.

**AI'en husker:** rammer du den samme vej igen og igen med angreb, sender den luftværn med konvojerne og til sidst et CAP-par over vejen. Skift jagtområde.

## De fire kort

| Kort | Scenarie | Størrelse |
| --- | --- | --- |
| **Caucasus** | BLUE Georgien mod RED nord, Abkhasien og Sydossetien. BLUE-depoter: Batumi og Kutaisi. RED: Sochi-Adler, Beslan og Krasnodar-Center | 39 baser |
| **Syria** | BLUE Israel, Jordan og Sydlibanon mod RED Syrien og Bekaa. Fronter: Golan, Daraa–Irbid, Beirut–Bekaa | 45 baser |
| **Persian Gulf** | RED er landet på Musandam og de nordlige Emirater og holder øerne; BLUE holder resten af UAE. Øer og strædet er forbundet af **søoverfarter** | 32 baser, 11 søoverfarter |
| **Cold War Germany** | Moderne styrker på den gamle indre tyske grænse, fra Østersøen til Fulda Gap; BLUE vest, RED øst | 55 baser |

Søoverfarter er færger og landgangsfartøjer: kolonner på dem kører kun på terninger og kan ikke rammes med BAI. Kæmp om dem ved havnene, på øerne og i luften. **Territoriet** er tegnet ud fra baserne: hver base ejer det land, der er tættere på den end på nogen anden base, og fronten er der, hvor BLUE- og RED-områder mødes.

## Vejret og natten

Vejret er ét tal – klart, overskyet, regn, storm – der flytter sig lidt hvert 5. minut mod den næste vejrfront, som vælges hver 2.–6. time. Fra klart til regn tager cirka 3 timer, altid gennem trinnene imellem, med prognoser på skærmen (»Met office: rain within about 3 h«) og tendensen i *Campaign status*.

|  | Kolonner | Øjne | Helikoptermissioner | AI-angrebsfly |
| --- | --- | --- | --- | --- |
| Overskyet | Normal fart | 90 % | Ja | Ja |
| Regn | 80 % fart | 60 % | Ja | Ja |
| Storm | 60 % fart | 40 % | **Ingen tilbydes** | **På jorden** |

I DCS ses vejret som **tåge**, der ruller ind og letter (let dis før regn, 4 km i regn, 1,5 km i storm). Skyer og regn kan ikke ændres, mens en mission kører. **Nat** (20–06 missionstid) halverer, hvad øjne kan se, og AI-angrebsfly flyver ikke – jagere og AWACS gør. Klokken starter kl. 12.00, når missionen startes, og går i realtid.

## Server og værktøjer

- **Webkort** (hvis serveren kører companion-programmet): frontlinje og baseejere på et rigtigt kort, krigsur og hvem der fører, vejr, seneste erobringer og kills, top-piloter og eskadriller. Opdateres hvert 30. sekund og virker på telefonen. Kun offentlig information – ingen garnisoner, SU eller fjendtlige positioner.
- **Discord-feed:** erobringer, nedskudte radarer, AWACS og SAM'er, sunkne skibe, ødelagte konvojer, fuldførte missioner, nye FARPs, vejrskift, krigsur-varsler, sejren og hele krigsrapporten.
- **Krigsrapport:** når en krig slutter, vises baser holdt og erobret, tabte delinger, SU leveret og ødelagt, tabte AI-fly, top-piloter og sejrsbonus. Pointene i rapporten er dem, der er scoret i netop den krig.
- **Varsler:** alle får besked 24 t, 6 t og 1 t før krigsuret løber ud, med navnet på den side, der fører. Ved sejr skifter serveren kort efter 2 minutter.
- **Performance guard:** tæller motoren over 700 jordenheder i DCS, skrumper den krigen i felten (live-zone 34 km, færre spawnede delinger og sammenstød); over 1000 endnu mere (29 km). Alle ser »Server busy …«. Selve krigsmodellen ændres aldrig – kun hvor meget af den der er rigtige DCS-enheder.
- **Kneeboard og DTC:** hver mission har 3–4 kneeboard-sider pr. fly (flyvepladsfrekvenser, skibenes TACAN/ICLS, tankfly, kampagnekortet ved start og en quick reference). F-16C og F/A-18C har DTC-cartridges med radiopresets og trusselstabeller; Hornet får alle flyvepladser og byer som navngivne steerpoints.
- **Flytyper:** alle flyvbare typer i DCS, fordelt efter hvem der fløj dem – fra F/A-18C, F-16C, F-15E, F-14, A-10 og AV-8B til Su-27, Su-33, MiG-29, JF-17 og Su-25, plus warbirds og træningsfly. Helikoptere: AH-64D, UH-1H, OH-58D, CH-47F, Gazelle (BLUE) og Ka-50, Mi-24P, Mi-8 (RED). A-4E-C og UH-60L er mods, som både server og spiller skal have installeret. Du kan kun flyve moduler, du ejer.

## Hurtig reference

**F10-menuer** (alle under *F10 → Other*)

| Menu | Indhold |
| --- | --- |
| Campaign → Campaign status | Baser, main effort, forsyning, konvojer, airlifts, seneste erobringer |
| Missions → Mission board | Missioner dit fly kan flyve, pr. type |
| Missions → Join a flight | Missioner andre på din side flyver nu |
| Missions → My mission | Gentag briefing / Abandon mission |
| Missions → Pilot records | Din journal, leaderboard, squadron leaderboard |
| Missions → JTAC | Report target, Mark with smoke, Next target (kun på CAS) |
| Support | Artilleri, CAS-par, AWACS-billede, Armoury at this base, lysgranater på kortmærke |
| CTLD | Kasser, tropper, FOB, AA, køretøjer (helikoptere) |

**Frekvenser og koder**

| Hvad | Værdi |
| --- | --- |
| JTAC-laserkode | 1688 |
| BLUE tankfly KC-135MPRS (drogue) | TACAN 51X |
| RED tankfly IL-78M | TACAN 52X |
| BLUE S-3B recovery tanker (følger Stennis) | TACAN 76X |
| CVN-74 Stennis (alle fire kort) | TACAN 74X, ICLS 4 |
| LHA-1 Tarawa (alle fire kort) | TACAN 75X, ICLS 5 |
| Admiral Kuznetsov (RED) | Su-33- og Ka-50-slots |

**Nøgletal**

| Hvad | Værdi |
| --- | --- |
| Live-zone (enheder spawner som rigtige DCS-enheder) | 40 km fra en spiller (34 / 29 km under høj serverbelastning) |
| SAM-radar tænder | 60 km (med EWR/AWACS-støtte), ellers 25 km |
| Kontakt frisk / glemt | 30 min / 3 t |
| RECON gælder | 6 t |
| Krigsur | 7 dage (24 t på en server uden gemning) |
| Krigen tikker | Hvert 5. minut |
| Depotproduktion | 1 deling pr. depot hvert 15. min, ±8 % pr. vundet/tabt base |
| SU-lager pr. base | By 60, flyveplads 80, depot 300 – baser starter halvfulde |
| AI-luftværn | 16 jagere + 16 angrebsfly pr. side, +1 i timen for 10 SU (maks. 24) |
| Strike-pakker / helikopterangreb | Ca. hvert 45. / 75. minut pr. side |
| QRA | I luften inden for 5 min, op til 150 km → +10 point |
| Cooldown | 2 dødsfald på 1 t = 15 min uden jetfly |
| Teambonus / pakkebonus | +5 / +10 |
| Sejrsbonus | 3 sorties eller 1 mission: +150 erobring / +50 krigsur |

Kilde: [DCS-Danica-Dynamic-Campaign på GitHub](https://github.com/krazyj83/DCS-Danica-Dynamic-Campaign) (v0.33). Missionen har også sine egne kneeboard-sider med frekvenser, kort og en quick reference.
