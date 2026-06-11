-- persistent highscores (ui cart)
-- up to MAX entries, each: hi_thousands, lo_units(0-999), name_code(base26^3)
local MAX_HS=4
local letters="abcdefghijklmnopqrstuvwxyz"
hs_entries={}
hs_sets={{},{},{}} -- per-difficulty tables: 1 easy,2 normal,3 veteran
local hs_tab=1
local hs_marq=0            -- marquee scroll offset (pixels)

local function dec_name(code)
 local a=code\676 code-=a*676
 local b=code\26
 local c=code-b*26
 return a,b,c
end
local function name_to_string(a,b,c)
 return sub(letters,a+1,a+1)..sub(letters,b+1,b+1)..sub(letters,c+1,c+1)
end

local function load_diff(di)
 local I_CNT,I_BASE=persist_hs_indices_for_df(di)
 local t=hs_sets[di]
 local cnt=dget(I_CNT)
 if cnt<=0 then cnt=0 end
 for i=#t,1,-1 do t[i]=nil end
 for i=0,cnt-1 do local o=I_BASE+i*3 add(t,{hi=dget(o),lo=dget(o+1),nc=dget(o+2)}) end
 while #t>MAX_HS do del(t,t[#t]) end
end
function hs_init()
 for d=1,3 do load_diff(d) end
 hs_tab=df or 1
 hs_entries=hs_sets[hs_tab]
end

local diff_icons={12,13,14} -- new 8x8 difficulty icons easy/normal/veteran
-- per-rank {main,shadow} colours for the raised name/score text: gold, silver, bronze, blue
local rank_cols={{10,9},{6,5},{9,4},{12,1}}

-- compare two split scores WITHOUT recombining (hi*1000+lo overflows pico-8's 32767 cap).
-- returns true if (ha,la) > (hb,lb).
function hs_gt(ha,la,hb,lb)
 ha=ha or 0 la=la or 0 hb=hb or 0 lb=lb or 0
 return ha>hb or (ha==hb and la>lb)
end

-- replace old fmt_score (returned number when hi==0 causing # on number)
local function fmt_score(hi,lo)
 lo=lo or 0 hi=hi or 0
 local s="00"..lo
 if hi>0 then
  return hi..sub(s,#s-2)
 end
 return ""..lo
end

-- helper: measure true pixel width (handles custom font + control codes)
local function tw(t)
 -- render off-screen (y=128) to get returned x = width
 local oldx,oldy=0,0
 local w=print(t,0,128)
 return w or 0
end

-- centered print using true pixel widths
-- optional bw = shared block width (in pixels)
local function cprint(t,y,c,bw)
 local w=tw(t)
 local target_bw=bw or w
 local x=(128-target_bw)\2 + (target_bw-w)\2
 print(t,x,y,c)
end

-- improved full-table renderer
function hs_draw_full()
 local t=hs_entries
 -- layout constants (adjusted to fit 4 rows)
 local y_title=9 -- centered vertically in the band above the tabs
 local y_tabs=26          -- slightly higher for more room
 local bar_h=10
 local panel_top=y_tabs+bar_h+2  -- gap under tabs
 local bottom_instr_y=118        -- fixed bottom line for back instruction
 local panel_bottom=bottom_instr_y-8  -- less bottom margin
 local y_header=panel_top+4       -- tighter header spacing
 local first_row_y=y_header+10    -- tighter gap header -> first row
 local row_gap=12                 -- slightly tighter row spacing

 -- title: block-letter logo, gold flash with a darker drop layer for depth
 local fl=time()%0.8<0.4
 draw_logo("high scores",y_title,fl and 9 or 10,fl and 4 or 9,fl and 9 or 10,fl and 4 or 9)

 -- difficulty selector: only the ACTIVE difficulty is shown (icon + name), flanked by fixed
 -- arrows that map to the left/right switch control. the icon+name re-centre as you switch
 -- while the arrows stay put, so nothing overflows or jumps.
 local tabs={"easy","normal","veteran"}
 local dn=tabs[hs_tab]
 local gw=10+#dn*4               -- icon(8) + 2px gap + name
 local gx=64-gw\2
 spr(diff_icons[hs_tab],gx,y_tabs)
 rprint(dn,gx+10,y_tabs+1,7,1)   -- active name: white, raised
 -- flashing sprite arrows (always active -- the difficulty tabs wrap around)
 farrow(18,y_tabs+1,false,true)
 farrow(102,y_tabs+1,true,true)

 -- no panel border -- rows float on the starfield like the menu. panel_top/panel_bottom still
 -- bound the row layout below.

 -- column headers (quiet, raised). rank is carried by the trophy, so there's no number column
 rprint("name",30,y_header-2,6,5)
 rprint("score",94,y_header-2,6,5)

 if #t==0 then
  cprint("(no scores yet)",y_header+10,5)
 else
  local trophy_sprs={28,29,30,31} -- gold/silver/bronze/4th
  -- calculate even spacing for up to 4 entries
  local content_start=y_header+8
  local content_end=panel_bottom-6
  local available_h=content_end-content_start-6  -- reduce total span by 6px (2px*3 gaps)
  local num_entries=min(#t,MAX_HS)
  local spacing=num_entries>1 and available_h/(num_entries-1) or 0

  for i=1,num_entries do
   local e=t[i]
   local a,b,c=dec_name(e.nc)
   local nm=name_to_string(a,b,c)
   local sc=fmt_score(e.hi,e.lo)
   local y=content_start+(i-1)*spacing
   local rc=rank_cols[min(i,4)]
   local m=rc[1]
   if i==1 and time()%0.6<0.3 then m=7 end -- #1 gets a gentle gold->white shimmer
   spr(trophy_sprs[min(i,4)],14,y)
   rprint(nm,30,y+1,m,rc[2])          -- name (raised, rank-coloured)
   rprint(sc,114-#sc*4,y+1,m,rc[2])   -- score, right-aligned to x114
  end
 end

 -- footer: how to switch difficulty (arrows) + how to leave
 cprint("⬅️➡️ difficulty   ❎ back",bottom_instr_y,5)
end

-- compact (single-line) display
-- marquee showing all 3 difficulties (trophy + diff icon + name + score)
function hs_draw_compact()
 if hs_entering then return end
 -- one segment per difficulty with a score: difficulty icon + name + score, dot-separated.
 -- the gold trophy was dropped -- it was identical on every entry, crowded the diff icon, and
 -- ate space. name and score now share equal weight (white name, gold score).
 local segs={} local total=0
 for di=1,3 do
  local e=hs_sets[di][1]
  if e then
   local a,b,c=dec_name(e.nc)
   local nm=name_to_string(a,b,c)
   local sc=fmt_score(e.hi,e.lo)
   -- width: icon(8) +3 +name +4 +score +16 (gap + separator dot)
   add(segs,{di=di,nm=nm,sc=sc,w=31+#nm*4+#sc*4})
   total+=segs[#segs].w
  end
 end
 if #segs==0 then return end
 -- advance scroll
 hs_marq-=0.5
 if hs_marq<=-total then hs_marq+=total end
 -- draw (wrap)
 local x=2+hs_marq
 local y=3
 while x<128 do
  for s in all(segs) do
   if x+s.w>0 then
    spr(diff_icons[s.di] or 28,x,y)        -- difficulty icon (no trophy)
    local tx=x+11
    rprint(s.nm,tx,y+1,7,5)                 -- name: white, raised
    local scx=tx+#s.nm*4+4
    rprint(s.sc,scx,y+1,10,9)               -- score: gold, raised
    circfill(scx+#s.sc*4+7,y+3,1,13)        -- dot separator in the trailing gap
   end
   x+=s.w
   if x>=128 then break end
  end
 end
end

function hs_change_tab(d)
 hs_tab=(hs_tab-1+d+3)%3+1 hs_entries=hs_sets[hs_tab]
end