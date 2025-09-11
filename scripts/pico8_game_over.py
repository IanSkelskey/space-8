from midiutil import MIDIFile

# Game Over theme: short, somber, and cohesive with the other PICO-8 style tracks
# 4 monophonic tracks (melody, bass, arpeggio/texture, light percussion)

tempo = 76  # slower, reflective
midi = MIDIFile(4)
for i in range(4):
    midi.addTempo(i, 0, tempo)


def add(track, channel, pitch, time, duration, volume=90):
    midi.addNote(track, channel, pitch, time, duration, volume)

# Key: A minor feel to match gameplay; 2 bars of 4/4 (8 beats total)
# Track 0: Falling melody motif that resolves quietly to A
melody = [
    # Bar 1 (descending sigh)
    (76, 0.5), (74, 0.5),  # E5, D5
    (72, 1.0),             # C5
    (69, 1.0),             # A4
    (67, 0.5), (64, 0.5),  # G4, E4
    # Bar 2 (fade to cadence)
    (62, 1.0),             # D4
    (60, 0.5), (0, 0.5),   # C4, rest
    (57, 1.0),             # A3
    (69, 1.0),             # A4 (soft final)
]

# Track 1: Sparse bass underpinning (A -> E -> A)
bass = [
    (45, 4.0),  # A2 sustain (bar 1)
    (40, 2.0),  # E2 (bar 2 first half)
    (45, 2.0),  # back to A2 (final half)
]

# Track 2: Gentle arpeggio texture (kept monophonic)
arp = [
    # Bar 1: A minor rolling
    (57, 0.5), (60, 0.5), (64, 0.5), (60, 0.5), (57, 0.5), (60, 0.5), (64, 0.5), (69, 0.5),
    # Bar 2: Brief E harmony then resolve to A
    (52, 0.5), (55, 0.5), (59, 0.5), (55, 0.5), (57, 0.5), (60, 0.5), (64, 0.5), (57, 0.5),
]

# Track 3: Very light percussion gestures for punctuation (channel 9 in GM)
# Kick at start, soft tom in the middle, light hats, gentle snare at the end
percussion = [
    (36, 0.2, 70, 0.0),  # Kick @0
    (42, 0.05, 35, 2.0), # Hat @2
    (41, 0.15, 45, 4.0), # Floor tom @4
    (42, 0.05, 35, 6.0), # Hat @6
    (38, 0.2, 60, 7.0),  # Soft snare @7 (close)
]

# Write tracks
# Melody (Track 0)
t = 0
for p, d in melody:
    if p > 0:
        add(0, 0, p, t, d * 0.92, 84)
    t += d

# Bass (Track 1)
t = 0
for p, d in bass:
    add(1, 0, p, t, d * 0.95, 72)
    t += d

# Arpeggio (Track 2)
t = 0
for p, d in arp:
    add(2, 0, p, t, d * 0.9, 62)
    t += d

# Percussion (Track 3, channel 9)
for note, dur, vel, when in percussion:
    add(3, 9, note, when, dur, vel)

# Emit file
out_name = "pico8_game_over.mid"
with open(out_name, "wb") as f:
    midi.writeFile(f)

print(f"Generated {out_name} - Short, somber game over cue")
print("Track 0: Falling minor melody to a soft A resolution")
print("Track 1: Sparse A–E–A bass support")
print("Track 2: Gentle A minor / E arpeggios")
print("Track 3: Light percussion punctuation")
