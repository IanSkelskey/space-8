station_mode = station_mode or "main"
station_confirm = station_confirm or false
local sel = sel or 1

function station_init() station_mode="main" station_confirm=false sel=1 if shop_init then shop_init() end end

function update_station()
    if station_mode == "main" then
        if not station_confirm then
            if btnp(2) then sel -= 1 snd_sfx(44) end -- up
            if btnp(3) then sel += 1 snd_sfx(44) end -- down
            if sel<1 then sel=2 elseif sel>2 then sel=1 end
            if btnp(4) then
                if sel == 1 then
                    if (level_fanfare_timer or 0)<=0 then station_confirm = true snd_sfx(63) end
                else
                    station_mode = "shop" snd_sfx(63)
                end
            end
        else
            if btnp(4) then
                snd_sfx(63)
                level_fanfare_timer = 0
                last_payout_ready = false
                last_bonus=0 -- reset collected bonus for new mission
                    launch_mission()
                station_confirm = false
            elseif btnp(5) then
                station_confirm = false snd_sfx(44)
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
        print("round"..vr,72,4,6)
        local cf="$"..money_total
    local tls="00"..ts
    local tdisp=tsh>0 and (tsh..sub(tls,#tls-2)) or ts
    print(tdisp,40,4,11)
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
        if last_payout_ready then
            print("base",84,26,5) local v=""..last_pay print(v,124-#v*4,26,11)
            print("bonus",84,32,5) v=""..last_bonus print(v,124-#v*4,32,12)
            print("total",84,38,5) v=""..(last_pay+last_bonus) print(v,124-#v*4,38,7)
        else
            print("none",84,30,5)
        end

        -- full-width actions panel
        rect(2,56,125,121,1)
        if station_confirm then
            print("launch mission?",10,64,7)
            print("🅾️ yes  ❎ no",12,76,6)
        else
            local y = 64
            for i=1,2 do
                local c = (i==sel) and 7 or 5
                if i==sel then rectfill(6,y-2,121,y+6,1) end
                local icon = (i==1) and 6 or 22
                local sx,sy=(icon%16)*8,flr(icon/16)*8
                sspr(sx,sy,5,5,10,y,5,5)
                print(i==1 and "launch mission" or "shop",18,y,c)
                y += 12
            end
            print("🅾️ sel  ❎ back",8,108,6)
        end
    else
        if shop_draw then shop_draw() else print("shop",58,76,7) end
    end
end
