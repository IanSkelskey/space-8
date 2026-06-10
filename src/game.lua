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
round_number,mission_distance,dr,ship_departing=1,0,0,false
local DEATH_ANIM_MIN=45      -- min death-animation frames before the gameover jingle can be skipped
local GO_JINGLE,RC_JINGLE=210,90 -- gameover / round-clear jingle lengths (frames); tune to your music
jingle_t=0 -- countdown for the current round-end jingle; cart hands off once it finishes (or is skipped)
taunts=split"game is hard.,get good.,go touch grass.,skill issue.,try again."
vr=1 -- visible round counter (always starts at 1)
shake=0 -- screen-shake intensity (px), decays each frame, set on hits in ship_kill
money_total,last_pay,last_bonus,last_payout_ready=0,0,0,false
-- round-summary data passed to the ui cart: captured round score + obstacle kills (live tally obk)
last_score,last_kills,obk=0,0,0
-- short init bundle (entities + hud + ship)
function ie() ship_init() asteroid_init() hud_init() blackhole_init() comet_init() popcorn_init() bomb_init() end
function tu(s) persist_save_from_game(s) load("ui.p8") load("ui.p8.png") load("#space_8_ui") end
function complete_mission()
 local mult=dsc[df]
 last_pay=flr((40+mission_distance\25)*mult)
 money_total+=last_pay
 -- lifetime money now folded in by the ui cart on arrival (saves gameplay tokens)
 last_payout_ready=true
 -- freeze the round summary now (before the explode-all sweep can inflate the kill count)
 last_score,last_kills=scoreh*1000+score,obk
 score,scoreh,db=0,0,0
 round_number+=1 vr+=1
 -- flag distance for regen in UI (station ensure_mission will set new name+distance next visit)
 mission_distance,dr=0,0
 snd_music(8) jingle_t=RC_JINGLE
 -- round clear: blow up everything left on the field. bhabsorb=true so these kills
 -- drop loot + booms but award NO score. collectibles are NOT cleared, so the coins
 -- (existing + freshly dropped) stay on screen to be scooped during the fly-off.
 bhabsorb=true
 asteroid_absorb(0,0,128,128) comet_absorb(0,0,128,128) popcorn_absorb(0,0,128,128)
 bhabsorb=false
 p_absorb(0,0,128,128,{[9]=true}) -- clear enemy bullets so the fly-off can't hurt the player
 ship_departing,game_state=true,"fanfare_depart"
end

-- gameplay cart init
function _init()
 starfield_init()
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

	-- pause menu removed (handled in UI cart to save tokens)

	if game_state=="fanfare_depart"then
	 if jingle_t>0 then jingle_t-=1 end
	 if ship_departing then
	  ship.y-=1.5
	  ship_thrust(0.8,0,-1.5) -- boost trail while flying off
	  ship.vlean+=mid(-0.2,-ship.vlean,0.2) -- roll lean back to level
	  if ship.y+ship.h<0 then ship_departing=false end
	 else
	  -- ship gone: let the round-clear jingle finish (or skip with a press), then hand off
	  if btnp(4)or btnp(5) then jingle_t=0 end
	  if jingle_t<=0 then tu(1) end
	 end
	 p_upd()
	 return
	end
	local gs=game_state
	if gs=="game" or gs=="dying"then
		update_bomb() update_blackhole() update_asteroid() update_comet() update_popcorn() update_ship() p_upd()
		if game_state=="game" then
			-- death is handled in ship_kill (sets game_state="dying" + stores run score);
			-- here we only advance mission distance
			if dr>0 then
				dr-=1
				if dr<=0 then complete_mission() end
			end
		else
			-- dying: death explosion + the full gameover jingle (taunt shown over it). once the
			-- jingle finishes (or a press skips it past the min anim), hand off to the ui gameover.
			if ship.dying then
				if current_music!=9 then snd_music(9) jingle_t=GO_JINGLE end if jingle_t>0 then jingle_t-=1 end
				if ship.death_t>=DEATH_ANIM_MIN then if btnp(4)or btnp(5) then jingle_t=0 end if jingle_t<=0 then tu(2) return end end
			end
		end
	end
end
function _draw()
	cls()
	-- screen shake: jitter the world camera; reset before HUD so it stays fixed
	if shake>0 then camera(rnd(shake)-shake/2,rnd(shake)-shake/2) end
	clip(0,17,128,128) -- confine all gameplay below the 17px HUD band so nothing overlaps it
	draw_starfield()
	if game_state=="fanfare_depart"then
		draw_ship()
		p_draw()
		camera() clip()
		draw_hud()
	elseif game_state=="game"or game_state=="dying"then
		draw_blackhole()
		draw_asteroid()
		draw_ship()
		p_draw()
		draw_popcorn()
		draw_comet() -- after p_draw so comet sprites sit above their trail particles
		draw_bomb()
		camera() clip()
		draw_hud()
		if game_state=="dying" then
			-- taunt the player over the death jingle; offer a skip once the explosion has played
			local tt=taunts[ts%#taunts+1]
			print(tt,64-#tt*2,90,14)
			if ship.death_t>=DEATH_ANIM_MIN and time()%0.6<0.4 then
				local p="🅾️/❎ skip"
				print(p,64-#p*2,100,6)
			end
		end
	end -- gameover + round summary now handled in the ui cart

	-- map screen-palette slot 15 -> hidden colour 140 (blue comet ramp); set last so per-entity pal() resets don't clobber it before flip
	pal(15,140,1)
end
