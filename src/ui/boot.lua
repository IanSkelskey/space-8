-- ui cart boot logic
df=df or 2
function _init()
 pal(15,0x81,1)
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
  game_state="gameover"
 else
  game_state="menu" menu_init()
 end
 -- init starfield for ui backgrounds
 if starfield_init then starfield_init() end
 dset(0,0)
 snd_music(0)
end

function _update()
 -- update starfield every frame
 if update_starfield then update_starfield() end
 if game_state=="menu" then update_menu()
 elseif game_state=="station" then update_station()
 elseif game_state=="gameover" then
  if btnp(5) then
   game_state="menu"
   menu_init()
   dset(0,0)
  end
 end
end

function _draw()
 cls()
 -- draw starfield first (behind ui)
 if draw_starfield then draw_starfield() end
 if game_state=="menu" then draw_menu()
 elseif game_state=="station" then draw_station()
 elseif game_state=="gameover" then draw_gameover() end
end