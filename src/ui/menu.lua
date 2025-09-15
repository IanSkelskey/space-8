local sel=1
SFX_CURSOR=SFX_CURSOR or 44
SFX_ERR=SFX_ERR or 45
SFX_OK=SFX_OK or 63
UI_CH=UI_CH or 3
local opts={
	{label="start",action=function()
		music(-1)
		game_state="game"
		ship_init() moon_init() hud_init() comet_init()
		sfx(SFX_OK,UI_CH)
	end},
	{label="help",action=function()
		-- don't restart music; just switch to controls
		game_state="controls" controls_init()
	end},
	{label="exit",action=function()
		if extcmd then stop("Thanks for playing!") end
	end}
}

function menu_init() sel=1 end

function update_menu()
	if btnp(2) then sel-=1 sfx(SFX_CURSOR,UI_CH) end
	if btnp(3) then sel+=1 sfx(SFX_CURSOR,UI_CH) end
	if sel<1 then sel=#opts end
	if sel>#opts then sel=1 end
	if btnp(4) then
		if sel==1 then
			local a=opts[sel].action if a then a() end
		else
			sfx(SFX_OK,UI_CH)
			local a=opts[sel].action if a then a() end
		end
	end
end

function draw_menu()
	print("\014sPACE 8",32,28,7)
	print("v1.0.0",32,36,6)
	local y=48
	for i=1,#opts do local c=i==sel and 7 or 6 if i==sel then print(">",28,y,c) end print(opts[i].label,36,y,c) y+=10 end
	print("🅾️ select  ❎ back",26,108,5)
	print("made with \fe♥\f7 by ian skelskey",8,120,5)
end
