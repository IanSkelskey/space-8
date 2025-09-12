local layers = {
	{ mx=0,  my=0, spd=0.25 },
	{ mx=15, my=0, spd=0.50 },
	{ mx=30, my=0, spd=1.00 },
	{ mx=45, my=0, spd=0.08 }
}

local scroll_y = {}

function starfield_init()
	for i=1,#layers do
		scroll_y[i] = 0
	end
end

function update_starfield()
	local ssc = ss or 1

	for i=1,#layers do
		scroll_y[i] += layers[i].spd * ssc
		if scroll_y[i] >= 120 then
			scroll_y[i] -= 120
		end
	end
end

function draw_starfield()
	local l = layers[4]
	map(l.mx, l.my, 0, scroll_y[4], 15, 15, 0, -120)
	map(l.mx, l.my, 0, scroll_y[4]-120, 15, 15)
	
	for i=1,3 do
		l = layers[i]
		map(l.mx, l.my, 0, scroll_y[i], 15, 15, 0, -120)
		map(l.mx, l.my, 0, scroll_y[i]-120, 15, 15)
	end
end