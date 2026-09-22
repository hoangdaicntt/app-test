#!/usr/bin/env bash
source "$(dirname -- "$0")/common.sh"
python3 "$PROJECT_ROOT/scripts/chromium/verify.py" "$CHROMIUM_SRC" "$ARTIFACT_DIR"
