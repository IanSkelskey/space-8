local pops,pt={},0

function popcorn_init()pops,pt={},0 end

-- popcorn death: score + a money roll (a touch richer than asteroids) + boom + del.
-- shared by bullet kills and the bomb shockwave (uses cash() from asteroid.lua).
local function pkill(e)
	hud_add_score(20)
	if rnd()<0.65 then cash(e.x+4,e.y+4,2+rndi(3)) end
	boom(e.x,e.y,EXR) del(pops,e)
end

-- black hole swallows popcorn: full death (pkill) so it pops + scores + drops loot
function popcorn_absorb(hx,hy,hw,hh)
 for e in all(pops) do
  if aabb(e.x,e.y,8,8,hx,hy,hw,hh) then pkill(e) end
 end
end

function update_popcorn()
 if round_number<2 then return end
 pt-=FT
 if pt<=0 and #pops<(round_number<5 and 1 or 2) then add(pops,{x=rnd(120),y=-8,dy=0.55+rnd(0.4),s=30+rndi(20),c=0,h=2,f=0,a=rnd()}) pt=1.2+rnd(1.5) end
 for e in all(pops) do
  -- bomb shockwave: trigger the normal death (score + money roll)
  if bhit(e.x+4,e.y+4) then pkill(e) goto continue end
  -- shield pulse (retaliation + shock aura) damages/vaporises popcorn
  local nh=shdmg(e.x+4,e.y+4,e.h)
  if nh<e.h then e.f=4 e.h=nh if e.h<=0 then pkill(e) goto continue end end
  e.y+=e.dy*cs e.x+=sin(e.y/32+e.a)*.4*cs
  if e.f>0 then e.f-=1 end
  e.s-=1
  if e.c>0 then
   if e.s==6 then p_add(e.x+4,e.y+4,mid(-1.2,(ship.x-e.x)/32,1.2),1.4,90,9) end
   if e.s<=0 then e.c-=1 e.s=e.c>0 and 12 or 45+rndi(30) end
  elseif e.s<=0 then
   e.c=3+rndi(3) e.s=12
  end
  if hit_by_player_bullet(e.x+1,e.y+1,6,6) then
   e.h-=1 e.f=4 snd_sfx(1)
   if e.h<=0 then pkill(e) end
  elseif scoll(e.x+1,e.y+1,6,6) then
   ship_kill()
  elseif e.y>136 then
   del(pops,e)
  end
  ::continue::
 end
end

function draw_popcorn()
 for e in all(pops) do
  if e.f>0 then fl(8) end
  local x,y=e.x,e.y
  if e.f>0 then x+=jit() y+=jit() end
  spr(e.c>0 and(e.s>6 and 17 or 33)or 1,x,y)
  if e.f>0 then pal() end
 end
end
