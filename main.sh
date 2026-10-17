#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")" || exit 1

# find the first file matches jadx-headless-mcp*
JADX_FILE=$(find . -maxdepth 1 -type f -name "jadx-headless-mcp*" | head -n 1)
if [[ -z "$JADX_FILE" ]]; then
    echo "jadx-headless-mcp file not found in the current directory."
    exit 1
fi
echo "Using jadx file: $JADX_FILE"

# ensure JAVA_HOME is set
if [[ -z "${JAVA_HOME:-}" ]]; then
    echo "JAVA_HOME is not set. Please set JAVA_HOME to your Java installation directory."
    exit 1
fi
echo "Using JAVA_HOME: $JAVA_HOME"

npx --yes rea inspect-android-package
