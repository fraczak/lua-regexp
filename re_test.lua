r = require "re"



function Iteration(e,f,t)
   local base = ""
   local r = ""
   for i=1,t do 
      base = e..base 
      if i == f then r = base 
      elseif i > f then r = r .. "|" .. base end end
   return r end

digit_1_20 = Iteration("[0-9*#]",1,20)
sep = "(|[-._() ])"
aux_2_10 = Iteration("("..sep.."("..digit_1_20..")"..sep..")",2,10)
dos = "(|[+])"..aux_2_10
