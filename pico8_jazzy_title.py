from midiutil import MIDIFile

# Create a MIDI file with 4 tracks
midi = MIDIFile(4)
tempo = 60  # Slower, more contemplative
for i in range(4):
    midi.addTempo(i, 0, tempo)

def add(track, channel, pitch, time, duration, volume=90):
    midi.addNote(track, channel, pitch, time, duration, volume)

# Chord progression (lush extended chords)
# Cmaj9 - Am11 - Fmaj7#11 - Em7 - Dm9 - G13sus - Cmaj7 - Bbmaj7#11
bass_roots = [
    (48, 4),   # C
    (45, 4),   # A
    (41, 4),   # F
    (40, 4),   # E
    (38, 4),   # D
    (43, 4),   # G
    (48, 2),   # C
    (46, 2),   # Bb
]

# Walking bass with occasional leaps
time = 0
for root, dur in bass_roots:
    # Root
    add(1, 0, root, time, dur * 0.75, 70)
    # Occasional fifth or octave
    if dur == 4:
        add(1, 0, root + 7, time + dur * 0.75, dur * 0.25, 60)
    time += dur

# Floating melody (sparse, contemplative)
melody_notes = [
    # Opening phrase - long, sustained notes
    (72, 3), (0, 1),  # C (rest)
    (74, 2), (76, 2),  # D, E
    (77, 6), (0, 2),   # F (long), rest
    
    # Development
    (79, 1.5), (77, 0.5), (76, 2),  # G, F, E
    (74, 3), (0, 1),  # D, rest
    
    # Resolution phrase
    (72, 2), (71, 2),  # C, B
    (69, 4),  # A (sustained)
    (67, 2), (72, 6),  # G, C (final)
]

time = 0
for pitch, dur in melody_notes:
    if pitch > 0:  # 0 means rest
        add(0, 0, pitch, time, dur * 0.9, 85)
    time += dur

# Lush chord voicings (comping)
chord_voicings = [
    # Cmaj9
    [(60, 64, 67, 71, 74), 4],
    # Am11
    [(57, 60, 64, 67, 71), 4],
    # Fmaj7#11
    [(53, 57, 60, 64, 66), 4],
    # Em7
    [(52, 55, 59, 62, 64), 4],
    # Dm9
    [(50, 53, 57, 60, 64), 4],
    # G13sus
    [(55, 60, 62, 65, 69), 4],
    # Cmaj7
    [(60, 64, 67, 71), 2],
    # Bbmaj7#11
    [(58, 62, 65, 69, 72), 2],
]

time = 0
for chord, dur in chord_voicings:
    # Play chord notes slightly staggered for jazz feel
    offset = 0
    for note in chord:
        add(2, 0, note, time + offset, dur - 0.1, 65)
        offset += 0.05  # Slight roll
    time += dur

# Subtle brushes-style drums
time = 0
for bar in range(8):
    for beat in range(4):
        # Soft hi-hat on all beats
        add(3, 9, 42, time, 0.1, 40)
        
        # Kick on 1 and 3, very soft
        if beat == 0 or beat == 2:
            add(3, 9, 36, time, 0.2, 50)
        
        # Brush snare on 2 and 4
        if beat == 1 or beat == 3:
            add(3, 9, 38, time, 0.15, 45)
            # Ghost note after
            add(3, 9, 38, time + 0.5, 0.1, 30)
        
        # Occasional ride cymbal
        if (bar % 2 == 0) and beat == 0:
            add(3, 9, 51, time, 2, 55)
        
        time += 1

# Add some texture with a second melody line (saxophone-like counter melody)
counter_melody = [
    (0, 8),  # Rest for first 8 beats
    (65, 3), (0, 1),  # F
    (67, 2), (69, 2),  # G, A
    (64, 4),  # E (sustained)
    (62, 2), (60, 2),  # D, C
    (0, 4),  # Rest
    (67, 8),  # G (long sustain to end)
]

time = 0
for pitch, dur in counter_melody:
    if pitch > 0:
        add(0, 1, pitch, time, dur * 0.9, 70)  # Softer than main melody
    time += dur

with open("pico8_jazzy_title.mid", "wb") as f:
    midi.writeFile(f)

print("Generated pico8_jazzy_title.mid - A contemplative jazz piece inspired by Space Lion")
