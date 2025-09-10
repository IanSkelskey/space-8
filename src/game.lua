-- game
game_state="menu"
prev_game_state="menu"
function aabb(ax,ay,aw,ah,bx,by,bw,bh)
	return ax<bx+bw and bx<ax+aw and ay<by+bh and by<ay+ah
end
local MUSIC_MASK=3
local FANFARE_LOCK=120
current_mission=nil
round_number=1
mission_distance=0
distance_remaining=0
level_fanfare_active=false
level_fanfare_timer=0
ship_departing=false
ship_depart_timer=0
local MONEY={MIN_BASE=50,BASE_PER_100=5,POINT_RATE=0.1}
money_total=money_total or 0
last_pay=last_pay or 0
last_bonus=last_bonus or 0
last_points=last_points or 0
last_payout_ready=last_payout_ready or false
sci_adj={"quantum","plasma","ionic","fusion","nano","cyber","holo","cryo","flux","void"}
sci_noun={"core","drive","matrix","relay","beacon","module","crystal","reactor","emitter","array"}

-- forward declarations (defined in station.lua)
if not station_init then function station_init() end end
if not update_station then function update_station() end end
if not draw_station then function draw_station() end end
function generate_mission()
	local adj=sci_adj[flr(rnd(#sci_adj))+1]
	local noun=sci_noun[flr(rnd(#sci_noun))+1]
	current_mission=adj.." "..noun
	mission_distance=500+(round_number*100)
	distance_remaining=mission_distance
end
local function get_points()
	if type(hud_get_points)=="function"then return hud_get_points()end
	if points~=nil then return points end
	if score~=nil then return score end
	return 0
end
local function reset_points()
	if type(hud_reset_points)=="function"then hud_reset_points()return end
	if points~=nil then points=0 end
	if score~=nil then score=0 end
end
function complete_mission()
	local pts=get_points()
	last_points=pts
	last_bonus=flr(pts*MONEY.POINT_RATE)
	last_pay=MONEY.MIN_BASE+flr(mission_distance/100)*MONEY.BASE_PER_100
	money_total+=last_pay+last_bonus
	last_payout_ready=true
	reset_points()
	round_number+=1
	generate_mission()
	moon_init()
	blackhole_init()
	comet_init()
	music(-1,0)
	music(8,0,MUSIC_MASK)
	level_fanfare_active=true
	level_fanfare_timer=FANFARE_LOCK
	ship_departing=true
	ship_depart_timer=0
	game_state="fanfare_depart"
end
function reset_game()
	music(-1,0)
	starfield_init()
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
	music(0,0,MUSIC_MASK)
end
function _init()
	starfield_init()
	ship_init()
	moon_init()
	hud_init()
	blackhole_init()
	comet_init()
	station_init()
	menu_init()
	music(0,0,MUSIC_MASK)
end
function _update()
	update_starfield()
	if level_fanfare_active then
		if level_fanfare_timer>0 then
			level_fanfare_timer-=1
		else
			level_fanfare_active=false
		end
	end

	if game_state=="fanfare_depart" then
		-- animate ship flying up
		if ship_departing then
			ship.y-=1.5
			ship_depart_timer+=1
			if ship.y+ship.h<0 then
				ship_departing=false
			end
		end
		if not ship_departing and not level_fanfare_active then
			ship_init() -- reset ship for next round
			game_state="station"
		end
		prev_game_state="fanfare_depart"
		return
	end
	local old_state=game_state
	if game_state=="game"and prev_game_state=="station"then
		music(-1,0)
		music(4,0,MUSIC_MASK)
	elseif(game_state=="menu"or game_state=="station")and prev_game_state!="menu"and prev_game_state!="station"and not level_fanfare_active then
		music(-1,0)
		music(0,0,MUSIC_MASK)
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
-- draw_station moved to station.lua
function hud_get_money()return money_total end
function _draw()
	cls(0)
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
			local frac=(mission_distance-max(0,distance_remaining))/max(1,mission_distance)
			frac=mid(0,frac,1)
			local w,h,x,y=60,3,flr((128-60)/2),122
			rectfill(x,y,x+w,y+h,0)
			rectfill(x+1,y+1,x+w-1,y+h-1,1)
			local filled=flr(frac*(w-2))
			if filled>0 then rectfill(x+1,y+1,x+1+filled,y+h-1,6)end
			local px=x+w-1
			circfill(px,y-1,1,8)
			pset(px,y+1,8)
		end
	elseif game_state=="gameover"then
		draw_hud()
		print("game over",40,54,7)
		print("z: menu",46,66,6)
	end
end
