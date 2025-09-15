from midiutil import MIDIFile
"""
Station / Shop Groove
Looping chill-upbeat cue for PICO-8 style soundtrack.
Progression (8 beats, repeats): Cmaj7  Dm7  Em7  Dm7
We voice it with tasteful extensions & passing tones to keep it alive while staying light.
Tracks (monophonic each to mirror PICO-8 channel constraints):
 0 - Lead / counter melody (syncopated, airy)
 1 - Bass (syncopated root + approach tones)
 2 - Chord texture arpeggio / broken chords
 3 - Light percussion pulse (hat / soft kick / snaps implied)
Adjust TEMPO, LOOP_REPS, or the note tables to taste.
"""

TEMPO = 92           # slightly slower for more space / clarity
LOOP_REPS = 4        # how many times to repeat the 8-beat pattern in the MIDI
BEATS_PER_LOOP = 8   # 2 beats per chord (4 chords)
TOTAL_BEATS = BEATS_PER_LOOP * LOOP_REPS

# MIDI setup
midi = MIDIFile(4)
for tr in range(4):
    midi.addTempo(tr, 0, TEMPO)

def add(tr, ch, pitch, start, dur, vol):
    midi.addNote(tr, ch, pitch, start, dur, vol)

# Chord progression base (per 2 beats): Cmaj7 Dm7 Em7 Dm7
# We'll use these for generating arpeggios / guide tones.
CHORDS = [
    # name, root, quality, color tones (relative intervals in semitones from root)
    ("Cmaj7", 60, [0, 4, 7, 11, 14]),     # add 9 (D) for color
    ("Dm7",   62, [0, 3, 7, 10, 14]),     # add 9 (E)
    ("Em7",   64, [0, 3, 7, 10, 14]),     # add 9 (F#) - (optional) skip to keep diatonic -> use 14 (B) only
    ("Dm7",   62, [0, 3, 7, 10, 14]),
]

# Bass line: sparser — root sustain plus light pickup, alternating omission for air.
# (offset, interval, duration, velocity)
BASS_PATTERN = [
    (0.0, 0, 1.6, 68),      # longer root hold
    (1.6, 7, 0.3, 60),      # soft fifth pickup into next chord
]
BASS_PATTERN_MINOR = [
    (0.0, 0, 1.6, 68),
    (1.6, 5, 0.3, 58),      # 11th-ish color pickup (kept soft)
]

# Arpeggio pattern: thinned (fewer events, longer sustains) for clarity.
# (offset, tone_idx, length, velocity) — leave intentional gaps.
ARP_PATTERN = [
    (0.0, 0, 0.60, 50),
    (0.65, 2, 0.55, 52),
    (1.25, 4, 0.60, 54),    # color tone (9) sustained
]

# Lead cells: reduced to 2 notes per chord (motif + answer) for more breathing room.
LEAD_CELLS = [
    [(0.10, 64, 0.55, 74), (0.90, 71, 0.70, 70)],  # Cmaj7
    [(0.15, 65, 0.50, 72), (0.95, 69, 0.65, 68)],  # Dm7
    [(0.10, 67, 0.55, 74), (0.90, 71, 0.70, 70)],  # Em7
    [(0.15, 69, 0.50, 72), (0.95, 65, 0.65, 68)],  # Dm7 return
]

# Light percussion pattern (track 3) per 8-beat loop (hat pulse + soft kick on 1 & 5)
# Using GM channel 9 for conceptual mapping; when translating to PICO-8 convert manually.
PERC_EVENTS = [
    # beat, midi note, length, velocity
    (0.0, 36, 0.15, 85),  # Kick
    (0.0, 42, 0.05, 55),
    (0.5, 42, 0.05, 48),
    (1.0, 42, 0.05, 52),
    (1.5, 42, 0.05, 48),
    (2.0, 42, 0.05, 55),
    (2.5, 42, 0.05, 48),
    (3.0, 42, 0.05, 52),
    (3.5, 42, 0.05, 48),
    (4.0, 36, 0.15, 78),  # Kick (softer)
    (4.0, 42, 0.05, 55),
    (4.5, 42, 0.05, 48),
    (5.0, 42, 0.05, 52),
    (5.5, 42, 0.05, 48),
    (6.0, 42, 0.05, 55),
    (6.5, 42, 0.05, 48),
    (7.0, 42, 0.05, 52),
    (7.5, 42, 0.05, 48),
]

# Build tracks
for loop_i in range(LOOP_REPS):
    loop_start = loop_i * BEATS_PER_LOOP
    sparse_alt = (loop_i % 2 == 1)  # every second loop even sparser (omit some pickups)
    for ci, (name, root, tones) in enumerate(CHORDS):
        chord_start = loop_start + ci * 2
        # Bass
        pattern = BASS_PATTERN if "maj" in name else BASS_PATTERN_MINOR
        for off, interval, ln, vel in pattern:
            if sparse_alt and off > 1.4:  # drop pickup on alt loops
                continue
            add(1, 0, root + interval, chord_start + off, ln, vel - (4 if sparse_alt else 0))
        # Arp (maybe remove middle note on sparse loops)
        for idx,(off, tone_idx, ln, vel) in enumerate(ARP_PATTERN):
            if sparse_alt and idx==1: # drop mid articulation
                continue
            tone = tones[tone_idx % len(tones)]
            add(2, 0, root + tone, chord_start + off, ln, vel - (sparse_alt and 4 or 0))
        # Lead (second loop variant: only first note)
        cell = LEAD_CELLS[ci]
        for li,(off,pitch,ln,vel) in enumerate(cell):
            if sparse_alt and li==1:
                continue
            add(0, 0, pitch, chord_start + off, ln, vel - (sparse_alt and 6 or 0))
    # Percussion constant
    for beat, note, ln, vel in PERC_EVENTS:
        add(3, 9, note, loop_start + beat, ln, vel)

# A tiny tail so last notes are not clipped on export
TAIL = 0.25

with open("pico8_station_shop_groove.mid", "wb") as f:
    midi.writeFile(f)

print("Generated pico8_station_shop_groove.mid")
print(f"Tempo: {TEMPO} BPM | Loop length: {BEATS_PER_LOOP} beats | Repeats: {LOOP_REPS}")
print("Progression: Cmaj7  Dm7  Em7  Dm7")
print("Tracks: 0 Lead, 1 Bass, 2 Arp texture, 3 Light perc")
print("Feel free to trim or re-seed for token/space constraints when importing to PICO-8.")
