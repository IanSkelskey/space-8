-- round-clear summary screen (ui cart). the round-clear jingle finished in the gameplay cart,
-- so this screen runs under the menu loop (started in boot); advancing to the station is what
-- starts the station music. kills/round-score come via cartdata (slots 33/47, written by the
-- gameplay cart); payout/bonus are loaded into globals by lg().
local skills,sscore,st_=0,0,0

-- one row: label left at x34, value right-aligned to x94, both colour c
local function srow(y,l,v,c) print(l,34,y,c) v=""..v print(v,94-#v*4,y,c) end

function summary_init()
 skills=dget(33) sscore=dget(47) st_=0
end

function update_summary()
 st_+=1
 if st_>40 and(btnp(4)or btnp(5)) then
  snd_sfx(63) game_state="station" station_init() snd_music(10)
 end
end

function draw_summary()
 local a=min(1,st_/40)
 draw_logo("round clear",28,11,3,11,3,1.5) -- block-letter logo title with a gentle bob
 srow(48,"destroyed",flr(skills*a),7)
 srow(56,"score",flr(sscore*a),7)
 srow(70,"payout","+"..flr(last_pay*a),10)
 srow(78,"bonus","+"..flr(last_bonus*a),10)
 srow(88,"earned","$"..flr((last_pay+last_bonus)*a),10)
 if a>=1 and st_%30<20 then local l="🅾️ continue" print(l,64-#l*2,100,6) end
end
