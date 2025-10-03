function snd_music(p)
 music(-1)
 if p then music(p,0,3) end
end

function snd_sfx(i,ch) sfx(i,ch or 3) end
-- snd_stop_sfx wrapper removed (use sfx(-1,ch))

function snd_update_music(gs,pgs,ft)
 if gs=="game"and pgs=="station"then snd_music(4)
 elseif gs=="dying"and pgs=="game"then snd_music(9)
 elseif(gs=="menu"or gs=="station")and pgs!="menu"and pgs!="station"and pgs!="controls"and ft<=0 then
  snd_music(gs=="station"and 10 or 0)
 elseif gs=="gameover"and(pgs=="game"or pgs=="menu"or pgs=="station")then snd_music() end
end
