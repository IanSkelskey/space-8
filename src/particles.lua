-- Unified particle system
local p={}
Gp=p

function p_add(x,y,dx,dy,life,typ,col,dat) add(p,{x=x,y=y,dx=dx,dy=dy,l=life,t=typ,c=col,d=dat}) end

function p_upd()
 for i in all(p) do
  i.x+=i.dx i.y+=i.dy+((i.t==7 and cs*0.7) or 0) i.l-=1
  -- inline damp
  if i.t==4 then i.dx*=0.99 i.dy*=0.99 elseif i.t==2 or i.t==3 then i.dx*=0.98 i.dy*=0.98 end
  -- pickup (type 7)
   if i.t==7 and scoll(i.x,i.y,8,8) then
   local d=i.d
   if d==2 then -- shield free (existing behavior)
    ship.shield_active=true ship.shield_free=110 ship.shield_power=max(ship.shield_power,10) snd_sfx(30)
   elseif d==1 or d==nil then -- hull repair (legacy nil or explicit 1)
    if ship.hull<2+ship.hull_level then ship.hull+=1 end hud_add_score(20) snd_sfx(63)
   elseif d==3 then -- big cash coin
    money_total+=30 last_bonus+=30 snd_sfx(63)
   elseif d==7 then -- small cash shard
    money_total+=8 last_bonus+=8 snd_sfx(63)
   elseif d==5 then -- rapid fire burst (extended duration)
    ship.rfb=120 snd_sfx(63)
    elseif d==6 then -- magnet field
      mag_t=180 snd_sfx(63)
   end
   del(p,i) goto continue
  end
   -- magnet attraction influences other pickups while active (excluding the one just collected)
   if mag_t and mag_t>0 and i.t==7 then
    local cx,cy=ship.x+4,ship.y+4
    local dx,dy=cx-i.x,cy-i.y
    local d2=dx*dx+dy*dy
    if d2>9 and d2<3600 then
      local inv=1/sqrt(d2)
      i.dx+=dx*inv*0.07
      i.dy+=dy*inv*0.07
    end
   end
  if i.l<=0 or i.x<-4 or i.x>132 or i.y<-4 or i.y>132 then del(p,i) end
  ::continue::
 end
end

function p_draw()
 for i in all(p) do
    if i.t==7 then
     -- powerup sprite + subtle alternating halo
     local cx,cy=i.x+2,i.y+2
     local d=i.d
    -- sprite selection: 10 shield, 38 hull, 57 big cash, 11 rapid, 56 magnet, 38 score; small cash (d==7) = custom spark
    if d==7 then
      local ph=flr(time()*8)%2 local col=10
      pset(cx-1,cy,col)pset(cx+1,cy,col)pset(cx,cy-1,col)pset(cx,cy+1,col)
    else
      local sprid=(d==2 and 10) or (d==5 and 11) or (d==6 and 56) or (d==3 and 57) or 38
      spr(sprid,i.x,i.y)
    end
     local ph=flr(time()*8)%2
   local gc=(d==2 and 12) or (d==5 and 10) or (d==6 and 13) or ((d==3 or d==7) and 10) or 11 -- halo for all cash types
     if ph==0 then
        pset(cx-4,cy,gc)pset(cx+4,cy,gc)pset(cx,cy-4,gc)pset(cx,cy+4,gc)
     else
        pset(cx-3,cy-3,gc)pset(cx+3,cy-3,gc)pset(cx-3,cy+3,gc)pset(cx+3,cy+3,gc)
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
