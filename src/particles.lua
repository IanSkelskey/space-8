-- Unified particle system
local p={}

-- Particle types
PT_DUST,PT_EXHAUST,PT_DEATH,PT_DEBRIS,PT_COMET,PT_HOLE=1,2,3,4,5,6

function p_add(x,y,dx,dy,life,typ,col,dat)
 add(p,{x=x,y=y,dx=dx,dy=dy,l=life,t=typ,c=col,d=dat})
end

function p_upd()
 for i in all(p) do
  i.x+=i.dx
  i.y+=i.dy
  i.l-=1
  
  -- Type-specific physics
  if i.t==PT_DUST then
   -- No friction for dust
  elseif i.t==PT_DEBRIS then
   -- Debris needs friction like original
   i.dx*=0.99
   i.dy*=0.99
  elseif i.t==PT_EXHAUST or i.t==PT_DEATH then
   -- Ship particles
   i.dx*=0.98
   i.dy*=0.98
  end
  
  if i.l<=0 or i.x<-4 or i.x>132 or i.y<-4 or i.y>132 then
   del(p,i)
  end
 end
end

function p_draw()
 for i in all(p) do
  if i.t==PT_DEBRIS and i.d then
   -- Draw debris chunks
   sspr(i.d[1],i.d[2],4,4,i.x,i.y)
  else
   -- Draw regular particles
   local c=i.c
   if not c then
    -- Default colors based on type/life
    if i.t==PT_DUST then
     c=i.l>12 and 6 or i.l>6 and 5 or 7
    elseif i.t==PT_EXHAUST then
     c=i.l>8 and (i.d and i.d[1] or 10) or i.l>4 and (i.d and i.d[2] or 9) or (i.d and i.d[3] or 8)
    elseif i.t==PT_DEATH then
     c=i.l>16 and 10 or i.l>8 and 9 or 8
    elseif i.t==PT_HOLE then
     c=i.l>16 and 14 or i.l>8 and 2 or 1
    else
     c=7
    end
   end
   pset(flr(i.x),flr(i.y),c)
  end
 end
end

function p_clear() p={} end
function p_get() return p end
function p_count() return #p end

-- Special physics for blackholes
function p_hole_pull(holes)
 for i in all(p) do
  if i.t==PT_HOLE then
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
     local invd,d=1/sqrt(d2),sqrt(d2)
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
    if i.t==PT_DEBRIS then
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
