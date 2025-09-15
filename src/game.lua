game_state,prev_game_state="menu","menu"
function aabb(ax,ay,aw,ah,bx,by,bw,bh)
	return ax<bx+bw and bx<ax+aw and ay<by+bh and by<ay+ah
end
local MM,FL,MB,B100,PR=3,120,35,4,0.03
current_mission,round_number,mission_distance,distance_remaining,level_fanfare_timer,ship_departing=nil,1,0,0,0,false
money_total,last_pay,last_bonus,last_payout_ready=money_total or 0,last_pay or 0,last_bonus or 0,last_payout_ready or false
sci_adj,sci_noun=split"quantum,plasma,ionic,fusion,nano,void",split"core,drive,matrix,relay,reactor,array"
function generate_mission()
	local adj,noun=sci_adj[flr(rnd(#sci_adj))+1],sci_noun[flr(rnd(#sci_noun))+1]
	current_mission=adj.." "..noun
	mission_distance,distance_remaining=400+round_number*80,400+round_number*80
	if sl then sl(round_number) end
end
function complete_mission()
	local pts=hud_get_points and hud_get_points()or 0
	last_bonus=flr(pts*PR)
	last_pay=MB+flr(mission_distance/100)*B100
	money_total+=last_pay+last_bonus
	last_payout_ready=true
	if hud_reset_points then hud_reset_points() end
	round_number+=1
	generate_mission()
	asteroid_init()
	blackhole_init()
	comet_init()
	music(-1,0)
	music(8,0,MM)
	level_fanfare_timer,ship_departing,game_state=FL,true,"fanfare_depart"
end
function reset_game()
	music(-1,0)
	starfield_init()
	if ship_reset_upgrades then ship_reset_upgrades() end
	ship_init()
	asteroid_init()
	hud_init()
	blackhole_init()
	comet_init()
	station_init()
	menu_init()
	game_state,prev_game_state,round_number="menu","menu",1
	current_mission,mission_distance,distance_remaining,money_total,ts=nil,0,0,0,0
	last_pay,last_bonus,last_points,last_payout_ready=0,0,0,false
	music(0,0,MM)
end
function _init()
	starfield_init()
	if ship_reset_upgrades then ship_reset_upgrades() end
	ship_init()
	asteroid_init()
	hud_init()
	blackhole_init()
	comet_init()
	station_init()
	menu_init()
	music(0,0,MM)
end
function _update()
	update_starfield()
	if level_fanfare_timer>0 then level_fanfare_timer-=1 end

	if game_state=="fanfare_depart"then
		if ship_departing then
			ship.y-=1.5
			if ship.y+ship.h<0 then ship_departing=false end
		end
		if not ship_departing and level_fanfare_timer<=0 then
			ship_init()
			game_state="station"
		end
		prev_game_state="fanfare_depart"
		return
	end
	local old_state,gs,pgs=game_state,game_state,prev_game_state
	if gs=="game"and pgs=="station"then
		music(-1,0)
		music(4,0,MM)
	elseif gs=="dying"and pgs=="game"then
		music(-1,0)
		music(9,0,MM)
	elseif(gs=="menu"or gs=="station")and pgs!="menu"and pgs!="station"and pgs!="controls"and level_fanfare_timer<=0 then
		music(-1,0)
		music(gs=="station"and 10 or 0,0,MM)
	elseif gs=="gameover"and(pgs=="game"or pgs=="menu"or pgs=="station")then
		music(-1,0)
	end
	if gs=="menu"then
		update_menu()
		if game_state=="game"then
			game_state="station"
			generate_mission()
			music(-1,0)
			music(10,0,MM)
		end
	elseif gs=="controls"then
		update_controls()
	elseif gs=="station"then
		update_station()
	elseif gs=="game"then
		update_blackhole()
		update_asteroid()
		update_comet()
		update_ship()
		if distance_remaining>0 and not(ship and ship.dying)then
			distance_remaining-=1
			if distance_remaining<=0 then complete_mission() end
		end
		if ship and ship.dying then game_state="dying"end
	elseif gs=="dying"then
		update_blackhole()
		update_asteroid()
		update_comet()
		update_ship()
		if ship_death_done and ship_death_done()then game_state="gameover"end
	elseif gs=="gameover"then
		if btnp(4)then reset_game() end
	end
	prev_game_state=old_state
end
function _draw()
	cls()
	draw_starfield()
	local gs=game_state
	if gs=="menu"then
		draw_menu()
	elseif gs=="controls"then
		draw_controls()
	elseif gs=="station"then
		draw_station()
	elseif gs=="fanfare_depart"or gs=="game"or gs=="dying"then
		draw_blackhole()
		draw_asteroid()
		draw_comet()
		draw_ship()
		draw_hud()
	elseif gs=="gameover"then
		draw_gameover()
	end
end
