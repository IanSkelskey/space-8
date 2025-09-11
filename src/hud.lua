local score,money=0,0
ts=ts or 0
HUD_HEIGHT=10

function hud_init()
	score = 0
	money = 0
end

function hud_add_score(n) score += n or 0 ts += n or 0 end
function hud_add_money(n) money += n or 0 end

-- minimal accessors for mission bonus calc
function hud_get_points() return score end
function hud_reset_points() score=0 end

-- helper to draw a compact meter
local function dm(x,y,w,h,v,m,cf,cm,cl)
	rectfill(x,y,x+w-1,y+h-1,0)
	local fw=flr((v/m)*w)
	if fw>0 then
		local r=v/m
		local c=cl if r>0.5 then c=cf elseif r>0.25 then c=cm end
		rectfill(x,y,x+fw-1,y+h-1,c)
	end
	rect(x,y,x+w-1,y+h-1,5)
end

function draw_hud()
	rectfill(0,0,127,HUD_HEIGHT-1,0)
	line(0,HUD_HEIGHT-1,127,HUD_HEIGHT-1,1)
	print(score,2,2,7)
	
	print(money_total or money,37,2,10)
	
	local x=72
	spr(10,x,2)
	local p=ship and ship.shield_power or 0
	dm(x+7,3,20,3,p,100,12,13,8)

end
