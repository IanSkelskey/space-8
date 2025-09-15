from midiutil import MIDIFile

"""
Generates three short UI sound effect MIDI files for PICO-8 style menus:
 1. pico8_menu_cursor.mid  - subtle upward tick when moving between options
 2. pico8_menu_select.mid  - satisfying confirm arpeggio
 3. pico8_menu_error.mid   - soft descending error / denial tone

Design Cohesion:
- All in A minor (natural) so they feel related to existing music.
- Same tempo & velocity palette; each uses slightly different contour.
- Very short (under ~0.4s at given tempo) to map cleanly to SFX editor import.

You can tweak pitches or durations easily in the data tables below.
"""

TEMPO = 200  # Fast so beat fractions become very short effects
CHANNEL = 0

# Helper to create a single-track (or lightweight multi-track) MIDI

def make_midi(filename, notes, sustain_tail=0.0, track_count=1):
    """Create a MIDI with given (pitch, start, dur, vel) tuples.
    notes: list[(pitch, start_beats, duration_beats, velocity)]
    sustain_tail: extra beats added at end to ensure final note isn't cut off.
    track_count: number of tracks (default 1; we keep all sfx monophonic).
    """
    mf = MIDIFile(track_count)
    for t in range(track_count):
        mf.addTempo(t, 0, TEMPO)
    track = 0
    for pitch, start, dur, vel in notes:
        if pitch is not None:  # None = rest segment
            mf.addNote(track, CHANNEL, pitch, start, dur, vel)
    length = 0
    if notes:
        length = max(start + dur for _, start, dur, _ in notes) + sustain_tail
    with open(filename, 'wb') as f:
        mf.writeFile(f)
    print(f"Wrote {filename} (len ~{length:.2f} beats at tempo {TEMPO})")

# Velocity palette for consistency
VEL_STRONG = 95
VEL_MED = 80
VEL_SOFT = 60

# 1. Cursor move: quick upward two-step with a faint ghost note echo.
# A5 (81) -> C6 (84); tiny echo of C6 one semitone below for texture.
cursor_notes = [
    (81, 0.00, 0.12, VEL_MED),   # A5
    (84, 0.10, 0.14, VEL_STRONG),# C6
    (83, 0.18, 0.10, VEL_SOFT),  # B5 (ghost / soft release)
]
make_midi("pico8_menu_cursor.mid", cursor_notes, sustain_tail=0.05)

# 2. Select / Confirm: root -> fifth -> octave arpeggio (A4 -> E5 -> A5)
# Slight crescendo; final octave holds a hair longer.
select_notes = [
    (69, 0.00, 0.10, VEL_MED),   # A4
    (76, 0.08, 0.11, VEL_MED+5), # E5
    (81, 0.16, 0.20, VEL_STRONG) # A5 sustain
]
make_midi("pico8_menu_select.mid", select_notes, sustain_tail=0.08)

# 3. Error: descending minor 2nd cluster then a resolving (but soft) third.
# C5 (72) -> B4 (71) -> A4 (69) quick, then low E4 (64) very soft = denial.
error_notes = [
    (72, 0.00, 0.09, VEL_STRONG),  # C5
    (71, 0.07, 0.09, VEL_MED),     # B4
    (69, 0.14, 0.12, VEL_MED),     # A4
    (64, 0.24, 0.18, VEL_SOFT),    # E4 (dull tail)
]
make_midi("pico8_menu_error.mid", error_notes, sustain_tail=0.05)

print("Generated UI SFX MIDIs:")
print(" - pico8_menu_cursor.mid")
print(" - pico8_menu_select.mid")
print(" - pico8_menu_error.mid")
print("Import into PICO-8 SFX slots and tailor instrument/noise as needed.")
