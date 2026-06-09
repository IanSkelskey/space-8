station_mode = station_mode or "main"
station_confirm = station_confirm or false
local sel = sel or 1

-- fallback mission word lists (only created if not already defined by gameplay cart)
local sci_adj=sci_adj or split"quantum,plasma,ionic,fusion,nano,void"
local sci_noun=sci_noun or split"core,drive,matrix,relay,reactor,array"
local diff_labels=diff_labels or split"easy,normal,veteran"

-- borderless slanted 3px bar, matching the gameplay HUD's hull meter
function sbar(x,y,w,c) for r=0,2 do rectfill(x+2-r,y+r,x+1-r+w,y+r,c) end end

local function ensure_mission()
 -- if gameplay cart didn't persist name, synthesize deterministic one
 if not current_mission then
  local ai=(round_number*3)%#sci_adj+1
  local ni=(round_number*5)%#sci_noun+1
  current_mission=sci_adj[ai].." "..sci_noun[ni]
 end
 if not mission_distance or mission_distance<=0 then
  mission_distance=400+round_number*80
 end
end

function station_init()
 station_mode="main" station_confirm=false sel=1
 ensure_mission()
 if shop_init then shop_init() end
 -- ensure correct music (pattern 10) starts on first arrival from menu/start
 if snd_music and current_music~=10 then snd_music(10) end
end

function update_station()
    local first_station = (vr==1 and not last_payout_ready)
    if station_mode == "main" then
        if not station_confirm then
            local max_sel = first_station and 3 or 2
            if btnp(2) then sel -= 1 snd_sfx(44) end -- up
            if btnp(3) then sel += 1 snd_sfx(44) end -- down
            if sel<1 then sel=max_sel elseif sel>max_sel then sel=1 end
            -- left/right to change difficulty when diff row selected
            if first_station and sel==3 then
                if btnp(0) then df = (df-2+#diff_labels)%#diff_labels+1 snd_sfx(44) round_number=sr[df] vr=1 current_mission=nil mission_distance=400+round_number*80 end
                if btnp(1) then df = (df%#diff_labels)+1 snd_sfx(44) round_number=sr[df] vr=1 current_mission=nil mission_distance=400+round_number*80 end
            end
            if first_station and btnp(5) then game_state="menu" menu_init() snd_sfx(44) return end
            if btnp(4) then
                if sel == 1 then
                    if (level_fanfare_timer or 0)<=0 then station_confirm = true snd_sfx(63) end
                elseif sel == 2 then
                    station_mode = "shop" snd_sfx(63)
                elseif sel == 3 then
                    -- acts like no-op (selector handled via left/right); provide confirm sound
                    snd_sfx(63)
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
        ensure_mission()
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
            -- hull meter, matching the gameplay HUD: fixed 24px, mh EQUAL segments, borderless slant
            spr(38,6,46)
            local mh=2+ship.hull_level local sw=24\mh
            for i=0,mh-1 do sbar(13+i*sw,47,sw-1,i<ship.hull and 11 or 5) end
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
            local first_station = (vr==1 and not last_payout_ready)
            local y = 64
            local rows = first_station and 3 or 2
            for i=1,rows do
                local c = (i==sel) and 7 or 5
                if i==sel then rectfill(6,y-2,121,y+6,1) end
                if i<3 or not first_station then
                    local icon = (i==1) and 6 or 22
                    local sx,sy=(icon%16)*8,flr(icon/16)*8
                    sspr(sx,sy,5,5,10,y,5,5)
                    print(i==1 and "launch mission" or "shop",18,y,c)
                else
                    -- difficulty selector row
                    print("difficulty",18,y,c)
                    local dname=diff_labels[df]
                    local dx=96-#dname*2
                    print("<",70,y,c)
                    print(dname,dx,y, (i==sel) and 11 or 6)
                    print(">",116,y,c)
                end
                y += 12
            end
            local prompt = first_station and "🅾️ sel  ❎ back" or "🅾️ select"
            print(prompt,8,108,6)
        end
    else
        if shop_draw then shop_draw() else print("shop",58,76,7) end
    end
end
