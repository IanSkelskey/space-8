local s,p,sm,st,sc=1,1,"",0,11

-- compressed items: icon,max,base$,inc$,field,unlock,name,desc
-- rebalance: cheaper early items, expensive later upgrades for 1-2 round affordability but >12 round completion
local id="11,3,100,120,fire_rate_level,,fire rate +20%,+ faster shots;10,3,140,150,shield_level,shield_unlocked,shield upgrade,+ more shield;25,2,180,200,spread_level,,phaser spread +1,+ wider spread;38,2,200,220,hull_level,,hull +1 segment,+ more hull;54,99,180,0,,,repair hull,+ restore 1 hull;55,3,90,140,thruster_level,,thruster boost,+ faster accel;105,2,220,180,shield_pulse_level,shield_unlocked,shield shock,+ shield dmg 1/2"
-- pre-split once to save tokens (was repeatedly split each access)
local items={}
for e in all(split(id,";")) do add(items,split(e,",")) end

function shop_init() s,p,sm,st=1,1,"",0 end

local function msg(t,e) sm,st,sc=t,60,e and 8 or 11 snd_sfx(e and 45 or 63) end

local function buy(i)
  local it,m=items[i],money_total
  local dm=dmul()
  local lv=it[5]~="" and (ship[it[5]] or 0) or 0
  local ul=it[6]~="" and ship[it[6]]

  -- block locked (except shield unlock itself)
  if it[6]!="" and not ul and i~=2 then
    msg("needs shield",1) return
  end

 if i==5 then -- repair (more affordable scaling)
  local h,mh=ship.hull,2+ship.hull_level
  if h>=mh then msg("hull full",1) return end
  local c=flr((150+max(0,round_number-8)*30)*dm+0.5)
  if m<c then msg("not enough $$$!",1) return end
  money_total=m-c ship.hull=h+1
 elseif i==2 and not ul then -- unlock shield (more accessible)
  local c=flr(140*dm+0.5)
  if m<c then msg("not enough $$$!",1) return end
  money_total=m-c ship_unlock_shield()
 else -- upgrade
  if lv>=it[2] then msg("max level",1) return end
  local c=flr((it[3]+it[4]*lv)*dm+0.5)
  if m<c then msg("not enough $$$!",1) return end
  money_total=m-c
  if it[5]~="" then ship[it[5]]=lv+1 end
  -- if hull upgrade, add 1 hull point for the new segment
  if i==4 then ship.hull=ship.hull+1 end
 end
 msg(i==5 and "repaired!" or "bought!")
end

function shop_update()
 if st>0 then st-=1 if st<=0 then sm="" end end
 local page_items = (p==1) and 5 or (#items-5)
 local mx=page_items
 if btnp(2) then s=s>1 and s-1 or mx snd_sfx(44) end
 if btnp(3) then s=s<mx and s+1 or 1 snd_sfx(44) end
 if btnp(0) and p>1 then p,s=1,1 snd_sfx(44) end
 if btnp(1) and p<2 then p,s=2,1 snd_sfx(44) end
 if btnp(5) then snd_sfx(63) station_mode="main" end
 if btnp(4) then
  -- page2 offset FIX (was 5+s-1 causing wrong item)
  local gi=(p==1) and s or (5+s)
  buy(gi)
 end
end

function shop_draw()
 rectfill(0,0,127,15,1)
 print("◀",4,4,p>1 and 7 or 1)
 spr(22,14,4)
 print("shop - page "..p.."/2",24,4,7)
 print("▶",96,4,p<2 and 7 or 1)
 print("$"..money_total,100,4,10)
 rect(2,18,125,121,1)
 
 -- draw items
 local start_i,end_i=(p==1 and 1 or 6),(p==1 and 5 or #items)
 local idx=1
 for i=start_i,end_i do
  local it=items[i]
  local y=26+(idx-1)*11
  local selc=idx==s
  local c=selc and 7 or 5
  if selc then rectfill(8,y-2,119,y+6,1) end
  -- dynamic icon: shield shock locked → tile 106
  local icon=it[1]
  if i==7 and not ship.shield_unlocked and ship.shield_pulse_level==0 then icon="106" end
  sspr((icon%16)*8,flr(icon/16)*8,5,5,12,y,5,5)
  print(it[7],22,y,c)
  local stat=""
  if i==5 then
   local h,mh=ship.hull,2+ship.hull_level stat=h.."/"..mh
  elseif it[5]~="" then
   local lv=ship[it[5]] or 0
   local ul=it[6]!="" and ship[it[6]]
   if i==2 and ul then lv=max(1,lv) end
   if (i~=2 or ul) then stat="lvl"..lv.."/"..it[2] end
   if i==7 and not ul then stat="locked" end
  end
  if stat~="" then print(stat,94,y,c) end
  idx+=1
 end

 -- cost / desc (page offset fix retained)
 local sit=items[(p==1 and s) or (5+s)]
 local cstr,desc="",sit[8]
 local dm=dmul()
 local locked = ( (p==1 and s)==false and ( (p==2 and s== (7-5) ) ) ) -- helper not used further; keep tokens low
 if ( (p==2 and (5+s)==7) and not ship.shield_unlocked and ship.shield_pulse_level==0 ) then
  cstr="locked"
  desc="+ requires shield"
 else
  if s==5 and p==1 then
    local repair_cost=(150+max(0,round_number-8)*30)*dm
    cstr="$"..flr(repair_cost+0.5)
  else
    local lv,ul=sit[5]~="" and (ship[sit[5]] or 0) or 0,sit[6]~="" and ship[sit[6]]
    if p==1 and s==2 and not ul then
      cstr,desc="$"..flr(140*dm+0.5),"+ adds shield"
    elseif lv<sit[2] then
      cstr="$"..flr((sit[3]+sit[4]*lv)*dm+0.5)
    else
      cstr="owned"
    end
  end
 end
 
 rect(8,84,119,116,1)
 print("cost "..cstr,12,87,12)
 print(desc,12,94,11)
 print("🅾️ buy  ❎ back",12,102,6)
 if sm~="" then print(sm,12,110,sc) end
end
