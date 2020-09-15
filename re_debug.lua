function tablePrint(t1,indent,name,depth)
   indent = indent or ""
   depth = depth or 80
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
