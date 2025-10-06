function draw_gameover()
	-- Pulsing game over text (centered)
	local c=time()%1<0.5 and 8 or 7
	print("\014game over",28,40,c)
	
	-- Calculate dynamic centering for stats
	local tls="00"..(ts or 0)
	local sdisp=tsh and tsh>0 and (tsh..sub(tls,#tls-2)) or ts or 0
	-- lifetime cash only on cash line (ignore final run cash)
	local ll="00"..(money_life_lo or 0)
	local ldisp=(money_life_hi and money_life_hi>0) and (money_life_hi..sub(ll,#ll-2)) or (money_life_lo or 0)
	local r,m,s="round "..vr,"cash $"..ldisp,"score "..sdisp
	print(r,64-#r*2,56,6)
	print(m,64-#m*2,66,10)
	print(s,64-#s*2,76,7)
	-- Single centered button prompt (move back up since extra line removed)
	print("❎ main menu",40,86,6)
end
