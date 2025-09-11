#!/usr/bin/env python3
"""
Generate an animated GIF of the starfield that tiles seamlessly in space and matches the in-game look.

What this reproduces from src/starfield.lua:
- 3 parallax layers with speeds: far=0.25, mid=0.50, near=1.00
- Star counts per layer: far=40, mid=25, near=12
- Colors per layer: far=1, mid=5, near=13 (with twinkle shifts)
- Twinkle on far/mid with 15% chance each; brightness oscillates using sin()

Loop-safe tweaks (to ensure a time loop when desired):
- We run with a step scale ssc=2 and 256 frames by default. With a 128px-tall canvas, layer
    displacements per full animation become 128, 256, 512 px for far/mid/near which align nicely.
- Stars do NOT randomize x on vertical wrap (we use modulo height only). This differs slightly from
    the game (which randomizes x on wrap) but guarantees a stable, loopable sequence.
- Twinkle speeds are quantized so each star's twinkle completes an integer number of cycles over
    the loop (k/frames with k in {3,4,5}).
- Distant planets are OFF by default. You can enable loop-friendly planets with --planets; they use
    modulo wrapping instead of respawn and discrete speeds.

New in this version for non-square heights:
- --auto-ssc computes a speed scale that guarantees a perfect time loop for ANY height/frames by
  solving spd_min * ssc * frames = 1 * height (with spd_min = 0.25). This removes the old
  restriction that height should divide 128 for a perfect loop.

Notes for non-square output:
- Width and height can be set independently with --width and --height. The previous --size option
    still works and sets both dimensions equally.
- For an exact time loop at arbitrary heights, use --auto-ssc. It selects ssc so that all layers
    return to their starting y on the last frame, regardless of height.

Usage (PowerShell):
    python .\gen_starfield_gif.py --out build\\starfield.gif --frames 256 --fps 15
    # non-square example
    python .\gen_starfield_gif.py --out build\\starfield_256x144.gif --width 256 --height 144 --auto-ssc
  
Optional flags:
    --size 128            Square output (sets both width and height). Default 128.
    --width               Output width (overrides --size for width if provided).
    --height              Output height (overrides --size for height if provided).
    --frames 256          Number of frames (default 256 for a smooth cycle with ssc=2).
    --fps 15              Target playback rate (affects GIF frame duration).
    --seed 42             Seed for reproducible randomness.
    --planets             Include distant planets in a loop-friendly way.
    --no-dither           Disable GIF dithering (defaults to enabled for better gradients).
    --bg 0                Background PICO-8 color index (default 0 = black).
    --auto-ssc            Auto-compute speed scale so the animation time-loops perfectly for any height.

Output is an animated GIF that tiles in space and is designed to loop well in time.
"""
from __future__ import annotations

import argparse
import math
import random
from dataclasses import dataclass
from typing import List

from PIL import Image, ImageDraw

# PICO-8 16-color palette (index -> RGB)
PICO8_PALETTE = [
    (0x00, 0x00, 0x00),  # 0 black
    (0x1D, 0x2B, 0x53),  # 1 dark-blue
    (0x7E, 0x25, 0x53),  # 2 dark-purple
    (0x00, 0x87, 0x51),  # 3 dark-green
    (0xAB, 0x52, 0x36),  # 4 brown
    (0x5F, 0x57, 0x4F),  # 5 dark-gray
    (0xC2, 0xC3, 0xC7),  # 6 light-gray
    (0xFF, 0xF1, 0xE8),  # 7 white-ish
    (0xFF, 0x00, 0x4D),  # 8 red
    (0xFF, 0xA3, 0x00),  # 9 orange
    (0xFF, 0xEC, 0x27),  # 10 yellow
    (0x00, 0xE4, 0x36),  # 11 green
    (0x29, 0xAD, 0xFF),  # 12 blue
    (0x83, 0x76, 0x9C),  # 13 indigo
    (0xFF, 0x77, 0xA8),  # 14 pink
    (0xFF, 0xCC, 0xAA),  # 15 peach
]


@dataclass
class Star:
    x: int
    y: float
    y0: float
    spd: float
    col_index: int  # base color index (1, 5, 13)
    layer: int      # 1=far, 2=mid, 3=near
    tw: float | None = None
    twspd_k: int | None = None  # integer cycles per full animation


@dataclass
class Planet:
    x: float
    y: float
    y0: float
    r: int
    spd: float
    has_ring: bool
    ring_angle: float


def build_palette_image(bg_index: int = 0) -> Image.Image:
    """Create a paletted image with the PICO-8 palette for consistent quantization."""
    pal_img = Image.new("P", (1, 1))
    palette = []
    for r, g, b in PICO8_PALETTE:
        palette.extend([r, g, b])
    # PIL requires exactly 768 entries (256 * 3)
    palette += [0, 0, 0] * (256 - len(PICO8_PALETTE))
    pal_img.putpalette(palette)
    pal_img.info["transparency"] = None
    pal_img.info["background"] = bg_index
    return pal_img


def pico8_sin(turns: float) -> float:
    """PICO-8 sin uses 1.0 as a full cycle; emulate via Python's sin(2πx)."""
    return math.sin(2 * math.pi * turns)


def init_stars(seed: int | None, width: int, height: int) -> List[Star]:
    if seed is not None:
        random.seed(seed)
    stars: List[Star] = []
    layers = [
        {"n": 40, "spd": 0.25, "col": 1, "li": 1},  # far
        {"n": 25, "spd": 0.50, "col": 5, "li": 2},  # mid
        {"n": 12, "spd": 1.00, "col": 13, "li": 3}, # near
    ]
    for l in layers:
        for _ in range(l["n"]):
            x = int(math.floor(random.random() * width))
            y = random.random() * height
            s = Star(x=x, y=y, y0=y, spd=l["spd"], col_index=l["col"], layer=l["li"], tw=None, twspd_k=None)
            # 15% twinkle chance for far/mid only
            if l["li"] <= 2 and random.random() < 0.15:
                k = random.choice([3, 4, 5])  # integer cycles over the full animation
                s.tw = random.random()  # initial phase in turns
                s.twspd_k = k
            stars.append(s)
    return stars


def init_planets_loop_friendly(seed: int | None, width: int, height: int) -> List[Planet]:
    if seed is not None:
        random.seed(seed + 1000)
    planets: List[Planet] = []
    n = 3 + int(math.floor(random.random() * 3))
    for _ in range(n):
        size_roll = random.random()
        if size_roll < 0.5:
            r = 1
        elif size_roll < 0.8:
            r = 2
        else:
            r = 3
        # keep some horizontal margin when width allows
        usable_w = max(1, width - 20)
        x = (10 if width >= 20 else 0) + random.random() * usable_w
        y = random.random() * height
        # Discrete speeds chosen to close loop at frames=256, ssc=2:
        # Need spd*ssc*frames to be a multiple of canvas height for a perfect time loop.
        # With defaults, spd in {0.25, 0.5} often produces good results for heights that divide 128/256.
        spd = random.choice([0.25, 0.5])
        has_ring = (r == 3) and (random.random() < 0.5)
        ring_angle = random.random()
        planets.append(Planet(x=x, y=y, y0=y, r=r, spd=spd, has_ring=has_ring, ring_angle=ring_angle))
    return planets


def update_stars(stars: List[Star], height: int, ssc: float, frame_idx: int, frames: int) -> None:
    """Update star positions and twinkle.

    Uses a non-accumulating position update (based on initial y0) to avoid floating-point drift, so
    exact time loops are preserved when spd*ssc*frames is a multiple of height.
    """
    for s in stars:
        # Non-accumulating update ensures y exactly returns to start when configured for a perfect loop.
        s.y = (s.y0 + s.spd * ssc * frame_idx) % height
        if s.tw is not None and s.twspd_k is not None:
            s.tw = (s.tw + (s.twspd_k / frames)) % 1.0


def update_planets(planets: List[Planet], height: int, ssc: float, frame_idx: int) -> None:
    for p in planets:
        p.y = (p.y0 + p.spd * ssc * frame_idx) % height


def _bbox_intersects_frame(bbox: tuple[int, int, int, int], width: int, height: int) -> bool:
    l, t, r, b = bbox
    return (r >= 0) and (l < width) and (b >= 0) and (t < height)


def draw_frame(width: int, height: int, stars: List[Star], planets: List[Planet], bg_index: int, pal_img: Image.Image) -> Image.Image:
    # Start with paletted image using PICO-8 palette
    img = Image.new("P", (width, height))
    img.putpalette(pal_img.getpalette())
    draw = ImageDraw.Draw(img)

    # Fill background
    draw.rectangle((0, 0, width, height), fill=bg_index)

    # Draw planets first (back), with toroidal wrapping to tile seamlessly in space
    for p in planets:
        cx0 = int(round(p.x))
        cy0 = int(round(p.y))
        color_idx = 1  # subtle dark planet body
        r = p.r
        for ox in (-width, 0, width):
            for oy in (-height, 0, height):
                cx = cx0 + ox
                cy = cy0 + oy
                bbox = (cx - r, cy - r, cx + r, cy + r)
                if _bbox_intersects_frame(bbox, width, height):
                    draw.ellipse(bbox, fill=color_idx)
                    if p.has_ring:
                        ring_color = 6
                        rx = r + 2
                        ry = r
                        rbbox = (cx - rx, cy - ry, cx + rx, cy + ry)
                        if _bbox_intersects_frame(rbbox, width, height):
                            draw.ellipse(rbbox, outline=ring_color)

    # Draw stars
    for s in stars:
        col = s.col_index
        if s.tw is not None:
            b = pico8_sin(s.tw)
            if b > 0.5:
                col = 6  # bright twinkle
            elif b < -0.3:
                col = 1  # dim twinkle
        x = s.x
        y = int(math.floor(s.y))
        if 0 <= x < width and 0 <= y < height:
            img.putpixel((x, y), col)

    return img


def parse_args() -> argparse.Namespace:
    ap = argparse.ArgumentParser(description="Generate a looped, tileable starfield GIF matching src/starfield.lua.")
    ap.add_argument("--out", default="build/starfield.gif", help="Output GIF path (default: build/starfield.gif)")
    ap.add_argument("--size", type=int, default=128, help="Square size (sets both width and height). Default: 128")
    ap.add_argument("--width", type=int, default=None, help="Output width in pixels (overrides --size for width)")
    ap.add_argument("--height", type=int, default=None, help="Output height in pixels (overrides --size for height)")
    ap.add_argument("--frames", type=int, default=256, help="Number of frames (default: 256 for seamless loop)")
    ap.add_argument("--fps", type=int, default=15, help="Frames per second for playback (default: 15; matches in-game speed with ssc=2)")
    ap.add_argument("--ssc", type=float, default=2.0, help="Speed scale per frame (default: 2.0; choose with frames to close the loop)")
    ap.add_argument("--auto-ssc", action="store_true", help="Auto-compute speed scale for a perfect time loop for the given height and frames")
    ap.add_argument("--seed", type=int, default=42, help="RNG seed for reproducibility (default: 42)")
    ap.add_argument("--planets", action="store_true", help="Include loop-friendly distant planets (optional)")
    ap.add_argument("--no-dither", action="store_true", help="Disable GIF dithering (enabled by default)")
    ap.add_argument("--bg", type=int, default=0, help="Background PICO-8 color index (default: 0 black)")
    return ap.parse_args()


def main() -> None:
    args = parse_args()

    # Resolve dimensions with backward compatibility for --size
    width = int(args.width) if args.width is not None else int(args.size)
    height = int(args.height) if args.height is not None else int(args.size)
    frames = args.frames
    fps = args.fps
    seed = args.seed
    dither = not args.no_dither
    bg_index = args.bg

    # Initialize entities (independent of ssc)
    stars = init_stars(seed, width, height)
    planets: List[Planet] = init_planets_loop_friendly(seed, width, height) if args.planets else []

    # Loop design: by default ssc=2 so the layer speeds align in 256 frames for height=128.
    # For arbitrary heights, --auto-ssc solves spd_min * ssc * frames = 1 * height so everything closes.
    if args.auto_ssc:
        min_spd = min(s.spd for s in stars) if stars else 0.25
        # Avoid divide-by-zero if frames is zero (shouldn't happen due to arg type), fall back to 2.0
        ssc = (height / max(1, frames)) / max(1e-9, min_spd)
    else:
        ssc = float(args.ssc)

    pal_img = build_palette_image(bg_index)

    # Simulate and render frames
    images: List[Image.Image] = []
    for f in range(frames):
        # Update positions
        update_stars(stars, height, ssc=ssc, frame_idx=f, frames=frames)
        if planets:
            update_planets(planets, height, ssc=ssc, frame_idx=f)

        # Draw frame
        img = draw_frame(width, height, stars, planets, bg_index, pal_img)
        images.append(img)

    # Save animated GIF
    duration_ms = int(1000 / max(1, fps))
    save_kwargs = dict(save_all=True, append_images=images[1:], loop=0, duration=duration_ms, optimize=False)
    if not dither:
        # Ensure no additional dithering; convert explicitly if desired
        for i, im in enumerate(images):
            images[i] = im.convert("P", dither=Image.NONE, palette=Image.ADAPTIVE, colors=16)
    images[0].save(args.out, **save_kwargs)
    suffix = " [auto-ssc]" if args.auto_ssc else ""
    print(f"Wrote {args.out} ({frames} frames @ {fps} fps, size {width}x{height}, ssc={ssc:.6g}){suffix}")


if __name__ == "__main__":
    main()
