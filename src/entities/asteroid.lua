local asteroids,debris,dust,spawn_t={},{},{},0

local function hit_by_player_bullet(x,y,w,h)
	local pb=ship_get_bullets and ship_get_bullets()
	if not pb then return end
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
		add(dust,{x=x,y=y,dx=cos(a)*(0.6+rnd(0.6)),dy=sin(a)*(0.6+rnd(0.6)),life=8+flr(rnd(6))})
	end
end

local function spawn_asteroid_debris(x,y,alt)
	local base,sx,sy=alt and 27 or 5,(alt and 27 or 5)%16*8,flr((alt and 27 or 5)/16)*8
	for i=0,3 do
		local ox,oy=i%2*4,i\2*4
		local a=rnd()
		add(debris,{x=x+ox,y=y+oy,dx=cos(a)*(0.5+rnd(1.2)),dy=sin(a)*(0.5+rnd(1.2)),sx=sx+ox,sy=sy+oy})
	end
	for i=1,8 do
		local a=rnd()
		add(dust,{x=x+4,y=y+4,dx=cos(a)*rnd(1.2),dy=sin(a)*rnd(1.2),life=18})
	end
end

local function spawn_child_asteroids(x,y,w,h,a)
	for i=0,1 do
		local ag=i*0.25+rnd(0.1)
		add(asteroids,{x=i%2*w-i%2*8+x+2,y=y+2,w=8,h=8,dx=cos(ag)*(0.4+rnd(0.3)),dy=sin(ag)*(0.4+rnd(0.3))*0.5+0.9,spd=mspd or 0.9,hp=a and 4 or 2,large=false,alt=a,flash_t=0})
	end
end

function asteroid_init()
	asteroids,debris,dust,spawn_t={},{},{},0
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
					if hud_add_score then hud_add_score(200) end
					spawn_child_asteroids(m.x,m.y,m.w,m.h,m.alt)
					spawn_asteroid_debris(m.x+4,m.y+4,m.alt)
				else
					if hud_add_score then hud_add_score(120) end
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
			if ship_kill then ship_kill() end
		end

		if m.y>136 or m.x<-20 or m.x>148 then del(asteroids,m) end
		::continue::
	end

	for d in all(debris) do
		d.x+=d.dx
		d.y+=d.dy
		d.dx*=0.99
		d.dy*=0.99

		if hit_by_player_bullet(d.x,d.y,4,4) then
			if hud_add_score then hud_add_score(12) end
			spawn_chunk_dust(d.x+2,d.y+2)
			del(debris,d)
		elseif ship and aabb(d.x,d.y,4,4,ship.x,ship.y,ship.w,ship.h) then
			if game_state=="game" and ship_kill then ship_kill() end
		elseif d.x<-4 or d.x>132 or d.y<-4 or d.y>132 then
			del(debris,d)
		end
	end

	for p in all(dust) do
		p.x+=p.dx
		p.y+=p.dy
		p.life-=1
		if p.life<=0 or p.x<-2 or p.x>130 or p.y<-2 or p.y>130 then
			del(dust,p)
		end
	end
end

function draw_asteroid()
	for m in all(asteroids) do
		local flash=m.flash_t>0 and m.flash_t%2==0
		if flash then
			for i=1,15 do pal(i,7) end
			palt(0,true)
		end
		if m.large then
			local o=m.alt and 5 or 0
			spr(7+o,m.x,m.y)
			spr(8+o,m.x+8,m.y)
			spr(23+o,m.x,m.y+8)
			spr(24+o,m.x+8,m.y+8)
		else
			spr(m.alt and 26 or 2,m.x,m.y)
		end
		if flash then pal() palt() end
	end
	for d in all(debris) do
		sspr(d.sx,d.sy,4,4,d.x,d.y)
	end
	for p in all(dust) do
		pset(flr(p.x),flr(p.y),p.life>12 and 6 or p.life>6 and 5 or 7)
	end
end

function asteroid_absorb(hx,hy,hw,hh)
	for m in all(asteroids) do
		if aabb(m.x,m.y,m.w,m.h,hx,hy,hw,hh) then
			del(asteroids,m)
		end
	end
	for d in all(debris) do
		if aabb(d.x,d.y,4,4,hx,hy,hw,hh) then
			spawn_chunk_dust(d.x+2,d.y+2)
			del(debris,d)
		end
	end
end

function asteroid_debris_pull(cx,cy,r,strength)
	local r2=r*r
	for d in all(debris) do
		local dx,dy=cx-(d.x+2),cy-(d.y+2)
		local d2=dx*dx+dy*dy
		if d2>0.5 and d2<r2 then
			local invd,fall,acc=1/sqrt(d2),1-d2/r2,strength*(1-d2/r2)
			d.dx+=dx*invd*acc
			d.dy+=dy*invd*acc
			local sp=sqrt(d.dx*d.dx+d.dy*d.dy)
			if sp>2 then
				d.dx*=2/sp
				d.dy*=2/sp
			end
		end
	end
end