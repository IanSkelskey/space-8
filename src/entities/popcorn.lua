local pops,pt={},0

function popcorn_init()pops,pt={},0 end

local function rflash() for i=1,15 do pal(i,8) end end

function update_popcorn()
 if round_number<2 then return end
 pt-=FT
 if pt<=0 and #pops<(round_number<5 and 1 or 2) then add(pops,{x=rnd(120),y=-8,dy=0.55+rnd(0.4),s=30+rndi(20),c=0,h=2,f=0,a=rnd()}) pt=1.2+rnd(1.5) end
 for e in all(pops) do
  if e.d then
   e.d+=1
   if e.d>=21 then del(pops,e) end
   goto continue
  end
  e.y+=e.dy*cs e.x+=sin(e.y/32+e.a)*.4*cs e.s-=1
  if e.f>0 then e.f-=1 end
  if e.s<=0 then
   if e.c<=0 then e.c=3+rndi(3) end
   p_add(e.x+4,e.y+4,mid(-1.2,(ship.x-e.x)/32,1.2),1.4,90,9) e.c-=1 e.s=e.c>0 and 8 or 45+rndi(30)
  end
  if hit_by_player_bullet(e.x+1,e.y+1,6,6) then
   e.h-=1 e.f=4 snd_sfx(1)
   if e.h<=0 then hud_add_score(20) e.d=1 e.fx=rnd()<.5 e.fy=rnd()<.5 end
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
  if e.d then
   if e.d<3 then
    rflash()
    spr(17,e.x,e.y) pal()
   else
    local f=(e.d-3)\3
    if f<6 then pal(1,2)pal(3,8)pal(11,9)spr(202+f,e.x,e.y,1,1,e.fx,e.fy)pal() end
   end
  else
   if e.f>0 then rflash() end
   local x,y=e.x,e.y
   if e.f>0 then x+=rndi(3)-1 y+=rndi(3)-1 end
   spr(e.c>0 and 17 or 1,x,y)
   if e.f>0 then pal() end
  end
 end
end
