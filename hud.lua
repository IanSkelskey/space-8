local score = 0

function hud_init()
	score = 0
end

function hud_add_score(n)
	score += n or 0
end

function draw_hud()
	local txt = "score: "..score
	-- shadow for readability
	print(txt, 1, 1, 0)
	print(txt, 2, 2, 7)
end
