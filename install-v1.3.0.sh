#!/bin/sh
# Straumr v1.3.0 + Widget v1.6.0 install script
# Kører pkcon uden devel-su — Sailfish OS viser GUI-dialog til kodeord

set -e

APP="harbour-straumr-1.3.0-1.aarch64.rpm"
WIDGET="harbour-straumr-widget-1.6.0-1.aarch64.rpm"
URL="https://github.com/storefyr/Straumr/releases/download/v1.3.0"

echo "=== Straumr v1.3.0 + Widget v1.6.0 ==="
echo ""

echo "--- Henter RPM'er ---"
cd /tmp
curl -sLO "${URL}/${APP}"
curl -sLO "${URL}/${WIDGET}"
echo "Download færdig"
echo ""

echo "--- Installerer hovedapp ---"
echo "(Godkend med sikkerhedskode i popup)"
pkcon install-local "/tmp/${APP}"
echo ""

echo "--- Installerer widget ---"
echo "(Godkend med sikkerhedskode i popup)"
pkcon install-local "/tmp/${WIDGET}"
echo ""

echo "--- Rydder op ---"
rm -f "/tmp/${APP}" "/tmp/${WIDGET}"

echo ""
echo "=== Færdig! ==="
echo "Stryg til venstre — ser du den røde boks?"
