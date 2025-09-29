local sel=1
SFX_CURSOR=SFX_CURSOR or 44
SFX_ERR=SFX_ERR or 45
SFX_OK=SFX_OK or 63
UI_CH=UI_CH or 3
local opts={
	{label="start",action=function()
		game_state="game"
		ship_init() asteroid_init() hud_init() comet_init()
		snd_sfx(SFX_OK,UI_CH)
	end,icon=6},
	{label="help",action=function()
		-- don't restart music; just switch to controls
		game_state="controls" controls_init()
	end,icon=41},
	{label="exit",action=function()
		if extcmd then stop("thanks for playing!") end
	end,icon=42}
}

function menu_init() sel=1 end

function update_menu()
	if btnp(2) then sel-=1 snd_sfx(SFX_CURSOR,UI_CH) end
	if btnp(3) then sel+=1 snd_sfx(SFX_CURSOR,UI_CH) end
	if sel<1 then sel=#opts end
	if sel>#opts then sel=1 end
	if btnp(4) then if sel>1 then snd_sfx(SFX_OK,UI_CH) end local a=opts[sel].action if a then a() end end
end

function draw_menu()
	
	-- Title centered with improved styling
	print("\014sPACE 8",36,24,7)
	
	print("v1.2.0",48,36,6)
	local y=52
	for i=1,#opts do 
		local c=i==sel and 7 or 6 
		if i==sel then 
			-- Simplified pulsing (saves 2 tokens: removed 'and 0 or 1')
			print(">",36+time()%1\0.5,y,c) 
		end 
		-- Draw sprite icon
		spr(opts[i].icon,44,y)
		print(opts[i].label,54,y,c) 
		y+=12 
	end
	
	-- Centered footer
	print("🅾️ select  ❎ back",30,104,5)
	print("made with \fe♥\f7 by ian skelskey",12,116,5)
end
