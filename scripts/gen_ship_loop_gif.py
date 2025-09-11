#!/usr/bin/env python3
"""
Generate a looping GIF of the ship flying left and right with exhaust particles on a transparent background.

Path specification:
- Starts at horizontal center, flies all the way to the left bound, then all the way to the right bound,
  then returns to center, drains particles, and loops.

Visuals:
- Uses the provided sprites:
  assets/sprites/ship.png (straight)
  assets/sprites/ship-tilt.png (leaning)
- Tilting mirrors when moving right (like the game). Straight sprite is not flipped.
- Exhaust particles approximate the game's behavior in src/entities/ship.lua.

Looping:
- Final frame returns to center with zero velocity and no particles so that the first frame matches exactly.

Usage (PowerShell):
    python .\scripts\gen_ship_loop_gif.py --out build\\ship_anim.gif --width 128 --height 128 --fps 15

Optional flags:
    --out                Output GIF path (default: build/ship_anim.gif)
    --width              Canvas width (default: 128)
    --height             Canvas height (default: 128)
    --fps                Frames per second (default: 15)
    --frames             Fixed total frame count; if omitted, the script auto-computes the sequence length.
    --seed               RNG seed (default: 42)
    --no-dither          Disable GIF dithering (defaults to enabled)
    --ship               Path to ship straight sprite PNG (default: assets/sprites/ship.png)
    --tilt               Path to ship tilt sprite PNG (default: assets/sprites/ship-tilt.png)
    --margin             Horizontal margin from edges in pixels (default: 0)
    --drain-frames       Particle drain frames at the end (default: 18)

Notes:
- Coordinates and constants are taken from the game where possible: ship speed 2.0, acc 0.12, FACE_EPS 0.05,
  exhaust parameters from X in ship.lua. Particles are drawn using PICO-8 palette indices 10/9/8 (yellow/orange/red).
- Background index 0 is kept transparent in the output GIF.
"""
from __future__ import annotations

import argparse
import math
import os
import random
from dataclasses import dataclass
from typing import List, Tuple

from PIL import Image, ImageDraw, ImageOps

# PICO-8 16-color palette (index -> RGB)
PICO8_PALETTE = [
    (0x00, 0x00, 0x00),  # 0 black (transparent index in GIF)
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

# Ship constants (mirroring src/entities/ship.lua)
SHIP_SPD = 2.0
SHIP_ACC = 0.12
FACE_EPS = 0.05
SHIP_W = 8
SHIP_H = 8

# Exhaust constants (from X in ship.lua)
X_NL = 2
X_NR = 3
X_BDY = 0.5
X_DYS = 0.9
X_LMIN = 6
X_LR = 10
X_XJ = 1
X_DXJ = 0.6
X_DXR = 0.3
X_DYR = 0.4

# Particle colors (PICO-8 indices)
COL_Y = 10  # yellow
COL_O = 9   # orange
COL_R = 8   # red

# Bounds like game
OFF_MIN, OFF_MAX = -4, 132

@dataclass
class Particle:
    x: float
    y: float
    dx: float
    dy: float
    life: int


def build_palette_image(trans_index: int = 0) -> Image.Image:
    """Create a P-mode image carrying the full 256-color palette with PICO-8 colors.
    Index 0 is reserved for transparency when saving GIFs.
    """
    pal_img = Image.new("P", (16, 16))  # size doesn't matter; using 256 slots
    palette = []
    for r, g, b in PICO8_PALETTE:
        palette.extend([r, g, b])
    # pad to 256 colors
    palette += [0, 0, 0] * (256 - len(PICO8_PALETTE))
    pal_img.putpalette(palette)
    pal_img.info["transparency"] = trans_index
    pal_img.info["background"] = trans_index
    return pal_img


def paste_rgba(base_rgba: Image.Image, sprite_rgba: Image.Image, xy: Tuple[int, int]) -> None:
    """Paste an RGBA sprite onto an RGBA canvas preserving alpha."""
    if sprite_rgba.mode != "RGBA":
        sprite_rgba = sprite_rgba.convert("RGBA")
    base_rgba.paste(sprite_rgba, xy, mask=sprite_rgba.split()[3])


def quantize_to_pico8(frame_rgba: Image.Image, pal: Image.Image, dither: bool) -> Image.Image:
    """Quantize an RGBA frame to the PICO-8 palette and enforce transparent index 0.
    We preserve transparency by forcing fully-transparent pixels to palette index 0 after quantization.
    """
    if frame_rgba.mode != "RGBA":
        frame_rgba = frame_rgba.convert("RGBA")
    # Quantize using the provided palette. Must quantize from RGB or L.
    rgb = frame_rgba.convert("RGB")
    q = rgb.quantize(palette=pal, dither=(Image.FLOYDSTEINBERG if dither else Image.NONE))
    # Force transparent pixels to index 0.
    alpha = frame_rgba.getchannel("A")
    trans_mask = alpha.point(lambda a: 255 if a == 0 else 0)
    q.paste(0, mask=trans_mask)
    return q


def spawn_exhaust(particles: List[Particle], rng: random.Random, ship_x: float, ship_y: float, thrust: float) -> None:
    thrust = max(0.0, min(1.0, thrust))
    if thrust <= 0.0:
        return
    y = ship_y + SHIP_H
    x1 = ship_x + X_NL
    x2 = ship_x + SHIP_W - X_NR
    bdy = X_BDY + X_DYS * thrust
    life = int(X_LMIN + X_LR * thrust)
    if rng.random() < thrust:
        dx = (rng.random() * X_DXJ - X_DXR) * thrust
        dy = bdy + rng.random() * (X_DYR * thrust)
        particles.append(Particle(x=x1 + rng.random() * X_XJ - 0.5, y=y, dx=dx, dy=dy, life=life))
    if rng.random() < thrust:
        dx = (rng.random() * X_DXJ - X_DXR) * thrust
        dy = bdy + rng.random() * (X_DYR * thrust)
        particles.append(Particle(x=x2 + rng.random() * X_XJ - 0.5, y=y, dx=dx, dy=dy, life=life))


def update_particles(particles: List[Particle]) -> None:
    i = 0
    while i < len(particles):
        p = particles[i]
        p.x += p.dx
        p.y += p.dy
        p.life -= 1
        if p.life <= 0 or p.y > OFF_MAX:
            particles.pop(i)
        else:
            i += 1


def draw_particles(base_p: Image.Image, particles: List[Particle]) -> None:
    put = base_p.putpixel
    for p in particles:
        c = COL_Y if p.life > 8 else (COL_O if p.life > 4 else COL_R)
        xi = int(math.floor(p.x))
        yi = int(math.floor(p.y))
        if 0 <= xi < base_p.width and 0 <= yi < base_p.height:
            put((xi, yi), c)


def simulate_and_render(out_path: str, width: int, height: int, fps: int, fixed_frames: int | None,
                        ship_path: str, tilt_path: str, margin: int, drain_frames: int, seed: int, dither: bool,
                        decel_dist: float = 8.0, start_hold: int = 1) -> None:
    rng = random.Random(seed)

    # Load sprites
    ship_img = Image.open(ship_path).convert("RGBA")
    tilt_img = Image.open(tilt_path).convert("RGBA")
    tilt_img_r = ImageOps.mirror(tilt_img)  # moving right uses mirrored tilt

    # Place ship vertically roughly like the game (2/3 height)
    ship_x = (width - SHIP_W) / 2.0
    ship_y = math.floor((height * 2) / 3 - SHIP_H / 2)
    vx = 0.0

    # Movement targets
    minx = margin
    maxx = width - SHIP_W - margin
    cx = (width - SHIP_W) / 2.0

    # Phases: go left -> go right -> return center -> drain
    # dx is input (-1, 0, 1). We choose dx based on current target.
    targets = [minx, maxx, cx]
    phase = 0

    frames: List[Image.Image] = []
    particles: List[Particle] = []

    pal = build_palette_image(trans_index=0)

    # Helper to draw one frame
    def draw_frame() -> Image.Image:
        # Draw onto RGBA for accurate colors/alpha, then quantize to PICO-8 palette.
        frame_rgba = Image.new("RGBA", (width, height), (0, 0, 0, 0))
        # Draw particles then ship to layer correctly
        # Particles as solid pixels in PICO-8 colors
        put_rgba = frame_rgba.putpixel
        for p in particles:
            c = COL_Y if p.life > 8 else (COL_O if p.life > 4 else COL_R)
            r, g, b = PICO8_PALETTE[c]
            xi = int(math.floor(p.x))
            yi = int(math.floor(p.y))
            if 0 <= xi < width and 0 <= yi < height:
                put_rgba((xi, yi), (r, g, b, 255))
        # Pick sprite based on velocity
        if abs(vx) > FACE_EPS:
            spr = tilt_img_r if vx > 0 else tilt_img
        else:
            spr = ship_img
        paste_rgba(frame_rgba, spr, (int(round(ship_x)), int(round(ship_y))))
        # Quantize to PICO-8 palette, preserving transparency index 0
        return quantize_to_pico8(frame_rgba, pal, dither)

    # Optionally add starting hold frames so the first frame matches the final center frame
    start_hold = max(0, int(start_hold))
    for _ in range(start_hold):
        frames.append(draw_frame())

    # We will always simulate a complete loop, then optionally resample to a fixed frame count.
    max_frames = None

    # Run simulation until done (and optional fixed frame cap)
    finished = False
    drain_left = 0
    step = 0
    while not finished:
        # Determine input direction towards current target (if any)
        if phase < len(targets):
            target = targets[phase]
            dx_input = -1.0 if ship_x > target else (1.0 if ship_x < target else 0.0)
        else:
            # Drain phase: no steering input
            dx_input = 0.0

        # Desired velocity and acceleration (like game), with gentle decel near the target
        # Scale target speed down as we approach the target to avoid an abrupt snap.
        if phase < len(targets):
            dist = abs(targets[phase] - ship_x)
            spd_scale = min(1.0, dist / max(0.001, decel_dist))
        else:
            spd_scale = 1.0
        tx = dx_input * SHIP_SPD * spd_scale
        # Clamp acceleration step
        delta = tx - vx
        if delta > 0:
            vx += min(SHIP_ACC, delta)
        else:
            vx += max(-SHIP_ACC, delta)

        prev_x = ship_x
        ship_x += vx
        # Bounds clamp
        if ship_x < minx:
            ship_x = minx
            if vx < 0:
                vx = 0.0
        if ship_x > maxx:
            ship_x = maxx
            if vx > 0:
                vx = 0.0

        # After moving, check if we reached or crossed the current target.
        if phase < len(targets):
            target = targets[phase]
            crossed = (prev_x - target) * (ship_x - target) <= 0
            near = abs(ship_x - target) <= 0.25
            if near or crossed:
                # Snap to target and stop, then advance to next phase.
                ship_x = target
                vx = 0.0
                phase += 1
                if phase == len(targets):
                    # Begin drain: no emission; we will decelerate to zero
                    drain_left = max(0, drain_frames)

        # Thrust level (approximate game logic)
        moving = (phase < len(targets)) and (abs(dx_input) > 0)
        thrust = 0.6 if moving else 0.2
        # Disable emission during drain
        if phase >= len(targets):
            thrust = 0.0

        # Particles
        spawn_exhaust(particles, rng, ship_x, ship_y, thrust)
        update_particles(particles)

        # Draw
        frames.append(draw_frame())

        # Drain completion when particles gone and velocity zero at center
        if phase >= len(targets):
            # reduce velocity towards zero
            if abs(vx) < 1e-3:
                vx = 0.0
            if drain_left > 0:
                drain_left -= 1
            finished = (drain_left == 0) and (len(particles) == 0) and (abs(ship_x - cx) <= 0.1) and (vx == 0.0)

        # Step counter (no early cut; we resample later if needed)
        step += 1

    # If a fixed frame count was requested, resample the completed loop to exactly that many frames.
    if fixed_frames and fixed_frames > 0 and len(frames) > 0:
        import math as _math
        # Prefer a seamless loop by treating the last frame as duplicate of the first (both are centered),
        # and sampling only within [0, cycle_len).
        cycle_len = max(1, len(frames) - 1)
        out_n = int(fixed_frames)
        sampled = []
        for i in range(out_n):
            t = (i * cycle_len) / out_n
            idx = int(_math.floor(t))
            if idx >= cycle_len:
                idx = cycle_len - 1
            sampled.append(frames[idx])
        frames = sampled

    # Save GIF with transparency index 0
    duration_ms = int(1000 / max(1, fps))
    save_kwargs = dict(
        save_all=True,
        append_images=frames[1:],
        loop=0,
        duration=duration_ms,
        optimize=False,
        transparency=0,   # index 0 is our transparent color
        disposal=2,       # restore to background between frames to avoid trails
        background=0      # background color index is 0
    )
    frames[0].save(out_path, **save_kwargs)
    print(f"Wrote {out_path} ({len(frames)} frames @ {fps} fps, size {width}x{height})")


def parse_args() -> argparse.Namespace:
    ap = argparse.ArgumentParser(description="Generate a transparent, looping ship left-right GIF with exhaust.")
    ap.add_argument("--out", default=os.path.join("build", "ship_anim.gif"), help="Output GIF path")
    ap.add_argument("--width", type=int, default=128, help="Canvas width (default: 128)")
    ap.add_argument("--height", type=int, default=128, help="Canvas height (default: 128)")
    ap.add_argument("--fps", type=int, default=15, help="Frames per second (default: 15)")
    ap.add_argument("--frames", type=int, default=0, help="Fixed total frames; 0 = auto-compute")
    ap.add_argument("--seed", type=int, default=42, help="RNG seed (default: 42)")
    ap.add_argument("--no-dither", action="store_true", help="Disable GIF dithering (enabled by default)")
    ap.add_argument("--ship", default=os.path.join("assets", "sprites", "ship.png"), help="Path to straight ship sprite PNG")
    ap.add_argument("--tilt", default=os.path.join("assets", "sprites", "ship-tilt.png"), help="Path to tilt ship sprite PNG")
    ap.add_argument("--margin", type=int, default=0, help="Horizontal margin from edges in pixels (default: 0)")
    ap.add_argument("--drain-frames", type=int, default=18, help="Particle drain frames at end (default: 18)")
    ap.add_argument("--start-hold", type=int, default=1, help="Frames to hold at start at center (default: 1)")
    ap.add_argument("--decel-dist", type=float, default=8.0, help="Pixels over which to ease speed near targets (default: 8)")
    return ap.parse_args()


def main() -> None:
    args = parse_args()

    width = int(args.width)
    height = int(args.height)
    fps = int(args.fps)
    frames = int(args.frames) if args.frames and args.frames > 0 else None
    seed = int(args.seed)
    dither = not args.no_dither

    # Ensure output folder exists
    out_dir = os.path.dirname(args.out)
    if out_dir and not os.path.isdir(out_dir):
        os.makedirs(out_dir, exist_ok=True)

    simulate_and_render(
        out_path=args.out,
        width=width,
        height=height,
        fps=fps,
        fixed_frames=frames,
        ship_path=args.ship,
        tilt_path=args.tilt,
        margin=int(args.margin),
        drain_frames=int(args.drain_frames),
        seed=seed,
        dither=dither,
        decel_dist=float(args.decel_dist),
        start_hold=int(args.start_hold),
    )


if __name__ == "__main__":
    main()
