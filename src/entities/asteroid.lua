local asteroids,spawn_t={},0

local function hit_by_player_bullet(x,y,w,h)
	for b in all(bullets) do
		if aabb(x,y,w,h,b.x,b.y,5,5) then
			del(bullets,b)
			return true
		end
	end
end

local function spawn_chunk_dust(x,y,alt)
	for i=1,3+rndi(3) do
		local a=rnd()
		-- alt flag rides in the d field; the type-1 ramp reads it to pick 13,5,1 vs 4,2,1
		p_add(x,y,cos(a)*(0.6+rnd(0.6)),sin(a)*(0.6+rnd(0.6)),8+rndi(6),1,nil,alt)
	end
end

local function cash(x,y,n)for i=1,n do local r=rnd() p_add(x,y,rnd()-0.5,rnd()-0.5,999,7,nil,r<.65 and 8 or r<.9 and 9 or 10)end end

local function kill_debris(p)
	local x,y=p.x+2,p.y+2
	hud_add_score(3) spawn_chunk_dust(x,y,p.c) p.l=0
	if rnd()<0.2 then cash(x,y,1) end
end

-- spawn the collectible rock chunks (the old dust puff is gone now that small + large both explode)
local function spawn_asteroid_debris(x,y,alt)
	for i=1,2+rndi(2) do
		local ox,oy=rndi(2)*4,rndi(2)*4
		local a,s=atan2(x+ox-ship.x,y+oy-ship.y)+rnd(.6)-.3,1+rnd(.5)
		-- chunks always sampled from debris tile 3 (src x=24,y=0); alt recoloured by pal swap at draw (c=alt)
		p_add(x+ox,y+oy,cos(a)*s,sin(a)*s,999,4,alt,{24+ox,oy})
	end
end

-- spawn_child_asteroids inlined at call site

-- full asteroid death: score + cash + (split children / debris) + boom + del.
-- shared by bullet kills and the bomb shockwave so both spawn the same payload.
local function akill(m)
	obk+=1 -- round-summary obstacle tally
	if m.large then
		-- alt (tougher) variants award more score + money for the extra hits
		hud_add_score(m.alt and 85 or 60)
		-- money shards (large): 0-5 (avg ~2.5), +4 flat for alt
		cash(m.x+4,m.y+4,max(1,rndi(6)+(m.alt and 4 or 0)))
		-- two halves of the 16px parent split straight outward (left half goes left, right
		-- half goes right) at a guaranteed minimum horizontal speed, falling at mspd in a
		-- straight line (constant velocity, no accel/decel) like a normal small asteroid.
		for i=0,1 do add(asteroids,{x=i*8+m.x+2,y=m.y+2,w=8,h=8,dx=(i*2-1)*(0.5+rnd(0.4)),spd=mspd,hp=m.alt and 4 or 2,large=false,alt=m.alt,flash=0}) end
		spawn_asteroid_debris(m.x+4,m.y+4,m.alt)
		-- fast rock-dust burst (alt-aware via the type-1 ramp); cheaper than a sprite explosion
		for i=1,12 do local a=rnd() p_add(m.x+8,m.y+8,cos(a)*(.5+rnd(1.6)),sin(a)*(.5+rnd(1.6)),9+rndi(7),1,nil,m.alt) end
	else
		hud_add_score(m.alt and 50 or 35)
		-- money shards (small): 0-3 (avg ~1.5), +2 flat for alt
		cash(m.x+4,m.y+4,max(1,rndi(4)+(m.alt and 2 or 0)))
		spawn_asteroid_debris(m.x,m.y,m.alt) boom(m.x,m.y,split"1,2,4,13")
	end
	snd_sfx(m.large and 6 or 5)
	del(asteroids,m)
end

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
		large=large,alt=alt,flash=0
	})
end

function update_asteroid()
	spawn_t-=FT
		if spawn_t<=0 and #asteroids<mm then
		spawn_asteroid()
		spawn_t=msmin+rnd(msrng)
	end

	-- refresh shield-pulse globals once per frame (asteroid runs first among enemies)
	shkl=ship.shield_pulse_level
	shsr=(ship.shield_active and shkl>0) and (10+shkl) or 0
	for m in all(asteroids) do
		m.y+=m.spd
		m.x+=m.dx
		m.flash=max(0,m.flash-1)

		-- bomb shockwave or shield pulse: shared damage/death check
		if eaoe(m,akill,m.x+m.w/2,m.y+m.h/2) then goto continue end

		if hit_by_player_bullet(m.x,m.y,m.w,m.h) then
			m.hp-=1
			if m.hp<=0 then akill(m) goto continue
			else m.flash=6 snd_sfx(3) end
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
			elseif shsr>0 then
				local dx=(p.x+2)-(ship.x+4) local dy=(p.y+2)-(ship.y+4)
				if dx*dx+dy*dy <= shsr*shsr then kill_debris(p) end
			elseif scoll(p.x,p.y,4,4) then if game_state=="game" then ship_kill() end end
		end
	end
end

function draw_asteroid()
	for m in all(asteroids) do
		-- hit flash whiteout (strobed); otherwise the stronger (alt) rock is just a
		-- palette swap of the base sprite colours (4,2,1 -> 13,5,1)
		if m.flash>0 and m.flash%2==0 then fl(7)
		elseif m.alt then pal(4,13) pal(2,5) end
		-- per-object hit shake: jitter the draw position +-1px while flashing
		local dx,dy=m.x,m.y
		if m.flash>0 then dx+=jit() dy+=jit() end
		if m.large then
			-- 2x2 block (base 1); alt uses the same sprites, recoloured by the swap above
			spr(1,dx,dy,2,2)
		else
			spr(16,dx,dy)
		end
		pal()
	end
	-- Debris and dust now drawn by particle system
end

function asteroid_absorb(hx,hy,hw,hh)
	-- black hole shreds asteroids: run the full death (akill) so they boom + score + drop loot
	for m in all(asteroids) do
		if aabb(m.x,m.y,m.w,m.h,hx,hy,hw,hh) then akill(m) end
	end
	-- Also absorb debris particles
	p_absorb(hx,hy,hw,hh,{[4]=true})
end

-- asteroid_debris_pull wrapper removed (inline p_pull with {[PT_DEBRIS]=true})
