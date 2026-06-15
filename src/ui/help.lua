local hp,MP=1,6

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
   {18,"fire rate","faster shots"},
   {19,"shield","lasts longer"},
   {24,"spread","more lasers"},
   {17,"hull","+1 max hull"},
   {25,"thrusters","+ top speed"},
   {20,"shock","blast on hit"}
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
  spr(48,8,y) print("\f8asteroid\f6",20,y+1,7) print("loot + debris",62,y+1,6)
  y+=13
  spr(49,8,y,2,2)
  print("\f8big asteroid\f6",28,y+1,7) print("more loot; splits",28,y+9,6)
  y+=20
  print("\fccomets\f6 (round 3+):",8,y,7)
  y+=9
  -- live comet art (base 51) recoloured per variant: magnet/rapid/hull/charge/bomb (red)
  local csrc=split"1,3,11,10"
  local cramps={split"2,8,14,7",split"4,9,10,7",split"1,3,11,10",split"1,15,12,6",split"2,8,9,10"}
  local comets={{35,"magnet"},{34,"rapid"},{32,"hull"},{33,"charge"},{36,"bomb"}}
  for i=1,5 do
   local cx=10+((i-1)%2)*58
   local cy=y+((i-1)\2)*11
   for k=1,4 do pal(csrc[k],cramps[i][k]) end
   spr(51,cx,cy) pal()
   spr(comets[i][1],cx+9,cy)
   print(comets[i][2],cx+19,cy+2,6)
  end
 elseif hp==4 then
  -- hazards 2: black holes
  shead("black holes",30)
  -- live 16x16 black-hole art (bases 236/238), alternating like draw_blackhole
  spr(flr(time()*8)%2==0 and 236 or 238,56,36,2,2)
  local y=52
  print("appear at \f9round 5\f6",8,y,6) y+=8
  print("\f8pull your ship inward\f6",8,y,7) y+=8
  print("swallow asteroids & loot",8,y,6) y+=8
  print("\f8one-shot kill if exposed\f6",8,y,8) y+=8
  print("\fcshield\f6 lives / takes 1 hit",8,y,6) y+=10
  print("\fcsurvive:\f6 thrust away early",8,y,6) y+=8
  print("keep your distance",8,y,6)
 elseif hp==5 then
  -- powerups: dropped by comets / found in-flight. animated palette-swapped ring + icon.
  shead("powerups",30)
  local items={
   -- {icon,name,desc,glow1,glow2} -- ring recolours 7/13 -> the two glow tones, toggling
   {32,"hull","+1 hp",11,3},
   {33,"charge","shield + free",12,15},
   {34,"rapid","burst fire 6s",10,9},
   {35,"magnet","pulls loot in",14,2},
   {36,"bomb","blast on grab",8,2}
  }
  local y=42
  for i=1,#items do
   local it=items[i]
   local s=flr(time()*8)%2==0
   pal(7,s and it[4] or it[5]) pal(13,s and it[5] or it[4])
   sspr(80,16,9,9,5,y-2)
   pal()
   spr(it[1],7,y)
   rprint(it[2],22,y,10,4)
   print(it[3],54,y,6)
   y+=12
  end
  print("\f5powerups reset each round",8,106,5)
 else
  -- credits: cash from destroyed hazards. three coin tiers, kept between rounds.
  shead("credits",30)
  local coins={
   {52,"bronze","+1 cash"},
   {68,"silver","+2 cash"},
   {84,"gold","+5 cash"}
  }
  local y=50
  for i=1,#coins do
   local it=coins[i]
   local a=flr(time()*8)%4 -- 3-frame spin (base,+1,+2,+1) from its base tile
   spr(it[1]+min(a,4-a),7,y)
   rprint(it[2],22,y,10,4)
   print(it[3],54,y,6)
   y+=16
  end
  print("\f5cash carries between rounds",8,108,5)
 end

 -- footer: page nav + exit
 print("⬅️➡️ page    ❎ back",24,118,5)
end
