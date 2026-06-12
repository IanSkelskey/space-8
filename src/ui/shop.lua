local s,sm,st,sc=1,"",0,11 -- s=selected item index (single grid now, no pages)

-- compressed items: icon,max,base$,inc$,field,unlock,name,desc
-- rebalance: cheaper early items, expensive later upgrades for 1-2 round affordability but >12 round completion
-- NOTE: fields are comma-split, so name/desc must NOT contain commas (use / or + instead).
local id="83,3,100,120,fire_rate_level,,fire rate,-20% shot cooldown / lvl;84,3,140,150,shield_level,shield_unlocked,shield,holds longer + recharges;87,2,180,200,spread_level,,spread shot,more lasers / wider spread;82,2,200,220,hull_level,,hull,+1 max hull segment;81,99,180,0,,,repair,restore 1 hull segment;86,3,90,140,thruster_level,,thrusters,+12% top speed / lvl;85,2,220,180,shield_pulse_level,shield_unlocked,shield shock,shielded hits blast foes"
-- pre-split once to save tokens (was repeatedly split each access)
local items={}
for e in all(split(id,";")) do add(items,split(e,",")) end

function shop_init() s,sm,st=1,"",0 end

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
 local n=#items
 -- grid nav: left/right wrap through all items in reading order; up/down jump a row (4 cols)
 if btnp(0) then s=s>1 and s-1 or n snd_sfx(44) end
 if btnp(1) then s=s<n and s+1 or 1 snd_sfx(44) end
 if btnp(2) and s>4 then s-=4 snd_sfx(44) end
 if btnp(3) and s+4<=n then s+=4 snd_sfx(44) end
 if btnp(5) then snd_sfx(63) station_mode="main" end
 if btnp(4) then buy(s) end
end

-- level pips under an icon: filled up to `cur` (green), hollow (dark gray) for the rest.
-- hollow is gray not blue so it stays visible on top of the blue selection fill.
local function pips(cx,y,cur,mx)
 local x0=cx-(mx*3-1)\2
 for j=0,mx-1 do rectfill(x0+j*3,y,x0+j*3+1,y+1,j<cur and 11 or 5) end
end

function shop_draw()
 -- header (new standard): block-letter SHOP title on the starfield + raised-gold cash. no bar.
 -- title at y4 to leave a small top margin.
 local fl=time()%0.8<0.4
 draw_logo("shop",4,fl and 12 or 7,fl and 1 or 12,fl and 12 or 7,fl and 1 or 12)
 local cash="$"..money_total
 mprint(cash,121-#cash*4,4,10,9)

 -- icon grid: 4 columns, native 8x8 upgrade tiles with level pips below.
 for i=1,#items do
  local it=items[i]
  local cx=22+((i-1)%4)*28      -- cell centre x
  local ty=22+((i-1)\4)*22      -- icon top y
  local sel=i==s
  local locked=it[6]~="" and not ship[it[6]] and i~=2 -- shield-gated, pre-unlock
  if sel then
   -- selection highlight, centred on the 8px icon (cx-4..cx+3) + pips
   rectfill(cx-6,ty-2,cx+5,ty+12,1)
   rect(cx-6,ty-2,cx+5,ty+12,12)
  end
  -- icon: shield shock shows its pre-grayed variant (tile 102) while shield-locked
  local icon=it[1]
  if i==7 and locked then icon="102" end
  sspr((icon%16)*8,(icon\16)*8,8,8,cx-4,ty,8,8) -- native 8x8 (sspr coerces the string id)
  -- pips below the icon: hull for repair, level for upgrades
  if i==5 then pips(cx,ty+9,ship.hull,2+ship.hull_level)
  elseif it[5]~="" then pips(cx,ty+9,ship[it[5]] or 0,it[2]) end
 end

 -- divider, then the selected item's details across the lower half
 line(6,60,121,60,1)
 local sit=items[s]
 local dm=dmul()
 local locked=sit[6]~="" and not ship[sit[6]] and s~=2
 local cstr,desc,stat="",sit[8]
 if locked then
  cstr,desc,stat="locked","+ requires shield","locked"
 elseif s==5 then
  local h,mh=ship.hull,2+ship.hull_level
  cstr=h>=mh and "hull full" or "$"..flr((150+max(0,round_number-8)*30)*dm+0.5)
  stat="hull "..h.."/"..mh
 elseif s==2 and not ship.shield_unlocked then
  cstr,desc,stat="$"..flr(140*dm+0.5),"+ adds shield","not owned"
 else
  local lv=sit[5]~="" and (ship[sit[5]] or 0) or 0
  cstr=lv<sit[2] and "$"..flr((sit[3]+sit[4]*lv)*dm+0.5) or "owned"
  stat="level "..lv.."/"..sit[2]
 end

 rprint(sit[7],8,64,7,1)                            -- item name (raised)
 if stat then rprint(stat,120-#stat*4,64,6,5) end   -- level/hull/status, right-aligned on the name line
 print(desc,8,74,11)                                -- effect description
 print("cost",8,84,6) mprint(cstr,30,84,12)
 print("⬅️➡️ select  🅾️ buy  ❎ back",6,104,6) -- navigation + actions
 if sm~="" then print(sm,8,114,sc) end
end
