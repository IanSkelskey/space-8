#!/usr/bin/env python3
"""
Generate tileable starfield PNG assets for PICO-8 to save tokens.

Creates 4 layer PNGs:
- far_stars.png: Dense field of dim stars (color 1)
- mid_stars.png: Medium density with some brighter stars (colors 5, 6)  
- near_stars.png: Sparse bright stars (color 13)
- planets.png: Very sparse distant planets

Each tile is designed to tile seamlessly and can be scrolled at different speeds
for parallax effect in PICO-8.

Usage:
    python gen_starfield_tiles.py --out-dir build/starfield_tiles
"""

import argparse
import random
import math
from pathlib import Path
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


def create_tileable_stars(width, height, star_count, colors, seed=None, twinkle_variants=0):
    """Create a tileable star pattern.
    
    Args:
        width: Tile width (should be power of 2 for efficient tiling)
        height: Tile height (should be power of 2 for efficient tiling)
        star_count: Number of stars to place
        colors: List of color indices to use
        seed: Random seed for reproducibility
        twinkle_variants: Number of twinkle animation frames (0 for static)
    
    Returns:
        List of PIL Images (one per frame if animated, otherwise single frame)
    """
    if seed is not None:
        random.seed(seed)
    
    frames = []
    base_positions = []
    
    # Generate base star positions that tile seamlessly
    # Use a larger virtual space and wrap to ensure good distribution at edges
    virtual_mult = 3
    vw, vh = width * virtual_mult, height * virtual_mult
    
    for _ in range(star_count * virtual_mult * virtual_mult):
        x = random.randint(0, vw - 1)
        y = random.randint(0, vh - 1)
        col_idx = random.choice(colors)
        base_positions.append((x % width, y % height, col_idx))
    
    # Remove duplicates that would stack on the same pixel
    seen = set()
    unique_positions = []
    for pos in base_positions:
        key = (pos[0], pos[1])
        if key not in seen:
            seen.add(key)
            unique_positions.append(pos)
            if len(unique_positions) >= star_count:
                break
    
    # Create frames (static or with twinkle animation)
    frame_count = max(1, twinkle_variants)
    for frame_idx in range(frame_count):
        img = Image.new("RGBA", (width, height), (0, 0, 0, 0))  # Transparent background
        
        for x, y, base_col in unique_positions:
            col_idx = base_col
            
            # Apply twinkle effect if requested
            if twinkle_variants > 0 and random.random() < 0.15:  # 15% chance to twinkle
                phase = (frame_idx / frame_count) * 2 * math.pi
                brightness = math.sin(phase + random.random() * 2 * math.pi)
                if brightness > 0.5:
                    col_idx = 6  # bright
                elif brightness < -0.3:
                    col_idx = 1  # dim
            
            rgb = PICO8_PALETTE[col_idx]
            img.putpixel((x, y), rgb + (255,))  # Add alpha channel
        
        frames.append(img)
    
    return frames


def create_tileable_planets(width, height, planet_count, seed=None):
    """Create a tileable planet pattern.
    
    Args:
        width: Tile width
        height: Tile height  
        planet_count: Number of planets (kept very low)
        seed: Random seed
        
    Returns:
        PIL Image with planets
    """
    if seed is not None:
        random.seed(seed)
    
    img = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    for _ in range(planet_count):
        # Position with margin from edges for clean tiling
        margin = 4
        x = random.randint(margin, width - margin)
        y = random.randint(margin, height - margin)
        
        # Planet size distribution
        size_roll = random.random()
        if size_roll < 0.5:
            r = 1  # tiny
        elif size_roll < 0.8:
            r = 2  # small
        else:
            r = 3  # medium
        
        # Draw planet body
        col_rgb = PICO8_PALETTE[1]  # dark blue for subtle planets
        bbox = (x - r, y - r, x + r, y + r)
        draw.ellipse(bbox, fill=col_rgb + (255,))
        
        # Optional ring for larger planets
        if r == 3 and random.random() < 0.5:
            ring_rgb = PICO8_PALETTE[5]  # dark gray for rings
            rx, ry = r + 2, r
            draw.ellipse((x - rx, y - ry, x + rx, y + ry), 
                        outline=ring_rgb + (255,), width=1)
    
    return img


def main():
    parser = argparse.ArgumentParser(description="Generate tileable starfield PNG assets for PICO-8")
    parser.add_argument("--out-dir", default="build/starfield_tiles", 
                       help="Output directory for PNG files")
    parser.add_argument("--tile-size", type=int, default=64,
                       help="Tile size (width and height, should be power of 2)")
    parser.add_argument("--seed", type=int, default=42,
                       help="Random seed for reproducibility")
    parser.add_argument("--animated", action="store_true",
                       help="Generate animation frames for twinkling")
    args = parser.parse_args()
    
    out_dir = Path(args.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    
    size = args.tile_size
    seed = args.seed
    
    # Layer configurations matching the original starfield
    layers = [
        {
            "name": "far_stars",
            "star_count": 40,  # Dense far stars
            "colors": [1],      # Dark blue only
            "seed": seed
        },
        {
            "name": "mid_stars", 
            "star_count": 25,   # Medium density
            "colors": [5, 6],   # Dark gray and light gray (some twinkle)
            "seed": seed + 1
        },
        {
            "name": "near_stars",
            "star_count": 12,   # Sparse near stars  
            "colors": [13, 6],  # Indigo and light gray
            "seed": seed + 2
        }
    ]
    
    # Generate star layers
    for layer in layers:
        frames = create_tileable_stars(
            width=size,
            height=size,
            star_count=layer["star_count"],
            colors=layer["colors"],
            seed=layer["seed"],
            twinkle_variants=4 if args.animated and layer["name"] != "near_stars" else 0
        )
        
        if len(frames) == 1:
            # Single static frame
            out_path = out_dir / f"{layer['name']}.png"
            frames[0].save(out_path)
            print(f"Generated {out_path} ({size}x{size}, {layer['star_count']} stars)")
        else:
            # Multiple animation frames
            for i, frame in enumerate(frames):
                out_path = out_dir / f"{layer['name']}_frame{i}.png"
                frame.save(out_path)
            print(f"Generated {layer['name']} ({len(frames)} frames, {size}x{size}, {layer['star_count']} stars)")
    
    # Generate planet layer (always static, very sparse)
    planet_img = create_tileable_planets(
        width=size * 2,  # Larger tile for planets to reduce repetition
        height=size * 2,
        planet_count=2,  # Very few planets
        seed=seed + 3
    )
    planet_path = out_dir / "planets.png"
    planet_img.save(planet_path)
    print(f"Generated {planet_path} ({size*2}x{size*2}, 2 planets)")
    
    # Generate a composite preview showing all layers
    preview = Image.new("RGB", (size, size), PICO8_PALETTE[0])
    
    # Load and composite layers
    planet_img_scaled = planet_img.resize((size, size), Image.NEAREST)
    preview.paste(planet_img_scaled, (0, 0), planet_img_scaled)
    
    for layer in reversed(layers):  # Draw from back to front
        layer_path = out_dir / f"{layer['name']}.png"
        if layer_path.exists():
            layer_img = Image.open(layer_path)
            preview.paste(layer_img, (0, 0), layer_img)
    
    preview_path = out_dir / "preview_composite.png"
    preview.save(preview_path)
    print(f"\nGenerated preview at {preview_path}")
    
    print(f"\nTo use in PICO-8:")
    print(f"1. Import PNGs as sprite sheets")
    print(f"2. Draw each layer with different scroll speeds:")
    print(f"   - planets: speed * 0.125")
    print(f"   - far_stars: speed * 0.25")
    print(f"   - mid_stars: speed * 0.5")
    print(f"   - near_stars: speed * 1.0")
    print(f"3. Use map() or spr() with offset positions for seamless tiling")


if __name__ == "__main__":
    main()
