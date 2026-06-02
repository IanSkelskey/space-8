-- procedural parallax starfield (no map/sprite tiles)
-- each layer: {scroll speed, color, star count}
-- slower + dimmer = farther away. brighter + faster = nearer.
local LAYERS={
 {0.08,1,16}, -- deep background: faint dark-blue dust
 {0.25,5,13}, -- far: dark grey
 {0.50,6,10}, -- mid: light grey
 {1.00,7,7}   -- near: white (twinkles)
}

-- distant planets/moons: slowest far layer, drawn as the original sprite tiles
-- each entry: {sprite id, tile width}
local PLANET_SPR={
 {92,1},{93,1},{94,1},{95,1},{109,1},{110,1},{111,1},
 {76,2},{78,2} -- two-tile-wide nebula planets
}
local PLANET_SPD=0.08
local PLANET_N=3

local stars,planets={},{}

-- (re)assign a planet a random sprite and x, placed at row y
local function set_planet(p,y)
 local d=PLANET_SPR[flr(rnd(#PLANET_SPR))+1]
 p.sp,p.w=d[1],d[2]
 p.x,p.y=rnd(128-p.w*8),y
end

function starfield_init()
 stars={}
 for li=1,#LAYERS do
  local sp,col,n=LAYERS[li][1],LAYERS[li][2],LAYERS[li][3]
  for i=1,n do
   add(stars,{
    x=rnd(128),y=rnd(128),
    s=sp,c=col,
    tw=li==#LAYERS, -- only the nearest layer twinkles
    ph=rnd(1)       -- twinkle phase so they're not synced
   })
  end
 end
 planets={}
 for i=1,PLANET_N do local p={} set_planet(p,rnd(128)) add(planets,p) end
end

function update_starfield()
 local ssc=ss or 1
 for st in all(stars) do
  st.y+=st.s*ssc
  if st.y>=128 then st.y-=128 st.x=rnd(128) end
 end
 for p in all(planets) do
  p.y+=PLANET_SPD*ssc
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
