local hp,MP=1,6

-- help pages as single strings with newlines
local hd={
 -- page 1: loop + controls (updated and concise)
 "\fcmission flow\f6:\n\n 1. pick difficulty\n 2. fill \fddistance\f6 bar\n 3. dodge, shoot, collect\n 4. land for payout\n 5. upgrade & relaunch\n\n\fccontrols\f6:\n\n move ship      \f9⬅️⬆️⬇️➡️\f6\n shoot lasers   \f9🅾️\f6\n shield (hold)  \f9❎\f6\n\n shield drains power;\n release to recharge",
 -- page 2: upgrades (current items)
 "\fcupgrades\f6:\n\n\f9fire rate\f6   faster shots\n\f9shield\f6      stronger wall\n\f9spread\f6      side beams\n\f9hull\f6        +max hp\n\f9thrusters\f6   more top speed\n\f9shock\f6       pulse on hit\n\nTip: spread + rate = DPS ramp",
 -- page 3: obstacles part 1 (asteroids & comets)
 "",
 -- page 4: obstacles part 2 (black holes)
 "",
 -- page 5: powerups & pickups (accurate)
 "\fcpowerups\f6:\n\n \f9hull\f6    +1 hp (if room)\n \f9charge\f6  full shield + \f8free\f6 time\n \f9credits\f6 +$ bonus payout\n \f9rapid\f6   short burst fire\n \f9magnet\f6  attract loot safely\n\nCash persists between runs;\nlost only on death.",
 -- page 6: tips (matching mechanics)
 "\fctips\f6:\n\n • magnet = safer pickups\n • finish runs, then spend\n • higher diff = +risk/+pay\n • shock hurts clusters\n • prioritize comets > holes\n • upgrade spread + fire rate\n • score high → highscores"
}

function help_init() hp=1 end

function update_help()
 if btnp(0) and hp>1 then hp-=1 snd_sfx(44,3) end
 if btnp(1) and hp<MP then hp+=1 snd_sfx(44,3) end
 if btnp(4) or btnp(5) then snd_sfx(63,3) game_state="menu" menu_init() end
end

function draw_help()
 rectfill(0,0,127,15,1)
 print("◀",4,4,hp>1 and 7 or 1)
 spr(41,14,4) -- Add sprite 41 before "help" - moved down 1 pixel for alignment
 print("help - page "..hp.."/"..MP,24,4,7) -- Shifted text right to make room
 print("▶",100,4,hp<MP and 7 or 1) -- Shifted arrow right to match
 rect(1,17,126,118,1)
 
 if hp==2 then
  -- upgrades page with icons matching shop
  print("\fcupgrades\f6:",6,20,6)
  local entries={
   {11,"fire rate","faster shots"},
   {10,"shield","stronger wall"},
   {25,"spread","side beams"},
   {38,"hull","+max hp"},
   {55,"thrusters","more top speed"},
   {105,"shock","pulse on hit"}
  }
  local y=32
  for i=1,#entries do
   local icon,name,desc=entries[i][1],entries[i][2],entries[i][3]
   -- draw 5x5 icon
   sspr((icon%16)*8,flr(icon/16)*8,5,5,10,y,5,5)
   -- label and description columns
   print("\f9"..name.."\f6",22,y,10)
   print(desc,64,y,6)
   y+=12
  end
  -- tip line kept concise to fit width
  print("tip: spread + rate = dps ramp",8,y+6,5)
 elseif hp==3 then
    -- obstacles page 1: asteroids and comets
    print("\fcobstacles\f6:",6,20,6)

    -- asteroids
    local y=28
    spr(2,8,y)
    print("\f8asteroid\f6",20,y+1,7)
    print("points + \f9credits\f6 + 4 debris",8,y+10,6)
    
    -- large asteroid
    y+=22
    spr(7,8,y) spr(8,16,y)
    spr(23,8,y+8) spr(24,16,y+8)
    print("\f8large asteroid\f6",28,y+4,7)
    print("more loot, splits into 2",8,y+18,6)

    -- comets
    y+=32
    print("\fccomets\f6 (unlock round 3):",8,y,7)
    y+=8
    print("shoot for powerups:",8,y,6)
    y+=8
    local comets={
     {60,56,"magnet"},
     {61,11,"rapid"},
     {62,38,"hull"},
     {63,10,"charge"}
    }
    for i=1,2 do
     spr(comets[i][1],8+(i-1)*60,y)
     spr(comets[i][2],18+(i-1)*60,y)
     print(comets[i][3],28+(i-1)*60,y+2,6)
    end
    y+=10
    for i=3,4 do
     spr(comets[i][1],8+(i-3)*60,y)
     spr(comets[i][2],18+(i-3)*60,y)
     print(comets[i][3],28+(i-3)*60,y+2,6)
    end
 elseif hp==4 then
    -- obstacles page 2: black holes
    print("\fcobstacles\f6:",6,20,6)
    
    local y=30
    spr(3,56,y)
    
    y+=14
    print("\f8black hole\f6 (round 5+)",28,y,7)
    y+=10
    print("\f8pulls ship\f6 inward",8,y,7)
    y+=9
    print("absorbs all objects",8,y,6)
    y+=9
    print("\f8ignores shield\f6 - death",8,y,8)
    y+=12
    print("\fctips\f6:",8,y,7)
    y+=9
    print("• thrust away",8,y,6)
    y+=8
    print("• keep distance",8,y,6)
    y+=8
    print("• plan escapes",8,y,6)
 elseif hp==5 then
  -- powerups page with real in-game visuals
  print("\fcpowerups\f6:",6,20,6)
  local items={
   {38,"hull","+1 hp (if room)"},
   {10,"charge","shield + \f8free\f6 time"},
   {-1,"credits","+$ bonus payout"},
   {11,"rapid","burst fire boost"},
   {56,"magnet","pull loot to ship"}
  }
  local y=32
  for i=1,#items do
   local icon,name,desc=items[i][1],items[i][2],items[i][3]
   -- draw visual (sprite or special rendering)
   if icon==-1 then
    -- money shards: cluster of 3 with shimmer + bobbing animation
    local t=time()
    for j=1,3 do
     local ox=(j-2)*3
     local yoff=(j==2) and 0 or -2
     local bob=sin(t*0.8+j*0.3)*0.7
     local cx,cy=10+ox,y+2+bob+yoff
     local c=(t*8+j*2)%8<4 and 10 or 9
     pset(cx,cy,c) pset(cx+1,cy,c) pset(cx,cy+1,c) pset(cx+1,cy+1,c)
     if (t*12+j)%15<1 then pset(cx+1,cy-1,7) end
    end
   else
    -- regular sprite icon
    spr(icon,8,y)
   end
   -- label and description
   print("\f9"..name.."\f6",20,y,10)
   print(desc,52,y,6)
   y+=12
  end
  print("powerups reset each round",8,y+6,6)
  print("credits accumulate",8,y+16,6)
 elseif hp==6 then
  -- bullet tips with tighter lines for width safety
  print("\fctips\f6:",6,20,6)
  local tips={
   "magnet = safer pickups",
   "finish runs, then spend",
   "higher diff = +risk/+pay",
   "shock breaks debris",
   "score high for highscores"
  }
  local y=32
  for i=1,#tips do
   print("• "..tips[i],8,y,7)
   y+=12
  end
 else
  -- use cursor() and print with built-in word wrap for other pages
  cursor(6,20)
  color(6)
  print(hd[hp])
 end
 
 -- footer
 print("❎/🅾️ back",44,120,5)
end
