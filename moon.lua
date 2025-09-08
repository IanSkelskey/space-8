-- moon obstacle

local moons = {}
local spawn_t = 0.0

-- simple aabb overlap
local function aabb(ax,ay,aw,ah,bx,by,bw,bh)
	return ax < bx+bw and bx < ax+aw and ay < by+bh and by < ay+ah
end

-- bullets helper (from ship.lua)
local function player_bullets()
	if ship_get_bullets then return ship_get_bullets() end
	return nil
end

local function hit_by_player_bullet(x,y,w,h)
	local pb = player_bullets()
	if not pb then return false end
	for b in all(pb) do
		if aabb(x,y,w,h, b.x,b.y,2,2) then
			del(pb,b)
			return true
		end
	end
	return false
end

function moon_init()
	moons = {}
	spawn_t = 0
end

local function spawn_moon()
	-- scroll speed close to near star layer
	local spd = 0.9
	add(moons, {
		x = flr(rnd(128-8)),
		y = -10,
		w = 8, h = 8,
		spd = spd,
		hp = 1
	})
end

function update_moon()
	-- spawn cadence (~ every 1.5-3s)
	spawn_t -= 1/30
	if spawn_t <= 0 and #moons < 3 then
		spawn_moon()
		spawn_t = 1.5 + rnd(1.5)
	end

	-- update + collisions
	for m in all(moons) do
		m.y += m.spd

		-- bullet hit destroys the moon
		if hit_by_player_bullet(m.x,m.y,m.w,m.h) then
			m.hp -= 1
			if m.hp <= 0 then
				if hud_add_score then hud_add_score(100) end
				sfx(1)
				del(moons, m)
				goto continue
			end
		end

		-- player collision -> reset game
		if ship and aabb(m.x,m.y,m.w,m.h, ship.x,ship.y,ship.w,ship.h) then
			if reset_game then reset_game()
			else
				-- fallback reset
				starfield_init()
				ship_init()
				moon_init()
				game_state = "menu"
				if menu_init then menu_init() end
			end
			return
		end

		-- cull
		if m.y > 136 then del(moons, m) end
		::continue::
	end
end

function draw_moon()
	for m in all(moons) do
		spr(2, m.x, m.y)
	end
end
