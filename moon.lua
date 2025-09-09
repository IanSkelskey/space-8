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

-- Large moon sprites (2x2 arrangement)
local SPR_LARGE_TL = 7   -- top left
local SPR_LARGE_TR = 8   -- top right
local SPR_LARGE_BL = 23  -- bottom left
local SPR_LARGE_BR = 24  -- bottom right

-- scoring
local MOON_SCORE  = 100
local LARGE_MOON_SCORE = 250
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

-- spawn smaller moons when large moon is destroyed
local function spawn_child_moons(x, y, w, h)
	-- spawn 4 regular moons from the large moon's quadrants
	local positions = {
		{x + 2, y + 2},      -- top left
		{x + w - 10, y + 2}, -- top right
		{x + 2, y + h - 10}, -- bottom left
		{x + w - 10, y + h - 10} -- bottom right
	}
	
	for i=1,4 do
		local angle = (i-1) * 0.25 + rnd(0.1) -- spread in 4 directions
		local speed = 0.4 + rnd(0.3)
		add(moons, {
			x = positions[i][1],
			y = positions[i][2],
			w = 8, h = 8,
			dx = cos(angle) * speed,
			dy = sin(angle) * speed * 0.5 + 0.9,  -- inherit downward motion
			spd = 0.9,
			hp = 1,
			large = false,
			flash_t = 0
		})
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
	local hud_top = HUD_HEIGHT or 0
	
	-- 30% chance for large moon
	local is_large = rnd(1) < 0.3
	
	if is_large then
		add(moons, {
			x = flr(rnd(128-16)),
			y = hud_top - 20,  -- spawn above HUD area
			w = 16, h = 16,
			dx = 0, dy = 0,  -- no horizontal drift initially
			spd = spd * 0.8,  -- slightly slower
			hp = 2,
			large = true,
			flash_t = 0  -- flash timer when hit
		})
	else
		add(moons, {
			x = flr(rnd(128-8)),
			y = hud_top - 10,  -- spawn above HUD area
			w = 8, h = 8,
			dx = 0, dy = 0,
			spd = spd,
			hp = 1,
			large = false,
			flash_t = 0
		})
	end
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
		m.x += m.dx
		
		-- update flash timer
		if m.flash_t > 0 then
			m.flash_t -= 1
		end

		-- bullet hit
		if hit_by_player_bullet(m.x,m.y,m.w,m.h) then
			m.hp -= 1
			if m.hp <= 0 then
				-- destroyed
				if m.large then
					if hud_add_score then hud_add_score(LARGE_MOON_SCORE) end
					spawn_child_moons(m.x, m.y, m.w, m.h)
				else
					if hud_add_score then hud_add_score(MOON_SCORE) end
					spawn_moon_debris(m.x + (m.w-8)/2, m.y + (m.h-8)/2)
				end
				sfx(1, 3)  -- play explosion on channel 3
				del(moons, m)
				goto continue
			else
				-- damaged but not destroyed - flash white
				m.flash_t = 6  -- flash for 6 frames
			end
		end

		-- check collision with player
		if ship and aabb(m.x,m.y,m.w,m.h, ship.x,ship.y,ship.w,ship.h) then
			if ship_kill then ship_kill() end  -- ship_kill now handles shield check internally
		end

		-- cull
		if m.y > 136 or m.x < -20 or m.x > 148 then del(moons, m) end
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
		if m.large then
			-- draw 2x2 moon sprite using specific sprites
			if m.flash_t > 0 and m.flash_t % 2 == 0 then
				-- flash white effect
				rectfill(m.x, m.y, m.x+15, m.y+15, 7)
			else
				-- draw proper 2x2 sprite arrangement
				spr(SPR_LARGE_TL, m.x, m.y)
				spr(SPR_LARGE_TR, m.x+8, m.y)
				spr(SPR_LARGE_BL, m.x, m.y+8)
				spr(SPR_LARGE_BR, m.x+8, m.y+8)
			end
		else
			if m.flash_t > 0 and m.flash_t % 2 == 0 then
				-- flash white effect for regular moon
				rectfill(m.x, m.y, m.x+7, m.y+7, 7)
			else
				spr(SPR_MOON, m.x, m.y)
			end
		end
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