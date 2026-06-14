-- Check if this run qualifies for highscore (without triggering entry yet)
local function check_highscore_qualified()
 local lo,hi=persist_fetch_last_run()
 if (lo or 0)==0 and (hi or 0)==0 then return false end
 local di=df or 1
 local t=hs_sets[di]
 return #t<4 or hs_gt(hi,lo,t[#t].hi,t[#t].lo)
end

function draw_gameover()
	-- animated game-over logo: block-letter tiles flashing red/purple, with a darker drop layer for depth
	local fl=time()%0.8<0.4
	draw_logo("game over",30,fl and 2 or 8,fl and 1 or 2,fl and 2 or 8,fl and 1 or 2)
	-- (taunt flavor now shown in the gameplay cart over the death jingle, right after death)

	-- Stats display
	local tls="00"..(ts or 0)
	local sdisp=tsh and tsh>0 and (tsh..sub(tls,#tls-2)) or ts or 0
	local ll="00"..(money_life_lo or 0)
	local ldisp=(money_life_hi and money_life_hi>0) and (money_life_hi..sub(ll,#ll-2)) or (money_life_lo or 0)
	local r,m,s="round "..vr,"cash $"..ldisp,"score "..sdisp
	print(r,64-#r*2,50,6)
	mprint(m,64-#m*2-1,60,10)
	print(s,64-#s*2,70,7)
	
	-- Check for highscore qualification
	local qualified = check_highscore_qualified()
	if qualified then
		-- Flashing notification
		if time()%0.4<0.2 then
			rectfill(20,84,107,94,1)
		end
		print("new high score!",32,86,time()%0.3<0.15 and 11 or 10)
		local l="🅾️/❎ enter name"
		print(l,64-#l*2,102,5)
	else
		local l="🅾️/❎ main menu"
		print(l,64-#l*2,90,5)
	end
end
