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

## ALLE KODE-HYPOTESER AFKRÆFTET: H1-H2-H6-H7-H10

v1.7.0 er **100% identisk** med v1.1.0 i kode og struktur:
- Samme Loader wrapper i PriceWidget.qml
- Samme fuld PriceWidgetContent.qml (230 linjer)
- Samme JSON med icon
- Samme widget spec uden %post og uden makroer
- Samme .pro med qml/eventsview/ i DISTFILES
- Samme yaml struktur

**Kun versionsnumrene er forskellige** (1.1.0 vs 1.3.0/1.7.0).

**MEN: Widget vises stadig ikke.**

Dette betyder: **Problemet er IKKE i koden.** Problemet er enten:
1. **På enheden** — dconf tilstand, Lipstick cache, eller systemændring siden v1.1.0
2. **I build-miljøet** — forskellige CI runners, forskellige SDK versioner
3. **I installationsprocessen** — noget brugeren gør anderledes nu vs. dengang

## Næste skridt (prioriteret)

1. **H11: Installer v1.1.0 RPM'er igen** — gå tilbage til præcis det der virkede.
   Hvis v1.1.0 STADIG virker, så sammenlign hvad der er anderledes på enheden nu.
   Hvis v1.1.0 IKKE længere virker → enheden er ændret (systemopdatering?).

2. **H12: Verificer på enheden** — kør disse kommandoer og send output:
   ```
   ls -la /usr/share/harbour-straumr/qml/eventsview/
   ```
   ```
   cat /usr/share/lipstick/eventswidgets/harbour-straumr.json
   ```
   ```
   dconf read /desktop/lipstick-jolla-home/events_screen_widgets
   ```
   ```
   rpm -qa | grep straumr
   ```

3. **H13: Sammenlign RPM-indhold byte-for-byte** — download v1.1.0 og v1.7.0
   RPM'er, udpak dem, og sammenlign filerne med `diff`

4. **H8: QML under `/usr/share/lipstick-jolla-home-qt5/eventsview/`**

5. **H9: Manuel dconf write** — sæt nøglen eksplicit efter installation

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
