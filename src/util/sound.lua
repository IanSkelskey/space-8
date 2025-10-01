-- flattened constants (removed tables for token savings)
MUS_MENU,MUS_GAME,MUS_FANFARE,MUS_DEATH,MUS_STATION=0,4,8,9,10
SFX_EXPLODE,SFX_SHIELD_ON,SFX_SHIELD_HIT,SFX_SHIELD_OFF,SFX_CURSOR,SFX_ERR,SFX_OK,SFX_LASER=1,30,31,43,44,45,63,62
UI_CH,LASER_CH,FX_CH=3,2,3

function snd_music(p)
 music(-1)
 if p then music(p,0,3) end
end

function snd_sfx(i,ch) sfx(i,ch or FX_CH) end
-- snd_stop_sfx wrapper removed (use sfx(-1,ch))

function snd_update_music(gs,pgs,ft)
 if gs=="game"and pgs=="station"then snd_music(MUS_GAME)
 elseif gs=="dying"and pgs=="game"then snd_music(MUS_DEATH)
 elseif(gs=="menu"or gs=="station")and pgs!="menu"and pgs!="station"and pgs!="controls"and ft<=0 then
  snd_music(gs=="station"and MUS_STATION or MUS_MENU)
 elseif gs=="gameover"and(pgs=="game"or pgs=="menu"or pgs=="station")then snd_music() end
end
