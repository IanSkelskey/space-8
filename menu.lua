local sel = 1
local opts = {
	{ label="start", action=function()
		game_state = "game"
		ship_init()
		moon_init()
	end },
	{ label="controls", action=function()
		game_state = "controls"
		controls_init()
	end },
	{ label="exit", action=function()
		if extcmd then stop("Thanks for playing!") end
	end }
}

function menu_init()
	sel = 1
end

function update_menu()
	if btnp(2) then sel -= 1 end -- up
	if btnp(3) then sel += 1 end -- down
	if sel < 1 then sel = #opts end
	if sel > #opts then sel = 1 end
	if btnp(4) then
		local a = opts[sel].action
		if a then a() end
	end
end

function draw_menu()
	-- title
	print("space shooter", 32, 28, 7)
	-- options
	local y = 48
	for i=1,#opts do
		local c = i == sel and 7 or 6
		if i == sel then print(">", 28, y, c) end
		print(opts[i].label, 36, y, c)
		y += 10
	end
	-- helper
	print("z: select  x: back", 28, 120, 5)
end
