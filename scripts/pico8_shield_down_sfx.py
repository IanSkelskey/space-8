from midiutil import MIDIFile

# Create a MIDI file with 2 tracks for the shield down effect
midi = MIDIFile(2)
tempo = 180  # Faster tempo for quick sound effect
for i in range(2):
    midi.addTempo(i, 0, tempo)

def add(track, channel, pitch, time, duration, volume=90):
    midi.addNote(track, channel, pitch, time, duration, volume)

# Total effect duration: ~1.5 seconds at 180 BPM
effect_duration = 4.5  # beats

# Track 0: Main shield power down sequence
# Descending chromatic pattern with decreasing intervals to represent energy drain
time = 0

# Start with high energy pitch (matching the sci-fi theme from gameplay)
start_pitch = 79  # G5 - high tension note from the gameplay track

# Phase 1: Rapid energy drain (stuttering descent)
for i in range(6):
    pitch = start_pitch - (i * 2)  # Descending by whole tones
    # Stuttering effect - quick on/off pattern
    add(0, 0, pitch, time, 0.08, 90 - (i * 5))  # Decreasing volume
    time += 0.1
    add(0, 0, pitch - 1, time, 0.08, 85 - (i * 5))  # Semitone below for dissonance
    time += 0.1

# Phase 2: System struggling (irregular pulses)
struggling_notes = [
    (67, 0.15, 70),  # G4
    (64, 0.1, 65),   # E4
    (67, 0.1, 60),   # G4 again (trying to recover)
    (62, 0.15, 55),  # D4
    (60, 0.2, 50),   # C4
    (57, 0.25, 45),  # A3
]

for pitch, dur, vol in struggling_notes:
    add(0, 0, pitch, time, dur * 0.8, vol)
    time += dur

# Phase 3: Final collapse (low rumble and cutoff)
final_collapse = [
    (52, 0.3, 40),   # E3
    (48, 0.35, 35),  # C3
    (45, 0.4, 30),   # A2 (matching bass from gameplay)
    (40, 0.5, 25),   # E2 (final low thud)
]

for pitch, dur, vol in final_collapse:
    add(0, 0, pitch, time, dur, vol)
    time += dur * 0.7  # Overlap slightly for rumbling effect

# Track 1: Harmonic layer for texture and "electronic failure" feel
time = 0

# High frequency "warning" beeps that fade
warning_beeps = [
    (84, 0.05, 80),  # C6
    (84, 0.05, 75),
    (84, 0.05, 70),
    (0, 0.15, 0),    # Rest
    (82, 0.05, 65),  # Bb5
    (82, 0.05, 60),
    (0, 0.2, 0),     # Rest
    (79, 0.05, 55),  # G5
    (0, 0.3, 0),     # Longer rest
]

for pitch, dur, vol in warning_beeps:
    if pitch > 0:
        add(1, 0, pitch, time, dur, vol)
    time += dur

# Add some noise-like rapid notes to simulate electronic interference
interference_time = 1.5
for i in range(12):
    # Random-feeling pattern but deterministic
    pitches = [72, 71, 73, 70, 74, 69, 75, 68, 76, 67, 77, 66]
    pitch = pitches[i]
    add(1, 0, pitch, interference_time, 0.03, 30 - i * 2)
    interference_time += 0.08

# Final "system offline" tone - a hollow fifth
add(1, 0, 45, 3.5, 1.0, 20)  # A2
add(1, 0, 52, 3.5, 1.0, 15)  # E3 (perfect fifth above)

# Write the MIDI file
with open("pico8_shield_down_sfx.mid", "wb") as f:
    midi.writeFile(f)

print("Generated pico8_shield_down_sfx.mid - Shield power down sound effect")
print("Track 0: Main power down sequence (descending energy drain)")
print("Track 1: Warning beeps and electronic interference")
print(f"Duration: ~1.5 seconds at {tempo} BPM")
print("\nSound design:")
print("- Phase 1: Rapid stuttering descent (energy draining)")
print("- Phase 2: Irregular pulses (system struggling)")
print("- Phase 3: Low rumble and collapse (total failure)")
print("- Matches A minor tonality of gameplay music")
