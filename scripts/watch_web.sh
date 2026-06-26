#!/usr/bin/env bash
#
# watch_web.sh — Auto-rebuild Flutter web on lib/ changes
#
# Usage:  bash scripts/watch_web.sh
#
# What it does:
#   1. Starts a `flutter build web` on every file change in lib/
#   2. Writes build/web/.build_timestamp after each successful build
#   3. The phone_preview.html page polls that file every 2s and
#      auto-refreshes the iframe when it changes.
#
# Requirements: `entr` (install: `choco install entr` or `brew install entr`)
#   Fallback: if `entr` is not installed, uses a polling loop instead.

set -euo pipefail

cd "$(dirname "$0")/.."   # project root

BUILD_DIR="build/web"
TS_FILE="$BUILD_DIR/.build_timestamp"

# ── Rebuild function ──
do_build() {
  echo "[build] Rebuilding at $(date '+%H:%M:%S')…"
  flutter build web 2>&1 | grep -vE '^(Compiling|Building|Font|Asset|$)'
  if [ "${PIPESTATUS[0]}" -eq 0 ]; then
    date +%s > "$TS_FILE"
    echo "[done]  Build OK — $(date '+%H:%M:%S')"
  else
    echo "[FAIL]  Build failed — see errors above"
  fi
  echo "---"
}

echo "▶ PickleTrack web watcher"
echo "  Watching: lib/"
echo "  Output:   $BUILD_DIR/"
echo ""

# ── Initial build ──
echo "[build] Initial build…"
flutter build web 2>&1 | grep -vE '^(Compiling|Building|Font|Asset|$)'
if [ "${PIPESTATUS[0]}" -eq 0 ]; then
  date +%s > "$TS_FILE"
  echo "[done]  Initial build complete — $(date '+%H:%M:%S')"
else
  echo "[FAIL]  Initial build failed"
  exit 1
fi
echo ""

# ── Watch method 1: entr (preferred, efficient) ──
if command -v entr &>/dev/null; then
  echo "Using entr for file watching."
  echo "Press Ctrl+C to stop."
  echo ""
  # Use bash -c (not sh -c) so PIPESTATUS works everywhere
  find lib/ -name '*.dart' | entr -r -p bash -c '
    cd "$(dirname "$0")/.." 2>/dev/null || true
    echo "[build] Rebuilding at $(date "+%H:%M:%S")…"
    flutter build web 2>&1 | grep -vE "^(Compiling|Building|Font|Asset|$)"
    if [ "${PIPESTATUS[0]}" -eq 0 ]; then
      date +%s > "build/web/.build_timestamp"
      echo "[done]  Build OK — $(date "+%H:%M:%S")"
    else
      echo "[FAIL]  Build failed — see errors above"
    fi
    echo "---"
  ' "$0"

# ── Watch method 2: polling fallback (no entr) ──
else
  echo "entr not found — using polling fallback (checks every 2s)."
  echo "Install entr for instant rebuilds: choco install entr (Windows) / brew install entr (Mac)"
  echo "Press Ctrl+C to stop."
  echo ""

  # Portable hash command: md5sum (Linux/Git-Bash) or md5 -r (macOS)
  if command -v md5sum &>/dev/null; then
    HASH_CMD=(md5sum)
  elif command -v md5 &>/dev/null; then
    HASH_CMD=(md5 -r)
  else
    echo "ERROR: neither md5sum nor md5 found. Cannot detect file changes."
    exit 1
  fi

  LAST_HASH=""
  while true; do
    # Hash all dart file contents to detect any change
    CURRENT_HASH=$(find lib/ -name '*.dart' -exec "${HASH_CMD[@]}" {} + 2>/dev/null | sort | "${HASH_CMD[0]}" | cut -d' ' -f1)

    if [ "$CURRENT_HASH" != "$LAST_HASH" ] && [ -n "$LAST_HASH" ]; then
      do_build
    fi

    LAST_HASH="$CURRENT_HASH"
    sleep 2
  done
fi
