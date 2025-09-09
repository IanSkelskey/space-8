function controls_init()
	-- no-op
end

function update_controls()
	-- back to menu on z/x
	if btnp(4) or btnp(5) then
		game_state = "menu"
		menu_init()
	end
end

function draw_controls()
	print("controls", 48, 20, 7)
	local y = 40
	print("arrow keys: move", 24, y, 6) y += 10
	print("z: fire", 24, y, 6) y += 10
	print("x: shield (hold)", 24, y, 6) y += 10
	print("x: back", 24, y + 10, 6) y += 10
end
