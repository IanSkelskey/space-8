-- parallax starfield
local stars = {}
local layers = {
	{ n=40, spd=0.25, col=1 }, -- far
	{ n=25, spd=0.50, col=5 }, -- mid
	{ n=12, spd=1.00, col=13 }  -- near (slightly darker)
}

function starfield_init()
	stars = {}
	for li=1,#layers do
		local l = layers[li]
		for i=1,l.n do
			add(stars, {
				x = flr(rnd(128)),
				y = rnd(128),
				spd = l.spd,
				col = l.col,
				layer = li -- 1=far, 2=mid, 3=near
			})
		end
	end
end

function update_starfield()
	for s in all(stars) do
		s.y += s.spd
		if s.y >= 128 then
			s.y -= 128
			s.x = flr(rnd(128))
		end
	end
end

function draw_starfield()
	for s in all(stars) do
		pset(s.x, flr(s.y), s.col)
	end
end

-- allow external influences to tug stars (only mid/near layers)
-- cx,cy: center; r: radius; mid_factor/near_factor: 0..1 displacement scale
function starfield_pull(cx, cy, r, mid_factor, near_factor)
	if not stars then return end
	local r2 = r*r
	for s in all(stars) do
		-- pick factor by layer (0 for far)
		local f = (s.layer == 2 and mid_factor) or (s.layer == 3 and near_factor) or 0
		if f > 0 then
			local dx = cx - s.x
			local dy = cy - s.y
			local d2 = dx*dx + dy*dy
			if d2 < r2 and d2 > 0.5 then
				local invd = 1/sqrt(d2)
				-- pull strength falls off toward radius
				local falloff = (1 - d2/r2)
				s.x += dx*invd * f * falloff
				s.y += dy*invd * f * falloff
				-- keep on screen horizontally
				if s.x < 0 then s.x = 0 end
				if s.x > 127 then s.x = 127 end
			end
		end
	end
end
