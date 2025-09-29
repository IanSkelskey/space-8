local holes,spawn_t={},0

local function spawn_hole()
	add(holes,{
		x=flr(rnd(120)),
		y=(HUD_HEIGHT or 0)-10,
		w=8,h=8,
		spd=0.8,
		r=50,
		spin_t=0
	})
end

local function spawn_particles(h)
	for i=1,1+(rnd()<0.5 and 1 or 0) do
		local ang,rad=rnd(),2+rnd(2)
		local px,py=h.x+4+cos(ang)*rad,h.y+4+sin(ang)*rad
		local tx,ty,spd=-sin(ang),cos(ang),0.45+rnd(0.45)
		p_add(px,py,tx*spd+rnd(0.2)-0.1+cos(ang)*0.08,ty*spd+rnd(0.2)-0.1+sin(ang)*0.08,20+flr(rnd(10)),PT_HOLE)
	end
end

function blackhole_init()
	holes,spawn_t={},0
end

function update_blackhole()
	if not round_number or round_number<5 then return end
	spawn_t-=1/30
	local hm=round_number<7 and 1 or 2
	if spawn_t<=0 and #holes<hm then
		spawn_hole()
		spawn_t=(3+rnd(3))*(round_number<7 and 1.5 or 1)
	end

	for h in all(holes) do
		h.y+=h.spd
		h.spin_t=(h.spin_t+1)%32
		
		local cx,cy=h.x+4,h.y+4
		if asteroid_debris_pull then
			asteroid_debris_pull(cx,cy,h.r,0.35)
		end
		if ship_trails_pull then
			ship_trails_pull(cx,cy,h.r,0.22)
		end

		if ship then
			local dx,dy=cx-ship.x-ship.w/2,cy-ship.y-ship.h/2
			local d2=dx*dx+dy*dy
			local r2=h.r*h.r
			if d2<r2 and d2>0 then
				local invd,str=1/sqrt(d2),0.75*(1-d2/r2)
				ship.x=mid(0,ship.x+dx*invd*str,128-ship.w)
				ship.y=mid(0,ship.y+dy*invd*str,128-ship.h)
			end
			if aabb(h.x,h.y,h.w,h.h,ship.x,ship.y,ship.w,ship.h) then
				if ship.dying~=true and ship_kill then
					ship.shield_power,ship.shield_active=0,false
					ship_kill()
				end
			end
		end

		if h.y>136 then del(holes,h) end

		if asteroid_absorb then
			asteroid_absorb(h.x,h.y,h.w,h.h)
		end
		if ship_trails_absorb then
			ship_trails_absorb(h.x,h.y,h.w,h.h)
		end

		spawn_particles(h)
		-- inline bullet pull
		local pb=ship_get_bullets and ship_get_bullets()
		if pb then
			local cx,cy,r2=h.x+4,h.y+4,h.r*h.r
			for b in all(pb) do
				if aabb(b.x,b.y,2,2,h.x,h.y,h.w,h.h) then
					del(pb,b)
				else
					local dx,dy=cx-b.x,cy-b.y
					local d2=dx*dx+dy*dy
					if d2>0.1 and d2<r2 then
						local invd,acc=1/sqrt(d2),0.25*(1-d2/r2)
						b.dx+=dx*invd*acc
						b.dy+=dy*invd*acc
						local sp=sqrt(b.dx*b.dx+b.dy*b.dy)
						if sp>4 then b.dx*=4/sp b.dy*=4/sp end
					end
				end
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