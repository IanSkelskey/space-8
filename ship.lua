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

local function spawn_laser()
	-- fire upward from the ship's nose (top-center)
	local speed = 3
	local bx = flr(ship.x + ship.w/2) - 1
	local by = ship.y - 2
	add(bullets, { x=bx, y=by, dx=0, dy=-speed })
	sfx(0)
end

function ship_init()
	-- no-op for now (hook for future resets)
	bullets = {}
end

function update_ship()
	local dx, dy = 0, 0
	if btn(0) then dx -= 1 end
	if btn(1) then dx += 1 end
	if btn(2) then dy -= 1 end
	if btn(3) then dy += 1 end

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
end

function draw_ship()
	spr(ship.spr, ship.x, ship.y, 1, 1, ship.flipx, false)
	-- draw lasers
	for b in all(bullets) do
		rectfill(b.x, b.y, b.x+1, b.y+1, 8)
	end
end
