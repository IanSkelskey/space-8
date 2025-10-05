local sel=1
local show_hs=false -- new: full high score mode

local function start_game(set_df)
 df=set_df
 round_number=sr[df] vr=1
 persist_save_for_game()
 load("space_shooter.p8")
end

-- extend labels with highscores entry
local labels,icons=split"easy,normal,veteran,highscores",{19,34,6,50}

function menu_init() sel,show_hs=1,false end

function update_menu()
    if hs_entering then hs_update_entry() return end
    if show_hs then
        -- full highscores mode
        if btnp(5) or btnp(4) then show_hs=false snd_sfx(44,3) end
        return
    end
    -- normal menu navigation
    if btnp(2) then sel-=1 snd_sfx(44,3) end
    if btnp(3) then sel+=1 snd_sfx(44,3) end
    if sel<1 then sel=#labels end
    if sel>#labels then sel=1 end
    if btnp(4) then
        if sel<=3 then
            start_game(sel)
        else
            show_hs=true snd_sfx(63,3)
        end
    end
end

function draw_menu()
    if show_hs then
        print("\014sPACE 8",36,12,7)
        hs_draw_full()
        hs_draw_entry_overlay()
        return
    end
    -- main menu
    print("\014sPACE 8",36,20,7)
    print("v2.0.0",48,32,6)
    local y=50
    for i=1,#labels do
        local c=i==sel and 7 or 6
        if i==sel then print(">",36+time()%1\0.5,y,c) end
        spr(icons[i],44,y)
        print(labels[i],54,y,c)
        y+=12
    end
    print("🅾️ select  ❎ back",30,104,5)
    print("made with \fe♥\f7 by ian skelskey",12,116,5)
    -- compact high score (only top)
    hs_draw_compact()
    hs_draw_entry_overlay()
end
