local comets,spawn_t={},0
-- use split strings for ids (cheaper than table literals)
-- arrays align to: pink, yellow, green, blue, red. red drops the bomb powerup (kind 3)
local C8,C9=split"2,10,3,1,8",split"14,9,11,12,2"
-- all comets use the green comet art (angled 198 / straight 200) recoloured by palette swap.
-- the green body ramp is colours 1,2,3,11 (dark->light); RAMPS replaces those per variant.
-- order matches C8/C9: pink, yellow, green, blue, red. yellow tops out at white (7).
-- blue draws with colour 15, which the screen palette remaps to hidden colour 140
-- (see pal(15,140,1) at the end of _draw); colour 15 is otherwise unused.
-- comet body ramps per variant; SRC + setramp moved to particles. red reuses the shared EXR blast.
local RAMPS={split"2,8,14,7",split"4,9,10,7",split"1,3,11,10",split"1,15,12,6",EXR}
-- one colour-keyed powerup drop per variant (pink,yellow,green,blue,red): shard d / odds / life
-- red drops the bomb (kind 3) at low odds; all five entries are now indexed
local DROP_D,DROP_ODDS,DROP_LIFE=split"6,5,1,2,3",split".5,.5,.5,.5,.5",split"150,150,170,140,150"
-- kill a comet: drop + score + start the death animation (shared by bullet hits and black holes)
local function comet_die(c)
	obk+=1 -- round-summary obstacle tally
	local k=c.ci+1
	if rnd()<DROP_ODDS[k] then p_add(c.x,c.y,0,0,DROP_LIFE[k],7,nil,DROP_D[k]) end
	hud_add_score(55) snd_sfx(1)
	boom(c.x,c.y,c.ramp) del(comets,c)
end

function comet_init()
	comets,spawn_t={},0
end

-- explode every comet overlapping a rect (full death). used by the round-clear sweep.
function comet_absorb(hx,hy,hw,hh)
	for c in all(comets) do
		if aabb(c.x,c.y,8,8,hx,hy,hw,hh) then comet_die(c) end
	end
end

-- bend live comets' trajectories toward a gravity well (called by the black hole)
function comet_pull(cx,cy,r,str)
	local r2=r*r
	for c in all(comets) do
		local dx,dy=cx-c.x-4,cy-c.y-4 local d2=dx*dx+dy*dy
		if d2<36 then comet_die(c) -- swallowed: spawn explosion + remove
		elseif d2<r2 then
			local invd,acc=1/sqrt(d2),str*(1-d2/r2) c.dx+=dx*invd*acc c.dy+=dy*invd*acc
			capv(c,3)
		end
	end
end

local function spawn_comet()
	local left=rnd()<0.5
	local x,y=left and -8 or 128,10+flr(rnd(110))
	local base_angles=left and split"0.125,0,0.875" or split"0.375,0.5,0.625"
	local ang,spd,i=base_angles[flr(rnd(3))+1]+(rnd()-0.5)*0.08,1.2+rnd(0.9),flr(rnd(5))
	add(comets,{
		x=x,y=y,
		dx=cos(ang)*spd,dy=sin(ang)*spd,
		c8=C8[i+1],c9=C9[i+1],
		ramp=RAMPS[i+1],ci=i,
		warning_t=20,
		left=left,
		hp=2,flash=0
	})
end

function update_comet()
	if round_number<3 then return end
	spawn_t-=FT
	local mx,mi,rg=cm,cmin,crng
	if round_number<5 then mx=min(mx,1) end
	if spawn_t<=0 and #comets<mx then
		spawn_comet()
		spawn_t=(mi+rnd(rg))*(round_number<5 and 1.5 or 1)
	end

	for c in all(comets) do
		-- pre-warning skip
		if c.warning_t>0 then c.warning_t-=1 goto continue end
		-- bomb shockwave or shield pulse: shared damage/death check
		if eaoe(c,comet_die,c.x+4,c.y+4) then goto continue end
		-- movement
		c.x+=c.dx*cs c.y+=c.dy*cs
		if c.flash>0 then c.flash-=1 end
		-- trail: a couple of colour particles drifting opposite the (speed-capped) velocity
		for i=1,rnd()<0.4 and 2 or 1 do
			p_add(c.x+3+rnd(2),c.y+3+rnd(2),-c.dx*0.2,-c.dy*0.2,18+rndi(10),5,rnd()<0.5 and c.c8 or c.c9)
		end
		if hit_by_player_bullet(c.x,c.y,8,8) then
			c.hp-=1
			if c.hp<=0 then comet_die(c) goto continue
			else c.flash=4 end
		end
		if c.hp>0 then if scoll(c.x,c.y,8,8) then ship_kill() end if c.x<-12 or c.x>140 or c.y<-12 or c.y>140 then del(comets,c) end end
		::continue::
	end
end

function draw_comet()
	for c in all(comets) do
		if c.warning_t>0 then
			local cx,cy=c.left and 4 or 123,max(c.y+4,14)
			h(cx,cy,(20-c.warning_t)*0.15,c.c8,c.c9)
		else
			-- orientation from CURRENT velocity (gravity bends the path): angled if neither axis dominates by >2.4x
			local ax,ay=abs(c.dx),abs(c.dy)
			local angled=ax*2.414>ay and ay*2.414>ax
			local vert=ay>ax  -- vertical-dominant heading (only reached when not angled)
			-- 2-frame flight anim; base sprite by orientation: angled 198 / vertical 196 / horizontal 200
			local sid,flash=(angled and 198 or(vert and 196 or 200))+flr(t()*6+c.x)%2,c.flash>0
			-- per-object hit shake: jitter the draw position +-1px while flashing
			local cx,cy=c.x,c.y
			if flash then fl(7) cx+=jit() cy+=jit()
			else setramp(c.ramp) end
			-- one spr for every orientation: flip_x by horizontal heading; flip_y points
			-- the up-drawn angled/vertical art downward when c.dy>0 (horizontal art never
			-- v-flips). flash whiteout handled by fl(7) above.
			spr(sid,cx,cy,1,1,c.dx<0,(angled or vert)and c.dy>0)
			pal()
		end
	end
end
