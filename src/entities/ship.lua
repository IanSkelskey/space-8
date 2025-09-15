local SCR_W,SCR_H,SHIP_W,SHIP_H=128,128,8,8
local SPR_SHIP,SPR_LEAN,SHIP_SPD,SHIP_ACC=1,4,2.1,0.18
local START_X,START_Y=SCR_W/2-SHIP_W/2,flr((SCR_H*2)/3 - SHIP_H/2)
local L={SPEED=2,SFX=62,COOLDOWN=15,CHANNEL=2}
local OFF_MIN,OFF_MAX,FACE_EPS=-4,132,0.05
local X={NL=2,NR=3,BDY=0.5,DYS=0.9,LMIN=6,LR=10,XJ=1,DXJ=0.6,DXR=0.3,DYR=0.4,CY=10,CO=9,CR=8}
local T={H=0.6,I=0.2,D=0.03,U=0.45}
local DEATH_FR=45
local SH={MAX=100,MIN=10,RAD=10,COLS={12,13,1},INVULN=30,CH=3,SFX_ON=30,SFX_HIT=31,SFX_OFF=43,COOL=60}
local HULL={MAX=2,INVULN=60}

ship=ship or{x=START_X,y=START_Y,w=SHIP_W,h=SHIP_H,spr=1,spd=SHIP_SPD,flipx=false,vx=0,vy=0,acc=SHIP_ACC,dying=false,death_t=0,shield_active=false,shield_power=0,shield_anim=0,shield_invuln=0,shield_cool=0,shield_level=0,laser_cd=0,fire_rate_level=0,spread_level=0,shield_unlocked=false,hull=HULL.MAX,hull_invuln=0,hull_level=0,thruster_level=0}

local bullets,exhaust,death_fx={},{},{}

local function sh_stats()
 local l=ship.shield_level or 0
 if l<=1 then return 1.0,0.7,22 end
 if l==2 then return 0.6,0.9,18 end
 return 0.4,1.2,12
end

local function spawn_laser()
	local spd=L.SPEED
	local cx,by=flr(ship.x+ship.w/2)-1,ship.y-2
	local iv=ship.vx*0.3
	local lvl=ship.spread_level or 0
	local sdx=lvl>1 and 0.7 or 0
	if lvl~=1 then add(bullets,{x=cx,y=by,dx=iv,dy=-spd}) end
	if lvl>=1 then
		add(bullets,{x=cx-1,y=by,dx=iv-sdx,dy=-spd})
		add(bullets,{x=cx+1,y=by,dx=iv+sdx,dy=-spd})
	end
	snd_sfx(SFX_LASER,LASER_CH)
end

-- replace duplicate bullet loops with a helper
local function upd_bullets()
	for b in all(bullets) do
		b.x+=b.dx b.y+=b.dy
		if b.x<OFF_MIN or b.x>OFF_MAX or b.y<OFF_MIN or b.y>OFF_MAX then del(bullets,b) end
	end
end

local function spawn_exhaust(str)
	str=mid(0,str or 1,1)
	if str<=0 then return end
	local y=ship.y+ship.h
	local x1,x2=ship.x+X.NL,ship.x+ship.w-X.NR
	local bdy=X.BDY+X.DYS*str
	local life=flr(X.LMIN+X.LR*str)
	-- two jets, same payload
	for i=1,2 do
		if rnd(1)<str then
			local x=(i==1 and x1 or x2)+rnd(X.XJ)-0.5
			add(exhaust,{x=x,y=y,dx=(rnd(X.DXJ)-X.DXR)*str,dy=bdy+rnd(X.DYR*str),life=life})
		end
	end
end

local function ship_break_shield()
	ship.shield_active,ship.shield_cool,ship.shield_invuln,ship.shield_anim=false,SH.COOL,SH.INVULN,0
	snd_stop_sfx(FX_CH) snd_sfx(SFX_SHIELD_OFF,FX_CH)
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
	snd_stop_sfx(FX_CH)
	if ship.shield_invuln>0 or ship.hull_invuln>0 then return end
	if ship.shield_active then
		local _,_,hit=sh_stats()
		ship.shield_power = max(0, ship.shield_power - hit)
		ship.shield_invuln = SH.INVULN
		ship.shield_anim = 0
		snd_sfx(SFX_SHIELD_HIT,FX_CH)
		if ship.shield_power <= 0 then
			ship_break_shield()
		end
		return
	end
	-- hull damage
	ship.hull-=1
	ship.hull_invuln=HULL.INVULN
	snd_sfx(SFX_EXPLODE,FX_CH)
	if ship.hull<=0 then
		ship.dying=true
		ship.death_t=0
		ship.vx,ship.vy=0,0
		exhaust={}
		death_fx={}
		spawn_death_fx()
		game_state="dying"
	end
end

function ship_death_done() return ship.dying and ship.death_t>=DEATH_FR end

function ship_init()
	bullets,exhaust,death_fx={},{},{}
	ship.x,ship.y,ship.vx,ship.vy=START_X,START_Y,0,0
	ship.dying,ship.death_t=false,0
	ship.shield_active,ship.shield_anim,ship.shield_invuln,ship.shield_cool=false,0,0,0
	ship.shield_power=ship.shield_unlocked and SH.MAX or 0
	ship.laser_cd=0
	-- Don't reset hull here - it persists between rounds
	-- ship.hull=ship_get_max_hull()
	ship.hull_invuln=0
	snd_stop_sfx(FX_CH)
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
		upd_bullets()
		return
	end
	
	if ship.hull_invuln>0 then ship.hull_invuln-=1 end

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
	-- Apply thruster boost to acceleration
	local thr_boost=1+0.15*(ship.thruster_level or 0)
	local eff_acc=ship.acc*thr_boost
	ship.vx+=mid(-eff_acc,tx-ship.vx,eff_acc)
	ship.vy+=mid(-eff_acc,ty-ship.vy,eff_acc)
	ship.x+=ship.vx
	ship.y+=ship.vy
	local ht=HUD_HEIGHT or 0
	local minx,maxx,miny,maxy=0,SCR_W-ship.w,ht,SCR_H-ship.h
	if ship.x<minx then ship.x=minx if ship.vx<0 then ship.vx=0 end end
	if ship.x>maxx then ship.x=maxx if ship.vx>0 then ship.vx=0 end end
	if ship.y<miny then ship.y=miny if ship.vy<0 then ship.vy=0 end end
	if ship.y>maxy then ship.y=maxy if ship.vy>0 then ship.vy=0 end end
	local str=T.H
	if rdx==0 and rdy==0 then str=T.I
	elseif rdy>0 then str=T.D
	elseif rdy<0 then str=T.U end
	spawn_exhaust(str)

	if ship.laser_cd>0 then ship.laser_cd-=1 end
	if ship.laser_cd<=0 and btn(4) then
		spawn_laser()
		-- inline cooldown: min 3 frames
		local lvl=ship.fire_rate_level or 0
		local eff=flr(L.COOLDOWN*(1-0.2*lvl)+0.5)
		if eff<3 then eff=3 end
		ship.laser_cd=eff
	end

	upd_bullets()
	update_exhaust()

	if ship.shield_invuln>0 then ship.shield_invuln-=1 end
	if ship.shield_unlocked then
		local drain,rech=sh_stats()
		if ship.shield_active then
			ship.shield_power = max(0, ship.shield_power - drain)
			if ship.shield_power <= 0 then
				ship_break_shield()
			end
		end
		
		if btn(5) and ship.shield_power>=SH.MIN and ship.shield_cool<=0 and not ship.dying and not ship.shield_active then
			ship.shield_active=true
			snd_sfx(SFX_SHIELD_ON,FX_CH)
		elseif not btn(5) and ship.shield_active then
			ship.shield_active=false
			snd_stop_sfx(FX_CH)
		end
		
		if not ship.shield_active then
			if ship.shield_cool>0 then
				ship.shield_cool-=1
			elseif ship.shield_power<SH.MAX and ship.shield_invuln<=0 then
				ship.shield_power=min(SH.MAX,ship.shield_power+rech)
			end
		end
	else
		if ship.shield_active then
			ship.shield_active=false
			snd_stop_sfx(FX_CH)
		end
		ship.shield_power=0
	end
	if ship.shield_active then ship.shield_anim=(ship.shield_anim+1)%30 end
end

function draw_ship()
	for p in all(exhaust) do
	local c=p.life>8 and X.CY or(p.life>4 and X.CO or X.CR)
		pset(flr(p.x),flr(p.y),c)
	end
	if ship.dying then
		for p in all(death_fx) do
			local c=p.life>16 and 10 or(p.life>8 and 9 or 8)
			pset(flr(p.x),flr(p.y),c)
		end
	else
		-- hull invuln flashing
		local vis=true
		if ship.hull_invuln>0 then
			vis=(ship.hull_invuln%4)<2
		end
		if vis then
			local sid,flip=SPR_SHIP,false
			if abs(ship.vx)>FACE_EPS then
				sid=SPR_LEAN
				flip=ship.vx>0
			end
			spr(sid,ship.x,ship.y,1,1,flip,false)
		end
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
				local r=SH.RAD-i+sin(t+i*0.2)*2
				local c=flash or SH.COLS[i]
				circ(cx,cy,r,c)
			end
		end
	end
end

function ship_get_bullets() return bullets end
function ship_get_hull() return ship.hull end
function ship_get_max_hull() return HULL.MAX+(ship.hull_level or 0) end

function ship_unlock_shield()
	ship.shield_unlocked=true
	ship.shield_level=max(1,ship.shield_level or 1)
	ship.shield_power,ship.shield_cool=SH.MAX,0
end

function ship_reset_upgrades()
	ship.fire_rate_level,ship.spread_level,ship.shield_unlocked,ship.shield_level,ship.shield_power,ship.shield_cool,ship.hull_level,ship.thruster_level=0,0,false,0,0,0,0,0
	ship.hull=HULL.MAX  -- Reset hull only on full game reset
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
