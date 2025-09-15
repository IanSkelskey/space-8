from midiutil import MIDIFile
"""
Station / Shop Groove (Half Duration Version)
-------------------------------------------
This is a derived script from `pico8_station_shop_groove.py` that produces an
IDENTICAL pattern construction logic, but only HALF the total duration by
reducing the loop repetitions from 4 to 2.

Original script parameters:
    TEMPO = 92
    BEATS_PER_LOOP = 8 (Cmaj7, Dm7, Em7, Dm7) => 4 two‑beat chords
    LOOP_REPS = 4  --> total beats = 32

Half version:
    LOOP_REPS = 2  --> total beats = 16 (first normal loop + one sparse loop)

Behavioral parity:
 - Keeps the alternating sparse variation via `sparse_alt = (loop_i % 2 == 1)`;
   with 2 loops you still get one "full" loop (loop 0) and one "sparser" loop (loop 1),
   matching the first half of the original 4-loop export.
 - All note generation logic, dynamics adjustments, and tail handling are unchanged.

Output file: `pico8_station_shop_groove_half.mid`
"""

TEMPO = 92            # same tempo
LOOP_REPS = 2         # HALF of original (was 4)
BEATS_PER_LOOP = 8    # unchanged
TOTAL_BEATS = BEATS_PER_LOOP * LOOP_REPS

# MIDI setup (4 monophonic concept tracks mapping to PICO-8 channels)
midi = MIDIFile(4)
for tr in range(4):
    midi.addTempo(tr, 0, TEMPO)

def add(tr, ch, pitch, start, dur, vol):
    midi.addNote(tr, ch, pitch, start, dur, vol)

# Chord progression per loop (2 beats each)
CHORDS = [
    ("Cmaj7", 60, [0, 4, 7, 11, 14]),
    ("Dm7",   62, [0, 3, 7, 10, 14]),
    ("Em7",   64, [0, 3, 7, 10, 14]),
    ("Dm7",   62, [0, 3, 7, 10, 14]),
]

# Bass patterns (major vs minor quality slight pickup difference)
BASS_PATTERN = [
    (0.0, 0, 1.6, 68),
    (1.6, 7, 0.3, 60),
]
BASS_PATTERN_MINOR = [
    (0.0, 0, 1.6, 68),
    (1.6, 5, 0.3, 58),
]

# Sparse arpeggio with intentional gaps
ARP_PATTERN = [
    (0.0, 0, 0.60, 50),
    (0.65, 2, 0.55, 52),
    (1.25, 4, 0.60, 54),
]

# Lead two-note motives per chord
LEAD_CELLS = [
    [(0.10, 64, 0.55, 74), (0.90, 71, 0.70, 70)],
    [(0.15, 65, 0.50, 72), (0.95, 69, 0.65, 68)],
    [(0.10, 67, 0.55, 74), (0.90, 71, 0.70, 70)],
    [(0.15, 69, 0.50, 72), (0.95, 65, 0.65, 68)],
]

# Light percussion (kick + hat pulses) per loop
PERC_EVENTS = [
    (0.0, 36, 0.15, 85),
    (0.0, 42, 0.05, 55),
    (0.5, 42, 0.05, 48),
    (1.0, 42, 0.05, 52),
    (1.5, 42, 0.05, 48),
    (2.0, 42, 0.05, 55),
    (2.5, 42, 0.05, 48),
    (3.0, 42, 0.05, 52),
    (3.5, 42, 0.05, 48),
    (4.0, 36, 0.15, 78),
    (4.0, 42, 0.05, 55),
    (4.5, 42, 0.05, 48),
    (5.0, 42, 0.05, 52),
    (5.5, 42, 0.05, 48),
    (6.0, 42, 0.05, 55),
    (6.5, 42, 0.05, 48),
    (7.0, 42, 0.05, 52),
    (7.5, 42, 0.05, 48),
]

# Build tracks (first full loop + one sparse loop)
for loop_i in range(LOOP_REPS):
    loop_start = loop_i * BEATS_PER_LOOP
    sparse_alt = (loop_i % 2 == 1)
    for ci, (name, root, tones) in enumerate(CHORDS):
        chord_start = loop_start + ci * 2
        # Bass
        pattern = BASS_PATTERN if "maj" in name else BASS_PATTERN_MINOR
        for off, interval, ln, vel in pattern:
            if sparse_alt and off > 1.4:
                continue
            add(1, 0, root + interval, chord_start + off, ln, vel - (4 if sparse_alt else 0))
        # Arp
        for idx, (off, tone_idx, ln, vel) in enumerate(ARP_PATTERN):
            if sparse_alt and idx == 1:  # drop middle articulation on sparse loop
                continue
            tone = tones[tone_idx % len(tones)]
            add(2, 0, root + tone, chord_start + off, ln, vel - (sparse_alt and 4 or 0))
        # Lead
        cell = LEAD_CELLS[ci]
        for li, (off, pitch, ln, vel) in enumerate(cell):
            if sparse_alt and li == 1:
                continue
            add(0, 0, pitch, chord_start + off, ln, vel - (sparse_alt and 6 or 0))
    # Percussion
    for beat, note, ln, vel in PERC_EVENTS:
        add(3, 9, note, loop_start + beat, ln, vel)

# Tail to avoid clipping release
TAIL = 0.25

with open("pico8_station_shop_groove_half.mid", "wb") as f:
    midi.writeFile(f)

print("Generated pico8_station_shop_groove_half.mid")
print(f"Tempo: {TEMPO} BPM | Loop length: {BEATS_PER_LOOP} beats | Repeats: {LOOP_REPS} (half duration)")
print("Progression: Cmaj7  Dm7  Em7  Dm7")
print("Tracks: 0 Lead, 1 Bass, 2 Arp texture, 3 Light perc (half version)")