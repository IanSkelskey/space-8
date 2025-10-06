-- persistent highscores (ui cart)
-- up to MAX entries, each: hi_thousands, lo_units(0-999), name_code(base26^3)
local MAX_HS=4
local letters="abcdefghijklmnopqrstuvwxyz"
hs_entries={}
local hs_sets={{},{},{}} -- per-difficulty tables: 1 easy,2 normal,3 veteran
local hs_tab=1
hs_entering=false
local pending_score=0
local name_idx={0,0,0}
local name_pos=1

local function enc_name(a,b,c) return a*676+b*26+c end
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

local diff_icons={19,34,6} -- difficulty icons easy/normal/veteran
local hs_marq=0            -- marquee scroll offset (pixels)

local function hs_save(di)
 di=di or hs_tab
 local t=hs_sets[di]
 local I_CNT,I_BASE=persist_hs_indices_for_df(di)
 dset(I_CNT,#t)
 for i=1,#t do local e=t[i] local o=I_BASE+(i-1)*3 dset(o,e.hi) dset(o+1,e.lo) dset(o+2,e.nc) end
end

local function score_value(hi,lo) return hi*1000+lo end

local function insert_entry(hi,lo,nc,di)
 di=di or hs_tab
 local t=hs_sets[di]
 local val=score_value(hi,lo)
 local inserted=false
 for i=1,#t do if val>score_value(t[i].hi,t[i].lo) then add(t,{hi=hi,lo=lo,nc=nc},i) inserted=true break end end
 if not inserted then add(t,{hi=hi,lo=lo,nc=nc}) end
 while #t>MAX_HS do del(t,t[#t]) end
 hs_save(di)
end

function hs_process_new_run()
 local lo,hi=persist_fetch_last_run()
 if (lo or 0)==0 and (hi or 0)==0 then return end
 persist_clear_last_run()
 local val=score_value(hi,lo)
 local di=df or 1
 local t=hs_sets[di]
 if #t<MAX_HS or val>score_value(t[#t].hi,t[#t].lo) then
  pending_score=val name_idx={0,0,0} name_pos=1 hs_entering=true hs_tab=di hs_entries=hs_sets[hs_tab]
 end
end

local function commit_name()
 local hi=pending_score\1000 local lo=pending_score%1000
 insert_entry(hi,lo,enc_name(name_idx[1],name_idx[2],name_idx[3]),hs_tab)
 hs_entering=false
end

function hs_update_entry()
 if not hs_entering then return end
 -- left/right cycle letter
 if btnp(0) then
  name_idx[name_pos]=(name_idx[name_pos]-1)%26
 elseif btnp(1) then
  name_idx[name_pos]=(name_idx[name_pos]+1)%26
 end
 -- confirm letter / advance
 if btnp(4) then
  if name_pos<3 then
   name_pos+=1
  else
   commit_name()
  end
 end
 -- cancel (skip entry)
 if btnp(5) then
  hs_entering=false
 end
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
 -- layout constants (updated)
 local y_title=4
 local y_tabs=28          -- moved tabs lower for breathing room under title
 local bar_h=11
 local panel_top=y_tabs+bar_h+2  -- gap under tabs
 local bottom_instr_y=118        -- fixed bottom line for back instruction
 local panel_bottom=bottom_instr_y-14
 local y_header=panel_top+6
 local first_row_y=y_header+14   -- larger gap header -> first row
 local row_gap=13

 -- title block (unchanged centering logic)
 local title1="high scores"
 local title2="\014sPACE 8\15"
 local tbw=max(tw(title1),tw(title2))
 cprint(title1,y_title,7,tbw)
 cprint(title2,y_title+8,7,tbw)

 -- unified tab bar (outer border removed) WITH padding + no separators
 local bar_x0,bar_x1=8,120
 rectfill(bar_x0,y_tabs,bar_x1,y_tabs+bar_h-1,0)
 local tabs={"easy","normal","veteran"}
 -- content widths: icon 8 + gap 4 + label chars*4
 local cw={}
 for i=1,3 do cw[i]=8+4+#tabs[i]*4 end
 local w={}
 for i=1,3 do w[i]=cw[i]+4 end -- +4 (=2px horiz padding total) so we can keep 1px padding each side after centering
 local gap=2
 local inner_w=w[1]+w[2]+w[3]+gap*2
 local bar_w=bar_x1-bar_x0+1
 local sx=bar_x0+(bar_w-inner_w)\2
 local pad=1
 for i=1,3 do
  local active=i==hs_tab
  local seg_w=w[i]
  local ex=sx+seg_w-1
  if active then
   -- full segment fill; content will respect padding
   rectfill(sx,y_tabs,ex,y_tabs+bar_h-1,1)
  end
  -- center content then clamp to ensure 1px padding inside segment
  local content_w=cw[i]
  local cx=sx+(seg_w-content_w)\2
  if cx<sx+pad then cx=sx+pad end
  if cx+content_w>ex-pad+1 then cx=ex-pad+1-content_w end
  local cy=y_tabs+pad+1 -- 1px top padding; leaves ≥1px bottom
  spr(diff_icons[i],cx,cy)
  print(tabs[i],cx+12,cy,(active and 7 or 6))
  sx=ex+gap+1
 end

 -- panel (height fixed to avoid overlapping bottom instructions)
 rect(8,panel_top,120,panel_bottom,1)
 for yy=panel_top,panel_bottom,2 do
  for xx=8,120,2 do pset(xx,yy,0) end
 end

 print("#",16,y_header-2,5)
 print("name",36,y_header-2,5)
 print("score",94,y_header-2,5)

 if #t==0 then
  cprint("(no scores yet)",y_header+10,5)
 else
  local trophy_sprs={50,103,104}
  for i=1,min(#t,MAX_HS) do
   local e=t[i]
   local a,b,c=dec_name(e.nc)
   local nm=name_to_string(a,b,c)
   local sc=fmt_score(e.hi,e.lo)
   local y=first_row_y+(i-1)*row_gap
   if y>panel_bottom-18 then break end -- safety: avoid overflow
   if i<=3 then spr(trophy_sprs[i],14,y-6) end
   print(i..".",24,y-6,(i==1 and 10) or (i==2 and 6) or (i==3 and 4) or 6)
   print(nm,36,y-6,(i==1 and 7 or 6))
   local sc_col=(i==1 and ((time()%0.5<0.25) and 11 or 10))
     or (i==2 and 6) or (i==3 and 4) or 13
   print(sc,116-#sc*4,y-6,sc_col)
  end
 end

 -- footer separator + fixed back instruction
 line(16,bottom_instr_y-10,112,bottom_instr_y-10,1)
 cprint("❎ back",bottom_instr_y,5)
end

-- compact (single-line) display
-- marquee showing all 3 difficulties (trophy + diff icon + name + score)
function hs_draw_compact()
 if hs_entering then return end
 -- build segments (skip difficulties with no score)
 local segs={} local tw=0
 for di=1,3 do
  local t=hs_sets[di] local e=t[1]
  if e then
   local a,b,c=dec_name(e.nc)
   local nm=name_to_string(a,b,c)
   local sc=fmt_score(e.hi,e.lo)
   local txt=" "..nm.." "..sc.."   " -- padding spaces
   local w=16+#txt*4  -- 2 icons (trophy+diff) + text
   add(segs,{di=di,txt=txt,w=w})
   tw+=w
  end
 end
 if #segs==0 then return end
 -- advance scroll
 hs_marq-=0.5
 if hs_marq<=-tw then hs_marq+=tw end
 -- draw (wrap)
 local x=2+hs_marq
 local y=4
 if tw<1 then return end
 while x<128 do
  for s in all(segs) do
   if x+s.w>0 then
    -- gold trophy
    spr(50,x,y)
    -- difficulty icon
    spr(diff_icons[s.di] or 50,x+8,y)
    -- text
    print(s.txt,x+16,y,7)
   end
   x+=s.w
   if x>=128 then break end
  end
 end
end

-- adjust overlay so it centers above new panel (y shift)
function hs_draw_entry_overlay()
 if not hs_entering then return end
 local hi=pending_score\1000 local lo=pending_score%1000 local scs=fmt_score(hi,lo)
 local bw,bh=104,46 local ox=(128-bw)\2 local oy=40
 rectfill(ox,oy,ox+bw,oy+bh,0) rect(ox,oy,ox+bw,oy+bh,7)
 cprint("NEW HIGH SCORE!",oy+4,7) cprint(scs,oy+14,11)
 for i=1,3 do local ch=sub(letters,name_idx[i]+1,name_idx[i]+1) local sel=i==name_pos local col= sel and (time()%0.25<0.125 and 10 or 7) or 6 print(ch,64+(i-2)*8,oy+26,col) end
 cprint("🅾️ next  ❎ skip",oy+36,5)
end

function hs_change_tab(d)
 hs_tab=(hs_tab-1+d+3)%3+1 hs_entries=hs_sets[hs_tab]
end