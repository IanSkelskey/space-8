game_state,prev_game_state="menu","menu"
-- shared small constants / helpers (token savings)
FT=1/30
function dmul() return 0.6+0.1*df+0.1*mid(0,df-1,1) end -- difficulty cost multiplier
function aabb(ax,ay,aw,ah,bx,by,bw,bh)
	return ax<bx+bw and bx<ax+aw and ay<by+bh and by<ay+ah
end
-- ship collision shorthand
function scoll(x,y,w,h)
 return aabb(x,y,w,h,ship.x,ship.y,ship.w,ship.h)
end
current_mission,round_number,mission_distance,dr,level_fanfare_timer,ship_departing=nil,1,0,0,0,false
vr=1 -- visible round counter (always starts at 1)
sr=sr or split"1,2,4" -- start rounds per difficulty (easy,normal,veteran)
money_total,last_pay,last_bonus,last_payout_ready=0,0,0,false
sci_adj,sci_noun=split"quantum,plasma,ionic,fusion,nano,void",split"core,drive,matrix,relay,reactor,array"
-- short init bundle (entities + hud + ship)
function ie() ship_init() asteroid_init() hud_init() blackhole_init() comet_init() end
function generate_mission()
	local a,n=sci_adj,sci_noun
	current_mission=a[flr(rnd(#a))+1].." "..n[flr(rnd(#n))+1]
	mission_distance=400+round_number*80
	dr=mission_distance
	sl(round_number)
end
function complete_mission()
	local mult=dsc and dsc[df] or 1
	-- increased bonus % and base pay for faster early progression
	last_bonus=flr((score or 0)*0.09*mult)
	last_pay=flr((40+mission_distance\25)*mult)
	money_total+=last_pay+last_bonus
	last_payout_ready=true
	score,scoreh,db=0,0,0
	round_number+=1
	vr+=1
	generate_mission()
	asteroid_init()
	blackhole_init()
	comet_init()
	snd_music(MUS_FANFARE)
	level_fanfare_timer,ship_departing,game_state=120,true,"fanfare_depart"
end
function reset_game()
	snd_music()
	starfield_init() ship_reset_upgrades() ie() station_init() menu_init() p_clear()
	game_state,prev_game_state,round_number,current_mission,mission_distance,dr,money_total,ts,tsh,last_pay,last_bonus,last_payout_ready="menu","menu",sr[df],nil,0,0,0,0,0,0,0,false
	vr=1 snd_music(MUS_MENU)
end
function _init()
	-- Set up palette swap: use extended color 129 instead of color 15
	-- 129 = 0x81 in hex (128 + 1)
	pal(15, 0x81, 1)
	
	starfield_init() ship_reset_upgrades() ie() station_init() menu_init() p_clear()
	round_number=sr[df] tsh=0 vr=1 snd_music(MUS_MENU)
end
function _update()
	update_starfield()
	if level_fanfare_timer>0 then level_fanfare_timer-=1 end

	-- update pause menu item (shows current round)
	do local show=(game_state=="game" or game_state=="station" or game_state=="fanfare_depart") if show then menuitem(1,"round "..vr) else menuitem(1) end end

	if game_state=="fanfare_depart"then
		if ship_departing then
			ship.y-=1.5
			if ship.y+ship.h<0 then ship_departing=false end
		end
		if not ship_departing and level_fanfare_timer<=0 then
			ship_init()
			game_state="station"
		end
		p_upd() -- Update particles during fanfare
		prev_game_state="fanfare_depart"
		return
	end
	local prev=game_state
	snd_update_music(game_state,prev_game_state,level_fanfare_timer)
	local gs=game_state
	if gs=="menu"then
		update_menu()
		if game_state=="game"then
			game_state="station"
			generate_mission()
			snd_music(MUS_STATION)
		end
	elseif gs=="controls"then
		update_controls()
	elseif gs=="station"then
		update_station()
		p_clear() -- Clear particles when at station
		-- Clear payout flag when leaving station to start new mission
		if game_state=="game" and last_payout_ready then
			last_payout_ready=false
		end
	elseif gs=="game" or gs=="dying"then
		update_blackhole() update_asteroid() update_comet() update_ship() p_upd()
		if game_state=="game" then if ship.dying then game_state="dying" elseif dr>0 then dr-=1 if dr<=0 then complete_mission() end end else if ship.dying and ship.death_t>=45 then game_state="gameover" end end
	elseif gs=="gameover"then
		if btnp(4)then reset_game() end
	end
	prev_game_state=prev
end
function _draw()
	cls()
	draw_starfield()
	if game_state=="menu"then
		draw_menu()
	elseif game_state=="controls"then
		draw_controls()
	elseif game_state=="station"then
		draw_station()
	elseif game_state=="fanfare_depart"then
		draw_ship()
		draw_hud()
	elseif game_state=="game"or game_state=="dying"then
		draw_blackhole()
		draw_asteroid()
		draw_comet()
		draw_ship()
		p_draw() -- Draw all particles
		draw_hud()
	elseif game_state=="gameover"then
		draw_gameover()
	end
end
