current_music=current_music or -1
function snd_music(p)
 music(-1)
 -- removed channel mask (was 3) so tracks use all channels; fixes game over jingle not sounding
 if p then music(p) current_music=p else current_music=-1 end
end

function snd_sfx(i,ch) sfx(i,ch or 3) end
-- snd_stop_sfx wrapper removed (use sfx(-1,ch))

-- pattern map:
-- 0 = main menu
-- 4 = gameplay
-- 8 = victory fanfare (played manually when mission complete)
-- 9 = gameover jingle
-- 10 = station / shop
function snd_update_music(gs,pgs,ft)
 -- entering gameplay from station/menu -> start gameplay loop (4)
 if gs=="game" and (pgs=="station" or pgs=="menu") then
  snd_music(4)
 -- return to ui states after gameplay/fanfare -> menu (0) or station (10)
 elseif (gs=="menu" or gs=="station") and pgs~="menu" and pgs~="station" and ft<=0 then
  snd_music(gs=="station" and 10 or 0)
 -- entering gameover from any prior non-gameover state -> play jingle 9
 elseif gs=="gameover" and pgs~="gameover" then
  snd_music(9)
 -- if we leave gameover to menu or station, stop music so next transition logic restarts correct track
 elseif (gs=="menu" or gs=="station") and pgs=="gameover" then
  snd_music(gs=="station" and 10 or 0)
 end
end
