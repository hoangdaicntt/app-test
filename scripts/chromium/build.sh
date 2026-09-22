#!/usr/bin/env bash
source "$(dirname -- "$0")/common.sh"
mkdir -p "$ARTIFACT_DIR" "$CHROMIUM_SRC/out/ADBAndroid"
cp "$PROJECT_ROOT/chromium/args.gn" "$CHROMIUM_SRC/out/ADBAndroid/args.gn"
cd "$CHROMIUM_SRC"
# Record memory/disk throughout compilation without recording environment secrets.
(
  while true; do
    date -u '+%Y-%m-%dT%H:%M:%SZ'
    free -m
    df -Pm "$CHROMIUM_SRC"
    sleep 60
  done
) > "$ARTIFACT_DIR/resource-samples.log" &
resource_monitor_pid=$!
trap 'kill "$resource_monitor_pid" 2>/dev/null || true' EXIT
gn gen out/ADBAndroid --fail-on-unused-args 2>&1 | tee "$ARTIFACT_DIR/gn.log"
autoninja -C out/ADBAndroid -j "${CHROMIUM_JOBS:-$(nproc)}" chrome_public_apk 2>&1 | tee "$ARTIFACT_DIR/build.log"
cp out/ADBAndroid/apks/ChromePublic.apk "$ARTIFACT_DIR/ADB-Browser-arm64.apk"
"$PROJECT_ROOT/scripts/chromium/verify-artifact.sh"
