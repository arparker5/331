-- parseit.lua
-- Glenn G. Chappell
-- 16 Feb 2018
--
-- For CS F331 / CSCE A331 Spring 2018
-- Recursive-Descent Parser #4: Expressions + Better ASTs
-- Requires lexit.lua


-- Grammar
-- Start symbol: expr
--
--     expr    ->  term { ("+" | "-") term }
--     term    ->  factor { ("*" | "/") factor }
--     factor  ->  ID
--              |  NUMLIT
--              |  "(" expr ")"
--
-- All operators (+ - * /) are left-associative.
--
-- AST Specification
-- - For an ID, the AST is { SIMPLE_VAR, SS }, where SS is the string
--   form of the lexeme.
-- - For a NUMLIT, the AST is { NUMLIT_VAL, SS }, where SS is the string
--   form of the lexeme.
-- - For expr -> term, then AST for the expr is the AST for the term,
--   and similarly for term -> factor.
-- - Let X, Y be expressions with ASTs XT, YT, respectively.
--   - The AST for ( X ) is XT.
--   - The AST for X + Y is { { BIN_OP, "+" }, XT, YT }. For multiple
--     "+" operators, left-asociativity is reflected in the AST. And
--     similarly for the other operators.


local parseit = {}  -- Our module
lexit = require "lexit"


-- Variables

-- For lexit iteration
local iter          -- Iterator returned by lexit.lex
local state         -- State for above iterator (maybe not used)
local lexit_out_s   -- Return value #1 from above iterator
local lexit_out_c   -- Return value #2 from above iterator

-- For current lexeme
local lexstr = ""   -- String form of current lexeme
local lexcat = 0    -- Category of current lexeme:
                    --  one of categories below, or 0 for past the end


--- Symbolic Constants for AST

local STMT_LIST   = 1
local INPUT_STMT  = 2
local PRINT_STMT  = 3
local FUNC_STMT   = 4
local CALL_FUNC   = 5
local IF_STMT     = 6
local WHILE_STMT  = 7
local ASSN_STMT   = 8
local CR_OUT      = 9
local STRLIT_OUT  = 10
local BIN_OP      = 11
local UN_OP       = 12
local NUMLIT_VAL  = 13
local BOOLLIT_VAL = 14
local SIMPLE_VAR  = 15
local ARRAY_VAR   = 16



-- Utility Functions

-- advance
-- Go to next lexeme and load it into lexstr, lexcat.
-- Should be called once before any parsing is done.
-- Function init must be called before this function is called.
    local function advance()
        -- Advance the iterator
        lexit_out_s, lexit_out_c = iter(state, lexit_out_s)
    
        -- If we're not past the end, copy current lexeme into vars
        if lexit_out_s ~= nil then
            lexstr, lexcat = lexit_out_s, lexit_out_c
        else
            lexstr, lexcat = "", 0
        end
    
        if lexstr == ")" or lexstr == "]" or
        lexstr == "true" or lexstr == "false" or 
        lexcat == lexit.ID or lexcat == lexit.NUMLIT then
        lexit.preferOp()
        
      --  return true
      end   
    end
    
    
    -- init
    -- Initial call. Sets input for parsing functions.
    local function init(prog)
        iter, state, lexit_out_s = lexit.lex(prog)
        advance()
    end
    
    
    -- atEnd
    -- Return true if pos has reached end of input.
    -- Function init must be called before this function is called.
    local function atEnd()
        return lexcat == 0
    end
    
    
    -- matchString
    -- Given string, see if current lexeme string form is equal to it. If
    -- so, then advance to next lexeme & return true. If not, then do not
    -- advance, return false.
    -- Function init must be called before this function is called.
    local function matchString(s)
        if lexstr == s then
            advance()
            return true
        else
            return false
        end
    end
    
    -- matchCat
    -- Given lexeme category (integer), see if current lexeme category is
    -- equal to it. If so, then advance to next lexeme & return true. If
    -- not, then do not advance, return false.
    -- Function init must be called before this function is called.
    local function matchCat(c)
        if lexcat == c then
            advance()
            return true
        else
            return false
        end
    end
    
    
    -- Primary Function for Client Code
    
    -- parse
    -- Given program, initialize parser and call parsing function for start
    -- symbol. Returns pair of booleans & AST. First boolean indicates
    -- successful parse or not. Second boolean indicates whether the parser
    -- reached the end of the input or not. AST is only valid if first
    -- boolean is true.
    function parseit.parse(prog)
        -- Initialization
        init(prog)
    
        -- Get results from parsing
        local good, ast = parse_program()  -- Parse start symbol
        local done = atEnd()
        -- And return them
        return good, done, ast
    end
    
    
    -- Parsing Functions
    
    -- Each of the following is a parsing function for a nonterminal in the
    -- grammar. Each function parses the nonterminal in its name and returns
    -- a pair: boolean, AST. On a successul parse, the boolean is true, the
    -- AST is valid, and the current lexeme is just past the end of the
    -- string the nonterminal expanded into. Otherwise, the boolean is
    -- false, the AST is not valid, and no guarantees are made about the
    -- current lexeme. See the AST Specification near the beginning of this
    -- file for the format of the returned AST.
    
    -- NOTE. Do not declare parsing functions "local". This allows them to
    -- be called before their definitions.
    
    
    -- parse_expr
    -- Parsing function for nonterminal "expr".
    -- Function init must be called before this function is called.
    function parse_expr()
        local good, ast, saveop, newast
    
        good, ast = parse_term()
        if not good then
            return false, nil
        end
    
        while true do
            saveop = lexstr
            if not matchString("+") and not matchString("-") then
                break
            end
    
            good, newast = parse_term()
            if not good then
                return false, nil
            end
    
            ast = { { BIN_OP, saveop }, ast, newast }
        end
    
        return true, ast
    end
    
    
    -- parse_term
    -- Parsing function for nonterminal "term".
    -- Function init must be called before this function is called.
    function parse_term()
        local good, ast, saveop, newast
    
        good, ast = parse_factor()
        if not good then
            return false, nil
        end
    
        while true do
            saveop = lexstr
            if not matchString("*") and not matchString("/") then
                break
            end
    
            good, newast = parse_factor()
            if not good then
                return false, nil
            end
    
            ast = { { BIN_OP, saveop }, ast, newast }
        end
    
        return true, ast
    end
    
    
    -- parse_factor
    -- Parsing function for nonterminal "factor".
    -- Function init must be called before this function is called.
    function parse_factor()
        local savelex, good, ast
    
        savelex = lexstr
        if matchCat(lexit.ID) then
            return true, { SIMPLE_VAR, savelex }
        elseif matchCat(lexit.NUMLIT) then
            return true, { NUMLIT_VAL, savelex }
        elseif matchString("(") then
            good, ast = parse_expr()
            if not good then
                return false, nil
            end
    
            if not matchString(")") then
                return false, nil
            end
    
            return true, ast
        else
            return false, nil
        end
    end

-- parse_program
-- Parsing function for nonterminal "program".
-- Function init must be called before this function is called.

function parse_program()
    local good, ast
    good, ast = parse_stmt_list
    ()
    return good, ast
end

-- parse_stmt_list

-- Parsing function for nonterminal "stmt_list".

-- Function init must be called before this function is called.

function parse_stmt_list()
    local good, ast, newast
    ast = { STMT_LIST }
    while true do
        if lexstr ~= "input"
          and lexstr ~= "print"
          and lexstr ~= "func"
          and lexstr ~= "call"
          and lexstr ~= "if"
          and lexstr ~= "while"
          and lexcat ~= lexit.ID then
            return true, ast
        end
        good, newast = parse_statement()
        if not good then
            return false, nil
        end
        table.insert(ast, newast)
    end
    
end

-- parse_statement
-- Parsing function for nonterminal "statement"
-- Function init must be called before this function is called.

function parse_statement()
    local good, ast1, ast2, savelex
    if matchString("input") then
        good, ast1 = parse_lvalue()
        if not good then
            return false, nil
        end
        return true, { INPUT_STMT, ast1 }
    elseif matchString("print") then
        good, ast1 = parse_print_arg()
        if not good then
            return false, nil
        end
        ast2 = { PRINT_STMT, ast1 }
        while true do
            if not matchString(";") then
                break
            end
            good, ast1 = parse_print_arg()
            if not good then
                return false, nil
            end
            table.insert(ast2, ast1)
        end
        return true, ast2
  --  elseif matchString("func") then
  end
end

function parse_lvalue()
    local savelex, good, ast, newast
    savelex = lexstr
    if matchCat(lexit.ID) then
        ast = {SIMPLE_VAR, savelex}
        if not matchString("[") then
            return true, ast
        end
        good, newast = parse_expr()
        if not good then
            return false, nil
        end
        if not matchString("]") then
            return false, nil
        end
        return true, {ARRAY_VAR, ast, newast}
    end
    return false, nil
end

function parse_print_arg()
    local savelex, good, ast, newast
    savelex = lexstr
    if matchString(lexit.STRLIT) then
        ast = {STRLIT_OUT, savelex}
        return true, ast
    end

end

return parseit

