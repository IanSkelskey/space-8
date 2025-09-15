"""sfx_splitter.py

Utility to convert a single-line or loosely formatted PICO-8 [sfx] hex blob
into a valid multi-line [sfx] block where each SFX record is exactly 168
hex characters on its own line. This makes PICO-8 accept multi-SFX pastes
without the dreaded 'INSUFFICIENT SPACE FOR INSTS' error (which often
appears when the structure or count pushes past slot 63).

Usage (basic):
    1. Put your raw blob (with or without [sfx] tags, any whitespace) in a file, e.g. raw_sfx.txt
    2. python sfx_splitter.py raw_sfx.txt out_sfx.txt
    3. Open out_sfx.txt, copy everything, select the FIRST destination SFX slot in PICO-8, paste.

Optional flags:
    --pad     : If there is a partial trailing chunk (<168 chars), pad it with zeros (not usually recommended).
    --keeppartial : Emit the partial chunk (as-is) as an extra line (PICO-8 will reject, for debug only).
    --max N   : Truncate to first N full SFX blocks.

Example:
    python sfx_splitter.py raw_sfx.txt multi.txt --max 15

Notes:
 - Script strips all non-hex characters automatically, so only 0-9 a-f A-F remain.
 - If you accidentally included music pattern data or other text, it will be silently removed.
 - Always verify resulting line count * start_slot + (count-1) <= 63.
"""

from __future__ import annotations
import sys, re, argparse, textwrap

REC_LEN = 168

def load_blob(path: str) -> str:
    data = open(path, 'r', encoding='utf-8').read()
    # Remove tags if present
    data = re.sub(r'\[/?sfx\]', '', data, flags=re.IGNORECASE)
    # Keep only hex digits
    data = re.sub(r'[^0-9a-fA-F]', '', data)
    return data.lower()

def chunk(blob: str):
    for i in range(0, len(blob), REC_LEN):
        yield blob[i:i+REC_LEN]

def main():
    ap = argparse.ArgumentParser(formatter_class=argparse.RawDescriptionHelpFormatter,
        description="Split concatenated PICO-8 SFX hex into 168-char lines.")
    ap.add_argument('infile')
    ap.add_argument('outfile')
    ap.add_argument('--pad', action='store_true', help='Pad final partial record with zeros to 168.')
    ap.add_argument('--keeppartial', action='store_true', help='Emit final partial record (debug).')
    ap.add_argument('--max', type=int, default=None, help='Limit to first N full records.')
    args = ap.parse_args()

    blob = load_blob(args.infile)
    full_records = []
    partial = None
    for i, c in enumerate(chunk(blob)):
        if len(c) == REC_LEN:
            full_records.append(c)
        else:
            partial = c
            break

    if args.max is not None:
        full_records = full_records[:args.max]

    notes = []
    if partial and len(partial) and len(partial) != REC_LEN:
        notes.append(f"Found partial tail of {len(partial)} chars.")
        if args.pad:
            padded = partial + '0' * (REC_LEN - len(partial))
            full_records.append(padded)
            notes.append("Padded partial tail to full record.")
        elif args.keeppartial:
            full_records.append(partial)
            notes.append("Keeping partial record (likely invalid for PICO-8 paste).")

    with open(args.outfile, 'w', encoding='utf-8') as f:
        f.write('[sfx]\n')
        for r in full_records:
            f.write(r + '\n')
        f.write('[/sfx]\n')

    print(f"Input hex chars: {len(blob)}")
    print(f"Full records: {len(full_records)} (168 chars each)")
    if partial and not (args.pad or args.keeppartial):
        print(f"Partial (discarded) tail chars: {len(partial)}")
    if args.max:
        print(f"Truncated to --max {args.max}")
    if notes:
        print('\n'.join(notes))
    print("Done ->", args.outfile)

if __name__ == '__main__':
    main()
