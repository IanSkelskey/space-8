local START_X,START_Y=60,77
ship={x=START_X,y=START_Y,w=8,h=8,spr=16,spd=2.5,flipx=false,vx=0,vy=0,acc=0.24,dying=false,death_t=0,shield_active=false,shield_power=0,shield_anim=0,shield_invuln=0,shield_cool=0,shield_level=0,laser_cd=0,fire_rate_level=0,spread_level=0,shield_unlocked=false,hull=2,hull_invuln=0,hull_level=0,thruster_level=0,shield_free=0,rfb=0,magnet_t=0,shield_pulse_level=0,shield_retaliate_t=0,shield_retaliate_r=0}

bullets={}

-- precomputed color triplets: base, level1, level2, level3+
local thr_cols={
 {10,9,8},
 {12,13,1},
 {11,3,1},
 {7,6,5}
}

-- update bullets (movement + cull)
local function ub()
 for b in all(bullets)do
  b.x+=b.dx b.y+=b.dy
  if b.x<-4 or b.x>132 or b.y<-4 or b.y>132 then del(bullets,b) end
 end
end

local function sh_stats()
 local l=ship.shield_level
 -- higher drain, slower recharge, larger hit chunks at low level
 return l<=1 and 1.25 or(l==2 and 0.85 or 0.6), l<=1 and 0.55 or(l==2 and 0.75 or 1.05), l<=1 and 26 or(l==2 and 21 or 15)
end

-- unified shield shutdown (set vars + sfx)
local function sh_off()
 ship.shield_active,ship.shield_cool,ship.shield_invuln,ship.shield_anim=false,60,30,0
 sfx(-1,3) snd_sfx(43)
end

function ship_kill()
 if ship.dying or ship.shield_invuln>0 or ship.hull_invuln>0 then return end
 sfx(-1,3)
 if ship.shield_active then
  local _,_,hit=sh_stats()
  -- reduced hit drain per shield_pulse_level
  hit=hit*(1-0.15*ship.shield_pulse_level)
  ship.shield_power=max(0,ship.shield_power-hit)
  ship.shield_invuln=30
  ship.shield_anim=0
  snd_sfx(31)
  -- retaliation (debounced by shield_invuln frames)
  if ship.shield_pulse_level>0 then
   ship.shield_retaliate_t=2
   ship.shield_retaliate_r=18+4*(ship.shield_pulse_level-1)
  end
  if ship.shield_power<=0 then sh_off() end
  return
 end
 ship.hull-=1
 ship.hull_invuln=60
  snd_sfx(1)
 if ship.hull<=0 then
  ship.dying,ship.death_t,ship.vx,ship.vy,game_state=true,0,0,0,"dying"
  for i=1,22 do
    local a,sp=rnd(1),0.7+rnd(1.3)
    p_add(ship.x+4,ship.y+4,cos(a)*sp,sin(a)*sp,flr(10+rnd(20)),3)
  end
 end
end


function ship_init()
 bullets={}
 ship.x,ship.y,ship.vx,ship.vy,ship.dying,ship.death_t,ship.shield_active,ship.shield_anim,ship.shield_invuln,ship.shield_cool,ship.laser_cd,ship.hull_invuln,ship.shield_free,ship.rfb=START_X,START_Y,0,0,false,0,false,0,0,0,0,0,0,0
 ship.shield_power=ship.shield_unlocked and 100 or 0
 ship.magnet_t=0
 ship.shield_retaliate_t,ship.shield_retaliate_r=0,0
 sfx(-1,3)
end

function update_ship()
 if ship.dying then
  ship.death_t+=1
  ub()
  return
 end
 do local _ENV=setmetatable(ship,{__index=_ENV})
  if hull_invuln>0 then hull_invuln-=1 end
  local dx,dy=btn(0)and -1 or(btn(1)and 1 or 0),btn(2)and -1 or(btn(3)and 1 or 0)
  local mag=sqrt(dx*dx+dy*dy) if mag>0 then dx/=mag dy/=mag end
  flipx=vx<-0.05 or(vx==0 and dx<0)
  local tx,ty,ea=dx*spd,dy*spd,acc*(1+0.15*thruster_level)
  vx+=mid(-ea,tx-vx,ea) vy+=mid(-ea,ty-vy,ea)
  x+=vx y+=vy
  x=mid(0,x,120) y=mid(10,y,120)
    if (x==0 and vx<0)or(x==120 and vx>0)then vx=0 end
  if (y==10 and vy<0)or(y==120 and vy>0)then vy=0 end
    local str=(dx==0 and dy==0)and 0.2 or(dy>0 and 0.03 or(dy<0 and 0.45 or 0.6))
  str=mid(0,str,1)
  if str>0 then local yy=y+8 local bdy=0.5+0.9*str local life=flr(6+10*str) local cols=thr_cols[min(4,thruster_level+1)] for i=0,1 do if rnd()<str then local ox=(i==0 and 2 or 5) p_add(x+ox+rnd()-0.5,yy,(rnd(0.6)-0.3)*str,bdy+rnd(0.4*str),life,2,nil,cols) end end end
  if laser_cd>0 then laser_cd-=1 end
  -- rapid fire burst timer
  if rfb>0 then rfb-=1 end
  if laser_cd<=0 and btn(4)then
  local cx,by,iv,lvl=flr(x+3),y-2,vx*0.3,spread_level
   local sdx=lvl>1 and 0.7 or 0
   if lvl~=1 then add(bullets,{x=cx,y=by,dx=iv,dy=-2})end
   if lvl>=1 then add(bullets,{x=cx-1,y=by,dx=iv-sdx,dy=-2}) add(bullets,{x=cx+1,y=by,dx=iv+sdx,dy=-2}) end
  -- muzzle flash particles (slight spread) when rapid fire active
  if rfb>0 then
   for mi=1,2 do
    local ang=rnd(0.2)-0.1
    p_add(cx+((mi==1)and -1 or 1),by+1,ang*0.4+rnd(0.2)-0.1,-1.5-rnd(0.3),6+rnd(4)\1,1, (mi==1 and 10 or 9))
   end
  end
  snd_sfx(62,2)
  laser_cd=max(3,flr(12*(1-0.2*fire_rate_level)-(rfb>0 and 5 or 0)+0.5))
  end
  ub()
  if shield_invuln>0 then shield_invuln-=1 end

  -- REPLACED SHIELD / PULSE BLOCK (previous version had mismatched else)
  if shield_unlocked or shield_free>0 then
    local drain,rech=sh_stats()
    if shield_pulse_level>0 then drain=drain*(1-0.1*shield_pulse_level) end

    -- drain while active
    if shield_active then
      if shield_free>0 then
        shield_free-=1
      else
        shield_power=max(0,shield_power-drain)
      end
      if shield_power<=0 and shield_free<=0 then sh_off() end
    end

    -- auto-hold during free shield time
    if shield_free>0 then
      shield_active=true
    end

    -- manual toggle (only when not in free period)
    if shield_free<=0 then
      if btn(5) and shield_power>=10 and shield_cool<=0 and not dying and not shield_active then
        shield_active=true snd_sfx(30)
      elseif (not btn(5)) and shield_active then
        shield_active=false sfx(-1,3)
      end
    end

    -- recharge when inactive
    if not shield_active then
      if shield_cool>0 then
        shield_cool-=1
      elseif shield_power<100 and shield_invuln<=0 then
        shield_power=min(100,shield_power+rech)
      end
    end
  else
    -- shield locked & no free time
    if shield_active then shield_active=false sfx(-1,3) end
    shield_power=0 shield_free=0
  end

  if shield_active then shield_anim=(shield_anim+1)%30 end
  if magnet_t>0 then magnet_t-=1 end
 end -- _ENV block
end

function draw_ship()
 if ship.dying then
  -- Death particles drawn by particle system
 elseif not(ship.hull_invuln>0 and(ship.hull_invuln%4)<2)then
  spr(abs(ship.vx)>0.05 and 17 or 16,ship.x,ship.y,1,1,ship.vx>0)
 end
 
 -- Skip bullets and shield during fanfare
 if game_state=="fanfare_depart" then return end
 
 for b in all(bullets)do local x,y=flr(b.x),flr(b.y)pset(x,y,9)pset(x,y-1,8)end
 if ship.rfb>0 then
  -- overlay yellow tint: redraw bullets with brighter colors
  for b in all(bullets)do local x,y=flr(b.x),flr(b.y)pset(x,y,10)pset(x,y-1,9)end
 end
 if ship.shield_active and not ship.dying and not(ship.shield_invuln>0 and (ship.shield_invuln%4)<2) then
  local cx,cy,t=ship.x+4,ship.y+4,ship.shield_anim/30
  local base_r=10+ship.shield_pulse_level -- slight growth per level
  local cols = (ship.shield_pulse_level>0) and {8,9,2} or thr_cols[2]
  local flash=ship.shield_invuln>25 and (ship.shield_pulse_level>0 and 8 or 7) or nil
  for i=1,3 do
    circ(cx,cy,base_r-i+sin(t+i*0.2)*2,flash or cols[i])
  end
 end
 -- magnet aura simplified: single spinning dotted ring at effect radius
 if ship.magnet_t>0 then
  local cx,cy=ship.x+4,ship.y+4
  local r=44 -- matches pull radius in particle system
  local aoff=time()*0.6
  for i=0,47 do
   if (i%2)==0 then
    local a=aoff+i/48
    pset(flr(cx+cos(a)*r+0.5),flr(cy+sin(a)*r+0.5),7)
   end
  end
 end
end

-- accessors removed (inline bullets, ship.hull, 2+ship.hull_level for tokens)

function ship_unlock_shield()
 ship.shield_unlocked,ship.shield_level,ship.shield_power,ship.shield_cool=true,max(1,ship.shield_level),100,0
end

function ship_reset_upgrades()
 ship.fire_rate_level,ship.spread_level,ship.shield_unlocked,ship.shield_level,ship.shield_power,ship.shield_cool,ship.hull_level,ship.thruster_level,ship.hull,ship.rfb=0,0,false,0,0,0,0,0,2,0
 ship.shield_pulse_level=0
 ship.shield_retaliate_t,ship.shield_retaliate_r=0,0
end
function ship_reset_upgrades()
 ship.fire_rate_level,ship.spread_level,ship.shield_unlocked,ship.shield_level,ship.shield_power,ship.shield_cool,ship.hull_level,ship.thruster_level,ship.hull,ship.rfb=0,0,false,0,0,0,0,0,2,0
 ship.shield_pulse_level=0
 ship.shield_retaliate_t,ship.shield_retaliate_r=0,0
end
