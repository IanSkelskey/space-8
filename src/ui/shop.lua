local s,p,sm,st,sc=1,1,"",0,11

-- compressed items: icon,max,base$,inc$,field,unlock,name,desc
local id="11,3,100,50,fire_rate_level,,fire rate +20%,+ faster shots;10,3,120,80,shield_level,shield_unlocked,shield upgrade,+ more shield;25,2,150,100,spread_level,,phaser spread +1,+ wider spread;38,2,200,150,hull_level,,hull +1 segment,+ more hull;54,99,200,0,,,repair hull,+ restore 1 hull;55,3,80,60,thruster_level,,thruster boost,+ faster accel"
-- pre-split once to save tokens (was repeatedly split each access)
local raw_items=split(id,";")
local items={}
for e in all(raw_items) do add(items,split(e,",")) end

function shop_init() s,p,sm,st=1,1,"",0 end

local function msg(t,e) sm,st,sc=t,60,e and 8 or 11 snd_sfx(e and SFX_ERR or SFX_OK,UI_CH) end

local function buy(i)
 local it,m=items[i],money_total or 0
 local lv=it[5]~="" and (ship[it[5]] or 0) or 0
 local ul=it[6]~="" and ship[it[6]]
 
 if i==5 then -- repair
  local h,mh=ship_get_hull(),ship_get_max_hull()
  if h>=mh then msg("hull full",1) return end
  local repair_cost=200+((round_number or 1)-1)*50  -- scales with round
  if m<repair_cost then msg("not enough $$$!",1) return end
  money_total=m-repair_cost ship.hull=h+1
 elseif i==2 and not ul then -- unlock shield
  if m<120 then msg("not enough $$$!",1) return end
  money_total=m-120 ship_unlock_shield()
 else -- upgrade
  if lv>=it[2] then msg("max level",1) return end
  local c=it[3]+it[4]*lv
  if m<c then msg("not enough $$$!",1) return end
  money_total=m-c
  if it[5]~="" then ship[it[5]]=lv+1 end
  -- if hull upgrade, add 1 hull point for the new segment
  if i==4 then ship.hull=(ship.hull or 0)+1 end
 end
 msg(i==5 and "repaired!" or "bought!")
end

function shop_update()
 if st>0 then st-=1 if st<=0 then sm="" end end
 local mx=p==1 and 5 or 1
 if btnp(2) then s=s>1 and s-1 or mx snd_sfx(SFX_CURSOR,UI_CH) end
 if btnp(3) then s=s<mx and s+1 or 1 snd_sfx(SFX_CURSOR,UI_CH) end
 if btnp(0) and p>1 then p,s=1,1 snd_sfx(SFX_CURSOR,UI_CH) end
 if btnp(1) and p<2 then p,s=2,1 snd_sfx(SFX_CURSOR,UI_CH) end
 if btnp(5) then snd_sfx(SFX_OK,UI_CH) station_mode="main" end
  if btnp(4) then
    -- compute selected item index without branch (page 1: 1..5, page 2: item 6)
    local gi=p==1 and s or 6
    buy(gi)
  end
end

function shop_draw()
 rectfill(0,0,127,15,1)
 print("◀",4,4,p>1 and 7 or 1)
 spr(22,14,4) -- Add sprite 22 before "shop"
 print("shop - page "..p.."/2",24,4,7) -- Shifted text right to make room
 print("▶",96,4,p<2 and 7 or 1) -- Shifted arrow right to match
 print("$"..(money_total or 0),100,4,10)
 rect(2,18,125,121,1)
 
  -- draw items (reuse pre-split `items` table to avoid per-frame split calls)
  local idx,start_i,end_i=1,(p==1 and 1 or 6),(p==1 and 5 or 6)
  for i=start_i,end_i do
    local it=items[i]
    local y=26+(idx-1)*11
    local selc=idx==s
    local c=selc and 7 or 5
    if selc then rectfill(8,y-2,119,y+6,1) end
    sspr((it[1]%16)*8,flr(it[1]/16)*8,5,5,12,y,5,5)
    print(it[7],22,y,c)
    local stat=""
    if i==5 then
      local h,mh=ship_get_hull(),ship_get_max_hull()
      stat=h.."/"..mh
    elseif it[5]~="" then
      local lv=ship[it[5]] or 0
      local ul=it[6]~="" and ship[it[6]]
      if i==2 and ul then lv=max(1,lv) end
      if i~=2 or ul then stat="lvl"..lv.."/"..it[2] end
    end
    if stat~="" then print(stat,94,y,c) end
    idx+=1
  end
 
 -- cost/desc
 local sit=items[p==1 and s or 6]
 local cstr,desc="",sit[8]
 if s==5 and p==1 then
  -- match actual charged repair cost (was displaying lower value)
  local repair_cost=200+((round_number or 1)-1)*50  -- scales with round
  cstr="$"..repair_cost
 else
    local lv=sit[5]~="" and (ship[sit[5]] or 0) or 0
    local ul=sit[6]~="" and ship[sit[6]]
  if p==1 and s==2 and not ul then
   cstr,desc="$120","+ adds shield"
  elseif lv<sit[2] then
   cstr="$"..(sit[3]+sit[4]*lv)
  else
   cstr="owned"
  end
 end
 
 rect(8,84,119,116,1)
 print("cost "..cstr,12,87,12)
 print(desc,12,94,11)
 print("🅾️ buy  ❎ back",12,102,6)
 if sm~="" then print(sm,12,110,sc) end
end
