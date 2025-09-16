local pups={}

function powerup_init()
	pups={}
end

function spawn_powerup(x,y)
	add(pups,{x=x,y=y,dy=0.5,t=0})
end

function update_powerup()
	for p in all(pups) do
		p.y+=p.dy
		p.t+=1
		
		-- check collision with ship
		if ship and aabb(p.x,p.y,8,8,ship.x,ship.y,ship.w,ship.h) then
			if ship_heal then ship_heal(1) end
			sfx(4) -- pickup sound
			del(pups,p)
		elseif p.y>130 then
			del(pups,p)
		end
	end
end

function draw_powerup()
	for p in all(pups) do
		-- pulse effect
		local s=38+(p.t\8%2==0 and 0 or 16)
		spr(s,p.x,p.y)
	end
end
