-- ship state
ship = ship or {
	x = 64-4,
	y = 64-4,
	w = 8,
	h = 8,
	spr = 1,
	spd = 1.5,
	flipx = false
}

-- lasers
local bullets = {}

-- exhaust particles
local exhaust = {}

local function spawn_laser()
	-- fire upward from the ship's nose (top-center)
	local speed = 3
	local bx = flr(ship.x + ship.w/2) - 1
	local by = ship.y - 2
	add(bullets, { x=bx, y=by, dx=0, dy=-speed })
	sfx(0)
end

local function spawn_exhaust(strength)
	-- strength in [0..1], controls spawn probability, life, and speed
	strength = mid(0, strength or 1, 1)
	if strength <= 0 then return end

	local y = ship.y + ship.h
	local x1 = ship.x + 2
	local x2 = ship.x + ship.w - 3

	-- speed/life scale with strength
	local base_dy = 0.5 + 0.9*strength
	local life = flr(6 + 10*strength)

	-- probabilistic spawn per nozzle
	if rnd(1) < strength then
		add(exhaust, { x=x1 + rnd(1)-0.5, y=y, dx=(rnd(0.6)-0.3)*strength, dy=base_dy + rnd(0.4*strength), life=life })
	end
	if rnd(1) < strength then
		add(exhaust, { x=x2 + rnd(1)-0.5, y=y, dx=(rnd(0.6)-0.3)*strength, dy=base_dy + rnd(0.4*strength), life=life })
	end
end

local function update_exhaust()
	for p in all(exhaust) do
		p.x += p.dx
		p.y += p.dy
		p.life -= 1
		if p.life <= 0 or p.y > 132 then
			del(exhaust, p)
		end
	end
end

function ship_init()
	-- no-op for now (hook for future resets)
	bullets = {}
	exhaust = {}
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

	if dx < 0 then ship.flipx = true end
	if dx > 0 then ship.flipx = false end

	ship.x += dx * ship.spd
	ship.y += dy * ship.spd

	ship.x = mid(0, ship.x, 128 - ship.w)
	ship.y = mid(0, ship.y, 128 - ship.h)

	-- exhaust strength rules (shorter trail when moving up)
	local strength = 0.6 -- horizontal/diagonal
	if raw_dx == 0 and raw_dy == 0 then
		strength = 0.2
	elseif raw_dy > 0 then
		strength = 0.03
	elseif raw_dy < 0 then
		strength = 0.45
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
		if b.x < -4 or b.x > 132 or b.y < -4 or b.y > 132 then
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
		local c = p.life > 8 and 10 or (p.life > 4 and 9 or 8)
		pset(flr(p.x), flr(p.y), c)
	end

	-- ship sprite
	spr(ship.spr, ship.x, ship.y, 1, 1, ship.flipx, false)

	-- draw lasers
	for b in all(bullets) do
		rectfill(b.x, b.y, b.x+1, b.y+1, 8)
	end
end

-- expose player bullets for other systems (e.g., moon/hud)
function ship_get_bullets()
	return bullets
end
