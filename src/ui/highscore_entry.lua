-- Dedicated highscore name entry screen
local entry_name = {0,0,0}
local entry_pos = 1
-- score kept split (hi=thousands, lo=0-999); recombining overflows pico-8's 32767 cap
local entry_hi = 0
local entry_lo = 0
local entry_rank = 0
local blink_timer = 0

function highscore_entry_init()
 entry_lo,entry_hi = persist_fetch_last_run()
 entry_name = {0,0,0}
 entry_pos = 1
 blink_timer = 0

 -- Determine rank this score will achieve
 local di = df or 1
 local t = hs_sets[di]
 entry_rank = #t + 1
 for i=1,#t do
  if hs_gt(entry_hi,entry_lo,t[i].hi,t[i].lo) then
   entry_rank = i
   break
  end
 end
end

function update_highscore_entry()
 blink_timer = (blink_timer + 1) % 30
 
 -- Letter selection
 if btnp(2) then -- up
  entry_name[entry_pos] = (entry_name[entry_pos] + 1) % 26
  snd_sfx(44)
 elseif btnp(3) then -- down  
  entry_name[entry_pos] = (entry_name[entry_pos] - 1 + 26) % 26
  snd_sfx(44)
 end
 
 -- Position navigation
 if btnp(0) and entry_pos > 1 then -- left
  entry_pos -= 1
  snd_sfx(44)
 elseif btnp(1) and entry_pos < 3 then -- right
  entry_pos += 1
  snd_sfx(44)
 end
 
 -- Confirm name
 if btnp(4) then -- O button
  if entry_pos < 3 then
   entry_pos += 1
   snd_sfx(63)
  else
   -- Save the highscore
   local hi = entry_hi
   local lo = entry_lo
   local nc = entry_name[1]*676 + entry_name[2]*26 + entry_name[3]

   -- Insert into appropriate difficulty table
   local di = df or 1
   local t = hs_sets[di]
   local inserted = false
   for i=1,#t do
    if hs_gt(entry_hi,entry_lo,t[i].hi,t[i].lo) then
     add(t,{hi=hi,lo=lo,nc=nc},i)
     inserted = true
     break
    end
   end
   if not inserted then add(t,{hi=hi,lo=lo,nc=nc}) end
   while #t > 4 do del(t,t[#t]) end
   
   -- Save to persistent storage
   local I_CNT,I_BASE = persist_hs_indices_for_df(di)
   dset(I_CNT,#t)
   for i=1,#t do
    local e=t[i]
    local o=I_BASE+(i-1)*3
    dset(o,e.hi)
    dset(o+1,e.lo)
    dset(o+2,e.nc)
   end
   
   persist_clear_last_run()
   game_state = "menu"
   menu_init()
   snd_sfx(63)
  end
 end
 
 -- Cancel entry
 if btnp(5) then -- X button
  persist_clear_last_run()
  game_state = "menu"
  menu_init()
  snd_sfx(44)
 end
end

function draw_highscore_entry()
 -- Title: block-letter logo, gold flash with a darker drop layer for depth
 local fl=time()%0.8<0.4
 draw_logo("high score!",14,fl and 9 or 10,fl and 4 or 9,fl and 9 or 10,fl and 4 or 9,1.5)
 
 -- Score display (format split score without recombining)
 local els="00"..entry_lo
 local score_str = entry_hi>0 and (entry_hi..sub(els,#els-2)) or (""..entry_lo)
 print(score_str, 64-#score_str*2, 32, 11)
 
 -- Rank with trophy on same line
 local trophy_sprs = {50,103,104} -- gold, silver, bronze
 if entry_rank <= 3 then
  spr(trophy_sprs[entry_rank], 40, 44)  -- moved from 42 to 44 (down 2 pixels)
 end
 local rank_str = "rank #"..entry_rank
 print(rank_str, 64-#rank_str*2, 44, 10)
 
 -- Name entry label
 print("enter name:", 42, 58, 6)
 
 -- Letter display with cursor (nudged down for better centering)
 local letters = "abcdefghijklmnopqrstuvwxyz"
 for i=1,3 do
  local x = 44 + (i-1)*14  -- base position for frame
  local y = 82
  local letter = sub(letters,entry_name[i]+1,entry_name[i]+1)
  
  -- Highlight current position
  if i == entry_pos then
   -- Blinking background
   if blink_timer < 15 then
    rectfill(x-2,y-2,x+6,y+6,1)
   end
   print(letter,x+1,y,10)  -- letter nudged right 1 pixel within frame
   
   -- Show up/down arrow characters (centered with letter)
   print("⬆️",x-1,y-10,time()%0.4<0.2 and 11 or 5)  -- shifted left from x+1 to x
   print("⬇️",x-1,y+10,time()%0.4<0.2 and 11 or 5)  -- shifted left from x+1 to x
  else
   print(letter,x+1,y,6)  -- also nudge non-selected letters for consistency
  end
 end
 
 -- Instructions pushed to bottom
 print("⬆️⬇️ change  ⬅️➡️ move",20,108,5)
 print("🅾️ confirm  ❎ cancel",22,116,7)
end