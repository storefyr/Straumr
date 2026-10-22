# Straumr Widget — Fejlfindingslogbog

Formål: Dokumentere hvad der er prøvet, hvad der virker, og hvad der ikke virker,
så vi undgår at gentage fejlsøgning.

## Grundlæggende fakta (bekræftet)

| Faktum | Status |
|--------|--------|
| Widget RPM installerer uden fejl (v1.2.5+) | ✅ Virker |
| RPM har ingen `gtk-update-icon-cache` afhængighed (v1.2.5+) | ✅ Virker |
| JSON installeres på `/usr/share/lipstick/eventswidgets/harbour-straumr.json` | ✅ Virker |
| Widget vises i Indstillinger → Begivenheder som "Straumr" | ✅ Virker |
| **Simpel widget (rød boks) VIRKER når QML ligger i hovedappen** | ✅ **BEKÆFTET** (v0.9.4, v0.9.8, v1.0.4, v1.1.0) |
| Samme widget-kode som selvstændig RPM (QML i `/usr/share/harbour-straumr-widget/`) | ❌ Virker IKKE |
| Widget vises på Events View med selvstændig RPM | ❌ Virker IKKE |

## Centrale forskelle: v1.1.0 (virker) vs v1.2.x (virker ikke)

| Aspekt | v1.1.0 (virker) | v1.2.x (virker ikke) |
|--------|-----------------|----------------------|
| **QML sti** | `/usr/share/harbour-straumr/qml/eventsview/` | `/usr/share/harbour-straumr-widget/qml/eventsview/` |
| **QML installeret af** | Hovedapp RPM (harbour-straumr) | Widget RPM (harbour-straumr-widget) |
| Widget-pakke `Requires:` | `harbour-straumr >= 1.1.0` | Ingen |
| JSON `path` | `/usr/share/harbour-straumr/qml/eventsview/PriceWidget.qml` | `/usr/share/harbour-straumr-widget/qml/eventsview/PriceWidget.qml` |
| JSON `available_path` | `/usr/share/harbour-straumr/qml/eventsview/PriceWidget.qml` | `/usr/share/harbour-straumr-widget/qml/eventsview/PriceWidget.qml` |

## Hovedhypotese (H1) — MEST SANNSYNLIG

**Lipstick kan kun loade widget-QML fra `/usr/share/harbour-straumr/` (eller en sti
registreret via libsailfishapp), ikke fra en vilkårlig `/usr/share/harbour-straumr-widget/`.**

Begrundelse:
- libsailfishapp tilføjer automatisk `/usr/share/<HARBOUR_APP_NAME>` til QML import path
- Lipstick kører i SailJail/sandbox — måske begrænset adgang til ikke-standard stier
- Alle bekræftede succeser har haft QML under `/usr/share/harbour-straumr/`

## Løsningsforslag (H1-løsning)

**Widget RPM installerer QML til `/usr/share/harbour-straumr/qml/eventsview/` — uden at `Require:` hovedappen.**

- Widget RPM er stadig selvstændig (kan installeres uden hovedappen)
- QML ligger på den "standard" harbour-sti som Lipstick kan læse
- Hvis hovedappen også installeres senere, vil der være fil-konflikt — men det kan løses med `%ghost` eller ved at hovedappen ikke længere installerer widget-QML

## Versionsoversigt

| Version | Ændring | Resultat |
|---------|---------|----------|
| v0.9.4 | DEBUG rød boks, QML i hovedapp | ✅ Virker |
| v0.9.8 | DEBUG Loader→Item→Rectangle, QML i hovedapp | ✅ Virker |
| v1.0.4 | Fuld widget, QML i hovedapp | ✅ Virker |
| v1.1.0 | Widget RPM = JSON kun, `Requires: harbour-straumr`, QML i hovedapp | ✅ Virker |
| v1.2.0 | Widget selvstændig RPM, QML i `/usr/share/harbour-straumr-widget/` | ❌ gtk-update-icon-cache fejl |
| v1.2.1–v1.2.4 | Forsøg på at fjerne gtk-update-icon-cache afhængighed | ❌ Samme fejl |
| v1.2.5 | Fjern ikon fra RPM | ✅ Installerer, ❌ widget vises ikke |
| v1.2.6 | Fjern `available_path`, tilføj `%post` dconf write | ❌ Widget vises ikke, ❌ ingen toggle |
| v1.2.7 | Gendan `available_path` | ❌ Widget vises ikke |
| v1.3.0 | DEBUG simpel rød boks, QML stadig i `/usr/share/harbour-straumr-widget/` | ⏳ Ikke testet (oversprunget) |
| v1.4.0 | H1 TEST: QML installeret til `/usr/share/harbour-straumr/qml/eventsview/`, stadig rød boks | ❌ **Rød boks vises IKKE** — H1 AFKRÆFTET |
| v1.5.0 | H2 TEST: `Requires: harbour-straumr` tilføjet, QML på `/usr/share/harbour-straumr/`, stadig rød boks | ❌ **Rød boks vises IKKE** — H2 AFKRÆFTET |
| v1.3.0/v1.6.0 | H6 TEST: Hovedapp installerer QML via libsailfishapp, widget-RPM = kun JSON, `Requires: harbour-straumr >= 1.3.0`. Lipstick genstartet. Fuld reboot testet. | ❌ **Rød boks vises IKKE** — H6 OG H7 AFKRÆFTET |
| v1.3.0/v1.7.0 | H10 TEST: **Nøjagtig kopi af v1.1.0** — Loader wrapper, fuld PriceWidgetContent (230 linjer), icon i JSON, ingen %post, ingen makroer. Kun versionsnumre forskellige. | ❌ **Widget vises IKKE** — H10 AFKRÆFTET |

## H1, H2 OG H6 AFKRÆFTET — Sti, Requires OG "hvem installerer QML" er IKKE problemet

v1.4.0: QML på `/usr/share/harbour-straumr/qml/eventsview/` uden Requires → ❌
v1.5.0: QML på `/usr/share/harbour-straumr/qml/eventsview/` MED `Requires: harbour-straumr` → ❌
v1.3.0/v1.6.0: **Præcis v1.1.0 struktur** — hovedapp installerer QML via libsailfishapp,
  widget-RPM = kun JSON, `Requires: harbour-straumr >= 1.3.0` → ❌ **Rød boks vises IKKE**

**KRITISK KONKLUSION:** v1.3.0/v1.6.0 er **100% identisk** med v1.1.0 strukturen
(som virkede!), men rød boks vises stadig ikke. Der er noget fundamentalt anderledes
mellem "det der virkede i går" (v1.1.0) og "det der ikke virker i dag".

Mulige årsager:
- **Lipstick cache/dconf tilstand** på enheden er ændret siden v1.1.0
- **Fuld reboot nødvendig** (ikke kun `systemctl --user restart lipstick`)
- **System opdatering** på telefonen siden v1.1.0 test
- **QML import path** ændret — måske skal der tilføjes noget til JSON
- **SailJail rettigheder** — Lipstick kører sandboxed og QML-filen skal måske
  ligge et specifikt sted ift. sandbox-konfigurationen

## Nye hypoteser

### H2: `Requires: harbour-straumr` er nødvendig
- **Begrundelse:** Måske tjekker EventsWidgetsModel om pakken der ejer QML-filen
  er installeret, eller måske er der en sikkerheds/sandbox-begrænsning
- **Løsning:** Tilføj `Requires: harbour-straumr` til widget-RPM (tilbage til v1.1.0)
- **Konsekvens:** Widget kan ikke installeres uden hovedappen — men det er måske OK
- **Status:** ❌ **AFKRÆFTET** (v1.5.0) — rød boks vises stadig ikke selv med
  `Requires: harbour-straumr` og hovedappen installeret

### H3: `%post` scriptlet kører ikke korrekt
- **Begrundelse:** Måske kører `su --login` ikke, eller dconf write fejler stille
- **Test:** Manuel `dconf write` efter installation
- **Status:** Brugeren har allerede testet manuel dconf write — virkede ikke

### H4: Lipstick cacher widget-listen og genlæser ikke
- **Begrundelse:** Måske skal Lipstick genstartes på en bestemt måde
- **Test:** `systemctl --user restart lipstick` (allerede gjort)
- **Alternativ test:** Full reboot

### H5: JSON struktur mangler noget
- **Begrundelse:** System widgets har `translation_catalog` og `translation_id`
- **Test:** Tilføj disse felter til JSON
- **Status:** Ikke testet

### H6: Widget-RPM må IKKE installere QML — kun hovedapp-RPM må gøre det
- **Status:** ❌ **AFKRÆFTET** (v1.3.0/v1.6.0) — præcis v1.1.0 struktur testet,
  rød boks vises stadig ikke selv efter Lipstick genstart

### H7: Fuld reboot af telefonen er nødvendig
- **Begrundelse:** Måske cacher Lipstick widget-listen ved boot, ikke ved
  `systemctl --user restart lipstick`. Eller dconf/systemd-tjenester skal
  genindlæses ved fuld boot
- **Løsning:** Genstart hele telefonen efter installation
- **Status:** Ikke testet endnu

### H8: Lipstick kører i SailJail og kan ikke læse `/usr/share/harbour-straumr/`
- **Begrundelse:** Selvom stien er korrekt, kører Lipstick sandboxed.
  Måske skal QML ligge i en sti der er eksplicit tilladt for Lipstick's sandbox
- **Løsning:** Undersøg Lipstick's SailJail-konfiguration. System widgets ligger
  i `/usr/share/lipstick-jolla-home-qt5/eventsview/` — måske skal vores widget
  også ligge under `/usr/share/lipstick-jolla-home-qt5/`?
- **Status:** Ikke testet

### H9: dconf nøgle er ikke sat korrekt
- **Begrundelse:** `events_screen_widgets` skal indeholde vores widget-sti.
  Måske er der forskel på hvordan Lipstick læser den vs. hvad vi skriver
- **Test:** `dconf read /desktop/lipstick-jolla-home/events_screen_widgets`
  efter installation, og sammenlign med v1.1.0
- **Status:** Ikke testet i denne session

### H10: Sammenlign RPM-indhold mellem v1.1.0 og v1.3.0
- **Begrundelse:** Måske er der en lille forskel i hvordan RPM'erne er bygget
  (f.eks. fil-rettigheder, timestamps, eller en manglende fil)
- **Løsning:** Download v1.1.0 RPM'er og sammenlign med `rpm -qlp` og
  `rpm -qip` output
- **Status:** Ikke testet

## ALLE HYPOTESER AFKRÆFTET: H1-H2-H6-H7-H10-H11-H15

v1.7.0 er **100% identisk** med v1.1.0 i kode og struktur.

**OG: v1.1.0 RPM'erne (dem der virkede i går) virker heller ikke længere!**

### H11: v1.1.0 testet igen — AFKRÆFTET ❌
- Samme RPM'er som virkede i går
- Afinstalleret alt, geninstalleret v1.1.0
- **Widget vises stadig ikke**

### VERIFICERING PÅ ENHED (alle ✅ korrekte):

| Check | Resultat |
|-------|----------|
| `rpm -qa \| grep straumr` | ✅ `harbour-straumr-1.1.0` + `harbour-straumr-widget-1.1.0` installeret |
| `ls /usr/share/harbour-straumr/qml/eventsview/` | ✅ PriceWidget.qml (221 bytes) + PriceWidgetContent.qml (8704 bytes) findes |
| `cat harbour-straumr.json` | ✅ Korrekt JSON med path, available_path, icon, default_enabled |
| `cat PriceWidget.qml` | ✅ Korrekt Loader wrapper (ikke rød boks) |
| Indstillinger → Begivenheder | ✅ Straumr vises med toggle, kan slås til |
| Lipstick version | `lipstick-jolla-home-qt5-1.27.18-1.56.1.jolla.aarch64` |

### H15: Manuel dconf write — KØRT, MEN VIRKER IKKE ❌
- **Før write:** dconf pegede på gammel sti `/usr/share/harbour-straumr-widget/...`
- **Efter write:** dconf peger korrekt på `/usr/share/harbour-straumr/qml/eventsview/PriceWidget.qml`
- **Resultat:** Widget vises **stadig ikke** efter dconf write + Lipstick restart

### KRITISK KONKLUSION:
**Alt er korrekt konfigureret på enheden:**
- ✅ RPM'er installeret
- ✅ QML-filer findes på korrekt sti
- ✅ JSON korrekt
- ✅ dconf peger på korrekt sti
- ✅ Toggle i Indstillinger er slået til
- ✅ Lipstick genstartet

**MEN widget vises stadig ikke på Events View.**

Dette peger på et dybere problem — måske:
- Lipstick loader QML i en sandbox der ikke kan tilgå `/usr/share/harbour-straumr/`
- Der er en QML-fejl der ikke vises nogen steder (ingen logs tilgængelige)
- Sailfish OS 5.2.0.15 har ændret hvordan Events View widgets fungerer
- Der mangler en eller anden registrering ud over JSON + dconf

### H20: QML i Lipstick's egen mappe — AFKRÆFTET ❌
- QML kopieret til `/usr/share/lipstick-jolla-home-qt5/eventsview/`
- JSON opdateret til samme sti
- dconf opdateret til samme sti
- Lipstick genstartet
- **Widget vises stadig ikke**

### H21: Systemopdatering fundet! 🔴
Screenshot viser: **"Opdatering til Finlayson 5.2.0.20 — 1 minut siden"**
Telefonen er blevet opdateret fra **5.2.0.15 → 5.2.0.20**!

Dette er sandsynligvis årsagen til at widgetten stoppede med at virke.
Jolla har måske ændret hvordan Events View widgets fungerer i 5.2.0.20.

### H25: KALENDER-WIDGET VIRKER IKKE HELLER! 🔴🔴
Screenshot af Events View viser KUN notifikationer (Påmindelser):
- Sailfish OS (systemopdatering)
- Sikkerhedskopi
- System (screenshots)

**Ingen kalender-widget. Ingen vejr-widget. Ingen widgets overhovedet!**

Dette betyder: **Problemet er IKKE specifikt for Straumr.**
**Alle Events View widgets er væk efter opdateringen til 5.2.0.20.**

## NYE NÆSTE SKRIDT (prioriteret)

1. **H26: Genaktiver system widgets** — gå til Indstillinger → Begivenhedsvisning
   og slå Kalender og Vejr til igen. Måske blev de deaktiveret ved opdateringen.

2. **H27: Verificer dconf efter opdatering** — måske har opdateringen nulstillet
   `events_screen_widgets`:
   ```
   dconf read /desktop/lipstick-jolla-home/events_screen_widgets
   ```

3. **H28: Søg efter Sailfish OS 5.2.0.20 changelog** — hvad er ændret i
   Events View / Lipstick i denne version?

4. **H29: Kontakt Jolla/Sailfish community** — "Events View widgets forsvandt
   efter opdatering til 5.2.0.20"

5. **H30: Vent på 5.2.0.21** — måske er det en bug der bliver fixet

## Gamle næste skridt (stadig relevante hvis ovenstående ikke hjælper)

6. **H22: Prøv at downgrade** — ikke praktisk på en produktionstelefon

7. **H23: Kontakt Sailfish OS community**

8. **H24: Alternativ tilgang — brug en anden widget-type**
   Måske compositor widgets eller cover widgets i stedet for Events View

## Scripts og værktøjer

### install-v1.3.0.sh
Kun til download — kører IKKE `devel-su` (hænger på kodeord).
Bruger skal selv køre `pkcon install-local` bagefter.

### Skoðja's update-script (reference)
Håndterer kodeord ved at bruge Sailfish OS' indbyggede godkendelsesdialog
("Bekræft med sikkerhedskode" / "Venter på godkendelse"). Dette er Sailfish's
`pkcon` der viser en GUI-dialog — ikke noget scriptet selv gør.

## Kendte Sailfish OS detaljer

- libsailfishapp tilføjer `/usr/share/<HARBOUR_APP_NAME>` til QML import path automatisk
- Lipstick kører som `defaultuser` i SailJail
- Events View widgets loades via `Loader { active: model.enabled; source: model.path }`
- `model.enabled` kommer fra dconf `events_screen_widgets`
- `model.available` afhænger af `available_path` — filen skal eksistere

## GENNEMBRUD: v1.8.0 (2026-10-22)

### H26: Vejrwidget VIRKER — systemopdatering er IKKE årsagen
- Bruger bekræftede at MET Norway/Yr vejrwidget fungerer fint på Events View
- Screenshot viste 10° i Roskilde med timeprognose
- **Konklusion:** Events View widgets virker på 5.2.0.20. Problemet er specifikt Straumr.

### H27: ROOT CAUSE — split packaging
- Research af fungerende tredjeparts-widgets på SFOS 5.x:
  - **Admirality** (Pauligrinder, v0.2.10): Én RPM installerer BÅDE JSON og QML
  - **Events View Custom Text** (Okxa, OpenRepos): Én RPM, `noarch`, JSON + QML sammen
  - **Sahkonseuranta** (Zesseth): Split packaging nævnt som workaround for 4.6 (som har ingen loader)
- Straumr brugte **split packaging** (separat companion-RPM `harbour-straumr-widget` kun til JSON)
- **Alle v1.2.0–v1.7.0 fejlede fordi JSON og QML var i forskellige RPM'er**
- Selv v1.1.0 (som virkede før) stoppede med at virke — sandsynligvis fordi bruger installerede den gamle widget-RPM som ikke længere matchede

### H28: FIX — single RPM packaging (Admirality pattern)
- `harbour-straumr.pro` tilføjet `INSTALLS += eventsWidgetQml eventsWidgetJson`
- QML installeres til `/usr/share/harbour-straumr/qml/eventsview/`
- JSON installeres til `/usr/share/lipstick/eventswidgets/harbour-straumr.json`
- Hoved-RPM'en (`rpm/harbour-straumr.yaml`) inkluderer nu `%{_datadir}/lipstick/eventswidgets/%{name}.json`
- **Companion widget-RPM fjernet** (`widget/rpm/` slettet, `build-widget` CI job fjernet)
- `PriceWidget.qml` omskrevet: `Item` root med `implicitHeight`, `active` gate, `refresh()`/`reload()`/`save()`
- `PriceWidgetContent.qml`: sekventiel tariff-fetch (undgår rate limiting), `FALLBACK_NETTARIF` hardcoded Radius vinter 2026 værdier

### Widget-kontrakt (fra Pauligrinder's dokumentation)
- QML skal have `refresh()`, `reload()`, `save()` funktioner
- Root item skal rapportere korrekt `implicitHeight`
- Widget kører i Lipstick-processen (ikke app-processen)
- `available_path` "is usually not needed for third-party widgets"
- JSON kan inkludere `translation_catalog`, `description_id`, `translation_id`

### Lektie
> **På SFOS 5.x skal Events View widgets pakkes i SAMME RPM som app'en.**
> Split packaging (separat widget-RPM) virker ikke på 5.2.
> Følg Admirality/Okxa pattern: én RPM, `INSTALLS` i .pro filen.

---

## v1.8.0 FEJLSLAGET — stadig ingen widget (2026-10-22)

Bruger installerede v1.8.0 (single RPM packaging) men widget vises STADIG ikke.

### H29: Detaljeret sammenligning med Admirality
Grundig sammenligning af Straumr vs Admirality (arbejdende widget) afslørede flere kritiske forskelle:

| Aspekt | Admirality (virker) | Straumr v1.8.0 (virker ikke) |
|--------|---------------------|------------------------------|
| **QML install sti** | `/usr/share/harbour-admirality/eventsview/` | `/usr/share/harbour-straumr/qml/eventsview/` |
| **Loader wrapper** | Ingen — indhold direkte i `Item` root | `Loader { source: PriceWidgetContent.qml }` |
| **active property** | `visible && eventsViewVisible` | `visible && (typeof eventsViewVisible !== "undefined" ? eventsViewVisible : true)` |
| **height** | `Math.max(column.height, Theme.itemSizeMedium)` | `content.implicitHeight` (via Loader) |
| **Timer** | `interval: 30000, running: root.active` | Ingen |
| **PriceWidgetContent** | — | Separat fil (extra QML load step) |

### H30-H34: FIX — match Admirality præcist (v1.9.0)
1. **Fjernet Loader wrapper** — alt indhold nu direkte i `PriceWidget.qml` `Item` root
2. **Flyttet QML-sti** — fra `/usr/share/harbour-straumr/qml/eventsview/` til `/usr/share/harbour-straumr/eventsview/` (matcher Admirality)
3. **Fikset active property** — `visible && eventsViewVisible` uden `typeof` check
4. **Tilføjet height floor** — `Math.max(column.height + padding*2, Theme.itemSizeMedium)`
5. **Slettet PriceWidgetContent.qml** — én fil, ingen ekstra QML load
6. **Tilføjet Timer** — auto-refresh hver 5. minut når aktiv
7. **Opdateret JSON path** — `/usr/share/harbour-straumr/eventsview/PriceWidget.qml`
8. **Opdateret .pro** — `eventsWidgetQml.path = /usr/share/harbour-straumr/eventsview`

### H35: Hypoteser hvis v1.9.0 stadig fejler
- **H35a**: Lipstick cacher widget-listen — måske skal `lipstick` genstartes (ikke bare telefonen)
- **H35b**: JSON skal måske have `translation_catalog` field (Admirality har det)
- **H35c**: Widget QML skal måske importere `org.nemomobile.lipstick 0.1` for at få `eventsViewVisible`
- **H35d**: `eventsViewVisible` er måske ikke defineret — Lipstick sætter den måske kun på system widgets
- **H35e**: Måske skal widget QML ligge i `/usr/share/lipstick-jolla-home-qt5/eventsview/` i stedet

### Næste skridt
Test v1.9.0 på enheden. Hvis stadig ikke virker, prøv H35a-e.

---

## v1.9.0 FEJLSLAGET — stadig ingen widget (2026-10-22)

Bruger installerede v1.9.0 (matchet Admirality pattern) men widget vises STADIG ikke.

### H36: Tilfojet omfattende logning (v1.9.1)
- Alle livscyklus-faser logger nu med `[Straumr-Widget]` prefix
- Component.onCompleted, onVisibleChanged, onActiveChanged, onWidthChanged, onHeightChanged
- Alle HTTP kald logger URL, status, record count, fejl
- Tariff-beregning logger hver komponent og slutpris
- Debug info vist direkte i widget: w=XXX h=XXX vis=true act=true evv=undef
- Rod kant omkring widget (synlig hvis den loades)
- Se logs: journalctl -f | grep "[Straumr-Widget]"

### H37: Fjernet eventsViewVisible dependency
- Tidligere: property bool active: visible && eventsViewVisible
- Problem: eventsViewVisible kan vaere undefined for tredjeparts-widgets
- Ny: property bool active: visible — simplere, faerre fejl
- Debug label viser om eventsViewVisible er defineret

### H38: Ny debug-widget.sh — kor pa telefonen
- Tjekker 11 ting: RPM installeret, JSON findes, QML findes, fil-stier,
  dconf-indstillinger, gammel widget-RPM, JSON validitet, journalctl logs,
  lipstick logs, proces status, netvaerkstest
- Brug: curl -LO .../debug-widget.sh && sh debug-widget.sh

### H39: Mulige arsager hvis v1.9.1 viser rod boks men ingen data
- Hvis rod boks vises: Widget QML loades korrekt, men data-fetch fejler
  -> Tjek journalctl -f | grep Straumr-Widget for HTTP fejl
  -> Lipstick kører maaske uden Internet permission (SailJail?)
- Hvis ingen rod boks: Widget loades slet ikke af Lipstick
  -> JSON ikke laest, eller QML path forkert, eller widget ikke aktiveret

### H40: Naeste diagnostiske skridt
1. Installer v1.9.1
2. Kør debug-widget.sh pa telefonen — del output
3. Kør journalctl -f | grep "[Straumr-Widget]" i en terminal
4. Stryg til venstre — hvad logges?
5. Del hvad du ser (rod boks? ingen boks? log-linjer?)

---

## v1.9.1 opdatering — lipstick-genstart i stedet for telefon-genstart (2026-10-22)

### H41: Opdateringsskript genstarter nu kun lipstick
- Tidligere: Brugeren skulle genstarte HELE telefonen efter installation
- Problem: Telefon-genstart er langsom og unødvendig — widget-konfiguration læses af lipstick
- Ny: `systemctl --user restart lipstick` i skriptet (2-5 sekunder, skærmen blinker kort)
- Tilføjet `--no-restart` flag hvis man vil springe over
- Standard-version opdateret til 1.9.1
- Hvis lipstick-genstart fejler, får brugeren besked om at køre den manuelt

---

### H42: pkcon godkendelses-popup fejlede (2026-10-22)
- Bruger fik "Fatal fejl: Failed to obtain authentication"
- Årsag: pkcon's popup-dialog til sikkerhedskode dukkede ikke op / blev ikke besvaret
  når skriptet kørte i baggrunden via curl-pipeline
- Fix: pkcon install-local køres nu med bedre instruktioner og baggrundshåndtering
- Hvis det stadig fejler: kør manuelt `pkcon install-local /tmp/harbour-straumr-*.rpm`
  så kommer popup'en garanteret frem

---

### H43: pkcon popup virker ikke fra curl-piped script (2026-10-22)
- Bruger fik igen "Failed to obtain authentication" selv med baggrundshåndtering
- Årsag: Sailfish OS' polkit-agent (sikkerhedskode-popup) kan ikke vise GUI
  når kommandoen køres fra et curl-piped shell script uden korrekt session
- Løsning: Skriptet downloader nu kun RPM'en til /tmp/ og viser instruktioner
- Brugeren skal åbne Terminal-appen og køre pkcon install-local manuelt
  hvor popup'en virker normalt

---

### H44: Skiftet fra pkcon til devel-su + rpm (2026-10-22)
- pkcon's polkit-popup virker ikke fra curl-piped scripts (H43)
- Løsning: Brug `devel-su rpm -Uvh` i stedet — beder om kode i terminalen
- Ingen popup nødvendig — kode indtastes direkte i shell
- Hele flowen er nu én kommando uden manuel indgriben
- Fjernelse af gammel widget-RPM også via `devel-su rpm -e`

---

### H45: journalctl adgangsproblemer + grep regex (2026-10-22)
- `journalctl -f` som normal bruger: "insufficient permissions" — ser kun egne logs
- `devel-su journalctl -f | grep "[Straumr-Widget]"`: grep tolker [] som regex!
- Løsning: Brug `grep -F "Straumr-Widget"` (fast string, ingen regex)
- Eller: `devel-su journalctl -f | grep Straumr` (uden specialtegn)
- Debug-script opdateret med korrekte kommandoer (trin 12-15)

---

### H46: Baggrundsjob stoppet af tty output (2026-10-22)
- `devel-su journalctl -f | grep Straumr > /tmp/file 2>&1 &` stoppes med "Stopped (tty output)"
- Årsag: devel-su beder om password på tty, men jobbet kører i baggrunden uden tty adgang
- Løsning: Brug `devel-su -c "kommando"` så password prompt går til samme terminal,
  eller kør uden baggrund (&) og brug Ctrl+C til at stoppe
- Alternativ: devel-su journalctl --no-pager -n 100 | grep Straumr (ikke -f, ingen live)

---

### H47: INGEN Straumr logs i journalctl — widget QML loades aldrig (2026-10-22)
- `devel-su journalctl --no-pager -n 200 | grep Straumr` returnerer TOMT
- Dette er KRITISK: Det betyder at PriceWidget.qml ALDRIG er blevet loaded af lipstick
- Widget QML kører i lipstick-processen, så dens console.log går til lipstick's journal
- Hvis der ikke er NOGET output, er årsagen en af:
  a) JSON-deskriptoren er ikke læst (forkert sti, ugyldig JSON, lipstick ikke genstartet)
  b) Widget er ikke aktiveret i dconf (events_screen_widgets)
  c) Widget er ikke tilføjet i EventsWidgetsModel (Indstillinger → Begivenhedsvisning)
  d) Lipstick cacher widget-listen og skal genstartes
  e) QML path i JSON peger på en fil der ikke findes
- Næste skridt: Kør debug-widget.sh for at tjekke alle disse punkter systematisk

---

## v1.9.2 — ROOT CAUSE ENDELIGT FUNDET! (2026-10-22)

### H48: DUPLIKAT QML-FIL — libsailfishapp installerer til forkert sti
- Brugerens dconf viste BÅDE:
  - `/usr/share/harbour-straumr/qml/eventsview/PriceWidget.qml` (gammel sti)
  - `/usr/share/harbour-straumr/eventsview/PriceWidget.qml` (ny sti)
- Årsag: `qml/eventsview/PriceWidget.qml` var i DISTFILES
- libsailfishapp (CONFIG += sailfishapp) installerer automatisk DISTFILES QML
  til `/usr/share/<name>/` bevarende sti → `/usr/share/harbour-straumr/qml/eventsview/`
- Vores custom INSTALLS installerede SAMME fil til `/usr/share/harbour-straumr/eventsview/`
- Resultat: To forskellige kopier af PriceWidget.qml på forskellige stier!
- Lipstick læste sandsynligvis den gamle kopi (uden logging) fra qml/eventsview/

### H49: dconf var også rodet — stray entries fra tidligere tests
- dconf havde `/usr/share/lipstick-jolla-home-qt5/eventsview/PriceWidget.qml` (H15 test)
- Den fil findes ikke længere — lipstick fejler stille på den
- Også to Straumr entries (gammel + ny sti)

### H50: FIX — match Admirality struktur præcist (v1.9.2)
- Flyttet `qml/eventsview/PriceWidget.qml` → `eventsview/PriceWidget.qml` (root niveau)
- Flyttet `widget/eventswidgets/harbour-straumr.json` → `eventsview/harbour-straumr.json`
- Opdateret .pro: DISTFILES bruger `eventsview/PriceWidget.qml` (ikke qml/eventsview/)
- libsailfishapp installerer nu til `/usr/share/harbour-straumr/eventsview/PriceWidget.qml`
- Samme sti som JSON peger på — ingen duplikat!
- Fjernet custom eventsWidgetQml INSTALLS (ikke længere nødvendig — DISTFILES håndterer det)
- Tilføjet fix-dconf.sh til at rense dconf og fjerne gamle filer

### H51: Systemfiler i eventswidgets/ — IKKE et problem
- `/usr/share/lipstick/eventswidgets/` indeholder også:
  - `eventswidgets.json` (599 bytes, system — kalender widget?)
  - `weatherwidget.json` (585 bytes, system — vejr widget)
- Disse er SYSTEM-filer, ikke tredjeparts. Lipstick læser alle *.json i mappen.
- Vores `harbour-straumr.json` ligger alongside — korrekt.

### Lektie
> **Med `CONFIG += sailfishapp` installerer libsailfishapp automatisk ALLE QML-filer
> i DISTFILES til `/usr/share/<app>/` (bevarende sti). Hvis widget QML ligger under
> `qml/eventsview/`, ender den på `/usr/share/<app>/qml/eventsview/` — ikke
> `/usr/share/<app>/eventsview/`. For at undgå duplikater: læg widget QML på
> root-niveau (`eventsview/`) som Admirality gør.**
