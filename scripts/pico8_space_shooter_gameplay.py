from midiutil import MIDIFile

# Create a MIDI file with 4 tracks (monophonic for PICO-8)
midi = MIDIFile(4)
tempo = 120  # Faster tempo for action gameplay
for i in range(4):
    midi.addTempo(i, 0, tempo)

def add(track, channel, pitch, time, duration, volume=90):
    midi.addNote(track, channel, pitch, time, duration, volume)

# Define loop length (in beats)
loop_length = 32

# Track 0: Lead synth melody (sci-fi theme in minor)
lead_melody = [
    # First phrase - establishing theme
    (72, 0.5), (76, 0.5), (79, 1), (76, 0.5), (72, 0.5), (76, 1),  # A minor arpeggio with extensions
    (74, 0.5), (77, 0.5), (81, 1), (77, 0.5), (74, 0.5), (77, 1),  # B diminished feel
    
    # Second phrase - response
    (71, 0.5), (74, 0.5), (79, 1), (74, 0.5), (71, 0.5), (67, 1),  # G minor to D
    (69, 0.5), (72, 0.5), (76, 1), (72, 1), (69, 1), (0, 0.5),     # E diminished with rest
    
    # Repeat with variation
    (72, 0.5), (76, 0.5), (79, 0.5), (76, 0.5), (72, 0.5), (76, 0.5), (79, 1),
    (74, 0.5), (77, 0.5), (81, 0.5), (77, 0.5), (74, 0.5), (77, 0.5), (81, 1),
    
    # Final phrase with more tension
    (71, 0.5), (74, 0.5), (76, 0.5), (74, 0.5), (71, 0.5), (74, 0.5), (76, 1),
    (72, 0.5), (76, 0.5), (79, 1), (76, 1), (72, 0.5), (0, 0.5),  # Return to A minor
]

time = 0
for pitch, dur in lead_melody:
    if pitch > 0:  # 0 means rest
        add(0, 0, pitch, time, dur * 0.9, 85)
    time += dur

# Track 1: Bass line (driving, rhythmic pattern)
bass_pattern = [
    # A minor
    (45, 0.5), (45, 0.5), (45, 0.5), (45, 0.5), 
    (45, 0.5), (45, 0.5), (45, 0.5), (45, 0.5),
    # G minor
    (43, 0.5), (43, 0.5), (43, 0.5), (43, 0.5),
    (43, 0.5), (43, 0.5), (43, 0.5), (43, 0.5),
    # F
    (41, 0.5), (41, 0.5), (41, 0.5), (41, 0.5),
    (41, 0.5), (41, 0.5), (41, 0.5), (41, 0.5),
    # E
    (40, 0.5), (40, 0.5), (40, 0.5), (40, 0.5),
    (40, 0.5), (40, 0.5), (43, 0.5), (44, 0.5),  # Rising back to A
]

# Repeat the pattern to fill the loop
time = 0
for _ in range(2):
    for pitch, dur in bass_pattern:
        add(1, 0, pitch, time, dur * 0.8, 75)  # Slightly shorter notes for a tighter feel
        time += dur

# Track 2: Arpeggiated tension builder
arp_patterns = [
    # A minor arpeggios (higher register)
    [(57, 0.25), (60, 0.25), (64, 0.25), (69, 0.25)] * 4,
    # G minor arpeggios
    [(55, 0.25), (58, 0.25), (62, 0.25), (67, 0.25)] * 4,
    # F arpeggios
    [(53, 0.25), (57, 0.25), (60, 0.25), (65, 0.25)] * 4,
    # E diminished/E minor with rising tension
    [(52, 0.25), (55, 0.25), (59, 0.25), (64, 0.25)] * 3 + 
    [(52, 0.25), (56, 0.25), (59, 0.25), (64, 0.25)]
]

time = 0
for pattern in arp_patterns:
    for note, dur in pattern:
        add(2, 0, note, time, dur * 0.7, 60)  # Staccato for rhythmic tension
        time += dur

# Repeat with variations in volume for tension
for pattern in arp_patterns:
    for i, (note, dur) in enumerate(pattern):
        # Gradually increase volume for building tension
        intensity = 60 + min(30, i // 2)
        add(2, 0, note, time, dur * 0.7, intensity)
        time += dur

# Track 3: Electronic drum pattern
time = 0
for bar in range(8):  # 8 bars to fill our loop
    for beat in range(4):  # 4 beats per bar
        # Kick drum on beats 1 and 3
        if beat == 0 or beat == 2:
            add(3, 9, 36, time, 0.2, 100)
        
        # Snare/noise hit on beats 2 and 4
        if beat == 1 or beat == 3:
            add(3, 9, 38, time, 0.2, 90)
        
        # Hi-hats on eighth notes
        add(3, 9, 42, time, 0.1, 70)
        add(3, 9, 42, time + 0.5, 0.1, 60)
        
        # Add some variation with occasional electronic sounds
        if bar % 2 == 1 and beat == 3:
            # Glitch sound (high pitched percussive noise)
            add(3, 9, 50, time + 0.75, 0.1, 75)
        
        # Extra percussion for tension build-up in second half
        if bar >= 4 and (beat == 1 or beat == 3):
            add(3, 9, 46, time + 0.25, 0.1, 65)
        
        time += 1

with open("pico8_space_shooter_gameplay.mid", "wb") as f:
    midi.writeFile(f)

print("Generated pico8_space_shooter_gameplay.mid - An energetic looping track for space shooter gameplay")
print("Track 0: Lead sci-fi melody")
print("Track 1: Driving bass pattern")
print("Track 2: Tension-building arpeggios")
print("Track 3: Electronic drums")
print(f"Loop length: {loop_length} beats")
