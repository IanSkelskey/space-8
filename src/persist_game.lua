-- minimal persistence for gameplay cart (trimmed from full persist)
cartdata("sp8")

-- indices (subset of full map)
local I_UI_STATE=0
local I_DF=1
local I_ROUND=2
local I_MONEY=3
local I_LAST_PAY=4
local I_LAST_BONUS=5
local I_VR=6
local I_FIRE=7
local I_SHIELD=8
local I_SPREAD=9
local I_HULL_L=10
local I_THRUST=11
local I_SHIELD_UNL=12
local I_HULL=13
local I_TS=14
local I_TSH=15
local I_PAYOUT_READY=16
local I_START_FLAG=17
local I_LAST_RUN_LO=18
local I_LAST_RUN_HI=19
local I_PULSE=40

local function w(i,v) if v then dset(i,v) end end

-- load values when gameplay cart starts; return true if mission launch flag set
function persist_load_game_start()
 if dget(I_START_FLAG)!=1 then return false end
 df=dget(I_DF) if df<1 or df>3 then df=2 end
 round_number=dget(I_ROUND)
 money_total=dget(I_MONEY)
 last_pay=dget(I_LAST_PAY)
 last_bonus=dget(I_LAST_BONUS)
 vr=dget(I_VR)
 ts=dget(I_TS) tsh=dget(I_TSH)
 last_payout_ready=dget(I_PAYOUT_READY)==1
 if not ship then ship={} end
 ship.fire_rate_level=dget(I_FIRE)
 ship.shield_level=dget(I_SHIELD)
 ship.spread_level=dget(I_SPREAD)
 ship.hull_level=dget(I_HULL_L)
 ship.thruster_level=dget(I_THRUST)
 ship.shield_unlocked=dget(I_SHIELD_UNL)==1
 ship.hull=dget(I_HULL)
 ship.shield_pulse_level=dget(I_PULSE)
 return true
end

function persist_consume_start_flag() dset(I_START_FLAG,0) end

-- save minimal state when leaving gameplay (station/gameover)
function persist_save_from_game(ui_state)
 dset(I_UI_STATE,ui_state)
 dset(I_START_FLAG,0)
 w(I_DF,df) w(I_ROUND,round_number) w(I_MONEY,money_total)
 w(I_LAST_PAY,last_pay) w(I_LAST_BONUS,last_bonus) w(I_VR,vr)
 if ship then
  w(I_FIRE,ship.fire_rate_level) w(I_SHIELD,ship.shield_level) w(I_SPREAD,ship.spread_level)
  w(I_HULL_L,ship.hull_level) w(I_THRUST,ship.thruster_level)
  w(I_SHIELD_UNL,ship.shield_unlocked and 1 or 0) w(I_HULL,ship.hull)
  if ui_state==2 then dset(I_PULSE,0) else w(I_PULSE,ship.shield_pulse_level) end
 end
 w(I_TS,ts) w(I_TSH,tsh)
 w(I_PAYOUT_READY,last_payout_ready and 1 or 0)
end

-- store last run total (already pre-summed by caller)
function persist_store_last_run_total(total)
 local hi=total\1000
 dset(I_LAST_RUN_HI,hi)
 dset(I_LAST_RUN_LO,total-hi*1000)
end

function persist_clear_pulse() dset(I_PULSE,0) end
