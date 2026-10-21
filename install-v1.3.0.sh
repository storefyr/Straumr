#!/bin/sh
# Straumr v1.3.0 + widget v1.6.0 install script - run on the Sailfish OS device
# Usage: sh install-v1.3.0.sh

set -e

APP_VERSION="1.3.0"
WIDGET_VERSION="1.6.0"
ARCH="aarch64"
BASE_URL="https://github.com/storefyr/Straumr/releases/download/v${APP_VERSION}"
TMP_DIR="/tmp"

echo "=== Straumr v${APP_VERSION} + Widget v${WIDGET_VERSION} Install ==="
echo ""

echo "--- Step 1: Remove old widget (if any) ---"
devel-su pkcon remove harbour-straumr-widget 2>/dev/null || true

echo "--- Step 2: Download RPMs ---"
cd "${TMP_DIR}"
curl -sLO "${BASE_URL}/harbour-straumr-${APP_VERSION}-1.${ARCH}.rpm"
curl -sLO "${BASE_URL}/harbour-straumr-widget-${WIDGET_VERSION}-1.${ARCH}.rpm"
echo "Downloaded both RPMs"

echo "--- Step 3: Install main app ---"
devel-su pkcon install-local "${TMP_DIR}/harbour-straumr-${APP_VERSION}-1.${ARCH}.rpm"

echo "--- Step 4: Install widget ---"
devel-su pkcon install-local "${TMP_DIR}/harbour-straumr-widget-${WIDGET_VERSION}-1.${ARCH}.rpm"

echo "--- Step 5: Clean up ---"
rm -f "${TMP_DIR}/harbour-straumr-${APP_VERSION}-1.${ARCH}.rpm"
rm -f "${TMP_DIR}/harbour-straumr-widget-${WIDGET_VERSION}-1.${ARCH}.rpm"

echo ""
echo "=== Done! ==="
echo "Swipe left to Events View — do you see the RED DEBUG BOX?"
