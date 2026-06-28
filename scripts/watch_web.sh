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
# Preferred watcher: chokidar-cli (cross-platform, instant)
#   Install: npm install --save-dev chokidar-cli
# Fallback 1: entr (Unix only)
#   Install: brew install entr (Mac) / pacman -S entr (MSYS2)
# Fallback 2: polling loop (checks every 2s)

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
echo "  Watching: lib/  +  web/phone_preview.html"
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

# ── Watch method 1: chokidar-cli (preferred, cross-platform, instant) ──
if command -v npx &>/dev/null && npx chokidar --version &>/dev/null; then
  echo "Using chokidar-cli (instant, cross-platform) for file watching."
  echo "Press Ctrl+C to stop."
  echo ""
  npx chokidar "lib/**/*.dart" "web/phone_preview.html" --initial --command "
    echo '[build] Rebuilding at \$(date +%H:%M:%S)…'
    flutter build web 2>&1 | grep -vE '^(Compiling|Building|Font|Asset|$)'
    if [ \"\${PIPESTATUS[0]}\" -eq 0 ]; then
      date +%s > '$TS_FILE'
      echo '[done]  Build OK — \$(date +%H:%M:%S)'
    else
      echo '[FAIL]  Build failed — see errors above'
    fi
    echo '---'
  "

# ── Watch method 2: entr (Unix-only, efficient) ──
elif command -v entr &>/dev/null; then
  echo "Using entr for file watching."
  echo "Press Ctrl+C to stop."
  echo ""
  find lib/ -name '*.dart' -o -name 'phone_preview.html' | entr -r -p bash -c '
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

# ── Watch method 3: polling fallback ──
else
  echo "No instant watcher found — using polling fallback (checks every 2s)."
  echo "Install chokidar-cli for instant rebuilds: npm install --save-dev chokidar-cli"
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
    CURRENT_HASH=$(find lib/ -name '*.dart' -o -name 'phone_preview.html' -exec "${HASH_CMD[@]}" {} + 2>/dev/null | sort | "${HASH_CMD[0]}" | cut -d' ' -f1)

    if [ "$CURRENT_HASH" != "$LAST_HASH" ] && [ -n "$LAST_HASH" ]; then
      do_build
    fi

    LAST_HASH="$CURRENT_HASH"
    sleep 2
  done
fi
