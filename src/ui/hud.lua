score,scoreh,ts,tsh,db=0,0,0,0,0

function hud_init()score,scoreh=0,0 end

function hud_add_score(n)
 if bhabsorb then return end -- black-hole kills don't score (set in update_blackhole)
 local m=flr(n*dsc[df]+0.5)
 score+=m ts+=m
 while score>=1000 do score-=1000 scoreh+=1 end
 while ts>=1000 do ts-=1000 tsh+=1 end
end

-- one borderless slanted 3px bar: width w at (x,y) in colour c
-- (each row up shifts 1px right, giving a 2px italic lean over the 3px height)
function sbar(x,y,w,c) for r=0,2 do rectfill(x+2-r,y+r,x+1-r+w,y+r,c) end end

function draw_hud()
 -- score (left) + money (right), on the top band's text row
 local ls="00"..score
 print(scoreh>0 and (scoreh..sub(ls,#ls-2)) or score,2,2,7)
 local run=(game_state=="game" or game_state=="dying")
 local sa=(run and last_payout_ready) and (money_total-last_pay-last_bonus) or money_total
 local mt="$"..sa print(mt,127-#mt*4-2,2,10)
 -- hull meter: FIXED 24px total (divisible by 2/3/4) split into mh EQUAL segments, so the
 -- bar is the same size for 2/3/4 hulls; filled=green, lost=grey. icon (spr 38) at left.
 spr(38,26,2)
 local mh=2+ship.hull_level local sw=24\mh
 for i=0,mh-1 do sbar(33+i*sw,3,sw-1,i<ship.hull and 11 or 5) end
 -- shield meter: same fixed 24px length, continuous fill by power%. icon (spr 10) at left.
 spr(10,63,2)
 local sp=ship.shield_power
 sbar(70,3,24,1)
 local fw=flr(sp/100*24)
 if fw>0 then sbar(70,3,fw,sp>50 and 12 or(sp>25 and 13 or 8)) end
 if ship.magnet_t>0 then spr(56,96,2) end
 -- mission progress: full-width thin bar inside the band (was the old bottom-screen bar)
 if run and mission_distance>0 then
  local pt=level_fanfare_timer>0 and 1 or min(1,(mission_distance-(dr or mission_distance))/mission_distance)
  db=db<pt and min(pt,db+0.02) or(db>pt and max(pt,db-0.02) or db)
  local w=db*124
  rectfill(2,10,125,11,1)
  if w>0 then rectfill(2,10,1+w,11,db>0.95 and(flr(time()*4)%2==0 and 6 or 13)or 13) end
 end
end
