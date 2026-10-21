#!/bin/sh
# Straumr v1.3.0 + Widget v1.6.0 — download only
# Kør dette script, så henter det RPM'erne til /tmp
# Derefter kører du selv: devel-su pkcon install-local ...

set -e

APP="harbour-straumr-1.3.0-1.aarch64.rpm"
WIDGET="harbour-straumr-widget-1.6.0-1.aarch64.rpm"
URL="https://github.com/storefyr/Straumr/releases/download/v1.3.0"

cd /tmp
echo "Henter ${APP}..."
curl -sLO "${URL}/${APP}"
echo "Henter ${WIDGET}..."
curl -sLO "${URL}/${WIDGET}"

echo ""
echo "Færdig! RPM'er ligger i /tmp"
echo ""
echo "Næste skridt (kopier én linje ad gangen):"
echo ""
echo "  devel-su pkcon install-local /tmp/${APP}"
echo "  devel-su pkcon install-local /tmp/${WIDGET}"
echo ""
echo "Stryg til venstre — ser du den røde boks?"
