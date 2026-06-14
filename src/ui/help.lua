local hp,MP=1,5

function help_init() hp=1 end

function update_help()
 if btnp(0) and hp>1 then hp-=1 snd_sfx(16,3) end
 if btnp(1) and hp<MP then hp+=1 snd_sfx(16,3) end
 if btnp(4) or btnp(5) then snd_sfx(17,3) game_state="menu" menu_init() end
end

-- section header: a raised page heading in logo-blue
local function shead(t,y) rprint(t,8,y,12,1) end

function draw_help()
 -- header: block-letter title + page dots/arrows, on the starfield (no solid bar, no border)
 local fl=time()%0.8<0.4
 draw_logo("guide",4,fl and 12 or 7,fl and 1 or 12,fl and 12 or 7,fl and 1 or 12)
 -- page indicator: 5 dots centred on screen (middle dot lands on x64), flashing sprite arrows
 local dw=(MP-1)*5
 local x0=64-dw\2
 farrow(x0-14,17,false,hp>1)
 farrow(x0+dw+6,17,true,hp<MP)
 for i=1,MP do circfill(x0+(i-1)*5,20,1,i==hp and 12 or 5) end

 if hp==1 then
  -- how to play: mission loop + controls
  shead("mission loop",30)
  local steps=split"pick a difficulty,fill the distance bar,dodge / shoot / collect,land for your payout,upgrade then relaunch"
  local y=40
  for i=1,#steps do print("\f9"..i.."\f6 "..steps[i],10,y,6) y+=9 end
  shead("controls",90)
  print("move  \f9⬅️⬆️⬇️➡️\f6   shoot \f9🅾️",10,100,6)
  print("shield \f9❎\f6 (hold; it drains)",10,109,6)
 elseif hp==2 then
  -- permanent upgrades (descriptions match the shop)
  shead("upgrades",30)
  local e={
   {83,"fire rate","faster shots"},
   {84,"shield","lasts longer"},
   {87,"spread","more lasers"},
   {82,"hull","+1 max hull"},
   {86,"thrusters","+ top speed"},
   {85,"shock","blast on hit"}
  }
  local y=42
  for i=1,#e do
   spr(e[i][1],9,y) -- icon at y, text at y+2
   rprint(e[i][2],22,y+2,10,4)
   print(e[i][3],66,y+2,6)
   y+=11
  end
  print("\f5buy these at the station shop",8,108,5)
 elseif hp==3 then
  -- hazards 1: asteroids, then comets (two labelled sections, no repeated word)
  shead("asteroids",30)
  local y=42
  spr(2,8,y) print("\f8asteroid\f6",20,y+1,7) print("loot + debris",62,y+1,6)
  y+=13
  spr(7,8,y) spr(8,16,y) spr(23,8,y+8) spr(24,16,y+8)
  print("\f8big asteroid\f6",28,y+1,7) print("more loot; splits",28,y+9,6)
  y+=24
  print("\fccomets\f6 (round 3+):",8,y,7)
  y+=10
  -- live comet art (200) recoloured per variant: magnet/rapid/hull/charge
  local csrc=split"1,3,11,10"
  local cramps={split"2,8,14,7",split"4,9,10,7",split"1,3,11,10",split"1,15,12,6"}
  local comets={{56,"magnet"},{11,"rapid"},{38,"hull"},{10,"charge"}}
  for i=1,4 do
   local cx=10+((i-1)%2)*58
   local cy=y+((i-1)\2)*11
   for k=1,4 do pal(csrc[k],cramps[i][k]) end
   spr(200,cx,cy) pal()
   spr(comets[i][1],cx+9,cy)
   print(comets[i][2],cx+19,cy+2,6)
  end
 elseif hp==4 then
  -- hazards 2: black holes
  shead("black holes",30)
  -- spinning 2x sprite (same flip cycle as the live black hole)
  local ph=flr(time()*8)%4
  sspr(24,0,8,8,56,36,16,16,ph==1 or ph==2,ph==2 or ph==3)
  local y=52
  print("appear at \f9round 5\f6",8,y,6) y+=8
  print("\f8pull your ship inward\f6",8,y,7) y+=8
  print("swallow asteroids & loot",8,y,6) y+=8
  print("\f8death on contact\f6",8,y,8) y+=8
  print("shield won't save you",8,y,6) y+=10
  print("\fcsurvive:\f6 thrust away early",8,y,6) y+=8
  print("keep your distance",8,y,6)
 else
  -- powerups (dropped by comets / found in-flight). icon at y, text at y+2 to match the
  -- comet rows on page 3.
  shead("powerups",30)
  local items={
   {38,"hull","+1 hp"},
   {10,"charge","shield + free"},
   {-1,"credits","cash bonus"},
   {11,"rapid","burst fire 6s"},
   {56,"magnet","pulls loot in"}
  }
  local y=42
  for i=1,#items do
   local icon=items[i][1]
   if icon==-1 then
    -- spinning coin, matching the in-game gold credit animation (frames 128,129,130,129)
    spr(130-abs(2-flr(time()*8)%4),7,y+1)
   else
    spr(icon,7,y)
   end
   rprint(items[i][2],22,y+2,10,4)
   print(items[i][3],54,y+2,6)
   y+=12
  end
  print("\f5powerups reset each round",8,106,5)
 end

 -- footer: page nav + exit
 print("\f6⬅️➡️ page    \f9❎\f6 back",24,118,5)
end
