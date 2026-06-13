-- bomb powerup shockwave: a red disc that expands from the ship and vaporises
-- every obstacle/enemy it sweeps over. fired on pickup of drop kind 3 (red comets).
-- mirrors the shield-shock pattern -- this file owns the radius; each entity loop
-- tests its own centre with bhit() rather than us iterating their (file-local) lists.
bomb_r=-1 -- current radius; <0 = inactive
local bx,by
function bomb_init() bomb_r=-1 end
-- detonate at (x,y): start the wave + a hard initial jolt
function bomb_fire(x,y) bx,by,bomb_r=x,y,0 shake=max(shake,6) snd_sfx(6) end
-- true if point (cx,cy) is inside the live shockwave disc
function bhit(cx,cy)
	if bomb_r<0 then return end
	local dx,dy=cx-bx,cy-by return dx*dx+dy*dy<=bomb_r*bomb_r
end
function update_bomb()
	if bomb_r>=0 then
		-- rumble that fades as the wave dissipates (strongest at detonation)
		shake=max(shake,5*(1-bomb_r/180))
		bomb_r+=6 if bomb_r>180 then bomb_r=-1 end
	end
end
-- 2px red expanding ring
function draw_bomb() if bomb_r>=0 then circ(bx,by,bomb_r,8) circ(bx,by,max(0,bomb_r-2),2) end end
