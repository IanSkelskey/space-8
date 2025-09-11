from midiutil import MIDIFile

# Config
tempo = 150            # upbeat, quick fanfare
root = 72              # C5 as tonic
major_third = root + 4
fifth = root + 7
octave = root + 12
dominant = root + 7    # G
dominant_oct = dominant + 12

# Create a MIDI file with 4 monophonic tracks (PICO-8 style)
midi = MIDIFile(4)
for i in range(4):
    midi.addTempo(i, 0, tempo)

def add(track, channel, pitch, time, duration, vel=90):
    midi.addNote(track, channel, pitch, time, duration, vel)

# Fanfares are short: 2 bars of 4/4 (8 beats total)
# Track 0: Lead melody (bright and triumphant)
t = 0
lead = [
    # Bar 1
    (root, 0.5), (major_third, 0.5), (fifth, 0.5), (root + 11, 0.5),  # C E G B
    (octave, 0.5), (0, 0.25), (octave - 3, 0.25), (fifth, 0.5),       # C6 (rest) A G
    # Bar 2
    (major_third, 0.5), (fifth, 0.5), (octave, 0.5), (octave + 4, 0.5),  # E G C6 E6
    (octave - 1, 0.5), (octave, 1.0)                                     # B5 (leads) C6 (final)
]
for p, d in lead:
    if p > 0:
        add(0, 0, p, t, d * 0.92, 95)
    t += d

# Track 1: Brass-like stabs (monophonic chord rolls)
# Short arpeggiated hits on I and V to support the melody
t = 0
stabs = [
    # Bar 1: C major hit at beat 0 and 2
    (root - 24, 0.25), (root - 12, 0.25), (root, 0.5),     # C2 C3 C4
    (root - 19, 0.25), (root - 7, 0.25), (root + 4, 0.5),  # G2 G3 E4
    # Bar 2: G major then cadence back to C
    (dominant - 24, 0.25), (dominant - 12, 0.25), (dominant, 0.5),   # G2 G3 G4
    (root - 24, 0.25), (root - 12, 0.25), (root, 0.5)                 # C2 C3 C4
]
t = 0
for p, d in stabs:
    add(1, 0, p, t, d * 0.9, 78)
    t += d

# Track 2: Quick flourish into the final note
# A short ascending run that lands on the tonic
flourish = [
    (fifth, 0.125), (major_third + 12, 0.125), (fifth + 12, 0.125), (octave, 0.125),
    (octave + 2, 0.125), (octave + 4, 0.125), (octave + 5, 0.125), (octave + 7, 0.125),
    (octave, 0.5)
]
t = 6.5  # start just before the end for a nice lead-in
for p, d in flourish:
    add(2, 0, p, t, d * 0.85, 70)
    t += d

# Track 3: Percussion (channel 9 in General MIDI)
# Kick at start, snare on 2 and 4, and a crash at the end
t = 0
for beat in range(8):
    if beat == 0:
        add(3, 9, 36, t, 0.2, 110)  # Kick
    if beat in (2, 6):
        add(3, 9, 38, t, 0.15, 95)  # Snare
    # Light hats to glue it together
    add(3, 9, 42, t, 0.05, 60)
    if beat < 7:
        add(3, 9, 42, t + 0.5, 0.05, 55)
    t += 1
# Final crash and hit on the last beat
add(3, 9, 49, 7.0, 0.8, 100)  # Crash cymbal
add(3, 9, 36, 7.0, 0.2, 105)  # Kick reinforce

# Write file
out_name = "pico8_level_fanfare.mid"
with open(out_name, "wb") as f:
    midi.writeFile(f)

print(f"Generated {out_name} - Short end-of-level fanfare")
print("Track 0: Lead fanfare")
print("Track 1: Brass-style stabs")
print("Track 2: Flourish into final")
print("Track 3: Percussion with final crash")
