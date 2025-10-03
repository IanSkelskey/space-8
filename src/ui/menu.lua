local sel=1

local function start_game(set_df)
    df=set_df
    round_number=sr[df] vr=1
    game_state="game"
    ship_init() asteroid_init() hud_init() comet_init() blackhole_init()
    snd_sfx(63,3)
end

local labels,icons=split"easy,normal,veteran,help",{19,34,6,41}

function menu_init() sel=1 end

function update_menu()
    if btnp(2) then sel-=1 snd_sfx(44,3) end
    if btnp(3) then sel+=1 snd_sfx(44,3) end
    if sel<1 then sel=#labels end
    if sel>#labels then sel=1 end
    if btnp(4) then
        if sel<4 then start_game(sel) else game_state="controls" controls_init() end
    end
end

function draw_menu()
    -- Title
    print("\014sPACE 8",36,16,7)
    print("v2.0.0",48,28,6)
    local y=46
    for i=1,#labels do
        local c=i==sel and 7 or 6
        if i==sel then print(">",36+time()%1\0.5,y,c) end
        spr(icons[i],44,y)
        print(labels[i],54,y,c)
        y+=12
    end
    print("🅾️ select  ❎ back",30,104,5)
    print("made with \fe♥\f7 by ian skelskey",12,116,5)
end
