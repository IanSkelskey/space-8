-- shared persistence + cart handoff helpers
-- uses cartdata to shuttle run-time state between ui cart and gameplay cart
-- index map (keep numbers small for tokens)
local CID="sp8" -- cartdata id
cartdata(CID)

-- shared difficulty + starting rounds (duplicated from gameplay for UI-only cart)
sr=sr or split"1,2,4"
dm=dm or split"0.7,0.8,0.9"
function dmul()return dm[df] end

-- indices
local I_UI_STATE=0   -- 0 menu (default) |1 station |2 gameover
local I_DF=1         -- difficulty
local I_ROUND=2      -- round_number
local I_MONEY=3      -- money_total
local I_LAST_PAY=4
local I_LAST_BONUS=5
local I_VR=6         -- visible round counter
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
local I_START_FLAG=17 -- 1 means gameplay cart should start a mission immediately
local I_LAST_RUN_LO=18
local I_LAST_RUN_HI=19
-- per-difficulty high score tables (each: count + entries (MAX_HS*3))
local I_HS1_COUNT=20
local I_HS1_BASE=21 -- easy (21-33: 1 count + 4 entries * 3 values = 13 slots)
local I_HS2_COUNT=34
local I_HS2_BASE=35 -- normal (35-47: 1 count + 4 entries * 3 values = 13 slots)
local I_HS3_COUNT=48
local I_HS3_BASE=49 -- veteran (49-61: 1 count + 4 entries * 3 values = 13 slots)
-- shield_pulse_level packed into high bits of I_SHIELD (level + pulse*8)
local I_LIFE_LO=62 -- lifetime money low (0-999)
local I_LIFE_HI=63 -- lifetime money thousands

-- write a value only if non-nil (saves a few tokens where used repeatedly)
local function w(i,v) if v then dset(i,v) end end

-- save state from UI before launching gameplay
function persist_save_for_game()
 w(I_DF,df)
 w(I_ROUND,round_number)
 w(I_MONEY,money_total)
 w(I_LAST_PAY,last_pay)
 w(I_LAST_BONUS,last_bonus)
 w(I_VR,vr)
 if ship then
  w(I_FIRE,ship.fire_rate_level)
  w(I_SHIELD,ship.shield_level+ship.shield_pulse_level*8)
  w(I_SPREAD,ship.spread_level)
  w(I_HULL_L,ship.hull_level)
  w(I_THRUST,ship.thruster_level)
  w(I_SHIELD_UNL,ship.shield_unlocked and 1 or 0)
  w(I_HULL,ship.hull)
 end
 w(I_TS,ts) w(I_TSH,tsh)
 w(I_PAYOUT_READY,last_payout_ready and 1 or 0)
 -- lifetime money already tracked incrementally; just persist current copy
 if money_life_lo then dset(I_LIFE_LO,money_life_lo) dset(I_LIFE_HI,money_life_hi) end
 dset(I_START_FLAG,1)
 dset(I_UI_STATE,0) -- clear pending ui state
end

-- save from gameplay when returning to UI (station/gameover)
function persist_save_from_game(ui_state)
 dset(I_UI_STATE,ui_state)
 dset(I_START_FLAG,0)
 w(I_DF,df)
 w(I_ROUND,round_number)
 w(I_MONEY,money_total)
 w(I_LAST_PAY,last_pay)
 w(I_LAST_BONUS,last_bonus)
 w(I_VR,vr)
 if ship then
  w(I_FIRE,ship.fire_rate_level)
  if ui_state==2 then ship.shield_pulse_level=0 end -- gameover: drop shield shock
  w(I_SHIELD,ship.shield_level+ship.shield_pulse_level*8)
  w(I_SPREAD,ship.spread_level)
  w(I_HULL_L,ship.hull_level)
  w(I_THRUST,ship.thruster_level)
  w(I_SHIELD_UNL,ship.shield_unlocked and 1 or 0)
  w(I_HULL,ship.hull)
 end
 w(I_TS,ts) w(I_TSH,tsh)
 w(I_PAYOUT_READY,last_payout_ready and 1 or 0)
 if money_life_lo then dset(I_LIFE_LO,money_life_lo) dset(I_LIFE_HI,money_life_hi) end
end

-- load values into globals (used by both carts)
local function lg()
 -- ensure ship table exists before populating upgrade fields
 if not ship then
  ship={fire_rate_level=0,shield_level=0,spread_level=0,hull_level=0,thruster_level=0,shield_unlocked=false,hull=2}
 end
 df=dget(I_DF) if df<1 or df>3 then df=2 end
 round_number=dget(I_ROUND)
 money_total=dget(I_MONEY)
 last_pay=dget(I_LAST_PAY)
 last_bonus=dget(I_LAST_BONUS)
 vr=dget(I_VR)
 ts=dget(I_TS) tsh=dget(I_TSH)
 last_payout_ready=dget(I_PAYOUT_READY)==1
 money_life_lo=dget(I_LIFE_LO) money_life_hi=dget(I_LIFE_HI)
 if ship then
  ship.fire_rate_level=dget(I_FIRE)
  local sv=dget(I_SHIELD) ship.shield_level=sv%8 ship.shield_pulse_level=sv\8
  ship.spread_level=dget(I_SPREAD)
  ship.hull_level=dget(I_HULL_L)
  ship.thruster_level=dget(I_THRUST)
  ship.shield_unlocked=dget(I_SHIELD_UNL)==1
  ship.hull=dget(I_HULL)>0 and dget(I_HULL) or ship.hull
 end
end

-- gameplay cart startup: returns true if it should immediately start a mission
function persist_load_game_start()
 if dget(I_START_FLAG)==1 then lg() return true end
 return false
end

-- ui cart startup: returns ui_state (0 menu,1 station,2 gameover) after loading
function persist_load_ui_state()
 local st=dget(I_UI_STATE)
 if st==1 or st==2 then lg() end
 return st or 0
end

-- ui helper to launch mission
function launch_mission()
 persist_save_for_game()
 load("space_8.p8") load("space_8.p8.png") load("#space_8")
end

-- gameplay helper to return to ui
function exit_to_ui(state)
 persist_save_from_game(state)
 load("ui.p8") load("ui.p8.png") load("#space_8_ui")
end

function persist_consume_start_flag() dset(I_START_FLAG,0) end
-- expose indices needed by ui/game for highscores
function persist_store_last_run(score_lo,score_hi)
 dset(I_LAST_RUN_LO,score_lo or 0) dset(I_LAST_RUN_HI,score_hi or 0)
end

-- new: authoritative total score writer (avoids caller order mistakes)
function persist_store_last_run_total(total)
 total=total or 0
 local hi=total\1000
 local lo=total%1000
 dset(I_LAST_RUN_LO,lo) dset(I_LAST_RUN_HI,hi)
end

function persist_fetch_last_run()
 local hi=dget(I_LAST_RUN_HI) local lo=dget(I_LAST_RUN_LO)
 return lo,hi
end
function persist_clear_last_run()
 dset(I_LAST_RUN_LO,0) dset(I_LAST_RUN_HI,0)
end
function persist_hs_indices() return I_HS1_COUNT,I_HS1_BASE end -- legacy (easy)
function persist_hs_indices_for_df(d)
 if d==2 then return I_HS2_COUNT,I_HS2_BASE elseif d==3 then return I_HS3_COUNT,I_HS3_BASE end
 return I_HS1_COUNT,I_HS1_BASE
end

function persist_reset_progress()
 -- runtime vars
 money_total,last_pay,last_bonus,last_payout_ready=0,0,0,false
 ts,tsh,vr=0,0,1
 round_number=1
 -- reset ship upgrades both in gameplay (has ship_reset_upgrades) and UI cart (no ship.lua included)
 if ship then
  if ship_reset_upgrades then
   ship_reset_upgrades()
  else
   -- explicit inline reset (mirror gameplay reset intent)
   ship.fire_rate_level,ship.shield_level,ship.spread_level,ship.hull_level,ship.thruster_level=0,0,0,0,0
   ship.shield_unlocked=false
   ship.hull=2
   ship.shield_pulse_level=0
   ship.shield_power=0
  end
 end
 -- persisted fields
 dset(I_MONEY,0) dset(I_LAST_PAY,0) dset(I_LAST_BONUS,0)
 dset(I_PAYOUT_READY,0) dset(I_VR,1)
 dset(I_FIRE,0) dset(I_SHIELD,0) dset(I_SPREAD,0) dset(I_HULL_L,0)
 dset(I_THRUST,0) dset(I_SHIELD_UNL,0) dset(I_HULL,2)
 dset(I_TS,0) dset(I_TSH,0)
 -- clear last run (score) so next session starts fresh (highscores unaffected)
 dset(I_LAST_RUN_LO,0) dset(I_LAST_RUN_HI,0)
 -- reset lifetime money for a fresh game
 money_life_lo,money_life_hi=0,0
 dset(I_LIFE_LO,0) dset(I_LIFE_HI,0)
end
