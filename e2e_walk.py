#!/usr/bin/env python3
"""
End-to-end walk of PickleTrack's pause-menu / end-match flow on the
emulator. Uses Python's stdlib xml.etree.ElementTree to parse uiautomator
XML dumps (proper XML parser; no grep / awk hacks) so tap bounds are
always exactly what the platform reports — even when the XML has long
attribute values that grep would miscount.

Flow captured (one dump + one screenshot per step):
  1.  home_after_launch           Home screen (Standard Start renamed)
  2.  bottom_sheet                Quick-Start sheet (Start Match / Edit Setup)
  3.  setup_screen                Quick-Start defaults screen
  4.  live_initial                Live match screen, fresh state 0-0-2
  5.  pause_menu                  Bottom sheet shown by leading pause icon
  6.  confirm_dialog              AlertDialog (Cancel / End Match)
  7.  details_after_endmatch      Match Details screen (post-endmatch entry)
  8.  home_post_endmatch          Home after END-MATCH back nav
  9.  home_with_history_card      Home showing newly-archived match in History
  10. details_from_history        Match Details reached from History tap
  11. home_post_history_back      Home after back-nav from history-driven Details

Usage:
    python e2e_walk.py [--device SERIAL] [--pkg PKG_ID] [--out DIR]

Defaults are chosen so a bare `python e2e_walk.py` continues to walk
PickleTrack on the local Pixel 5 emulator; only pass overrides when
running from CI or against a different device / package variant.

Examples:
    python e2e_walk.py                              # defaults
    python e2e_walk.py --out artifacts/             # local artifacts dir
    python e2e_walk.py --device emulator-5556      # alternate AVD
    python e2e_walk.py --pkg com.example.pickletrack.dev
"""
from __future__ import annotations

import argparse
import os
import re
import subprocess
import sys
import time
import xml.etree.ElementTree as ET
from pathlib import Path

# ── Configuration ─────────────────────────────────────────────────────────
# Argparse layer so the script is reusable from CI / multi-device
# setups. Defaults preserve the prior positional behaviour so a bare
# `python e2e_walk.py` invocation still does what it always did — pass
# `--device`, `--pkg`, or `--out` to override any of them.
_DEFAULT_ADB = r"C:/Users/tomer/AppData/Local/Android/Sdk/platform-tools/adb.exe"
_DEFAULT_PKG = "com.example.pickletrack"
_DEFAULT_DEVICE = "emulator-5554"
_DEFAULT_ACTIVITY = ".MainActivity"
_DEFAULT_OUT = Path(r"C:/Users/tomer/OneDrive/Documents/PickleBall")


def _parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(
        prog="e2e_walk.py",
        description=(
            "End-to-end walk of PickleTrack's pause-menu / end-match flow on "
            "an Android emulator. Parses uiautomator XML with xml.etree "
            "ElementTree and writes one dump + one screenshot per step. "
            "Designed for single-script CI use."
        ),
    )
    p.add_argument(
        "--device",
        default=_DEFAULT_DEVICE,
        metavar="SERIAL",
        help=f"adb device serial (default: {_DEFAULT_DEVICE!r})",
    )
    p.add_argument(
        "--pkg",
        default=_DEFAULT_PKG,
        metavar="PKG_ID",
        help=(
            f"Android application package id (default: {_DEFAULT_PKG!r}). "
            f"Activity class defaults to `{_DEFAULT_ACTIVITY!r}` relative to "
            f"this package — override with --activity when the variant's "
            f"`AndroidManifest.xml` registers a different class."
        ),
    )
    p.add_argument(
        "--activity",
        default=_DEFAULT_ACTIVITY,
        metavar="ACTIVITY",
        help=(
            f"MainActivity class name (default: {_DEFAULT_ACTIVITY!r}). "
            f"Accepts both relative (`MainActivity` or `.MainActivity`) "
            f"and fully qualified (`com.example.pickletrack.MainActivity`) "
            f"forms; the former is composed to `pkg/cls`, the latter is "
            f"passed through untouched."
        ),
    )
    p.add_argument(
        "--out",
        type=Path,
        default=_DEFAULT_OUT,
        metavar="DIR",
        help=(
            "Output directory for walk_*_dump.xml + walk_*_screen.png "
            f"artifacts (default: {str(_DEFAULT_OUT)!r}). Created on startup "
            "if missing so a typo'd path fails fast."
        ),
    )
    return p.parse_args()


# Module-level defaults. main() parses CLI args and overrides these in
# place; deferring argparse to main() means `import e2e_walk` from a test
# harness or downstream script doesn't crash on the parent's argv.
ADB = _DEFAULT_ADB
PKG = _DEFAULT_PKG
ACT = f"{_DEFAULT_PKG}/{_DEFAULT_ACTIVITY.lstrip('.')}"
DEVICE = _DEFAULT_DEVICE
OUT = _DEFAULT_OUT


# ── Subprocess helpers ────────────────────────────────────────────────────
def sh(cmd: list[str], *, check: bool = False) -> tuple[int, str, str]:
    p = subprocess.run(cmd, capture_output=True, text=True)
    if check and p.returncode != 0:
        raise RuntimeError(f"command failed (exit {p.returncode}): {cmd}\n{p.stderr}")
    return p.returncode, p.stdout, p.stderr


def adb(*args: str) -> tuple[int, str, str]:
    return sh([ADB, *args])


def adb_dev(*args: str) -> tuple[int, str, str]:
    return adb("-s", DEVICE, *args)


# Resolved at runtime from `adb shell wm size` so swipe gestures stay
# inside the viewport on any device — not just the 2340-tall Pixel we
# tuned against during initial development. Falls back to 1080×2340
# (the current Pixel_3_API_30 AVD default) so the script remains
# usable in CI / syntax-check contexts where no emulator is attached.
_SCREEN_W = 1080
_SCREEN_H = 2340


def _get_screen_size() -> tuple[int, int]:
    """Update `_SCREEN_W, _SCREEN_H` from `adb shell wm size`. Silent on
    failure so a metadata call never blocks the walk."""
    global _SCREEN_W, _SCREEN_H
    rc, out, _ = adb_dev("shell", "wm", "size")
    if rc == 0:
        # `wm size` returns two lines on AVDs with an active override:
        #   Physical size: 1080x2340
        #   Override size: 720x1280
        # We MUST prefer `Override size:` since that's what the dev
        # actually wants the app to render as (the whole point of the
        # override). Crucially, `re.search` is governed by the
        # *leftmost-position-in-the-string* rule, not by alternation
        # order, so a single combined regex with `(?:Override|Physical)`
        # can never prefer Override when both lines appear — the engine
        # matches leftmost and stops. Run an Override-first lookup and
        # fall back to Physical size when no override is active (this
        # is also the production-device path). Char-class `[xX]` +
        # `re.IGNORECASE` tolerates manufacturer `1080X2340` formats.
        m = re.search(r"Override size:\s*(\d+)\s*[xX]\s*(\d+)", out, re.IGNORECASE)
        if not m:
            m = re.search(r"Physical size:\s*(\d+)\s*[xX]\s*(\d+)", out, re.IGNORECASE)
        if m:
            _SCREEN_W, _SCREEN_H = int(m.group(1)), int(m.group(2))
    return _SCREEN_W, _SCREEN_H


# ── Dump / screenshot ─────────────────────────────────────────────────────
def dumps_window(step: str) -> Path:
    """Native uiautomator dump → pulled to OUT/<step>_dump.xml."""
    local = OUT / f"walk_{step}_dump.xml"
    # Rotate any prior copy so we don't see stale state during analysis.
    if local.exists():
        local.unlink()
    # No --compressed so we get the full attribute set (Flutter renders
    # rather long content-descs that compressed mode can truncate).
    rc, _, _ = adb_dev("shell", "uiautomator", "dump", "/sdcard/win_dump.xml")
    if rc != 0:
        raise RuntimeError("uiautomator dump failed — is the emulator responsive?")
    rc, out, _ = adb_dev("pull", "/sdcard/win_dump.xml", str(local))
    if rc != 0:
        raise RuntimeError(f"adb pull failed: {out}")
    return local


def screenshot(step: str) -> Path:
    """Native screencap → pulled to OUT/<step>_screen.png."""
    local = OUT / f"walk_{step}_screen.png"
    if local.exists():
        local.unlink()
    adb_dev("shell", "screencap", "-p", "/sdcard/win_screen.png")
    adb_dev("pull", "/sdcard/win_screen.png", str(local))
    return local


def snap(step: str) -> tuple[Path, Path]:
    """Dump + screenshot together — returns (dump_path, screen_path)."""
    d = dumps_window(step)
    s = screenshot(step)
    return d, s


# ── XML helpers (proper ElementTree, not grep) ────────────────────────────
def _bounds_to_rect(b: str) -> tuple[int, int, int, int] | None:
    """bounds="[11,147][143,279]" -> (x1, y1, x2, y2).
    Uses a regex for the literal brackets instead of splitting on
    brackets to avoid miscounts on attribute values that themselves
    contain brackets (Flutter rarely does, but we don't want a silent
    off-by-one from a future Flutter quirk).
    """
    m = re.match(r"\[(\d+),(\d+)\]\[(\d+),(\d+)\]", b or "")
    if not m:
        return None
    return tuple(int(x) for x in m.groups())


def parse_dump(path: Path):
    """xml.etree tree → root Element.  Raises on genuine XML errors
    (which is exactly why we use a real parser instead of grep)."""
    return ET.parse(path).getroot()


def find(root, **predicates) -> list:
    """Filter the node tree by an arbitrary combination of predicates.
    Supported keys (all optional):
        content_desc_eq         match content-desc exactly
        content_desc_starts     match content-desc prefix
        content_desc_contains   match content-desc substring (case-sensitive)
        text_eq                 match text exactly
        class_eq                match class exactly
        clickable_eq            'true' / 'false'
        bounds_y_lt             rect.y1 < n
        bounds_y_gt             rect.y3 > n
        bounds_x_lt             rect.x2 < n
    Returns the (ordered) list of matching <node> elements. Predicates are
    AND-composed — a node must match every supplied key.
    """
    cls_pred = predicates.get("class_eq")
    clickable_pred = predicates.get("clickable_eq")
    desc_eq = predicates.get("content_desc_eq")
    desc_starts = predicates.get("content_desc_starts")
    desc_contains = predicates.get("content_desc_contains")
    text_eq = predicates.get("text_eq")
    y_lt = predicates.get("bounds_y_lt")
    y_gt = predicates.get("bounds_y_gt")

    matches: list = []
    for n in root.iter("node"):
        if cls_pred is not None and n.attrib.get("class", "") != cls_pred:
            continue
        if clickable_pred is not None and n.attrib.get("clickable", "") != clickable_pred:
            continue
        if desc_eq is not None and n.attrib.get("content-desc", "") != desc_eq:
            continue
        if desc_starts is not None and not n.attrib.get("content-desc", "").startswith(desc_starts):
            continue
        if desc_contains is not None and desc_contains not in (n.attrib.get("content-desc", "") or ""):
            continue
        if text_eq is not None and n.attrib.get("text", "") != text_eq:
            continue
        if y_lt is not None or y_gt is not None:
            r = _bounds_to_rect(n.attrib.get("bounds", ""))
            if r is None:
                continue
            if y_lt is not None and not (r[1] < y_lt):
                continue
            if y_gt is not None and not (r[3] > y_gt):
                continue
        matches.append(n)
    return matches


# ── Driving ───────────────────────────────────────────────────────────────
def _tap_in_node(node, *, frac_x: float = 0.5, frac_y: float = 0.5) -> tuple[int, int]:
    """Tap at fractional position inside `node`'s bounds. Pass
    `frac_y=0.3` to bias toward the TOP of the node rather than the
    centre — the Android system gesture-nav bottom inset is 48 dp
    (≈132 px at density 440 on the Pixel 5 AVD, ≈90 px on density 320),
    so dead-centre taps on a control whose bottom edge sits within
    that inset will be eaten by the home gesture recognizer. The
    720×1280 wm-override walk confirmed this empirically: dead-centre
    on a 137-px-tall End Match tile at [0,1143][720,1280] landed at
    y=1211, which sits 21 px inside the ~1232 inset cutoff, and the
    dialog never opened. Default 0.5 preserves the existing
    dead-centre tap semantics for everything else.
    """
    rect = _bounds_to_rect(node.attrib["bounds"])
    if rect is None:
        raise ValueError(f"unparseable bounds: {node.attrib['bounds']!r}")
    x = int(rect[0] + (rect[2] - rect[0]) * frac_x)
    y = int(rect[1] + (rect[3] - rect[1]) * frac_y)
    return x, y


def tap_node(node, *, label: str, frac_y: float = 0.5) -> None:
    """Tap `node`. Pass `frac_y` to bias the tap point away from the
    centre; see `_tap_in_node` for the Android system-gesture rationale."""
    x, y = _tap_in_node(node, frac_x=0.5, frac_y=frac_y)
    cd = node.attrib.get("content-desc", "")
    tx = node.attrib.get("text", "")
    cls = node.attrib.get("class", "")
    print(f"   ▶ tap ({x:4d},{y:4d})  [{label}]  desc={cd!r}  text={tx!r}  class={cls}")
    adb_dev("shell", "input", "tap", str(x), str(y))


def tap_first(matches, *, step: str, label: str, dump: Path, frac_y: float = 0.5) -> None:
    if not matches:
        raise SystemExit(f"   ✗ no match for {label!r} in {dump}")
    tap_node(matches[0], label=label, frac_y=frac_y)


def tap_desc(desc: str, *, step: str, dump: Path | None = None,
            starts: bool = False, **extra) -> None:
    """Find a node by content-desc on the most recent dump and tap it.
    Returns the matching node so callers can re-inspect if needed."""
    if dump is None:
        dump = dumps_window(step)
    root = parse_dump(dump)
    if starts:
        nodes = find(root, content_desc_starts=desc, **extra)
    else:
        nodes = find(root, content_desc_eq=desc, **extra)
    tap_first(nodes, step=step, label=f"desc={desc!r}", dump=dump)


def _build_parent_map(root) -> dict:
    """{child Element -> parent Element} — uiautomator dumps don't expose
    parent pointers but ET only stores child lists, so we reverse-walk in
    one pass. Cheap and lets us scope searches to subtrees (e.g. find
    'End Match' only inside the 'Paused' bottom-sheet container)."""
    return {child: parent for parent in root.iter() for child in parent}


def find_within(root, *, ancestor_content_desc: str, **predicates) -> list:
    """Find nodes whose ancestor has content-desc = ancestor_content_desc.
    Predicate signatures delegate to `find()` (content_desc_eq,
    content_desc_contains, class_eq, clickable_eq, text_eq, etc.) — adding
    a new predicate to `find()` automatically surfaces here. This is the
    right tool when the same widget text appears in multiple places on
    screen (e.g. 'End Match' appears both as a bottom-bar Button on the
    live screen AND as a ListTile in the pause menu bottom sheet).
    """
    pmap = _build_parent_map(root)

    def _has_matching_ancestor(n) -> bool:
        cur: object = n
        while cur in pmap:
            cur = pmap[cur]
            if cur.attrib.get("content-desc", "") == ancestor_content_desc:
                return True
        return False

    return [n for n in find(root, **predicates) if _has_matching_ancestor(n)]


def _history_cards_in_lower_half(
    root,
    *,
    screen_h: int,
    match_type_label: str,
    dump_path: Path,
) -> list:
    """Helper for STEPS 9 + 11: collect clickable Card-style nodes whose
    content-desc contains `match_type_label` and whose bounds sit in
    the lower half of the viewport (so the Settings action above the
    History section header is excluded). Parameterising the label lets
    a future Singles walk (or any custom setup preset) re-use the same
    lower-half / bounds-validation heuristic without duplicating it —
    the previous `Doubles`-hardcoded helper would silently return an
    empty list for a Singles variant, and STEP 9 would SystemExit with
    a misleading "no Doubles card" message. Raises on malformed bounds
    via the same `SystemExit('   ✗ ...')` idiom the rest of the walk
    uses, and now includes the dump path so the operator can inspect
    the offending XML when `uiautomator` corrupts an attribute.
    """
    out: list = []
    for n in find(root, class_eq="android.widget.Button", clickable_eq="true"):
        if match_type_label not in (n.attrib.get("content-desc") or ""):
            continue
        rect = _bounds_to_rect(n.attrib.get("bounds", ""))
        if rect is None:
            raise SystemExit(
                f"   ✗ malformed bounds on {match_type_label} card: "
                f"{n.attrib.get('bounds', '')!r} — dump: {dump_path}"
            )
        if rect[1] >= screen_h * 0.40:
            out.append(n)
    # Sort by y1 ascending so the caller picks the topmost (most-recent)
    # entry regardless of upstream order in completedMatchesProvider.
    # Belt-and-suspenders: mirror the filter branch's `.get()` so the
    # sort step is symmetric if some future refactor drops the
    # upstream SystemExit guard.
    out.sort(key=lambda n: _bounds_to_rect(n.attrib.get("bounds", ""))[1])
    return out


def tap_desc_scrollable(
    desc: str,
    *,
    step: str,
    max_attempts: int = 5,
    swipe_y_start: int | None = None,
    swipe_y_end: int | None = None,
    swipe_dur_ms: int = 300,
) -> bool:
    """Tap a node by content-desc, scrolling the screen if the node is not
    yet in the visible viewport. Flutter's ListView only mounts widgets
    into the rendered tree once they're scrolled in, so a static find()
    can fail even when the target is a few hundred px below the fold.

    Loop: dump → find → if absent, swipe up (content scrolls down) → dump
    again. After max_attempts unsuccessful scroll-and-find cycles we give
    up and return False so the caller can decide whether to bail.

    Swipe y-coords default to ~85% / ~35% of `_SCREEN_H` (which main()
    refreshes from `wm size` at startup) so the gesture stays inside
    the viewport on any display size. Override via the explicit kwargs
    if a particular screen needs a custom travel distance."""
    if swipe_y_start is None:
        swipe_y_start = int(_SCREEN_H * 0.85)
    if swipe_y_end is None:
        swipe_y_end = int(_SCREEN_H * 0.35)
    for i in range(max_attempts):
        dump = dumps_window(step)
        root = parse_dump(dump)
        nodes = find(root, content_desc_eq=desc)
        if nodes:
            print(f"   ✓ '{desc}' visible after {i} scroll(s)")
            tap_node(nodes[0], label=f"desc={desc!r}")
            return True
        # Swipe up: gesture from low y to high-ish y so content moves down
        # (and the next-page widgets scroll into view).
        adb_dev(
            "shell", "input", "swipe",
            "540", str(swipe_y_start),
            "540", str(swipe_y_end),
            str(swipe_dur_ms),
        )
        time.sleep(0.6)
    return False


# ── Flow ──────────────────────────────────────────────────────────────────
def main() -> int:
    # Windows python defaults stdout to cp1252 which can't encode ✓ / ⚠
    # / ▶ etc.  Force UTF-8 so the log lines print cleanly regardless of
    # the host console encoding.
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
        sys.stderr.reconfigure(encoding="utf-8", errors="replace")
    except (AttributeError, OSError):
        pass  # Python <3.7 (reconfigure) or a non-replaceable stream

    # Parse CLI args HERE (not at module-import time) so a downstream
    # `import e2e_walk` doesn't crash on the parent process's argv. The
    # .resolve() + mkdir() pair also promotes path typos from "fails
    # mid-walk inside dumps_window()" to "fails immediately at startup".
    # Single-script end-to-end driver — module-level config rebinds are
    # the right call here; threading settings through every helper
    # (`parse_dump`, `find`, `_tap_in_node`, taps, ...) would expand
    # the public API without test-ability payoff.
    args = _parse_args()
    global PKG, ACT, DEVICE, OUT  # noqa: PLW0603
    PKG = args.pkg
    # Accept both forms `--activity .MainActivity` and `--activity
    # com.example.pickletrack.MainActivity` (fully qualified). `am
    # start -n` accepts either, but we normalise downstream so the
    # rest of the script doesn't need to care which came in.
    if args.activity.startswith(".") or "." not in args.activity:
        ACT = f"{PKG}/{args.activity.lstrip('.')}"
    else:
        ACT = args.activity
    DEVICE = args.device
    OUT = args.out.resolve()
    OUT.mkdir(parents=True, exist_ok=True)

    print(f"Output dir: {OUT}")
    print(f"Device:     {DEVICE}")
    print(f"Pkg:        {PKG}")
    # Surface Activity only when it differs from the default — printing
    # it unconditionally shifts the 99%-case log shape, which breaks
    # downstream grep scripts that match the `Device:` / `Pkg:` /
    # `Screen:` line block. Override `--activity` always wins.
    # Only print the banner line when --activity was actually overridden;
    # comparing the *composed* ACT would also fire on a bare `--pkg` change,
    # which would surprise anyone who reads the log expecting the canonical
    # 4-line banner shape.
    if args.activity != _DEFAULT_ACTIVITY:
        print(f"Activity:   {ACT}  (custom)")
    print()

    # Sanity check the emulator first.
    rc, devs, _ = adb("devices")
    if not re.search(rf"{DEVICE}\s+device", devs):
        print(f"ERROR: {DEVICE} not online.\n{devs}")
        return 1

    # Resolve the active display size so swipe gestures work on any
    # device, not just the 2340-tall emulator we developed against.
    w, h = _get_screen_size()
    print(f"Screen:    {w}x{h}\n")

    # ── 0 — clean cold launch ─────────────────────────────────────────
    print("STEP 0  Cold launch (force-stop + pm clear + am start)")
    adb_dev("shell", "am", "force-stop", PKG)
    adb_dev("shell", "pm", "clear", PKG)
    adb_dev("logcat", "-c")
    adb_dev("shell", "am", "start", "-W", "-n", ACT)
    time.sleep(8)  # let DB initialise + theme load
    snap("01_home_after_launch")

    # ── 1 — Home → tap Standard Start card ────────────────────────────
    print("\nSTEP 1  Tap 'Standard Start' action card on Home")
    dump = dumps_window("01_home_after_launch")
    root = parse_dump(dump)
    card = find(root, content_desc_starts="Standard Start")
    if not card:
        raise SystemExit("   ✗ Home: 'Standard Start' card not found")
    print(f"   ✓ Home card content-desc: {card[0].attrib.get('content-desc','')!r}")
    tap_node(card[0], label="Standard Start card")
    time.sleep(2.0)

    # ── 2 — Bottom sheet appears, capture it ──────────────────────────
    print("\nSTEP 2  Bottom sheet appears (Quick Start / Standard Start defaults)")
    snap("02_bottom_sheet")
    # Pump the Edit Setup button as a fallback proof — actually no, the
    # user wanted us to go through to Setup. Tap "Start Match" on the sheet
    # which routes to /match/setup?quick=true (same destination as Edit).
    tap_desc("Start Match", step="02_bottom_sheet")
    time.sleep(3.0)

    # ── 3 — Setup screen appears, tap Start Match ────────────────────
    # The Start Match FilledButton sits at the bottom of a tall form
    # ListView so it's not rendered into the uiautomator hierarchy until
    # we scroll it into view. Use the scroll-aware helper.
    print("\nSTEP 3  Setup screen → tap Start Match (creates match in DB)")
    snap("03_setup_screen")
    if not tap_desc_scrollable("Start Match", step="03_setup_screen"):
        raise SystemExit("   ✗ 'Start Match' not visible after 5 scroll attempts")
    time.sleep(4.0)  # createMatchInDb + nav to live

    # ── 4 — Live match screen, fresh ─────────────────────────────────
    print("\nSTEP 4  Live match screen, fresh (0-0-2 state)")
    live_dump, live_png = snap("04_live_initial")
    root = parse_dump(live_dump)

    # Sanity check the live screen actually rendered — we expect the
    # score-call content-desc which the Semantics wrapper emits.
    score_calls = find(root, content_desc_starts="Score call:")
    if not score_calls:
        raise SystemExit(f"   ✗ Live screen did not render score callout — see {live_dump}")
    print(f"   ✓ Score callout content-desc: {score_calls[0].attrib.get('content-desc','')!r}")

    # Also look for the AppBar pause-icon-styled button near the top
    # (NAF Button with bounds in the AppBar region).
    pause_buttons = find(root, class_eq="android.widget.Button",
                         clickable_eq="true", bounds_y_lt=300)
    if not pause_buttons:
        raise SystemExit(f"   ✗ No leading Button found in AppBar of {live_dump}")
    print(f"   ✓ AppBar Buttons (top region): {len(pause_buttons)}  bounds={pause_buttons[0].attrib.get('bounds','')}")

    # ── 5 — Tap pause → bottom sheet (Paused / Resume / End Match) ────
    print("\nSTEP 5  Tap leading pause icon → shows pause menu sheet")
    tap_node(pause_buttons[0], label="AppBar leading pause button")
    time.sleep(2.0)
    snap("05_pause_menu")
    # Verify the sheet title is visible (Flutter renders 'Paused' as
    # a Text widget inside the sheet).
    dump = dumps_window("05_pause_menu")
    root = parse_dump(dump)
    title = find(root, text_eq="Paused")
    if not title:
        # Flutter sometimes surfaces text only as content-desc. Fallback.
        title = find(root, content_desc_starts="Paused")
    if not title:
        print("   ⚠ 'Paused' title not surfaced in dump — sheet may render differently")
    else:
        print("   ✓ Pause sheet title 'Paused' found.")

    # Tap the End Match *list-tile inside the pause sheet*. The same
    # 'End Match' label also appears on the live screen's bottom-bar
    # outlined button (off-screen while the sheet is open, but still
    # captures if Flutter has any deferred semantics). Scope the lookup
    # to the 'Paused' container subtree so we get the sheet's tile, not
    # anything bleeding in from the live screen behind the scrim.
    dump = dumps_window("05_pause_menu")
    root = parse_dump(dump)
    end_tile = find_within(
        root,
        ancestor_content_desc="Paused",
        content_desc_eq="End Match",
    )
    if not end_tile:
        raise SystemExit(f"   ✗ No 'End Match' found inside 'Paused' container — dump: {dump}")
    # Bias the tap toward the top of the ListTile (frac_y=0.3) because
    # on small viewports the tile sits at the bottom edge where
    # Android's system-gesture nav would swallow a dead-centre tap
    # (the centre of [0,1143][720,1280] is at y=1211, which is *inside*
    # the home-zone on Android 11+ gesture nav).
    tap_first(end_tile, step="05_pause_menu",
              label="End Match list tile", dump=dump, frac_y=0.3)
    time.sleep(2.0)

    # ── 6 — Confirmation dialog ─────────────────────────────────────
    print("\nSTEP 6  'End Match' confirmation dialog appears")
    snap("06_confirm_dialog")
    dump = dumps_window("06_confirm_dialog")
    root = parse_dump(dump)
    # Pick the dialog's destructive End Match by filtering to the
    # upper 80% of the viewport (Material centres the AlertDialog around
    # ~50% of height; live screen's bottom-bar End Match sits at ~95%
    # and the pause-menu's ListTile at ~89% on 720×1280). This drops the
    # false positives regardless of viewport size — `bounds_y_gt=1300`
    # was off-screen on 1280-tall (walk failed there) and bare `find`
    # would surface the live bottom-bar copy.
    end_button = []
    for n in find(root, content_desc_eq="End Match",
                  class_eq="android.widget.Button",
                  clickable_eq="true"):
        rect = _bounds_to_rect(n.attrib.get("bounds", ""))
        if rect is not None and rect[1] < _SCREEN_H * 0.80:
            end_button.append(n)
    if not end_button:
        raise SystemExit(
            f"   ✗ No dialog 'End Match' in upper 80% (SCREEN_H={_SCREEN_H}) — dump: {dump}"
        )
    if len(end_button) > 1:
        # Sort by y1 ascending — pick the topmost surviving candidate.
        end_button.sort(key=lambda n: _bounds_to_rect(n.attrib["bounds"])[1])
        print(f"   (info) {len(end_button)} candidate dialog 'End Match' Buttons; picking topmost")
    tap_node(end_button[0], label="End Match confirm (destructive, dialog)")
    time.sleep(4.0)  # endMatch() + go('/') + push('/match/$id')

    # ── 7 — Match Details screen ────────────────────────────────────
    print("\nSTEP 7  Match Details screen renders")
    snap("07_details_after_endmatch")
    dump = dumps_window("07_details_after_endmatch")
    root = parse_dump(dump)
    # AppBar title is 'Match Details'.  Check both 'text' and 'desc'.
    details_title = find(root, text_eq="Match Details")
    if not details_title:
        details_title = find(root, content_desc_starts="Match Details")
    if not details_title:
        print(f"   ⚠ 'Match Details' title not surfaced — see {dump}")
    else:
        print(f"   ✓ Match Details AppBar title visible.")
    # Winner banner text — accept either 'Team A Wins!' or 'Team B Wins!'.
    winner = (
        find(root, content_desc_starts="Team A Wins!")
        or find(root, content_desc_starts="Team B Wins!")
    )
    if not winner:
        # Relaxed fallback — any node whose semantic label ends in 'Wins!'.
        for n in root.iter("node"):
            if n.attrib.get("content-desc", "").endswith("Wins!"):
                winner = [n]
                break
    if winner:
        print(f"   ✓ Winner banner: {winner[0].attrib.get('content-desc','')!r}")
    else:
        print("   ⚠ Winner banner text not detected.")

    # ── 8 — Also confirm Home / Resume state ───────────────────────
    print("\nSTEP 8  Back to Home: confirm match is in history (no resume banner)")
    adb_dev("shell", "input", "keyevent", "KEYCODE_BACK")
    time.sleep(2.0)
    snap("08_home_post_endmatch")

    # ── 9 — Tap history Card → navigation to Match Details ──────────
    # A `_CompletedMatchCard` collapses the score, type label, date and
    # duration into a single uiautomator content-desc; "Doubles"/"Singles"
    # is in that string so we filter on substring rather than fragile
    # regex on the score prefix. Scope to the lower half of the viewport
    # so the Settings action above the History section header doesn't
    # pollute the result.
    #
    # Precondition: STEP 6 must have successfully ended the match — this
    # walk does NOT pre-seed history; it conditions on the end-match path.
    # If STEP 6 fails (e.g. on the 720×1280 override where the dialog
    # never opens), the prior STEP raises SystemExit and STEPS 9-11
    # simply don't run.
    print("\nSTEP 9  Home → tap History card (topmost Doubles match)")
    dump = dumps_window("09_home_with_history_card")
    root = parse_dump(dump)
    cards = _history_cards_in_lower_half(
        root,
        screen_h=_SCREEN_H,
        match_type_label="Doubles",
        dump_path=dump,
    )
    if not cards:
        raise SystemExit(
            f"   ✗ No Doubles history card within lower-half viewport — dump: {dump}"
        )
    print(f"   ✓ History card surface: {cards[0].attrib.get('content-desc','')!r}")
    tap_node(cards[0], label="History card (topmost Doubles)")
    time.sleep(2.0)

    # ── 10 — Match Details (read-only, reached from History) ────────
    # The destination screen shares the AppBar title "Match Details" +
    # a winner banner ("Team A Wins!"/"Team B Wins!") with the post-
    # endmatch Details screen — but the entry path is different:
    # end-match forces `go('/') + push('/match/$id')` while history-tap
    # is just `context.push('/match/${match.id}')`. The screen itself
    # should be identical; we verify title + winner banner so any
    # future route-stack divergence surfaces in CI.
    print("\nSTEP 10  Match Details (read-only, reached via History)")
    snap("10_details_from_history")
    dump = dumps_window("10_details_from_history")
    root = parse_dump(dump)
    details_title = find(root, text_eq="Match Details")
    if not details_title:
        details_title = find(root, content_desc_starts="Match Details")
    if not details_title:
        print(f"   ⚠ 'Match Details' title not surfaced — see {dump}")
    else:
        print("   ✓ Match Details AppBar title visible (history entry).")
    winner = (
        find(root, content_desc_starts="Team A Wins!")
        or find(root, content_desc_starts="Team B Wins!")
    )
    if not winner:
        # Fallback: ends-with 'Wins!' lookup (in case the prefix differs).
        for n in root.iter("node"):
            if n.attrib.get("content-desc", "").endswith("Wins!"):
                winner = [n]
                break
    if winner:
        print(f"   ✓ Winner banner: {winner[0].attrib.get('content-desc','')!r}")
    else:
        print("   ⚠ Winner banner not detected in history-driven Details.")

    # ── 11 — Back from Match Details → Home ─────────────────────────
    # From Step 7's post-endmatch Details the back arrow does `go('/')`
    # which clears the stack. From this history-driven Details the
    # back arrow pops the route and returns to the Home underneath.
    # Either way we land on Home, and we capture a sanity dump to
    # confirm the History card is still listed (this runner never
    # DELETEs, so back-nav is a state-preserving op).
    print("\nSTEP 11  Back → Home (History card should still be listed)")
    adb_dev("shell", "input", "keyevent", "KEYCODE_BACK")
    time.sleep(2.0)
    snap("11_home_post_history_back")
    dump = dumps_window("11_home_post_history_back")
    root = parse_dump(dump)
    still_there = _history_cards_in_lower_half(
        root,
        screen_h=_SCREEN_H,
        match_type_label="Doubles",
        dump_path=dump,
    )
    if still_there:
        print(f"   ✓ History card still listed ({len(still_there)} match).")
    else:
        print(f"   ⚠ History card not surfaced after back — see {dump}")

    # Pull a logcat slice filtered to the pickletrack PID so unrelated
    # system events don't drown out our app's FATAL / sqlite FFI
    # errors. `--pid` is the right tool here because `logcat -t 200`
    # only captures the last 200 lines, which is rarely enough to
    # surface a regression that happened earlier in the run.
    print("\nLOGCAT tail (PID-filtered for pickletrack/flutter/sqlite errors):")
    rc, pid_out, _ = adb_dev("shell", "pidof", PKG)
    pid = (pid_out or "").strip()
    if pid:
        rc, out, _ = adb_dev("logcat", "-d", "--pid", pid)
    else:
        # Fallback if the app crashed before we got here (PID gone) —
        # pull the last 5000 lines and rely on keyword filtering.
        rc, out, _ = adb_dev("logcat", "-d", "-t", "5000")
    interesting = "\n".join(
        ln for ln in out.splitlines()
        if any(k in ln for k in ("FATAL", "libsqlite3",
                                  "dlopen", "sqlite3_flutter_libs",
                                  "Exception", "Error"))
    )
    print(interesting or "  (no interesting lines)")

    print("\nArtifacts written under:")
    for p in sorted(OUT.glob("walk_*_*")):
        size = p.stat().st_size
        print(f"  {p.name:40s}  {size:>9d} bytes")
    print("\nDONE.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
