local START_X,START_Y=60,77
ship=ship or{x=START_X,y=START_Y,w=8,h=8,spr=16,spd=2.1,flipx=false,vx=0,vy=0,acc=0.18,dying=false,death_t=0,shield_active=false,shield_power=0,shield_anim=0,shield_invuln=0,shield_cool=0,shield_level=0,laser_cd=0,fire_rate_level=0,spread_level=0,shield_unlocked=false,hull=2,hull_invuln=0,hull_level=0,thruster_level=0}

local bullets={}

local function sh_stats()
 local l=ship.shield_level or 0
 return l<=1 and 1.0 or(l==2 and 0.6 or 0.4),l<=1 and 0.7 or(l==2 and 0.9 or 1.2),l<=1 and 22 or(l==2 and 18 or 12)
end

function ship_kill()
 if ship.dying or ship.shield_invuln>0 or ship.hull_invuln>0 then return end
 snd_stop_sfx(FX_CH)
 if ship.shield_active then
  local _,_,hit=sh_stats()
  ship.shield_power=max(0,ship.shield_power-hit)
  ship.shield_invuln=30
  ship.shield_anim=0
  snd_sfx(SFX_SHIELD_HIT,FX_CH)
  if ship.shield_power<=0 then
   ship.shield_active,ship.shield_cool,ship.shield_invuln,ship.shield_anim=false,60,30,0
   snd_stop_sfx(FX_CH)snd_sfx(SFX_SHIELD_OFF,FX_CH)
  end
  return
 end
 ship.hull-=1
 ship.hull_invuln=60
 snd_sfx(SFX_EXPLODE,FX_CH)
 if ship.hull<=0 then
  ship.dying,ship.death_t,ship.vx,ship.vy,game_state=true,0,0,0,"dying"
  for i=1,22 do
   local a,sp=rnd(1),0.7+rnd(1.3)
   p_add(ship.x+4,ship.y+4,cos(a)*sp,sin(a)*sp,flr(10+rnd(20)),PT_DEATH)
  end
 end
end

function ship_death_done()return ship.dying and ship.death_t>=45 end

function ship_init()
 bullets={}
 ship.x,ship.y,ship.vx,ship.vy,ship.dying,ship.death_t,ship.shield_active,ship.shield_anim,ship.shield_invuln,ship.shield_cool,ship.laser_cd,ship.hull_invuln=START_X,START_Y,0,0,false,0,false,0,0,0,0,0
 ship.shield_power=ship.shield_unlocked and 100 or 0
 snd_stop_sfx(FX_CH)
end

function update_ship()
 if ship.dying then
  ship.death_t+=1
  for b in all(bullets)do
   b.x+=b.dx b.y+=b.dy
   if b.x<-4 or b.x>132 or b.y<-4 or b.y>132 then del(bullets,b)end
  end
  return
 end
 
 if ship.hull_invuln>0 then ship.hull_invuln-=1 end
 
 local dx,dy,rdx,rdy=btn(0)and -1 or(btn(1)and 1 or 0),btn(2)and -1 or(btn(3)and 1 or 0)
 rdx,rdy=dx,dy
 local mag=sqrt(dx*dx+dy*dy)
 if mag>0 then dx/=mag dy/=mag end
 ship.flipx=ship.vx<-0.05 or(ship.vx==0 and dx<0)
 local tx,ty,ea=dx*ship.spd,dy*ship.spd,ship.acc*(1+0.15*(ship.thruster_level or 0))
 ship.vx+=mid(-ea,tx-ship.vx,ea)
 ship.vy+=mid(-ea,ty-ship.vy,ea)
 ship.x+=ship.vx
 ship.y+=ship.vy
 ship.x=mid(0,ship.x,120)
 ship.y=mid(HUD_HEIGHT or 0,ship.y,120)
 if ship.x==0 and ship.vx<0 then ship.vx=0 end
 if ship.x==120 and ship.vx>0 then ship.vx=0 end
 if ship.y==(HUD_HEIGHT or 0)and ship.vy<0 then ship.vy=0 end
 if ship.y==120 and ship.vy>0 then ship.vy=0 end
 
 -- exhaust
 local str=rdx==0 and rdy==0 and 0.2 or(rdy>0 and 0.03 or(rdy<0 and 0.45 or 0.6))
 str=mid(0,str,1)
 if str>0 then
  local y,x1,x2,bdy,life=ship.y+8,ship.x+2,ship.x+5,0.5+0.9*str,flr(6+10*str)
  local tl=ship.thruster_level or 0
  local cols={10,9,8}
  if tl==1 then cols={12,13,1}
  elseif tl==2 then cols={11,3,1}
  elseif tl>=3 then cols={7,6,5} end
  for i=1,2 do
   if rnd(1)<str then
    p_add((i==1 and x1 or x2)+rnd(1)-0.5,y,(rnd(0.6)-0.3)*str,bdy+rnd(0.4*str),life,PT_EXHAUST,nil,cols)
   end
  end
 end

 -- lasers
 if ship.laser_cd>0 then ship.laser_cd-=1 end
 if ship.laser_cd<=0 and btn(4)then
  local cx,by,iv,lvl=flr(ship.x+3),ship.y-2,ship.vx*0.3,ship.spread_level or 0
  local sdx=lvl>1 and 0.7 or 0
  if lvl~=1 then add(bullets,{x=cx,y=by,dx=iv,dy=-2})end
  if lvl>=1 then
   add(bullets,{x=cx-1,y=by,dx=iv-sdx,dy=-2})
   add(bullets,{x=cx+1,y=by,dx=iv+sdx,dy=-2})
  end
  snd_sfx(SFX_LASER,LASER_CH)
  ship.laser_cd=max(3,flr(15*(1-0.2*(ship.fire_rate_level or 0))+0.5))
 end
 
 for b in all(bullets)do
  b.x+=b.dx b.y+=b.dy
  if b.x<-4 or b.x>132 or b.y<-4 or b.y>132 then del(bullets,b)end
 end
 
 -- shield
 if ship.shield_invuln>0 then ship.shield_invuln-=1 end
 if ship.shield_unlocked then
  local drain,rech=sh_stats()
  if ship.shield_active then
   ship.shield_power=max(0,ship.shield_power-drain)
   if ship.shield_power<=0 then
    ship.shield_active,ship.shield_cool,ship.shield_invuln,ship.shield_anim=false,60,30,0
    snd_stop_sfx(FX_CH)snd_sfx(SFX_SHIELD_OFF,FX_CH)
   end
  end
  
  if btn(5)and ship.shield_power>=10 and ship.shield_cool<=0 and not ship.dying and not ship.shield_active then
   ship.shield_active=true
   snd_sfx(SFX_SHIELD_ON,FX_CH)
  elseif not btn(5)and ship.shield_active then
   ship.shield_active=false
   snd_stop_sfx(FX_CH)
  end
  
  if not ship.shield_active then
   if ship.shield_cool>0 then
    ship.shield_cool-=1
   elseif ship.shield_power<100 and ship.shield_invuln<=0 then
    ship.shield_power=min(100,ship.shield_power+rech)
   end
  end
 else
  if ship.shield_active then ship.shield_active=false snd_stop_sfx(FX_CH)end
  ship.shield_power=0
 end
 if ship.shield_active then ship.shield_anim=(ship.shield_anim+1)%30 end
end

function draw_ship()
 if ship.dying then
  -- Death particles drawn by particle system
 elseif not(ship.hull_invuln>0 and(ship.hull_invuln%4)<2)then
  spr(abs(ship.vx)>0.05 and 17 or 16,ship.x,ship.y,1,1,ship.vx>0)
 end
 for b in all(bullets)do local x,y=flr(b.x),flr(b.y)pset(x,y,9)pset(x,y-1,8)end
 if ship.shield_active and not ship.dying and not(ship.shield_invuln>0 and(ship.shield_invuln%4)<2)then
  local cx,cy,t,cols=ship.x+4,ship.y+4,ship.shield_anim/30,{12,13,1}
  local flash=ship.shield_invuln>25 and 7 or nil
  for i=1,3 do circ(cx,cy,10-i+sin(t+i*0.2)*2,flash or cols[i])end
 end
end

function ship_get_bullets()return bullets end
function ship_get_hull()return ship.hull end
function ship_get_max_hull()return 2+(ship.hull_level or 0)end

function ship_unlock_shield()
 ship.shield_unlocked,ship.shield_level,ship.shield_power,ship.shield_cool=true,max(1,ship.shield_level or 1),100,0
end

function ship_reset_upgrades()
 ship.fire_rate_level,ship.spread_level,ship.shield_unlocked,ship.shield_level,ship.shield_power,ship.shield_cool,ship.hull_level,ship.thruster_level,ship.hull=0,0,false,0,0,0,0,0,2
end

function ship_trails_pull(cx,cy,r,str)
 -- Now handled by p_pull for PT_EXHAUST and PT_DEATH types
 p_pull(cx,cy,r,str,{[PT_EXHAUST]=true,[PT_DEATH]=true})
end

function ship_trails_absorb(hx,hy,hw,hh)
 -- Now handled by p_absorb for PT_EXHAUST and PT_DEATH types
 p_absorb(hx,hy,hw,hh,{[PT_EXHAUST]=true,[PT_DEATH]=true})
end
