#!/usr/bin/env bash
source "$(dirname -- "$0")/common.sh"

: "${CHECKPOINT_ARCHIVE:=$PROJECT_ROOT/chromium/checkpoint/out-ADBAndroid.tar.zst}"
[[ -s "$CHECKPOINT_ARCHIVE" ]] || { echo "Missing checkpoint archive: $CHECKPOINT_ARCHIVE" >&2; exit 1; }

mkdir -p "$CHROMIUM_SRC"
archive_bytes=$(stat -c '%s' "$CHECKPOINT_ARCHIVE")
echo "Restoring checkpoint ($archive_bytes bytes)"
tar -C "$CHROMIUM_SRC" -I 'zstd -T0' -xf "$CHECKPOINT_ARCHIVE"
rm -f "$CHECKPOINT_ARCHIVE"
[[ -f "$CHROMIUM_SRC/out/ADBAndroid/args.gn" ]]
touch "$CHROMIUM_SRC/out/ADBAndroid/.checkpoint-restored"
du -sh "$CHROMIUM_SRC/out/ADBAndroid"
