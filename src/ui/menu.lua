local sel=1
-- difficulty labels (full names; single string literal token)
dl=dl or split"easy,normal,veteran"
SFX_CURSOR=SFX_CURSOR or 44
SFX_ERR=SFX_ERR or 45
SFX_OK=SFX_OK or 63
UI_CH=UI_CH or 3
local opts={
	{label="start",action=function()
		round_number=sr[df] vr=1 -- internal difficulty round, visible round
		game_state="game"
		ship_init() asteroid_init() hud_init() comet_init() blackhole_init()
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
	-- left/right adjust difficulty while on start
	if sel==1 then
		if btnp(0) then df=df>1 and df-1 or 3 snd_sfx(SFX_CURSOR,UI_CH) end
		if btnp(1) then df=df<3 and df+1 or 1 snd_sfx(SFX_CURSOR,UI_CH) end
	end
	if btnp(4) then if sel>1 then snd_sfx(SFX_OK,UI_CH) end opts[sel].action() end
end

function draw_menu()
	
	-- Title centered with improved styling
	print("\014sPACE 8",36,24,7)
	
	print("v1.2.0",48,36,6)
	local y=52
	for i=1,#opts do
		local c=i==sel and 7 or 6
		if i==sel then print(">",36+time()%1\0.5,y,c) end
		spr(opts[i].icon,44,y)
		local lbl=opts[i].label
		if i==1 then lbl=lbl.."("..dl[df]..")" end
		print(lbl,54,y,c)
		y+=12
	end
	
	-- Centered footer
	print("🅾️ select  ❎ back",30,104,5)
	print("made with \fe♥\f7 by ian skelskey",12,116,5)
end
