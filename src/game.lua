game_state="game"
-- shared small constants / helpers (token savings)
FT=1/30
function aabb(ax,ay,aw,ah,bx,by,bw,bh)
	return ax<bx+bw and bx<ax+aw and ay<by+bh and by<ay+ah
end
-- ship collision shorthand
function scoll(x,y,w,h)
 -- ship hitbox: 5x5 centered on the ship (smaller than the 16x16 sprite)
 return aabb(x,y,w,h,ship.x+1.5,ship.y+1.5,5,5)
end
-- gameplay-only state (mission name now owned by UI cart via station ensure_mission)
round_number,mission_distance,dr,level_fanfare_timer,ship_departing=1,0,0,0,false
death_jingle_t=death_jingle_t or 0 -- frames remaining for death jingle before gameover
death_skip_pending=death_skip_pending or false -- whether first skip press has been made during jingle
death_skip_lock=death_skip_lock or 0 -- frames before skip input is accepted (debounce)
local DEATH_ANIM_MIN=45      -- minimum death animation duration (frames)
local DEATH_JINGLE_LEN=210   -- full gameover jingle length; cart loads only after this ends
vr=1 -- visible round counter (always starts at 1)
shake=0 -- screen-shake intensity (px), decays each frame, set on hits in ship_kill
money_total,last_pay,last_bonus,last_payout_ready=0,0,0,false
-- short init bundle (entities + hud + ship)
function ie() ship_init() asteroid_init() hud_init() blackhole_init() comet_init() end
function tu(s) persist_save_from_game(s) load("ui.p8") load("ui.p8.png") load("#space_8_ui") end
function complete_mission()
 local mult=dsc and dsc[df] or 1
 last_pay=flr((40+mission_distance\25)*mult)
 money_total+=last_pay
 -- lifetime money accumulation
 if not money_life_lo then money_life_lo,money_life_hi=0,0 end
 money_life_lo+=last_pay while money_life_lo>=1000 do money_life_lo-=1000 money_life_hi+=1 end
 last_payout_ready=true
 score,scoreh,db=0,0,0
 round_number+=1 vr+=1
 -- flag distance for regen in UI (station ensure_mission will set new name+distance next visit)
 mission_distance,dr=0,0
 snd_music(8)
 p_clear() -- start the fly-off with a clean field so only the boost trail shows
 level_fanfare_timer,ship_departing,game_state=120,true,"fanfare_depart"
end

-- gameplay cart init
function _init()
 starfield_init()
 death_jingle_t=0
 local resumed=persist_load_game_start()
 if not resumed then
  tu(0)
  return
 end
 ie() p_clear()
 -- mission distance & scaling (UI decides name; always recompute here)
 mission_distance=400+round_number*80 dr=mission_distance sl(round_number)
 -- start gameplay background music (pattern 4)
 snd_music(4)
end
function _update()
	if shake>0 then shake-=1 end
	update_starfield()
	if level_fanfare_timer>0 then level_fanfare_timer-=1 end

	-- pause menu removed (handled in UI cart to save tokens)

	if game_state=="fanfare_depart"then
	 if ship_departing then
	  ship.y-=1.5
	  ship_thrust(0.8,0,-1.5) -- boost trail while flying off
	  ship.vlean+=mid(-0.2,-ship.vlean,0.2) -- roll lean back to level
	  if ship.y+ship.h<0 then ship_departing=false end
	 end
	 p_upd()
	 if not ship_departing and level_fanfare_timer<=0 then
	  -- mission finished: return to station in ui cart
	  tu(1)
	 end
	 return
	end
	local gs=game_state
	if gs=="game" or gs=="dying"then
		update_blackhole() update_asteroid() update_comet() update_ship() p_upd()
		if game_state=="game" then
			-- death is handled in ship_kill (sets game_state="dying" + stores run score);
			-- here we only advance mission distance
			if dr>0 then
				dr-=1
				if dr<=0 then complete_mission() end
			end
		else
			-- in dying state: count down jingle; only transition after both thresholds
			if ship.dying then
				-- safety: if somehow music was interrupted, restart it without resetting timer
				if death_jingle_t>0 and current_music!=9 then snd_music(9) end
				-- edge case: death flag set but jingle never started (death_jingle_t==0 & current_music!=9)
				if death_jingle_t==0 and ship.death_t<DEATH_JINGLE_LEN and current_music!=9 then
					death_jingle_t=DEATH_JINGLE_LEN-ship.death_t
					snd_music(9)
				end
				if death_jingle_t>0 then death_jingle_t-=1 end
				-- skip lock: >0 counting down; ==0 waiting for release; <0 ready
				if death_skip_lock>0 then
					death_skip_lock-=1
				elseif death_skip_lock==0 then
					-- require both buttons released once after lock period before arming
					if not (btn(4) or btn(5)) then death_skip_lock=-1 end
				end
				-- allow player to skip to gameover only when armed (lock<0)
				if death_skip_lock<0 and btnp and (btnp(4) or btnp(5)) then
					if not death_skip_pending then
						death_skip_pending=true
					else
						-- second press: force finish timers
						death_jingle_t=0
						ship.death_t=DEATH_ANIM_MIN
					end
				end
				if ship.death_t>=DEATH_ANIM_MIN and death_jingle_t<=0 then
					death_skip_pending=false death_skip_lock=0
					tu(2)
					return
				end
			end
		end
	end
end
function _draw()
	cls()
	-- screen shake: jitter the world camera; reset before HUD so it stays fixed
	if shake>0 then camera(rnd(shake)-shake/2,rnd(shake)-shake/2) end
	draw_starfield()
	if game_state=="fanfare_depart"then
		draw_ship()
		p_draw()
		camera()
		draw_hud()
	elseif game_state=="game"or game_state=="dying"then
		draw_blackhole()
		draw_asteroid()
		draw_ship()
		p_draw()
		draw_comet() -- after p_draw so comet sprites sit above their trail particles
		camera()
		draw_hud()
		if game_state=="dying" and death_skip_pending and death_skip_lock<0 then
			-- simple centered prompt (multi-line minimal tokens)
			local t="🅾️/❎ skip"
			local x=64-#t*2
			print(t,x,62,7)
		end
	end -- gameover never drawn here now (handled in ui cart)
	-- map screen-palette slot 15 -> hidden colour 140 (blue comet ramp); set last so per-entity pal() resets don't clobber it before flip
	pal(15,140,1)
end
