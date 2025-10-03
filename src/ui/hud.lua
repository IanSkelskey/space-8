score=score or 0 -- run low part
scoreh=scoreh or 0 -- run thousands
ts=ts or 0     -- total low part
tsh=tsh or 0   -- total thousands
db=db or 0
gs=gs or game_state

function hud_init()score,scoreh=0,0 end

function hud_add_score(n)
 local m=flr(((n or 0)*(dsc and dsc[df] or 1))+0.5)
 score+=m ts+=m
 while score>=1000 do score-=1000 scoreh+=1 end
 while ts>=1000 do ts-=1000 tsh+=1 end
end

function draw_hud()
 local ls="00"..score
 local ds=scoreh>0 and (scoreh..sub(ls,#ls-2)) or score
 print(ds,2,2,7)
 local gsx,gsn=game_state,gs
 local run=(gsx=="game" or gsx=="fanfare_depart" or gsx=="dying")
 local sa=(run and last_payout_ready) and (money_total-last_pay-last_bonus) or money_total
 local t="$"..sa print(t,127-#t*4-2,2,10)
 spr(38,30,2)
 local h,m=ship.hull,2+ship.hull_level local bw=min(20,m*10) rectfill(37,3,36+bw,5,0) local sw=bw/m for i=1,h do local sx=37+(i-1)*sw rectfill(sx,3,sx+sw-2,5,11) end rect(37,3,36+bw,5,5)
 spr(10,58,2)
 local sp=ship.shield_power local fw=sp>0 and sp*0.2\1 or 0 rectfill(65,3,84,5,0) if fw>0 then local r=sp/100 rectfill(65,3,64+fw,5,r>0.5 and 12 or(r>0.25 and 13 or 8)) end rect(65,3,84,5,5)
 if gsn~=gsx then if gsx=="game" and (gsn!="fanfare_depart" and gsn!="fanfare_arrive") then db=0 end gs=gsx end
 if (run or gsx=="fanfare_arrive") and mission_distance and mission_distance>0 then local t=level_fanfare_timer>0 and 1 or min(1,(mission_distance-(dr or mission_distance))/mission_distance) db=db<t and min(t,db+0.02) or(db>t and max(t,db-0.02) or db) local bx,by,bw=20,122,88 local w=db*bw rectfill(bx,by,bx+bw-1,123,1) if w>0 then rectfill(bx,by,bx+w-1,123,13) if db>0.95 then rectfill(bx+w-2,by,bx+w-1,123,flr(time()*4)%2==0 and 6 or 13) end end spr(39,111,119) end
end
