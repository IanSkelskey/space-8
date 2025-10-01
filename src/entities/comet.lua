local comets,spawn_t={},0
-- use split strings for ids (cheaper than table literals)
local SIDS_ANGLED,SIDS_STRAIGHT=split"43,44,45,46,47",split"59,60,61,62,63"
local C8,C9=split"8,2,10,3,1",split"9,14,9,11,12"

function comet_init()
	comets,spawn_t={},0
end

local function spawn_comet()
	local left=rnd()<0.5
	local x,y=left and -8 or 128,10+flr(rnd(120-10))
	local base_angles=left and {0.125,0,0.875} or {0.375,0.5,0.625}
	local ang,spd,i=base_angles[flr(rnd(#base_angles))+1]+(rnd()-0.5)*0.08,1.2+rnd(0.9),flr(rnd(#C8))
	local norm_ang=ang%0.25
	local use_angled=norm_ang>0.0625 and norm_ang<0.1875
	
	add(comets,{
		x=x,y=y,w=8,h=8,
		dx=cos(ang)*spd,dy=sin(ang)*spd,
		c8=C8[i+1],c9=C9[i+1],
		sid=use_angled and SIDS_ANGLED[i+1] or SIDS_STRAIGHT[i+1],
		use_angled=use_angled,
		warning_t=20,
		left=left,
		hp=2,flash_t=0
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
		if c.warning_t>0 then c.warning_t-=1 goto continue end
		c.x+=c.dx*cs c.y+=c.dy*cs
		if c.flash_t>0 then c.flash_t-=1 end
		local spd=c.dx*c.dx+c.dy*c.dy
		local ux,uy=0,0
		if spd>0 then local s=sqrt(spd) ux,uy=c.dx/s,c.dy/s end
		for i=1,rnd()<0.4 and 2 or 1 do
			local col=rnd()<0.5 and c.c8 or c.c9
			p_add(c.x+4-ux*2+rnd()-0.5,c.y+4-uy*2+rnd()-0.5,-ux*(0.2+rnd(0.2))+rnd(0.1)-0.05,-uy*(0.2+rnd(0.2))+rnd(0.1)-0.05,18+rnd(10)\1,5,col)
		end
		for b in all(bullets) do
			if aabb(c.x,c.y,8,8,b.x,b.y,2,2) then
				del(bullets,b) c.hp-=1
				if c.hp<=0 then
					local cx,cy=c.x+4,c.y+4
					p_add(cx,cy,0,0,10,1,7)
					for i=1,10 do local a=rnd() local sp=rnd(1.3) p_add(cx,cy,cos(a)*sp,sin(a)*sp,12+rnd(10)\1,5,(i%2==0 and c.c8 or c.c9)) end
					-- reduced drop rates: fewer free survivability resources
					local green=(c.c8==3 or c.c9==11)
					local blue=(c.c9==12)
					if green and rnd()<0.18 then p_add(c.x,c.y,0,0,170,7) end
					if blue and rnd()<0.14 then p_add(c.x,c.y,0,0,140,7,nil,true) end
						hud_add_score(55) snd_sfx(SFX_EXPLODE) del(comets,c) break
				else c.flash_t=4 end
				break
			end
		end
		if c.hp>0 then if scoll(c.x,c.y,c.w,c.h) then ship_kill() end if c.x<-12 or c.x>140 or c.y<-12 or c.y>140 then del(comets,c) end end
		::continue::
	end
end

function draw_comet()
	for c in all(comets) do
		if c.warning_t>0 then
			local cx,cy,ht=c.left and 4 or 123,c.y+4,10
			cy=max(cy,ht+4)
			local ba=(20-c.warning_t)*0.15
			for i=0,3 do
				local ang=ba+i*0.25
				pset(flr(cx+cos(ang)*3),flr(cy+sin(ang)*3),i%2==0 and c.c8 or c.c9)
			end
		else
			local sid=c.sid
			if c.flash_t>0 then sid=c.use_angled and 35 or 51 end
			if c.use_angled then
				spr(sid,c.x,c.y,1,1,c.dx<0,c.dy>0)
			elseif abs(c.dx)>abs(c.dy) then
				spr(sid,c.x,c.y,1,1,c.dx<0,false)
			else
				local sx,sy=sid%16*8,flr(sid/16)*8
				for px=0,7 do
					for py=0,7 do
						local col=sget(sx+px,sy+py)
						if col!=0 then
							if c.dy>0 then pset(c.x+py,c.y+7-px,col) else pset(c.x+7-py,c.y+px,col) end
						end
					end
				end
			end
		end
	end
end