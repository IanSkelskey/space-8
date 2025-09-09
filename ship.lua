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

-- death
local DEATH_FRAMES = 45 -- ~1.5s at 30fps

-- shield constants
local SHIELD_MAX_POWER = 100
local SHIELD_DRAIN_RATE = 0.5  -- reduced from 2 (4x longer duration)
local SHIELD_RECHARGE_RATE = 1.0  -- increased from 0.5 (2x faster recharge)
local SHIELD_MIN_ACTIVATE = 10  -- minimum power needed to activate
local SHIELD_RADIUS = 10
local SHIELD_COLORS = {12, 13, 1}  -- light blue, lavender, dark blue
local SHIELD_HIT_COST = 15  -- power lost when blocking a hit
local SHIELD_INVULN_FRAMES = 30  -- 1 second of invulnerability after hit

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
	acc = SHIP_ACC,
	-- death state
	dying = false,
	death_t = 0,
	-- shield state
	shield_active = false,
	shield_power = SHIELD_MAX_POWER,
	shield_anim = 0,
	shield_invuln = 0  -- invulnerability timer
}

-- lasers
local bullets = {}

-- exhaust particles
local exhaust = {}

-- death particles
local death_fx = {}

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

local function spawn_death_fx()
	-- burst of colored pixels from ship center
	for i=1,22 do
		local a = rnd(1)
		local sp = 0.7 + rnd(1.3)
		add(death_fx, {
			x=ship.x+ship.w/2, y=ship.y+ship.h/2,
			dx=cos(a)*sp, dy=sin(a)*sp,
			life=flr(10+rnd(20))
		})
	end
end

function ship_kill()
	if ship.dying then return end
	
	-- check for invulnerability first
	if ship.shield_invuln > 0 then
		return  -- still invulnerable, ignore hit
	end
	
	if ship.shield_active then
		-- shield blocks the hit, deplete some power instead
		ship.shield_power = max(0, ship.shield_power - SHIELD_HIT_COST)
		ship.shield_invuln = SHIELD_INVULN_FRAMES  -- start invulnerability
		ship.shield_anim = 0  -- reset animation for flash effect
		sfx(31)  -- shield hit sound (impact)
		if ship.shield_power <= 0 then
			ship.shield_active = false
			sfx(32)  -- shield depletion sound (power down)
		end
		return  -- blocked the damage
	end
	ship.dying = true
	ship.death_t = 0
	-- stop moving and clear exhaust
	ship.vx, ship.vy = 0, 0
	exhaust = {}
	death_fx = {}
	spawn_death_fx()
	-- reuse sfx(1) for death for now
	sfx(1)
	-- move game into dying state
	game_state = "dying"
end

function ship_death_done()
	return ship.dying and ship.death_t >= DEATH_FRAMES
end

function ship_init()
	-- no-op for now (hook for future resets)
	bullets = {}
	exhaust = {}
	death_fx = {}
	-- reset movement
	ship.vx, ship.vy = 0, 0
	ship.dying = false
	ship.death_t = 0
	-- reset shield
	ship.shield_active = false
	ship.shield_power = SHIELD_MAX_POWER
	ship.shield_anim = 0
	ship.shield_invuln = 0
end

local function update_death_fx()
	for p in all(death_fx) do
		p.x += p.dx
		p.y += p.dy
		-- slight drag
		p.dx *= 0.98
		p.dy *= 0.98
		p.life -= 1
		if p.life <= 0 then
			del(death_fx, p)
		end
	end
end

function update_ship()
	-- dying: freeze input, play particles, advance timer, keep bullets flying/culling
	if ship.dying then
		ship.death_t += 1
		update_death_fx()
		-- keep bullets moving/culling
		for b in all(bullets) do
			b.x += b.dx
			b.y += b.dy
			if b.x < OFF_MIN or b.x > OFF_MAX or b.y < OFF_MIN or b.y > OFF_MAX then
				del(bullets, b)
			end
		end
		return
	end

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

	-- clamp to screen (128x128) respecting HUD area, and cancel outward velocity on edges
	local hud_top = HUD_HEIGHT or 0  -- fallback if HUD_HEIGHT not defined
	local minx, maxx = 0, SCREEN_W - ship.w
	local miny, maxy = hud_top, SCREEN_H - ship.h
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
	
	-- update invulnerability timer
	if ship.shield_invuln > 0 then
		ship.shield_invuln -= 1
	end
	
	-- shield logic (button 5 is X)
	if btn(5) and ship.shield_power >= SHIELD_MIN_ACTIVATE and not ship.dying then
		if not ship.shield_active then
			ship.shield_active = true
			sfx(30)  -- shield activation sound
		end
		-- drain shield while active
		ship.shield_power = max(0, ship.shield_power - SHIELD_DRAIN_RATE)
		if ship.shield_power <= 0 then
			ship.shield_active = false
			sfx(32)  -- shield depletion sound (power down)
		end
	else
		if ship.shield_active then
			ship.shield_active = false
			sfx(-1, 0)  -- stop sound on channel 0 (where sfx 30 plays)
		end
		-- recharge shield while inactive (and not invulnerable)
		if ship.shield_power < SHIELD_MAX_POWER and ship.shield_invuln <= 0 then
			ship.shield_power = min(SHIELD_MAX_POWER, ship.shield_power + SHIELD_RECHARGE_RATE)
		end
	end
	
	-- animate shield
	if ship.shield_active then
		ship.shield_anim = (ship.shield_anim + 1) % 30
	end
end

function draw_ship()
	-- draw exhaust behind the ship
	for p in all(exhaust) do
		-- fade colors: yellow(10) -> orange(9) -> red(8)
		local c = p.life > 8 and EXH_COL_Y or (p.life > 4 and EXH_COL_O or EXH_COL_R)
		pset(flr(p.x), flr(p.y), c)
	end

	-- dying: draw explosion particles instead of ship sprite
	if ship.dying then
		for p in all(death_fx) do
			local c = p.life > 16 and 10 or (p.life > 8 and 9 or 8)
			pset(flr(p.x), flr(p.y), c)
		end
	else
		-- ship sprite (lean when moving horizontally)
		local sid, flip = SPR_SHIP, false
		if abs(ship.vx) > FACE_EPS then
			sid = SPR_SHIP_LEAN
			flip = ship.vx > 0 -- lean sprite is left-facing; flip when moving right
		end
		spr(sid, ship.x, ship.y, 1, 1, flip, false)
	end

	-- draw lasers
	for b in all(bullets) do
		rectfill(b.x, b.y, b.x+1, b.y+1, EXH_COL_R)
	end
	
	-- draw shield bubble if active
	if ship.shield_active and not ship.dying then
		local cx = ship.x + ship.w/2
		local cy = ship.y + ship.h/2
		-- animated concentric circles with flash on recent hit
		local t = ship.shield_anim / 30
		
		-- flash white when invulnerable, pulse between visible/invisible
		local visible = true
		local flash = nil
		if ship.shield_invuln > 0 then
			visible = (ship.shield_invuln % 4) < 2  -- blink every 2 frames
			flash = ship.shield_invuln > 25 and 7 or nil  -- white flash for first 5 frames
		end
		
		if visible then
			for i=1,3 do
				local r = SHIELD_RADIUS - i + sin(t + i*0.2)*2
				local c = flash or SHIELD_COLORS[i]
				circ(cx, cy, r, c)
			end
		end
	end
end

-- expose player bullets for other systems (e.g., moon/hud)
function ship_get_bullets()
	return bullets
end

-- check if shield is active (for collision detection)
function ship_has_shield()
	return ship.shield_active
end

-- get shield power for HUD
function ship_get_shield_power()
	return ship.shield_power, SHIELD_MAX_POWER
end

-- allow external forces (e.g., blackholes) to pull exhaust/death particles
function ship_trails_pull(cx,cy,r,strength)
	local r2 = r*r
	local function pull_list(list)
		if not list then return end
		for p in all(list) do
			local dx = cx - p.x
			local dy = cy - p.y
			local d2 = dx*dx + dy*dy
			if d2 > 0.5 and d2 < r2 then
				local invd = 1/sqrt(d2)
				local fall = 1 - d2/r2
				local acc = strength * fall
				p.dx += dx*invd * acc
				p.dy += dy*invd * acc
			end
		end
	end
	pull_list(exhaust)
	if death_fx then pull_list(death_fx) end
end

-- absorb (delete) any exhaust/death particles intersecting a region (e.g., hole core)
function ship_trails_absorb(hx,hy,hw,hh)
	local function absorb_list(list)
		if not list then return end
		for p in all(list) do
			if p.x >= hx and p.x < hx+hw and p.y >= hy and p.y < hy+hh then
				del(list, p)
			end
		end
	end
	absorb_list(exhaust)
	if death_fx then absorb_list(death_fx) end
end
