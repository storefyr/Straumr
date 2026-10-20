# Straumr

En Sailfish OS-app der viser elpriser i begivenhedsvisningen (når man stryger til venstre).

Straumr viser **elspotpriser for Øst Danmark (DK2)** — både på hovedsiden og i coveret når du stryger til venstre på hjemmeskærmen.

## Datakilde

Elpriser hentes fra [Energi Data Service](https://www.energidataservice.dk/) (Energinet), dataset `DayAheadPrices`, prisområde `DK2`. Data er underlagt [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/) — kilde: Energinet (www.energidataservice.dk).

Priserne er **spotpriser** (DKK/MWh, vist som øre/kWh) og dækker **ikke** moms, elafgift eller nettarif.

## Funktioner

- **Cover** (venstre-stryg): viser aktuel spotpris med farveindikator (grøn/gul/rød)
- **Hovedside**: aktuel pris + liste over dagens 15-minutters priser
- **Offline cache**: priser gemmes lokalt i SQLite via `QtQuick.LocalStorage`, så app'en virker uden net (opdateres hver 15. minut)
- **SailJail**: kører sandboxed med `Internet`-permission

## SailJail (sandboxing)

App'en kører i SailJail med følgende permission:
- **Internet** — til at hente elpriser fra API'et

Data gemmes i `~/.local/share/io.github.storefyr/Straumr/`, `~/.cache/...` og `~/.config/...`
(sættes automatisk af libsailfishapp ud fra `[X-Sailjail]`-sektionen i .desktop-filen).

## Bygning

Åbn `harbour-straumr.pro` i Sailfish SDK (Qt Creator), vælg et kit
(f.eks. `SailfishOS-latest-armv7hl` til en telefon eller `-i486` til emulatoren)
og kør. Vil du bygge en RPM-pakke til Harbour, vælg "Deploy as RPM package".

## Struktur

- `src/harbour-straumr.cpp` — C++ entry point via `sailfishapp`
- `qml/harbour-straumr.qml` — app-vindue
- `qml/pages/MainPage.qml` — første side ("Hej verden")
- `qml/cover/CoverPage.qml` — cover til begivenhedsvisningen
- `rpm/` — packaging (yaml + spec) til Harbour
- `icons/` — app-ikoner i 86/108/128/172 px
