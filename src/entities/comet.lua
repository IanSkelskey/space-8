local comets,parts,spawn_t={},{},0
local SIDS,WARNING_TIME={48,49,50,51,52},20
local SWAPS={{8,9},{2,14},{10,9},{3,11},{1,12}}

function comet_init()
	comets,parts,spawn_t={},{},0
end

local function spawn_comet()
	local left,x,y=rnd()<0.5,0,(HUD_HEIGHT or 0)+flr(rnd(120-(HUD_HEIGHT or 0)))
	x=left and -8 or 128
	local ang=left and (rnd()<0.5 and 0.125 or 0.875) or (rnd()<0.5 and 0.375 or 0.625)
	local spd=1.2+rnd(0.9)
	local i=flr(rnd(#SWAPS))
	add(comets,{
		x=x,y=y,w=8,h=8,
		dx=cos(ang)*spd,dy=sin(ang)*spd,
		c8=SWAPS[i+1][1],c9=SWAPS[i+1][2],sid=SIDS[i+1],
		warning_t=WARNING_TIME,
		left=left
	})
end

function update_comet()
	if not round_number or round_number<3 then return end
	spawn_t-=1/30
	local mx,mi,rg=cm or 3,cmin or 1,crng or 1.2
	if round_number<5 then mx=min(mx,1) end
	if spawn_t<=0 and #comets<mx then
		spawn_comet()
		spawn_t=(mi+rnd(rg))*(round_number<5 and 1.5 or 1)
	end

	for c in all(comets) do
		if c.warning_t>0 then
			c.warning_t-=1
			goto continue
		end

		local s=cs or 1
		c.x+=c.dx*s
		c.y+=c.dy*s

		local spd=sqrt(c.dx*c.dx+c.dy*c.dy)
		local ux,uy=spd>0 and c.dx/spd or 0,spd>0 and c.dy/spd or 0
		for i=1,rnd()<0.4 and 2 or 1 do
			add(parts,{
				x=c.x+4-ux*2+rnd()-0.5,
				y=c.y+4-uy*2+rnd()-0.5,
				dx=-ux*(0.2+rnd(0.2))+rnd(0.1)-0.05,
				dy=-uy*(0.2+rnd(0.2))+rnd(0.1)-0.05,
				life=18+flr(rnd(10)),
				col=rnd()<0.5 and c.c8 or c.c9
			})
		end

		if ship and not c.warning and aabb(c.x,c.y,c.w,c.h,ship.x,ship.y,ship.w,ship.h) then
			if ship_kill then ship_kill() end
		end

		if c.x<-12 or c.x>140 or c.y<-12 or c.y>140 then del(comets,c) end
		::continue::
	end

	for p in all(parts) do
		p.x+=p.dx
		p.y+=p.dy
		p.life-=1
		if p.life<=0 or p.x<-4 or p.x>132 or p.y<-4 or p.y>132 then del(parts,p) end
	end
end

function draw_comet()
	for c in all(comets) do
		if c.warning_t>0 then
			local cx,cy,ht=c.left and 4 or 123,c.y+4,HUD_HEIGHT or 0
			cy=max(cy,ht+4)
			local ba=(WARNING_TIME-c.warning_t)*0.15
			for i=0,3 do
				local ang=ba+i*0.25
				pset(flr(cx+cos(ang)*3),flr(cy+sin(ang)*3),i%2==0 and c.c8 or c.c9)
			end
		end
	end

	for p in all(parts) do
		pset(flr(p.x),flr(p.y),p.col)
	end
	
	for c in all(comets) do
		if c.warning_t<=0 then
			spr(c.sid,c.x,c.y,1,1,c.dx<0,c.dy>0)
		end
	end
end