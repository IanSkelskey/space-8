local asteroids,spawn_t={},0

local function hit_by_player_bullet(x,y,w,h)
	local pb=ship_get_bullets()
	for b in all(pb) do
		if aabb(x,y,w,h,b.x,b.y,2,2) then
			del(pb,b)
			return true
		end
	end
end

local function spawn_chunk_dust(x,y)
	for i=1,3+flr(rnd(3)) do
		local a=rnd()
		p_add(x,y,cos(a)*(0.6+rnd(0.6)),sin(a)*(0.6+rnd(0.6)),8+flr(rnd(6)),PT_DUST)
	end
end

local function spawn_asteroid_debris(x,y,alt)
	local sx,sy=(alt and 27 or 5)%16*8,flr((alt and 27 or 5)/16)*8
	for i=0,3 do
		local ox,oy=i%2*4,i\2*4
		local a=rnd()
		p_add(x+ox,y+oy,cos(a)*(0.5+rnd(1.2)),sin(a)*(0.5+rnd(1.2)),999,PT_DEBRIS,nil,{sx+ox,sy+oy})
	end
	for i=1,8 do
		local a=rnd()
		p_add(x+4,y+4,cos(a)*rnd(1.2),sin(a)*rnd(1.2),18,PT_DUST)
	end
end

local function spawn_child_asteroids(x,y,w,h,a)
	for i=0,1 do
		local ag=i*0.25+rnd(0.1)
		add(asteroids,{x=i%2*w-i%2*8+x+2,y=y+2,w=8,h=8,dx=cos(ag)*(0.4+rnd(0.3)),dy=sin(ag)*(0.4+rnd(0.3))*0.5+0.9,spd=mspd or 0.9,hp=a and 4 or 2,large=false,alt=a,flash_t=0})
	end
end

function asteroid_init()
	asteroids,spawn_t={},0
end

local function spawn_asteroid()
	local spd,alt=mspd or 0.9,(round_number or 0)>10 and rnd()<min(0.1+0.04*(round_number-10),0.5)
	local large=(round_number and round_number>=4) and rnd()<(mlc or 0.3)
	add(asteroids,{
		x=flr(rnd(large and 112 or 120)),
		y=(HUD_HEIGHT or 0)-(large and 20 or 10),
		w=large and 16 or 8,
		h=large and 16 or 8,
		dx=0,dy=0,
		spd=large and spd*0.8 or spd,
		hp=large and (alt and 6 or 3) or (alt and 4 or 2),
		large=large,alt=alt,flash_t=0
	})
end

function update_asteroid()
	spawn_t-=1/30
	if spawn_t<=0 and #asteroids<(mm or 3) then
		spawn_asteroid()
		spawn_t=(msmin or 1.5)+rnd(msrng or 1.5)
	end

	for m in all(asteroids) do
		m.y+=m.spd
		m.x+=m.dx
		m.flash_t=max(0,m.flash_t-1)

		if hit_by_player_bullet(m.x,m.y,m.w,m.h) then
			m.hp-=1
			if m.hp<=0 then
				if m.large then
					hud_add_score(200)
					spawn_child_asteroids(m.x,m.y,m.w,m.h,m.alt)
					spawn_asteroid_debris(m.x+4,m.y+4,m.alt)
				else
					hud_add_score(120)
					spawn_asteroid_debris(m.x+(m.w-8)/2,m.y+(m.h-8)/2,m.alt)
				end
				snd_sfx(SFX_EXPLODE,FX_CH)
				del(asteroids,m)
				goto continue
			else
				m.flash_t=6
			end
		end

		if ship and aabb(m.x,m.y,m.w,m.h,ship.x,ship.y,ship.w,ship.h) then
			ship_kill()
		end

		if m.y>136 or m.x<-20 or m.x>148 then del(asteroids,m) end
		::continue::
	end

	-- Check debris collisions with bullets and ship
	local parts=p_get()
	for p in all(parts) do
		if p.t==PT_DEBRIS then
			if hit_by_player_bullet(p.x,p.y,4,4) then
				hud_add_score(12)
				spawn_chunk_dust(p.x+2,p.y+2)
				p.l=0 -- Mark for deletion
			elseif ship and aabb(p.x,p.y,4,4,ship.x,ship.y,ship.w,ship.h) then
				if game_state=="game" then ship_kill() end
			end
		end
	end
end

function draw_asteroid()
	for m in all(asteroids) do
		local flash=m.flash_t>0 and m.flash_t%2==0
		if m.large then
			if flash then
				spr(14,m.x,m.y) spr(15,m.x+8,m.y) spr(30,m.x,m.y+8) spr(31,m.x+8,m.y+8)
			else
				local o=m.alt and 5 or 0
				local a=7+o
				spr(a,m.x,m.y) spr(a+1,m.x+8,m.y) spr(a+16,m.x,m.y+8) spr(a+17,m.x+8,m.y+8)
			end
		else
			if flash then
				-- Use hit sprite for regular asteroids (sprite 1)
				spr(1,m.x,m.y)
			else
				spr(m.alt and 26 or 2,m.x,m.y)
			end
		end
	end
	-- Debris and dust now drawn by particle system
end

function asteroid_absorb(hx,hy,hw,hh)
	for m in all(asteroids) do
		if aabb(m.x,m.y,m.w,m.h,hx,hy,hw,hh) then
			del(asteroids,m)
		end
	end
	-- Also absorb debris particles
	p_absorb(hx,hy,hw,hh,{[PT_DEBRIS]=true})
	-- Spawn dust when debris is absorbed
	local parts=p_get()
	for p in all(parts) do
		if p.t==PT_DEBRIS and p.x>=hx and p.x<hx+hw and p.y>=hy and p.y<hy+hh then
			spawn_chunk_dust(p.x+2,p.y+2)
		end
	end
end

function asteroid_debris_pull(cx,cy,r,strength)
	-- Now use unified particle pull for debris
	p_pull(cx,cy,r,strength,{[PT_DEBRIS]=true})
end