-- minimal persistence for gameplay cart (trimmed from full persist)
cartdata("sp8")

-- indices documented in CARTDATA.md; numeric literals save gameplay tokens
-- shield_pulse_level is packed into slot 8 (level + pulse*8)

-- load values when gameplay cart starts; return true if mission launch flag set
function persist_load_game_start()
 if dget(17)!=1 then return false end
 df=dget(1) if df<1 or df>3 then df=2 end
 round_number=dget(2)
 money_total=dget(3)
 last_pay=dget(4)
 last_bonus=dget(5)
 vr=dget(6)
 ts=dget(14) tsh=dget(15)
 last_payout_ready=dget(16)==1
 ship.fire_rate_level=dget(7)
 local sv=dget(8) ship.shield_level=sv%8 ship.shield_pulse_level=sv\8
 ship.spread_level=dget(9)
 ship.hull_level=dget(10)
 ship.thruster_level=dget(11)
 ship.shield_unlocked=dget(12)==1
 ship.hull=dget(13)
 dset(17,0)
 return true
end

-- save minimal state when leaving gameplay (station/gameover)
function persist_save_from_game(ui_state)
 dset(0,ui_state)
 dset(17,0)
 dset(1,df) dset(2,round_number) dset(3,money_total)
 dset(4,last_pay) dset(5,last_bonus) dset(6,vr)
 if ui_state==2 then ship.shield_pulse_level=0 end
 dset(7,ship.fire_rate_level) dset(8,ship.shield_level+ship.shield_pulse_level*8) dset(9,ship.spread_level)
 dset(10,ship.hull_level) dset(11,ship.thruster_level)
 dset(12,ship.shield_unlocked and 1 or 0) dset(13,ship.hull)
 dset(14,ts) dset(15,tsh)
 dset(16,last_payout_ready and 1 or 0)
 -- round-summary tallies for the ui cart's round-clear screen (spare cartdata slots)
 dset(33,last_kills) dset(47,last_score)
end
