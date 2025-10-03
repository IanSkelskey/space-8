function draw_gameover()
	-- Pulsing game over text (centered)
	local c=time()%1<0.5 and 8 or 7
	print("\014game over",28,40,c)
	
	-- Calculate dynamic centering for stats
	local tls="00"..(ts or 0)
	local sdisp=tsh and tsh>0 and (tsh..sub(tls,#tls-2)) or ts or 0
	local r,m,s="round "..vr,"cash $"..money_total,"score "..sdisp
	print(r,64-#r*2,56,6)
	print(m,64-#m*2,66,10)
	print(s,64-#s*2,76,7)
	
	-- Single centered button prompt
	print("❎ main menu",40,92,6)
end
