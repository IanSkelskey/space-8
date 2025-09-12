station_mode = station_mode or "main"
station_confirm = station_confirm or false
local sel = sel or 1
SFX_CURSOR=SFX_CURSOR or 44
SFX_ERR=SFX_ERR or 45
SFX_OK=SFX_OK or 63
UI_CH=UI_CH or 3

function station_init() station_mode="main" station_confirm=false sel=1 if shop_init then shop_init() end end

function update_station()
    if station_mode == "main" then
        if not station_confirm then
            if btnp(2) then sel -= 1 sfx(SFX_CURSOR,UI_CH) end -- up
            if btnp(3) then sel += 1 sfx(SFX_CURSOR,UI_CH) end -- down
            if sel < 1 then sel = 2 end
            if sel > 2 then sel = 1 end
            if btnp(4) then
                if sel == 1 then
                    if level_fanfare_timer<=0 then station_confirm = true sfx(SFX_OK,UI_CH) end
                else
                    station_mode = "shop" sfx(SFX_OK,UI_CH)
                end
            end
        else
            if btnp(4) then
                sfx(SFX_OK,UI_CH)
                level_fanfare_timer = 0
                last_payout_ready = false
                game_state = "game"
                if sl then sl(round_number) end
                ship_init()
                station_confirm = false
            elseif btnp(5) then
                station_confirm = false sfx(SFX_CURSOR,UI_CH)
            end
        end
    else
        if shop_update then shop_update() end
    end
end

function draw_station()
    if station_mode == "main" then
        -- header bar
        rectfill(0,0,127,15,1)
    print("station",4,4,7)
    print("round"..round_number,72,4,6)
    local cf="$"..money_total
    print(cf,124-#cf*4,4,10)

        -- mission panel
        rect(2,18,78,54,1)
        print("mission",6,20,12)
        if current_mission then
            print(current_mission,6,30,11)
            print("dist:"..mission_distance,6,38,6)
        else
            print("pending",6,30,5)
        end

        -- payout (round earnings) panel - current funds moved to header
        rect(80,18,125,54,1)
        print("payout",84,20,6)
        local function rtxt(label,val,y,col_l,col_v)
            print(label,84,y,col_l)
            local vs=""..val
            print(vs,124-#vs*4,y,col_v)
        end
        if last_payout_ready then
            rtxt("base",last_pay,26,5,11)
            rtxt("bonus",last_bonus,32,5,12)
            rtxt("total",(last_pay+last_bonus),38,5,7)
        else
            print("none",84,30,5)
        end

        -- full-width actions panel
        rect(2,56,125,121,1)
        if station_confirm then
            print("launch mission?",10,64,7)
            print("z yes  x no",12,76,6)
        else
            local y = 64
            for i=1,2 do
                local c = (i==sel) and 7 or 5
                if i==sel then rectfill(6,y-2,121,y+6,1) end
                print(i==1 and "launch mission" or "shop",10,y,c)
                y += 12
            end
            print("z sel  x back",10,108,6)
        end
    else
        if shop_draw then shop_draw() else print("shop",58,76,7) end
    end
end
