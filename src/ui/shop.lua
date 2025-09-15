local sel = sel or 1
local shop_msg = ""
local shop_msg_t = 0

local FM,SC,SM=3,120,2
SFX_CURSOR=SFX_CURSOR or 44
SFX_ERR=SFX_ERR or 45
SFX_OK=SFX_OK or 63
UI_CH=UI_CH or 3

function shop_init() sel,shop_msg,shop_msg_t=1,"",0 end

local function msg(t,s,c) shop_msg,shop_msg_t,smc=t,60,c snd_sfx(s,UI_CH) end

local function buy(id)
    local mt=money_total or 0
    local fr,sh,sp,hl,hu=ship.fire_rate_level or 0,ship.shield_level or 0,ship.spread_level or 0,ship.hull_level or 0,ship_get_hull and ship_get_hull() or 2
    local mh=ship_get_max_hull and ship_get_max_hull() or 2
    
    if id==1 then
        if fr>=FM then msg("max level",SFX_ERR,8) return end
        local c=100+50*fr
        if mt<c then msg("not enough $$$!",SFX_ERR,8) return end
        money_total-=c ship.fire_rate_level=fr+1
    elseif id==2 then
        if sh>=3 then msg("max level",SFX_ERR,8) return end
        local c=ship.shield_unlocked and (SC+80*sh) or SC
        if mt<c then msg("not enough $$$!",SFX_ERR,8) return end
        money_total-=c
        if ship.shield_unlocked then ship.shield_level=sh+1 else ship_unlock_shield() end
    elseif id==3 then
        if sp>=SM then msg("max level",SFX_ERR,8) return end
        local c=150+100*sp
        if mt<c then msg("not enough $$$!",SFX_ERR,8) return end
        money_total-=c ship.spread_level=sp+1
    elseif id==4 then
        if hl>=2 then msg("max level",SFX_ERR,8) return end
        local c=200+150*hl
        if mt<c then msg("not enough $$$!",SFX_ERR,8) return end
        money_total-=c ship.hull_level=hl+1 ship.hull=mh+1
    else
        if hu>=mh then msg("hull full",SFX_ERR,8) return end
        if mt<50 then msg("not enough $$$!",SFX_ERR,8) return end
        money_total-=50 ship.hull=hu+1
    end
    msg(id==5 and "repaired!" or "bought!",SFX_OK,11)
end

function shop_update()
    if shop_msg_t>0 then shop_msg_t-=1 if shop_msg_t<=0 then shop_msg="" end end
    if btnp(2) then sel=sel>1 and sel-1 or 5 snd_sfx(SFX_CURSOR,UI_CH) end
    if btnp(3) then sel=sel<5 and sel+1 or 1 snd_sfx(SFX_CURSOR,UI_CH) end
    if btnp(5) then snd_sfx(SFX_OK,UI_CH) station_mode="main" end
    if btnp(4) then buy(sel) end
end

function shop_draw()
    rectfill(0,0,127,15,1)
    print("shop",4,4,7)
    print("$"..(money_total or 0),100,4,10)
    rect(2,18,125,121,1)
    
    local fr,sp,sh,hl=ship.fire_rate_level or 0,ship.spread_level or 0,ship.shield_level or 0,ship.hull_level or 0
    local hu,mh=ship_get_hull and ship_get_hull() or 2,ship_get_max_hull and ship_get_max_hull() or 2
    local items=split"fire rate +20%,shield upgrade,phaser spread +1,hull +1 segment,repair hull"
    local icons=split"11,10,25,38,54"
    local stats={
        "lvl"..fr.."/"..FM,
        ship.shield_unlocked and ("lvl"..max(1,sh).."/3") or "",
        "lvl"..sp.."/"..SM,
        "lvl"..hl.."/2",
        hu.."/"..mh
    }
    local costs={
        fr<FM and 100+50*fr or -1,
        ship.shield_unlocked and (sh<3 and SC+80*sh or -1) or SC,
        sp<SM and 150+100*sp or -1,
        hl<2 and 200+150*hl or -1,
        hu<mh and 50 or 0
    }
    
    for i=1,5 do
        local y,c=26+(i-1)*11,i==sel and 7 or 5
        if i==sel then rectfill(8,y-2,119,y+6,1) end
        local ic=icons[i]
        sspr((ic%16)*8,flr(ic/16)*8,5,5,12,y,5,5)
        print(items[i],22,y,c)
        if stats[i]~="" then print(stats[i],94,y,c) end
    end
    
    local cost=costs[sel]
    local cstr=cost<0 and "owned" or (cost==0 and "n/a" or "$"..cost)
    local descs=split"+ faster shots,+ more shield,+ wider spread,+ more hull,+ restore 1 hull"
    if sel==2 and not ship.shield_unlocked then descs[2]="+ adds shield" end
    
    rect(8,84,119,116,1)
    print("cost "..cstr,12,87,12)
    print(descs[sel],12,94,11)
    print("🅾️ buy  ❎ back",12,102,6)
    if shop_msg~="" then print(shop_msg,12,110,smc or 11) end
end
