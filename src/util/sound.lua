current_music=current_music or -1
function snd_music(p)
 music(-1)
 -- removed channel mask (was 3) so tracks use all channels; fixes game over jingle not sounding
 if p then music(p) current_music=p end
end

function snd_sfx(i,ch) sfx(i,ch or 3) end
-- snd_stop_sfx wrapper removed (use sfx(-1,ch))
