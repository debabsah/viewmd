#!/usr/bin/env bash
#
# release.sh - build, sign, notarize, and package viewmd for distribution.
#
# This is OWNER-RUN. It requires an Apple Developer ID (a paid Apple Developer
# account) for code signing and notarization. Without that, the app can still be
# built and run locally, but it cannot be distributed for others to install
# without Gatekeeper warnings. See docs/RELEASE.md for the full walkthrough.
#
# Usage:
#   DEVELOPER_ID="Developer ID Application: Your Name (TEAMID)" \
#   NOTARY_PROFILE="viewmd-notary" \
#   Scripts/release.sh 0.3.0
#
set -euo pipefail

VERSION="${1:?usage: release.sh <version>, e.g. 0.3.0}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD="$ROOT/.build/Build/Products/Release"
APP="$BUILD/viewmd.app"
DIST="$ROOT/dist-release"
DMG="$DIST/viewmd-$VERSION.dmg"

echo "==> Building Release"
make -C "$ROOT" app

echo "==> Signing (hardened runtime)"
: "${DEVELOPER_ID:?set DEVELOPER_ID to your 'Developer ID Application' identity}"
codesign --force --deep --options runtime --timestamp \
  --sign "$DEVELOPER_ID" "$APP"
codesign --verify --strict --verbose=2 "$APP"

echo "==> Packaging DMG"
mkdir -p "$DIST"
rm -f "$DMG"
# create-dmg gives a nicer layout; hdiutil is the no-dependency fallback.
if command -v create-dmg >/dev/null 2>&1; then
  create-dmg --volname "viewmd" --app-drop-link 480 170 \
    --window-size 640 360 "$DMG" "$APP"
else
  hdiutil create -volname "viewmd" -srcfolder "$APP" -ov -format UDZO "$DMG"
fi

echo "==> Notarizing"
: "${NOTARY_PROFILE:?set NOTARY_PROFILE (xcrun notarytool store-credentials)}"
xcrun notarytool submit "$DMG" --keychain-profile "$NOTARY_PROFILE" --wait
xcrun stapler staple "$DMG"

echo "==> Writing appcast.json"
SHA="$(shasum -a 256 "$DMG" | awk '{print $1}')"
cat > "$DIST/appcast.json" <<JSON
{
  "version": "$VERSION",
  "downloadURL": "https://viewmd.app/releases/viewmd-$VERSION.dmg",
  "sha256": "$SHA",
  "notes": "viewmd $VERSION"
}
JSON

echo "==> Done"
echo "    DMG:     $DMG"
echo "    appcast: $DIST/appcast.json"
echo "    Next: upload both, then update the Homebrew cask (see docs/RELEASE.md)."
