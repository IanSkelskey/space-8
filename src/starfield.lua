-- parallax starfield with enhanced visuals
local stars = {}
local twinkle_stars = {}  -- stars that pulse
local distant_planets = {}  -- subtle background planets
local shooting_stars = {}  -- occasional meteors
local layers = {
	{ n=40, spd=0.25, col=1 }, -- far
	{ n=25, spd=0.50, col=5 }, -- mid
	{ n=12, spd=1.00, col=13 }  -- near (slightly darker)
}

function starfield_init()
	stars = {}
	twinkle_stars = {}
	distant_planets = {}
	shooting_stars = {}
	
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
				add(twinkle_stars, {
					star = star,
					phase = rnd(1),  -- random starting phase
					speed = 0.008 + rnd(0.012)  -- much slower twinkle (was 0.02-0.05)
				})
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
			x = 10 + rnd(108),  -- avoid edges
			y = rnd(128),
			r = r,
			spd = 0.08 + rnd(0.04),  -- very slow with slight variation (0.08-0.12)
			col = 1,  -- all dark blue for distant feel
			has_ring = r == 3 and rnd(1) < 0.5,  -- 50% chance of ring for medium planets only
			ring_angle = rnd(1)  -- random angle for ring orientation (0-1 = 0-360 degrees)
		})
	end
end

function update_starfield()
	-- update regular stars
	for s in all(stars) do
		s.y += s.spd
		if s.y >= 128 then
			s.y -= 128
			s.x = flr(rnd(128))
		end
	end
	
	-- update twinkle phases
	for t in all(twinkle_stars) do
		t.phase = (t.phase + t.speed) % 1
	end
	
	-- update distant planets
	for p in all(distant_planets) do
		p.y += p.spd
		if p.y - p.r > 128 then
			p.y = -p.r - 5
			p.x = 10 + rnd(108)
			-- regenerate size
			local size_roll = rnd(1)
			if size_roll < 0.5 then
				p.r = 1
			elseif size_roll < 0.8 then
				p.r = 2
			else
				p.r = 3
			end
			p.has_ring = p.r == 3 and rnd(1) < 0.5
			p.ring_angle = rnd(1)  -- new random angle for regenerated planet
		end
	end
	
	-- spawn occasional shooting star (very rare)
	if rnd(1) < 0.003 then  -- ~0.3% chance per frame
		add(shooting_stars, {
			x = rnd(128),
			y = rnd(60),  -- upper half of screen
			dx = -0.5 - rnd(1),  -- diagonal movement
			dy = 0.5 + rnd(1),
			life = 15 + flr(rnd(10)),
			max_life = 25
		})
	end
	
	-- update shooting stars
	for s in all(shooting_stars) do
		s.x += s.dx
		s.y += s.dy
		s.life -= 1
		if s.life <= 0 or s.x < -10 or s.y > 138 then
			del(shooting_stars, s)
		end
	end
end

function draw_starfield()
	-- draw distant planets first (deepest background)
	for p in all(distant_planets) do
		-- draw planet circle
		circfill(p.x, p.y, p.r, p.col)
		
		-- add subtle shading for larger planets
		if p.r >= 2 then
			-- tiny highlight to suggest 3D form
			pset(p.x - flr(p.r/2), p.y - flr(p.r/2), 5)  -- dark gray highlight
		end
		
		-- draw ring if planet has one (only for r=3 now)
		if p.has_ring then
			-- draw a thin elliptical ring at an angle
			local ring_radius = p.r + 2
			local ellipse_height = 0.3  -- how flat the ellipse is
			
			-- use the planet's ring_angle for rotation
			local rot = p.ring_angle or 0  -- fallback to 0 if not set
			
			-- draw the ring using an ellipse equation with rotation
			-- sample points around the ellipse
			for i=0,31 do  -- 32 points around the ring
				local angle = i/32  -- 0 to 1 (full circle)
				
				-- create ellipse points before rotation
				local ex = cos(angle) * ring_radius
				local ey = sin(angle) * ring_radius * ellipse_height
				
				-- rotate the ellipse points by ring_angle
				local dx = ex * cos(rot) - ey * sin(rot)
				local dy = ex * sin(rot) + ey * cos(rot)
				
				local rx = p.x + dx
				local ry = p.y + dy
				
				-- determine if this part is behind the planet (based on rotated y)
				local behind = dy < 0
				
				-- check if point is visible (not obscured by planet body)
				-- use distance from center to determine occlusion
				local dist_from_center = sqrt(dx*dx + dy*dy)
				local visible = dist_from_center > p.r or not behind
				
				if visible and rx >= 0 and rx < 128 and ry >= 0 and ry < 128 then
					-- use darker colors: dark blue (1) for back, dark gray (5) for front
					local col = behind and 1 or 5  -- both darker colors now
					pset(flr(rx), flr(ry), col)
				end
			end
		end
	end
	
	-- draw regular stars with twinkle effect
	for s in all(stars) do
		local col = s.col
		-- check if this star twinkles
		for t in all(twinkle_stars) do
			if t.star == s then
				-- pulse brightness using sine wave
				local brightness = sin(t.phase)
				if brightness > 0.5 then
					col = 6  -- light gray instead of white
				elseif brightness < -0.3 then
					col = 1  -- dim when in trough
				end
				break
			end
		end
		pset(s.x, flr(s.y), col)
	end
	
	-- draw shooting stars (on top)
	for s in all(shooting_stars) do
		-- main body
		local brightness = s.life / s.max_life
		local col = brightness > 0.7 and 7 or (brightness > 0.4 and 6 or 5)
		pset(flr(s.x), flr(s.y), col)
		-- fading trail
		if s.life > 5 then
			pset(flr(s.x - s.dx), flr(s.y - s.dy), 5)
			if s.life > 10 then
				pset(flr(s.x - s.dx*2), flr(s.y - s.dy*2), 1)
			end
		end
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