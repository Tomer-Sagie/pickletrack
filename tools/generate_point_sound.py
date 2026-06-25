"""Generate a short "point scored" WAV file for PickleTrack.

Design: two-tone "bing" (C6 → E6) with exponential decay.
- Mono, 16-bit PCM, 22050 Hz
- Duration: ~120ms
- Sound: clean notification pop, pleasant on repeated triggers

Output: assets/sounds/point_scored.wav (CC0 — generated from scratch).
"""
import wave
import struct
import math
import os

SAMPLE_RATE = 22050
DURATION_SEC = 0.12  # 120ms — short and snappy
N_SAMPLES = int(SAMPLE_RATE * DURATION_SEC)

# Frequencies: C6 (1046.5 Hz) → E6 (1318.5 Hz), quick slide
F_START = 1046.5
F_END = 1318.5

samples = []
for i in range(N_SAMPLES):
    t = i / SAMPLE_RATE
    progress = i / N_SAMPLES
    # Frequency sweep (fast up-slide in first 40%, hold the rest)
    if progress < 0.4:
        freq = F_START + (F_END - F_START) * (progress / 0.4)
    else:
        freq = F_END
    # Envelope: fast attack (~5ms), exponential decay
    attack = min(1.0, t / 0.005)
    decay = math.exp(-t * 18)  # strong decay so it dies in ~120ms
    envelope = attack * decay
    # Sample value — 16-bit signed (-32768..32767)
    value = math.sin(2 * math.pi * freq * t) * envelope
    sample_int = int(value * 30000)  # ~91% amplitude, leave headroom
    samples.append(struct.pack('<h', sample_int))

out_path = os.path.join('assets', 'sounds', 'point_scored.wav')
os.makedirs(os.path.dirname(out_path), exist_ok=True)

with wave.open(out_path, 'wb') as w:
    w.setnchannels(1)         # mono
    w.setsampwidth(2)         # 16-bit
    w.setframerate(SAMPLE_RATE)
    w.writeframes(b''.join(samples))

print(f'Wrote {out_path}: {os.path.getsize(out_path)} bytes, '
      f'{N_SAMPLES} samples, {DURATION_SEC * 1000:.0f}ms')
