cs,cm,cmin,crng,mspd,mm,msmin,msrng,mlc,ss,ssh=1,1,1.5,1.2,0.9,1,1.8,1.4,0,1,0.003
-- difficulty (1=easy,2=normal,3=veteran)
df=df or 2
-- movement speed mults, spawn count mults, virtual round offset, score/cash mult
dms,dmm,dro,dsc=split"0.9,1,1.12",split"0.85,1,1.25",split"0,-1,-3",split"0.85,1,1.18"
function sl(r)
 -- virtual earlier round for harder modes (negative offset advances difficulty)
 r+=dro[df]
 cs=0.85+min(0.05*r,0.5)
 cm=min(4,flr((r+1)/3))
 cmin=max(0.6,1.5-0.1*r)
 crng=max(0.4,1.2-0.08*r)
 mspd=0.9*(0.8+min(0.04*r,0.5))
 mm=min(4,flr((r+3)/3))
 msmin=max(0.8,1.8-0.06*r)
 msrng=max(0.6,1.4-0.05*r)
 mlc=mid(0.1+0.05*(r-4),0,0.6)
 ss=0.85+min(0.01*r,0.08)
 ssh=min(0.003+0.0002*r,0.006)
 -- apply difficulty multipliers
 local i=df
 cs*=dms[i] mspd*=dms[i]
 mm=mid(1,flr(mm*dmm[i]+0.5),4)
 cm=mid(1,flr(cm*dmm[i]+0.5),4)
end