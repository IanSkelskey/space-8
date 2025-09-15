local HOLE_W,HOLE_H,HOLE_HW,HOLE_HH=8,8,4,4
local HOLE_SPD,HOLE_R,HOLE_MAX,HOLE_SPR=0.8,50,2,3
local SPAWN_BASE,SPAWN_RND,SPAWN_DEC=3,3,1/30
local ORPHAN_DAMP,ORPHAN_DRIFT,P_MAXSPD,ORPHAN_MAXSPD=0.65,0.20,1.8,0.6
local SPIN_STEP=8
local P_BASE,P_EXTRA,P_MINR,P_RVAR=1,0.5,2,2
local P_BSPD,P_SVAR,P_RNDVAR,P_KICK=0.45,0.45,0.2,0.08
local P_LIFE,P_LVAR=20,10
local MIN_D2,RAD_GAIN,SWIRL_GAIN,MIN_SWIRL=0.1,0.30,0.80,0.20
local CORE_PROX,OUT_BIAS,VEL_ZERO=2.2,0.20,0.01
local STAR_STR,STAR_SW,ASTEROID_STR,SHIP_TR,SHIP_STR=0.10,0.20,0.35,0.22,0.6
local SCR_W,SCR_H,OFF_Y=128,128,136
local P_BRIGHT,P_DIM,COL_BRIGHT,COL_MID,COL_DIM=16,8,14,2,1

local parts={}

local function pull_bullets(h)
	local pb=ship_get_bullets and ship_get_bullets()
	if not pb then return end
	local cx,cy=h.x+HOLE_HW,h.y+HOLE_HH
	local r2=h.r*h.r
	for b in all(pb) do
		if aabb(b.x,b.y,2,2,h.x,h.y,h.w,h.h) then
			del(pb,b)
		else
			local dx,dy=cx-b.x,cy-b.y
			local d2=dx*dx+dy*dy
			if d2>MIN_D2 and d2<r2 then
				local invd=1/sqrt(d2)
				local fall=1-d2/r2
				local acc=0.25*fall
				b.dx+=dx*invd*acc
				b.dy+=dy*invd*acc
				local sp=sqrt(b.dx*b.dx+b.dy*b.dy)
				if sp>4 then
					local s=4/sp
					b.dx*=s
					b.dy*=s
				end
			end
		end
	end
end

local function spawn_hole()
	local ht=HUD_HEIGHT or 0
	add(holes,{
		x=flr(rnd(SCR_W-HOLE_W)),
		y=ht-10,
		w=HOLE_W,h=HOLE_H,
		spd=HOLE_SPD,
		r=HOLE_R,
		spin_t=0
	})
end

local function spawn_particles(h)
	local cnt=P_BASE+(rnd(1)<P_EXTRA and 1 or 0)
	for i=1,cnt do
		local ang=rnd(1)
		local rad=P_MINR+rnd(P_RVAR)
		local px=h.x+HOLE_HW+cos(ang)*rad
		local py=h.y+HOLE_HH+sin(ang)*rad
		local tx,ty=-sin(ang),cos(ang)
		local spd=P_BSPD+rnd(P_SVAR)
		local vx=tx*spd+(rnd(P_RNDVAR)-P_RNDVAR/2)
		local vy=ty*spd+(rnd(P_RNDVAR)-P_RNDVAR/2)
		vx+=cos(ang)*P_KICK
		vy+=sin(ang)*P_KICK
		add(parts,{x=px,y=py,vx=vx,vy=vy,life=P_LIFE+flr(rnd(P_LVAR))})
	end
end

local function update_particles()
	for p in all(parts) do
		local cx,cy,bestd2,hh
		for h in all(holes) do
			local hx,hy=h.x+HOLE_HW,h.y+HOLE_HH
			local dx,dy=hx-p.x,hy-p.y
			local d2=dx*dx+dy*dy
			if not bestd2 or d2<bestd2 then
				bestd2=d2
				cx,cy=hx,hy
				hh=h
			end
		end
		if cx then
			local dx,dy=cx-p.x,cy-p.y
			local d2=dx*dx+dy*dy
			if d2>MIN_D2 then
				local invd=1/sqrt(d2)
				local r=(hh and hh.r) or 32
				local d=sqrt(d2)
				local fall=1-min(d/r,1)
				local rg=RAD_GAIN*fall
				local sg=SWIRL_GAIN*max(fall,MIN_SWIRL)
				p.vx+=dx*invd*rg
				p.vy+=dy*invd*rg
				local tx,ty=-dy*invd,dx*invd
				p.vx+=tx*sg
				p.vy+=ty*sg
				if d<CORE_PROX then
					p.vx-=dx*invd*OUT_BIAS
					p.vy-=dy*invd*OUT_BIAS
				end
				local sp=sqrt(p.vx*p.vx+p.vy*p.vy)
				if sp>P_MAXSPD then
					local s=P_MAXSPD/sp
					p.vx*=s
					p.vy*=s
				end
			end
		else
			p.vx*=ORPHAN_DAMP
			p.vy*=ORPHAN_DAMP
			local sp=sqrt(p.vx*p.vx+p.vy*p.vy)
			if sp>ORPHAN_MAXSPD then
				local s=ORPHAN_MAXSPD/sp
				p.vx*=s
				p.vy*=s
			end
			p.vy+=ORPHAN_DRIFT
			if abs(p.vx)<VEL_ZERO then p.vx=0 end
			if abs(p.vy)<VEL_ZERO then p.vy=0 end
		end
		p.x+=p.vx
		p.y+=p.vy
		p.life-=1
		if p.life<=0 then del(parts,p) end
	end
end

function blackhole_init()
	holes={}
	parts={}
	spawn_t=0
end

function update_blackhole()
	if not round_number or round_number<5 then return end
	spawn_t-=SPAWN_DEC
	local hm=HOLE_MAX
	if round_number<7 then hm=1 end
	if spawn_t<=0 and #holes<hm then
		spawn_hole()
		local mul=round_number<7 and 1.5 or 1
		spawn_t=(SPAWN_BASE+rnd(SPAWN_RND))*mul
	end

	for h in all(holes) do
		h.y+=h.spd
		h.spin_t=(h.spin_t+1)%(SPIN_STEP*4)

		if moon_debris_pull then
			moon_debris_pull(h.x+HOLE_HW,h.y+HOLE_HH,h.r,MOON_STR)
		end
		if ship_trails_pull then
			ship_trails_pull(h.x+HOLE_HW,h.y+HOLE_HH,h.r,SHIP_TR)
		end
		if asteroid_debris_pull then
			asteroid_debris_pull(h.x+HOLE_HW,h.y+HOLE_HH,h.r,ASTEROID_STR)
		end

		if ship then
			local cx,cy=h.x+HOLE_HW,h.y+HOLE_HH
			local dx,dy=cx-ship.x-ship.w/2,cy-ship.y-ship.h/2
			local d2=dx*dx+dy*dy
			local r2=h.r*h.r
			if d2<r2 and d2>0 then
				local invd=1/sqrt(d2)
				local str=(SHIP_STR*1.25)*(1-d2/r2)
				ship.x+=dx*invd*str
				ship.y+=dy*invd*str
				if ship.x<0 then ship.x=0 end
				if ship.x>SCR_W-ship.w then ship.x=SCR_W-ship.w end
				if ship.y<0 then ship.y=0 end
				if ship.y>SCR_H-ship.h then ship.y=SCR_H-ship.h end
			end

		end

		if ship and aabb(h.x,h.y,h.w,h.h,ship.x,ship.y,ship.w,ship.h) then
			if ship.dying~=true and ship_kill then
				ship.shield_power = 0
				ship.shield_active = false
				ship_kill()
			end
		end

		if h.y>OFF_Y then del(holes,h) end

		if moon_absorb then
			moon_absorb(h.x,h.y,h.w,h.h)
		end
		if ship_trails_absorb then
			ship_trails_absorb(h.x,h.y,h.w,h.h)
		end
		if asteroid_absorb then
			asteroid_absorb(h.x,h.y,h.w,h.h)
		end

		spawn_particles(h)
		pull_bullets(h)
	end

	update_particles()
end

function draw_blackhole()
	for p in all(parts) do
		local c=p.life>P_BRIGHT and COL_BRIGHT or(p.life>P_DIM and COL_MID or COL_DIM)
		pset(flr(p.x),flr(p.y),c)
	end
	for h in all(holes) do

		local ph=flr(h.spin_t/SPIN_STEP)%4
		local fx=(ph==1)or(ph==2)
		local fy=(ph==2)or(ph==3)
		spr(HOLE_SPR,h.x,h.y,1,1,fx,fy)
	end
end