local START_X,START_Y=60,77
-- ship state. fields that genuinely need a default HERE:
--   * w/h/spd : constants, never reassigned
--   * heal_t  : compared in draw_ship before it's ever set
--   * the 8 upgrade fields (fire_rate_level..hull): persist_save_from_game() READS
--     these, and a direct boot (the not-resumed path) calls it via tu(0) to write a
--     clean default save before ship_init()/persist_load_game_start() ever run.
-- every OTHER runtime field -- vx vy dying death_t shield_active shield_power
-- shield_anim shield_invuln shield_cool laser_cd hull_invuln shield_free rfb
-- magnet_t shield_retaliate_t shield_retaliate_r vlean muzzle_t -- is set by
-- ship_init() on each mission launch, so defaulting it here was pure duplication.
ship={x=START_X,y=START_Y,w=8,h=8,spd=2.5,heal_t=0,fire_rate_level=0,shield_level=0,shield_pulse_level=0,spread_level=0,hull_level=0,thruster_level=0,shield_unlocked=false,hull=2}

bullets={}

-- precomputed color triplets: base, level1, level2, level3+
local thr_cols={split"10,9,8",split"12,13,1",split"11,3,1",split"7,6,5",split"8,9,2"}

-- rapid-fire recolor: shift warm bullet/flash colors one step hotter (yellow->white, orange->yellow, red->orange)
local function rfpal() pal(10,7)pal(9,10)pal(8,9) end

-- polar pset: plot colour c at angle a / radius r around (cx,cy), rounded to nearest pixel
local function pp(cx,cy,a,r,c) pset(flr(cx+cos(a)*r+0.5),flr(cy+sin(a)*r+0.5),c) end

-- twin exhaust flames for a given thrust strength + velocity (shared by live flight and the round-clear fly-off)
function ship_thrust(str,vx,vy)
 if str<=0 then return end
 local yy,cols,life=ship.y+7,thr_cols[min(4,ship.thruster_level+1)],flr(3+4*str)
 local lx,ly=-vx*0.18,0.7+0.7*str-vy*0.12
 for i=0,1 do local ox=ship.x+(i==0 and 2 or 6)
  for j=1,2 do if rnd()<str then p_add(ox+rnd()-0.5,yy+rnd()*1.5,lx+(rnd()-0.5)*0.4,ly+rnd()*0.3,life,2,nil,cols) end end
 end
end

-- update bullets (movement + cull)
local function ub()
 for b in all(bullets)do
  b.x+=b.dx b.y+=b.dy
  if b.x<-4 or b.x>132 or b.y<-4 or b.y>132 then del(bullets,b) end
 end
end

local sd,sr,sh=split"1.25,.85,.6",split".55,.75,1.05",split"26,21,15"
local function sh_stats()
 local l=mid(1,ship.shield_level,3)
 return sd[l],sr[l],sh[l]
end

-- unified shield shutdown (set vars + sfx)
local function sh_off()
 ship.shield_active,ship.shield_cool,ship.shield_invuln,ship.shield_anim=false,60,30,0
 sfx(-1,3) snd_sfx(43)
end

-- shield-pulse kill-level + shock-aura radius, refreshed each frame in update_asteroid
shkl,shsr=0,0
-- shield-pulse damage at an enemy centre (cx,cy): the retaliation pulse (fired when a
-- hit lands on the active shield) plus the shock aura's threshold-kill. returns hp
-- after damage; the caller flashes the enemy and runs its own full death at hp<=0.
function shdmg(cx,cy,hp)
 local dx,dy=cx-ship.x-4,cy-ship.y-4 local d2=dx*dx+dy*dy
 if ship.shield_retaliate_t>0 and d2<=ship.shield_retaliate_r*ship.shield_retaliate_r then hp-=1 end
 if shsr>0 and d2<=shsr*shsr and hp<=shkl then hp=0 end
 return hp
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
 shake=max(shake,5) -- kick the screen on a hull hit
  snd_sfx(1)
 if ship.hull<=0 then
  shake=12 -- bigger jolt on death
  ship.dying,ship.death_t,ship.vx,ship.vy,game_state=true,0,0,0,"dying"
  -- store run score here: game.lua's death-entry block is unreachable because
  -- game_state is already "dying" by the time it re-checks for it
  -- store split directly; recombining (tsh*1000+ts) overflows pico-8's 32767 int cap
  dset(19,tsh) dset(18,ts)
 end
end


function ship_init()
 bullets={}
 ship.x,ship.y,ship.vx,ship.vy,ship.dying,ship.death_t,ship.shield_active,ship.shield_anim,ship.shield_invuln,ship.shield_cool,ship.laser_cd,ship.hull_invuln,ship.shield_free,ship.rfb=START_X,START_Y,0,0,false,0,false,0,0,0,0,0,0,0
 ship.shield_power=ship.shield_unlocked and 100 or 0
 ship.magnet_t=0
 ship.vlean=0
 ship.muzzle_t=0
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
  if shield_retaliate_t>0 then shield_retaliate_t-=1 end
  local dx,dy=btn(0)and -1 or(btn(1)and 1 or 0),btn(2)and -1 or(btn(3)and 1 or 0)
  local mag=sqrt(dx*dx+dy*dy) if mag>0 then dx/=mag dy/=mag end
  -- direct (no-accel) control: instant velocity = input * speed
  local s=spd*(1+0.12*thruster_level)
  vx,vy=dx*s,dy*s
  x+=vx y+=vy
  x=mid(0,x,120) y=mid(17,y,120) -- y top = HUD band height (17)
  -- visual lean: ease toward heading so direction changes roll through every lean frame (no gameplay effect)
  vlean+=mid(-0.2,(vx>0.05 and 1 or(vx<-0.05 and -1 or 0))-vlean,0.2)
    local str=(dx==0 and dy==0)and 0.2 or(dy>0 and 0.03 or(dy<0 and 0.45 or 0.6))
  ship_thrust(mid(0,str,1),vx,vy)
  if laser_cd>0 then laser_cd-=1 end
  if muzzle_t>0 then muzzle_t-=1 end
  -- rapid fire burst timer
  if rfb>0 then rfb-=1 end
  if laser_cd<=0 and btn(4)then
  local cx,by,iv,lvl=flr(x+2),y-3,vx*0.12,spread_level
   local sdx=lvl>1 and 0.7 or 0
   -- spawn spread wide enough that the 5px bullet sprites don't overlap
   local so=lvl>1 and 6 or 3
   if lvl~=1 then add(bullets,{x=cx,y=by,dx=iv,dy=-3})end
   if lvl>=1 then add(bullets,{x=cx-so,y=by,dx=iv-sdx,dy=-3}) add(bullets,{x=cx+so,y=by,dx=iv+sdx,dy=-3}) end
  muzzle_t=4 -- two-frame muzzle flash (72 then 73) at the nose
  -- 2-3 hot muzzle sparks: warm ramp that darkens with distance, then vanishes
  for i=1,2+rndi(2) do p_add(x+4+rnd()*2-1,y-4,iv+(rnd()-0.5)*1.2,-(0.6+rnd()*1.1),8+rndi(3),8) end
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

-- draw the 16x16 hull at its current visual lean (level 137 / bank 139 / max 141)
local function draw_hull()
 local al=abs(ship.vlean)
 if al<0.33 then spr(137,ship.x-4,ship.y-4,2,2)
 else spr(al<0.66 and 139 or 141,ship.x-4,ship.y-4,2,2,ship.vlean>0) end
end

-- flash the hull with a 2-colour ramp (light a / dark b), draw it, reset:
-- red hit-flash = hf(8,2); green heal-flash = hf(11,3). swaps the hull greys (6,13,5,9,4).
local function hf(a,b) pal(6,a) pal(13,b) pal(5,b) pal(9,a) pal(4,a) draw_hull() pal() end

function draw_ship()
 -- flying off after a round clear: roll through the lean frames back to level, but no blink/muzzle/effects
 if game_state=="fanfare_depart" then draw_hull() return end
 if ship.dying then
  -- death: a hit flash first, then the full 6-frame 16x16 explosion (tiles 160..170), 4 game-frames each
  local f=ship.death_t\4
  if f<1 then hf(8,2)
  elseif f<7 then spr(160+(f-1)*2,ship.x-4,ship.y-4,2,2) end
 elseif ship.heal_t>t() then
  -- heal flash: blink the green-ramped hull on/off, same cadence as the red hit flash
  if (flr(t()*15))%2<1 then hf(11,3) end
 elseif ship.hull_invuln>45 then
  -- red hit flash: blink the red-ramped hull for the first ~half-second before the normal invuln blink
  if (ship.hull_invuln%4)>=2 then hf(8,2) end
 elseif not(ship.hull_invuln>0 and(ship.hull_invuln%4)<2)then
  draw_hull()
 end
 
 -- muzzle flash at the nose: frame1 always 72; frame2 is 73/74/75 by lean stage (flipped to match the bank)
 if ship.muzzle_t>0 and not ship.dying then
  if ship.rfb>0 then rfpal() end
  local st=abs(ship.vlean)
  st=st<0.33 and 0 or(st<0.66 and 1 or 2)
  local f1=ship.muzzle_t>2
  -- at max lean, nudge frame-1 (72) 1px left (right when flipped)
  local ox=(f1 and st==2)and(ship.vlean>0 and 1 or -1)or 0
  spr(f1 and 72 or 73+st,ship.x+ox,ship.y-9,1,1,st>0 and ship.vlean>0)
  pal()
 end

 -- bullets: animated 5x6 sprite over the 5x5 hitbox; rapid fire recolors the base sprite hotter via palette
 if ship.rfb>0 then rfpal() end
 for b in all(bullets)do sspr(64+(flr(time()*16+b.x+b.y)%2)*8,56,5,6,flr(b.x),flr(b.y)-1) end
 pal()
 if ship.shield_active and not ship.dying and not(ship.shield_invuln>0 and (ship.shield_invuln%4)<2) then
  local cx,cy,t=ship.x+3,ship.y+4,ship.shield_anim/30
  local base_r=12+ship.shield_pulse_level -- slight growth per level
  local cols=thr_cols[ship.shield_pulse_level>0 and 5 or 2]
  local flash=ship.shield_invuln>25 and (ship.shield_pulse_level>0 and 8 or 7)
  for i=1,3 do
    circ(cx,cy,base_r-i+sin(t+i*0.2)*2,flash or cols[i])
  end
 end
 -- magnet aura: a rotating dotted ring in the gravity-well palette
 -- (pink 14 / purple 2, shared with pink comets + black holes). the radius
 -- breathes gently around the 44px pull range and the ring flickers out as the
 -- effect expires, so it reads as a field without becoming a distraction.
 if ship.magnet_t>0 and not ship.dying and not(ship.magnet_t<20 and ship.magnet_t%4<2) then
  -- single rotating pink/purple dotted ring at the ~44px pull range; breathes
  -- gently and flickers out as the effect expires. (the inner counter-rotating
  -- ring and the in-falling spark streams were dropped to reclaim tokens.)
  local cx,cy,t=ship.x+4,ship.y+4,time()
  local r=43+sin(t*0.5)*1.5
  local ao=t*0.6
  for i=0,23 do
   pp(cx,cy,ao+i/24,r,i%2==0 and 14 or 2)
  end
 end
end
