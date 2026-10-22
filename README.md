# Straumr

En Sailfish OS-app der viser elpriser i begivenhedsvisningen (når man stryger til venstre).

Straumr viser **samlet elpris for Øst Danmark (DK2)** — inkl. nettarif, Energinet-tariffer, elafgift og moms — både på hovedsiden og i coveret når du stryger til venstre på hjemmeskærmen.

## Datakilder

- **Spotpriser**: [Energi Data Service](https://www.energidataservice.dk/) (Energinet), dataset `DayAheadPrices`, prisområde `DK2`, DKK/MWh. [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).
- **Tariffer**: Energinet DatahubPricelist — Systemtarif, Transmissions nettarif, Elafgift (Energinet GLN `5790000432752`) og Nettarif C (Radius Elnet GLN `5790000705689`).

Prisen beregnes som: `(spot + nettarif(time) + systemtarif + transmission + elafgift) × 1,25`

**Ekskluderet**: elselskabstillæg, netabo (fast månedligt abonnement), effektabonnement.

## Funktioner

- **Cover** (venstre-stryg): viser aktuel samlet pris kr/kWh inkl. tariffer og moms
- **Hovedside**: aktuel pris + liste over dagens 15-minutters priser med totalpris per kvarter
- **Automatisk opdatering** hver 15. minut
- **SailJail**: kører sandboxed med `Internet`-permission
- **Separation af data og visning**: nemt at tilføje nye grafiske repræsentationer

## Arkitektur

```
qml/
├── harbour-straumr.qml     # App-vindue, opretter PriceModel
├── js/
│   └── PriceFetcher.js     # Ren data + beregning (ingen UI)
├── models/
│   └── PriceModel.qml      # QtObject: henter data, eksponerer properties
├── components/
│   ├── PriceDisplay.qml    # Genbrugelig: stort tal + prisniveau
│   └── PriceList.qml       # Genbrugelig: liste over priser
├── pages/
│   └── MainPage.qml        # Hovedside (bruger PriceDisplay + PriceList)
└── cover/
    └── CoverPage.qml       # Cover (bruger PriceDisplay)
```

**PriceModel** er en `QtObject` der ejes af `ApplicationWindow` (`app.priceModel`). Alle sider og komponenter tilgår samme instans, så data hentes én gang og deles.

For at tilføje en ny visning (f.eks. en graf), opret en ny komponent i `qml/components/` der læser fra `app.priceModel`.

## SailJail (sandboxing)

App'en kører i SailJail med følgende permission:
- **Internet** — til at hente elpriser fra API'et

Data gemmes i `~/.local/share/io.github.storefyr/Straumr/` (sættes automatisk af libsailfishapp ud fra `[X-Sailjail]`-sektionen i .desktop-filen).

## Installation og opdatering

### Én kommando på telefonen

Kør dette på din Sailfish OS telefon for automatisk at hente og installere seneste version:

```bash
curl -LO https://raw.githubusercontent.com/storefyr/Straumr/vibe/straumr-hej-verden-8d2220/update-straumr.sh && sh update-straumr.sh
```

> **Bemærk:** Når PR #1 merges til `main`, skifter URL'en til `.../main/update-straumr.sh`.

Skriptet:
1. Fjerner gammel `harbour-straumr-widget` RPM hvis installeret
2. Henter seneste RPM fra [GitHub Releases](https://github.com/storefyr/Straumr/releases)
3. Installerer den (du skal godkende med sikkerhedskode)
4. Rydder op

**Genstart telefonen bagefter**, gå til **Indstillinger → Begivenhedsvisning** og slå **Straumr** til.

### Manuel installation

Download RPM'en til din telefon fra [Releases](https://github.com/storefyr/Straumr/releases):

| Fil | Til enhed |
|-----|-----------|
| `harbour-straumr-X.Y.Z-1.aarch64.rpm` | Jolla Phone 2026, Xperia 10 III/IV/V |
| `harbour-straumr-X.Y.Z-1.armv7hl.rpm` | Ældre telefoner (Jolla 1, C, Xperia X) |

```bash
devel-su
pkcon install local ~/Downloads/harbour-straumr-*-1.aarch64.rpm
```

### Events View widget

Fra v1.8.0 er widgetten **inkluderet i samme RPM** som app'en — ingen separat pakke nødvendig.



## Fejlfinding

Se loggen på telefonen:
```bash
journalctl -f | grep Straumr
```

## Bygning

Åbn `harbour-straumr.pro` i Sailfish SDK (Qt Creator), vælg et kit (f.eks. `SailfishOS-latest-aarch64` til Jolla Phone 2026 eller `-armv7hl`/`-i486` til ældre enheder/emulator) og kør. Vil du bygge en RPM-pakke til Harbour, vælg "Deploy as RPM package".

CI bygger automatisk RPM'er til `aarch64` og `armv7hl` ved hver `v*` tag.

## Struktur

- `src/harbour-straumr.cpp` — C++ entry point via `sailfishapp`
- `qml/harbour-straumr.qml` — app-vindue + PriceModel instans
- `qml/js/PriceFetcher.js` — datahentning + prisberegning (pure JS)
- `qml/models/PriceModel.qml` — delt datamodel (QtObject)
- `qml/components/` — genbrugelige UI-komponenter
- `qml/pages/MainPage.qml` — hovedside
- `qml/cover/CoverPage.qml` — cover til begivenhedsvisningen
- `rpm/` — packaging (yaml + spec) til Harbour
- `icons/` — app-ikoner i 86/108/128/172 px
