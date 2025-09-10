game_state="menu"
prev_game_state="menu"
function aabb(ax,ay,aw,ah,bx,by,bw,bh)
	return ax<bx+bw and bx<ax+aw and ay<by+bh and by<ay+ah
end
local MM=3
local FL=120
current_mission=nil
round_number=1
mission_distance=0
distance_remaining=0
level_fanfare_timer=0
ship_departing=false
-- payout tuning: modest earnings with smaller point bonus
local MB,B100,PR=35,4,0.03
money_total=money_total or 0
last_pay=last_pay or 0
last_bonus=last_bonus or 0
last_points=last_points or 0
last_payout_ready=last_payout_ready or false
sci_adj={"quantum","plasma","ionic","fusion","nano","cyber","holo","cryo","flux","void"}
sci_noun={"core","drive","matrix","relay","beacon","module","crystal","reactor","emitter","array"}
function generate_mission()
	local adj=sci_adj[flr(rnd(#sci_adj))+1]
	local noun=sci_noun[flr(rnd(#sci_noun))+1]
	current_mission=adj.." "..noun
	mission_distance=400+(round_number*80)
	distance_remaining=mission_distance
 if sl then sl(round_number) end
end
function complete_mission()
	local pts=(hud_get_points and hud_get_points()) or 0
	last_points=pts
	last_bonus=flr(pts*PR)
	last_pay=MB+flr(mission_distance/100)*B100
	money_total+=last_pay+last_bonus
	last_payout_ready=true
	if hud_reset_points then hud_reset_points() end
	round_number+=1
	generate_mission()
	moon_init()
	blackhole_init()
	comet_init()
	music(-1,0)
	music(8,0,MM)
	level_fanfare_timer=FL
	ship_departing=true
	game_state="fanfare_depart"
end
function reset_game()
	music(-1,0)
	starfield_init()
	if ship_reset_upgrades then ship_reset_upgrades() end
	ship_init()
	moon_init()
	hud_init()
	blackhole_init()
	comet_init()
	station_init()
	menu_init()
	game_state="menu"
	prev_game_state="menu"
	round_number=1
	current_mission=nil
	mission_distance=0
	distance_remaining=0
	money_total=0
	last_pay,last_bonus,last_points=0,0,0
	last_payout_ready=false
	music(0,0,MM)
end
function _init()
	starfield_init()
	if ship_reset_upgrades then ship_reset_upgrades() end
	ship_init()
	moon_init()
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

	if game_state=="fanfare_depart" then
		if ship_departing then
			ship.y-=1.5
			if ship.y+ship.h<0 then
				ship_departing=false
			end
		end
		if not ship_departing and level_fanfare_timer<=0 then
			ship_init()
			game_state="station"
		end
		prev_game_state="fanfare_depart"
		return
	end
	local old_state=game_state
	if game_state=="game"and prev_game_state=="station"then
		music(-1,0)
	music(4,0,MM)
	elseif game_state=="dying" and prev_game_state=="game" then
		music(-1,0)
	music(9,0,MM)
	elseif(game_state=="menu"or game_state=="station")and prev_game_state!="menu"and prev_game_state!="station"and level_fanfare_timer<=0 then
		music(-1,0)
	music(0,0,MM)
	elseif(game_state=="controls"or game_state=="gameover")and(prev_game_state=="game"or prev_game_state=="menu"or prev_game_state=="station")then
		music(-1,0)
	end
	if game_state=="menu"then
		update_menu()
		if game_state=="game"then
			game_state="station"
			generate_mission()
		end
	elseif game_state=="controls"then
		update_controls()
	elseif game_state=="station"then
			update_station()
	elseif game_state=="game"then
		update_blackhole()
		update_moon()
		update_comet()
		update_ship()
		if distance_remaining>0 and not(ship and ship.dying)then
			distance_remaining-=1
			if distance_remaining<=0 then
				complete_mission()
			end
		end
		if ship and ship.dying then game_state="dying"end
	elseif game_state=="dying"then
		update_blackhole()
		update_moon()
		update_comet()
		update_ship()
		if ship_death_done and ship_death_done()then
			game_state="gameover"
		end
	elseif game_state=="gameover"then
		if btnp(4)then reset_game()end
	end
	prev_game_state=old_state
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
	elseif game_state=="fanfare_depart" then
		draw_blackhole()
		draw_moon()
		draw_comet()
		draw_ship()
		draw_hud()
	elseif game_state=="game"or game_state=="dying"then
		draw_blackhole()
		draw_moon()
		draw_comet()
		draw_ship()
		draw_hud()
		if mission_distance>0 then
			local f=(mission_distance-max(0,distance_remaining))/max(1,mission_distance)
			f=mid(0,f,1)
			local w,h,x,y=60,3,34,122
			rectfill(x+1,y+1,x+w-1,y+h-1,1)
			local k=flr(f*(w-2))
			if k>0 then rectfill(x+1,y+1,x+1+k,y+h-1,6)end
		end
	elseif game_state=="gameover"then
		draw_hud()
		print("game over",40,54,7)
		print("z: menu",46,66,6)
	end
end
