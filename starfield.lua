-- parallax starfield

local stars = {}
local layers = {
	{ n=40, spd=0.25, col=1 }, -- far
	{ n=25, spd=0.50, col=5 }, -- mid
	{ n=12, spd=1.00, col=13 }  -- near (slightly darker)
}

function starfield_init()
	stars = {}
	for l in all(layers) do
		for i=1,l.n do
			add(stars, {
				x = flr(rnd(128)),
				y = rnd(128),
				spd = l.spd,
				col = l.col
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
