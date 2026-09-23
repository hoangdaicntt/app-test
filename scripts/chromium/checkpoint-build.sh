#!/usr/bin/env bash
source "$(dirname -- "$0")/common.sh"

: "${CHECKPOINT_MINUTES:=225}"
: "${CHECKPOINT_ARCHIVE:=$PROJECT_ROOT/chromium/checkpoint/out-ADBAndroid.tar.zst}"
: "${CHECKPOINT_MAX_BYTES:=9500000000}"

mkdir -p "$ARTIFACT_DIR" "$CHROMIUM_SRC/out/ADBAndroid" "$(dirname -- "$CHECKPOINT_ARCHIVE")"
cp "$PROJECT_ROOT/chromium/args.gn" "$CHROMIUM_SRC/out/ADBAndroid/args.gn"
cd "$CHROMIUM_SRC"

(
  while true; do
    date -u '+%Y-%m-%dT%H:%M:%SZ'
    free -m
    df -Pm "$CHROMIUM_SRC"
    du -sm out/ADBAndroid 2>/dev/null || true
    sleep 60
  done
) > "$ARTIFACT_DIR/resource-samples.log" &
resource_monitor_pid=$!
trap 'kill "$resource_monitor_pid" 2>/dev/null || true' EXIT

gn gen out/ADBAndroid --fail-on-unused-args 2>&1 | tee "$ARTIFACT_DIR/gn.log"

# A fresh hosted runner gives the identical source tree new mtimes. Mark only
# outputs from an exact-key checkpoint newer after GN has refreshed the graph,
# otherwise Ninja rebuilds completed actions despite identical content.
if [[ -f out/ADBAndroid/.checkpoint-restored ]]; then
  find out/ADBAndroid -type f ! -name .checkpoint-restored -exec touch {} +
  rm out/ADBAndroid/.checkpoint-restored
  echo "Refreshed restored output timestamps." | tee "$ARTIFACT_DIR/checkpoint-restore.log"
fi

set +e
timeout --signal=INT --kill-after=5m "${CHECKPOINT_MINUTES}m" \
  autoninja -C out/ADBAndroid -j "${CHROMIUM_JOBS:-$(nproc)}" chrome_public_apk \
  2>&1 | tee "$ARTIFACT_DIR/build.log"
compile_status=${PIPESTATUS[0]}
set -e

case "$compile_status" in
  0)
    echo "Compilation completed before the checkpoint deadline." | tee "$ARTIFACT_DIR/checkpoint.log"
    ;;
  124)
    echo "Compilation paused after ${CHECKPOINT_MINUTES} minutes." | tee "$ARTIFACT_DIR/checkpoint.log"
    ;;
  *)
    echo "Compilation failed before checkpointing (status $compile_status)." >&2
    exit "$compile_status"
    ;;
esac

sync
rm -f "$CHECKPOINT_ARCHIVE"
tar -C "$CHROMIUM_SRC" -I 'zstd -T0 -3' -cf "$CHECKPOINT_ARCHIVE" out/ADBAndroid
checkpoint_bytes=$(stat -c '%s' "$CHECKPOINT_ARCHIVE")
checkpoint_human=$(du -h "$CHECKPOINT_ARCHIVE" | cut -f1)
output_human=$(du -sh "$CHROMIUM_SRC/out/ADBAndroid" | cut -f1)
{
  echo "output_size=$output_human"
  echo "archive_size=$checkpoint_human"
  echo "archive_bytes=$checkpoint_bytes"
  sha256sum "$CHECKPOINT_ARCHIVE"
} | tee -a "$ARTIFACT_DIR/checkpoint.log"

if (( checkpoint_bytes > CHECKPOINT_MAX_BYTES )); then
  echo "Checkpoint exceeds ${CHECKPOINT_MAX_BYTES} bytes and will not fit the repository cache." >&2
  exit 1
fi
