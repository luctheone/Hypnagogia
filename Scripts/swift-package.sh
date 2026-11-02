#!/bin/zsh

set -euo pipefail

SCRIPT_DIR="${0:A:h}"
PROJECT_DIR="${SCRIPT_DIR:h}"
DEFAULT_SDK="$(/usr/bin/xcrun --sdk macosx --show-sdk-path)"
COMPATIBLE_CLT_SDK="/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk"
SDK_PATH="${HYPNAGOGIA_SDK_PATH:-$DEFAULT_SDK}"

# Some Command Line Tools installations expose a newer SDK that their bundled
# compiler cannot import. When Apple also installed the compatible macOS 15.4
# SDK, use it; an explicit HYPNAGOGIA_SDK_PATH always wins.
if [[ -z "${HYPNAGOGIA_SDK_PATH:-}" && "$DEFAULT_SDK" == "/Library/Developer/CommandLineTools/SDKs/"* && -d "$COMPATIBLE_CLT_SDK" ]]; then
    SDK_PATH="$COMPATIBLE_CLT_SDK"
fi

if [[ "${1:-}" == "sdk-path" ]]; then
    print -r -- "$SDK_PATH"
    exit 0
fi

if [[ $# -eq 0 ]]; then
    print -u2 "Usage: swift-package.sh <build|test|run> [arguments…]"
    exit 2
fi

COMMAND="$1"
shift
CACHE_ROOT="$PROJECT_DIR/.build/local-cache"
/bin/mkdir -p \
    "$CACHE_ROOT/clang" \
    "$CACHE_ROOT/swiftpm-cache" \
    "$CACHE_ROOT/swiftpm-config" \
    "$CACHE_ROOT/swiftpm-security"

export CLANG_MODULE_CACHE_PATH="$CACHE_ROOT/clang"
export SWIFTPM_MODULECACHE_OVERRIDE="$CACHE_ROOT/clang"

exec /usr/bin/swift "$COMMAND" \
    --disable-sandbox \
    --sdk "$SDK_PATH" \
    --cache-path "$CACHE_ROOT/swiftpm-cache" \
    --config-path "$CACHE_ROOT/swiftpm-config" \
    --security-path "$CACHE_ROOT/swiftpm-security" \
    "$@"
