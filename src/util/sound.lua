current_music=current_music or -1
function snd_music(p)
 -- no caller passes nil (grepped both carts), so no nil-guard needed.
 -- no channel mask (was 3) so tracks use all channels; fixes game-over jingle not sounding
 music(-1) music(p) current_music=p
end

function snd_sfx(i,ch) sfx(i,ch or 3) end
-- snd_stop_sfx wrapper removed (use sfx(-1,ch))
