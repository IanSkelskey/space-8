local comets,parts = {},{}
local SIDS={48,49,50,51,52} -- red, pink, yellow, green, blue
local spawn_t = 0
local WARNING_TIME = 20

local SWAPS = {
	{8,9},  -- red
	{2,14}, -- pink
	{10,9}, -- yellow
	{3,11}, -- green
	{1,12}  -- blue
}

-- removed unused trail sampler to save tokens

function comet_init()
	comets = {}
	parts = {}
	spawn_t = 0
end

local function spawn_comet()
	local left = rnd(1) < 0.5
	local x = left and -8 or 128
	local hud_top = HUD_HEIGHT or 0
	local y = hud_top + flr(rnd(128-8-hud_top))

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

	local i=flr(rnd(#SWAPS))
	local pair=SWAPS[i+1]
	local c8,c9=pair[1],pair[2]

	add(comets, {
		x=x, y=y, w=8, h=8,
		dx=dx, dy=dy,
		c8=c8, c9=c9, sid=SIDS[i+1],
		warning_t = WARNING_TIME,
		left = left
	})
end

function update_comet()
	if not round_number or round_number<3 then return end
	spawn_t -= 1/30
	local mx=cm or 3
	local mi=cmin or 1.0
	local rg=crng or 1.2
	-- keep very sparse in early comet rounds
	if round_number<5 then mx=min(mx,1) end
	if spawn_t <= 0 and #comets < mx then
		spawn_comet()
		local mul=round_number<5 and 1.5 or 1
		spawn_t = (mi + rnd(rg))*mul
	end

	-- update comets
	for c in all(comets) do
		if c.warning_t > 0 then
			c.warning_t -= 1
			goto continue
		end

		-- move (scaled by level comet speed)
		local s=cs or 1
		c.x += c.dx*s
		c.y += c.dy*s

		-- spawn 1-2 trail particles
		local ux, uy = 0, 0
		local spd = sqrt(c.dx*c.dx + c.dy*c.dy)
		if spd > 0 then ux, uy = c.dx/spd, c.dy/spd end
		for i=1, (rnd(1) < 0.4 and 2 or 1) do
			local px = c.x + 4 - ux*2 + (rnd(1)-0.5)
			local py = c.y + 4 - uy*2 + (rnd(1)-0.5)
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

		if ship and not c.warning and aabb(c.x,c.y,c.w,c.h, ship.x,ship.y,ship.w,ship.h) then
			if ship_kill then ship_kill() end
		end

		if c.x<-12 or c.x>140 or c.y<-12 or c.y>140 then del(comets,c) end
		::continue::
	end

	-- update trail particles
	for p in all(parts) do
		p.x += p.dx
		p.y += p.dy
		p.life -= 1
		if p.life<=0 or p.x<-4 or p.x>132 or p.y<-4 or p.y>132 then del(parts,p) end
	end
end

function draw_comet()
	for c in all(comets) do
		if c.warning_t > 0 then
			local cx = c.left and 4 or 123
			local cy = c.y + 4
			local hud_top = HUD_HEIGHT or 0
			if cy < hud_top + 4 then cy = hud_top + 4 end
			local radius = 3
			local base_angle = (WARNING_TIME - c.warning_t) * 0.15
			for i=0,3 do
				local ang = base_angle + i * 0.25
				local px = cx + cos(ang) * radius
				local py = cy + sin(ang) * radius
				local col = (i % 2 == 0) and c.c8 or c.c9
				pset(flr(px), flr(py), col)
			end
		end
	end

	for p in all(parts) do
		pset(flr(p.x), flr(p.y), p.col)
	end
	
	for c in all(comets) do
		if c.warning_t <= 0 then
			local fx = c.dx < 0
			local fy = c.dy > 0
			spr(c.sid, c.x, c.y, 1, 1, fx, fy)
		end
	end
end