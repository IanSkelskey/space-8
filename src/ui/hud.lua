local score,money,HUD_HEIGHT=0,0,10
ts=ts or 0
db=db or 0
gs=gs or game_state

function hud_init()score,money=0,0 end

function hud_add_score(n)score+=n or 0 ts+=n or 0 end
function hud_add_money(n)money+=n or 0 end

function hud_get_points()return score end
function hud_reset_points()score=0 db=0 end  -- reset progress bar when starting new mission

local function dm(x,y,w,h,v,m,cf,cm,cl)
	rectfill(x,y,x+w-1,y+h-1,0)
	local fw=flr(v/m*w)
	if fw>0 then
		local r,c=v/m,cl
		if r>0.5 then c=cf elseif r>0.25 then c=cm end
		rectfill(x,y,x+fw-1,y+h-1,c)
	end
	rect(x,y,x+w-1,y+h-1,5)
end

local function draw_segmented_bar(x,y,w,h,segments,max_segments,col)
	rectfill(x,y,x+w-1,y+h-1,0)
	local seg_w=w/max_segments
	for i=1,segments do
		local sx=(i-1)*seg_w
		rectfill(x+sx,y,x+sx+seg_w-2,y+h-1,col)
	end
	rect(x,y,x+w-1,y+h-1,5)
end

function draw_hud()
	print(score,2,2,7)
	-- Show old total during game/fanfare, new total only at station
	local show_amount = money_total or money
	if (game_state=="game" or game_state=="fanfare_depart" or game_state=="dying") and last_payout_ready then
		-- During gameplay after completing a mission, show the previous total
		show_amount = (money_total or 0) - (last_pay or 0) - (last_bonus or 0)
	end
	local t="$"..show_amount
	print(t,127-#t*4-2,2,10)
	spr(38,30,2)
	local h,m=ship_get_hull and ship_get_hull()or 2,ship_get_max_hull and ship_get_max_hull()or 2
	draw_segmented_bar(37,3,min(20,m*10),3,h,m,11)
	spr(10,58,2)
	dm(65,3,20,3,ship and ship.shield_power or 0,100,12,13,8)
	-- reset smoothing only when entering game from non-game/fanfare state
	if gs~=game_state then 
		if game_state=="game" and gs!="fanfare_depart" and gs!="fanfare_arrive" then 
			db=0 
		end 
		gs=game_state 
	end
	-- mission progress bar (subtle design)
	if (game_state=="game" or game_state=="fanfare_depart" or game_state=="fanfare_arrive") and mission_distance and mission_distance>0 then
		-- calculate actual progress from distance_remaining
		local actual_progress = mission_distance - (distance_remaining or mission_distance)
		local t = min(1, actual_progress / mission_distance)
		-- force full during fanfare
		if level_fanfare_timer and level_fanfare_timer>0 then t=1 end
		-- smooth the display value
		if db<t then db=min(t,db+0.02) elseif db>t then db=max(t,db-0.02) end

		-- smaller, subtler progress bar
		local bx,by,bw,bh=20,122,88,2
		rectfill(bx,by,bx+bw-1,by+bh-1,1) -- dark blue background
		local w=db*bw
		if w>0 then 
			rectfill(bx,by,bx+w-1,by+bh-1,13) -- dark gray fill
			if db>0.95 then
				-- pulse near completion
				local c=flr(time()*4)%2==0 and 6 or 13
				rectfill(bx+w-2,by,bx+w-1,by+bh-1,c)
			end
		end
		-- icon stays at same position
		spr(39,111,119)
	end
end
