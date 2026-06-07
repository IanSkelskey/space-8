local comets,spawn_t={},0
-- use split strings for ids (cheaper than table literals)
-- removed red comet variant (first entries) since it had no drop; arrays now align to: pink, yellow, green, blue
local C8,C9=split"2,10,3,1",split"14,9,11,12"
-- all comets use the green comet art (angled 46 / straight 62) recoloured by palette swap.
-- the green body ramp is colours 1,2,3,11 (dark->light); RAMPS replaces those per variant.
-- order matches C8/C9: pink, yellow, green, blue. yellow tops out at white (7).
-- blue draws with colour 15, which the screen palette remaps to hidden colour 140
-- (see pal(15,140,1) at the end of _draw); colour 15 is otherwise unused.
local SRC=split"1,2,3,11"
local RAMPS={split"2,8,14,7",split"4,9,10,7",split"1,3,11,10",split"1,15,12,6"}
-- one colour-keyed powerup drop per variant (pink,yellow,green,blue): shard d / odds / life
local DROP_D,DROP_ODDS,DROP_LIFE=split"6,5,1,2",split".2,.17,.05,.14",split"150,150,170,140"
-- apply a variant's ramp to the draw palette (call pal() to reset afterwards)
local function setramp(rp) for k=1,4 do pal(SRC[k],rp[k]) end end

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
		x=x,y=y,
		dx=cos(ang)*spd,dy=sin(ang)*spd,
		c8=C8[i+1],c9=C9[i+1],
		ramp=RAMPS[i+1],ci=i,
		sid=use_angled and 198 or 200,
		use_angled=use_angled,
		warning_t=20,
		left=left,
		hp=2,flash_t=0
	})
end

function update_comet()
	if round_number<3 then return end
	spawn_t-=FT
	local mx,mi,rg=cm or 3,cmin or 1,crng or 1.2
	if round_number<5 then mx=min(mx,1) end
	if spawn_t<=0 and #comets<mx then
		spawn_comet()
		spawn_t=(mi+rnd(rg))*(round_number<5 and 1.5 or 1)
	end

	local kill_lvl=ship.shield_pulse_level
	local sr=(ship.shield_active and kill_lvl>0) and (10+kill_lvl) or 0
	for c in all(comets) do
		-- death animation: flash the hit sprite (death_t<3), then a 6-frame explosion (3 frames each), then remove
		if c.dying then
			c.death_t+=1
			-- coast along the comet's trajectory, decelerating, so the blast drifts then settles
			c.x+=c.dx*cs c.y+=c.dy*cs
			c.dx*=0.85 c.dy*=0.85
			if c.death_t>=21 then del(comets,c) end
			goto continue
		end
		-- pre-warning skip
		if c.warning_t>0 then c.warning_t-=1 goto continue end
		-- retaliation splash
		if ship.shield_retaliate_t>0 then
		 local dx=c.x+4-(ship.x+4) local dy=c.y+4-(ship.y+4)
		 if dx*dx+dy*dy <= ship.shield_retaliate_r*ship.shield_retaliate_r then
		  c.hp-=1 c.flash_t=4
		 end
		end
		-- shield shock threshold kill (no continuous damage accumulation)
		if sr>0 and c.flash_t==0 then
		 local dx=c.x+4-(ship.x+4) local dy=c.y+4-(ship.y+4)
		 if dx*dx+dy*dy <= sr*sr and c.hp<=kill_lvl then
		  c.hp=0 c.flash_t=4
		 end
		end
		-- movement
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
			if aabb(c.x,c.y,8,8,b.x,b.y,5,5) then
				del(bullets,b) c.hp-=1
				if c.hp<=0 then
					-- single colour-keyed drop (green=hull repair d1, blue d2, yellow d5, pink d6)
					local k=c.ci+1
					if rnd()<DROP_ODDS[k] then p_add(c.x,c.y,0,0,DROP_LIFE[k],7,nil,DROP_D[k]) end
					hud_add_score(55) snd_sfx(1)
					c.dying,c.death_t,c.fx,c.fy=true,0,rnd()<.5,rnd()<.5 goto continue
				else c.flash_t=4 end
				break
			end
		end
		if c.hp>0 then if scoll(c.x,c.y,8,8) then ship_kill() end if c.x<-12 or c.x>140 or c.y<-12 or c.y>140 then del(comets,c) end end
		::continue::
	end
end

function draw_comet()
	for c in all(comets) do
		if c.dying and c.death_t>=3 then
			-- 6-frame explosion (8x8) starting at tile 202, held 3 game-frames each
			local f=(c.death_t-3)\3
			if f<6 then setramp(c.ramp) spr(202+f,c.x,c.y,1,1,c.fx,c.fy) pal() end
		elseif c.warning_t>0 then
			local cx,cy=c.left and 4 or 123,max(c.y+4,14)
			h(cx,cy,(20-c.warning_t)*0.15,c.c8,c.c9)
		else
			-- hit flash via palette whiteout; dying<3 frames force-flashes the hit sprite before the boom
			-- 2-frame flight anim: +0/+1 from the base sprite, desynced per comet via c.x
			local sid,flash=c.sid+flr(t()*6+c.x)%2,c.flash_t>0 or c.dying
			-- per-object hit shake: jitter the draw position +-1px while flashing
			local jx,jy=0,0
			if flash then for i=1,15 do pal(i,7) end jx=rnd(3)\1-1 jy=rnd(3)\1-1
			else setramp(c.ramp) end
			local cx,cy=c.x+jx,c.y+jy
			if c.use_angled then
				spr(sid,cx,cy,1,1,c.dx<0,c.dy>0)
			elseif abs(c.dx)>abs(c.dy) then
				spr(sid,cx,cy,1,1,c.dx<0,false)
			else
				-- rotated branch draws pixel-by-pixel; tint to white inline when flashing
				local sx,sy=sid%16*8,flr(sid/16)*8
				for px=0,7 do
					for py=0,7 do
						local col=sget(sx+px,sy+py)
						if col!=0 then
							if c.dy>0 then pset(cx+py,cy+7-px,flash and 7 or col) else pset(cx+7-py,cy+px,flash and 7 or col) end
						end
					end
				end
			end
			pal()
		end
	end
end
