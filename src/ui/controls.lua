function controls_init() end

-- reuse same indices (define if not already global)
SFX_CURSOR=SFX_CURSOR or 44
SFX_ERR=SFX_ERR or 45
SFX_OK=SFX_OK or 46
UI_CH=UI_CH or 3

function update_controls()
	if btnp(4) or btnp(5) then sfx(SFX_OK,UI_CH) game_state="menu" menu_init() end
end

function draw_controls()
	print("controls",48,20,7)
	local y=40
	print("arrows: move",24,y,6) y+=10
	print("z: fire",24,y,6) y+=10
	print("x: shield(hold)",24,y,6) y+=10
	print("x: back",24,y+10,6) y+=10
end
