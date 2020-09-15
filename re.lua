function tablePrint(t1,indent,name,depth)
   indent = indent or ""
   depth = depth or 120
   if #indent > depth then return "..." end
   name = name or ""
   local result = indent..name..":"
   if (type(t1) == 'table') then
      local empty = true
      for k, v in pairs(t1) do
         empty = false;
         result = result .. "\n" .. tablePrint(v, indent.."   |",tostring(k),depth)
      end
      if (empty) then result = result.." []" end
   else  
      result = result.."'"..tostring(t1).."'"  
   end
   return result
end

-------------------------------
-------- helper functions
local function map(f,a) local res = {} 
   for i=1,#a do res[i] = f(a[i]) end
   return res end

local function foldl(init,f,a) local res = init;
   for i = 1,#a do res = f(res,a[i]) end
   return res end

-- copy array 'a' from index 'start' till 'End' (or the end of 'a')
local function copyArray(a, start, End) local res = {}
   if (End == nil or End > #a) then End = #a end
   for i = start,End do res[#res+1] =a[i] end
   return res end

-- copy table 'a' 
local function copyTable(a) local res = {}
   for i,v in pairs(a) do res[i] = v end
   return res end

-- replace table 'a' by 'b' (the pointer of 'a' doesn't change) 
local function replaceTable(a,b) 
   for i,v in pairs(a) do a[i] = nil end
   for i,v in pairs(b) do a[i] = v end end

-- split word 'w' into two at index 'i'
local function split(w,i)
   if (w:len() >= i) then return  {w:sub(1,i), w:sub(2)} end
   return nil end

-- push/pop
local function push(stack,a) table.insert(stack,a) end
local function pop(stack) 
   if (type(stack) ~= 'table' or #stack == 0) then return nil end 
   local a = stack[#stack] 
   table.remove(stack) 
   return a end
--------------------------------------------------------------------
-- e ::= class() | plus(e,e,...) | con(e,e,...) | iter(e) 
-- empty 'con' is ACCEPT, empty 'plus' is REJECT
-- 
-- e = {root=[class|plus|con],
--      iter=true|false
--      children: [e1,e2,...]
--      pattern: ... string for a char match
---------------------------------------------------------------------
local context = {}

local ACCEPT = {root='con',children={}}
local REJECT = {root='plus',children={}}
   
local function accepts(e) 
   if (e.iter) then return true end
   if (e.root == 'con') then
      return foldl(true,
		   function(x,e) return x and accepts(e) end,
		   e.children) end
   if (e.root == 'plus') then
      return foldl(false,
		   function(x,e) return x or accepts(e) end,
		   e.children) end
   return false end		 

local function toIndex(e)
   if e.index then return e.index end
   -- 
   if (e.root == "class") then e.index = e.pattern
   else
      local tail = table.concat(map(toIndex, e.children),",")
      if (e.root == 'plus') then e.index = "+["..tail.."]" 
      elseif (e.root == 'con') then e.index = ".{"..tail.."}" end end
   if (e.iter) then e.index = "*("..e.index..")" end 
   return e.index end

local function register(e) 
   local index = toIndex(e)
   local result = context[index]
   if (result) then return result end
   context[index] = e
   return e end

local function step(e,a) 
   e = register(e)
   if (e == ACCEPT or e == REJECT) then return REJECT end 
   -- 
   local f = e[a]
   if (f == nil) then
      if (e.iter) then 
	 local es = copyTable(e)
	 es.iter=nil
	 es.index=nil
	 f = con{step(es,a),e}
      elseif (e.root == "plus") then
	 f = plus(map(function(e) return step(e,a) end, e.children))
      elseif (e.root == "con") then
	 local ch = {}
	 for i=1,#e.children do
	    local l = copyArray(e.children,i)
	    l[1] = step(e.children[i],a) 
	    ch[i] = con(l)
	    if (not accepts(e.children[i])) then break end end
	 f = plus(ch) 
      elseif (e.root == "class") then
	 if (a:match(e.pattern)) then return ACCEPT
	 else return REJECT end end
      e[a] = f end
   return f end

local function flatten(t,root)
   local r = {}
   for i,v in ipairs(t) do
      if v.root ~= root or v.iter then
	 table.insert(r,v) 
      else
	 for j,w in ipairs(v.children) do table.insert(r,w) end 
   end end
   return r end

local function normalize(t)
   local r = flatten(t,"plus")
   table.sort(r,function(x,y) return toIndex(x) < toIndex(y) end)
   local i = 2
   while i <= #r do
      if toIndex(r[i-1]) == toIndex(r[i]) then table.remove(r,i)
      else i = i+1 end end
   return r end

function plus(children)
   local ch = 
      foldl({},
	    function(r,e)
	       if (e == REJECT) then return r end
	       r[#r+1] = e
	       return r end,
	    normalize(children))	   
   if (#ch == 0) then return REJECT end
   if (#ch == 1) then return ch[1] end
   return {root="plus",children=ch} end

function con(children)
   local ch = 
      foldl({},
	    function(r,e)
	       if (r == REJECT or e == REJECT) then return REJECT end
	       if (e == ACCEPT) then return r end
	       r[#r+1] = e
	       return r end,
	    flatten(children,"con"))
   if (ch == REJECT) then return REJECT end
   if (#ch == 0) then  return ACCEPT end
   if (#ch == 1) then return ch[1] end
   return {root="con",children=ch} end

function iter(e)
   --   if (e.iter) then return e end
   local result = copyTable(e)
   if not result.iter then
      result.iter = true
      result.index = nil end
   return result end

function class(pat) return {root="class", pattern=pat} end

function matches(e,w)
   if (w == '') then return accepts(e) end
   local s = split(w,1)
   return matches(step(e,s[1]),s[2]) end

local function eat(e,w,res,ahead)
   if (w == '' or e == REJECT) then return res, ahead..w end
   local s = split(w,1)
   e = step(e,s[1])
   if (accepts(e)) then 
      if (res) then res = res..ahead..s[1] else res = ahead..s[1] end
      ahead = '' 
   else ahead = ahead..s[1] end
   return eat(e,s[2],res,ahead) end

local EXPORT = 
   { matches=matches,
     class=class,
     plus=plus,
     con=con,
     iter=iter,
     eat=function(e,w) 
	    if (accepts(e)) then return eat(e,w,'','') end
	    return eat(e,w,nil,'') end
  }

-------------------------------------------
-- PARSING
-------------------------------------------

-- returns {type=1..5,subExp={...},rest='...'}
--  'type' is the index in [ w$, w(, w+, w), w)* ]
local getToken = (function() 
   local token = 
   -- Regular expression of a token such as: w$, w+, ... 
   -- (E1.E2)*E1.E3 where:
   --   E1 = [^[+()]          -- e.g. "ala"
   --   E2 = [[][^]]*[]]      -- e.g. "ala[^ala]"
   --   E3 = [+)(]?|")*"      -- e.g. "+" or ")*"
	con{ iter(con{iter(class("[^[|()]")),class("[[]"),class("."),iter(class("[^]]")),class("[]]")}),
	   iter(class("[^[|()]")),
	   plus{ACCEPT,class("[|()]"), con{class("[)]"),class("[*]")}}}

   local function decode(w) 
      local ch = {}
      local i = 1
      while i <= #w do
	 local a = w:sub(i,i)
	 if (#ch > 0 and a == '*') then 
            ch[#ch] = iter(ch[#ch])
	 elseif (a == '[') then
	    local cars = w:sub(i,i+1)
	    i = i+2
	    while (w:sub(i,i) ~= ']') do 
	       cars =  cars..w:sub(i,i)
	       i = i+1 end
	    cars = cars..']'
	    ch[#ch+1] = class(cars)
	 else 
	    ch[#ch+1] = class(a) end
         i = i +1 end
      return con(ch) end

   return function(ww)
	     local s, w = eat(token,ww,'','')
             local result = "?"
	     if (s:match('[)][*]$')) then
		result = {type=")*", subExp = decode(s:sub(1,-3)),rest=w} 
	     elseif (s:match('[)]$')) then
		result = {type=")", subExp = decode(s:sub(1,-2)),rest=w} 
	     elseif (s:match('[|]$')) then
		result = {type="|" , subExp = decode(s:sub(1,-2)),rest=w} 
	     elseif (s:match('[(]$')) then
		result = {type="(", subExp = decode(s:sub(1,-2)),rest=w} 
             else
                result = {type="$",subExp = decode(s),rest=w} end
             return result
          end
end)()
	    
local function parse(word)
   local word = word
   local parse_tree = {kind="E",rule=nil,val=nil,iter=nil}
   -- kind := E | G | L, rule := 1,2,3,4,5,6,7, val := list of children or leaf value, iter := true
   local function from_parse_tree(s)
      if s.rule == 1 then return {s.val} end
      if s.rule == 4 or s.rule == 5 then 
	 if s.iter then return {iter(s.val)} end
	 return {s.val} end
      local G = plus(from_parse_tree(s.val[2]))
      if (s.val[2].iter) then G = iter(G) end
      if s.rule == 3 or s.rule == 7 then return {s.val[1], G} end
      local R = from_parse_tree(s.val[3]) 
      if #R == 1 then return {con{s.val[1],G,R[1]}} end
      return {con{s.val[1],G,R[1]}, R[2]} end

   local stack = {parse_tree}
   local iter_stack = {}
   local function getNextToken() 
       local token  = getToken(word) 
       word = token.rest
       return token.type, token.subExp end

   while (#stack > 0) do
--      print("-------------- stack size = "..tostring(#stack))
--      print(tablePrint(stack,"","stack"))
      local s = pop(stack)
      local k, e  = getNextToken()
      if k == "$" and s.kind == "E" then -- w$, and 
	 s.rule = 1 -- E -> w$
	 s.val = e
      elseif k == "(" then 
	 if s.kind == "E" then s.rule=2 else s.rule=6 end
	 s.val={e,{kind="G"},{kind=s.kind}}
	 push(stack,s.val[3])
	 push(stack,s.val[2])
	 push(iter_stack,s.val[2]) 
      elseif (k == "|") then -- w+ 
	 if s.kind == "E" then s.rule=3 else s.rule=7 end
	 s.val={e,{kind=s.kind}}
	 push(stack,s.val[2])
      elseif (k == ")") and s.kind=="G" then -- w)
	 s.rule=4
	 s.val=e 
	 pop(iter_stack).iter=false
      elseif (k == ")*") and s.kind=="G" then -- w)*
	 s.rule=5
	 s.val=e 
	 pop(iter_stack).iter=true 
      else error("Syntax error") end end
   --   print(tablePrint(parse_tree,"= "," parse tree"))
   local result = plus(from_parse_tree(parse_tree))
   --   print(tablePrint(result,"> "," result"))
   return result end

EXPORT.parse = function(x) return parse(x) end 

--------------------
-- DEBUG and testing
---------------------
function dump() local c=0
   print(" *** Showing all:")
   for i,v in pairs(context) do c=c+1 
      print(i) end
   print(" *** Number of states: "..c)
end

EXPORT.db={dump=dump}

return EXPORT