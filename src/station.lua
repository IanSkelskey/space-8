station_mode = station_mode or "main"
station_confirm = station_confirm or false
local sel = sel or 1

function station_init() station_mode="main" station_confirm=false sel=1 if shop_init then shop_init() end end

local function can_launch() return level_fanfare_timer<=0 end

function update_station()

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
        if shop_update then shop_update() end
    end
end

function draw_station()
    if station_mode == "main" then
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
        if shop_draw then shop_draw() else print("shop",58,76,7) end
    end
end
