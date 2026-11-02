#!/bin/zsh

set -euo pipefail

SCRIPT_DIR="${0:A:h}"
PROJECT_DIR="${SCRIPT_DIR:h}"
DIST_DIR="$PROJECT_DIR/dist"
FINAL_ZIP="$DIST_DIR/Hypnagogia.zip"
PACKAGE_WORK_DIR="$(/usr/bin/mktemp -d /tmp/HypnagogiaPackage.XXXXXX)"
trap '/bin/rm -rf "$PACKAGE_WORK_DIR"' EXIT
APP_DIR="$PACKAGE_WORK_DIR/Hypnagogia.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "Building Hypnagogia…"
"$SCRIPT_DIR/swift-package.sh" build --package-path "$PROJECT_DIR" -c release
BIN_DIR="$("$SCRIPT_DIR/swift-package.sh" build --package-path "$PROJECT_DIR" -c release --show-bin-path)"

/bin/mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"
/usr/bin/install -m 755 "$BIN_DIR/Hypnagogia" "$MACOS_DIR/Hypnagogia"
/usr/bin/install -m 644 "$PROJECT_DIR/Resources/Info.plist" "$CONTENTS_DIR/Info.plist"

SDK_PATH="$("$SCRIPT_DIR/swift-package.sh" sdk-path)"
ICON_MODULE_CACHE="$PROJECT_DIR/.build/local-cache/clang"
env CLANG_MODULE_CACHE_PATH="$ICON_MODULE_CACHE" \
    /usr/bin/swift \
    -sdk "$SDK_PATH" \
    -module-cache-path "$ICON_MODULE_CACHE" \
    "$PROJECT_DIR/Scripts/generate-icon.swift" \
    "$RESOURCES_DIR/Hypnagogia.icns"

/usr/bin/plutil -lint "$CONTENTS_DIR/Info.plist" >/dev/null
/usr/bin/xattr -cr "$APP_DIR"
/usr/bin/codesign --force --sign - --timestamp=none "$APP_DIR"
/usr/bin/codesign --verify --deep --strict "$APP_DIR"

TEMP_ZIP="$PACKAGE_WORK_DIR/Hypnagogia.zip"
/usr/bin/ditto -c -k --norsrc --keepParent "$APP_DIR" "$TEMP_ZIP"

# Verify the exact archive before exposing it in a Finder/File Provider folder.
VERIFY_DIR="$PACKAGE_WORK_DIR/verify"
/bin/mkdir -p "$VERIFY_DIR"
/usr/bin/ditto -x -k --norsrc "$TEMP_ZIP" "$VERIFY_DIR"
/usr/bin/xattr -cr "$VERIFY_DIR/Hypnagogia.app"
/usr/bin/codesign --verify --deep --strict "$VERIFY_DIR/Hypnagogia.app"

/bin/mkdir -p "$DIST_DIR"
/bin/mv -f "$TEMP_ZIP" "$FINAL_ZIP"

echo "Built $FINAL_ZIP"
