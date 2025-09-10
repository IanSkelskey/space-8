station_mode = station_mode or "main"
station_confirm = station_confirm or false
local sel = sel or 1
local shop_sel = shop_sel or 1
local shop_msg = ""
local shop_msg_t = 0

-- shop data
local FIRE_MAX=3
local function fire_cost(lvl) return 100+50*lvl end
local SHIELD_COST=200

function station_init() station_mode="main" station_confirm=false sel=1 shop_sel=1 shop_msg="" shop_msg_t=0 end

local function can_launch() return level_fanfare_timer<=0 end

local function try_buy_fire_rate()
    local lvl = 0
    if ship_get_fire_rate_level then lvl = ship_get_fire_rate_level() end
    if lvl >= FIRE_MAX then
        shop_msg = "max level"
        shop_msg_t = 60
        return
    end
    local cost = fire_cost(lvl)
    if (money_total or 0) < cost then
        shop_msg = "not enough $"
        shop_msg_t = 60
        return
    end
    money_total -= cost
    lvl += 1
    if ship_set_fire_rate_level then ship_set_fire_rate_level(lvl) end
    shop_msg = "purchased!"
    shop_msg_t = 60
end

function update_station()
    if shop_msg_t>0 then shop_msg_t-=1 if shop_msg_t<=0 then shop_msg="" end end

    if station_mode == "main" then
        if not station_confirm then
            if btnp(2) then sel -= 1 end -- up
            if btnp(3) then sel += 1 end -- down
            if sel < 1 then sel = 2 end
            if sel > 2 then sel = 1 end
            if btnp(4) then
                if sel == 1 then
                    if can_launch() then station_confirm = true end
                else
                    station_mode = "shop"
                end
            end
        else
            if btnp(4) then
                level_fanfare_timer = 0
                last_payout_ready = false
                game_state = "game"
                if sl then sl(round_number) end
                ship_init()
                station_confirm = false
            elseif btnp(5) then
                station_confirm = false
            end
        end
    else
        local items_n = 2
        if btnp(2) then shop_sel -= 1 end -- up
        if btnp(3) then shop_sel += 1 end -- down
        if shop_sel < 1 then shop_sel = items_n end
        if shop_sel > items_n then shop_sel = 1 end
        if btnp(5) then
            station_mode = "main"
            return
        end
        if btnp(4) then
            if shop_sel == 1 then
                try_buy_fire_rate()
            else
                if ship_has_shield_unlocked and ship_has_shield_unlocked() then
                    shop_msg = "already owned"
                    shop_msg_t = 60
                else
                    if (money_total or 0) < SHIELD_COST then
                        shop_msg = "not enough $"
                        shop_msg_t = 60
                    else
                        money_total -= SHIELD_COST
                        if ship_unlock_shield then ship_unlock_shield() end
                        shop_msg = "purchased!"
                        shop_msg_t = 60
                    end
                end
            end
        end
    end
end

function draw_station()
    print("station",52,10,7)
    print("round "..round_number,48,20,6)
    print("mission:",44,28,12)
    if current_mission then
        print(current_mission,64-#current_mission*2,36,11)
        print("dist: "..mission_distance,40,44,6)
    end
    print("$"..money_total,52,58,10)
    if last_payout_ready then
        print("+$"..(last_pay+last_bonus),48,66,11)
    end

    if station_mode == "main" then
        local y = 86
        local opts = {"launch mission", "shop"}
        for i=1,#opts do
            local c = (i==sel) and 7 or 6
            if i==sel then print(">",28,y,c) end
            print(opts[i], 36, y, c)
            y += 10
        end
        if station_confirm then
            print("launch mission?",36,102,7)
            print("z: yes   x: no",40,110,6)
        else
            print("z: select  x: back", 28, 120, 5)
        end
    else
        print("shop",58,76,7)
        local y = 90
        local lvl = ship_get_fire_rate_level and ship_get_fire_rate_level() or 0
        local cost1 = (lvl < FIRE_MAX) and ("$"..fire_cost(lvl)) or "owned"
    local owned_shield = ship_has_shield_unlocked and ship_has_shield_unlocked() or false
    local cost2 = owned_shield and "owned" or ("$"..SHIELD_COST)
        for i=1,2 do
            local c = (i==shop_sel) and 7 or 6
            if i==shop_sel then print(">", 20, y, c) end
            if i==1 then
                print("fire rate +20%", 28, y, c)
                print("lvl "..lvl.."/"..FIRE_MAX.."  "..cost1, 100, y, c)
            else
                print("shield power", 28, y, c)
                print(cost2, 100, y, c)
            end
            y += 10
        end
        if shop_msg ~= "" then
            print(shop_msg, 28, 120, 11)
        else
            print("z: buy   x: back", 28, 120, 5)
        end
    end
end
