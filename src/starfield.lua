local stars = {}
local distant_planets = {}
local layers = {
	{ n=40, spd=0.25, col=1 }, -- far
	{ n=25, spd=0.50, col=5 }, -- mid
	{ n=12, spd=1.00, col=13 }  -- near (slightly darker)
}

function starfield_init()
	stars = {}
	distant_planets = {}
	
	-- regular stars
	for li=1,#layers do
		local l = layers[li]
		for i=1,l.n do
			local star = {
				x = flr(rnd(128)),
				y = rnd(128),
				spd = l.spd,
				col = l.col,
				layer = li -- 1=far, 2=mid, 3=near
			}
			add(stars, star)
			
			-- 15% chance to be a twinkling star (only far/mid layers)
			if li <= 2 and rnd(1) < 0.15 then
				star.tw=rnd(1)
				star.twspd=0.008+rnd(0.012)
			end
		end
	end
	
	-- add 3-5 distant planets with more variety (very subtle background objects)
	for i=1,3+flr(rnd(3)) do
		local size_roll = rnd(1)
		local r
		if size_roll < 0.5 then
			r = 1  -- tiny planet (50% chance)
		elseif size_roll < 0.8 then
			r = 2  -- small planet (30% chance)
		else
			r = 3  -- medium planet (20% chance)
		end
		
		add(distant_planets, {
			x=10+rnd(108),
			y=rnd(128),
			r=r,
			sid=15+r, -- 16,17,18
			spd=0.08+rnd(0.04),
			col=1,
			has_ring=r==3 and rnd(1)<0.5,
			ring_angle=rnd(1)
		})
	end
end

function update_starfield()
	-- update regular stars (move + twinkle)
	local ssc=ss or 1
	for s in all(stars) do
		s.y += s.spd*ssc
		if s.y >= 128 then s.y -= 128 s.x = flr(rnd(128)) end
		if s.tw then s.tw=(s.tw+s.twspd)%1 end
	end
	
	-- update distant planets
	for p in all(distant_planets) do
		local ssc=ss or 1
		p.y += p.spd*ssc
		if p.y - p.r > 128 then
			p.y = -p.r - 5
			p.x = 10 + rnd(108)
			-- regenerate size
			local size_roll = rnd(1)
			if size_roll < 0.5 then
				p.r=1
			elseif size_roll < 0.8 then
				p.r=2
			else
				p.r=3
			end
			p.sid=15+p.r -- 16,17,18
			p.has_ring=p.r==3 and rnd(1)<0.5
			p.ring_angle=rnd(1)
		end
	end
end

function draw_starfield()
	-- draw distant planets first (deepest background)
	for p in all(distant_planets) do
		-- pre-baked planet sprite centered at (x,y)
		spr(p.sid, p.x-4, p.y-4)
	end
	
	-- draw regular stars with twinkle effect
	for s in all(stars) do
		local col=s.col
		if s.tw then
			local b=sin(s.tw)
			if b>0.5 then col=6 elseif b<-0.3 then col=1 end
		end
		pset(s.x, flr(s.y), col)
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