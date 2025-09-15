local sel,page,shop_msg,shop_msg_t=1,1,"",0
local FM,SC,SM,TM,smc=3,120,2,3,11
SFX_CURSOR=SFX_CURSOR or 44
SFX_ERR=SFX_ERR or 45
SFX_OK=SFX_OK or 63
UI_CH=UI_CH or 3

-- item data: icon,max,cost_base,cost_inc,stat_field,unlock_field,desc
local items={
 {11,FM,100,50,"fire_rate_level",nil,"fire rate +20%","+ faster shots"},
 {10,3,SC,80,"shield_level","shield_unlocked","shield upgrade","+ more shield"},
 {25,SM,150,100,"spread_level",nil,"phaser spread +1","+ wider spread"},
 {38,2,200,150,"hull_level",nil,"hull +1 segment","+ more hull"},
 {54,99,200,0,nil,nil,"repair hull","+ restore 1 hull"},
 {55,TM,80,60,"thruster_level",nil,"thruster boost","+ faster accel"}
}

function shop_init() sel,page,shop_msg,shop_msg_t=1,1,"",0 end

local function msg(t,s,c) shop_msg,shop_msg_t,smc=t,60,c snd_sfx(s,UI_CH) end

local function buy(id)
 local it,mt=items[id],money_total or 0
 local lv=it[5] and (ship[it[5]] or 0) or 0
 local ul=it[6] and ship[it[6]]
 
 if id==5 then -- repair
  local hu,mh=ship_get_hull(),ship_get_max_hull()
  if hu>=mh then msg("hull full",SFX_ERR,8) return end
  if mt<50 then msg("not enough $$$!",SFX_ERR,8) return end
  money_total-=50 ship.hull=hu+1
 elseif id==2 and not ul then -- unlock shield
  if mt<SC then msg("not enough $$$!",SFX_ERR,8) return end
  money_total-=SC ship_unlock_shield()
 else -- upgrade
  if lv>=it[2] then msg("max level",SFX_ERR,8) return end
  local c=it[3]+it[4]*lv
  if mt<c then msg("not enough $$$!",SFX_ERR,8) return end
  money_total-=c
  if it[5] then ship[it[5]]=lv+1 end
  if id==4 then ship.hull=ship_get_max_hull() end -- hull upgrade
 end
 msg(id==5 and "repaired!" or "bought!",SFX_OK,11)
end

function shop_update()
 if shop_msg_t>0 then shop_msg_t-=1 if shop_msg_t<=0 then shop_msg="" end end
 local mx=page==1 and 5 or 1
 if btnp(2) then sel=sel>1 and sel-1 or mx snd_sfx(SFX_CURSOR,UI_CH) end
 if btnp(3) then sel=sel<mx and sel+1 or 1 snd_sfx(SFX_CURSOR,UI_CH) end
 if btnp(0) and page>1 then page,sel=1,1 snd_sfx(SFX_CURSOR,UI_CH) end
 if btnp(1) and page<2 then page,sel=2,1 snd_sfx(SFX_CURSOR,UI_CH) end
 if btnp(5) then snd_sfx(SFX_OK,UI_CH) station_mode="main" end
 if btnp(4) then buy(page==1 and sel or 6) end
end

function shop_draw()
 rectfill(0,0,127,15,1)
 print("shop",4,4,7)
 print("$"..(money_total or 0),100,4,10)
 rect(2,18,125,121,1)
 
 local st,ed=page==1 and 1 or 6,page==1 and 5 or 6
 local idx=1
 for i=st,ed do
  local it=items[i]
  local y,c=26+(idx-1)*11,idx==sel and 7 or 5
  if idx==sel then rectfill(8,y-2,119,y+6,1) end
  
  local ic=it[1]
  sspr((ic%16)*8,flr(ic/16)*8,5,5,12,y,5,5)
  print(it[7],22,y,c)
  
  -- stat display
  local stat=""
  if i==5 then -- repair
   local hu,mh=ship_get_hull(),ship_get_max_hull()
   stat=hu.."/"..mh
  elseif it[5] then -- upgrade
   local lv=ship[it[5]] or 0
   local ul=it[6] and ship[it[6]]
   if i==2 and ul then lv=max(1,lv) end
   if i~=2 or ul then stat="lvl"..lv.."/"..it[2] end
  end
  if stat~="" then print(stat,94,y,c) end
  idx+=1
 end
 
 -- cost/desc for selected
 local sit=items[page==1 and sel or 6]
 local cost,cstr=-1,""
 if sel==5 and page==1 then -- repair
  local hu,mh=ship_get_hull(),ship_get_max_hull()
  cost=hu<mh and 50 or 0
  cstr=cost==0 and "n/a" or "$50"
 else
  local lv=sit[5] and (ship[sit[5]] or 0) or 0
  local ul=sit[6] and ship[sit[6]]
  if page==1 and sel==2 and not ul then
   cost,cstr=SC,"$"..SC
  elseif lv<sit[2] then
   cost=sit[3]+sit[4]*lv
   cstr="$"..cost
  else
   cstr="owned"
  end
 end
 
 local desc=sit[8]
 if page==1 and sel==2 and not ship.shield_unlocked then desc="+ adds shield" end
 
 rect(8,84,119,116,1)
 print("cost "..cstr,12,87,12)
 print(desc,12,94,11)
 print("◀",4,102,page>1 and 6 or 1)
 print("▶",120,102,page<2 and 6 or 1)
 print("🅾️ buy  ❎ back",12,102,6)
 if shop_msg~="" then print(shop_msg,12,110,smc) end
end
