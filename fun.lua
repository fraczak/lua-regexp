module("fun")

function map(f,a)
   local res = {}
   for i=1,#a do res[i] = f(a[i]) end
   return res
end

function foldl(init,f,a)
   local res = init;
   for i = 1,#a do res = f(res,a[i]) end
   return res
end

-- coppy an array 'a' into a new one starting fromindex 'start' 
-- till index 'End' (or the end of 'a')
function copyArray(a, start, End)
   local res = {}
   if (End == nil or End > #a) then End = #a end
   for i = start,End do
      res[#res+1] =a[i]
   end
   return res
end

