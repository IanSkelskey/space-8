-- Unified particle system
local p={}
Gp=p

-- tiny shared halo (rotating 4-dot ring) reused by comets + powerups
function h(x,y,a,c1,c2)for i=0,3 do local g=a+i*0.25 pset(flr(x+cos(g)*3),flr(y+sin(g)*3),i%2==0 and c1 or c2)end end

function p_add(x,y,dx,dy,life,typ,col,dat) add(p,{x=x,y=y,dx=dx,dy=dy,l=life,t=typ,c=col,d=dat}) end

function p_upd()
 for i in all(p) do
  i.x+=i.dx i.y+=i.dy+((i.t==7 and cs*0.7) or 0) i.l-=1
  -- inline damp
  if i.t==4 then i.dx*=0.99 i.dy*=0.99 elseif i.t==2 or i.t==3 then i.dx*=0.98 i.dy*=0.98 end
   -- money shard settle: apply stronger friction once speed low
    if i.t==7 and i.d==7 then
         local dx,dy=ship.x+4-(i.x+1),ship.y+4-(i.y+1) local d2=dx*dx+dy*dy
         if d2<196 and d2>0 then local inv=1/sqrt(d2)
            if d2<49 then i.dx=dx*inv*1.8 i.dy=dy*inv*1.8 else local f=0.4*(1-d2/196) i.dx+=dx*inv*f i.dy+=dy*inv*f end
         else i.dx*=0.94 i.dy*=0.94 end
    end
   -- pickup handling with tighter coin capture (center 4x4)
   if i.t==7 then
      if i.d==7 then local cx,cy=ship.x+2,ship.y+2 if not (i.x>=cx and i.x<cx+4 and i.y>=cy and i.y<cy+4) then goto skip_pick end end
      if scoll(i.x,i.y,8,8) then local d=i.d
   if d==2 then ship.shield_active=true ship.shield_free=110 ship.shield_power=100 snd_sfx(30)
       elseif d==1 or d==nil then if ship.hull<2+ship.hull_level then ship.hull+=1 end hud_add_score(20) snd_sfx(63)
       elseif d==7 then money_total+=4 last_bonus+=4 snd_sfx(63)
   if not money_life_lo then money_life_lo,money_life_hi=0,0 end money_life_lo+=4 while money_life_lo>=1000 do money_life_lo-=1000 money_life_hi+=1 end
       elseif d==5 then ship.rfb=120 snd_sfx(63)
       elseif d==6 then ship.magnet_t=420 snd_sfx(63)
       end del(p,i) goto continue end
      ::skip_pick::
   end
  if i.l<=0 or i.x<-4 or i.x>132 or i.y<-4 or i.y>132 then del(p,i) end
  ::continue::
 end
 -- global magnet pull (after per-particle updates for smoother feel)
 if ship.magnet_t and ship.magnet_t>0 then
  local cx,cy=ship.x+4,ship.y+4
  local r=44
  local r2=r*r
  for i in all(p) do
   if i.t==7 then
    local dx,dy=cx-i.x,cy-i.y
    local d2=dx*dx+dy*dy
    if d2<r2 and d2>0.5 then
     local inv=1/sqrt(d2)
     local pull=0.55*(1-d2/r2)
     i.dx+=dx*inv*pull
     i.dy+=dy*inv*pull
    end
   end
  end
 end
end

function p_draw()
 for i in all(p) do
    if i.t==7 then
     local d=i.d
     if d==7 then
       pset(i.x,i.y,10)pset(i.x+1,i.y,10)pset(i.x,i.y+1,10)pset(i.x+1,i.y+1,10)
     else
       h(i.x+2.5,i.y+2.5,time(),
        (d==2 and 12) or (d==5 and 9) or (d==6 and 10) or 11,
        (d==2 and 1)  or (d==5 and 10) or (d==6 and 8)  or 7)
       spr((d==2 and 10) or (d==5 and 11) or (d==6 and 56) or 38,i.x,i.y)
     end
    elseif i.t==4 and i.d then
     sspr(i.d[1],i.d[2],4,4,i.x,i.y)
    else
     local c=i.c
     if not c then
        local t,l=i.t,i.l
        c=(t==1 and (l>12 and 6 or l>6 and 5 or 7))
         or (t==2 and (l>8 and (i.d and i.d[1] or 10) or l>4 and (i.d and i.d[2] or 9) or (i.d and i.d[3] or 8)))
         or (t==3 and (l>16 and 10 or l>8 and 9 or 8))
         or (t==6 and (l>16 and 14 or l>8 and 2 or 1))
         or 7
     end
     pset(flr(i.x),flr(i.y),c)
    end
 end
end

function p_clear() p={} Gp=p end

-- Special physics for blackholes
function p_hole_pull(holes)
 for i in all(p) do
  if i.t==6 then
   local cx,cy,bestd2,hh
   for h in all(holes) do
    local hx,hy=h.x+4,h.y+4
    local dx,dy=hx-i.x,hy-i.y
    local d2=dx*dx+dy*dy
    if not bestd2 or d2<bestd2 then
     bestd2,cx,cy,hh=d2,hx,hy,h
    end
   end
   if cx then
    local dx,dy=cx-i.x,cy-i.y
    local d2=dx*dx+dy*dy
    if d2>0.1 then
     local invd,d=sqrt(d2) and 1/sqrt(d2),sqrt(d2)
     local fall=1-min(d/(hh and hh.r or 32),1)
     local rg,sg=0.3*fall,0.8*max(fall,0.2)
     local vx,vy=i.dx,i.dy
     vx+=dx*invd*rg-dy*invd*sg
     vy+=dy*invd*rg+dx*invd*sg
     if d<2.2 then
      vx-=dx*invd*0.2
      vy-=dy*invd*0.2
     end
     local sp=sqrt(vx*vx+vy*vy)
     if sp>1.8 then
      vx*=1.8/sp
      vy*=1.8/sp
     end
     i.dx,i.dy=vx,vy
    end
   else
    i.dx*=0.65
    i.dy=i.dy*0.65+0.2
    local sp=sqrt(i.dx*i.dx+i.dy*i.dy)
    if sp>0.6 then
     i.dx*=0.6/sp
     i.dy*=0.6/sp
    end
   end
  end
 end
end

-- Pull particles toward point
function p_pull(cx,cy,r,str,types)
 local r2=r*r
 for i in all(p) do
  if not types or types[i.t] then
   local dx,dy=cx-i.x,cy-i.y
   local d2=dx*dx+dy*dy
   if d2>0.5 and d2<r2 then
    local invd,acc=1/sqrt(d2),str*(1-d2/r2)
    i.dx+=dx*invd*acc
    i.dy+=dy*invd*acc
    -- Limit debris speed like original
 if i.t==4 then
     local sp=sqrt(i.dx*i.dx+i.dy*i.dy)
     if sp>2 then
      i.dx*=2/sp
      i.dy*=2/sp
     end
    end
   end
  end
 end
end

-- Absorb particles in rect
function p_absorb(hx,hy,hw,hh,types)
 for i in all(p) do
  if (not types or types[i.t]) and i.x>=hx and i.x<hx+hw and i.y>=hy and i.y<hy+hh then
   del(p,i)
  end
 end
end
