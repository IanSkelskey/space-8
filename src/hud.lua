local score=0
local money=0
local fuel=100
local max_fuel=100
HUD_HEIGHT=10

function hud_init()
	score = 0
	money = 0
	fuel = max_fuel
end

function hud_add_score(n) score += n or 0 end
function hud_add_money(n) money += n or 0 end

-- fuel management functions (for future use)
function hud_use_fuel(n) fuel=max(0,fuel-(n or 0)) end
function hud_add_fuel(n) fuel=min(max_fuel,fuel+(n or 0)) end

function hud_get_fuel() return fuel,max_fuel end

-- get current points (score)
function hud_get_points() return score end
function hud_reset_points() score=0 end

-- get current money
function hud_get_money() return money_total or money end

-- helper to draw a compact meter
local function draw_meter(x,y,w,h,value,max_value,col_full,col_mid,col_low)
	rectfill(x,y,x+w-1,y+h-1,0)
	local fill_w=flr((value/max_value)*w)
	if fill_w>0 then
		local r=value/max_value
		local c=col_low
		if r>0.5 then c=col_full elseif r>0.25 then c=col_mid end
		rectfill(x,y,x+fill_w-1,y+h-1,c)
	end
	rect(x,y,x+w-1,y+h-1,5)
end

function draw_hud()
	rectfill(0,0,127,HUD_HEIGHT-1,0)
	line(0,HUD_HEIGHT-1,127,HUD_HEIGHT-1,1)
	print(score,2,2,7)
	
	local money_x=32
	-- Removed coin pixel shading
	local cash=money if type(hud_get_money)=="function" then cash=hud_get_money() end
	print(cash,money_x+5,2,10)
	
	if ship_get_shield_power then
		local power,max_power=ship_get_shield_power()
		local icon_x=72
		spr(10,icon_x,2)
		draw_meter(icon_x+7,3,20,3,power,max_power,12,13,8)
	end
	
	local fuel_icon_x=100
	spr(9,fuel_icon_x,2)
	draw_meter(fuel_icon_x+7,3,20,3,fuel,max_fuel,10,9,8)
end
