#!/bin/sh
# Straumr opdateringsskript — kør på Sailfish OS telefonen
# RENSER gamle filer først, så henter og installerer seneste version.
# Genstarter lipstick (ikke hele telefonen) efter installation.
#
# Brug (én kommando):
#   curl -LO https://raw.githubusercontent.com/storefyr/Straumr/main/update-straumr.sh && sh update-straumr.sh
#
# Valgfrit — angiv en specifik version:
#   sh update-straumr.sh 1.9.3
#
# Du skal indtaste din sikkerhedskode én gang når devel-su beder om det.

set -e

# --- Konfiguration ---
REPO="storefyr/Straumr"
DEFAULT_VERSION="1.9.3"
VERSION="${1:-${DEFAULT_VERSION}}"
ARCH="aarch64"
RPM_NAME="harbour-straumr-${VERSION}-1.${ARCH}.rpm"
DOWNLOAD_URL="https://github.com/${REPO}/releases/download/v${VERSION}/${RPM_NAME}"
TMP_FILE="/tmp/${RPM_NAME}"

echo ""
echo "  ███████╗████████╗██████╗  █████╗ ██╗   ██╗███╗   ███╗██████╗ "
echo "  ██╔════╝╚══██╔══╝██╔══██╗██╔══██╗██║   ██║████╗ ████║██╔══██╗"
echo "  ███████╗   ██║   ██████╔╝███████║██║   ██║██╔████╔██║██████╔╝"
echo "  ╚════██║   ██║   ██╔══██╗██╔══██║██║   ██║██║╚██╔╝██║██╔══██╗"
echo "  ███████║   ██║   ██║  ██║██║  ██║╚██████╔╝██║ ╚═╝ ██║██║  ██║"
echo "  ╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚═╝     ╚═╝╚═╝  ╚═╝"
echo ""
echo "  Opdateringsskript — renser og installerer v${VERSION}"
echo ""

# --- Tjek forudsætninger ---
if ! command -v rpm >/dev/null 2>&1; then
    echo "FEJL: rpm ikke fundet — kører du dette på en Sailfish OS telefon?"
    exit 1
fi
if ! command -v devel-su >/dev/null 2>&1; then
    echo "FEJL: devel-su ikke fundet — er Developer Mode aktiveret?"
    exit 1
fi

# ============================================================
# TRIN 1: RENS — fjern alt gammelt først
# ============================================================
echo "=== TRIN 1/5: RENSER gamle installationer ==="
echo ""

echo "  >>> Indtast din sikkerhedskode nu (én gang) <<<"
echo ""

# 1a. Fjern gammel widget-RPM hvis installeret
if rpm -q harbour-straumr-widget >/dev/null 2>&1; then
    echo "  [1a] Fjerner gammel harbour-straumr-widget RPM..."
    devel-su rpm -e harbour-straumr-widget
    echo "       OK"
else
    echo "  [1a] Ingen gammel widget-RPM — springer over"
fi

# 1b. Fjern nuværende Straumr hvis installeret (så vi får en ren installation)
if rpm -q harbour-straumr >/dev/null 2>&1; then
    echo "  [1b] Fjerner nuværende harbour-straumr RPM..."
    devel-su rpm -e harbour-straumr
    echo "       OK"
else
    echo "  [1b] Straumr ikke installeret endnu — springer over"
fi

# 1c. Fjern gamle/stray filer fra tidligere tests
STRAY_FILES="
/usr/share/lipstick-jolla-home-qt5/eventsview/PriceWidget.qml
/usr/share/harbour-straumr/qml/eventsview/PriceWidget.qml
/usr/share/harbour-straumr/qml/eventsview/PriceWidgetContent.qml
/usr/share/harbour-straumr-widget
/usr/share/lipstick/eventswidgets/harbour-straumr-widget.json
"

echo "  [1c] Fjerner gamle/stray filer fra tidligere tests..."
for f in $STRAY_FILES; do
    if [ -e "$f" ]; then
        echo "       Fjerner: $f"
        devel-su rm -rf "$f"
    fi
done

# Fjern tomme mapper
for d in /usr/share/harbour-straumr/qml/eventsview /usr/share/harbour-straumr-widget; do
    if [ -d "$d" ]; then
        devel-su rmdir "$d" 2>/dev/null && echo "       Fjernede tom mappe: $d" || true
    fi
done

# 1d. Rens dconf — sæt til kun system widgets (Straumr tilføjes ved næste skridt)
echo "  [1d] Renser dconf events_screen_widgets..."
CLEAN_DCONF="['/usr/share/lipstick-jolla-home-qt5/eventsview/weather/WeatherLoader.qml', '/usr/share/lipstick-jolla-home-qt5/eventsview/calendar/CalendarWidgetLoader.qml']"
dconf write /desktop/lipstick-jolla-home/events_screen_widgets "$CLEAN_DCONF"
echo "       OK — kun system widgets tilbage"
echo ""

# ============================================================
# TRIN 2: DOWNLOAD ny RPM
# ============================================================
echo "=== TRIN 2/5: Henter Straumr v${VERSION} ==="
echo "  URL: ${DOWNLOAD_URL}"
rm -f "${TMP_FILE}"
curl -sL -o "${TMP_FILE}" "${DOWNLOAD_URL}"

if [ ! -s "${TMP_FILE}" ]; then
    echo "FEJL: Download fejlede — filen er tom"
    exit 1
fi
if ! head -c 2 "${TMP_FILE}" | od -An -tx1 | grep -q "ed ab"; then
    echo "FEJL: Downloadet fil er ikke en gyldig RPM"
    rm -f "${TMP_FILE}"
    exit 1
fi
echo "  Download færdig: $(wc -c < "${TMP_FILE}" | tr -d ' ') bytes"
echo ""

# ============================================================
# TRIN 3: INSTALLER
# ============================================================
echo "=== TRIN 3/5: Installerer Straumr v${VERSION} ==="
devel-su rpm -Uvh "${TMP_FILE}"
echo "  Installation færdig!"
echo ""

# ============================================================
# TRIN 4: SÆT DCONF — tilføj Straumr til widget-listen
# ============================================================
echo "=== TRIN 4/5: Tilføjer Straumr til widget-listen ==="
NEW_DCONF="['/usr/share/lipstick-jolla-home-qt5/eventsview/weather/WeatherLoader.qml', '/usr/share/lipstick-jolla-home-qt5/eventsview/calendar/CalendarWidgetLoader.qml', '/usr/share/harbour-straumr/eventsview/PriceWidget.qml']"
dconf write /desktop/lipstick-jolla-home/events_screen_widgets "$NEW_DCONF"
echo "  OK — Straumr tilføjet"
echo "  Verificerer:"
dconf read /desktop/lipstick-jolla-home/events_screen_widgets
echo ""

# ============================================================
# TRIN 5: GENSTART LIPSTICK
# ============================================================
echo "=== TRIN 5/5: Genstarter lipstick ==="
echo "  (Skærmen blinker i 2-5 sekunder)"
systemctl --user restart lipstick 2>/dev/null || {
    echo "  ADVARSEL: Kunne ikke genstarte lipstick automatisk."
    echo "  Kør selv: systemctl --user restart lipstick"
}
echo "  Lipstick genstartet."
echo ""
sleep 3

# Ryd op
rm -f "${TMP_FILE}"

# ============================================================
# FÆRDIG
# ============================================================
echo "  ╔═══════════════════════════════════════╗"
echo "  ║  ✅ Straumr v${VERSION} er installeret!  ║"
echo "  ╚═══════════════════════════════════════╝"
echo ""
echo "  Næste skridt:"
echo "  1. Gå til: Indstillinger → Begivenhedsvisning"
echo "  2. Se at 'Straumr' vises MED en toggle — slå den til!"
echo "  3. Stryg til venstre — se din elpris! ⚡"
echo ""
echo "  Se debug logs med:"
echo "    devel-su journalctl -f | grep Straumr"
echo ""
