# Straumr Widget — Fejlfindingslogbog

Formål: Dokumentere hvad der er prøvet, hvad der virker, og hvad der ikke virker,
så vi undgår at gentage fejlsøgning.

## Grundlæggende fakta (bekræftet)

| Faktum | Status |
|--------|--------|
| Widget RPM installerer uden fejl (v1.2.5+) | ✅ Virker |
| RPM har ingen `gtk-update-icon-cache` afhængighed (v1.2.5+) | ✅ Virker |
| JSON installeres på `/usr/share/lipstick/eventswidgets/harbour-straumr.json` | ✅ Virker |
| QML-filer installeres på `/usr/share/harbour-straumr-widget/qml/eventsview/` | ✅ Virker |
| Widget vises i Indstillinger → Begivenheder som "Straumr" | ✅ Virker (v1.2.5+) |
| Widget har kontakt (toggle) i Indstillinger | ❓ Ukendt — skal testes med debug-version |
| Widget vises på Events View (stryg til venstre) | ❌ Virker IKKE |
| Samme widget-kode virker når den pakkes sammen med hovedappen (v1.1.0) | ✅ Virker |
| Samme widget-kode som selvstændig RPM (v1.2.x) | ❌ Virker IKKE |

## Centrale forskelle: v1.1.0 (virker) vs v1.2.x (virker ikke)

| Aspekt | v1.1.0 (virker) | v1.2.x (virker ikke) |
|--------|-----------------|----------------------|
| QML sti | `/usr/share/harbour-straumr/qml/eventsview/` | `/usr/share/harbour-straumr-widget/qml/eventsview/` |
| QML i pakke | Hovedapp (harbour-straumr) | Separat widget-pakke (harbour-straumr-widget) |
| JSON i pakke | Separat widget-pakke | Separat widget-pakke |
| Widget-pakke `Requires:` | `harbour-straumr >= 1.1.0` | Ingen |
| `icon` i JSON | `/usr/share/icons/hicolor/86x86/apps/harbour-straumr.png` | Fjernet (v1.2.5+) |
| `available_path` i JSON | `/usr/share/harbour-straumr/qml/eventsview/PriceWidget.qml` | `/usr/share/harbour-straumr-widget/qml/eventsview/PriceWidget.qml` |
| QML importer | `import "../components"` etc. (relative til app) | Kun `import QtQuick` + `import Sailfish.Silica` |

## Hypoteser (ikke bekræftet)

### H1: Lipstick kan ikke læse QML uden for `/usr/share/harbour-straumr/`
- **Begrundelse:** SailJail/sandbox kan begrænse Lipsticks adgang til QML-filer
- **Test:** Debug-widget (v1.3.0) med simpel Rectangle
- **Status:** Afventer test

### H2: `events_screen_widgets` dconf nøglen overskriver ikke korrekt
- **Begrundelse:** `%post` scriptlet kører måske ikke, eller Lipstick cacher værdien
- **Test:** Manuel `dconf write` + genstart
- **Status:** Testet manuelt — virker ikke

### H3: Widget QML fejler ved load (silent failure)
- **Begrundelse:** QML syntax error, manglende import, eller runtime error
- **Test:** Debug-widget uden kompleks logik
- **Status:** Afventer test (v1.3.0)

### H4: `onlyUserConfigurable` eller anden model-filter skjuler widgetten
- **Begrundelse:** EventsWidgetsModel i EventsViewList.qml bruger `onlyUserConfigurable: false`, men måske er der andre filtre
- **Test:** Sammenligne med v1.1.0 hvor det virkede
- **Status:** Ikke undersøgt

## Versionsoversigt

| Version | Ændring | Resultat |
|---------|---------|----------|
| v1.1.0 | Widget som del af hovedapp + separat JSON-RPM | ✅ Virker |
| v1.2.0 | Widget selvstændig RPM (JSON+QML+ikon) | ❌ gtk-update-icon-cache fejl |
| v1.2.1 | AutoReq=no/AutoProv=no | ❌ Samme fejl |
| v1.2.2 | `__requires_exclude` makro | ❌ Samme fejl |
| v1.2.3 | `__scriptlet_requires() %{nil}` | ❌ Samme fejl |
| v1.2.4 | `%global __os_install_post %{nil}` | ❌ Samme fejl |
| v1.2.5 | Fjern ikon fra RPM | ✅ Installerer, ❌ widget vises ikke |
| v1.2.6 | Fjern `available_path`, tilføj `%post` dconf write | ❌ Widget vises ikke, ❌ ingen toggle i Indstillinger |
| v1.2.7 | Gendan `available_path` | ❌ Widget vises ikke (ikke testet endnu?) |
| v1.3.0 | DEBUG: Simpel rød boks, ingen Loader/Content | ⏳ Afventer test |

## Næste skridt

1. **Test v1.3.0** — hvis rød boks vises, er problemet i widget-QML'en
2. **Hvis rød boks IKKE vises** — problemet er i RPM/JSON-strukturen:
   - Tjek om Lipstick faktisk læser JSON'en (tilføj `translation_catalog` som system widgets)
   - Tjek om QML-stien er sand
   - Overvej at pakke QML under `/usr/share/harbour-straumr/` selvom det er en separat RPM
3. **Sammenlign med et virkende eksempel** — f.eks. Sahkonseuranta eller Helmsman

## Kendte Sailfish OS detaljer

- Lipstick kører som `defaultuser`, ikke root
- Events View widgets loades via `Loader { active: model.enabled; source: model.path }`
- `model.enabled` kommer fra dconf `events_screen_widgets`
- `model.available` afhænger af `available_path` — filen skal eksistere
- System widgets har `translation_catalog` og `translation_id` i JSON
- Vores widget har kun `title` (plain text, ikke lokaliseret)
