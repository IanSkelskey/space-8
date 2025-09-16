function draw_gameover()
	draw_hud()
	print("game over",40,52,7)
	print("round "..(round_number or 1),44,64,6)
	print("cash $"..(money_total or 0),44,72,10)
	print("total "..(ts or 0),44,80,7)
	print("🅾️ menu",50,96,6)
end
