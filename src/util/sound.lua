-- music patterns
local M,S,C={MENU=0,GAME=4,FANFARE=8,DEATH=9,STATION=10,VOL=3},{EXPLODE=1,SHIELD_ON=30,SHIELD_HIT=31,SHIELD_OFF=43,CURSOR=44,ERROR=45,OK=63,LASER=62},{UI=3,LASER=2,FX=3}

-- exported functions
function snd_music(pattern)
	music(-1,0)
	if pattern then music(pattern,0,M.VOL) end
end

function snd_sfx(index,channel)
	sfx(index,channel or C.FX)
end

function snd_stop_sfx(channel)
	sfx(-1,channel or C.FX)
end

-- state-based music switcher
function snd_update_music(gs,pgs,fanfare_t)
	if gs=="game"and pgs=="station"then
		snd_music(M.GAME)
	elseif gs=="dying"and pgs=="game"then
		snd_music(M.DEATH)
	elseif(gs=="menu"or gs=="station")and pgs!="menu"and pgs!="station"and pgs!="controls"and fanfare_t<=0 then
		snd_music(gs=="station"and M.STATION or M.MENU)
	elseif gs=="gameover"and(pgs=="game"or pgs=="menu"or pgs=="station")then
		snd_music(nil)
	end
end

-- export constants for files that need them
SFX_CURSOR,SFX_ERR,SFX_OK=S.CURSOR,S.ERROR,S.OK
SFX_LASER,SFX_EXPLODE=S.LASER,S.EXPLODE
SFX_SHIELD_ON,SFX_SHIELD_HIT,SFX_SHIELD_OFF=S.SHIELD_ON,S.SHIELD_HIT,S.SHIELD_OFF
UI_CH,LASER_CH,FX_CH=C.UI,C.LASER,C.FX
MUS_MENU,MUS_GAME,MUS_FANFARE,MUS_DEATH,MUS_STATION=M.MENU,M.GAME,M.FANFARE,M.DEATH,M.STATION
