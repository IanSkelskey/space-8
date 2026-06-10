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
death_jingle_t,death_skip_pending=0,false
local DEATH_ANIM_MIN=45      -- minimum death animation duration (frames)
local DEATH_JINGLE_LEN=210   -- full gameover jingle length; cart loads only after this ends
vr=1 -- visible round counter (always starts at 1)
shake=0 -- screen-shake intensity (px), decays each frame, set on hits in ship_kill
money_total,last_pay,last_bonus,last_payout_ready=0,0,0,false
-- round-summary state: captured round score + obstacle kills, count-up timer, live kill tally
last_score,last_kills,sum_t,obk=0,0,0,0
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
 last_score,last_kills,sum_t=scoreh*1000+score,obk,0
 score,scoreh,db=0,0,0
 round_number+=1 vr+=1
 -- flag distance for regen in UI (station ensure_mission will set new name+distance next visit)
 mission_distance,dr=0,0
 snd_music(8)
 -- round clear: blow up everything left on the field. bhabsorb=true so these kills
 -- drop loot + booms but award NO score. collectibles are NOT cleared, so the coins
 -- (existing + freshly dropped) stay on screen to be scooped during the fly-off.
 bhabsorb=true
 asteroid_absorb(0,0,128,128) comet_absorb(0,0,128,128) popcorn_absorb(0,0,128,128)
 bhabsorb=false
 p_absorb(0,0,128,128,{[9]=true}) -- clear enemy bullets so the fly-off can't hurt the player
 ship_departing,game_state=true,"fanfare_depart"
end

-- round-clear summary panel: tallies count up over sum_t, then a continue prompt blinks
-- one summary row: label left at x34, value right-aligned to x94, both colour c
function srow(y,l,v,c) print(l,34,y,c) v=""..v print(v,94-#v*4,y,c) end

function draw_summary()
 local a=min(1,sum_t/40)
 -- "round clear": secondary font, centred, per-letter sine wave + drop shadow
 local s="round clear"
 local x=64-print("\014"..s,0,200)/2
 for i=1,#s do
  local c,yy="\014"..sub(s,i,i),34+sin(t()/2+i/9)*2
  print(c,x+1,yy+1,3)
  x=print(c,x,yy,11)
 end
 srow(48,"destroyed",flr(last_kills*a),7)
 srow(56,"score",flr(last_score*a),7)
 srow(70,"payout","+"..flr(last_pay*a),10)
 srow(78,"bonus","+"..flr(last_bonus*a),10)
 srow(88,"earned","$"..flr((last_pay+last_bonus)*a),10)
 if a>=1 and sum_t%30<20 then print("🅾️ continue",40,100,6) end
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

	-- pause menu removed (handled in UI cart to save tokens)

	if game_state=="fanfare_depart"then
	 if ship_departing then
	  ship.y-=1.5
	  ship_thrust(0.8,0,-1.5) -- boost trail while flying off
	  ship.vlean+=mid(-0.2,-ship.vlean,0.2) -- roll lean back to level
	  if ship.y+ship.h<0 then ship_departing=false end
	 else
	  -- ship gone: round summary counts up (sum_t/40), then continue on a press
	  sum_t+=1
	  if sum_t>40 and(btnp(4)or btnp(5)) then tu(1) end
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
			-- dying: play the gameover jingle, then hand off to the ui cart's gameover
			if ship.dying then
				-- (re)start the jingle if it isn't playing; seed its countdown once
				if current_music!=9 then snd_music(9) if death_jingle_t<=0 then death_jingle_t=DEATH_JINGLE_LEN-ship.death_t end end
				if death_jingle_t>0 then death_jingle_t-=1 end
				-- after the min animation: arm once buttons release, then a single press skips the rest
				if ship.death_t>=DEATH_ANIM_MIN then
					if not(btn(4)or btn(5)) then death_skip_pending=true end
					if death_skip_pending and(btnp(4)or btnp(5)) then death_jingle_t=0 end
					if death_jingle_t<=0 then tu(2) return end
				end
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
		if not ship_departing then draw_summary() end
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
		if game_state=="dying" and death_skip_pending then
			-- simple centered prompt (multi-line minimal tokens)
			local t="🅾️/❎ skip"
			local x=64-#t*2
			print(t,x,62,7)
		end
	end -- gameover never drawn here now (handled in ui cart)
	-- map screen-palette slot 15 -> hidden colour 140 (blue comet ramp); set last so per-entity pal() resets don't clobber it before flip
	pal(15,140,1)
end
