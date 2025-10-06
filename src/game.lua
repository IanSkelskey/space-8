game_state,prev_game_state="game","game"
-- shared small constants / helpers (token savings)
FT=1/30
function aabb(ax,ay,aw,ah,bx,by,bw,bh)
	return ax<bx+bw and bx<ax+aw and ay<by+bh and by<ay+ah
end
-- ship collision shorthand
function scoll(x,y,w,h)
 return aabb(x,y,w,h,ship.x,ship.y,ship.w,ship.h)
end
-- gameplay-only state (mission name now owned by UI cart via station ensure_mission)
round_number,mission_distance,dr,level_fanfare_timer,ship_departing=1,0,0,0,false
vr=1 -- visible round counter (always starts at 1)
sr=sr or split"1,2,4" -- start rounds per difficulty (easy,normal,veteran)
money_total,last_pay,last_bonus,last_payout_ready=0,0,0,false
-- short init bundle (entities + hud + ship)
function ie() ship_init() asteroid_init() hud_init() blackhole_init() comet_init() end
function complete_mission()
 local mult=dsc and dsc[df] or 1
 last_pay=flr((40+mission_distance\25)*mult)
 money_total+=last_pay
 last_payout_ready=true
 score,scoreh,db=0,0,0
 round_number+=1 vr+=1
 -- flag distance for regen in UI (station ensure_mission will set new name+distance next visit)
 mission_distance,dr=0,0
 snd_music(8)
 level_fanfare_timer,ship_departing,game_state=120,true,"fanfare_depart"
end
-- no local reset (handled by ui cart). When player chooses restart in ui cart it resets cartdata and relaunches.
function _init()
 pal(15,0x81,1)
 starfield_init()
 local resumed=persist_load_game_start()
 if not resumed then
  persist_save_from_game(0)
  load("ui.p8")
  return
 end
 persist_consume_start_flag()
 ie() p_clear()
 -- mission distance & scaling (UI decides name; always recompute here)
 mission_distance=400+round_number*80 dr=mission_distance sl(round_number)
 snd_music(10)
end
function _update()
	update_starfield()
	if level_fanfare_timer>0 then level_fanfare_timer-=1 end

	-- pause menu removed (handled in UI cart to save tokens)

	if game_state=="fanfare_depart"then
	 if ship_departing then
	  ship.y-=1.5
	  if ship.y+ship.h<0 then ship_departing=false end
	 end
	 p_upd()
	 if not ship_departing and level_fanfare_timer<=0 then
	  -- mission finished: return to station in ui cart
	  persist_save_from_game(1) -- station state
	  load("ui.p8")
	 end
	 prev_game_state="fanfare_depart"
	 return
	end
	snd_update_music(game_state,prev_game_state,level_fanfare_timer)
	local gs=game_state
	if gs=="game" or gs=="dying"then
		update_blackhole() update_asteroid() update_comet() update_ship() p_upd()
		if game_state=="game" then
			if ship.dying then
				game_state="dying"
			elseif dr>0 then
				dr-=1
				if dr<=0 then complete_mission() end
			end
		else
			if ship.dying and ship.death_t>=45 then
				ship.shield_pulse_level=0 -- reset per-run upgrade
				-- CHANGED: store total accumulated run score (ts/tsh) instead of per‑mission score
				persist_store_last_run_total(tsh*1000+ts) -- new robust call
				persist_save_from_game(2)
				load("ui.p8")
				return
			end
		end
	end
	prev_game_state=game_state
end
function _draw()
	cls()
	draw_starfield()
	if game_state=="fanfare_depart"then
		draw_ship()
		draw_hud()
	elseif game_state=="game"or game_state=="dying"then
		draw_blackhole()
		draw_asteroid()
		draw_comet()
		draw_ship()
		p_draw()
		draw_hud()
	end -- gameover never drawn here now (handled in ui cart)
end
