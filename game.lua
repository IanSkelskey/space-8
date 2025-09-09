-- main game loop and logic

game_state = "menu"
prev_game_state = "menu"

-- mission system
current_mission = nil
round_number = 1
mission_distance = 0
distance_remaining = 0

-- sci-fi name generators
sci_adj = {"quantum","plasma","ionic","fusion","nano","cyber","holo","cryo","flux","void"}
sci_noun = {"core","drive","matrix","relay","beacon","module","crystal","reactor","emitter","array"}

function generate_mission()
    local adj = sci_adj[flr(rnd(#sci_adj))+1]
    local noun = sci_noun[flr(rnd(#sci_noun))+1]
    current_mission = adj.." "..noun
    -- increase distance with each round
    mission_distance = 500 + (round_number * 100)
    distance_remaining = mission_distance
end

function complete_mission()
    round_number += 1
    generate_mission()
    -- reset obstacles for new round
    moon_init()
    blackhole_init()
    comet_init()
    game_state = "station"
end

-- reset helper used by obstacles
function reset_game()
    music(-1, 0) -- stop any playing music
    starfield_init()
    ship_init()
    moon_init()
    hud_init()
    blackhole_init()
    comet_init()
    menu_init()
    game_state = "menu"
    prev_game_state = "menu"
    
    -- reset mission system
    round_number = 1
    current_mission = nil
    mission_distance = 0
    distance_remaining = 0
    
    -- Start menu music (channels 0-1 only)
    music(0, 0, MUSIC_MASK)
end

function _init()
    starfield_init()
    ship_init()
    moon_init()
    hud_init()
    blackhole_init()
    comet_init()
    menu_init()
    
    -- Start menu music (channels 0-1 only)
    music(0, 0, MUSIC_MASK)
end

function _update()
    update_starfield()
    
    -- Store the current state before any updates
    local old_state = game_state
    
    -- Simple music state handling
    if game_state == "game" and prev_game_state == "station" then
        -- Start gameplay music (pattern 4) on channels 0-1
        music(-1, 0)
        music(4, 0, MUSIC_MASK)
    elseif (game_state == "menu" or game_state == "station") and 
           prev_game_state != "menu" and prev_game_state != "station" then
        -- Start menu music (pattern 0) on channels 0-1
        music(-1, 0)
        music(0, 0, MUSIC_MASK)
    elseif (game_state == "controls" or game_state == "gameover") and 
           (prev_game_state == "game" or prev_game_state == "menu" or prev_game_state == "station") then
        -- Stop music when entering non-music states
        music(-1, 0)
    end
    
    if game_state == "menu" then
        update_menu()
        -- Check if menu just changed state to "game"
        if game_state == "game" then
            -- Intercept and go to station instead
            game_state = "station"
            generate_mission()
        end
    elseif game_state == "controls" then
        update_controls()
    elseif game_state == "station" then
        -- station update - press z to launch
        if btnp(4) then
            game_state = "game"
            ship_init() -- reset ship for new round
        end
    elseif game_state == "game" then
        update_blackhole()
        update_moon()
        update_comet()
        update_ship()
        
        -- update distance
        if distance_remaining > 0 and not (ship and ship.dying) then
            distance_remaining -= 1
            if distance_remaining <= 0 then
                complete_mission()
            end
        end
        
        -- transition if ship triggered death internally
        if ship and ship.dying then 
            game_state = "dying" 
        end
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
    
    -- Update previous state
    prev_game_state = old_state
end

function draw_station()
    -- draw space station
    -- main hub
    circfill(30, 64, 20, 5)
    circ(30, 64, 20, 6)
    
    -- docking ports
    rectfill(50, 62, 70, 66, 5)
    rectfill(68, 60, 72, 68, 6)
    
    -- ship docked
    spr(0, 74, 60)
    
    -- mission briefing
    print("space station", 40, 10, 7)
    print("round "..round_number, 48, 20, 6)
    
    print("delivery mission:", 32, 35, 12)
    if current_mission then
        print(current_mission, 64-#current_mission*2, 45, 11)
        print("distance: "..mission_distance.." units", 28, 55, 6)
    end
    
    print("press z to launch", 32, 100, 10)
end

function _draw()
    cls(0)
    draw_starfield()
    if game_state == "menu" then
        draw_menu()
    elseif game_state == "controls" then
        draw_controls()
    elseif game_state == "station" then
        draw_station()
    elseif game_state == "game" or game_state == "dying" then
        draw_blackhole()
        draw_moon()
        draw_comet()
        draw_ship()
        draw_hud()
        
        -- draw distance remaining with better visibility
        if distance_remaining > 0 then
            -- Draw background box for better readability
            rectfill(86, 0, 127, 8, 0)
            print("dist: "..distance_remaining, 88, 2, 11)
        end
    elseif game_state == "gameover" then
        -- show game over with score and hint
        draw_hud()
        local t = "game over"
        local p = "z: menu"
        print(t, 40, 54, 7)
        print(p, 46, 66, 6)
    end
end
