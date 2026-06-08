local sel=1            -- current selection index in active menu
local show_hs=false    -- full high score mode
local picking_diff=false -- whether we are on difficulty submenu
local menu_t0=0        -- time() when the menu was entered; drives the one-shot logo shine

-- difficulty & root label/icon sets
local diff_labels,diff_icons=split"easy,normal,veteran",{19,34,6}
local root_labels,root_icons=split"start,highscores,help",{6,50,41} -- added help option

-- start a new run but remain in station before launching first mission
local function start_game(set_df)
 df=set_df
 persist_reset_progress() -- wipe progress for fresh run
 round_number=sr[df] vr=1
 game_state="station" station_init()
end

function menu_init()
 sel=1 show_hs=false picking_diff=false menu_t0=time()
end

function update_menu()
 if show_hs then
    if btnp(0) then hs_change_tab(-1) snd_sfx(44,3) end
    if btnp(1) then hs_change_tab(1) snd_sfx(44,3) end
    if btnp(5) or btnp(4) then show_hs=false snd_sfx(44,3) end
  return
 end
 -- submenu: picking difficulty
 if picking_diff then
  if btnp(2) then sel-=1 snd_sfx(44,3) end
  if btnp(3) then sel+=1 snd_sfx(44,3) end
  if sel<1 then sel=#diff_labels end
  if sel>#diff_labels then sel=1 end
  if btnp(5) then picking_diff=false sel=1 snd_sfx(44,3) return end
  if btnp(4) then start_game(sel) end
  return
 end
 -- root menu (start / highscores)
 if btnp(2) then sel-=1 snd_sfx(44,3) end
 if btnp(3) then sel+=1 snd_sfx(44,3) end
 if sel<1 then sel=#root_labels end
 if sel>#root_labels then sel=1 end
 if btnp(4) then
  if sel==1 then
   picking_diff=true sel=1 snd_sfx(63,3)
  elseif sel==2 then
   show_hs=true snd_sfx(63,3)
  else
   game_state="help" help_init() snd_sfx(63,3)
  end
 end
end

local function draw_list(labels,icons,start_y)
 local y=start_y
 for i=1,#labels do
  local c=i==sel and 7 or 6
  if i==sel then print(">",36+time()%1\0.5,y,c) end
  spr(icons[i],44,y)
  print(labels[i],54,y,c)
  y+=12
 end
end

-- angled shine band: redraw the logo one row at a time inside a slanted clip strip so a
-- diagonal glint sweeps over it. x0=band x at the top row, w=width, sl=x shift per row (slant);
-- lm/ls/dm/ds = the (brightened) letter/digit main+shadow colours used inside the band.
local function shine(x0,w,sl,lm,ls,dm,ds)
 for yy=24,44 do
  clip(x0+(yy-24)*sl,yy,w,1)
  draw_logo("space 8",26,lm,ls,dm,ds)
 end
 clip()
end

function draw_menu()
 if show_hs then
  hs_draw_full()
  return
 end
 -- one-shot logo shine then steady flashing. e = time since menu entry; the glint sweeps until
 -- e>=2.23 (band clears the logo at 70px/s), then the flash phases off (e-2.23) so its first
 -- half-cycle is a full 0.4s like the rest (not a partial slice of the global time() cycle).
 local e=time()-menu_t0
 if e<2.23 then
  local sx=-16+e*70
  draw_logo("space 8",26,12,1,9,4) -- steady base while the glint plays
  shine(sx,9,-1,7,12,10,9)         -- both bands brighten both layers at 45deg (/)
  shine(sx-6,3,-1,7,12,10,9)
 else
  -- normal flashing logo: letters blue/white, "8" orange/yellow
  local fl=(e-2.23)%0.8<0.4
  draw_logo("space 8",26,fl and 12 or 7,fl and 1 or 12,fl and 9 or 10,fl and 4 or 9)
 end
 if picking_diff then
  print("select difficulty",28,40,10)
  draw_list(diff_labels,diff_icons,56)
  print("🅾️ select  ❎ back",22,104,5)
 else
  print("v2.1.0",52,40,6)
  draw_list(root_labels,root_icons,56)
  print("🅾️ select",40,104,5)
 end
 print("made with \fe♥\f7 by ian skelskey",12,116,5)
 hs_draw_compact()
end