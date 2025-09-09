-- comets

local comets = {}
local parts = {}
local spawn_t = 0
local WARNING_TIME = 20  -- frames to show warning

local SWAPS = {
	{1,12}, -- 8->1, 9->12
	{3,11}, -- 8->3, 9->11
	{9,10}  -- 8->9, 9->10
}

-- aabb
local function aabb(ax,ay,aw,ah,bx,by,bw,bh)
	return ax < bx+bw and bx < ax+aw and ay < by+bh and by < ay+ah
end

-- collect unique colors used by sprite 6 (exclude 0)
local trail_cols = {}
local function collect_colors_from_sprite6()
	trail_cols = {}
	local seen = {}
	local sx = (6%16)*8
	local sy = flr(6/16)*8
	for y=0,7 do
		for x=0,7 do
			local c = sget(sx+x, sy+y)
			if c ~= 0 and not seen[c] then
				seen[c] = true
				add(trail_cols, c)
			end
		end
	end
	-- fallback palette if sprite is single-color for some reason
	if #trail_cols == 0 then
		trail_cols = {6,9,10,7}
	end
end

function comet_init()
	comets = {}
	parts = {}
	spawn_t = 0
	collect_colors_from_sprite6()
end

local function spawn_comet()
	-- side choose
	local left = rnd(1) < 0.5
	local x = left and -8 or 128
	local y = flr(rnd(128-8))

	-- restrict to diagonals:
	-- left side -> ±45° (0.125 or 0.875 turns)
	-- right side -> ±135° (0.375 or 0.625 turns)
	local ang
	if left then
		ang = (rnd(1) < 0.5) and 0.125 or 0.875
	else
		ang = (rnd(1) < 0.5) and 0.375 or 0.625
	end

	-- speed and velocity
	local spd = 1.2 + rnd(0.9)
	local dx = cos(ang) * spd
	local dy = sin(ang) * spd

	-- pick a palette swap for this comet (only colors 8 and 9)
	local pair = SWAPS[1+flr(rnd(#SWAPS))]
	local c8, c9 = pair[1], pair[2]

	add(comets, {
		x=x, y=y, w=8, h=8,
		dx=dx, dy=dy,
		c8=c8, c9=c9,
		warning_t = WARNING_TIME,  -- countdown timer
		left = left  -- track spawn side for indicator
	})
end

local function spawn_trail(c)
	-- trail particle with stored color
	add(parts, c)
end

function update_comet()
	-- spawn cadence
	spawn_t -= 1/30
	if spawn_t <= 0 and #comets < 3 then
		spawn_comet()
		spawn_t = 1.0 + rnd(1.2)
	end

	-- update comets
	for c in all(comets) do
		-- handle warning phase
		if c.warning_t > 0 then
			c.warning_t -= 1
			-- don't move or collide during warning
			goto continue
		end

		-- move
		c.x += c.dx
		c.y += c.dy

		-- spawn 1-2 trail particles behind comet along negative velocity
		local ux, uy = 0, 0
		local spd = sqrt(c.dx*c.dx + c.dy*c.dy)
		if spd > 0 then ux, uy = c.dx/spd, c.dy/spd end
		for i=1, (rnd(1) < 0.4 and 2 or 1) do
			local px = c.x + 4 - ux*2 + (rnd(1)-0.5)
			local py = c.y + 4 - uy*2 + (rnd(1)-0.5)
			-- choose base comet sprite color (8 or 9), then map to this comet's swap
			local base8 = rnd(1) < 0.5
			local col = base8 and c.c8 or c.c9
			add(parts, {
				x=px, y=py,
				dx = -ux*(0.2+rnd(0.2)) + (rnd(0.1)-0.05),
				dy = -uy*(0.2+rnd(0.2)) + (rnd(0.1)-0.05),
				life = 18 + flr(rnd(10)),
				col = col
			})
		end

		-- collide with player using only the "nose" quadrant (4x4)
		-- default nose is upper-right, adjust based on flips
		local fx = c.dx < 0  -- flip horizontally if moving left
		local fy = c.dy > 0  -- flip vertically if moving down
		
		-- calculate nose position based on flips
		-- no flip: upper-right (x+4, y+0)
		-- fx only: upper-left (x+0, y+0)
		-- fy only: lower-right (x+4, y+4)
		-- both: lower-left (x+0, y+4)
		local nose_x = c.x + (fx and 0 or 4)
		local nose_y = c.y + (fy and 4 or 0)
		
		if ship and aabb(nose_x, nose_y, 4, 4, ship.x, ship.y, ship.w, ship.h) then
			if game_state == "game" and ship_kill then ship_kill() end
			-- keep comet; death flow handles reset
		end

		-- cull offscreen (with some padding)
		if c.x < -12 or c.x > 140 or c.y < -12 or c.y > 140 then
			del(comets, c)
		end
		::continue::
	end

	-- update trail particles
	for p in all(parts) do
		p.x += p.dx
		p.y += p.dy
		p.life -= 1
		if p.life <= 0 or p.x < -4 or p.x > 132 or p.y < -4 or p.y > 132 then
			del(parts, p)
		end
	end
end

function draw_comet()
	-- draw warning indicators for incoming comets
	for c in all(comets) do
		if c.warning_t > 0 then
			-- rotating circle indicator
			local cx = c.left and 4 or 123
			local cy = c.y + 4
			local radius = 3
			-- rotate based on warning timer (smoother spin)
			local base_angle = (WARNING_TIME - c.warning_t) * 0.15
			-- draw 4 pixels in a circle pattern
			for i=0,3 do
				local ang = base_angle + i * 0.25
				local px = cx + cos(ang) * radius
				local py = cy + sin(ang) * radius
				-- alternate between the two comet colors
				local col = (i % 2 == 0) and c.c8 or c.c9
				pset(flr(px), flr(py), col)
			end
		end
	end

	-- draw trail behind
	for p in all(parts) do
		pset(flr(p.x), flr(p.y), p.col)
	end
	
	-- draw comets (skip if still in warning phase)
	for c in all(comets) do
		if c.warning_t <= 0 then
			-- reset palettes to avoid carry-over
			pal()
			-- apply draw-palette remap: 8->c.c8, 9->c.c9
			pal(8, c.c8)
			pal(9, c.c9)

			local fx = c.dx < 0  -- flip horizontally if moving left
			local fy = c.dy > 0  -- flip vertically if moving down
			spr(6, c.x, c.y, 1, 1, fx, fy)

			-- reset for next draw
			pal()
		end
	end
end
