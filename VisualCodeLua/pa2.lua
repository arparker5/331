--pa2.lua
--Grenon J. Samuel
--6 Feb 2018

--For cs 331/ Programing Languages 
--This is the module for pa2_test.lua

-- To use this module, do
-- pa2 = require "pa2"
-- in some Lua Program.
local pa2 = {}

--mapArray
--mapArray is a member function that takes a function
--and a table. mapArray then operates on every value of that
--table with the function.
--Exports
function pa2.mapArray(f, t)

    for k,v in pairs(t) do 
        t[k] = f(v)
    end

    return t
end

--concatMax
--concatMax is a member function that uses the floor function
--to divide the newSize by the current string size and rounds down
--then concats the string that many times.
--Exports
function pa2.concatMax(input, newSize)

   local cat = math.floor(newSize/input:len())
    input = input:rep(cat)
   return input
end


--collatz
--collatz is a memember function that performs the collatz
--sequence. Collatz puts the values in the ables and then uses
--a courotine to yeild the results.
--Exports
function pa2.collatz(k)

    local a =  { k }
    while true do
        if k <= 1 then
            break;
        end

        if k%2 ~= 0 then
            k = 3*k + 1
            table.insert(a, k)
        else 
            k = k/2
            table.insert(a,k)
        end
    end
    for key in pairs(a) do
        coroutine.yield(a[key])
    end
end
        
return pa2          



   




