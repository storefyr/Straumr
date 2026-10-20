# Straumr

En Sailfish OS-app der viser elpriser i begivenhedsvisningen (når man stryger til venstre).

Dette er første babyskidt: app'en viser indtil videre kun "Hej verden".

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
