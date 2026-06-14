-- Unified particle system
local p={}
local ppf=0 -- frame counter for shimmer
Gp=p
-- powerup icon by drop kind (icon at PS[d*3-2]): 32 hull,33 charge,34 bomb,35 rapid,36 magnet
local PS=split"32,11,3,33,12,15,34,8,2,0,0,0,35,10,9,36,14,2"
-- shared explosion: the 6-frame blast (spr 202..207) recoloured per-source by a ramp.
-- SRC = green-comet body colours setramp() swaps; EXR = red blast (popcorn + red comets).
-- moved here so comets AND popcorn spawn the explosion as a one-shot particle (type 10).
local SRC,EXR=split"1,3,11,10",split"2,8,9,10"
local function setramp(rp) for k=1,4 do pal(SRC[k],rp[k]) end end
-- spawn a one-shot explosion particle (type 10): 6 frames over 18 ticks, recoloured by ramp r
function boom(x,y,r) p_add(x,y,0,0,18,10,nil,r) end

-- shared token-saving helpers (used across gameplay files)
function rndi(n) return rnd(n)\1 end                         -- integer rnd
function jit() return rndi(3)-1 end                          -- -1/0/+1 hit-shake jitter
function fl(c) for i=1,15 do pal(i,c) end end                -- solid palette fill (white hit flash fl(7), red popcorn fl(8), etc.)
function capv(o,m) local s=sqrt(o.dx*o.dx+o.dy*o.dy) if s>m then o.dx*=m/s o.dy*=m/s end end -- cap a {dx,dy} speed

-- tiny shared halo (rotating 4-dot ring) reused by comets + powerups
function h(x,y,a,c1,c2)for i=0,3 do local g=a+i*0.25 pset(flr(x+cos(g)*3),flr(y+sin(g)*3),i%2==0 and c1 or c2)end end

function p_add(x,y,dx,dy,life,typ,col,dat) add(p,{x=x,y=y,dx=dx,dy=dy,l=life,t=typ,c=col,d=dat}) end

-- swirl of n particles around (cx,cy): tangential velocity gives the black-hole accretion look.
-- type 6 fades through ramp rmp (default = the black-hole pink->dark); shared with the shield break.
local BHR=split"14,2,1"
function swirl(cx,cy,n,rmp)
 rmp=rmp or BHR
 for i=1,n do
  local ang,rad=rnd(),2+rnd(2)
  local s=0.45+rnd(0.45)
  p_add(cx+cos(ang)*rad,cy+sin(ang)*rad,-sin(ang)*s+rnd(0.2)-0.1+cos(ang)*0.08,cos(ang)*s+rnd(0.2)-0.1+sin(ang)*0.08,20+rndi(10),6,nil,rmp)
 end
end

function p_upd()
 ppf=(ppf+1)%60
 for i in all(p) do
  i.x+=i.dx i.y+=i.dy+((i.t==7 and cs*0.7) or 0) i.l-=1
  -- inline damp
  if i.t==2 then i.dx*=0.9 i.dy*=0.9 elseif i.t==3 then i.dx*=0.98 i.dy*=0.98 end
  if i.t==9 then if bhit(i.x+2,i.y+2) then del(p,i) goto continue elseif scoll(i.x+1,i.y+1,3,3) then ship_kill() del(p,i) goto continue end end
   -- coin/pickup attraction (magnet pass folded in here):
   --  * magnet powerup pulls ALL pickups in from 44px (1936=44^2)
   --  * EVERY pickup then homes in within 14px and snaps straight in within 10px -- so
   --    pickups settle INTO the hull instead of being slingshotted past. the speed cap
   --    keeps the magnet from flinging anything away.
    if i.t==7 and not ship.dying then
         local dx,dy=ship.x+4-i.x,ship.y+4-i.y local d2=dx*dx+dy*dy
         if ship.magnet_t>0 and d2<1936 and d2>0.5 then local inv,f=1/sqrt(d2),0.55*(1-d2/1936) i.dx+=dx*inv*f i.dy+=dy*inv*f end
         if d2<196 and d2>0 then local inv=1/sqrt(d2)
            if d2<100 then i.dx=dx*inv*1.8 i.dy=dy*inv*1.8 else local f=0.4*(1-d2/196) i.dx+=dx*inv*f i.dy+=dy*inv*f end
         elseif i.d>7 then i.dx*=0.94 i.dy*=0.94 end
         if ship.magnet_t>0 or d2<196 then capv(i,2) end
   -- pickup capture: collect anything whose centre is within an 8px disc of the ship centre
   -- (64=8^2, ~the visible hull). a round distance test instead of a tight offset box, so a
   -- coin sitting on the ship is never missed because its position fell just outside a corner.
   -- (reuses d2 from the attraction pass above: position hasn't changed, only velocity)
      if d2<64 then local d=i.d
   if d==2 then ship.shield_active=true ship.shield_free=110 ship.shield_power=100 snd_sfx(9)
       elseif d==1 then if ship.hull<2+ship.hull_level then ship.hull+=1 end ship.heal_t=t()+0.4 hud_add_score(20) snd_sfx(15)
       elseif d>7 then local v=d==10 and 5 or d-7 money_total+=v last_bonus+=v snd_sfx(13)
       elseif d==3 then bomb_fire(ship.x+4,ship.y+4)
       elseif d==5 then ship.rfb=210 snd_sfx(14)
       elseif d==6 then ship.magnet_t=420 snd_sfx(14)
       end del(p,i) goto continue end
   end
  if i.l<=0 or i.x<-4 or i.x>132 or i.y<-4 or i.y>132 then del(p,i) end
  ::continue::
 end
end

function p_draw()
 for i in all(p) do
      if i.t==7 then
     local d=i.d
     if d>7 then
          local a=(ppf\4)%4
          spr(48+(d-8)*16+min(a,4-a),i.x-2,i.y-2) -- credits small/mid/gold at 48/64/80
     else
       local o,f=d*3,ppf%12<6 and 1 or 0
       pal(7,PS[o-f])pal(13,PS[o-1+f])
       sspr(80,16,9,9,i.x-1,i.y-1)
       pal()
       spr(PS[o-2],i.x+1,i.y+1)
     end
    elseif i.t==4 and i.d then
     -- debris chunk sampled from sprite 5; alt asteroids recolour it (4,2,1 -> 13,5,1)
     if i.c then pal(4,13) pal(2,5) end
     sspr(i.d[1],i.d[2],4,4,i.x,i.y)
     if i.c then pal() end
    elseif i.t==9 then
     sspr(104+((ppf\4)%2)*8,0,5,5,flr(i.x),flr(i.y))
    elseif i.t==10 then
     -- explosion: frame from remaining life; flip by spawn-pos parity for variety
     setramp(i.d) spr(25+(18-i.l)\3,i.x,i.y,1,1,i.x%2<1,i.y%2<1) pal()
    else
     local c=i.c
     if not c then
        local t,l=i.t,i.l
        c=(t==1 and (l>9 and (i.d and 13 or 4) or l>4 and (i.d and 5 or 2) or 1)) -- rock dust; alt debris (i.d set) fades 13->5->1
         or (t==2 and (l>3 and (i.d and i.d[1] or 10) or l>1 and (i.d and i.d[2] or 9) or (i.d and i.d[3] or 8)))
         or (t==3 and (l>16 and 10 or l>8 and 9 or 8))
         or (t==6 and (l>16 and i.d[1] or l>8 and i.d[2] or i.d[3]))
         or (t==8 and (ship.rfb>0 and (l>6 and 7 or l>4 and 10 or l>2 and 9 or 5) or (l>6 and 10 or l>4 and 9 or l>2 and 8 or 5))) -- muzzle spark; rapid fire shifts hotter (white->yellow->orange->gray)
         or 7
     end
     -- muzzle sparks stretch to 2px tall mid-life for a speedy streak
     if i.t==8 and i.l>2 and i.l<7 then local fx,fy=flr(i.x),flr(i.y) pset(fx,fy,c)pset(fx,fy+1,c)
     else pset(flr(i.x),flr(i.y),c) end
    end
 end
end

function p_clear() p={} Gp=p end

-- Special physics for blackholes
function p_hole_pull(holes)
 for i in all(p) do
  if i.t==6 then
   local cx,cy,bestd2
   for h in all(holes) do
    local hx,hy=h.x+4,h.y+4
    local dx,dy=hx-i.x,hy-i.y
    local d2=dx*dx+dy*dy
    if not bestd2 or d2<bestd2 then
     bestd2,cx,cy=d2,hx,hy
    end
   end
   if cx then
    local dx,dy=cx-i.x,cy-i.y
    if bestd2>0.1 then
     local d=sqrt(bestd2)
     local invd=1/d
     local fall=1-min(d/50,1) -- 50 = hole pull radius (spawn_hole's r)
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
    capv(i,0.6)
   end
  end
 end
end

-- Pull particles toward point
function p_pull(cx,cy,r,str,types)
 local r2=r*r
 for i in all(p) do
  if types[i.t] then
   local dx,dy=cx-i.x,cy-i.y
   local d2=dx*dx+dy*dy
   if d2>0.5 and d2<r2 then
    local invd,acc=1/sqrt(d2),str*(1-d2/r2)
    i.dx+=dx*invd*acc
    i.dy+=dy*invd*acc
    -- Limit debris speed like original
 if i.t==4 then
     capv(i,2)
    end
   end
  end
 end
end

-- Absorb particles in rect
function p_absorb(hx,hy,hw,hh,types)
 for i in all(p) do
  if types[i.t] and i.x>=hx and i.x<hx+hw and i.y>=hy and i.y<hy+hh then
   del(p,i)
  end
 end
end
