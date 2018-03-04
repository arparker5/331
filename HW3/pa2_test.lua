#!/usr/bin/env lua
-- pa2_test.lua
-- Glenn G. Chappell
-- 4 Feb 2018
--
-- For CS F331 / CSCE A331 Spring 2018
-- Test Program for Assignment 2 Functions
-- Used in Assignment 2, Exercise B

pa2 = require "pa2"  -- Import pa2 module


-- *********************************************
-- * YOU MAY WISH TO CHANGE THE FOLLOWING LINE *
-- *********************************************

EXIT_ON_FIRST_FAILURE = true
-- If EXIT_ON_FIRST_FAILURE is true, then this program exits after the
-- first failing test. If it is false, then this program executes all
-- tests, reporting success/failure for each.


-- *********************************************************************
-- Testing Package
-- *********************************************************************


tester = {}
tester.countTests = 0
tester.countPasses = 0

function tester.test(self, success, testName)
    self.countTests = self.countTests+1
    io.write("    Test: " .. testName .. " - ")
    if success then
        self.countPasses = self.countPasses+1
        io.write("passed")
    else
        io.write("********** FAILED **********")
    end
    io.write("\n")
end

function tester.allPassed(self)
    return self.countPasses == self.countTests
end


-- *********************************************************************
-- Utility Functions
-- *********************************************************************


function fail_exit()
    if EXIT_ON_FIRST_FAILURE then
        io.write("**************************************************\n")
        io.write("* This test program is configured to exit after  *\n")
        io.write("* the first failing test. To make it execute all *\n")
        io.write("* tests, reporting success/failure for each, set *\n")
        io.write("* variable                                       *\n")
        io.write("*                                                *\n")
        io.write("*   EXIT_ON_FIRST_FAILURE                        *\n")
        io.write("*                                                *\n")
        io.write("* to false, near the start of the test program.  *\n")
        io.write("**************************************************\n")

        -- Wait for user
        io.write("\nPress ENTER to quit ")
        io.read("*l")

        -- Terminate program
        os.exit(1)
    end
end


-- printTable
-- Given a table, prints it in (roughly) Lua literal notation. If
-- parameter is not a table, prints <not a table>.
function printTable(t)
    -- out
    -- Print parameter, surrounded by double quotes if it is a string,
    -- or simply an indication of its type, if it is not number, string,
    -- or boolean.
    local function out(p)
        if type(p) == "number" then
            io.write(p)
        elseif type(p) == "string" then
            io.write('"'..p..'"')
        elseif type(p) == "boolean" then
            if p then
                io.write("true")
            else
                io.write("false")
            end
        else
            io.write('<'..type(p)..'>')
        end
    end

    if type(t) ~= "table" then
        io.write("<not a table>")
    end

    io.write("{ ")
    local first = true  -- First iteration of loop?
    for k, v in pairs(t) do
        if first then
            first = false
        else
            io.write(", ")
        end
        io.write("[")
        out(k)
        io.write("]=")
        out(v)
    end
    io.write(" }")
end


-- printArray
-- Given a table, prints it in (roughly) Lua literal notation for an
-- array. If parameter is not a table, prints <not a table>.
function printArray(t)
    -- out
    -- Print parameter, surrounded by double quotes if it is a string.
    local function out(p)
        if type(p) == "string" then io.write('"') end
        io.write(p)
        if type(p) == "string" then io.write('"') end
    end

    if type(t) ~= "table" then
        io.write("<not a table>")
    end

    io.write("{ ")
    local first = true  -- First iteration of loop?
    for k, v in ipairs(t) do
        if first then
            first = false
        else
            io.write(", ")
        end
        out(v)
    end
    io.write(" }")
end


-- tableEq
-- Compare equality of two tables.
-- Uses "==" on table values. Returns false if either of t1 or t2 is not
-- a table.
function tableEq(t1, t2)
    -- Both params are tables?
    local type1, type2 = type(t1), type(t2)
    if type1 ~= "table" or type2 ~= "table" then
        return false
    end

    -- Get number of keys in t1 & check values in t1, t2 are equal
    local t1numkeys = 0
    for k, v in pairs(t1) do
        t1numkeys = t1numkeys + 1
        if t2[k] ~= v then
            return false
        end
    end

    -- Check number of keys in t1, t2 same
    local t2numkeys = 0
    for k, v in pairs(t2) do
        t2numkeys = t2numkeys + 1
    end
    return t1numkeys == t2numkeys
end


-- getCoroutineValues
-- Given coroutine f, returns array of all values yielded by f when
-- passed param as its parameter, in the order the values are yielded.
function getCoroutineValues(f, param)
    assert(type(f)=="function",
           "getCoroutineValues: f is not a function")
    local covals = {}  -- Array of values yielded by coroutine f
    local co = coroutine.create(f)
    local ok, value = coroutine.resume(co, param)
    while (coroutine.status(co) ~= "dead") do
        table.insert(covals, value)
        ok, value = coroutine.resume(co)
    end
    assert(ok, "Error in coroutine")
    return covals
end


-- *********************************************************************
-- Definitions for This Test Program
-- *********************************************************************


-- NONE


-- *********************************************************************
-- Test Suite Functions
-- *********************************************************************


function test_mapArray(t)
    local function test(t, f, inv, expect, msg)
        local outv = pa2.mapArray(f, inv)
        local success = tableEq(outv, expect)
        t:test(success, msg)
        if not success then
            io.write("Expect: ")
            printTable(expect)
            io.write("\n")
            io.write("Actual: ")
            printTable(outv)
            io.write("\n")
            io.write("\n")
            fail_exit()
        end
    end

    io.write("Test Suite: mapArray\n")

    local inv, expect

    local function id(x)
        return x
    end

    local function sq(n)
        return n*n
    end

    local function strlen(s)
        return s:len()
    end

    local function xs(n)
        retval = ""
        for i = 1, n do
            retval = retval .. "x"
        end
        return retval
    end

    local function is5(x)
        return x == 5
    end

    inv = { }
    expect = inv
    test(t, id, inv, expect, "empty array")

    inv = { 2 }
    expect = { 2 }
    test(t, id, inv, expect, "singleton array, #1")

    inv = { 2 }
    expect = { 4 }
    test(t, sq, inv, expect, "singleton array, #2")

    inv = { "abcd" }
    expect = { 4 }
    test(t, strlen, inv, expect, "singleton array, #3")

    inv = { 3 }
    expect = { "xxx" }
    test(t, xs, inv, expect, "singleton array, #4")

    inv = { 5 }
    expect = { true }
    test(t, is5, inv, expect, "singleton array, #5")

    inv = { true, 2, "xyz" }
    expect = inv
    test(t, id, inv, expect, "small array, #1")

    inv = { 20, -1, 37, 4321 }
    expect = { 400, 1, 1369, 18671041 }
    test(t, sq, inv, expect, "small array, #2")

    inv = { "My", "dog", "has", "globuliferous", "fleas" }
    expect = { 2, 3, 3, 13, 5 }
    test(t, strlen, inv, expect, "small array, #3")

    inv = { 10, 2, 1, 0 }
    expect = { "xxxxxxxxxx", "xx", "x", "" }
    test(t, xs, inv, expect, "small array, #4")

    inv = { 3, 5, "abc", true }
    expect = { false, true, false, false }
    test(t, is5, inv, expect, "small array, #5")

    inv = {}
    for i = 1, 10000 do
        table.insert(inv, 37)
        table.insert(inv, "abcd")
    end
    expect = inv
    test(t, id, inv, expect, "large array, #1")

    inv = {}
    expect = {}
    for i = 1, 10000 do
        table.insert(inv, 3)
        table.insert(expect, 9)
        table.insert(inv, -100)
        table.insert(expect, 10000)
    end
    test(t, sq, inv, expect, "large array, #2")

    inv = {}
    expect = {}
    for i = 1, 10000 do
        table.insert(inv, "x")
        table.insert(expect, 1)
        table.insert(inv, "This is a sentence." )
        table.insert(expect, 19)
    end
    test(t, strlen, inv, expect, "large array, #3")

    inv = {}
    expect = {}
    for i = 1, 10000 do
        table.insert(inv, 2)
        table.insert(expect, "xx")
        table.insert(inv, 5)
        table.insert(expect, "xxxxx")
    end
    test(t, xs, inv, expect, "large array, #4")

    inv = {}
    expect = {}
    for i = 1, 10000 do
        table.insert(inv, 5)
        table.insert(expect, true)
        table.insert(inv, "Howdy")
        table.insert(expect, false)
    end
    test(t, is5, inv, expect, "large array, #4")

end


function test_concatMax(t)
    local function test(t, ins, lim, expect, msg)
        local outs = pa2.concatMax(ins, lim)
        local success = outs == expect
        t:test(success, msg)
        if not success then
            io.write("Expect: "..expect.."\n")
            io.write("Actual: "..outs.."\n")
            io.write("\n")
            fail_exit()
        end
    end

    io.write("Test Suite: concatMax\n")

    local ins, expect

    ins = "a"
    expect = "aa"
    test(t, ins, 2, expect, "string of length 1, #1")
    expect = "aaaaaaaa"
    test(t, ins, 8, expect, "string of length 1, #2")
    expect = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
    test(t, ins, 40, expect, "string of length 1, #3")

    ins="abcdefghijklmnop"
    expect=""
    test(t, ins, 0, expect, "string of length 16, #1")
    test(t, ins, 7, expect, "string of length 16, #2")
    test(t, ins, 15, expect, "string of length 16, #3")
    expect = ins
    test(t, ins, 16, expect, "string of length 16, #4")
    expect=ins..ins..ins..ins
    test(t, ins, 70, expect, "string of length 16, #5")
    test(t, ins, 78, expect, "string of length 16, #6")
    test(t, ins, 79, expect, "string of length 16, #7")
    expect=ins..ins..ins..ins..ins
    test(t, ins, 80, expect, "string of length 16, #8")
    test(t, ins, 81, expect, "string of length 16, #9")
end


function test_collatz(t)
    local function test(t, inv, expect)
        local outv = getCoroutineValues(pa2.collatz, inv)
        local success = tableEq(outv, expect)
        t:test(success, "sequence starting at "..inv)
        if not success then
            io.write("Expect (yielded values): ")
            printArray(expect)
            io.write("\n")
            io.write("Actual (yielded values): ")
            printArray(outv)
            io.write("\n")
            io.write("\n")
            fail_exit()
        end
    end

    io.write("Test Suite: collatz\n")

    local inv, expect

    inv = 1
    expect = {1}
    test(t, inv, expect)

    inv = 2
    expect = {2,1}
    test(t, inv, expect)

    inv = 3
    expect = {3,10,5,16,8,4,2,1}
    test(t, inv, expect)

    inv = 4
    expect = {4,2,1}
    test(t, inv, expect)

    inv = 5
    expect = {5,16,8,4,2,1}
    test(t, inv, expect)

    inv = 9
    expect = {9,28,14,7,22,11,34,17,52,26,13,40,20,10,5,16,8,4,2,1}
    test(t, inv, expect)

    inv = 27
    expect = {27,82,41,124,62,31,94,47,142,71,214,107,322,161,484,242,
        121,364,182,91,274,137,412,206,103,310,155,466,233,700,350,175,
        526,263,790,395,1186,593,1780,890,445,1336,668,334,167,502,251,
        754,377,1132,566,283,850,425,1276,638,319,958,479,1438,719,2158,
        1079,3238,1619,4858,2429,7288,3644,1822,911,2734,1367,4102,2051,
        6154,3077,9232,4616,2308,1154,577,1732,866,433,1300,650,325,976,
        488,244,122,61,184,92,46,23,70,35,106,53,160,80,40,20,10,5,16,8,
        4,2,1}
    test(t, inv, expect)

    inv = 100
    expect = {100,50,25,76,38,19,58,29,88,44,22,11,34,17,52,26,13,40,20,
        10,5,16,8,4,2,1}
    test(t, inv, expect)
end


function test_pa2(t)
    io.write("TEST SUITES FOR CS F331 / CSCE A331 ASSIGNMENT 2\n")
    test_mapArray(t)
    test_concatMax(t)
    test_collatz(t)
end


-- *********************************************************************
-- Main Program
-- *********************************************************************


test_pa2(tester)
io.write("\n")
if tester:allPassed() then
    io.write("All tests successful\n")
else
    io.write("Tests ********** UNSUCCESSFUL **********\n")
    io.write("\n")
    io.write("**************************************************\n")
    io.write("* This test program is configured to execute all *\n")
    io.write("* tests, reporting success/failure for each. To  *\n")
    io.write("* make it exit after the first failing test, set *\n")
    io.write("* variable                                       *\n")
    io.write("*                                                *\n")
    io.write("*   EXIT_ON_FIRST_FAILURE                        *\n")
    io.write("*                                                *\n")
    io.write("* to true, near the start of the test program.   *\n")
    io.write("**************************************************\n")
end

-- Wait for user
io.write("\nPress ENTER to quit ")
io.read("*l")

