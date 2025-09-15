# P8SCII Character Set Reference

P8SCII is PICO-8's character set with 256 codes: 16 control codes and 240 printable characters.

## Control Codes (0-15)

| Number | Escape | Character | Name | Parameters |
|--------|--------|-----------|------|------------|
| 0 | `\0` | none | Terminate printing | |
| 1 | `\*` | ¹ | Repeat next character | P0: number of times to repeat |
| 2 | `\#` | ² | Draw solid background | P0: color |
| 3 | `\-` | ³ | Move cursor horizontally | P0: num of pixels minus 16 |
| 4 | `\|` | ⁴ | Move cursor vertically | P0: num of pixels minus 16 |
| 5 | `\+` | ⁵ | Move cursor | P0: horiz offset minus 16; P1: vert offset minus 16 |
| 6 | `\^` | ⁶ | Special command | See P8SCII Control Codes |
| 7 | `\a` | ⁷ | Audio command | See P8SCII Control Codes |
| 8 | `\b` | ⁸ | Backspace | |
| 9 | `\t` | tab | Tab | |
| 10 | `\n` | newline | Newline | |
| 11 | `\v` | ᵇ | Decorate previous character | See P8SCII Control Codes |
| 12 | `\f` | ᶜ | Set foreground color | P0: color |
| 13 | `\r` | none | Carriage return | |
| 14 | `\14` | ᵉ | Switch font defined at 0x5600 | |
| 15 | `\15` | ᶠ | Switch font to default | |

## Symbols and Japanese Punctuation (16-31)

| Number | Character | Name | Unicode | Entry (Japanese mode) |
|--------|-----------|------|---------|----------------------|
| 16 | ▮ | Vertical rectangle | U+25AE | Shift+1 |
| 17 | ■ | Filled square | U+25A0 | Shift+2 |
| 18 | □ | Hollow square | U+25A1 | Shift+3 |
| 19 | ⁙ | Five dot | U+2059 | Shift+4 |
| 20 | ⁘ | Four dot | U+2058 | Shift+5 |
| 21 | ‖ | Pause | U+2016 | Shift+6 |
| 22 | ◀ | Back | U+25C0 | Shift+7 |
| 23 | ▶ | Forward | U+25B6 | Shift+8 |
| 24 | 「 | Japanese starting quote | U+300C | [ |
| 25 | 」 | Japanese ending quote | U+300D | ] |
| 26 | ¥ | Yen sign | U+A5 | \ |
| 27 | • | Interpunct | U+2022 | / |
| 28 | 、 | Japanese comma | U+3001 | , |
| 29 | 。 | Japanese full stop | U+3002 | . |
| 30 | ゛ | Japanese dakuten | U+309B | e.g. ba |
| 31 | ゜ | Japanese handakuten | U+309C | e.g. pa |

## ASCII Characters (32-127)

Standard ASCII characters where 65-90 print as lowercase and 97-122 print as uppercase.

| Number | Character | Name | | Number | Character | Name |
|--------|-----------|------|-|--------|-----------|------|
| 32 | (space) | space | | 80 | P | P |
| 33 | ! | ! | | 81 | Q | Q |
| 34 | " | Double quote | | 82 | R | R |
| 35 | # | Number sign | | 83 | S | S |
| 36 | $ | Dollar sign | | 84 | T | T |
| 37 | % | Percent sign | | 85 | U | U |
| 38 | & | Ampersand | | 86 | V | V |
| 39 | ' | Single quote | | 87 | W | W |
| 40 | ( | ( | | 88 | X | X |
| 41 | ) | ) | | 89 | Y | Y |
| 42 | * | * | | 90 | Z | Z |
| 43 | + | + | | 91 | [ | [ |
| 44 | , | , | | 92 | \ | \ |
| 45 | - | - | | 93 | ] | ] |
| 46 | . | . | | 94 | ^ | Caret |
| 47 | / | / | | 95 | _ | Underscore |
| 48-57 | 0-9 | Numbers | | 96 | ` | Backtick |
| 58 | : | : | | 97-122 | a-z | Lowercase letters |
| 59 | ; | ; | | 123 | { | { |
| 60 | < | < | | 124 | \| | Vertical bar |
| 61 | = | = | | 125 | } | } |
| 62 | > | > | | 126 | ~ | Tilde |
| 63 | ? | ? | | 127 | ○ | Hollow circle |
| 64 | @ | @ | | | | |
| 65-79 | A-O | Uppercase letters | | | | |

## Typeable Symbols (128-153)

| Number | Character | Name | Unicode | Entry |
|--------|-----------|------|---------|-------|
| 128 | █ | Rectangle | U+2588 | Shift-A |
| 129 | ▒ | Checkerboard | U+2592 | Shift-B |
| 130 | 🐱 | Jelpi | U+1F431 | Shift-C |
| 131 | ⬇️ | Down key | U+2B07 U+FE0F | Shift-D |
| 132 | ░ | Dot pattern | U+2591 | Shift-E |
| 133 | ✽ | Throwing star | U+273D | Shift-F |
| 134 | ● | Ball | U+25CF | Shift-G |
| 135 | ♥ | Heart | U+2665 | Shift-H |
| 136 | ☉ | Eye | U+2609 | Shift-I |
| 137 | 웃 | Man | U+C6C3 | Shift-J |
| 138 | ⌂ | House | U+2302 | Shift-K |
| 139 | ⬅️ | Left key | U+2B05 U+FE0F | Shift-L |
| 140 | 😐 | Face | U+1F610 | Shift-M |
| 141 | ♪ | Musical note | U+266A | Shift-N |
| 142 | 🅾️ | O key | U+1F17E U+FE0F | Shift-O |
| 143 | ◆ | Diamond | U+25C6 | Shift-P |
| 144 | … | Ellipsis | U+2026 | Shift-Q |
| 145 | ➡️ | Right key | U+27A1 U+FE0F | Shift-R |
| 146 | ★ | Five-pointed star | U+2605 | Shift-S |
| 147 | ⧗ | Hourglass | U+29D7 | Shift-T |
| 148 | ⬆️ | Up key | U+2B06 U+FE0F | Shift-U |
| 149 | ˇ | Birds | U+2C7 | Shift-V |
| 150 | ∧ | Sawtooth | U+2227 | Shift-W |
| 151 | ❎ | X key | U+274E | Shift-X |
| 152 | ▤ | Horiz lines | U+25A4 | Shift-Y |
| 153 | ▥ | Vert lines | U+25A5 | Shift-Z |

## Hiragana (154-203)

| Number | Character | Entry | Unicode | | Number | Character | Entry | Unicode |
|--------|-----------|-------|---------|--|--------|-----------|-------|---------|
| 154 | あ | a | U+3042 | | 179 | は | ha | U+306F |
| 155 | い | i | U+3044 | | 180 | ひ | hi | U+3072 |
| 156 | う | u | U+3046 | | 181 | ふ | fu | U+3075 |
| 157 | え | e | U+3048 | | 182 | へ | he | U+3078 |
| 158 | お | o | U+304A | | 183 | ほ | ho | U+307B |
| 159 | か | ka | U+304B | | 184 | ま | ma | U+307E |
| 160 | き | ki | U+304D | | 185 | み | mi | U+307F |
| 161 | く | ku | U+304F | | 186 | む | mu | U+3080 |
| 162 | け | ke | U+3051 | | 187 | め | me | U+3081 |
| 163 | こ | ko | U+3053 | | 188 | も | mo | U+3082 |
| 164 | さ | sa | U+3055 | | 189 | や | ya | U+3084 |
| 165 | し | shi | U+3057 | | 190 | ゆ | yu | U+3086 |
| 166 | す | su | U+3059 | | 191 | よ | yo | U+3088 |
| 167 | せ | se | U+305B | | 192 | ら | ra | U+3089 |
| 168 | そ | so | U+305D | | 193 | り | ri | U+308A |
| 169 | た | ta | U+305F | | 194 | る | ru | U+308B |
| 170 | ち | chi | U+3061 | | 195 | れ | re | U+308C |
| 171 | つ | tsu | U+3064 | | 196 | ろ | ro | U+308D |
| 172 | て | te | U+3066 | | 197 | わ | wa | U+308F |
| 173 | と | to | U+3068 | | 198 | を | wo | U+3092 |
| 174 | な | na | U+306A | | 199 | ん | nn | U+3093 |
| 175 | に | ni | U+306B | | 200 | っ | tt | U+3063 |
| 176 | ぬ | nu | U+306C | | 201 | ゃ | e.g: kya | U+3083 |
| 177 | ね | ne | U+306D | | 202 | ゅ | e.g. kyu | U+3085 |
| 178 | の | no | U+306E | | 203 | ょ | e.g: kyo | U+3087 |

## Katakana (204-253)

| Number | Character | Entry | Unicode | | Number | Character | Entry | Unicode |
|--------|-----------|-------|---------|--|--------|-----------|-------|---------|
| 204 | ア | a | U+30A2 | | 229 | ハ | ha | U+30CF |
| 205 | イ | i | U+30A4 | | 230 | ヒ | hi | U+30D2 |
| 206 | ウ | u | U+30A6 | | 231 | フ | fu | U+30D5 |
| 207 | エ | e | U+30A8 | | 232 | ヘ | he | U+30D8 |
| 208 | オ | o | U+30AA | | 233 | ホ | ho | U+30DB |
| 209 | カ | ka | U+30AB | | 234 | マ | ma | U+30DE |
| 210 | キ | ki | U+30AD | | 235 | ミ | mi | U+30DF |
| 211 | ク | ku | U+30AF | | 236 | ム | mu | U+30E0 |
| 212 | ケ | ke | U+30B1 | | 237 | メ | me | U+30E1 |
| 213 | コ | ko | U+30B3 | | 238 | モ | mo | U+30E2 |
| 214 | サ | sa | U+30B5 | | 239 | ヤ | ya | U+30E4 |
| 215 | シ | shi | U+30B7 | | 240 | ユ | yu | U+30E6 |
| 216 | ス | su | U+30B9 | | 241 | ヨ | yo | U+30E8 |
| 217 | セ | se | U+30BB | | 242 | ラ | ra | U+30E9 |
| 218 | ソ | so | U+30BD | | 243 | リ | ri | U+30EA |
| 219 | タ | ta | U+30BF | | 244 | ル | ru | U+30EB |
| 220 | チ | chi | U+30C1 | | 245 | レ | re | U+30EC |
| 221 | ツ | tsu | U+30C4 | | 246 | ロ | ro | U+30ED |
| 222 | テ | te | U+30C6 | | 247 | ワ | wa | U+30EF |
| 223 | ト | to | U+30C8 | | 248 | ヲ | wo | U+30F2 |
| 224 | ナ | na | U+30CA | | 249 | ン | nn | U+30F3 |
| 225 | ニ | ni | U+30CB | | 250 | ッ | tt | U+30C3 |
| 226 | ヌ | nu | U+30CC | | 251 | ャ | e.g. kya | U+30E3 |
| 227 | ネ | ne | U+30CD | | 252 | ュ | e.g. kyu | U+30E5 |
| 228 | ノ | no | U+30CE | | 253 | ョ | e.g. kyo | U+30E7 |

## Final Symbols (254-255)

| Number | Character | Name | Unicode | Entry (Japanese mode) |
|--------|-----------|------|---------|----------------------|
| 254 | ◜ | Left arc | U+25DC | Shift+9 |
| 255 | ◝ | Right arc | U+25DD | Shift+0 |


# Lighting System in *Dank Tombs* — Key Concepts & Implementations

These are the distilled lessons & techniques from the “Lighting by Hand” articles by Jakub Wasilewski (creator of Dank Tomb / Dank Tombs) + the *Dank Tombs Tech Demo*.

| Stage                                 | What was added / improved                                                                                        | Key technique(s)                                                                                                                                                                                           | Trade‑offs / performance concerns                                                                  |
| ------------------------------------- | ---------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------- |
| **Part 1 — Thin Dark Line**           | Basic light radius, dark border line to block/unlit area.                                                        | Light circle drawing; thin dark line to demarcate “where light ends.” Probably using distance checks per-screen-pixel or per‐scan‐line.                                                                    | Limited smoothness; visible sharp edges; computing many distance checks is expensive.              |
| **Part 2 — Stitching Lines Together** | Smooth circle of light, blending of lines; stitching many small light / darkness segments to create circle fill. | Precomputing line offsets / radius per y‑scan, using lookup tables; drawing multiple lines per scan to fill circle shape. Maybe use symmetry to cut work in halves/quadrants.                              | More CPU work per frame; color banding becomes visible if too few levels.                          |
| **Part 3 — Breath of Life**           | Flicker / variation to simulate torch; softening harsh bands; adding life to lighting so it doesn’t feel static. | Dithering across bands; maybe random variation in brightness per line; slightly randomizing radius per frame; subtle color shifts.                                                                         | Adds jitter / complexity; must balance to avoid distraction; cost of random + fill / line drawing. |
| **Part 4 — Into the Shadows**         | Real‑time shadows: walls/obstacles block light; shadow volumes; more realistic light/shadow interactions.        | Represent walls as line segments; compute which walls are between light source and pixel; project shadow volumes/polygons; clip or subtract those regions when drawing light; use vector math efficiently. | Shadow computations are heavier; more geometry operations; potential token / performance cost.     |

---

# Proposed Design / Blueprint: Lighting + Damage System for Ninja Platformer

Below is a design that takes inspiration from *Dank Tombs*, adapted for platformer mechanics + “light hurts you” rule. Division by feature, plus suggestions for how to implement efficiently in PICO‑8 given constraints (128×128, 16 colors, limited CPU cycles/tokens).

## Features

* **Light Sources**: Torches, lanterns, spotlights, maybe flashing / pulsing lights.
* **Shadow Casters**: Walls, columns, blocks, maybe moving obstacles.
* **Ambient Darkness**: Areas outside light are dark (safe or possibly other mechanics).
* **Light as Hazard**: When player enters lit area (above certain brightness), health decreases (continuous or stepped).
* **Light Variation**: Flicker, soft edges, maybe gradient / falloff so edges are less harsh.
* **Optimization Modes**: Static lights vs dynamic; limit number of shadow casters; maybe precompute parts.

## Data Structures & Representations

```lua
light = {
  x, y,         -- center
  radius,       -- max reach
  intensity,    -- brightness scale 0‑1
  flicker_amp,  -- optionally how much radius/intensity quirks
  type,         -- e.g. point, spotlight (cone)
  dir,          -- if needed (for cones)
  shadow = true/false
}

wall = {
  x1, y1, x2, y2,   -- endpoints
  normal_dir,       -- which way is “light‑blocking”
}
```

## Rendering Pipeline (Frame-by‑Frame)

1. **Draw background & non‑lighting elements** (terrain, walls, platforms, sprites, etc.).
2. **Draw darkness layer**: fill entire screen with “dark” color.
3. **For each light source:**

   * Compute effective radius & intensity, including flicker.
   * Draw light shape (circle / cone) masking darkness.
   * Implement falloff so brightness decreases with distance.
   * Compute and draw shadow polygons for each wall blocking this light.
4. **Render foreground / player**.
5. **Damage computation**: check if player's position is in lit area above threshold → apply damage.

## Algorithms / Techniques

* **Distance lookup table**: Precompute sqrt‑like table for distances to avoid costly operations per pixel or per scan line.
* **Scanline / line‑by‑line light fill**: Instead of per‑pixel, fill by horizontal lines (or parts of them) for the light area; use symmetry for circles/quadrants.
* **Shadow volumes via wall projection**: Given a wall segment, project a polygon behind it away from the light source, and carve that region out of the light.
* **Dithering / palette tricking**: Use dithered patterns and subtle color variation to reduce visible banding.
* **Flicker / variation**: Vary radius/intensity per frame (with noise / sin waves) to make lights feel alive.

## Performance / Optimization Tips

* Limit number of light sources and shadow casters simultaneously active.
* Use symmetry (draw only quadrant / half, mirror, etc.) for circles.
* Precompute as much as possible: lookup tables for radius → brightness, shadow geometry for static walls.
* Use local variables heavily in loops to reduce overhead.
* Minimize expensive math (sqrt, cos/sin) in per‑pixel or per‑line code; reuse results.
* Possibly degrade detail (less shadow accuracy / fewer steps) when many lights are present.
* Consider toggling lights off / lowering radius when off-screen / far away.

## Sketch of Implementation (pseudo / sample code structure)

```lua
-- global tables
lights = {}
walls = {}
player = { x=..., y=..., w=..., h=..., hp=... }

-- precompute distance → brightness table
brightness_lut = {}
for d=0, max_radius do
  brightness_lut[d] = 1 - (d / max_radius)
end

function draw_light(light)
  local cx, cy, r = light.x, light.y, light.radius
  local rad = r + (light.opts.flicker_amp and rnd(light.opts.flicker_amp) or 0)
  local inten = light.intensity * (1 + (light.opts.flicker_int and (rnd(light.opts.flicker_int)-0.5) or 0))

  for dy = -rad, rad do
    local y = flr(cy + dy)
    if y < 0 or y >= 128 then goto continue end
    local dx_bound = sqrt(rad*rad - dy*dy)
    local x0 = flr(cx - dx_bound)
    local x1 = flr(cx + dx_bound)
    x0 = mid(0, x0, 127)
    x1 = mid(0, x1, 127)
    for x = x0, x1 do
      local d = sqrt((x-cx)*(x-cx) + (y-cy)*(y-cy))
      local b = brightness_lut[flr(d)] * inten
      if b > light_threshold then
        pset(x, y, light_color_for(b))
      end
    end
    ::continue::
  end
end
```

## Damage + Gameplay Integration

* Determine **damage threshold**, i.e. how much brightness / how close to light source the player must be before damage.
* Possibly allow a grace period or “blink” to give player feedback.
* UI feedback: screen flash, color tint, sound, etc.
* Variants:

  * Continuous damage over time.
  * Instant damage if inside bright core.
  * Temporary shields or upgrades to resist light.

## Palette & Visual Style

* Use PICO‑8 palette smartly: dark colors for shadows, mid‑tones for ambient, bright colors for light glow.
* Soft edges for light: use multiple brightness “bands” (colors) and dithering to smooth transitions.
* Ensure contrast so player is visible in dark & light.

## Suggested Roadmap

1. **Prototype basic light circle**
2. **Add damage logic**
3. **Add flicker & soft edges**
4. **Add walls & shadow casters**
5. **Multiple lights & overlapping**
6. **Performance optimization & refinement**
7. **Gameplay polish**


# Designing Good-Feeling Platformer Controls (Inspired by Celeste)

This document distills the key mechanics and implementation details from the PICO-8 *Celeste* source code to guide creation of tight, satisfying platformer controls. Celeste is celebrated for its responsive movement and subtle input handling, and these notes outline how to reproduce those qualities in a new project.

---

## Core Design Goals

* **Responsiveness:** Player actions (jump, dash, wall climb) must feel immediate and predictable.
* **Forgiveness:** Small input windows buffer actions to reduce frustration.
* **Consistency:** Movement physics should be stable across variable frame conditions.
* **Expressiveness:** Advanced players can combine moves fluidly, while new players still find success.

---

## Key Mechanics

### 1. Horizontal Movement

* **Acceleration/Deceleration:**

  * On ground: `accel = 0.6`, `deccel = 0.15` (fast acceleration, mild deceleration).
  * In air: lower acceleration (`0.4`) for floatier control.
  * On ice: much lower acceleration (`0.05`) for slippery feel.
* **Maximum Run Speed:** `maxrun = 1` (pixels per frame). Speed is capped and smoothly approached using `appr()` (approach function).
* **Facing Direction:** Updated when horizontal speed changes sign.

### 2. Gravity & Falling

* **Base Gravity:** `gravity = 0.21` per frame.
* **Variable Gravity:** Reduced when vertical speed is near zero (`abs(spd.y) <= 0.15`) to create a slight “hang time.”
* **Maximum Fall Speed:** `maxfall = 2` normally; reduced to `0.4` during wall slides.

### 3. Jumping

* **Jump Buffering:** `jbuffer = 4` allows a jump input up to 4 frames before landing to still trigger a jump.
* **Coyote Time (Grace Period):** `grace = 6` lets players jump up to 6 frames after leaving the ground.
* **Wall Jumps:** If adjacent to a solid tile and not on ice, player can jump off the wall with added horizontal push (`spd.x = -wall_dir * (maxrun + 1)`).
* **Variable Jump Height:** Holding jump can reduce gravity early, giving a higher arc.

### 4. Dashing

* **Single/Double Dash:** Limited by `djump` (number of dashes remaining). Reset on ground or when hitting refill objects.
* **Dash Physics:**

  * Speed: `d_full = 5` for straight dashes, `d_half = 5 * 0.707` for diagonals.
  * Duration: `dash_time = 4` frames.
  * Acceleration to target handled by `dash_target` and `dash_accel` for smooth approach.
* **Input Handling:** Allows 8-way dashing with combined directional buttons.
* **Feedback:** Screen freeze (`freeze = 2`) and camera shake (`shake = 6`) reinforce impact.

### 5. Wall Slide & Climb

* **Wall Detection:** Checks adjacent tiles for solidity.
* **Slide Behavior:** Reduces `maxfall` to 0.4 and spawns smoke particles for feedback.

### 6. Particles & Animation

* Smoke clouds spawn when landing, jumping, dashing, or wall sliding to convey speed and action.
* Hair color and animation frames reflect dash availability (`set_hair_color(djump)`).

---

## Input Handling Strategies

Celeste uses several small but crucial techniques to make inputs forgiving:

* **Buffered Input:** Jump presses are stored briefly, so near-miss timings still register.
* **Grace Periods:** Ground checks allow a few frames after stepping off a ledge to still jump.
* **Single-Frame Press Detection:** Uses `btn()` vs `btnp()` carefully to detect held vs new presses.
* **Dash Direction Priority:** Combines vertical/horizontal inputs intelligently to pick a dash vector.

---

## Implementation Outline (PICO-8 Lua)

Below is a simplified structure for implementing similar controls:

```lua
player = {
  x=0, y=0,
  spd={x=0,y=0},
  grace=0, jbuffer=0,
  djump=1, dash_time=0,
  update=function(this)
    -- Horizontal input
    local input = btn(k_right) and 1 or (btn(k_left) and -1 or 0)

    -- Ground/ice checks
    local on_ground = this.is_solid(0,1)
    local on_ice = this.is_ice(0,1)

    -- Jump buffer & coyote time
    if btnp(k_jump) then this.jbuffer=4 end
    if on_ground then this.grace=6 end

    -- Horizontal movement
    local accel = on_ground and 0.6 or 0.4
    if on_ice then accel = 0.05 end
    local deccel = 0.15
    this.spd.x = appr(this.spd.x, input*1, accel)

    -- Jumping
    if this.jbuffer>0 then
      if this.grace>0 then
        this.spd.y = -2
        this.jbuffer=0
        this.grace=0
      else
        -- wall jump logic
      end
    end

    -- Gravity & fall
    local maxfall = 2
    local gravity = 0.21
    if abs(this.spd.y) <= 0.15 then gravity *= 0.5 end
    if not on_ground then
      this.spd.y = appr(this.spd.y, maxfall, gravity)
    end

    -- Dash
    if btnp(k_dash) and this.djump>0 then
      -- set dash direction and speed
      this.djump -= 1
      this.dash_time = 4
    end

    -- Movement
    this.move(this.spd.x, this.spd.y)
  end
}
```

Key helper functions:

* `appr(val,target,amount)`: Moves `val` toward `target` by `amount`.
* `is_solid(ox,oy)`: Checks map collisions.
* `btnp()`: Detects button pressed this frame only.

---

## Tuning Tips

* **Small Numbers, Big Feel:** Even small changes to acceleration or gravity drastically change game feel. Tune with playtesting.
* **Visual Feedback:** Use particles and animation to signal states (landing, dashing, wall sliding).
* **Audio Cues:** Jump, dash, and landing sounds reinforce input timing.
* **Grace Frames:** Adjust `jbuffer` and `grace` to balance precision and forgiveness.

---

## Advanced Extensions

* **Double Jump Upgrades:** Increase `max_djump` after key events.
* **Variable Dash Length:** Modify `dash_time` or speed for power-ups.
* **Environmental Variants:** Ice tiles, wind zones, or moving platforms for variety.

---

By combining buffered input, subtle physics tweaks, and strong feedback, you can replicate the "tight but forgiving" controls that make *Celeste* stand out. This foundation ensures a platformer that feels precise for speedrunners and approachable for newcomers alike.

# Tokens in PICO-8

PICO-8 cartridges are limited to a maximum of 8192 tokens. A token is a unit of code counted by the PICO-8 engine, and the token count is often a stricter limit than character count.

## What Counts as a Token?

- Literal values: nil, false, true, numbers (e.g. 123, 0xff.ff, -3, ~1e4), or any string.
- A variable or operator.
- An opening bracket: '(', '[', '{'.
- A keyword (except for `end` and `local`).

## What Does *Not* Count as a Token?

- Comma (,), semicolon (;), period (.), colon (:), and double-colon (::).
- Closing brackets: ')', ']', '}'.
- The keywords `end` and `local`.
- The unary minus (-) and complement (~) operators when applied to a numeric literal.

## Token Saving Tips

- Combine assignments: `a=1 b=2 c=3` → `a,b,c=1,2,3`
- Omit trailing nils: `a,b=nil,nil` → `a,b`
- When calling functions with one argument that is a string or table literal, omit parentheses: `f"hello"` or `f{1,2,3}`
- Use `and`/`or` instead of `if` when possible: `a=f() and x or y`
- Prefer member access over array indexing: `tbl.special` instead of `tbl['special']`
- Use API default arguments: `mid(z,1)` instead of `mid(z,0,1)`
- Use `\` for integer division: `a\10` instead of `flr(a/10)`
- For constant tables, use `split`: `t=split"1,2,3,10,9,8,99,-1"`
- Save tokens by using `next,mytable` instead of `pairs(mytable)`, and `inext,mytable` instead of `ipairs(mytable)`

Efficient token usage is essential for fitting more features and logic into your PICO-8 games.