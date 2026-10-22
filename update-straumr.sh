#!/bin/sh
# Straumr opdateringsskript — kør på Sailfish OS telefonen
# Henter og installerer seneste version fra GitHub Releases i én kommando.
# Genstarter kun lipstick (ikke hele telefonen) efter installation.
#
# Brug:
#   curl -LO https://raw.githubusercontent.com/storefyr/Straumr/main/update-straumr.sh && sh update-straumr.sh
#
# Valgfrit — angiv en specifik version:
#   curl -LO https://raw.githubusercontent.com/storefyr/Straumr/main/update-straumr.sh && sh update-straumr.sh 1.9.1
#
# Valgfrit — spring lipstick-genstart over (hvis du vil gøre det manuelt senere):
#   sh update-straumr.sh 1.9.1 --no-restart

set -e

# --- Konfiguration ---
REPO="storefyr/Straumr"
DEFAULT_VERSION="1.9.1"
VERSION="${1:-${DEFAULT_VERSION}}"
NO_RESTART=""
if [ "$2" = "--no-restart" ]; then
    NO_RESTART="yes"
elif [ "$1" = "--no-restart" ]; then
    NO_RESTART="yes"
    VERSION="${DEFAULT_VERSION}"
fi
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
echo "--- Trin 1/5: Fjerner gammel widget-RPM (hvis installeret) ---"
if pkcon list 2>/dev/null | grep -q "harbour-straumr-widget"; then
    echo "  Fjerner harbour-straumr-widget..."
    echo "  (Godkend med sikkerhedskode hvis bedt om)"
    pkcon remove harbour-straumr-widget || true
else
    echo "  Ingen gammel widget-RPM fundet — springer over"
fi
echo ""

# --- Trin 3: Download ny RPM ---
echo "--- Trin 2/5: Henter Straumr v${VERSION} ---"
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
echo "--- Trin 3/5: Installerer Straumr v${VERSION} ---"
echo ""
echo "  VIGTIGT: pkcon vil vise en popup-dialog for sikkerhedskode."
echo "  Kig efter popup'en og indtast din sikkerhedskode der!"
echo ""
# Kør installationen i baggrunden så popup'en kan komme frem,
# og vent på at den bliver færdig.
pkcon install-local "${TMP_FILE}" &
PKCON_PID=$!

# Vent på at pkcon er færdig (max 120 sekunder)
WAITED=0
while kill -0 $PKCON_PID 2>/dev/null && [ $WAITED -lt 120 ]; do
    sleep 1
    WAITED=$((WAITED + 1))
done

# Tjek om processen stadig kører (timeout)
if kill -0 $PKCON_PID 2>/dev/null; then
    echo ""
    echo "  ADVARSEL: Installationen tog for lang tid — blev popup'en vist?"
    echo "  Prøv at køre manuelt:"
    echo "    pkcon install-local ${TMP_FILE}"
    kill $PKCON_PID 2>/dev/null || true
    rm -f "${TMP_FILE}"
    exit 1
fi

# Vent på exit code
wait $PKCON_PID
PKCON_EXIT=$?

if [ $PKCON_EXIT -ne 0 ]; then
    echo ""
    echo "  FEJL: Installation fejlede (exit code: $PKCON_EXIT)"
    echo "  Hvis popup'en ikke dukkede op, prøv at køre manuelt:"
    echo "    pkcon install-local ${TMP_FILE}"
    echo "  (Så kan du se popup'en og indtaste sikkerhedskoden)"
    exit 1
fi
echo "  Installation OK"
echo ""

# --- Trin 5: Genstart lipstick (ikke hele telefonen!) ---
if [ "$NO_RESTART" = "yes" ]; then
    echo "--- Trin 4/5: Lipstick-genstart SKIPPET (--no-restart) ---"
else
    echo "--- Trin 4/5: Genstarter lipstick (hjemmeskærmen) ---"
    echo "  (Dette tager 2-5 sekunder — skærmen blinker kort)"
    systemctl --user restart lipstick 2>/dev/null || {
        echo "  ADVARSEL: Kunne ikke genstarte lipstick automatisk."
        echo "  Kør selv: systemctl --user restart lipstick"
    }
fi
echo ""

# --- Trin 6: Ryd op ---
echo "--- Trin 5/5: Rydder op ---"
rm -f "${TMP_FILE}"
echo ""

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
