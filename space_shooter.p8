pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
-- simple spaceship movement + draw
-- assumes your ship graphic is sprite 0 (top-left 8x8)

#include controls.lua
#include menu.lua
#include starfield.lua
#include ship.lua
#include moon.lua
#include hud.lua
#include blackhole.lua
#include comet.lua

game_state = "menu"

-- reset helper used by obstacles
function reset_game()
    starfield_init()
    ship_init()
    moon_init()
    hud_init()
    blackhole_init()
    comet_init()
    menu_init()
    game_state = "menu"
end

function _init()
    starfield_init()
    ship_init()
    moon_init()
    hud_init()
    blackhole_init()
    comet_init()
    menu_init()
end

function _update()
    update_starfield()
    if game_state == "menu" then
        update_menu()
    elseif game_state == "controls" then
        update_controls()
    elseif game_state == "game" then
        update_blackhole()
        update_moon()
        update_comet()
        update_ship()
        -- transition if ship triggered death internally (optional guard)
        if ship and ship.dying then game_state="dying" end
    elseif game_state == "dying" then
        -- keep background/obstacles moving for drama
        update_blackhole()
        update_moon()
        update_comet()
        update_ship()
        if ship_death_done and ship_death_done() then
            game_state = "gameover"
        end
    elseif game_state == "gameover" then
        -- wait for confirm to return to menu
        if btnp(4) then
            reset_game()
        end
    end
end

function _draw()
    cls(0)
    draw_starfield()
    if game_state == "menu" then
        draw_menu()
    elseif game_state == "controls" then
        draw_controls()
    elseif game_state == "game" or game_state == "dying" then
        draw_blackhole()
        draw_moon()
        draw_comet()
        draw_ship()
        draw_hud()
    elseif game_state == "gameover" then
        -- show game over with score and hint
        draw_hud()
        local t = "game over"
        local p = "z: menu"
        print(t, 40, 54, 7)
        print(p, 46, 66, 6)
    end
end
__gfx__
00000000001661000666665000eee000001661000660065000008888000000000000000000000000000000000000000000000000000000000000000000000000
00000000016cc610665666650e222e0001cc66106656666500088998000000000000000000000000000000000000000000000000000000000000000000000000
007007001666666165665665e21002e0156666606566566500089998000000000000000000000000000000000000000000000000000000000000000000000000
000770006676676665666655e20000ee576676600560065000889988000000000000000000000000000000000000000000000000000000000000000000000000
000770006666666666666655e200002e566666600660065000898880000000000000000000000000000000000000000000000000000000000000000000000000
0070070066d66d66566565550e10002e5d66d6605665655502888000000000000000000000000000000000000000000000000000000000000000000000000000
00000000015115105555555500e222e0151151005555555512200000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000005555550000eee00000000000550055021000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000200001f0501e0501d0401c0401b0401a0401904018040170401604015040140401304012030110301002000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100000f0500e0500d0500c0500b0500a0500905008050070500605005050040500305003050020500205002050020500205002050020500205002050020500205002050020500205002050020500205002050
