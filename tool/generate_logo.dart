// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:math';

import 'package:image/image.dart';

/// Generates the PickleTrack app icon — a stylised geometric P+T
/// monogram inspired by the Flutter "F" logo.
///
/// Run with: dart run tool/generate_logo.dart
void main() {
  const size = 1024;
  const padding = 120;
  const effectiveSize = size - padding * 2;

  // Brand palette
  final bgColor = ColorUint8.rgba(74, 140, 63, 255); // #4A8C3F court green
  final letterColor = ColorUint8.rgba(255, 255, 255, 255);
  final shadowColor = ColorUint8.rgba(0, 0, 0, 60);

  // ── Full icon with background ──
  final icon = Image(width: size, height: size);
  fill(icon, color: bgColor);

  // Subtle radial gradient overlay for depth
  _drawRadialGradient(icon, size, bgColor);

  // Draw the P+T monogram
  _drawMonogram(icon, size, padding, effectiveSize, letterColor, shadowColor);

  // Save full icon
  Directory('assets/icon').createSync(recursive: true);
  File('assets/icon/icon.png').writeAsBytesSync(encodePng(icon));
  print('✓ assets/icon/icon.png');

  // ── Foreground only (for adaptive icons) ──
  final fg = Image(width: size, height: size);
  // Transparent background
  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      fg.setPixel(x, y, ColorUint8.rgba(0, 0, 0, 0));
    }
  }
  _drawMonogram(fg, size, padding, effectiveSize, letterColor, shadowColor);
  File('assets/icon/icon_fg.png').writeAsBytesSync(encodePng(fg));
  print('✓ assets/icon/icon_fg.png');
}

void _drawRadialGradient(Image img, int size, Color centerColor) {
  final cx = size / 2;
  final cy = size / 2;
  final maxDist = sqrt(cx * cx + cy * cy);

  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      final dist = sqrt((x - cx) * (x - cx) + (y - cy) * (y - cy));
      final t = dist / maxDist;
      // Slightly darker toward edges
      final factor = 1.0 - t * 0.15;
      final r = (centerColor.r * factor).round().clamp(0, 255);
      final g = (centerColor.g * factor).round().clamp(0, 255);
      final b = (centerColor.b * factor).round().clamp(0, 255);
      img.setPixel(x, y, ColorUint8.rgba(r, g, b, 255));
    }
  }
}

void _drawMonogram(
  Image img,
  int size,
  int padding,
  int effectiveSize,
  Color letterColor,
  Color shadowColor,
) {
  final cx = size ~/ 2;
  final cy = size ~/ 2;

  // The monogram occupies a square region in the center.
  // P is on the left, T is on the right, they interlock.
  final letterW = effectiveSize * 0.55; // width of each letter
  final letterH = effectiveSize * 0.75; // height of letters
  final stroke = effectiveSize * 0.18; // stroke thickness
  final gap = effectiveSize * 0.04; // gap between P and T
  final round = stroke * 0.35; // corner rounding

  // Shadow offset
  const shadowOff = 8;

  // ── P (left) ──
  final pLeft = (cx - letterW - gap / 2).round();
  final pTop = (cy - letterH / 2).round();
  final pRight = pLeft + letterW.round();
  final pBottom = pTop + letterH.round();

  // Draw P shadow
  _drawP(img, pLeft + shadowOff, pTop + shadowOff, pRight + shadowOff,
      pBottom + shadowOff, stroke.round(), round.round(), shadowColor);
  // Draw P
  _drawP(img, pLeft, pTop, pRight, pBottom, stroke.round(), round.round(),
      letterColor);

  // ── T (right) ──
  final tLeft = (cx + gap / 2).round();
  final tTop = pTop;
  final tRight = tLeft + letterW.round();
  final tBottom = pBottom;

  // Draw T shadow
  _drawT(img, tLeft + shadowOff, tTop + shadowOff, tRight + shadowOff,
      tBottom + shadowOff, stroke.round(), round.round(), shadowColor);
  // Draw T
  _drawT(img, tLeft, tTop, tRight, tBottom, stroke.round(), round.round(),
      letterColor);
}

void _drawP(Image img, int left, int top, int right, int bottom, int stroke,
    int round, Color color) {
  final bowlRadius = (right - left - stroke) ~/ 2;
  final bowlCy = top + (bottom - top) ~/ 2;
  final bowlCx = left + stroke + bowlRadius;

  // Vertical stem
  _fillRoundedRect(img, left, top, left + stroke, bottom, round, color);

  // Bowl (right side semi-circle shape)
  for (var y = top + stroke ~/ 2; y < bottom - stroke ~/ 2; y++) {
    for (var x = left + stroke; x < right; x++) {
      final dy = y - bowlCy;
      final dx = x - bowlCx;
      final dist = sqrt(dx * dx + dy * dy);
      // Outer edge of bowl
      if (dist <= bowlRadius + 2 && dist >= bowlRadius - stroke) {
        // Only the right half of the circle
        if (x >= bowlCx) {
          img.setPixel(x, y, color);
        }
      }
    }
  }

  // Fill the top and bottom horizontal connectors of the bowl
  _fillRoundedRect(img, left + stroke ~/ 2, top, bowlCx + bowlRadius,
      top + stroke, round, color);
  _fillRoundedRect(img, left + stroke ~/ 2, bottom - stroke,
      bowlCx + bowlRadius, bottom, round, color);
}

void _drawT(Image img, int left, int top, int right, int bottom, int stroke,
    int round, Color color) {
  // Horizontal bar (top)
  _fillRoundedRect(img, left, top, right, top + stroke, round, color);

  // Vertical stem (centered)
  final stemX = (left + right) ~/ 2 - stroke ~/ 2;
  _fillRoundedRect(img, stemX, top, stemX + stroke, bottom, round, color);
}

void _fillRoundedRect(
    Image img, int x1, int y1, int x2, int y2, int radius, Color color) {
  final left = x1 < x2 ? x1 : x2;
  final top = y1 < y2 ? y1 : y2;
  final right = x1 < x2 ? x2 : x1;
  final bottom = y1 < y2 ? y2 : y1;

  for (var y = top; y < bottom; y++) {
    for (var x = left; x < right; x++) {
      // Distance to nearest edge
      final dx = x < left + radius
          ? left + radius - x
          : (x >= right - radius ? x - (right - radius) + 1 : 0);
      final dy = y < top + radius
          ? top + radius - y
          : (y >= bottom - radius ? y - (bottom - radius) + 1 : 0);
      final dist = sqrt(dx * dx + dy * dy);

      if (dx == 0 || dy == 0 || dist <= radius) {
        img.setPixel(x, y, color);
      }
    }
  }
}
