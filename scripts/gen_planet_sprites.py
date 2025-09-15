#!/usr/bin/env python3
"""
Generate planet sprite sheet for PICO-8 matching the game's planet generation.

Creates sprites for:
- Size 1 (r=1): tiny planets
- Size 2 (r=2): small planets  
- Size 3 (r=3): medium planets with optional rings

Each sprite is 8x8 pixels to fit PICO-8's sprite system.

Usage:
    python gen_planet_sprites.py --out-dir build/sprites
"""

import argparse
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


def draw_planet(draw, cx, cy, radius, color_idx, shading=True):
    """Draw a planet with optional shading."""
    base_color = PICO8_PALETTE[color_idx]
    
    if radius < 1:
        # Just a pixel for tiny planets
        draw.point((cx, cy), fill=base_color + (255,))
        return
    
    # Draw main circle
    bbox = (cx - radius, cy - radius, cx + radius, cy + radius)
    draw.ellipse(bbox, fill=base_color + (255,))
    
    if shading and radius >= 2:
        # Add subtle shading with darker color on one side
        shade_color = PICO8_PALETTE[max(0, color_idx - 1)]
        for y in range(cy - radius, cy + radius + 1):
            for x in range(cx - radius, cx):
                dx = x - cx
                dy = y - cy
                if dx*dx + dy*dy <= radius*radius:
                    # Left side shading
                    if x < cx - radius//2:
                        draw.point((x, y), fill=shade_color + (255,))


def draw_ring(draw, cx, cy, planet_radius, angle, color_idx):
    """Draw a ring around a planet at the given angle."""
    ring_color = PICO8_PALETTE[color_idx]
    
    # Ring dimensions based on planet size
    rx = planet_radius + 2  # horizontal radius
    ry = max(1, planet_radius - 1)  # vertical radius (flattened)
    
    # Simple approach: draw ellipse for ring
    # For angled rings, we'd need more complex math, but for pixel art
    # we'll use a few preset orientations
    
    if angle < 0.25:
        # Horizontal ring
        for x in range(cx - rx, cx + rx + 1):
            dx = x - cx
            if abs(dx) > planet_radius - 1:  # Only draw outside planet
                y_offset = int(ry * math.sqrt(1 - (dx/rx)**2))
                draw.point((x, cy - y_offset), fill=ring_color + (255,))
                if y_offset > 0:
                    draw.point((x, cy + y_offset), fill=ring_color + (255,))
    elif angle < 0.5:
        # Diagonal ring (top-left to bottom-right)
        for i in range(-rx, rx + 1):
            x = cx + i
            y = cy + int(i * 0.5)
            dx = x - cx
            dy = y - cy
            # Check if outside planet body
            if dx*dx + dy*dy > (planet_radius-0.5)**2:
                if abs(i) > planet_radius - 1:
                    draw.point((x, y), fill=ring_color + (255,))
    elif angle < 0.75:
        # Vertical ring (edge-on)
        for y in range(cy - ry, cy + ry + 1):
            dy = y - cy
            x_offset = int(rx * math.sqrt(max(0, 1 - (dy/ry)**2)))
            if x_offset > planet_radius - 1:
                draw.point((cx - x_offset, y), fill=ring_color + (255,))
                draw.point((cx + x_offset, y), fill=ring_color + (255,))
    else:
        # Diagonal ring (top-right to bottom-left)
        for i in range(-rx, rx + 1):
            x = cx + i
            y = cy - int(i * 0.5)
            dx = x - cx
            dy = y - cy
            # Check if outside planet body
            if dx*dx + dy*dy > (planet_radius-0.5)**2:
                if abs(i) > planet_radius - 1:
                    draw.point((x, y), fill=ring_color + (255,))


def generate_planet_sheet():
    """Generate a sprite sheet with all planet variations."""
    # Each sprite is 8x8, but we'll add spacing
    sprite_size = 8
    spacing = 2  # pixels between sprites
    sprites_per_row = 8
    rows = 3
    
    sheet_width = (sprite_size + spacing) * sprites_per_row - spacing
    sheet_height = (sprite_size + spacing) * rows - spacing
    
    # Create transparent background
    img = Image.new("RGBA", (sheet_width, sheet_height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    sprites = []
    
    # Use only dark blue and dark gray
    planet_colors = [1, 5]  # dark-blue, dark-gray
    
    # Row 1: Size 1 planets (tiny) alternating between the two colors
    for i in range(sprites_per_row):
        x = i * (sprite_size + spacing) + sprite_size // 2
        y = sprite_size // 2
        col = planet_colors[i % 2]
        draw_planet(draw, x, y, 1, col, shading=False)
        sprites.append(f"Sprite {i}: Size 1, Color {col}")
    
    # Row 2: Size 2 planets (small) alternating colors
    for i in range(sprites_per_row):
        x = i * (sprite_size + spacing) + sprite_size // 2
        y = (sprite_size + spacing) + sprite_size // 2
        col = planet_colors[i % 2]
        draw_planet(draw, x, y, 2, col, shading=True)
        sprites.append(f"Sprite {i+8}: Size 2, Color {col}")
    
    # Row 3: Size 3 planets (medium) - half without rings, half with rings at different angles
    for i in range(sprites_per_row):
        x = i * (sprite_size + spacing) + sprite_size // 2
        y = 2 * (sprite_size + spacing) + sprite_size // 2
        
        if i < 4:
            # Planets without rings, alternating colors
            col = planet_colors[i % 2]
            draw_planet(draw, x, y, 3, col, shading=True)
            sprites.append(f"Sprite {i+16}: Size 3, Color {col}, No ring")
        else:
            # Planets with rings at different angles
            col = planet_colors[(i-4) % 2]
            draw_planet(draw, x, y, 3, col, shading=True)
            angle = (i - 4) * 0.25  # 0, 0.25, 0.5, 0.75
            # Use the opposite color for rings
            ring_col = 5 if col == 1 else 1
            draw_ring(draw, x, y, 3, angle, ring_col)
            sprites.append(f"Sprite {i+16}: Size 3, Color {col}, Ring angle {angle:.2f}")
    
    return img, sprites


def main():
    parser = argparse.ArgumentParser(description="Generate planet sprite sheet for PICO-8")
    parser.add_argument("--out-dir", default="build/sprites",
                       help="Output directory for sprite sheet")
    parser.add_argument("--show-grid", action="store_true",
                       help="Add grid lines to show sprite boundaries")
    args = parser.parse_args()
    
    out_dir = Path(args.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    
    # Generate the sprite sheet
    img, sprite_list = generate_planet_sheet()
    
    # Optionally add grid
    if args.show_grid:
        draw = ImageDraw.Draw(img)
        grid_color = (64, 64, 64, 128)
        # Vertical lines
        for x in range(8, img.width, 8):
            draw.line([(x, 0), (x, img.height)], fill=grid_color)
        # Horizontal lines
        for y in range(8, img.height, 8):
            draw.line([(0, y), (img.width, y)], fill=grid_color)
    
    # Save the sprite sheet
    out_path = out_dir / "planet_sprites.png"
    img.save(out_path)
    print(f"Generated planet sprite sheet: {out_path}")
    print(f"Sheet size: {img.width}x{img.height} ({img.width//8}x{img.height//8} sprites)")
    
    # Print sprite descriptions
    print("\nSprite descriptions:")
    for desc in sprite_list:
        print(f"  {desc}")
    
    # Save a scaled-up preview for easier viewing
    preview = img.resize((img.width * 4, img.height * 4), Image.NEAREST)
    preview_path = out_dir / "planet_sprites_preview.png"
    preview.save(preview_path)
    print(f"\nGenerated 4x preview: {preview_path}")
    
    print("\nTo use in PICO-8:")
    print("1. Import planet_sprites.png into sprite editor")
    print("2. Sprites 0-7: Size 1 (tiny) planets")
    print("3. Sprites 8-15: Size 2 (small) planets")
    print("4. Sprites 16-19: Size 3 (medium) planets without rings")
    print("5. Sprites 20-23: Size 3 (medium) planets with rings")
    print("\nIn code, use: spr(16 + planet.r - 1, x-4, y-4)")


if __name__ == "__main__":
    main()
