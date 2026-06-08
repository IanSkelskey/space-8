cs,cm,cmin,crng,mspd,mm,msmin,msrng,mlc,ss=1,1,1.5,1.2,0.9,1,1.8,1.4,0,1
df=2
-- mult tables: speed, spawn counts, score/cash
dms,dmm,dsc=split"0.9,1,1.12",split"0.85,1,1.25",split"0.85,1,1.18"
function sl(r)
 local i=df
 cs= (0.85+min(0.05*r,0.5))*dms[i]
 cm=mid(1,flr(min(4,(r+1)/3)*dmm[i]+0.5),4)
 cmin=max(0.6,1.5-0.1*r)
 crng=max(0.4,1.2-0.08*r)
 mspd=0.9*(0.8+min(0.04*r,0.5))*dms[i]
 mm=mid(1,flr(min(4,(r+3)/3)*dmm[i]+0.5),4)
 msmin=max(0.8,1.8-0.06*r)
 msrng=max(0.6,1.4-0.05*r)
 mlc=mid(0.1+0.05*(r-4),0,0.6)
 ss=0.85+min(0.01*r,0.08)
end
