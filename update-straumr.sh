#!/bin/sh
# Straumr opdateringsskript — kør på Sailfish OS telefonen
# Downloader seneste RPM og viser instruktioner til manuel installation.
#
# Brug (én kommando):
#   curl -LO https://raw.githubusercontent.com/storefyr/Straumr/main/update-straumr.sh && sh update-straumr.sh
#
# Valgfrit — angiv en specifik version:
#   sh update-straumr.sh 1.9.1
#
# Bemærk: Installation skal køres manuelt i Terminal-appen fordi
# pkcon's sikkerhedskode-popup ikke virker fra curl-piped scripts.

set -e

# --- Konfiguration ---
REPO="storefyr/Straumr"
DEFAULT_VERSION="1.9.1"
VERSION="${1:-${DEFAULT_VERSION}}"
ARCH="aarch64"
RPM_NAME="harbour-straumr-${VERSION}-1.${ARCH}.rpm"
DOWNLOAD_URL="https://github.com/${REPO}/releases/download/v${VERSION}/${RPM_NAME}"
TMP_FILE="/tmp/${RPM_NAME}"

# --- Udskriv banner ---
echo ""
echo "  ███████╗████████╗██████╗  █████╗ ██╗   ██╗███╗   ███╗██████╗ "
echo "  ██╔════╝╚══██╔══╝██╔══██╗██╔══██╗██║   ██║████╗ ████║██╔══██╗"
echo "  ███████╗   ██║   ██████╔╝███████║██║   ██║██╔████╔██║██████╔╝"
echo "  ╚════██║   ██║   ██╔══██╗██╔══██║██║   ██║██║╚██╔╝██║██╔══██╗"
echo "  ███████║   ██║   ██║  ██║██║  ██║╚██████╔╝██║ ╚═╝ ██║██║  ██║"
echo "  ╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚═╝     ╚═╝╚═╝  ╚═╝"
echo ""
echo "  Opdateringsskript — henter v${VERSION} til Jolla Phone 2026 (${ARCH})"
echo ""

# --- Trin 1: Tjek om vi kører på Sailfish OS ---
if ! command -v pkcon >/dev/null 2>&1; then
    echo "FEJL: pkcon ikke fundet — kører du dette på en Sailfish OS telefon?"
    exit 1
fi

# --- Trin 2: Fjern gammel widget-RPM hvis den findes ---
echo "--- Trin 1/3: Fjerner gammel widget-RPM (hvis installeret) ---"
if pkcon list 2>/dev/null | grep -q "harbour-straumr-widget"; then
    echo "  Fjerner harbour-straumr-widget..."
    echo "  OBS: Dette kræver også godkendelse — popup kommer måske ikke frem."
    echo "  Hvis det fejler, kør manuelt: pkcon remove harbour-straumr-widget"
    pkcon remove harbour-straumr-widget 2>/dev/null || echo "  (Springer over — fjern manuelt hvis nødvendigt)"
else
    echo "  Ingen gammel widget-RPM fundet — godt!"
fi
echo ""

# --- Trin 3: Download ny RPM ---
echo "--- Trin 2/3: Henter Straumr v${VERSION} ---"
echo "  URL: ${DOWNLOAD_URL}"
rm -f "${TMP_FILE}"
curl -sL -o "${TMP_FILE}" "${DOWNLOAD_URL}"

# Tjek at download faktisk er en RPM (starter med magic bytes: 0xED 0xAB)
if [ ! -s "${TMP_FILE}" ]; then
    echo "FEJL: Download fejlede — filen er tom"
    exit 1
fi
if ! head -c 2 "${TMP_FILE}" | od -An -tx1 | grep -q "ed ab"; then
    echo "FEJL: Downloadet fil er ikke en gyldig RPM"
    echo "  (Måske findes version v${VERSION} ikke?)"
    rm -f "${TMP_FILE}"
    exit 1
fi
echo "  Download færdig: $(wc -c < "${TMP_FILE}" | tr -d ' ') bytes"
echo "  Gemmer som: ${TMP_FILE}"
echo ""

# --- Trin 4: Vis instruktioner ---
echo "--- Trin 3/3: Næste skridt ---"
echo ""
echo "  ╔═══════════════════════════════════════════════════════╗"
echo "  ║  RPM er downloadet til /tmp/                          ║"
echo "  ║  Åbn nu Terminal-appen og kør:                        ║"
echo "  ║                                                       ║"
echo "  ║    pkcon install-local ${TMP_FILE}   ║"
echo "  ║                                                       ║"
echo "  ║  Popup med sikkerhedskode vises — indtast koden.      ║"
echo "  ╚═══════════════════════════════════════════════════════╝"
echo ""
echo "  Bagefter — genstart lipstick (hjemmeskærmen):"
echo "    systemctl --user restart lipstick"
echo ""
echo "  Så gå til: Indstillinger → Begivenhedsvisning → slå Straumr til"
echo "  og stryg til venstre for at se widgetten! ⚡"
echo ""
echo "  Se debug logs med:"
echo "    journalctl -f | grep '[Straumr-Widget]'"
echo ""
