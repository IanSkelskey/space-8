function controls_init() end
SFX_OK=SFX_OK or 63 UI_CH=UI_CH or 3

function update_controls()
 if btnp(4) or btnp(5) then sfx(SFX_OK,UI_CH) game_state="menu" menu_init() end
end

function draw_controls()
 rectfill(0,0,127,15,1)
 print("help",4,4,7)
	rect(1,17,126,118,1)
	print("\fcloop\f6:\n  deliver tech>cash>upgrade\n  launch>survive>return\n\n\fccontrols\f6:\n  move pad  shoot 🅾️\n  shield ❎ hold\n\n\fcupgrades\f6:\n  fire+ faster\n  shield+ stronger\n  spread +bolts",6,20,6)
 print("❎ back",52,120,5)
end
