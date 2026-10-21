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
| v1.4.0 | H1 TEST: QML installeret til `/usr/share/harbour-straumr/qml/eventsview/`, stadig rød boks | ⏳ Afventer test |

## Næste skridt

1. **Test v1.4.0** — rød boks med QML på standard harbour-sti:
   - Hvis rød boks **VISES** → H1 bekræftet! Problemet er stien. Gå til v1.5.0 med fuld widget på samme sti
   - Hvis rød boks **IKKE VISES** → H1 afkræftet. Problemet er noget andet (måske JSON struktur, %post scriptlet, eller Lipstick cache)
2. **Hvis H1 afkræftes:** Overvej at widget-RPM skal `Requires: harbour-straumr` (tilbage til v1.1.0 struktur)
3. **Alternativ:** Accepter at widget kræver hovedappen

## Kendte Sailfish OS detaljer

- libsailfishapp tilføjer `/usr/share/<HARBOUR_APP_NAME>` til QML import path automatisk
- Lipstick kører som `defaultuser` i SailJail
- Events View widgets loades via `Loader { active: model.enabled; source: model.path }`
- `model.enabled` kommer fra dconf `events_screen_widgets`
- `model.available` afhænger af `available_path` — filen skal eksistere
