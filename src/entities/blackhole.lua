local holes,spawn_t={},0

local function spawn_hole()
	add(holes,{
		x=flr(rnd(120)),
		y=0,
		spd=0.8,
		r=50,
		spin_t=0
	})
end

-- spawn_particles inlined in update loop for token savings

function blackhole_init()
	holes,spawn_t={},0
end

function update_blackhole()
	if round_number<5 then return end
	spawn_t-=FT
	local hm=round_number<7 and 1 or 2
	if spawn_t<=0 and #holes<hm then
		spawn_hole()
		spawn_t=(3+rnd(3))*(round_number<7 and 1.5 or 1)
	end

	for h in all(holes) do
		h.y+=h.spd
		h.spin_t=(h.spin_t+1)%32
		
		local cx,cy=h.x+4,h.y+4
		-- inline asteroid_debris_pull / ship_trails_pull
		p_pull(cx,cy,h.r,0.35,{[4]=true})
		p_pull(cx,cy,h.r,0.22,{[2]=true,[3]=true})
		comet_pull(cx,cy,h.r,0.3)

		local dx,dy=cx-ship.x-ship.w/2,cy-ship.y-ship.h/2
		local d2=dx*dx+dy*dy
		local r2=h.r*h.r
		if d2<r2 and d2>0 then
			local invd,str=1/sqrt(d2),0.75*(1-d2/r2)
			ship.x=mid(0,ship.x+dx*invd*str,128-ship.w)
			ship.y=mid(0,ship.y+dy*invd*str,128-ship.h)
			-- gravity drama: subtle shake builds as the ship is dragged deeper into the well
			shake=max(shake or 0,str*2)
		end
		if scoll(h.x,h.y,8,8) and not ship.dying then
			ship.shield_power,ship.shield_active=0,false
			ship_kill()
		end

		if h.y>136 then del(holes,h) end

		asteroid_absorb(h.x,h.y,8,8)
		-- inline ship_trails_absorb
		p_absorb(h.x,h.y,8,8,{[2]=true,[3]=true})

		-- inlined spawn_particles(h)
		for i=1,(rnd()<0.5 and 2 or 1) do
			local ang,rad=rnd(),2+rnd(2)
			local px,py=h.x+4+cos(ang)*rad,h.y+4+sin(ang)*rad
			local tx,ty,spd=-sin(ang),cos(ang),0.45+rnd(0.45)
			p_add(px,py,tx*spd+rnd(0.2)-0.1+cos(ang)*0.08,ty*spd+rnd(0.2)-0.1+sin(ang)*0.08,20+rnd(10)\1,6)
		end
		-- inline bullet pull (reuse cx,cy and r2)
		for b in all(bullets) do
			if aabb(b.x,b.y,5,5,h.x,h.y,8,8) then
				del(bullets,b)
			else
				local dx,dy=cx-b.x,cy-b.y local d2=dx*dx+dy*dy
				if d2>0.1 and d2<r2 then local invd,acc=1/sqrt(d2),0.25*(1-d2/r2) b.dx+=dx*invd*acc b.dy+=dy*invd*acc local sp=b.dx*b.dx+b.dy*b.dy if sp>16 then local s=sqrt(sp) b.dx*=4/s b.dy*=4/s end end
			end
		end
	end

	-- Update hole particles with special physics
	p_hole_pull(holes)
end

function draw_blackhole()
	-- Hole particles now drawn by particle system
	for h in all(holes) do
		local ph=flr(h.spin_t/8)%4
		spr(3,h.x,h.y,1,1,ph==1 or ph==2,ph==2 or ph==3)
	end
end
