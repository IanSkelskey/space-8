-- blackhole obstacle

-- blackhole properties
local HOLE_WIDTH = 8
local HOLE_HEIGHT = 8
local HOLE_HALF_WIDTH = 4
local HOLE_HALF_HEIGHT = 4
local HOLE_SPEED = 0.8
local HOLE_RADIUS = 50
local HOLE_MAX_COUNT = 2
local HOLE_SPRITE = 3

-- spawn timing
local SPAWN_BASE_INTERVAL = 3
local SPAWN_RANDOM_INTERVAL = 3
local SPAWN_TIME_DECREMENT = 1/30

-- particle system
local ORPHAN_DAMP  = 0.65   -- was 0.85 (stronger damping)
local ORPHAN_DRIFT = 0.20   -- was 0.5 (subtler drift)
local PARTICLE_MAXSPD = 1.8 -- was 1.4, allow a bit more swirl speed
local ORPHAN_MAXSPD  = 0.6  -- cap when orphaned
local SPIN_STEP = 8         -- frames per 90° step (slower spin)

-- particle spawning
local PARTICLE_BASE_COUNT = 1
local PARTICLE_EXTRA_CHANCE = 0.5
local PARTICLE_MIN_RADIUS = 2
local PARTICLE_RADIUS_VAR = 2
local PARTICLE_BASE_SPEED = 0.45
local PARTICLE_SPEED_VAR = 0.45
local PARTICLE_RANDOM_VAR = 0.2
local PARTICLE_OUTWARD_KICK = 0.08
local PARTICLE_BASE_LIFE = 20
local PARTICLE_LIFE_VAR = 10

-- particle physics
local MIN_SQUARED_DIST = 0.1
local RADIAL_GAIN_FACTOR = 0.30
local SWIRL_GAIN_FACTOR = 0.80
local MIN_SWIRL_FACTOR = 0.20
local CORE_PROXIMITY_THRESHOLD = 2.2
local OUTWARD_BIAS = 0.20
local VELOCITY_ZERO_THRESHOLD = 0.01

-- pull strengths
local STAR_PULL_STRENGTH = 0.10
local STAR_PULL_SWIRL = 0.20
local MOON_DEBRIS_PULL = 0.35
local SHIP_TRAILS_PULL = 0.22
local SHIP_PULL_STRENGTH = 0.6

-- screen dimensions
local SCREEN_WIDTH = 128
local SCREEN_HEIGHT = 128
local OFFSCREEN_Y = 136

-- particle colors
local BRIGHT_PARTICLE_THRESHOLD = 16
local DIM_PARTICLE_THRESHOLD = 8
local BRIGHT_PARTICLE_COLOR = 14  -- pink
local MID_PARTICLE_COLOR = 2      -- medium purple
local DIM_PARTICLE_COLOR = 1      -- dark purple

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
	local cx, cy = h.x+HOLE_HALF_WIDTH, h.y+HOLE_HALF_HEIGHT
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
			if d2 > MIN_SQUARED_DIST and d2 < r2 then
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
	local hud_top = HUD_HEIGHT or 0
	add(holes, {
		x = flr(rnd(SCREEN_WIDTH-HOLE_WIDTH)),
		y = hud_top - 10,  -- spawn above HUD area
		w = HOLE_WIDTH, h = HOLE_HEIGHT,
		spd = HOLE_SPEED,
		r = HOLE_RADIUS,
		spin_t = 0 -- add spin timer
	})
end

local function spawn_particles(h)
	-- spawn slightly fewer particles: always 1, 50% chance of a second
	local count = PARTICLE_BASE_COUNT + (rnd(1) < PARTICLE_EXTRA_CHANCE and 1 or 0)
	for i=1,count do
		-- use pico-8 "turns" (0..1) for angle to keep spawn truly circular
		local ang = rnd(1)
		-- start close to the core
		local rad = PARTICLE_MIN_RADIUS + rnd(PARTICLE_RADIUS_VAR)
		local px = h.x + HOLE_HALF_WIDTH + cos(ang)*rad
		local py = h.y + HOLE_HALF_HEIGHT + sin(ang)*rad
		-- give initial tangential velocity for spiral (stronger than before)
		local tx, ty = -sin(ang), cos(ang)
		local speed = PARTICLE_BASE_SPEED + rnd(PARTICLE_SPEED_VAR)
		local vx = tx*speed + (rnd(PARTICLE_RANDOM_VAR)-PARTICLE_RANDOM_VAR/2)
		local vy = ty*speed + (rnd(PARTICLE_RANDOM_VAR)-PARTICLE_RANDOM_VAR/2)
		-- tiny outward kick to prevent immediate collapse
		vx += cos(ang)*PARTICLE_OUTWARD_KICK
		vy += sin(ang)*PARTICLE_OUTWARD_KICK
		add(parts, { x=px, y=py, vx=vx, vy=vy, life=PARTICLE_BASE_LIFE + flr(rnd(PARTICLE_LIFE_VAR)) })
	end
end

local function update_particles()
	for p in all(parts) do
		-- pull toward nearest hole center
		local cx, cy, bestd2, hh
		for h in all(holes) do
			local hx, hy = h.x+HOLE_HALF_WIDTH, h.y+HOLE_HALF_HEIGHT
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
			if d2 > MIN_SQUARED_DIST then
				local invd = 1/sqrt(d2)
				local r = (hh and hh.r) or 32
				local d = sqrt(d2)
				local fall = 1 - min(d/r, 1)
				-- bias toward tangential swirl; keep radial modest so particles orbit
				local radial_gain = RADIAL_GAIN_FACTOR * fall
				local swirl_gain  = SWIRL_GAIN_FACTOR * max(fall, MIN_SWIRL_FACTOR)

				-- radial pull
				p.vx += dx*invd * radial_gain
				p.vy += dy*invd * radial_gain

				-- tangential swirl (perpendicular to radial)
				local tx, ty = -dy*invd, dx*invd
				p.vx += tx * swirl_gain
				p.vy += ty * swirl_gain

				-- gentle outward bias if too close to core to avoid clustering
				if d < CORE_PROXIMITY_THRESHOLD then
					p.vx -= dx*invd * OUTWARD_BIAS
					p.vy -= dy*invd * OUTWARD_BIAS
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
			if abs(p.vx) < VELOCITY_ZERO_THRESHOLD then p.vx = 0 end
			if abs(p.vy) < VELOCITY_ZERO_THRESHOLD then p.vy = 0 end
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
	spawn_t -= SPAWN_TIME_DECREMENT
	if spawn_t <= 0 and #holes < HOLE_MAX_COUNT then
		spawn_hole()
		spawn_t = SPAWN_BASE_INTERVAL + rnd(SPAWN_RANDOM_INTERVAL)
	end

	for h in all(holes) do
		-- scroll
		h.y += h.spd
		-- advance spin (wrap every 4 phases)
		h.spin_t = (h.spin_t + 1) % (SPIN_STEP*4)

		-- apply pull to stars (slightly reduced earlier)
		if starfield_pull then
			starfield_pull(h.x+HOLE_HALF_WIDTH, h.y+HOLE_HALF_HEIGHT, h.r, STAR_PULL_STRENGTH, STAR_PULL_SWIRL)
		end

		-- pull moon debris toward the center (moderate strength)
		if moon_debris_pull then
			moon_debris_pull(h.x+HOLE_HALF_WIDTH, h.y+HOLE_HALF_HEIGHT, h.r, MOON_DEBRIS_PULL)
		end

		-- pull ship trails (exhaust and death particles)
		if ship_trails_pull then
			ship_trails_pull(h.x+HOLE_HALF_WIDTH, h.y+HOLE_HALF_HEIGHT, h.r, SHIP_TRAILS_PULL)
		end

		-- pull player if close (stronger)
		if ship then
			local cx, cy = h.x+HOLE_HALF_WIDTH, h.y+HOLE_HALF_HEIGHT
			local dx, dy = cx-ship.x-ship.w/2, cy-ship.y-ship.h/2
			local d2 = dx*dx + dy*dy
			local r2 = h.r*h.r
			if d2 < r2 and d2 > 0 then
				local invd = 1/sqrt(d2)
				local strength = SHIP_PULL_STRENGTH * (1 - d2/r2) -- was 0.35
				-- nudge position toward center
				ship.x += dx*invd * strength
				ship.y += dy*invd * strength
				-- clamp to screen
				if ship.x < 0 then ship.x=0 end
				if ship.x > SCREEN_WIDTH-ship.w then ship.x=SCREEN_WIDTH-ship.w end
				if ship.y < 0 then ship.y=0 end
				if ship.y > SCREEN_HEIGHT-ship.h then ship.y=SCREEN_HEIGHT-ship.h end
			end
		end

		-- check collision with player
		if ship and aabb(h.x,h.y,h.w,h.h, ship.x,ship.y,ship.w,ship.h) then
			if ship_kill then ship_kill() end  -- ship_kill now handles shield check internally
		end

		-- cull if offscreen
		if h.y > OFFSCREEN_Y then del(holes, h) end

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
		local c = p.life > BRIGHT_PARTICLE_THRESHOLD and BRIGHT_PARTICLE_COLOR or 
		         (p.life > DIM_PARTICLE_THRESHOLD and MID_PARTICLE_COLOR or DIM_PARTICLE_COLOR)
		pset(flr(p.x), flr(p.y), c)
	end
	-- draw holes (flip-based 0/90/180/270 "rotation")
	for h in all(holes) do
		local phase = flr(h.spin_t / SPIN_STEP) % 4
		-- sequence: 0: no flip, 1: flip x, 2: flip x+y, 3: flip y
		local fx = (phase == 1) or (phase == 2)
		local fy = (phase == 2) or (phase == 3)
		spr(HOLE_SPRITE, h.x, h.y, 1, 1, fx, fy)
	end
end