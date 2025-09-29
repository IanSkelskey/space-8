function draw_gameover()
	-- Pulsing game over text (centered)
	local c=time()%1<0.5 and 8 or 7
	print("\014game over",28,40,c)
	
	-- Calculate dynamic centering for stats
	local r,m,s="round "..vr,"cash $"..money_total,"score "..(ts or 0)
	print(r,64-#r*2,56,6)
	print(m,64-#m*2,66,10)
	print(s,64-#s*2,76,7)
	
	-- Single centered button prompt
	print("❎ main menu",40,92,6)
end

-- Simplified input handling (saves tokens)
function update_gameover()
	if btnp(5) then
		game_state="menu"
		snd_sfx(SFX_OK,UI_CH)
	end
end
