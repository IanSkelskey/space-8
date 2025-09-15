local asteroids = {}
local spawn_t = 0.0

local function hit_by_player_bullet(x,y,w,h)
	local pb = ship_get_bullets and ship_get_bullets()
	if not pb then return false end
	for b in all(pb) do
		if aabb(x,y,w,h, b.x,b.y,2,2) then
			del(pb,b)
			return true
		end
	end
	return false
end

local debris = {}
local SPR_ASTEROID = 2
local SPR_ASTEROID_A = 26
local SPR_SHARDS = 5
local SPR_SHARDS_A = 27

local SPR_LARGE_TL = 7
local SPR_LARGE_TR = 8
local SPR_LARGE_BL = 23
local SPR_LARGE_BR = 24

local ASTEROID_SCORE  = 120
local LARGE_ASTEROID_SCORE = 200   
local CHUNK_SCORE = 12         

local dust = {}

local function spawn_chunk_dust(x,y)
	local n=3+flr(rnd(3))
	for i=1,n do
		local ang = rnd(1)
		local sp = 0.6 + rnd(0.6)
		add(dust, { x=x, y=y, dx=cos(ang)*sp, dy=sin(ang)*sp, life=8+flr(rnd(6)) })
	end
end

local function spawn_asteroid_debris(x,y,alt)
	local base = alt and SPR_SHARDS_A or SPR_SHARDS
	local sx_base = (base%16)*8
	local sy_base = flr(base/16)*8
	for i=0,3 do
		local ox=(i%2==0) and 0 or 4
		local oy=(i<2) and 0 or 4
		local a=rnd(1)
		local sp=0.5+rnd(1.2)
		add(debris,{x=x+ox,y=y+oy,dx=cos(a)*sp,dy=sin(a)*sp,sx=sx_base+ox,sy=sy_base+oy})
	end
	for i=1,8 do
		local ang = rnd(1)
		local sp = rnd(1.2)
		add(dust, { x=x+4, y=y+4, dx=cos(ang)*sp, dy=sin(ang)*sp, life=18 })
	end
end

local function spawn_child_asteroids(x,y,w,h,a)
	for i=0,1 do
		local px=(i%2==0) and (x+2) or (x+w-10)
		local py=y+2
		local ag=i*0.25+rnd(0.1)
		local sp=0.4+rnd(0.3)
		add(asteroids,{x=px,y=py,w=8,h=8,dx=cos(ag)*sp,dy=sin(ag)*sp*0.5+0.9,spd=mspd or 0.9,hp=a and 4 or 2,large=false,alt=a,flash_t=0})
	end
end

function asteroid_init()
	asteroids = {}
	spawn_t = 0
	debris = {}
	dust = {}
end

local function spawn_asteroid()
	local spd = mspd or 0.9
	local alt = (round_number or 0)>10 and rnd(1)<min(0.1+0.04*(round_number-10),0.5)
	if (round_number and round_number>=4) and (rnd(1) < (mlc or 0.3)) then
		add(asteroids,{x=flr(rnd(128-16)),y=(HUD_HEIGHT or 0)-20,w=16,h=16,dx=0,dy=0,spd=spd*0.8,hp=alt and 6 or 3,large=true,alt=alt,flash_t=0})
	else
		add(asteroids,{x=flr(rnd(128-8)),y=(HUD_HEIGHT or 0)-10,w=8,h=8,dx=0,dy=0,spd=spd,hp=alt and 4 or 2,large=false,alt=alt,flash_t=0})
	end
end

function update_asteroid()
	spawn_t -= 1/30
	if spawn_t <= 0 and #asteroids < (mm or 3) then
		spawn_asteroid()
		spawn_t = (msmin or 1.5) + rnd(msrng or 1.5)
	end

	for m in all(asteroids) do
		m.y += m.spd
		m.x += m.dx
		
		if m.flash_t > 0 then
			m.flash_t -= 1
		end

		if hit_by_player_bullet(m.x,m.y,m.w,m.h) then
			m.hp -= 1
			if m.hp<=0 then
				if m.large then
					if hud_add_score then hud_add_score(LARGE_ASTEROID_SCORE) end
					spawn_child_asteroids(m.x,m.y,m.w,m.h,m.alt)
					spawn_asteroid_debris(m.x+4,m.y+4,m.alt)
				else
					if hud_add_score then hud_add_score(ASTEROID_SCORE) end
					spawn_asteroid_debris(m.x + (m.w-8)/2, m.y + (m.h-8)/2, m.alt)
				end
				sfx(1, 3)
				del(asteroids, m)
				goto continue
			else
				m.flash_t=6
			end
		end

		if ship and aabb(m.x,m.y,m.w,m.h, ship.x,ship.y,ship.w,ship.h) then
			if ship_kill then ship_kill() end
		end

		if m.y > 136 or m.x < -20 or m.x > 148 then del(asteroids, m) end
		::continue::
	end

	for d in all(debris) do
		d.x += d.dx
		d.y += d.dy
		d.dx *= 0.99
		d.dy *= 0.99

		if hit_by_player_bullet(d.x, d.y, 4, 4) then
			if hud_add_score then hud_add_score(CHUNK_SCORE) end
			spawn_chunk_dust(d.x+2, d.y+2)
			del(debris, d)
		else
			if ship and aabb(d.x,d.y,4,4, ship.x,ship.y,ship.w,ship.h) then
				if game_state == "game" and ship_kill then ship_kill() end
				return
			end
			if d.x < -4 or d.x > 132 or d.y < -4 or d.y > 132 then
				del(debris, d)
			end
		end
	end

	for p in all(dust) do
		p.x += p.dx
		p.y += p.dy
		p.life -= 1
		if p.life <= 0 or p.x < -2 or p.x > 130 or p.y < -2 or p.y > 130 then
			del(dust, p)
		end
	end
end

function draw_asteroid()
	local function begin_white_flash()
		for i=1,15 do pal(i,7) end
		palt(0, true)
	end
	local function end_white_flash()
		pal()
		palt()
	end

	for m in all(asteroids) do
		if m.large then
			if m.flash_t > 0 and m.flash_t % 2 == 0 then
				begin_white_flash()
				spr(SPR_LARGE_TL, m.x, m.y)
				spr(SPR_LARGE_TR, m.x+8, m.y)
				spr(SPR_LARGE_BL, m.x, m.y+8)
				spr(SPR_LARGE_BR, m.x+8, m.y+8)
				end_white_flash()
			else
				local o=m.alt and 5 or 0
				spr(SPR_LARGE_TL+o, m.x, m.y)
				spr(SPR_LARGE_TR+o, m.x+8, m.y)
				spr(SPR_LARGE_BL+o, m.x, m.y+8)
				spr(SPR_LARGE_BR+o, m.x+8, m.y+8)
			end
		else
			if m.flash_t > 0 and m.flash_t % 2 == 0 then
				begin_white_flash()
				spr(SPR_ASTEROID, m.x, m.y)
				end_white_flash()
			else
				spr(m.alt and SPR_ASTEROID_A or SPR_ASTEROID, m.x, m.y)
			end
		end
	end
	for d in all(debris) do
		sspr(d.sx, d.sy, 4, 4, d.x, d.y)
	end
	for p in all(dust) do
		local c = p.life > 12 and 6 or (p.life > 6 and 5 or 7)
		pset(flr(p.x), flr(p.y), c)
	end
end

function asteroid_absorb(hx,hy,hw,hh)
	for m in all(asteroids) do
		if aabb(m.x,m.y,m.w,m.h, hx,hy,hw,hh) then
			del(asteroids, m)
		end
	end
	for d in all(debris) do
		if aabb(d.x,d.y,4,4, hx,hy,hw,hh) then
			spawn_chunk_dust(d.x+2, d.y+2)
			del(debris, d)
		end
	end
end

function asteroid_debris_pull(cx,cy,r,strength)
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
			local sp = sqrt(d.dx*d.dx + d.dy*d.dy)
			if sp > 2 then
				local s = 2/sp
				d.dx *= s
				d.dy *= s
			end
		end
	end
end