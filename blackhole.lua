-- blackhole obstacle

local holes = {}
local spawn_t = 0

-- simple aabb
local function aabb(ax,ay,aw,ah,bx,by,bw,bh)
	return ax < bx+bw and bx < ax+aw and ay < by+bh and by < ay+ah
end

-- inward purple particles
local parts = {}

-- get player bullets from ship.lua
local function get_player_bullets()
	if ship_get_bullets then return ship_get_bullets() end
	return nil
end

-- pull and redirect bullets toward the hole center
local function pull_bullets(h)
	local pb = get_player_bullets()
	if not pb then return end
	local cx, cy = h.x+4, h.y+4
	local r2 = h.r*h.r
	for b in all(pb) do
		-- absorb bullets that hit the hole core
		if aabb(b.x,b.y,2,2, h.x,h.y,h.w,h.h) then
			del(pb,b)
		else
			-- assume bullets have x,y,dx,dy
			local dx = cx - b.x
			local dy = cy - b.y
			local d2 = dx*dx + dy*dy
			if d2 > 0.25 and d2 < r2 then
				local invd = 1/sqrt(d2)
				local fall = 1 - d2/r2
				-- small accel toward center; stronger near the hole
				local acc = 0.25 * fall
				b.dx += dx*invd * acc
				b.dy += dy*invd * acc
				-- cap bullet speed to keep behavior stable
				local sp = sqrt(b.dx*b.dx + b.dy*b.dy)
				local maxsp = 4.0
				if sp > maxsp then
					local s = maxsp/sp
					b.dx *= s
					b.dy *= s
				end
			end
		end
	end
end

local function spawn_hole()
	add(holes, {
		x = flr(rnd(128-8)),
		y = -10,
		w = 8, h = 8,
		spd = 0.8,     -- scroll with near-ish layer
		r = 50         -- was 36; larger influence radius
	})
end

local function spawn_particles(h)
	-- spawn slightly fewer particles: always 1, 50% chance of a second
	local count = 1 + (rnd(1) < 0.5 and 1 or 0)
	for i=1,count do
		local ang = rnd(1)*2*0.785
		local rad = 6 + rnd(4)
		local px = h.x + 4 + cos(ang)*rad
		local py = h.y + 4 + sin(ang)*rad
		local vx = (rnd(0.4)-0.2)
		local vy = (rnd(0.4)-0.2)
		add(parts, { x=px, y=py, vx=vx, vy=vy, life=20 + flr(rnd(10)) })
	end
end

local function update_particles()
	for p in all(parts) do
		-- pull toward nearest hole center
		local cx, cy, bestd2
		for h in all(holes) do
			local hx, hy = h.x+4, h.y+4
			local dx, dy = hx-p.x, hy-p.y
			local d2 = dx*dx + dy*dy
			if not bestd2 or d2 < bestd2 then
				bestd2 = d2
				cx, cy = hx, hy
			end
		end
		if cx then
			local dx, dy = cx-p.x, cy-p.y
			local d2 = dx*dx + dy*dy
			if d2 > 0.1 then
				local invd = 1/sqrt(d2)
				local pull = 1.2 -- was 0.7
				p.vx += dx*invd * pull * 0.8 -- was *0.5
				p.vy += dy*invd * pull * 0.8
			end
		end

		-- integrate and decay
		p.x += p.vx
		p.y += p.vy
		p.life -= 1
		if p.life <= 0 then del(parts, p) end
	end
end

function blackhole_init()
	holes = {}
	parts = {}
	spawn_t = 0
end

function update_blackhole()
	-- spawn cadence: occasionally, keep small count
	spawn_t -= 1/30
	if spawn_t <= 0 and #holes < 2 then
		spawn_hole()
		spawn_t = 3 + rnd(3)
	end

	for h in all(holes) do
		-- scroll
		h.y += h.spd

		-- apply pull to stars (slightly reduced earlier)
		if starfield_pull then
			starfield_pull(h.x+4, h.y+4, h.r, 0.10, 0.20)
		end

		-- pull moon debris toward the center (moderate strength)
		if moon_debris_pull then
			moon_debris_pull(h.x+4, h.y+4, h.r, 0.35)
		end

		-- pull player if close (stronger)
		if ship then
			local cx, cy = h.x+4, h.y+4
			local dx, dy = cx-ship.x-ship.w/2, cy-ship.y-ship.h/2
			local d2 = dx*dx + dy*dy
			local r2 = h.r*h.r
			if d2 < r2 and d2 > 0 then
				local invd = 1/sqrt(d2)
				local strength = 0.6 * (1 - d2/r2) -- was 0.35
				-- nudge position toward center
				ship.x += dx*invd * strength
				ship.y += dy*invd * strength
				-- clamp to screen
				if ship.x < 0 then ship.x=0 end
				if ship.x > 128-ship.w then ship.x=128-ship.w end
				if ship.y < 0 then ship.y=0 end
				if ship.y > 128-ship.h then ship.y=128-ship.h end
			end
		end

		-- collide with player -> reset
		if ship and aabb(h.x,h.y,h.w,h.h, ship.x,ship.y,ship.w,ship.h) then
			if reset_game then reset_game() end
			return
		end

		-- cull if offscreen
		if h.y > 136 then del(holes, h) end

		-- remove moons that intersect the hole
		if moon_absorb then
			moon_absorb(h.x,h.y,h.w,h.h)
		end

		-- particles around this hole
		spawn_particles(h)

		-- pull and redirect player bullets (and absorb on contact)
		pull_bullets(h)
	end

	update_particles()
end

function draw_blackhole()
	-- draw particles (purple hues) behind the hole
	for p in all(parts) do
		local c = p.life > 16 and 13 or (p.life > 8 and 2 or 1)
		pset(flr(p.x), flr(p.y), c)
	end
	-- draw holes
	for h in all(holes) do
		spr(3, h.x, h.y)
	end
end
