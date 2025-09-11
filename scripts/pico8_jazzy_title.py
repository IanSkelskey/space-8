from midiutil import MIDIFile

# Create a MIDI file with 4 tracks (monophonic for PICO-8)
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

# Track 0: Combined melody line (main melody + counter melody in gaps)
# Using main melody and filling gaps with counter melody
combined_melody = [
    # Opening phrase - main melody
    (72, 3), (0, 1),  # C (rest)
    (74, 2), (76, 2),  # D, E
    (77, 6), (0, 2),   # F (long), rest
    
    # Counter melody enters during rest
    (65, 3), (0, 1),  # F from counter
    
    # Back to main melody development
    (79, 1.5), (77, 0.5), (76, 2),  # G, F, E
    (67, 2), (69, 2),  # G, A from counter
    (74, 3), (0, 1),  # D, rest
    
    # Counter melody continues
    (64, 4),  # E (sustained)
    
    # Resolution phrase - main melody
    (72, 2), (71, 2),  # C, B
    (62, 2), (60, 2),  # D, C from counter
    (69, 4),  # A (sustained)
    (67, 2), (72, 6),  # G, C (final with G sustain underneath implied)
]

time = 0
for pitch, dur in combined_melody:
    if pitch > 0:  # 0 means rest
        add(0, 0, pitch, time, dur * 0.9, 85)
    time += dur

# Track 2: Arpeggiated chords (monophonic, using smart voice leading)
# Convert lush chord voicings to rolling arpeggios
chord_arpeggios = [
    # Cmaj9 - roll through: C-E-G-B-D
    [(60, 0.5), (64, 0.5), (67, 0.5), (71, 0.5), (74, 0.5), (71, 0.5), (67, 0.5), (64, 0.5)],
    # Am11 - roll through: A-C-E-G-B
    [(57, 0.5), (60, 0.5), (64, 0.5), (67, 0.5), (71, 0.5), (67, 0.5), (64, 0.5), (60, 0.5)],
    # Fmaj7#11 - roll through: F-A-C-E-B
    [(53, 0.5), (57, 0.5), (60, 0.5), (64, 0.5), (66, 0.5), (64, 0.5), (60, 0.5), (57, 0.5)],
    # Em7 - roll through: E-G-B-D
    [(52, 0.5), (55, 0.5), (59, 0.5), (62, 0.5), (64, 0.5), (62, 0.5), (59, 0.5), (55, 0.5)],
    # Dm9 - roll through: D-F-A-C-E
    [(50, 0.5), (53, 0.5), (57, 0.5), (60, 0.5), (64, 0.5), (60, 0.5), (57, 0.5), (53, 0.5)],
    # G13sus - roll through: G-C-D-F-A
    [(55, 0.5), (60, 0.5), (62, 0.5), (65, 0.5), (69, 0.5), (65, 0.5), (62, 0.5), (60, 0.5)],
    # Cmaj7 - shorter pattern
    [(60, 0.5), (64, 0.5), (67, 0.5), (71, 0.5)],
    # Bbmaj7#11 - shorter pattern
    [(58, 0.5), (62, 0.5), (65, 0.5), (69, 0.5)],
]

time = 0
for arpeggio in chord_arpeggios:
    for note, dur in arpeggio:
        add(2, 0, note, time, dur * 0.9, 65)
        time += dur

# Track 3: Simplified drums (monophonic - one hit at a time)
# Using jazz brush patterns but one sound at a time
time = 0
for bar in range(8):
    for beat in range(4):
        # Pattern: hat-kick-hat-snare for basic jazz feel
        if beat == 0:
            # Kick on 1
            add(3, 9, 36, time, 0.2, 50)
            # Hi-hat on off-beats
            add(3, 9, 42, time + 0.25, 0.1, 40)
            add(3, 9, 42, time + 0.5, 0.1, 35)
            add(3, 9, 42, time + 0.75, 0.1, 35)
        elif beat == 1:
            # Snare on 2
            add(3, 9, 38, time, 0.15, 45)
            # Ghost note
            add(3, 9, 38, time + 0.5, 0.1, 30)
            # Hi-hats
            add(3, 9, 42, time + 0.75, 0.1, 35)
        elif beat == 2:
            # Kick on 3 (softer)
            add(3, 9, 36, time, 0.2, 40)
            # Hi-hats
            add(3, 9, 42, time + 0.25, 0.1, 35)
            add(3, 9, 42, time + 0.5, 0.1, 35)
            add(3, 9, 42, time + 0.75, 0.1, 35)
        else:  # beat == 3
            # Snare on 4
            add(3, 9, 38, time, 0.15, 45)
            # Fill with hi-hats
            add(3, 9, 42, time + 0.25, 0.1, 40)
            add(3, 9, 42, time + 0.5, 0.1, 35)
            # Occasional ride accent
            if bar % 2 == 1:
                add(3, 9, 51, time + 0.75, 0.25, 55)
            else:
                add(3, 9, 42, time + 0.75, 0.1, 35)
        
        time += 1

with open("pico8_jazzy_title.mid", "wb") as f:
    midi.writeFile(f)

print("Generated pico8_jazzy_title.mid - A contemplative jazz piece adapted for PICO-8's 4 monophonic channels")
print("Track 0: Melody line (combined main and counter melodies)")
print("Track 1: Walking bass")
print("Track 2: Arpeggiated chords (implying harmony)")
print("Track 3: Jazz drums (monophonic pattern)")
