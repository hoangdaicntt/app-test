#!/usr/bin/env bash
source "$(dirname -- "$0")/common.sh"
[[ $(git -C "$CHROMIUM_SRC" rev-parse HEAD) == "$(pin chromium_revision)" ]]
python3 "$PROJECT_ROOT/scripts/chromium/branding.py" "$CHROMIUM_SRC"
