-- constants
local SCREEN_W, SCREEN_H = 128, 128
local SHIP_W, SHIP_H = 8, 8
local SPR_SHIP = 1
local SPR_SHIP_LEAN = 4
local SHIP_SPEED = 2.0
local SHIP_ACC = 0.12
local START_X = SCREEN_W/2 - SHIP_W/2
local START_Y = SCREEN_H/2 - SHIP_H/2

local LASER_SPEED = 3
local LASER_SFX = 0
local OFF_MIN, OFF_MAX = -4, 132
local FACE_EPS = 0.05

-- exhaust tuning
local EXH_NOZZLE_L, EXH_NOZZLE_R = 2, 3
local EXH_BASE_DY, EXH_DY_SCALE = 0.5, 0.9
local EXH_LIFE_MIN, EXH_LIFE_RANGE = 6, 10
local EXH_X_JITTER, EXH_DX_JITTER, EXH_DX_RANGE = 1, 0.6, 0.3
local EXH_DY_RAND_SCALE = 0.4
local EXH_COL_Y, EXH_COL_O, EXH_COL_R = 10, 9, 8

-- exhaust strength presets
local STRENGTH_HORIZ = 0.6
local STRENGTH_IDLE  = 0.2
local STRENGTH_DOWN  = 0.03
local STRENGTH_UP    = 0.45

-- ship state
ship = ship or {
	x = START_X,
	y = START_Y,
	w = SHIP_W,
	h = SHIP_H,
	spr = 1,
	spd = SHIP_SPEED,
	flipx = false,
	vx = 0, vy = 0,
	acc = SHIP_ACC
}

-- lasers
local bullets = {}

-- exhaust particles
local exhaust = {}

local function spawn_laser()
	-- fire upward from the ship's nose (top-center)
	local speed = LASER_SPEED
	local bx = flr(ship.x + ship.w/2) - 1
	local by = ship.y - 2
	add(bullets, { x=bx, y=by, dx=0, dy=-speed })
	sfx(LASER_SFX)
end

local function spawn_exhaust(strength)
	-- strength in [0..1], controls spawn probability, life, and speed
	strength = mid(0, strength or 1, 1)
	if strength <= 0 then return end

	local y = ship.y + ship.h
	local x1 = ship.x + EXH_NOZZLE_L
	local x2 = ship.x + ship.w - EXH_NOZZLE_R

	-- speed/life scale with strength
	local base_dy = EXH_BASE_DY + EXH_DY_SCALE*strength
	local life = flr(EXH_LIFE_MIN + EXH_LIFE_RANGE*strength)

	-- probabilistic spawn per nozzle
	if rnd(1) < strength then
		add(exhaust, {
			x = x1 + rnd(EXH_X_JITTER) - 0.5,
			y = y,
			dx = (rnd(EXH_DX_JITTER) - EXH_DX_RANGE) * strength,
			dy = base_dy + rnd(EXH_DY_RAND_SCALE*strength),
			life = life
		})
	end
	if rnd(1) < strength then
		add(exhaust, {
			x = x2 + rnd(EXH_X_JITTER) - 0.5,
			y = y,
			dx = (rnd(EXH_DX_JITTER) - EXH_DX_RANGE) * strength,
			dy = base_dy + rnd(EXH_DY_RAND_SCALE*strength),
			life = life
		})
	end
end

local function update_exhaust()
	for p in all(exhaust) do
		p.x += p.dx
		p.y += p.dy
		p.life -= 1
		if p.life <= 0 or p.y > OFF_MAX then
			del(exhaust, p)
		end
	end
end

function ship_init()
	-- no-op for now (hook for future resets)
	bullets = {}
	exhaust = {}
	-- reset movement
	ship.vx, ship.vy = 0, 0
end

function update_ship()
	local dx, dy = 0, 0
	if btn(0) then dx -= 1 end
	if btn(1) then dx += 1 end
	if btn(2) then dy -= 1 end
	if btn(3) then dy += 1 end

	-- remember raw input for exhaust logic
	local raw_dx, raw_dy = dx, dy

	-- normalize input to prevent faster diagonal movement
	local mag = sqrt(dx*dx + dy*dy)
	if mag > 0 then
		dx /= mag
		dy /= mag
	end

	-- face by actual motion when possible (fallback to input)
	if ship.vx < -FACE_EPS or (ship.vx == 0 and dx < 0) then ship.flipx = true end
	if ship.vx >  FACE_EPS or (ship.vx == 0 and dx > 0) then ship.flipx = false end

	-- target velocity from input
	local tx = dx * ship.spd
	local ty = dy * ship.spd

	-- accelerate toward target velocity (subtle accel/decel)
	ship.vx += mid(-ship.acc, tx - ship.vx, ship.acc)
	ship.vy += mid(-ship.acc, ty - ship.vy, ship.acc)

	-- integrate position
	ship.x += ship.vx
	ship.y += ship.vy

	-- clamp to screen (128x128) and cancel outward velocity on edges
	local minx, maxx = 0, SCREEN_W - ship.w
	local miny, maxy = 0, SCREEN_H - ship.h
	if ship.x < minx then ship.x=minx if ship.vx<0 then ship.vx=0 end end
	if ship.x > maxx then ship.x=maxx if ship.vx>0 then ship.vx=0 end end
	if ship.y < miny then ship.y=miny if ship.vy<0 then ship.vy=0 end end
	if ship.y > maxy then ship.y=maxy if ship.vy>0 then ship.vy=0 end end

	-- exhaust strength rules (shorter trail when moving up)
	local strength = STRENGTH_HORIZ
	if raw_dx == 0 and raw_dy == 0 then
		strength = STRENGTH_IDLE
	elseif raw_dy > 0 then
		strength = STRENGTH_DOWN
	elseif raw_dy < 0 then
		strength = STRENGTH_UP
	end
	spawn_exhaust(strength)

	-- fire on spacebar press (btnp(4))
	if btnp(4) then
		spawn_laser()
	end

	-- update lasers and cull offscreen
	for b in all(bullets) do
		b.x += b.dx
		b.y += b.dy
		if b.x < OFF_MIN or b.x > OFF_MAX or b.y < OFF_MIN or b.y > OFF_MAX then
			del(bullets, b)
		end
	end

	-- update exhaust
	update_exhaust()
end

function draw_ship()
	-- draw exhaust behind the ship
	for p in all(exhaust) do
		-- fade colors: yellow(10) -> orange(9) -> red(8)
		local c = p.life > 8 and EXH_COL_Y or (p.life > 4 and EXH_COL_O or EXH_COL_R)
		pset(flr(p.x), flr(p.y), c)
	end

	-- ship sprite (lean when moving horizontally)
	local sid, flip = SPR_SHIP, false
	if abs(ship.vx) > FACE_EPS then
		sid = SPR_SHIP_LEAN
		flip = ship.vx > 0 -- lean sprite is left-facing; flip when moving right
	end
	spr(sid, ship.x, ship.y, 1, 1, flip, false)

	-- draw lasers
	for b in all(bullets) do
		rectfill(b.x, b.y, b.x+1, b.y+1, EXH_COL_R)
	end
end

-- expose player bullets for other systems (e.g., moon/hud)
function ship_get_bullets()
	return bullets
end
