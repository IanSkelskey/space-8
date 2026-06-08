-- procedural parallax starfield (no map/sprite tiles)
-- each layer: {scroll speed, color, star count}
-- slower + dimmer = farther away. brighter + faster = nearer.
local LS,LC,LN=split".08,.25,.5,1",split"1,5,6,7",split"16,13,10,7"

-- distant planets/moons: slowest far layer, drawn as the original sprite tiles
-- each entry: {sprite id, tile width}
local PSP,PW=split"92,93,94,95,109,110,111,76,78",split"1,1,1,1,1,1,1,2,2"
local PLANET_SPD=0.08
local PLANET_N=3

local stars,planets={},{}
ss=1

-- (re)assign a planet a random sprite and x, placed at row y
local function set_planet(p,y)
 local d=flr(rnd(#PSP))+1
 p.sp,p.w=PSP[d],PW[d]
 p.x,p.y=rnd(128-p.w*8),y
end

function starfield_init()
 stars={}
 for li=1,#LS do
  local sp,col,n=LS[li],LC[li],LN[li]
  for i=1,n do
   add(stars,{
    x=rnd(128),y=rnd(128),
    s=sp,c=col,
    tw=li==#LS, -- only the nearest layer twinkles
    ph=rnd(1)       -- twinkle phase so they're not synced
   })
  end
 end
 planets={}
 for i=1,PLANET_N do local p={} set_planet(p,rnd(128)) add(planets,p) end
end

function update_starfield()
 for st in all(stars) do
  st.y+=st.s*ss
  if st.y>=128 then st.y-=128 st.x=rnd(128) end
 end
 for p in all(planets) do
  p.y+=PLANET_SPD*ss
  if p.y>=136 then set_planet(p,-8) end -- offscreen below, respawn above
 end
end

function draw_starfield()
 -- planets sit farthest back, behind all star layers
 for p in all(planets) do spr(p.sp,p.x,p.y,p.w,1) end
 local t=time()
 for st in all(stars) do
  local c=st.c
  if st.tw and (t+st.ph)%1<0.12 then c=13 end -- brief dim flicker
  pset(st.x,st.y,c)
 end
end
