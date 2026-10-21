#!/bin/sh
# Test: Installer v1.1.0 (den version der virkede i går)
# Kører pkcon uden devel-su — Sailfish OS viser GUI-dialog til kodeord

set -e

APP="harbour-straumr-1.1.0-1.aarch64.rpm"
WIDGET="harbour-straumr-widget-1.1.0-1.aarch64.rpm"
URL="https://github.com/storefyr/Straumr/releases/download/v1.1.0"

echo "=== Test: Installer v1.1.0 (kendt virkende version) ==="
echo ""

echo "--- Afinstallerer nuværende versioner ---"
echo "(Godkend med sikkerhedskode i popup hvis nødvendigt)"
pkcon remove harbour-straumr-widget 2>/dev/null || true
pkcon remove harbour-straumr 2>/dev/null || true
echo ""

echo "--- Henter v1.1.0 RPM'er ---"
cd /tmp
curl -sLO "${URL}/${APP}"
curl -sLO "${URL}/${WIDGET}"
echo "Download færdig"
echo ""

echo "--- Installerer v1.1.0 hovedapp ---"
echo "(Godkend med sikkerhedskode i popup)"
pkcon install-local "/tmp/${APP}"
echo ""

echo "--- Installerer v1.1.0 widget ---"
echo "(Godkend med sikkerhedskode i popup)"
pkcon install-local "/tmp/${WIDGET}"
echo ""

echo "--- Rydder op ---"
rm -f "/tmp/${APP}" "/tmp/${WIDGET}"

echo ""
echo "=== Færdig! ==="
echo "Stryg til venstre — ser du Straumr widget med elpris?"
echo ""
echo "Hvis JA: Problemet er i de nye builds (v1.7.0)"
echo "Hvis NEJ: Noget er ændret på telefonen siden i går"
