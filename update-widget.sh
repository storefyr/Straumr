#!/bin/sh
# Straumr Widget update script - run on the Sailfish OS device
# Usage: sh update-widget.sh [version]
# Example: sh update-widget.sh 1.5.0

set -e

VERSION="${1:-1.5.0}"
ARCH="aarch64"
RPM_NAME="harbour-straumr-widget-${VERSION}-1.${ARCH}.rpm"
DOWNLOAD_URL="https://github.com/storefyr/Straumr/releases/download/v${VERSION}/${RPM_NAME}"
TMP_DIR="/tmp"

echo "=== Straumr Widget Update Script ==="
echo "Version: ${VERSION}"
echo "Architecture: ${ARCH}"
echo ""

echo "--- Step 1: Download new RPM ---"
cd "${TMP_DIR}"
curl -LO "${DOWNLOAD_URL}"
echo "Downloaded: ${RPM_NAME}"

echo "--- Step 2: Install new version ---"
devel-su pkcon install-local "${TMP_DIR}/${RPM_NAME}"

echo "--- Step 3: Restart Lipstick ---"
systemctl --user restart lipstick

echo "--- Step 4: Clean up ---"
rm -f "${TMP_DIR}/${RPM_NAME}"

echo ""
echo "=== Done! ==="
echo "Straumr Widget ${VERSION} is installed. Swipe left to see it."
