local score,money,HUD_HEIGHT=0,0,10
ts=ts or 0
db=db or 0
gs=gs or game_state

function hud_init()score,money=0,0 end

function hud_add_score(n)score+=n or 0 ts+=n or 0 end
function hud_add_money(n)money+=n or 0 end

function hud_get_points()return score end
function hud_reset_points()score=0 db=0 end  -- reset progress bar when starting new mission

-- removed dm helper (inlined in draw_hud)

-- removed segmented bar helper (inlined below for tokens)

function draw_hud()
	print(score,2,2,7)
	-- show prior total during run after payout achieved
	local mt=money_total or 0
	local show_amount=((game_state=="game" or game_state=="fanfare_depart" or game_state=="dying") and last_payout_ready) and (mt-(last_pay or 0)-(last_bonus or 0)) or mt
	local t="$"..show_amount
	print(t,127-#t*4-2,2,10)
	spr(38,30,2)
	local h,m=ship_get_hull(),ship_get_max_hull()
	local bw=min(20,m*10)
	rectfill(37,3,36+bw,5,0)
	local sw=bw/m
	for i=1,h do local sx=37+(i-1)*sw rectfill(sx,3,sx+sw-2,5,11) end
	rect(37,3,36+bw,5,5)
	spr(10,58,2)
	-- inline shield bar (was dm)
	local sp=ship and ship.shield_power or 0
	rectfill(65,3,84,5,0)
	local fw=flr(sp/100*20)
	if fw>0 then
		local r,c=sp/100,8
		if r>0.5 then c=12 elseif r>0.25 then c=13 end
		rectfill(65,3,65+fw-1,5,c)
	end
	rect(65,3,84,5,5)
	-- track previous state; reset progress only on entering gameplay from outside fanfare
	if gs~=game_state then if game_state=="game" and (gs!="fanfare_depart" and gs!="fanfare_arrive") then db=0 end gs=game_state end
	-- mission progress bar (subtle design)
	if (game_state=="game" or game_state=="fanfare_depart" or game_state=="fanfare_arrive") and mission_distance and mission_distance>0 then
		-- calculate actual progress from distance_remaining
		local actual_progress = mission_distance - (distance_remaining or mission_distance)
		local t = min(1, actual_progress / mission_distance)
		-- force full during fanfare
		if level_fanfare_timer and level_fanfare_timer>0 then t=1 end
		-- smooth progress
		db=db<t and min(t,db+0.02) or (db>t and max(t,db-0.02) or db)

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
