shop_mode = shop_mode or "menu"
local sel = sel or 1
local shop_msg = ""
local shop_msg_t = 0

local FM=3
local SC=200
local SM=2

function shop_init()
    shop_mode = "menu"
    sel = 1
    shop_msg = ""
    shop_msg_t = 0
end

local function try_buy_fire_rate()
    local lvl = ship.fire_rate_level or 0
    if lvl >= FM then shop_msg="max" shop_msg_t=60 return end
    local cost = 100+50*lvl
    if (money_total or 0) < cost then shop_msg="not enough $$$" shop_msg_t=60 shop_msg_color=8 return end
    money_total -= cost
    lvl += 1
    ship.fire_rate_level=lvl shop_msg="bought" shop_msg_t=60 shop_msg_color=11
end

local function try_buy_shield()
    if ship.shield_unlocked then shop_msg="owned" shop_msg_t=60 return end
    if (money_total or 0) < SC then shop_msg="not enough $$$" shop_msg_t=60 shop_msg_color=8 return end
    money_total -= SC
    if ship_unlock_shield then ship_unlock_shield() end
    shop_msg="bought" shop_msg_t=60 shop_msg_color=11
end

local function try_buy_spread()
    local lvl = ship.spread_level or 0
    if lvl >= SM then shop_msg="max" shop_msg_t=60 return end
    local cost = 150+100*lvl
    if (money_total or 0) < cost then shop_msg="not enough $$$" shop_msg_t=60 shop_msg_color=8 return end
    money_total -= cost
    lvl += 1
    ship.spread_level=lvl shop_msg="bought" shop_msg_t=60 shop_msg_color=11
end

function shop_update()
    if shop_msg_t>0 then shop_msg_t-=1 if shop_msg_t<=0 then shop_msg="" end end
    if btnp(2) then sel -= 1 end
    if btnp(3) then sel += 1 end
    if sel < 1 then sel = 3 end
    if sel > 3 then sel = 1 end
    if btnp(5) then station_mode = "main" return end
    if btnp(4) then
        if sel==1 then try_buy_fire_rate() elseif sel==2 then try_buy_shield() else try_buy_spread() end
    end
end

function shop_draw()
    cls()
    print("station shop",44,8,7)
    print("$"..(money_total or 0), 100, 16, 10)
    line(0,24,127,24,1)
    local lvl = ship.fire_rate_level or 0
    local spread_lvl = ship.spread_level or 0
    local y = 34
    for i=1,3 do
        local c = (i==sel) and 7 or 6
        if i==sel then print(">", 4, y, c) end
        local icon = (i==1) and 11 or (i==2 and 10 or 25)
        local sx,sy=(icon%16)*8,flr(icon/16)*8
        sspr(sx, sy, 5, 5, 10, y, 5, 5)
        if i==1 then
            print("fire rate +20%", 20, y, c)
            print("lvl "..lvl.."/"..FM, 96, y, c)
        elseif i==2 then
            print("shield power", 20, y, c)
            if ship.shield_unlocked then print("owned", 104, y, c) end
        else
            print("fire spread +1", 20, y, c)
            print("lvl "..spread_lvl.."/"..SM, 96, y, c)
        end
        y += 12
    end
    line(0,110,127,110,1)
    if shop_msg ~= "" then
        print(shop_msg, 24, 116, shop_msg_color or 11)
    else
    local sel_cost=(sel==1 and (lvl<FM and ("$"..(100+50*lvl)) or "owned")) or (sel==2 and (ship.shield_unlocked and "owned" or ("$"..SC)) or (spread_lvl<SM and ("$"..(150+100*spread_lvl)) or "owned"))
        print("cost: "..sel_cost, 1, 116, 12)
    print("z: buy  x: back", 60, 116, 5)
    end
end
