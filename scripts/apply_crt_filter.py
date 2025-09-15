"""apply_crt_filter.py

Apply a lightweight retro CRT effect to an (animated) GIF.

Features (configurable):
  * Scanlines (darken every other row)
  * Phosphor / aperture-grille mask (RGB stripe brightness modulation)
  * Sub‑pixel RGB channel horizontal shift
  * Radial vignette (simulates screen curvature & edge darkening)
  * Bloom (blur + screen blend of bright areas)

The goal is to stay dependency‑light: only Pillow is required.

Usage:
  python scripts/apply_crt_filter.py input.gif output.gif \
      --scanline-strength 0.4 --mask-strength 0.25 --rgb-shift 1 \
      --bloom 0.6 --vignette 0.35

All arguments are optional; defaults are subtle.
"""

from __future__ import annotations

import argparse
import math
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import List, Tuple

try:
    from PIL import Image, ImageFilter, ImageChops, ImageEnhance
except ImportError as e:  # pragma: no cover - user environment issue
    print("[ERROR] Pillow is not installed. Install with: pip install Pillow", file=sys.stderr)
    raise


@dataclass
class CrtParams:
    scanline_strength: float = 0.35  # 0..1 (portion of brightness removed on dark rows)
    mask_strength: float = 0.18      # 0..1 (how strong the RGB stripe modulation is)
    rgb_shift: int = 1               # horizontal pixel shift magnitude of color channels
    bloom_strength: float = 0.4      # 0..1 (blend amount)
    bloom_radius: float = 1.2        # gaussian blur radius for bloom
    vignette_strength: float = 0.25  # 0..1 multiplier for edge darkening
    preserve_duration: bool = True


def clamp01(v: float) -> float:
    return 0.0 if v < 0 else 1.0 if v > 1 else v


def apply_scanlines(im: Image.Image, strength: float) -> Image.Image:
    if strength <= 0:  # no-op
        return im
    px = im.load()
    w, h = im.size
    dark_factor = 1.0 - clamp01(strength)
    for y in range(1, h, 2):  # every other row
        for x in range(w):
            r, g, b, a = px[x, y]
            px[x, y] = (int(r * dark_factor), int(g * dark_factor), int(b * dark_factor), a)
    return im


def apply_phosphor_mask(im: Image.Image, strength: float) -> Image.Image:
    if strength <= 0:
        return im
    px = im.load()
    w, h = im.size
    s = clamp01(strength)
    # Stripe pattern: x % 3
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            m = x % 3
            # Reduce two channels, keep one bright per stripe.
            if m == 0:  # R stripe (dim G,B)
                g = int(g * (1 - s))
                b = int(b * (1 - s))
            elif m == 1:  # G stripe (dim R,B)
                r = int(r * (1 - s))
                b = int(b * (1 - s))
            else:  # B stripe (dim R,G)
                r = int(r * (1 - s))
                g = int(g * (1 - s))
            px[x, y] = (r, g, b, a)
    return im


def apply_rgb_shift(im: Image.Image, shift: int) -> Image.Image:
    if shift <= 0:
        return im
    r, g, b, a = im.split()
    # Use ImageChops.offset for simple channel displacements
    r = ImageChops.offset(r, -shift, 0)
    b = ImageChops.offset(b, shift, 0)
    # G stays centered
    return Image.merge("RGBA", (r, g, b, a))


def apply_vignette(im: Image.Image, strength: float) -> Image.Image:
    if strength <= 0:
        return im
    w, h = im.size
    cx, cy = w / 2.0, h / 2.0
    max_r = math.sqrt(cx * cx + cy * cy)
    s = clamp01(strength)
    px = im.load()
    for y in range(h):
        dy = y - cy
        for x in range(w):
            dx = x - cx
            d = math.sqrt(dx * dx + dy * dy) / max_r
            # quadratic falloff
            f = 1 - s * (d * d)
            r, g, b, a = px[x, y]
            px[x, y] = (int(r * f), int(g * f), int(b * f), a)
    return im


def apply_bloom(im: Image.Image, strength: float, radius: float) -> Image.Image:
    if strength <= 0:
        return im
    s = clamp01(strength)
    # Extract bright pass (simple luminance threshold)
    bright = im.copy()
    px = bright.load()
    w, h = bright.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            lum = (0.2126 * r + 0.7152 * g + 0.0722 * b)
            if lum < 160:  # threshold; heuristic
                px[x, y] = (0, 0, 0, 0)
    blurred = bright.filter(ImageFilter.GaussianBlur(radius=radius))
    # Screen blend: result = 1 - (1-A)*(1-B)
    base = im.convert("RGBA")
    bp = blurred.load()
    bpw, bph = blurred.size
    bpx = base.load()
    for y in range(bph):
        for x in range(bpw):
            br, bg, bb, ba = bp[x, y]
            if ba == 0:
                continue
            r, g, b, a = bpx[x, y]
            r = int((1 - (1 - r / 255.0) * (1 - s * br / 255.0)) * 255)
            g = int((1 - (1 - g / 255.0) * (1 - s * bg / 255.0)) * 255)
            b = int((1 - (1 - b / 255.0) * (1 - s * bb / 255.0)) * 255)
            bpx[x, y] = (r, g, b, a)
    return base


def process_frame(frame: Image.Image, params: CrtParams) -> Image.Image:
    im = frame.convert("RGBA")
    im = apply_scanlines(im, params.scanline_strength)
    im = apply_phosphor_mask(im, params.mask_strength)
    im = apply_rgb_shift(im, params.rgb_shift)
    im = apply_vignette(im, params.vignette_strength)
    im = apply_bloom(im, params.bloom_strength, params.bloom_radius)
    return im


def iterate_gif_frames(im: Image.Image):
    i = 0
    try:
        while True:
            im.seek(i)
            frame = im.copy()
            duration = im.info.get("duration", 100)
            yield frame, duration
            i += 1
    except EOFError:
        return


def build_arg_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(description="Apply CRT effect to a GIF")
    p.add_argument("input", type=Path, help="Input GIF path")
    p.add_argument("output", type=Path, help="Output GIF path")
    p.add_argument("--scanline-strength", type=float, default=0.35)
    p.add_argument("--mask-strength", type=float, default=0.18)
    p.add_argument("--rgb-shift", type=int, default=1)
    p.add_argument("--bloom", type=float, default=0.4, help="Bloom strength 0..1")
    p.add_argument("--bloom-radius", type=float, default=1.2)
    p.add_argument("--vignette", type=float, default=0.25)
    p.add_argument("--no-preserve-duration", action="store_true", help="Normalize frame durations to first frame")
    p.add_argument("--preview", action="store_true", help="Show first processed frame instead of saving")
    return p


def main(argv: List[str]) -> int:
    args = build_arg_parser().parse_args(argv)
    if not args.input.exists():
        print(f"[ERROR] Input not found: {args.input}", file=sys.stderr)
        return 1
    params = CrtParams(
        scanline_strength=args.scanline_strength,
        mask_strength=args.mask_strength,
        rgb_shift=args.rgb_shift,
        bloom_strength=args.bloom,
        bloom_radius=args.bloom_radius,
        vignette_strength=args.vignette,
        preserve_duration=not args.no_preserve_duration,
    )
    src = Image.open(args.input)
    frames: List[Image.Image] = []
    durations: List[int] = []
    first_duration = None
    for frame, dur in iterate_gif_frames(src):
        if first_duration is None:
            first_duration = dur
        processed = process_frame(frame, params)
        frames.append(processed)
        durations.append(dur)
        if args.preview:
            break
    if args.preview:
        frames[0].show()
        return 0
    if len(frames) == 1:
        frames[0].save(args.output, format="GIF")
        print(f"[OK] Wrote single-frame GIF to {args.output}")
        return 0
    # Quantize each frame to keep palette size manageable, then save
    quantized = [f.quantize(dither=Image.FLOYDSTEINBERG) for f in frames]
    if not params.preserve_duration and first_duration is not None:
        durations = [first_duration] * len(quantized)
    # Pillow expects 'duration' (ms) + loop=0 for infinite
    quantized[0].save(
        args.output,
        save_all=True,
        append_images=quantized[1:],
        loop=0,
        duration=durations,
        optimize=False,
        disposal=2,
    )
    print(
        f"[OK] Wrote {len(quantized)} frames to {args.output} | scanlines={params.scanline_strength} mask={params.mask_strength} rgb_shift={params.rgb_shift} bloom={params.bloom_strength} vignette={params.vignette_strength}"
    )
    return 0


if __name__ == "__main__":  # pragma: no cover
    raise SystemExit(main(sys.argv[1:]))
