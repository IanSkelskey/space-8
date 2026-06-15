cs,cm,cmin,crng,mspd,mm,msmin,msrng,mlc,ss=1,1,1.5,1.2,0.9,1,1.8,1.4,0,1
df=2
-- mult tables: speed, spawn counts, score/cash
dms,dmm,dsc=split"0.9,1,1.12",split"0.85,1,1.25",split"0.85,1,1.18"
-- endless escalation: the ramp (rounds 1..12) builds the roster to "baseline hard",
-- then `e` keeps SPEED climbing forever (never caps) while spawn density holds at a
-- raised ceiling. so a maxed-out ship eventually can't clear a round untouched -- the
-- run ends when the world finally outruns you, tetris-style, not at a fixed plateau.
-- tune endless pressure with the 0.03/0.025 speed-creep coefficients below.
function sl(r)
 local i=df
 local e=max(0,r-12) -- 0 during the ramp, then +1 per round forever
 -- endless escalation climbs SPEED *and* ASTEROID DENSITY (mm rises past 4): a sparse fast
 -- field is easy to out-shoot, a saturated one isn't. comets stay capped at 4 (their trails are
 -- the main perf cost); the lowered interval floors mean the linear -0.06*r term already drives
 -- asteroid spawns near-floor by the time the cap rises, so it fills. counts hard-capped for perf.
 cs= (0.85+min(0.05*r,0.5)+e*0.03)*dms[i]
 cm=mid(1,flr(min(4,(r+1)/3)*dmm[i]+0.5),4)
 cmin=max(0.4,1.5-0.1*r)
 crng=max(0.3,1.2-0.08*r)
 mspd=0.9*(0.8+min(0.04*r,0.5)+e*0.025)*dms[i]
 mm=mid(1,flr(min(4,(r+3)/3)*dmm[i]+0.5)+e\6,6)
 msmin=max(0.4,1.8-0.06*r)
 msrng=max(0.3,1.4-0.05*r)
 mlc=mid(0.1+0.05*(r-4),0,0.7)
 ss=0.85+min(0.01*r+e*0.004,0.25)
end
