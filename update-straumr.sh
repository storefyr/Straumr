#!/bin/sh
# Straumr opdateringsskript — kør på Sailfish OS telefonen
# Henter og installerer seneste version fra GitHub Releases i én kommando.
# Bruger devel-su + rpm (undgår pkcon's polkit-popup problem).
#
# Brug (én kommando):
#   curl -LO https://raw.githubusercontent.com/storefyr/Straumr/main/update-straumr.sh && sh update-straumr.sh
#
# Valgfrit — angiv en specifik version:
#   sh update-straumr.sh 1.9.1
#
# Du skal indtaste din sikkerhedskode én gang når devel-su beder om det.

set -e

# --- Konfiguration ---
REPO="storefyr/Straumr"
DEFAULT_VERSION="1.9.2"
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
echo "  Opdateringsskript — henter og installerer v${VERSION}"
echo ""

# --- Trin 1: Tjek forudsætninger ---
if ! command -v rpm >/dev/null 2>&1; then
    echo "FEJL: rpm ikke fundet — kører du dette på en Sailfish OS telefon?"
    exit 1
fi
if ! command -v devel-su >/dev/null 2>&1; then
    echo "FEJL: devel-su ikke fundet — er Developer Mode aktiveret?"
    exit 1
fi

# --- Trin 2: Fjern gammel widget-RPM hvis den findes ---
echo "--- Trin 1/4: Fjerner gammel widget-RPM (hvis installeret) ---"
if rpm -q harbour-straumr-widget >/dev/null 2>&1; then
    echo "  Fjerner harbour-straumr-widget..."
    echo "  (Indtast sikkerhedskode hvis bedt om)"
    devel-su rpm -e harbour-straumr-widget
    echo "  OK: Gammel widget-RPM fjernet"
else
    echo "  Ingen gammel widget-RPM — godt!"
fi
echo ""

# --- Trin 3: Download ny RPM ---
echo "--- Trin 2/4: Henter Straumr v${VERSION} ---"
echo "  URL: ${DOWNLOAD_URL}"
rm -f "${TMP_FILE}"
curl -sL -o "${TMP_FILE}" "${DOWNLOAD_URL}"

# Tjek at download faktisk er en RPM (magic bytes: 0xED 0xAB)
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
echo ""

# --- Trin 4: Installer med devel-su + rpm ---
echo "--- Trin 3/4: Installerer Straumr v${VERSION} ---"
echo ""
echo "  >>> Indtast din sikkerhedskode nu <<<"
echo ""
devel-su rpm -Uvh "${TMP_FILE}"
echo ""
echo "  Installation færdig!"
echo ""

# --- Trin 5: Genstart lipstick ---
echo "--- Trin 4/4: Genstarter lipstick (hjemmeskærmen) ---"
echo "  (Skærmen blinker i 2-5 sekunder)"
systemctl --user restart lipstick 2>/dev/null || {
    echo "  ADVARSEL: Kunne ikke genstarte lipstick automatisk."
    echo "  Kør selv: systemctl --user restart lipstick"
}
echo ""

# --- Ryd op ---
rm -f "${TMP_FILE}"

# --- Færdig ---
echo "  ╔═══════════════════════════════════════╗"
echo "  ║  ✅ Straumr v${VERSION} er installeret!  ║"
echo "  ╚═══════════════════════════════════════╝"
echo ""
echo "  Næste skridt:"
echo "  1. Gå til: Indstillinger → Begivenhedsvisning"
echo "  2. Slå 'Straumr' til (hvis ikke allerede gjort)"
echo "  3. Stryg til venstre — se din elpris! ⚡"
echo ""
echo "  Se debug logs med:"
echo "    journalctl -f | grep '[Straumr-Widget]'"
echo ""
echo "  Kør fuld debug med:"
echo "    curl -LO https://raw.githubusercontent.com/storefyr/Straumr/main/debug-widget.sh && sh debug-widget.sh"
echo ""
