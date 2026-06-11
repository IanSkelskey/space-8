station_mode = station_mode or "main"
station_confirm = station_confirm or false
local sel = sel or 1

-- fallback mission word lists (only created if not already defined by gameplay cart)
local sci_adj=sci_adj or split"quantum,plasma,ionic,fusion,nano,void"
local sci_noun=sci_noun or split"core,drive,matrix,relay,reactor,array"
local diff_labels=diff_labels or split"easy,normal,veteran"
local diff_icons={12,13,14} -- new 8x8 difficulty icons (easy/normal/veteran)

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
        -- header: block-letter title (centred at y4, leaving a top margin) + readouts.
        local fl=time()%0.8<0.4
        draw_logo("station",4,fl and 12 or 7,fl and 1 or 12,fl and 12 or 7,fl and 1 or 12)
        local cf="$"..money_total
        rprint(cf,124-#cf*4,5,10,9)
        rprint("round "..vr,4,15,6,5)
        local tls="00"..ts
        local tdisp=tsh>0 and (tsh..sub(tls,#tls-2)) or ts
        local ss="score "..tdisp
        rprint(ss,124-#ss*4,15,6,5)
        line(2,23,125,23,1)

        -- mission status. the payout breakdown was removed -- the round-summary screen now
        -- shows earnings, which freed this whole area.
        if current_mission then
            rprint(current_mission,4,27,12,1)
            print("dist "..mission_distance,4,37,6)
            spr(38,66,35) -- hull meter (matches the gameplay HUD): icon + mh equal segments
            local mh=2+ship.hull_level local sw=24\mh
            for i=0,mh-1 do sbar(73+i*sw,36,sw-1,i<ship.hull and 11 or 5) end
        else
            print("mission pending...",4,31,5)
        end
        line(2,45,125,45,1)

        if station_confirm then
            local q="launch mission?"
            rprint(q,64-#q*2,63,7,1)
            print("🅾️ yes   ❎ no",38,79,6)
        else
            -- action list: bobbing cursor + raised labels, matching the main menu
            local first_station = (vr==1 and not last_payout_ready)
            local rows = first_station and 3 or 2
            local y=57
            for i=1,rows do
                local on=i==sel
                if on then spr(20,6+time()%1\0.5,y-1) end
                local m,s=on and 7 or 6,on and 1 or 5
                if i==1 then
                    spr(45,16,y-1) rprint("launch mission",27,y,m,s)
                elseif i==2 then
                    spr(22,16,y-1) rprint("shop",27,y,m,s)
                else
                    spr(diff_icons[df],16,y-1) rprint("difficulty",27,y,m,s)
                    local dn=diff_labels[df]
                    local ac=on and (time()%0.8<0.4 and 12 or 6) or 6
                    print("◀",74,y,ac) print(dn,96-#dn*2,y,on and 11 or 6) print("▶",114,y,ac)
                end
                y+=14
            end
            local prompt,px=first_station and "🅾️ select  ❎ back" or "🅾️ select",first_station and 22 or 42
            print(prompt,px,115,6)
        end
    else
        if shop_draw then shop_draw() else print("shop",58,76,7) end
    end
end
