#!/bin/zsh

set -euo pipefail

SCRIPT_DIR="${0:A:h}"
PROJECT_DIR="${SCRIPT_DIR:h}"

exec "$SCRIPT_DIR/swift-package.sh" run \
    --package-path "$PROJECT_DIR" \
    HypnagogiaChecks
