-- blackhole obstacle

local holes = {}
local spawn_t = 0

-- simple aabb
local function aabb(ax,ay,aw,ah,bx,by,bw,bh)
	return ax < bx+bw and bx < ax+aw and ay < by+bh and by < ay+ah
end

-- inward purple particles
local parts = {}
-- gentle fallback behavior when no hole influences a particle
local ORPHAN_DAMP  = 0.65   -- was 0.85 (stronger damping)
local ORPHAN_DRIFT = 0.20   -- was 0.5 (subtler drift)
local PARTICLE_MAXSPD = 1.8 -- was 1.4, allow a bit more swirl speed
local ORPHAN_MAXSPD  = 0.6  -- cap when orphaned
local SPIN_STEP = 8         -- frames per 90° step (slower spin)

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
		spd = 0.8,
		r = 50,
		spin_t = 0 -- add spin timer
	})
end

local function spawn_particles(h)
	-- spawn slightly fewer particles: always 1, 50% chance of a second
	local count = 1 + (rnd(1) < 0.5 and 1 or 0)
	for i=1,count do
		-- use pico-8 "turns" (0..1) for angle to keep spawn truly circular
		local ang = rnd(1)
		-- start close to the core
		local rad = 2 + rnd(2)
		local px = h.x + 4 + cos(ang)*rad
		local py = h.y + 4 + sin(ang)*rad
		-- give initial tangential velocity for spiral (stronger than before)
		local tx, ty = -sin(ang), cos(ang)
		local speed = 0.45 + rnd(0.45)
		local vx = tx*speed + (rnd(0.2)-0.1)
		local vy = ty*speed + (rnd(0.2)-0.1)
		-- tiny outward kick to prevent immediate collapse
		vx += cos(ang)*0.08
		vy += sin(ang)*0.08
		add(parts, { x=px, y=py, vx=vx, vy=vy, life=20 + flr(rnd(10)) })
	end
end

local function update_particles()
	for p in all(parts) do
		-- pull toward nearest hole center
		local cx, cy, bestd2, hh
		for h in all(holes) do
			local hx, hy = h.x+4, h.y+4
			local dx, dy = hx-p.x, hy-p.y
			local d2 = dx*dx + dy*dy
			if not bestd2 or d2 < bestd2 then
				bestd2 = d2
				cx, cy = hx, hy
				hh = h
			end
		end
		if cx then
			local dx, dy = cx-p.x, cy-p.y
			local d2 = dx*dx + dy*dy
			if d2 > 0.1 then
				local invd = 1/sqrt(d2)
				local r = (hh and hh.r) or 32
				local d = sqrt(d2)
				local fall = 1 - min(d/r, 1)
				-- bias toward tangential swirl; keep radial modest so particles orbit
				local radial_gain = 0.30 * fall
				local swirl_gain  = 0.80 * max(fall, 0.20)

				-- radial pull
				p.vx += dx*invd * radial_gain
				p.vy += dy*invd * radial_gain

				-- tangential swirl (perpendicular to radial)
				local tx, ty = -dy*invd, dx*invd
				p.vx += tx * swirl_gain
				p.vy += ty * swirl_gain

				-- gentle outward bias if too close to core to avoid clustering
				if d < 2.2 then
					p.vx -= dx*invd * 0.20
					p.vy -= dy*invd * 0.20
				end

				-- clamp speed under influence
				local sp = sqrt(p.vx*p.vx + p.vy*p.vy)
				if sp > PARTICLE_MAXSPD then
					local s = PARTICLE_MAXSPD/sp
					p.vx *= s
					p.vy *= s
				end
			end
		else
			-- no active hole nearby: damp velocity, cap speed, and gently drift down
			p.vx *= ORPHAN_DAMP
			p.vy *= ORPHAN_DAMP
			local sp = sqrt(p.vx*p.vx + p.vy*p.vy)
			if sp > ORPHAN_MAXSPD then
				local s = ORPHAN_MAXSPD/sp
				p.vx *= s
				p.vy *= s
			end
			p.vy += ORPHAN_DRIFT
			if abs(p.vx) < 0.01 then p.vx = 0 end
			if abs(p.vy) < 0.01 then p.vy = 0 end
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
		-- advance spin (wrap every 4 phases)
		h.spin_t = (h.spin_t + 1) % (SPIN_STEP*4)

		-- apply pull to stars (slightly reduced earlier)
		if starfield_pull then
			starfield_pull(h.x+4, h.y+4, h.r, 0.10, 0.20)
		end

		-- pull moon debris toward the center (moderate strength)
		if moon_debris_pull then
			moon_debris_pull(h.x+4, h.y+4, h.r, 0.35)
		end

		-- pull ship trails (exhaust and death particles)
		if ship_trails_pull then
			ship_trails_pull(h.x+4, h.y+4, h.r, 0.22)
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

		-- collide with player -> start death animation
		if ship and aabb(h.x,h.y,h.w,h.h, ship.x,ship.y,ship.w,ship.h) then
			if game_state == "game" and ship_kill then
				ship_kill()
				return
			end
			-- while dying/gameover, don't exit early; keep updating particles
		end

		-- cull if offscreen
		if h.y > 136 then del(holes, h) end

		-- remove moons that intersect the hole
		if moon_absorb then
			moon_absorb(h.x,h.y,h.w,h.h)
		end

		-- absorb ship trails that touch the core
		if ship_trails_absorb then
			ship_trails_absorb(h.x,h.y,h.w,h.h)
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
		-- pink for brightest, then medium/dark purple
		local c = p.life > 16 and 14 or (p.life > 8 and 2 or 1)
		pset(flr(p.x), flr(p.y), c)
	end
	-- draw holes (flip-based 0/90/180/270 "rotation")
	for h in all(holes) do
		local phase = flr(h.spin_t / SPIN_STEP) % 4
		-- sequence: 0: no flip, 1: flip x, 2: flip x+y, 3: flip y
		local fx = (phase == 1) or (phase == 2)
		local fy = (phase == 2) or (phase == 3)
		spr(3, h.x, h.y, 1, 1, fx, fy)
	end
end
