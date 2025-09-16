local hp,MP=1,4

-- help pages as single strings with newlines
local hd={
 "\fcgameplay loop\f6:\n 1. deliver tech packages\n 2. earn cash rewards\n 3. upgrade your ship\n 4. launch into space\n 5. survive obstacles\n 6. return to station\n\n\fccontrols\f6:\n move: arrow keys/d-pad\n shoot: 🅾️ button\n shield: ❎ (hold)",
 "\fcupgrades\f6:\n\n\f9fire rate\f6\n  faster weapon recharge\n\n\f9shield\f6\n  blocks damage when held\n\n\f9spread\f6\n  adds extra projectiles\n\n\f9hull\f6\n  increases max health\n\n\f9thrusters\f6\n  faster acceleration",
 "", -- page 3 will be custom drawn for sprites
 "\fctips\f6:\n\n • shield blocks all damage\n • prioritize dangerous foes\n • collect tech packages\n • upgrade before harder runs\n • comets move fast\n • black holes pull you in\n • asteroids drift slowly"
}

function controls_init() hp=1 end

function update_controls()
 if btnp(0) and hp>1 then hp-=1 snd_sfx(SFX_CURSOR,UI_CH) end
 if btnp(1) and hp<MP then hp+=1 snd_sfx(SFX_CURSOR,UI_CH) end
 if btnp(4) or btnp(5) then snd_sfx(SFX_OK,UI_CH) game_state="menu" menu_init() end
end

function draw_controls()
 rectfill(0,0,127,15,1)
 print("◀",4,4,hp>1 and 7 or 1)
 print("help - page "..hp.."/"..MP,16,4,7)
 print("▶",90,4,hp<MP and 7 or 1)
 rect(1,17,126,118,1)
 
 if hp==3 then
  -- custom draw for obstacles page with sprites
  print("\fcobstacles\f6:",6,20,6)
  
  -- asteroid
  spr(2,10,32) -- asteroid sprite (id 2) - single sprite
  print("\f8asteroid\f6",22,33,5)
  print("slow; +points",28,40,13)
  print("splits into chunks",28,47,13)
  
  -- comet  
  spr(43,10,58) -- comet sprite (id 51) - single sprite
  print("\f8comet\f6",22,59,5)
  print("fast diagonal",28,66,13)
  print("hard to avoid",28,73,13)
  
  -- black hole
  spr(3,10,84) -- black hole sprite (id 3) - single sprite
  print("\f8black hole\f6",22,85,5)
  print("pulls you in",28,92,13)
  print("ignores hull",28,99,13)
 else
  -- use cursor() and print with built-in word wrap for other pages
  cursor(6,20)
  color(6)
  print(hd[hp])
 end
 
 print("❎/🅾️ back",44,120,5)
end
