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
	for i=1,3+rndi(3) do
		local a=rnd()
		p_add(x,y,cos(a)*(0.6+rnd(0.6)),sin(a)*(0.6+rnd(0.6)),8+rndi(6),1)
	end
end

local function cash(x,y,n)for i=1,n do p_add(x,y,rnd()-0.5,rnd()-0.5,999,7,nil,7)end end

local function kill_debris(p)
	local x,y=p.x+2,p.y+2
	hud_add_score(3) spawn_chunk_dust(x,y) p.l=0
	if rnd()<0.2 then cash(x,y,1) end
end

local function spawn_asteroid_debris(x,y,alt,boomed)
	for i=1,2+rndi(2) do
		local ox,oy=rndi(2)*4,rndi(2)*4
		local a,s=atan2(x+ox-ship.x,y+oy-ship.y)+rnd(.6)-.3,1+rnd(.5)
		-- chunks always sampled from sprite 5 (src x=40); alt recoloured by pal swap at draw (c=alt)
		p_add(x+ox,y+oy,cos(a)*s,sin(a)*s,999,4,alt,{40+ox,oy})
	end
	-- dust puff: skipped for small asteroids, whose sprite explosion (boom) covers it
	if not boomed then for i=1,8 do
		local a=rnd()
		p_add(x+4,y+4,cos(a)*rnd(1.2),sin(a)*rnd(1.2),18,1)
	end end
end

-- spawn_child_asteroids inlined at call site

function asteroid_init()
	asteroids,spawn_t={},0
end

local function spawn_asteroid()
	local spd,alt=mspd,round_number>6 and rnd()<min(0.12+0.06*(round_number-6),0.65)
	local large=round_number>=3 and rnd()<mlc
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
						-- alt (tougher) variants award more score + money for the extra hits
						hud_add_score(m.alt and 85 or 60)
						-- money shards (large): 0-5 (avg ~2.5), +4 flat for alt; 4 credits each
						cash(m.x+4,m.y+4,max(1,rndi(6)+(m.alt and 4 or 0)))
					-- inlined spawn_child_asteroids
					for i=0,1 do local ag=i*0.25+rnd(0.1) add(asteroids,{x=i%2*m.w-i%2*8+m.x+2,y=m.y+2,w=8,h=8,dx=cos(ag)*(0.4+rnd(0.3)),dy=sin(ag)*(0.4+rnd(0.3))*0.5+0.9,spd=mspd,hp=m.alt and 4 or 2,large=false,alt=m.alt,flash_t=0}) end
					spawn_asteroid_debris(m.x+4,m.y+4,m.alt)
				else
						hud_add_score(m.alt and 50 or 35)
						-- money shards (small): 0-3 (avg ~1.5), +2 flat for alt; 4 credits each
						cash(m.x+4,m.y+4,max(1,rndi(4)+(m.alt and 2 or 0)))
					spawn_asteroid_debris(m.x,m.y,m.alt,true) boom(m.x,m.y,split"1,2,4,13")
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
					kill_debris(p)
			-- shield shock (active shield aura destroys debris)
			elseif ship.shield_pulse_level>0 and ship.shield_active then
				local dx=(p.x+2)-(ship.x+4) local dy=(p.y+2)-(ship.y+4)
				local r=10+ship.shield_pulse_level
				if dx*dx+dy*dy <= r*r then
					 kill_debris(p)
				end
			elseif scoll(p.x,p.y,4,4) then if game_state=="game" then ship_kill() end end
		end
	end
end

function draw_asteroid()
	for m in all(asteroids) do
		-- hit flash whiteout (strobed); otherwise the stronger (alt) rock is just a
		-- palette swap of the base sprite colours (4,2,1 -> 13,5,1)
		if m.flash_t>0 and m.flash_t%2==0 then wt()
		elseif m.alt then pal(4,13) pal(2,5) end
		-- per-object hit shake: jitter the draw position +-1px while flashing
		local dx,dy=m.x,m.y
		if m.flash_t>0 then dx+=rndi(3)-1 dy+=rndi(3)-1 end
		if m.large then
			-- 2x2 block; alt uses the same sprites, recoloured by the swap above
			spr(7,dx,dy) spr(8,dx+8,dy) spr(23,dx,dy+8) spr(24,dx+8,dy+8)
		else
			spr(2,dx,dy)
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
