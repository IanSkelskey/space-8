local comets,parts,spawn_t={},{},0
local SIDS_ANGLED={48,49,50,51,52}  -- diagonal sprites
local SIDS_STRAIGHT={59,60,61,62,63} -- horizontal/vertical sprites
local WARNING_TIME=20
local SWAPS={{8,9},{2,14},{10,9},{3,11},{1,12}}

function comet_init()
	comets,parts,spawn_t={},{},0
end

local function spawn_comet()
	local left,x,y=rnd()<0.5,0,(HUD_HEIGHT or 0)+flr(rnd(120-(HUD_HEIGHT or 0)))
	x=left and -8 or 128
	
	-- More varied angles: pick from 8 directions with some randomness
	local base_angles = left and {0.125, 0, 0.875} or {0.375, 0.5, 0.625}
	local ang = base_angles[flr(rnd(#base_angles))+1] + (rnd()-0.5)*0.08
	
	local spd=1.2+rnd(0.9)
	local i=flr(rnd(#SWAPS))
	
	-- Determine if angle is closer to diagonal or perpendicular
	-- Normalize angle to 0-1 range then to 0-0.5 (since we have symmetry)
	local norm_ang = ang % 0.25
	local use_angled = norm_ang > 0.0625 and norm_ang < 0.1875
	
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