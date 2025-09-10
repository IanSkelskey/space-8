shop_mode = shop_mode or "menu"
local sel = sel or 1
local shop_msg = ""
local shop_msg_t = 0

local FIRE_MAX=3
local function fire_cost(lvl) return 100+50*lvl end
local SHIELD_COST=200

function shop_init()
    shop_mode = "menu"
    sel = 1
    shop_msg = ""
    shop_msg_t = 0
end

local function try_buy_fire_rate()
    local lvl = ship_get_fire_rate_level and ship_get_fire_rate_level() or 0
    if lvl >= FIRE_MAX then shop_msg="max level" shop_msg_t=60 return end
    local cost = fire_cost(lvl)
    if (money_total or 0) < cost then shop_msg="not enough $" shop_msg_t=60 return end
    money_total -= cost
    lvl += 1
    if ship_set_fire_rate_level then ship_set_fire_rate_level(lvl) end
    shop_msg="purchased!" shop_msg_t=60
end

local function try_buy_shield()
    if ship_has_shield_unlocked and ship_has_shield_unlocked() then shop_msg="already owned" shop_msg_t=60 return end
    if (money_total or 0) < SHIELD_COST then shop_msg="not enough $" shop_msg_t=60 return end
    money_total -= SHIELD_COST
    if ship_unlock_shield then ship_unlock_shield() end
    shop_msg="purchased!" shop_msg_t=60
end

function shop_update()
    if shop_msg_t>0 then shop_msg_t-=1 if shop_msg_t<=0 then shop_msg="" end end
    local items_n = 2
    if btnp(2) then sel -= 1 end
    if btnp(3) then sel += 1 end
    if sel < 1 then sel = items_n end
    if sel > items_n then sel = 1 end
    if btnp(5) then station_mode = "main" return end
    if btnp(4) then
        if sel==1 then try_buy_fire_rate() else try_buy_shield() end
    end
end

function shop_draw()
    cls()
    print("station shop",44,8,7)
    local mstr = "$"..(money_total or 0)
    print(mstr, 124-#mstr*4, 16, 10)
    line(0,24,127,24,1)
    local y = 34
    local lvl = ship_get_fire_rate_level and ship_get_fire_rate_level() or 0
    local cost1 = (lvl < FIRE_MAX) and ("$"..(100+50*lvl)) or "owned"
    local owned_shield = ship_has_shield_unlocked and ship_has_shield_unlocked() or false
    local cost2 = owned_shield and "owned" or ("$"..200)
    for i=1,2 do
        local c = (i==sel) and 7 or 6
        if i==sel then print(">", 4, y, c) end
        local icon = (i==1) and 4 or 10 -- fire rate uses lean ship icon; shield uses shield icon (sprite 9)
        spr(icon, 10, y-1)
        if i==1 then
            print("fire rate +20%", 20, y, c)
            local r = "lvl "..lvl.."/"..FIRE_MAX
            print(r, 126-#r*4, y, c)
        else
            print("shield power", 20, y, c)
        end
        y += 12
    end
    line(0,110,127,110,1)
    if shop_msg ~= "" then
        -- center the message
        print(shop_msg, 64-#shop_msg*2, 116, 11)
    else
        local sel_cost = (sel==1) and cost1 or cost2
        -- show cost only for the hovered item in the footer, leaving rows uncluttered
        local cstr = "cost: "..sel_cost
        print(cstr, 1, 116, 12)
        local f = "z: buy   x: back"
        print(f, 128-#f*4, 116, 5)
    end
end
