local layers = {
	{ mx=0,  my=0, spd=0.25 }, -- far stars (map 0,0)
	{ mx=15, my=0, spd=0.50 }, -- mid stars (map 15,0)
	{ mx=30, my=0, spd=1.00 }, -- near stars (map 30,0)
	{ mx=45, my=0, spd=0.08 }  -- distant planets (map 45,0)
}

local scroll_y = {}

function starfield_init()
	-- Initialize scroll positions for each layer
	for i=1,#layers do
		scroll_y[i] = 0
	end
end

function update_starfield()
	local ssc = ss or 1
	
	-- Update scroll positions for each layer
	for i=1,#layers do
		scroll_y[i] += layers[i].spd * ssc
		-- Wrap around at 120 pixels (15 tiles * 8 pixels/tile)
		if scroll_y[i] >= 120 then
			scroll_y[i] -= 120
		end
	end
end

function draw_starfield()
	-- Draw each parallax layer from back to front
	-- Distant planets first (deepest)
	local l = layers[4]
	map(l.mx, l.my, 0, scroll_y[4], 15, 15, 0, -120)
	map(l.mx, l.my, 0, scroll_y[4]-120, 15, 15)
	
	-- Then far, mid, near stars
	for i=1,3 do
		l = layers[i]
		-- Draw twice to cover vertical wrapping
		map(l.mx, l.my, 0, scroll_y[i], 15, 15, 0, -120)
		map(l.mx, l.my, 0, scroll_y[i]-120, 15, 15)
	end
end

-- Simplified pull function - just affects scroll speed temporarily
function starfield_pull(cx, cy, r, mid_factor, near_factor)
	-- This could temporarily modify scroll speeds if needed
	-- For now, keeping it minimal since map-based parallax
	-- doesn't support individual star movement
end