# PICO-8 Space Station tiles & mockup generator
# Produces:
#  - /mnt/data/pico8_space_station_tilesheet_16x16x64.png (128x128)
#  - /mnt/data/pico8_station_mockup_128x128.png (128x128)

from PIL import Image, ImageDraw
import math, random, os

# --- PICO-8 default palette (0..15) ---
PALETTE_HEX = [
    "#000000","#1D2B53","#7E2553","#008751","#AB5236","#5F574F","#C2C3C7","#FFF1E8",
    "#FF004D","#FFA300","#FFEC27","#00E436","#29ADFF","#83769C","#FF77A8","#FFCCAA"
]
PALETTE = [tuple(int(h[i:i+2],16) for i in (1,3,5)) for h in PALETTE_HEX]
BLACK, DBLUE, DPURP, DGREEN, BROWN, DGRAY, LGRAY, WHITE, RED, ORANGE, YELLOW, GREEN, BLUE, INDIGO, PINK, PEACH = range(16)

TILE_SIZE = 16
SHEET_TILES = 64
SHEET_COLS = 8
SHEET_ROWS = SHEET_TILES // SHEET_COLS

def new_tile(color=DGRAY):
    return Image.new("RGB", (TILE_SIZE, TILE_SIZE), PALETTE[color])

def px(draw, x, y, color):
    if 0 <= x < TILE_SIZE and 0 <= y < TILE_SIZE:
        draw.point((x,y), fill=PALETTE[color])

def rect(draw, x0,y0,x1,y1, color, fill=False):
    if fill:
        draw.rectangle([x0,y0,x1,y1], fill=PALETTE[color])
    else:
        draw.rectangle([x0,y0,x1,y1], outline=PALETTE[color])

def line(draw, x0,y0,x1,y1, color):
    draw.line([x0,y0,x1,y1], fill=PALETTE[color])

def circle(draw, cx, cy, r, color, fill=False):
    bbox=[cx-r, cy-r, cx+r, cy+r]
    if fill: draw.ellipse(bbox, fill=PALETTE[color])
    else:    draw.ellipse(bbox, outline=PALETTE[color])

# --- tiny 5x7 pixel font (A,B,1,2,i,+,-) ---
FONT5x7 = {
    "A":["01110","10001","10001","11111","10001","10001","10001"],
    "B":["11110","10001","11110","10001","10001","10001","11110"],
    "1":["00100","01100","00100","00100","00100","00100","01110"],
    "2":["01110","10001","00001","00010","00100","01000","11111"],
    "i":["00100","00000","01100","00100","00100","00100","01110"],
    "+":["00100","00100","11111","00100","00100","00000","00000"],
    "-":["00000","00000","11111","00000","00000","00000","00000"],
}

def draw_char(draw, ch, x, y, color=YELLOW, scale=1):
    grid = FONT5x7.get(ch.upper() if ch not in FONT5x7 else ch, None)
    if not grid: return
    for r,row in enumerate(grid):
        for c,bit in enumerate(row):
            if bit == "1":
                for dy in range(scale):
                    for dx in range(scale):
                        px(draw, x + c*scale + dx, y + r*scale + dy, color)

# --- floor tiles ---
def tile_plain_floor():
    img=new_tile(5); d=ImageDraw.Draw(img)
    for y in (3,8,13):
        for x in (3,8,13): px(d,x,y,6)
    line(d,0,7,15,7,1); line(d,7,0,7,15,1)
    return img

def tile_grid_floor():
    img=new_tile(5); d=ImageDraw.Draw(img)
    for x in range(0,16,4): line(d,x,0,x,15,1)
    for y in range(0,16,4): line(d,0,y,15,y,1)
    return img

def tile_hazard():
    img=new_tile(5); d=ImageDraw.Draw(img)
    for k in range(-8,16,4):
        for t in range(16):
            x=t; y=t-k
            if 0<=x<16 and 0<=y<16:
                px(d,x,y,9); 
                if y+1<16: px(d,x,y+1,9)
    rect(d,0,0,15,15,1,False)
    return img

def tile_vent():
    img=new_tile(5); d=ImageDraw.Draw(img)
    rect(d,1,1,14,14,1,False)
    for y in range(3,14,3): line(d,2,y,13,y,6)
    return img

def tile_pad_border():
    img=new_tile(5); d=ImageDraw.Draw(img)
    rect(d,1,1,14,14,9,False); rect(d,3,3,12,12,0,False)
    return img

def tile_conveyor_h():
    img=new_tile(3); d=ImageDraw.Draw(img)
    rect(d,0,0,15,15,1,False)
    for y in (5,10): line(d,1,y,14,y,6)
    for x in range(2,15,3): line(d,x,7,x,8,9)
    return img

def tile_conveyor_v():
    img=new_tile(3); d=ImageDraw.Draw(img)
    rect(d,0,0,15,15,1,False)
    for x in (5,10): line(d,x,1,x,14,6)
    for y in range(2,15,3): line(d,7,y,8,y,9)
    return img

def tile_conveyor_corner_tl():
    img=new_tile(3); d=ImageDraw.Draw(img)
    rect(d,0,0,15,15,1,False)
    for y in (5,10): line(d,1,y,10,y,6)
    for x in (5,10): line(d,x,1,x,10,6)
    for i in range(3): px(d,7+i,7-i,9); px(d,7+i,8-i,9)
    return img

# --- walls ---
def tile_wall_top():
    img=new_tile(1); d=ImageDraw.Draw(img)
    rect(d,0,0,15,3,13,True); rect(d,0,4,15,15,1,True); line(d,0,4,15,4,6)
    return img

def tile_wall_bottom():
    img=new_tile(1); d=ImageDraw.Draw(img)
    rect(d,0,0,15,11,1,True); rect(d,0,12,15,15,13,True); line(d,0,11,15,11,6)
    return img

def tile_wall_left():
    img=new_tile(1); d=ImageDraw.Draw(img)
    rect(d,0,0,3,15,13,True); rect(d,4,0,15,15,1,True); line(d,4,0,4,15,6)
    return img

def tile_wall_right():
    img=new_tile(1); d=ImageDraw.Draw(img)
    rect(d,0,0,11,15,1,True); rect(d,12,0,15,15,13,True); line(d,11,0,11,15,6)
    return img

def tile_wall_corner_tl():
    img=new_tile(1); d=ImageDraw.Draw(img)
    rect(d,0,0,3,3,13,True); rect(d,4,0,15,15,1,True); rect(d,0,4,3,15,1,True)
    line(d,4,0,4,15,6); line(d,0,4,15,4,6)
    return img

def tile_wall_corner_tr(): return tile_wall_corner_tl().transpose(Image.FLIP_LEFT_RIGHT)
def tile_wall_corner_bl(): return tile_wall_corner_tl().transpose(Image.FLIP_TOP_BOTTOM)
def tile_wall_corner_br(): return tile_wall_corner_tl().transpose(Image.ROTATE_180)

# --- access & rails ---
def tile_door_v():
    img=new_tile(1); d=ImageDraw.Draw(img)
    rect(d,5,1,10,14,12,True); rect(d,6,2,9,13,1,True)
    line(d,7,3,7,12,12); line(d,8,3,8,12,12)
    return img

def tile_door_h():
    img=new_tile(1); d=ImageDraw.Draw(img)
    rect(d,1,5,14,10,12,True); rect(d,2,6,13,9,1,True)
    line(d,3,7,12,7,12); line(d,3,8,12,8,12)
    return img

def tile_window():
    img=new_tile(1); d=ImageDraw.Draw(img)
    rect(d,1,1,14,14,6,False)
    for (x,y) in [(3,4),(6,8),(10,3),(12,10),(4,12)]: px(d,x,y,7)
    for y in range(2,14):
        for x in range(2,14):
            if (x+y)%7==0: px(d,x,y,12)
    return img

def tile_rail_h():
    img=new_tile(5); d=ImageDraw.Draw(img)
    line(d,0,4,15,4,6); line(d,0,11,15,11,6); line(d,0,5,15,5,0); line(d,0,10,15,10,0)
    return img

def tile_rail_v():
    img=new_tile(5); d=ImageDraw.Draw(img)
    line(d,4,0,4,15,6); line(d,11,0,11,15,6); line(d,5,0,5,15,0); line(d,10,0,10,15,0)
    return img

def tile_rail_corner_tl():
    img=new_tile(5); d=ImageDraw.Draw(img)
    line(d,0,4,10,4,6); line(d,0,11,10,11,6)
    line(d,4,0,4,10,6); line(d,11,0,11,10,6)
    return img

def tile_rail_corner_br(): return tile_rail_corner_tl().transpose(Image.ROTATE_180)

def tile_info_kiosk():
    img=new_tile(1); d=ImageDraw.Draw(img)
    rect(d,2,2,13,13,6,True); rect(d,3,3,12,12,1,False); draw_char(d,"i",6,4,12,1)
    return img

# --- shop blocks (2x2) ---
def draw_icon(d, kind, x, y, color):
    if kind=="fuel":  # droplet
        pts=[(3,0),(5,2),(6,4),(5,6),(3,7),(1,6),(0,4),(1,2)]
        pts=[(x+px, y+py) for (px,py) in pts]
        for i in range(len(pts)-1): d.line([pts[i], pts[i+1]], fill=PALETTE[color])
        d.line([pts[-1], pts[0]], fill=PALETTE[color])
        for cy in range(2,6):
            for cx in range(2,5): d.point((x+cx,y+cy), fill=PALETTE[color])
    elif kind=="shield":
        rect(d,x+1,y+0,x+5,y+1,color,False)
        rect(d,x+0,y+1,x+6,y+3,color,False)
        rect(d,x+1,y+4,x+5,y+6,color,False)
        for cy in range(2,6):
            for cx in range(2,5): d.point((x+cx,y+cy), fill=PALETTE[color])
    elif kind=="upgrade":  # gear-ish
        circle(d, x+3, y+3, 3, color, False)
        for i in range(8):
            ang=i*45*3.14159/180
            sx=int(x+3+math.cos(ang)*4); sy=int(y+3+math.sin(ang)*4)
            d.point((sx,sy), fill=PALETTE[color])
        circle(d, x+3, y+3, 1, color, True)

def build_shop_block_with_icon(banner_color, icon_kind, icon_color):
    block = Image.new("RGB",(32,32), PALETTE[5]); d=ImageDraw.Draw(block)
    d.rectangle([1,1,30,30], outline=PALETTE[1])           # frame
    d.rectangle([2,2,29,8],  fill=PALETTE[banner_color])   # banner
    d.rectangle([2,20,29,23],fill=PALETTE[6])              # counter lip
    d.rectangle([2,9,5,30],  fill=PALETTE[1])              # pillars
    d.rectangle([26,9,29,30],fill=PALETTE[1])
    d.rectangle([8,12,23,19],fill=PALETTE[12])             # window
    d.rectangle([9,13,22,18],outline=PALETTE[1])
    d.rectangle([11,3,20,7], fill=PALETTE[1])              # icon plate
    draw_icon(d, icon_kind, 12,3, icon_color)
    tiles=[]
    for ty in range(2):
        for tx in range(2):
            tiles.append(block.crop((tx*16,ty*16,tx*16+16,ty*16+16)))
    return tiles

def tile_terminal():
    img=new_tile(5); d=ImageDraw.Draw(img)
    rect(d,2,3,13,10,12,True); line(d,2,11,13,11,1); rect(d,3,4,12,9,1,False)
    rect(d,2,12,13,13,1,True)  # keyboard
    for x in range(3,13,2): px(d,x,12,6)
    return img

# --- shipping props & signage ---
def tile_crate_wood():
    img=new_tile(4); d=ImageDraw.Draw(img)
    rect(d,1,1,14,14,0,False)
    line(d,2,2,13,13,0); line(d,2,13,13,2,0)
    for y in range(3,14,3): line(d,2,y,13,y,5)
    return img

def tile_crate_steel():
    img=new_tile(6); d=ImageDraw.Draw(img)
    rect(d,1,1,14,14,1,False)
    for x in (4,8,12): line(d,x,2,x,13,5)
    return img

def tile_package_small():
    img=new_tile(5); d=ImageDraw.Draw(img)
    rect(d,4,5,12,12,15,True); line(d,4,8,12,8,9); rect(d,4,5,12,12,4,False)
    return img

def tile_pallet_stack():
    img=new_tile(5); d=ImageDraw.Draw(img)
    rect(d,2,11,13,13,4,True)  # pallet
    for x in (3,6,9,12): line(d,x,11,x,13,0)
    rect(d,2,3,7,10,15,True); rect(d,8,3,13,10,15,True)
    line(d,2,6,7,6,9); line(d,8,6,13,6,9)
    rect(d,2,3,7,10,4,False); rect(d,8,3,13,10,4,False)
    return img

def tile_label():
    img=new_tile(5); d=ImageDraw.Draw(img)
    rect(d,3,9,12,13,15,True); rect(d,3,9,12,13,4,False); line(d,4,10,11,10,9)
    return img

def tile_conveyor_tight_corner():
    img=new_tile(3); d=ImageDraw.Draw(img)
    rect(d,0,0,15,15,1,False)
    for y in (5,10): line(d,8,y,14,y,6)
    for x in (5,10): line(d,x,8,x,14,6)
    for i in range(3): px(d,11+i,11-i,9); px(d,11+i,12-i,9)
    return img

def tile_arrow_sign():
    img=new_tile(5); d=ImageDraw.Draw(img)
    rect(d,1,4,14,12,1,True)
    for y in range(7,9): line(d,3,y,11,y,10)
    for i in range(4): line(d,11,6+i,13,7,10)
    return img

def tile_caution_sign():
    img=new_tile(5); d=ImageDraw.Draw(img)
    rect(d,1,3,14,12,9,True)
    for t in range(1,13,2): line(d,t,3, t+2,12,8)
    rect(d,1,3,14,12,1,False)
    return img

def tile_window_alt(): return tile_window()

def tile_plant():
    img=new_tile(5); d=ImageDraw.Draw(img)
    rect(d,5,10,10,13,4,True)  # pot
    for i in range(6):
        px(d,7+random.randint(-2,2), 6+random.randint(-2,2), 11)
        px(d,8+random.randint(-2,2), 7+random.randint(-2,2), 3)
    return img

def tile_pad_letter_A():
    img=new_tile(5); d=ImageDraw.Draw(img)
    rect(d,2,2,13,13,9,False); draw_char(d,"A",5,4,10,1)
    return img

def tile_pad_number_1():
    img=new_tile(5); d=ImageDraw.Draw(img)
    rect(d,2,2,13,13,9,False); draw_char(d,"1",6,4,10,1)
    return img

def tile_pad_letter_B():
    img=new_tile(5); d=ImageDraw.Draw(img)
    rect(d,2,2,13,13,9,False); draw_char(d,"B",5,4,10,1)
    return img

def tile_pad_number_2():
    img=new_tile(5); d=ImageDraw.Draw(img)
    rect(d,2,2,13,13,9,False); draw_char(d,"2",5,4,10,1)
    return img

# --- ship (2x2) ---
def build_ship_quadrants():
    img = Image.new("RGB",(32,32), PALETTE[5]); d=ImageDraw.Draw(img)
    circle(d,16,18,12,1,False)             # shadow ring
    rect(d,11,6,21,26,7,True)              # hull (white)
    rect(d,13,9,19,15,12,True)             # cockpit (cyan/blue)
    rect(d,7,14,11,22,7,True)              # wings
    rect(d,21,14,25,22,7,True)
    rect(d,12,26,15,29,6,True)             # engines
    rect(d,17,26,20,29,6,True)
    line(d,11,6,21,6,6); line(d,11,26,21,26,6)
    tiles=[]
    for ty in range(2):
        for tx in range(2):
            tiles.append(img.crop((tx*16,ty*16,tx*16+16,ty*16+16)))
    return tiles

def tile_floor_rivets_alt():
    img=new_tile(5); d=ImageDraw.Draw(img)
    for y in (4,11):
        for x in range(1,16,3): px(d,x,y,6)
    return img

def tile_hatch():
    img=new_tile(5); d=ImageDraw.Draw(img)
    rect(d,2,3,13,12,1,False); line(d,2,8,13,8,1); line(d,8,3,8,12,1)
    return img

# --- assemble whole set of 64 tiles in the ID order we discussed ---
def make_all_tiles():
    tiles=[]
    # Row 0 (0..7)
    tiles += [tile_plain_floor(), tile_grid_floor(), tile_hazard(), tile_vent(),
              tile_pad_border(), tile_conveyor_h(), tile_conveyor_v(), tile_conveyor_corner_tl()]
    # Row 1 (8..15)
    tiles += [tile_wall_top(), tile_wall_bottom(), tile_wall_left(), tile_wall_right(),
              tile_wall_corner_tl(), tile_wall_corner_tr(), tile_wall_corner_bl(), tile_wall_corner_br()]
    # Row 2 (16..23)
    tiles += [tile_door_v(), tile_door_h(), tile_window(), tile_rail_h(),
              tile_rail_v(), tile_rail_corner_tl(), tile_rail_corner_br(), tile_info_kiosk()]
    # Rows 3-4 (24..35): shops 2x2 blocks
    tiles += build_shop_block_with_icon(ORANGE,"fuel",YELLOW)    # 24..27
    tiles += build_shop_block_with_icon(BLUE,"shield",BLUE)      # 28..31
    tiles += build_shop_block_with_icon(YELLOW,"upgrade",ORANGE) # 32..35
    # Row 4 cont. (36..39): counters & terminal
    def simple_counter(color):
        img=new_tile(5); d=ImageDraw.Draw(img)
        d.rectangle([2,4,13,9], fill=PALETTE[color])
        d.rectangle([2,10,13,12], fill=PALETTE[6])
        d.rectangle([2,4,13,12], outline=PALETTE[1])
        return img
    tiles += [simple_counter(ORANGE), simple_counter(BLUE), simple_counter(YELLOW), tile_terminal()]
    # Row 5 (40..47): shipping & signs
    tiles += [tile_crate_wood(), tile_crate_steel(), tile_package_small(), tile_pallet_stack(),
              tile_label(), tile_conveyor_tight_corner(), tile_arrow_sign(), tile_caution_sign()]
    # Row 6 (48..55): misc + ship half
    tiles += [tile_window_alt(), tile_plant(), tile_pad_letter_A(), tile_pad_number_1(),
              tile_pad_letter_B(), tile_pad_number_2()]
    tiles += build_ship_quadrants()  # 54..57
    # Row 7 (58..63): extras
    tiles += [tile_rail_corner_tl(), tile_rail_corner_br(), tile_floor_rivets_alt(), tile_hatch(),
              tile_grid_floor(), tile_plain_floor()]
    assert len(tiles)==64
    return tiles

def assemble_tilesheet(tiles):
    sheet = Image.new("RGB", (SHEET_COLS*TILE_SIZE, SHEET_ROWS*TILE_SIZE), PALETTE[0])
    for i, tile in enumerate(tiles):
        x = (i % SHEET_COLS) * TILE_SIZE
        y = (i // SHEET_COLS) * TILE_SIZE
        sheet.paste(tile, (x,y))
    return sheet

def render_mockup(tiles, layout8x8):
    img = Image.new("RGB",(128,128), PALETTE[0])
    for ty,row in enumerate(layout8x8):
        for tx,tile_id in enumerate(row):
            img.paste(tiles[tile_id], (tx*16, ty*16))
    return img

def main():
    tiles = make_all_tiles()
    sheet = assemble_tilesheet(tiles)
    # Station layout (8x8 of 16x16 macro-tiles)
    station = [
     [12,  8,  8, 17, 17,  8,  8, 13],
     [10, 24, 25, 28, 29, 32, 33, 11],
     [10, 26, 27, 30, 31, 34, 35, 11],
     [10,  0,  0,  4,  0,  0,  7, 11],
     [10,  0, 50, 51,  0,  5, 40, 11],
     [10,  0, 54, 55,  5, 40, 42, 11],
     [10, 49, 56, 57, 46, 43, 41, 11],
     [14,  9,  9, 17, 17,  9,  9, 15],
    ]
    mock = render_mockup(tiles, station)
    out_sheet = "pico8_space_station_tilesheet_16x16x64.png"
    out_mock = "pico8_station_mockup_128x128.png"
    sheet.save(out_sheet, optimize=True)
    mock.save(out_mock, optimize=True)
    print("Saved:", out_sheet, os.path.getsize(out_sheet), "bytes")
    print("Saved:", out_mock, os.path.getsize(out_mock), "bytes")

if __name__ == "__main__":
    main()
