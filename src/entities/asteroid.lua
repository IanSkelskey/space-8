local asteroids,spawn_t={},0

local function hit_by_player_bullet(x,y,w,h)
	for b in all(bullets) do
		if aabb(x,y,w,h,b.x,b.y,5,5) then
			del(bullets,b)
			return true
		end
	end
end

local function spawn_chunk_dust(x,y)
	for i=1,3+rnd(3)\1 do
		local a=rnd()
		p_add(x,y,cos(a)*(0.6+rnd(0.6)),sin(a)*(0.6+rnd(0.6)),8+rnd(6)\1,1)
	end
end

local function spawn_asteroid_debris(x,y,alt)
	local l=alt and 27 or 5
	local sx,sy=l%16*8,flr(l/16)*8
	for i=0,3 do
		local ox,oy=i%2*4,i\2*4
		local a=rnd()
		p_add(x+ox,y+oy,cos(a)*(0.5+rnd(1.2)),sin(a)*(0.5+rnd(1.2)),999,4,nil,{sx+ox,sy+oy})
	end
	for i=1,8 do
		local a=rnd()
		p_add(x+4,y+4,cos(a)*rnd(1.2),sin(a)*rnd(1.2),18,1)
	end
end

-- spawn_child_asteroids inlined at call site

function asteroid_init()
	asteroids,spawn_t={},0
end

local function spawn_asteroid()
	local spd,alt=mspd,round_number>6 and rnd()<min(0.12+0.06*(round_number-6),0.65)
	local large=round_number>=3 and rnd()<(mlc or 0.3)
	local sz=large and 16 or 8
	add(asteroids,{
		x=flr(rnd(large and 112 or 120)),
		y=10-(large and 20 or 10),
		w=sz,h=sz,
		dx=0,dy=0,
		spd=large and spd*0.8 or spd,
		hp=large and (alt and 6 or 3) or (alt and 4 or 2),
		large=large,alt=alt,flash_t=0
	})
end

function update_asteroid()
	spawn_t-=FT
		if spawn_t<=0 and #asteroids<mm then
		spawn_asteroid()
		spawn_t=msmin+rnd(msrng)
	end

	-- shield shock threshold kill:
	-- level1: destroy if asteroid hp<=1 inside shield radius
	-- level2: destroy if hp<=2 inside shield radius
	local kill_lvl=ship.shield_pulse_level
	local sr=(ship.shield_active and kill_lvl>0) and (10+kill_lvl) or 0
	for m in all(asteroids) do
		m.y+=m.spd
		m.x+=m.dx
		m.flash_t=max(0,m.flash_t-1)

		-- shield shock kill check (no continuous damage tick)
		if sr>0 and m.flash_t==0 then
			local dx=(m.x+m.w/2)-(ship.x+4) local dy=(m.y+m.h/2)-(ship.y+4)
			if dx*dx+dy*dy <= sr*sr and m.hp<=kill_lvl then
				-- simulate bullet kill path: award score and spawn debris like normal hp<=0 branch
				m.hp=0 m.flash_t=4
			end
		end

		if hit_by_player_bullet(m.x,m.y,m.w,m.h) then
			m.hp-=1
				if m.hp<=0 then
				if m.large then
						hud_add_score(60)
						-- money shards (large): 0-5 (avg ~2.5) at 4 each => ~10 value
						for i=1,rnd(6)\1 do p_add(m.x+4,m.y+4,rnd()-0.5,rnd()-0.5,999,7,nil,7) end
					-- inlined spawn_child_asteroids
					for i=0,1 do local ag=i*0.25+rnd(0.1) add(asteroids,{x=i%2*m.w-i%2*8+m.x+2,y=m.y+2,w=8,h=8,dx=cos(ag)*(0.4+rnd(0.3)),dy=sin(ag)*(0.4+rnd(0.3))*0.5+0.9,spd=mspd or 0.9,hp=m.alt and 4 or 2,large=false,alt=m.alt,flash_t=0}) end
					spawn_asteroid_debris(m.x+4,m.y+4,m.alt)
				else
						hud_add_score(35)
						-- money shards (small): 0-3 (avg ~1.5) => ~6 value
						for i=1,rnd(4)\1 do p_add(m.x+(m.w-8)/2+4,m.y+(m.h-8)/2+4,rnd()-0.5,rnd()-0.5,999,7,nil,7) end
					spawn_asteroid_debris(m.x+(m.w-8)/2,m.y+(m.h-8)/2,m.alt)
				end
				snd_sfx(1)
				del(asteroids,m)
				goto continue
			else
				m.flash_t=6
			end
		end

		if scoll(m.x,m.y,m.w,m.h) then ship_kill() end

		if m.y>136 or m.x<-20 or m.x>148 then del(asteroids,m) end
		::continue::
	end

	-- Check debris collisions with bullets and ship
	for p in all(Gp) do
		if p.t==4 then
			if hit_by_player_bullet(p.x,p.y,4,4) then
					hud_add_score(3) spawn_chunk_dust(p.x+2,p.y+2) p.l=0 if rnd()<0.2 then p_add(p.x+2,p.y+2,rnd()-0.5,rnd()-0.5,999,7,nil,7) end
			-- shield shock (active shield aura destroys debris)
			elseif ship.shield_pulse_level>0 and ship.shield_active then
				local dx=(p.x+2)-(ship.x+4) local dy=(p.y+2)-(ship.y+4)
				local r=10+ship.shield_pulse_level
				if dx*dx+dy*dy <= r*r then
					 hud_add_score(3) spawn_chunk_dust(p.x+2,p.y+2) p.l=0
					 if rnd()<0.2 then p_add(p.x+2,p.y+2,rnd()-0.5,rnd()-0.5,999,7,nil,7) end
				end
			elseif scoll(p.x,p.y,4,4) then if game_state=="game" then ship_kill() end end
		end
	end
end

function draw_asteroid()
	for m in all(asteroids) do
		-- hit flash via palette whiteout (no dedicated flash sprites)
		if m.flash_t>0 and m.flash_t%2==0 then
			for i=1,15 do pal(i,7) end
		end
		if m.large then
			local base=7+(m.alt and 5 or 0)
			-- draw 2x2 block
			spr(base,m.x,m.y) spr(base+1,m.x+8,m.y) spr(base+16,m.x,m.y+8) spr(base+17,m.x+8,m.y+8)
		else
			spr(m.alt and 26 or 2,m.x,m.y)
		end
		pal()
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
	p_absorb(hx,hy,hw,hh,{[4]=true})
end

-- asteroid_debris_pull wrapper removed (inline p_pull with {[PT_DEBRIS]=true})
