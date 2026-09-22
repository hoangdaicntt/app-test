#!/usr/bin/env bash
set -euo pipefail
PROJECT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
: "${CHROMIUM_WORK_ROOT:?Set CHROMIUM_WORK_ROOT to a dedicated Chromium cache directory}"
export DEPOT_TOOLS_UPDATE=0
export DEPOT_TOOLS_METRICS=0
export PATH="$CHROMIUM_WORK_ROOT/depot_tools:$PATH"
CHROMIUM_SRC="$CHROMIUM_WORK_ROOT/checkout/src"
ARTIFACT_DIR="$PROJECT_ROOT/chromium/artifacts"
pin() { python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))[sys.argv[2]])' "$PROJECT_ROOT/chromium/versions.json" "$1"; }
