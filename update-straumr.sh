#!/bin/sh
# Straumr opdateringsskript — kør på Sailfish OS telefonen
# Henter og installerer seneste version fra GitHub Releases i én kommando.
#
# Brug:
#   curl -LO https://raw.githubusercontent.com/storefyr/Straumr/main/update-straumr.sh
#   sh update-straumr.sh
#
# Eller hvis du allerede har skriptet liggende:
#   sh update-straumr.sh
#
# Valgfrit — angiv en specifik version:
#   sh update-straumr.sh 1.8.0

set -e

# --- Konfiguration ---
REPO="storefyr/Straumr"
DEFAULT_VERSION="1.8.0"
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
echo "--- Trin 1/4: Fjerner gammel widget-RPM (hvis installeret) ---"
if pkcon list 2>/dev/null | grep -q "harbour-straumr-widget"; then
    echo "  Fjerner harbour-straumr-widget..."
    echo "  (Godkend med sikkerhedskode hvis bedt om)"
    pkcon remove harbour-straumr-widget || true
else
    echo "  Ingen gammel widget-RPM fundet — springer over"
fi
echo ""

# --- Trin 3: Download ny RPM ---
echo "--- Trin 2/4: Henter Straumr v${VERSION} ---"
echo "  URL: ${DOWNLOAD_URL}"
rm -f "${TMP_FILE}"
curl -sL -o "${TMP_FILE}" "${DOWNLOAD_URL}"

# Tjek at download faktisk er en RPM (starter med magic bytes)
if [ ! -s "${TMP_FILE}" ]; then
    echo "FEJL: Download fejlede — filen er tom"
    exit 1
fi
if ! head -c 4 "${TMP_FILE}" | grep -q $'\xed\xab'; then
    echo "FEJL: Downloadet fil er ikke en gyldig RPM"
    echo "  (Måske findes version v${VERSION} ikke?)"
    rm -f "${TMP_FILE}"
    exit 1
fi
echo "  Download færdig: $(wc -c < "${TMP_FILE}" | tr -d ' ') bytes"
echo ""

# --- Trin 4: Installer ---
echo "--- Trin 3/4: Installerer Straumr v${VERSION} ---"
echo "  (Godkend med sikkerhedskode i popup)"
pkcon install-local "${TMP_FILE}"
echo ""

# --- Trin 5: Ryd op ---
echo "--- Trin 4/4: Rydder op ---"
rm -f "${TMP_FILE}"
echo ""

# --- Færdig ---
echo "  ╔═══════════════════════════════════════╗"
echo "  ║  ✅ Straumr v${VERSION} er installeret!  ║"
echo "  ╚═══════════════════════════════════════╝"
echo ""
echo "  Næste skridt:"
echo "  1. Genstart telefonen (eller kør: systemctl --user restart lipstick)"
echo "  2. Gå til: Indstillinger → Begivenhedsvisning"
echo "  3. Slå 'Straumr' til"
echo "  4. Stryg til venstre — se din elpris! ⚡"
echo ""
