-- ui cart boot logic
df=df or 2
-- gameplay cart now retains control until jingle (pattern 9) fully completes,
-- so no UI-side countdown or restart needed.
function _init()
 cartdata("sp8")
 local st=persist_load_ui_state()
 -- set defaults if empty
 money_total=money_total or 0
 ts=ts or 0 tsh=tsh or 0
 last_pay=last_pay or 0 last_bonus=last_bonus or 0
 vr=vr or 1
 level_fanfare_timer=level_fanfare_timer or 0
 ship=ship or {fire_rate_level=0,shield_level=0,spread_level=0,hull_level=0,thruster_level=0,shield_unlocked=false,hull=2}
 -- stub for shield unlock when in ui cart (real version exists in gameplay cart)
 if not ship_unlock_shield then
  function ship_unlock_shield()
   ship.shield_unlocked=true
   if (ship.shield_level or 0)<1 then ship.shield_level=1 end
   ship.shield_power=100 -- for display; gameplay cart will re-init proper vars
  end
 end
 if st==1 then
  game_state="station" station_init()
 elseif st==2 then
  game_state="gameover" -- jingle expected to have finished in gameplay cart
  -- if silent (e.g., jingle failed) fall back to menu loop for gameover ambience
  if current_music<0 then snd_music(0) end
 else
  game_state="menu" menu_init()
 end
 -- init starfield for ui backgrounds
 if starfield_init then starfield_init() end
 hs_init()        -- load table
 -- Remove automatic hs_process_new_run() call
 dset(0,0)
 -- start appropriate looping music for initial ui state
 if game_state=="menu" then
  snd_music(0)
 elseif game_state=="station" then
  snd_music(10)
 end
end

function _update()
 -- update starfield every frame
 if update_starfield then update_starfield() end
 if game_state=="menu" then update_menu()
 elseif game_state=="station" then update_station()
 elseif game_state=="help" then update_help()
 elseif game_state=="highscore_entry" then update_highscore_entry()
 elseif game_state=="gameover" then
  -- Check for highscore qualification
  local lo,hi=persist_fetch_last_run()
  local qualified = false
  if (lo or 0)>0 or (hi or 0)>0 then
   local val=hi*1000+lo
   local di=df or 1
   local t=hs_sets[di]
   qualified = #t<4 or val>((t[#t].hi or 0)*1000+(t[#t].lo or 0))
  end
  
  if btnp(4) or btnp(5) then
    if qualified then
      -- enter highscore entry with either button
      game_state="highscore_entry"
      highscore_entry_init()
      if current_music~=0 and current_music~=9 then snd_music(0) end
      snd_sfx(63)
    else
      -- go back to menu
      persist_clear_last_run()
      persist_reset_progress()
      game_state="menu"
      menu_init()
      if current_music~=0 then snd_music(0) end
      dset(0,0)
    end
  end
 end
end

function _draw()
 cls()
 -- draw starfield first (behind ui)
 if draw_starfield then draw_starfield() end
 if game_state=="menu" then draw_menu()
 elseif game_state=="station" then draw_station()
 elseif game_state=="help" then draw_help()
 elseif game_state=="highscore_entry" then draw_highscore_entry()
 elseif game_state=="gameover" then draw_gameover() end
 pal(15,140,1)
end