#!/usr/bin/env python3
"""
dev.py -- One-command dev server for PickleTrack web preview.

Starts both:
  1. File watcher -> auto-rebuilds Flutter web on lib/ changes
  2. HTTP server -> serves build/web/ for phone_preview.html

Usage:
  python scripts/dev.py
  python scripts/dev.py --port 8080

Requires: chokidar-cli (npm install --save-dev chokidar-cli)
"""

import argparse
import http.server
import os
import socketserver
import subprocess
import sys
import threading

_IS_WINDOWS = sys.platform.startswith("win")

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BUILD_DIR = os.path.join(PROJECT_ROOT, "build", "web")


class BuildHTTPHandler(http.server.SimpleHTTPRequestHandler):
    """Serve files from build/web/ without changing global working directory."""

    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=BUILD_DIR, **kwargs)

    def log_message(self, format, *args):
        # Suppress noisy request logs
        pass


def start_server(port):
    """Start a static HTTP server serving build/web/."""
    with socketserver.TCPServer(("", port), BuildHTTPHandler, bind_and_activate=False) as httpd:
        httpd.allow_reuse_address = True
        httpd.server_bind()
        httpd.server_activate()
        print("[serve] HTTP server on http://localhost:{}".format(port))
        print("[serve] Open http://localhost:{}/phone_preview.html".format(port))
        print("")
        print("Press Ctrl+C to stop.")
        print("")
        httpd.serve_forever()


def main():
    parser = argparse.ArgumentParser(description="PickleTrack dev server")
    parser.add_argument("--port", type=int, default=8080, help="HTTP server port (default: 8080)")
    args = parser.parse_args()

    print(">> PickleTrack dev server")
    print("  Project:  {}".format(PROJECT_ROOT))
    print("  Build:    {}".format(BUILD_DIR))
    print("")

    # Start the file watcher (platform-native script)
    if _IS_WINDOWS:
        print("[watch] Starting file watcher (watch_web.bat)...")
        watcher_cmd = ["cmd", "/c", "scripts\\watch_web.bat"]
    else:
        print("[watch] Starting file watcher (watch_web.sh)...")
        watcher_cmd = ["bash", "scripts/watch_web.sh"]
    watcher = subprocess.Popen(
        watcher_cmd,
        cwd=PROJECT_ROOT,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
    )

    # Start the HTTP server in a background thread
    server_thread = threading.Thread(target=start_server, args=(args.port,), daemon=True)
    server_thread.start()

    # Stream watcher output to the console so the user sees build progress
    try:
        for line in watcher.stdout:
            print(line, end="")
    except KeyboardInterrupt:
        pass
    finally:
        print("\n[stop] Shutting down...")
        watcher.terminate()
        watcher.wait(timeout=5)
        print("[stop] Bye!")
        sys.exit(0)


if __name__ == "__main__":
    main()
