local comets,spawn_t,SIDS_ANGLED,SIDS_STRAIGHT,WARNING_TIME,SWAPS={},0,{43,44,45,46,47},{59,60,61,62,63},20,{{8,9},{2,14},{10,9},{3,11},{1,12}}

function comet_init()
	comets,spawn_t={},0
end

local function spawn_comet()
	local left=rnd()<0.5
	local x,y=left and -8 or 128,HUD_HEIGHT+flr(rnd(120-HUD_HEIGHT))
	local base_angles=left and {0.125,0,0.875} or {0.375,0.5,0.625}
	local ang,spd,i=base_angles[flr(rnd(#base_angles))+1]+(rnd()-0.5)*0.08,1.2+rnd(0.9),flr(rnd(#SWAPS))
	local norm_ang=ang%0.25
	local use_angled=norm_ang>0.0625 and norm_ang<0.1875
	
	add(comets,{
		x=x,y=y,w=8,h=8,
		dx=cos(ang)*spd,dy=sin(ang)*spd,
		c8=SWAPS[i+1][1],c9=SWAPS[i+1][2],
		sid=use_angled and SIDS_ANGLED[i+1] or SIDS_STRAIGHT[i+1],
		use_angled=use_angled,
		warning_t=WARNING_TIME,
		left=left
	})
end

function update_comet()
	if round_number<3 then return end
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

		c.x+=c.dx*cs
		c.y+=c.dy*cs

		local spd=sqrt(c.dx*c.dx+c.dy*c.dy)
		local ux,uy=spd>0 and c.dx/spd or 0,spd>0 and c.dy/spd or 0
		for i=1,rnd()<0.4 and 2 or 1 do
			local col=rnd()<0.5 and c.c8 or c.c9
			p_add(c.x+4-ux*2+rnd()-0.5,c.y+4-uy*2+rnd()-0.5,-ux*(0.2+rnd(0.2))+rnd(0.1)-0.05,-uy*(0.2+rnd(0.2))+rnd(0.1)-0.05,18+flr(rnd(10)),PT_COMET,col)
		end

		if not c.warning and aabb(c.x,c.y,c.w,c.h,ship.x,ship.y,ship.w,ship.h) then
			ship_kill()
		end

		if c.x<-12 or c.x>140 or c.y<-12 or c.y>140 then del(comets,c) end
		::continue::
	end
end

function draw_comet()
	for c in all(comets) do
		if c.warning_t>0 then
			local cx,cy,ht=c.left and 4 or 123,c.y+4,HUD_HEIGHT
			cy=max(cy,ht+4)
			local ba=(WARNING_TIME-c.warning_t)*0.15
			for i=0,3 do
				local ang=ba+i*0.25
				pset(flr(cx+cos(ang)*3),flr(cy+sin(ang)*3),i%2==0 and c.c8 or c.c9)
			end
		end
	end

	-- Comet particles now drawn by particle system
	
	for c in all(comets) do
		if c.warning_t<=0 then
			if c.use_angled then
				-- Use diagonal sprite with flipping based on direction
				spr(c.sid,c.x,c.y,1,1,c.dx<0,c.dy>0)
			else
				-- Use straight sprite with rotation based on primary direction
				local ax,ay=abs(c.dx),abs(c.dy)
				if ax > ay then
					-- Horizontal movement - use sprite as-is or flipped
					spr(c.sid,c.x,c.y,1,1,c.dx<0,false)
				else
					-- Vertical movement - rotate sprite 90 degrees
					-- We'll need to draw it rotated
					local cx,cy=c.x+4,c.y+4
					for px=0,7 do
						for py=0,7 do
							local col=sget(c.sid%16*8+px,flr(c.sid/16)*8+py)
							if col!=0 then
								-- Rotate 90 degrees: (x,y) -> (y,7-x) for downward
								-- or (7-y,x) for upward
								if c.dy>0 then
									pset(c.x+py,c.y+7-px,col)
								else
									pset(c.x+7-py,c.y+px,col)
								end
							end
						end
					end
				end
			end
		end
	end
end