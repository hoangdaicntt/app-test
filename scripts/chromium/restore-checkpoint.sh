#!/usr/bin/env bash
source "$(dirname -- "$0")/common.sh"

: "${CHECKPOINT_ARCHIVE:=$PROJECT_ROOT/chromium/checkpoint/out-ADBAndroid.tar.zst}"
[[ -s "$CHECKPOINT_ARCHIVE" ]] || { echo "Missing checkpoint archive: $CHECKPOINT_ARCHIVE" >&2; exit 1; }

mkdir -p "$CHROMIUM_SRC"
archive_bytes=$(stat -c '%s' "$CHECKPOINT_ARCHIVE")
echo "Restoring checkpoint ($archive_bytes bytes)"

# A fresh hosted runner gives every source file a new mtime. Normalize the
# identical pinned checkout before extracting outputs so Ninja can trust the
# timestamps and dependency metadata stored in the exact-key checkpoint.
source_epoch=$(git -C "$CHROMIUM_SRC" show -s --format=%ct HEAD)
find "$CHROMIUM_SRC" \
  -path "$CHROMIUM_SRC/.git" -prune -o \
  -path "$CHROMIUM_SRC/out" -prune -o \
  -type f -exec touch -d "@$source_epoch" {} +

tar -C "$CHROMIUM_SRC" -I 'zstd -T0' -xf "$CHECKPOINT_ARCHIVE"
rm -f "$CHECKPOINT_ARCHIVE"
[[ -f "$CHROMIUM_SRC/out/ADBAndroid/args.gn" ]]
du -sh "$CHROMIUM_SRC/out/ADBAndroid"
