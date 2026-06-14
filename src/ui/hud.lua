score,scoreh,ts,tsh,db=0,0,0,0,0

function hud_init()score,scoreh=0,0 end

function hud_add_score(n)
 if bhabsorb then return end -- black-hole kills don't score (set in update_blackhole)
 if ship and ship.dying then return end -- no scoring once dead (bullets in flight, etc.)
 local m=flr(n*dsc[df]+0.5)
 score+=m ts+=m
 while score>=1000 do score-=1000 scoreh+=1 end
 while ts>=1000 do ts-=1000 tsh+=1 end
end

-- one borderless slanted 3px bar: width w at (x,y) in colour c
-- (each row up shifts 1px right, giving a 2px italic lean over the 3px height)
function sbar(x,y,w,c) for r=0,2 do rectfill(x+2-r,y+r,x+1-r+w,y+r,c) end end

-- temp-effect icon at x (status row): when active, the colour sprite `id` plus a
-- remaining-time bar (t of tm) the width of the 5px icon, 1px below the icon art;
-- otherwise the dimmed grayscale `gid`.
function fxi(x,id,gid,t,tm,c)
 if t>0 then spr(id,x,8) rectfill(x,14,x+t/tm*4,14,c)
 else spr(gid,x,8) end
end

-- raised text: a darker copy 1px below, then the main colour on top. matches the ui cart's
-- rprint (which lives in font.lua, not included in this gameplay cart) so the hud reads the same.
function rprint(t,x,y,m,s) print(t,x,y+1,s) print(t,x,y,m) end

function draw_hud()
 -- score (left) + money (right), on the top band's text row -- raised to match the rest of the game
 local ls="00"..score
 rprint(scoreh>0 and (scoreh..sub(ls,#ls-2)) or score,2,2,7,5) -- gray shadow reads on the black band
 local run=(game_state=="game" or game_state=="dying")
 local sa=(run and last_payout_ready) and (money_total-last_pay-last_bonus) or money_total
 local ns=""..sa rprint(ns,125-#ns*4,2,10,9) spr(80,119-#ns*4,2)
 -- hull meter: FIXED 24px total (divisible by 2/3/4) split into mh EQUAL segments, so the
 -- bar is the same size for 2/3/4 hulls; filled=green, lost=grey. icon (spr 32) at left.
 spr(32,26,2)
 local mh=2+ship.hull_level local sw=24\mh
 for i=0,mh-1 do sbar(33+i*sw,3,sw-1,i<ship.hull and 11 or 5) end
 -- shield meter: icon + fill colour reflect the shock upgrade (spr 41 / warm ramp vs spr 33 / cool ramp).
 -- during a free (powerup) shield it shows the countdown, flashing, so a pinned-full bar can't read as charge.
 local shk=ship.shield_pulse_level>0
 spr(ship.shield_unlocked and(shk and 41 or 33)or 38,63,2)
 local fr=ship.shield_free
 local sp=fr>0 and fr/110 or ship.shield_power/100
 sbar(70,3,24,1)
 local fw=flr(sp*24)
 if fw>0 then
  local c=fr>0 and(flr(time()*8)%2<1 and 7 or(shk and 8 or 12))
   or(shk and(sp>.5 and 8 or sp>.25 and 9 or 2)or(sp>.5 and 12 or sp>.25 and 13 or 1))
  sbar(70,3,fw,c)
 end
 -- temp-effect status row (y8): rapid fire, free shield (shock-aware icon/colour), magnet.
 -- always shown (grayscale dim icons 37/38/39 when idle); active = colour icon + colour time bar.
 fxi(26,35,37,ship.rfb,120,10)
 fxi(33,shk and 41 or 33,38,ship.shield_free,110,shk and 8 or 12)
 fxi(40,36,39,ship.magnet_t,420,14)
 -- mission progress: full-width 1px bar at the very bottom of the band (slimmed from 2px to give
 -- the status row a clear margin above it -- 1px gap under the icons, then the timer row, then this)
 if run and mission_distance>0 then
  local pt=min(1,(mission_distance-(dr or mission_distance))/mission_distance)
  db=mid(pt,db-0.02,db+0.02) -- ease toward pt, 0.02/frame
  local w=db*124
  rectfill(2,17,125,17,1)
  if w>0 then rectfill(2,17,1+w,17,db>0.95 and(flr(time()*4)%2==0 and 6 or 13)or 13) end
 end
end
