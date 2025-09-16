-- compressed items: icon,max,base$,inc$,field,unlock,name,desc
U="11,3,100,50,fire_rate_level,,fire rate +20%,+ faster shots;10,3,120,80,shield_level,shield_unlocked,shield upgrade,+ more shield;25,2,150,100,spread_level,,phaser spread +1,+ wider spread;38,2,200,150,hull_level,,hull +1 segment,+ more hull;54,99,200,0,,,repair hull,+ restore 1 hull;55,3,80,60,thruster_level,,thruster boost,+ faster accel"
UA=split(U,";")
UT={} for a in all(UA) do add(UT,split(a,",")) end
