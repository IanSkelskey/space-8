local score = 0
local money = 0  -- placeholder for future money system
local fuel = 100  -- placeholder for fuel system
local max_fuel = 100

-- HUD area height (top of screen reserved for UI)
HUD_HEIGHT = 10  -- reduced for less intrusion

function hud_init()
	score = 0
	money = 0
	fuel = max_fuel
end

function hud_add_score(n)
	score += n or 0
end

function hud_add_money(n)
	money += n or 0
end

function hud_get_money()
	return money
end

-- fuel management functions (for future use)
function hud_use_fuel(n)
	fuel = max(0, fuel - (n or 0))
end

function hud_add_fuel(n)
	fuel = min(max_fuel, fuel + (n or 0))
end

function hud_get_fuel()
	return fuel, max_fuel
end

-- helper to draw a compact meter
local function draw_meter(x, y, w, h, value, max_value, col_full, col_mid, col_low)
	-- background (darker version)
	rectfill(x, y, x + w - 1, y + h - 1, 0)
	
	-- fill
	local fill_w = flr((value / max_value) * w)
	if fill_w > 0 then
		local ratio = value / max_value
		local col = col_low
		if ratio > 0.5 then
			col = col_full
		elseif ratio > 0.25 then
			col = col_mid
		end
		rectfill(x, y, x + fill_w - 1, y + h - 1, col)
	end
	
	-- subtle border using darker shade
	rect(x, y, x + w - 1, y + h - 1, 5)
end

function draw_hud()
	-- draw sleek background with just a thin line
	rectfill(0, 0, 127, HUD_HEIGHT-1, 0)  -- black base
	line(0, HUD_HEIGHT-1, 127, HUD_HEIGHT-1, 1)  -- thin dark blue divider
	
	-- LEFT: Score (compact)
	print(score, 2, 2, 7)
	
	-- LEFT-CENTER: Money (with improved coin icon)
	local money_x = 32
	-- draw better coin icon ($ symbol in circle)
	circfill(money_x, 4, 2, 10)  -- gold circle
	circ(money_x, 4, 2, 9)  -- darker edge
	-- tiny $ symbol
	pset(money_x, 2, 0)  -- top
	pset(money_x-1, 3, 0)  -- middle left
	pset(money_x, 4, 0)  -- center
	pset(money_x+1, 5, 0)  -- middle right
	pset(money_x, 6, 0)  -- bottom
	print(money, money_x + 5, 2, 10)
	
	-- RIGHT SIDE: Dual meter system (shield and fuel side by side)
	-- Shield meter (blue tones)
	if ship_get_shield_power then
		local power, max_power = ship_get_shield_power()
		-- improved shield icon (classic shield outline)
		local icon_x = 72
		-- top row (wider)
		pset(icon_x-1, 2, 12)
		pset(icon_x, 2, 12)
		pset(icon_x+1, 2, 12)
		-- middle rows (full width)
		pset(icon_x-1, 3, 12)
		pset(icon_x, 3, 13)  -- center highlight
		pset(icon_x+1, 3, 12)
		pset(icon_x-1, 4, 12)
		pset(icon_x, 4, 13)  -- center highlight
		pset(icon_x+1, 4, 12)
		-- bottom point
		pset(icon_x, 5, 12)
		
		-- compact meter
		draw_meter(icon_x + 4, 3, 20, 3, power, max_power, 12, 13, 8)
	end
	
	-- Fuel meter (green to red)
	-- improved fuel icon (flame/droplet shape - more recognizable as fuel)
	local fuel_icon_x = 100
	-- flame/fuel drop shape
	pset(fuel_icon_x, 2, 10)  -- top (yellow tip)
	pset(fuel_icon_x-1, 3, 9)  -- upper sides (orange)
	pset(fuel_icon_x, 3, 10)   -- center (yellow)
	pset(fuel_icon_x+1, 3, 9)  -- upper sides (orange)
	pset(fuel_icon_x-1, 4, 11) -- bottom sides (green base)
	pset(fuel_icon_x, 4, 11)   -- center (green base)
	pset(fuel_icon_x+1, 4, 11) -- bottom sides (green base)
	pset(fuel_icon_x, 5, 11)   -- bottom point (green)
	
	-- compact meter
	draw_meter(fuel_icon_x + 4, 3, 20, 3, fuel, max_fuel, 11, 10, 8)
end
