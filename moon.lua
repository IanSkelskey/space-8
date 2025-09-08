-- moon obstacle

local moons = {}
local spawn_t = 0.0

-- simple aabb overlap
local function aabb(ax,ay,aw,ah,bx,by,bw,bh)
	return ax < bx+bw and bx < ax+aw and ay < by+bh and by < ay+ah
end

-- bullets helper (from ship.lua)
local function player_bullets()
	if ship_get_bullets then return ship_get_bullets() end
	return nil
end

local function hit_by_player_bullet(x,y,w,h)
	local pb = player_bullets()
	if not pb then return false end
	for b in all(pb) do
		if aabb(x,y,w,h, b.x,b.y,2,2) then
			del(pb,b)
			return true
		end
	end
	return false
end

-- debris from destroyed moons (4x4 shards from sprite 5)
local debris = {}
local SPR_MOON = 2
local SPR_SHARDS = 5
local SHARDS_SX = (SPR_SHARDS%16)*8
local SHARDS_SY = flr(SPR_SHARDS/16)*8

-- scoring
local MOON_SCORE  = 100
local CHUNK_SCORE = 20

-- harmless dust pixels
local dust = {}

-- small dust burst for chunk death
local function spawn_chunk_dust(x,y)
	-- 3-5 short-lived pixels
	local n = 3 + flr(rnd(3))
	for i=1,n do
		local ang = rnd(1)
		local sp = 0.6 + rnd(0.6)
		add(dust, { x=x, y=y, dx=cos(ang)*sp, dy=sin(ang)*sp, life=8+flr(rnd(6)) })
	end
end

local function spawn_moon_debris(x,y)
	-- 4 quadrants: tl,tr,bl,br (4x4 each)
	local quads = {
		{ sx=SHARDS_SX+0, sy=SHARDS_SY+0, ox=0, oy=0 },
		{ sx=SHARDS_SX+4, sy=SHARDS_SY+0, ox=4, oy=0 },
		{ sx=SHARDS_SX+0, sy=SHARDS_SY+4, ox=0, oy=4 },
		{ sx=SHARDS_SX+4, sy=SHARDS_SY+4, ox=4, oy=4 }
	}
	for q in all(quads) do
		local a = rnd(1)
		local sp = 0.5 + rnd(1.2)
		add(debris, {
			x = x + q.ox, y = y + q.oy,
			dx = cos(a)*sp, dy = sin(a)*sp,
			sx = q.sx, sy = q.sy
		})
	end
	-- spawn 8 single-pixel dust particles (no damage)
	for i=1,8 do
		local ang = rnd(1)
		local sp = rnd(1.2)
		add(dust, { x=x+4, y=y+4, dx=cos(ang)*sp, dy=sin(ang)*sp, life=18 })
	end
end

function moon_init()
	moons = {}
	spawn_t = 0
	debris = {}
	dust = {}
end

local function spawn_moon()
	-- scroll speed close to near star layer
	local spd = 0.9
	add(moons, {
		x = flr(rnd(128-8)),
		y = -10,
		w = 8, h = 8,
		spd = spd,
		hp = 1
	})
end

function update_moon()
	-- spawn cadence (~ every 1.5-3s)
	spawn_t -= 1/30
	if spawn_t <= 0 and #moons < 3 then
		spawn_moon()
		spawn_t = 1.5 + rnd(1.5)
	end

	-- update + collisions
	for m in all(moons) do
		m.y += m.spd

		-- bullet hit destroys the moon
		if hit_by_player_bullet(m.x,m.y,m.w,m.h) then
			m.hp -= 1
			if m.hp <= 0 then
				if hud_add_score then hud_add_score(MOON_SCORE) end
				sfx(1)
				spawn_moon_debris(m.x, m.y)
				del(moons, m)
				goto continue
			end
		end

		-- player collision -> start death
		if ship and aabb(m.x,m.y,m.w,m.h, ship.x,ship.y,ship.w,ship.h) then
			if game_state == "game" and ship_kill then ship_kill() end
			return
		end

		-- cull
		if m.y > 136 then del(moons, m) end
		::continue::
	end

	-- update debris (no timeout, but cull offscreen)
	for d in all(debris) do
		d.x += d.dx
		d.y += d.dy
		-- gentle drag
		d.dx *= 0.99
		d.dy *= 0.99

		-- allow player bullets to destroy shards (4x4 aabb)
		if hit_by_player_bullet(d.x, d.y, 4, 4) then
			if hud_add_score then hud_add_score(CHUNK_SCORE) end
			spawn_chunk_dust(d.x+2, d.y+2)
			del(debris, d)
		else
			-- collide debris with player -> start death
			if ship and aabb(d.x,d.y,4,4, ship.x,ship.y,ship.w,ship.h) then
				if game_state == "game" and ship_kill then ship_kill() end
				return
			end
			-- cull if offscreen
			if d.x < -4 or d.x > 132 or d.y < -4 or d.y > 132 then
				del(debris, d)
			end
		end
	end

	-- update harmless dust particles (fade and remove)
	for p in all(dust) do
		p.x += p.dx
		p.y += p.dy
		p.life -= 1
		if p.life <= 0 or p.x < -2 or p.x > 130 or p.y < -2 or p.y > 130 then
			del(dust, p)
		end
	end
end

function draw_moon()
	for m in all(moons) do
		spr(SPR_MOON, m.x, m.y)
	end
	-- draw debris shards
	for d in all(debris) do
		sspr(d.sx, d.sy, 4, 4, d.x, d.y)
	end
	-- draw dust pixels (light gray/white fade)
	for p in all(dust) do
		local c = p.life > 12 and 6 or (p.life > 6 and 5 or 7)
		pset(flr(p.x), flr(p.y), c)
	end
end

function moon_absorb(hx,hy,hw,hh)
	-- delete any moons intersecting [hx,hy,hw,hh]
	for m in all(moons) do
		if aabb(m.x,m.y,m.w,m.h, hx,hy,hw,hh) then
			del(moons, m)
		end
	end
	-- also absorb debris shards
	for d in all(debris) do
		if aabb(d.x,d.y,4,4, hx,hy,hw,hh) then
			spawn_chunk_dust(d.x+2, d.y+2)
			del(debris, d)
		end
	end
	-- dust is harmless; let it pass or get drawn over
end

-- allow blackholes to pull debris inward
function moon_debris_pull(cx,cy,r,strength)
	local r2 = r*r
	for d in all(debris) do
		local dx = cx - (d.x+2)
		local dy = cy - (d.y+2)
		local d2 = dx*dx + dy*dy
		if d2 > 0.5 and d2 < r2 then
			local invd = 1/sqrt(d2)
			local fall = 1 - d2/r2
			local acc = strength * fall
			d.dx += dx*invd * acc
			d.dy += dy*invd * acc
			-- cap shard speed a bit
			local sp = sqrt(d.dx*d.dx + d.dy*d.dy)
			if sp > 2 then
				local s = 2/sp
				d.dx *= s
				d.dy *= s
			end
		end
	end
end