-- persistent highscores (ui cart)
-- up to MAX entries, each: hi_thousands, lo_units(0-999), name_code(base26^3)
local MAX_HS=5
local letters="abcdefghijklmnopqrstuvwxyz"
hs_entries={}
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

function hs_init()
 local I_CNT,I_BASE=persist_hs_indices()
 local cnt=dget(I_CNT)
 if cnt<=0 then
  -- seed with one initial entry
  dset(I_CNT,1)
  dset(I_BASE,5)      -- hi
  dset(I_BASE+1,0)    -- lo
  dset(I_BASE+2,enc_name(0,2,4)) -- "ace"
  cnt=1
 end
 hs_entries={}
 for i=0,cnt-1 do
  local o=I_BASE+i*3
  add(hs_entries,{
   hi=dget(o),
   lo=dget(o+1),
   nc=dget(o+2)
  })
 end
end

local function hs_save()
 local I_CNT,I_BASE=persist_hs_indices()
 dset(I_CNT,#hs_entries)
 for i,e in ipairs and ipairs(hs_entries) or inext,hs_entries do
  local o=I_BASE+(i-1)*3
  dset(o,e.hi) dset(o+1,e.lo) dset(o+2,e.nc)
 end
end

local function score_value(hi,lo) return hi*1000+lo end

local function insert_entry(hi,lo,nc)
 local val=score_value(hi,lo)
 local inserted=false
 for i=1,#hs_entries do
  if val>score_value(hs_entries[i].hi,hs_entries[i].lo) then
   add(hs_entries,{hi=hi,lo=lo,nc=nc},i)
   inserted=true
   break
  end
 end
 if not inserted then add(hs_entries,{hi=hi,lo=lo,nc=nc}) end
 while #hs_entries>MAX_HS do
  del(hs_entries,hs_entries[#hs_entries])
 end
 hs_save()
end

function hs_process_new_run()
 local lo,hi=persist_fetch_last_run()
 if (lo or 0)==0 and (hi or 0)==0 then return end
 persist_clear_last_run()
 local val=score_value(hi,lo)
 -- qualifies?
 if #hs_entries<MAX_HS or val>score_value(hs_entries[#hs_entries].hi,hs_entries[#hs_entries].lo) then
  pending_score=val
  name_idx={0,0,0}
  name_pos=1
  hs_entering=true
 else
  -- ignore
 end
end

local function commit_name()
 local hi=pending_score\1000
 local lo=pending_score%1000
 insert_entry(hi,lo,enc_name(name_idx[1],name_idx[2],name_idx[3]))
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

-- helper: centered print
local function cprint(t,y,c)
 local x=64-#t*2
 print(t,x,y,c)
end

-- improved full-table renderer
function hs_draw_full()
 if #hs_entries==0 then return end
 -- layout constants (tuned for more vertical spacing)
 local top=10
 local panel_bottom=118
 local row_gap=13        -- increased from 11
 local row_h_hi_y_off=8  -- highlight box bottom offset
 -- panel frame (taller)
 rectfill(6,top-6,121,panel_bottom,0)
 rect(6,top-6,121,panel_bottom,1)

 -- title block (shifted up slightly with extra gap before rows)
 cprint("high scores",top-4,7)
 cprint("\014sPACE 8\15",top+4,7)
 line(18,top+12,110,top+12,1)

 -- column headers (pushed down a bit for clarity)
 local hy=top+14
 print("#",12,hy,5)
 print("name",26,hy,5)
 print("score",92,hy,5)

 -- rows (start further down)
 local row_start=top+24
 local trophy_sprs={50,103,104}
 for i,e in ipairs and ipairs(hs_entries) or inext,hs_entries do
  local a,b,c=dec_name(e.nc)
  local nm=name_to_string(a,b,c)
  local sc=fmt_score(e.hi,e.lo)
  local row_y=row_start+(i-1)*row_gap
  -- base stripe
  local stripe=((i%2)==0) and 1 or 0
  rectfill(10,row_y-3,118,row_y+row_h_hi_y_off,stripe)

  -- special styling for top 3
  if i<=3 then
   -- overlay distinct background & border
   local bc=i==1 and 10 or (i==2 and 6 or 4) -- gold, silver, bronze accents
   rectfill(10,row_y-3,118,row_y+row_h_hi_y_off,0)
   rect(10,row_y-3,118,row_y+row_h_hi_y_off,bc)
   spr(trophy_sprs[i],14,row_y)
  else
   spr(50,14,row_y) -- reuse gold icon as generic marker for remaining
  end

  -- rank / name
  print(i..".",22,row_y,(i==1 and 10 or i==2 and 6 or i==3 and 4 or 6))
  print(nm,34,row_y,(i==1 and 7 or 6))

  -- score color pulse for #1, subtle for #2/#3
  local sc_col=
    (i==1 and ((time()%0.5<0.25) and 11 or 10))
    or (i==2 and 6)
    or (i==3 and 4)
    or 13
  print(sc,118-#sc*4,row_y,sc_col)
 end

 -- footer (lower, matching new panel height)
 local fy=panel_bottom-14
 line(18,fy,110,fy,1)
 cprint("❎ back",panel_bottom-9,5)
end

-- compact (single-line) display
function hs_draw_compact()
 -- show only top entry (used on main menu)
 if hs_entering then return end
 local e=hs_entries[1]
 if not e then return end
 local a,b,c=dec_name(e.nc)
 local nm=name_to_string(a,b,c)
 local sc=fmt_score(e.hi,e.lo)
 -- small tag top-left
 print("top "..nm.." "..sc,2,4,7)
end

-- adjust overlay so it centers above new panel (y shift)
function hs_draw_entry_overlay()
 if not hs_entering then return end
 local hi=pending_score\1000 local lo=pending_score%1000
 local scs=fmt_score(hi,lo)
 local bw,bh=104,46
 local ox=(128-bw)\2 local oy=40
 rectfill(ox,oy,ox+bw,oy+bh,0)
 rect(ox,oy,ox+bw,oy+bh,7)
 cprint("NEW HIGH SCORE!",oy+4,7)
 cprint(scs,oy+14,11)
 for i=1,3 do
  local ch=sub(letters,name_idx[i]+1,name_idx[i]+1)
  local sel=i==name_pos
  local col= sel and (time()%0.25<0.125 and 10 or 7) or 6
  print(ch,64+(i-2)*8,oy+26,col)
 end
 cprint("🅾️ next  ❎ skip",oy+36,5)
end
