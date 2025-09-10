local SCR_W,SCR_H,SHIP_W,SHIP_H=128,128,8,8
local SPR_SHIP,SPR_LEAN,SHIP_SPD,SHIP_ACC=1,4,2.0,0.12
local START_X,START_Y=SCR_W/2-SHIP_W/2,flr((SCR_H*2)/3 - SHIP_H/2)
local LASER={SPEED=2,SFX=0,COOLDOWN=15,CHANNEL=2}
local OFF_MIN,OFF_MAX,FACE_EPS=-4,132,0.05
local EXH={NL=2,NR=3,BDY=0.5,DYS=0.9,LMIN=6,LR=10,XJ=1,DXJ=0.6,DXR=0.3,DYR=0.4,CY=10,CO=9,CR=8}
local THRUST={H=0.6,I=0.2,D=0.03,U=0.45}
local DEATH_FR=45
local SHIELD={MAX=100,DRAIN=0.5,RECHARGE=1.0,MIN=10,RAD=10,COLS={12,13,1},HIT=15,INVULN=30,CH=3,SFX_ON=30,SFX_HIT=31,SFX_OFF=32}

ship=ship or{x=START_X,y=START_Y,w=SHIP_W,h=SHIP_H,spr=1,spd=SHIP_SPD,flipx=false,vx=0,vy=0,acc=SHIP_ACC,dying=false,death_t=0,shield_active=false,shield_power=0,shield_anim=0,shield_invuln=0,laser_cd=0,fire_rate_level=0,spread_level=0,shield_unlocked=false}

local bullets,exhaust,death_fx={},{},{}

local function spawn_laser()
	local spd=LASER.SPEED
	local cx,by=flr(ship.x+ship.w/2)-1,ship.y-2
	local iv=ship.vx*0.3
	local lvl=ship.spread_level or 0
	local sdx=lvl>1 and 0.7 or 0
	if lvl~=1 then add(bullets,{x=cx,y=by,dx=iv,dy=-spd}) end
	if lvl>=1 then
		add(bullets,{x=cx-1,y=by,dx=iv-sdx,dy=-spd})
		add(bullets,{x=cx+1,y=by,dx=iv+sdx,dy=-spd})
	end
	sfx(LASER.SFX,LASER.CHANNEL)
end

local function laser_cooldown()
	local lvl=ship.fire_rate_level or 0
	local eff=flr(LASER.COOLDOWN*(1-0.2*lvl)+0.5)
	if eff<3 then eff=3 end
	return eff
end

local function spawn_exhaust(str)
	str=mid(0,str or 1,1)
	if str<=0 then return end
	local y=ship.y+ship.h
	local x1,x2=ship.x+EXH.NL,ship.x+ship.w-EXH.NR
	local bdy=EXH.BDY+EXH.DYS*str
	local life=flr(EXH.LMIN+EXH.LR*str)
	if rnd(1)<str then
		add(exhaust,{x=x1+rnd(EXH.XJ)-0.5,y=y,dx=(rnd(EXH.DXJ)-EXH.DXR)*str,dy=bdy+rnd(EXH.DYR*str),life=life})
	end
	if rnd(1)<str then
		add(exhaust,{x=x2+rnd(EXH.XJ)-0.5,y=y,dx=(rnd(EXH.DXJ)-EXH.DXR)*str,dy=bdy+rnd(EXH.DYR*str),life=life})
	end
end

local function update_exhaust()
	for p in all(exhaust) do
		p.x+=p.dx
		p.y+=p.dy
		p.life-=1
		if p.life<=0 or p.y>OFF_MAX then del(exhaust,p) end
	end
end

local function spawn_death_fx()
	for i=1,22 do
		local a=rnd(1)
		local sp=0.7+rnd(1.3)
		add(death_fx,{x=ship.x+ship.w/2,y=ship.y+ship.h/2,dx=cos(a)*sp,dy=sin(a)*sp,life=flr(10+rnd(20))})
	end
end

function ship_kill()
	if ship.dying then return end
	sfx(-1,SHIELD.CH)
	if ship.shield_invuln>0 then return end
	if ship.shield_active then
		ship.shield_power=max(0,ship.shield_power-SHIELD.HIT)
		ship.shield_invuln=SHIELD.INVULN
		ship.shield_anim=0
		sfx(SHIELD.SFX_HIT,3)
		if ship.shield_power<=0 then
			ship.shield_active=false
			sfx(-1,SHIELD.CH)
			sfx(SHIELD.SFX_OFF,3)
		end
		return
	end
	ship.dying=true
	ship.death_t=0
	ship.vx,ship.vy=0,0
	exhaust={}
	death_fx={}
	spawn_death_fx()
	sfx(1,3)
	game_state="dying"
end

function ship_death_done() return ship.dying and ship.death_t>=DEATH_FR end

function ship_init()
bullets,exhaust,death_fx={},{},{}
ship.x,ship.y=START_X,START_Y
ship.vx,ship.vy=0,0
ship.dying=false
ship.death_t=0
ship.shield_active=false
ship.shield_anim=0
ship.shield_invuln=0
-- if shield is unlocked, refill; otherwise keep power at 0
ship.shield_power = ship.shield_unlocked and SHIELD.MAX or 0
ship.laser_cd=0
sfx(-1,SHIELD.CH)
end

local function update_death_fx()
	for p in all(death_fx) do
		p.x+=p.dx
		p.y+=p.dy
		p.dx*=0.98
		p.dy*=0.98
		p.life-=1
		if p.life<=0 then del(death_fx,p) end
	end
end

function update_ship()
	if ship.dying then
		ship.death_t+=1
		update_death_fx()
		for b in all(bullets) do
			b.x+=b.dx
			b.y+=b.dy
			if b.x<OFF_MIN or b.x>OFF_MAX or b.y<OFF_MIN or b.y>OFF_MAX then del(bullets,b) end
		end
		return
	end

	local dx,dy=0,0
	if btn(0) then dx-=1 end
	if btn(1) then dx+=1 end
	if btn(2) then dy-=1 end
	if btn(3) then dy+=1 end
	local rdx,rdy=dx,dy
	local mag=sqrt(dx*dx+dy*dy)
	if mag>0 then dx/=mag dy/=mag end
	if ship.vx<-FACE_EPS or(ship.vx==0 and dx<0)then ship.flipx=true end
	if ship.vx>FACE_EPS or(ship.vx==0 and dx>0)then ship.flipx=false end
	local tx,ty=dx*ship.spd,dy*ship.spd
	ship.vx+=mid(-ship.acc,tx-ship.vx,ship.acc)
	ship.vy+=mid(-ship.acc,ty-ship.vy,ship.acc)
	ship.x+=ship.vx
	ship.y+=ship.vy
	local ht=HUD_HEIGHT or 0
	local minx,maxx,miny,maxy=0,SCR_W-ship.w,ht,SCR_H-ship.h
	if ship.x<minx then ship.x=minx if ship.vx<0 then ship.vx=0 end end
	if ship.x>maxx then ship.x=maxx if ship.vx>0 then ship.vx=0 end end
	if ship.y<miny then ship.y=miny if ship.vy<0 then ship.vy=0 end end
	if ship.y>maxy then ship.y=maxy if ship.vy>0 then ship.vy=0 end end
	local str=THRUST.H
	if rdx==0 and rdy==0 then str=THRUST.I
	elseif rdy>0 then str=THRUST.D
	elseif rdy<0 then str=THRUST.U end
	spawn_exhaust(str)
	if ship.laser_cd>0 then ship.laser_cd-=1 end
	if ship.laser_cd<=0 and btn(4) then
		spawn_laser()
		ship.laser_cd=laser_cooldown()
	end
	for b in all(bullets) do
		b.x+=b.dx
		b.y+=b.dy
		if b.x<OFF_MIN or b.x>OFF_MAX or b.y<OFF_MIN or b.y>OFF_MAX then del(bullets,b) end
	end
	update_exhaust()
	if ship.shield_invuln>0 then ship.shield_invuln-=1 end
	if ship.shield_unlocked then
		if btn(5)and ship.shield_power>=SHIELD.MIN and not ship.dying then
			if not ship.shield_active then
				ship.shield_active=true
				sfx(SHIELD.SFX_ON,SHIELD.CH)
			end
			ship.shield_power=max(0,ship.shield_power-SHIELD.DRAIN)
			if ship.shield_power<=0 then
				ship.shield_active=false
				sfx(-1,SHIELD.CH)
				sfx(SHIELD.SFX_OFF,3)
			end
		else
			if ship.shield_active then
				ship.shield_active=false
				sfx(-1,SHIELD.CH)
			end
			if ship.shield_power<SHIELD.MAX and ship.shield_invuln<=0 then
				ship.shield_power=min(SHIELD.MAX,ship.shield_power+SHIELD.RECHARGE)
			end
		end
	else
		if ship.shield_active then
			ship.shield_active=false
			sfx(-1,SHIELD.CH)
		end
		ship.shield_power=0
	end
	if ship.shield_active then ship.shield_anim=(ship.shield_anim+1)%30 end
end

function draw_ship()
	for p in all(exhaust) do
		local c=p.life>8 and EXH.CY or(p.life>4 and EXH.CO or EXH.CR)
		pset(flr(p.x),flr(p.y),c)
	end
	if ship.dying then
		for p in all(death_fx) do
			local c=p.life>16 and 10 or(p.life>8 and 9 or 8)
			pset(flr(p.x),flr(p.y),c)
		end
	else
		local sid,flip=SPR_SHIP,false
		if abs(ship.vx)>FACE_EPS then
			sid=SPR_LEAN
			flip=ship.vx>0
		end
		spr(sid,ship.x,ship.y,1,1,flip,false)
	end
	for b in all(bullets) do
		local x,y=flr(b.x),flr(b.y)
		pset(x,y,9)
		pset(x,y-1,8)
	end
	if ship.shield_active and not ship.dying then
		local cx,cy=ship.x+ship.w/2,ship.y+ship.h/2
		local t=ship.shield_anim/30
		local vis=true
		local flash=nil
		if ship.shield_invuln>0 then
			vis=(ship.shield_invuln%4)<2
			flash=ship.shield_invuln>25 and 7 or nil
		end
		if vis then
			for i=1,3 do
				local r=SHIELD.RAD-i+sin(t+i*0.2)*2
				local c=flash or SHIELD.COLS[i]
				circ(cx,cy,r,c)
			end
		end
	end
end

function ship_get_bullets() return bullets end

function ship_unlock_shield()
	ship.shield_unlocked=true
	ship.shield_power=SHIELD.MAX
end

function ship_reset_upgrades()
	ship.fire_rate_level=0
	ship.spread_level=0
	ship.shield_unlocked=false
	ship.shield_power=0
end

function ship_trails_pull(cx,cy,r,str)
	local r2=r*r
	local function pull(lst)
		if not lst then return end
		for p in all(lst) do
			local dx,dy=cx-p.x,cy-p.y
			local d2=dx*dx+dy*dy
			if d2>0.5 and d2<r2 then
				local invd=1/sqrt(d2)
				local fall=1-d2/r2
				local acc=str*fall
				p.dx+=dx*invd*acc
				p.dy+=dy*invd*acc
			end
		end
	end
	pull(exhaust)
	if death_fx then pull(death_fx) end
end

function ship_trails_absorb(hx,hy,hw,hh)
	local function absorb(lst)
		if not lst then return end
		for p in all(lst) do
			if p.x>=hx and p.x<hx+hw and p.y>=hy and p.y<hy+hh then del(lst,p) end
		end
	end
	absorb(exhaust)
	if death_fx then absorb(death_fx) end
end
