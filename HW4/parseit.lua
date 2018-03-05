-- parseit.lua
-- Samuel Grenon
-- 3/4/2018
-- Based on rdparser4 and assn4_code.txt

local parseit = {}

lexit = require "lexit"

-- For lexer iteration
local iter
local state
local lexer_out_s
local lexer_out_c

-- For current lexeme
local lexstr = ""
local lexcat = 0

-- Symbolic constants for AST
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
    end


-- Return true if pos has reached end of input.
-- Function init must be called before this function is called.
local function at_end()
	return lexcat == 0
end


-- Given string, see if current lexeme string form is equal to it. If
-- so, then advance to next lexeme & return true. If not, then do not
-- advance, return false.
-- Function init must be called before this function is called.	
local function matchString(s)
	if lexstr == s then
		if lexstr == ')' then
			lexit.preferOp()
		end
		advance()
        return true
    else
        return false
    end
end


-- Same as matchString, but for categories
local function matchCat(c)
	return lexcat == c
end


-- Initial call. Sets input for parsing functions.
local function init(prog)
    iter, state, lexer_out_s = lexit.lex(prog)
    advance()
end

function parseit.parse(prog)
    -- Initialization
    init(prog)

    -- Get results from parsing
    local good, ast = parse_program()  -- Parse start symbol
    local done = at_end()

    -- And return them
    return good, done, ast
end

-- parse_program
-- Parsing function for nonterminal "program".
-- Function init must be called before this function is called.
function parse_program()
	local good, ast
	good, ast = parse_stmt_list()
	return good, ast
end


-- Parsing function for nonterminal "stmt_list".
-- Function init must be called before this function is called.
function parse_stmt_list()
	local good, ast, ast2

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

		good, ast2 = parse_statement()
		if not good then
			return false, nil
		end

		table.insert(ast, ast2)
	end
	return good, ast
end


-- Handles call statements
function parse_call()
	local good, ast
	if matchCat(lexit.ID) then
		ast = { CALL_FUNC, lexstr }
		good = true
		advance()
	else
		good = false
	end
	return good, ast
end


-- Handles expressions
function parse_expr()
	local good, ast, ast2, old_lexstr

	good, ast = parse_comp_expr()

	while true do
		old_lexstr = lexstr
		if not matchString("&&") and not matchString("||") then
			break
		end
		good, ast2 = parse_comp_expr()
		if not good then
			return false, nil
		end
		ast = { { BIN_OP, old_lexstr }, ast, ast2 }
	end
	return good, ast
end


-- Handles comparison expressions
function parse_comp_expr()
	local good, ast, ast2, ast3
	if matchString('!') then
		good, ast = parse_comp_expr()
        if not good then
            return false, nil
        end
		ast = { { UN_OP, "!" }, ast}
		return true, ast
	end
	good, ast = parse_arith_expr()
	if not good then
		return false, nil
	end

	while true do
		local old_lexstr = lexstr
		if not matchString("==") 
		and not matchString("!=")
		and not matchString("<")
		and not matchString("<=")
		and not matchString(">")
		and not matchString(">=") then
			return good, ast
		else
			good, ast2 = parse_arith_expr()
			if not good then
				return false, nil
			end
			ast = { { BIN_OP, old_lexstr }, ast, ast2 }
		end
	end
	return good, ast
end


-- Handles arithmetic expressions
function parse_arith_expr()
	local good, ast, ast2, old_lexstr
	good, ast = parse_term()
	if not good then
		return false, nil
	end
	while true do
		old_lexstr = lexstr
		if not matchString('+') and not matchString('-') then
			break
		end
		
		good, ast2 = parse_term()
		if not good then
			return false, nil
		end
		ast = { { BIN_OP, old_lexstr }, ast, ast2 }
	end
	return true, ast
end


-- Handles terminals
function parse_term()
	local good, ast, ast2, old_lexstr
	good, ast = parse_factor()
	if not good then
		return false, nil
	end
	while true do
		old_lexstr = lexstr
		if not matchString('*')
		and not matchString('/')
		and not matchString('%') then
			break
		end

		good, ast2 = parse_factor()
		if not good then
			return false, nil
		end
		ast = { { BIN_OP, old_lexstr }, ast, ast2 }
	end
	return true, ast
end


-- Handles factors
function parse_factor()
	local good, ast, ast2, old_lexstr
	old_lexstr = lexstr
	if matchString('call') then
		return parse_call()
	elseif matchString('true') or matchString('false') then
		return true, { BOOLLIT_VAL, old_lexstr }
	elseif matchCat(lexit.NUMLIT) then
		lexit.preferOp()
		good = true
		ast = { NUMLIT_VAL, lexstr }
		advance()
	elseif matchString('+')
	or matchString('-')
	or matchString('%') then
		good, ast2 = parse_factor()
		if not good then
			return false, nil
		end
		ast = { {UN_OP, old_lexstr}, ast2 }
	elseif matchString('(') then
		good, ast = parse_expr()
		if not good or not matchString(')') then
			return false, nil
		end
	else
		good, ast = parse_lvalue() 
        if not good then
            return false, nil
        end
	end	
	return good, ast
end



-- Handles lvalues
function parse_lvalue()
	local good, ast
	if matchCat(lexit.ID) then
		lexit.preferOp()
		ast = { SIMPLE_VAR, lexstr }
		good = true
		advance()
		if matchString('[') then
			local good, ast2 = parse_expr()
			if not good then
				return false, nil
			end
			ast = { ARRAY_VAR, ast[2], ast2 }
			if not matchString(']') then
				return false, nil
			end
		end
	else
		good = false
	end
	return good, ast
end


-- Handles print arguments
function parse_print_arg()
	local good, ast
	if matchString('cr') then
		ast = { CR_OUT }
		good = true
	elseif matchCat(lexit.STRLIT) then
		ast = { STRLIT_OUT, lexstr }
		advance()
		good = true
	else
		good, ast = parse_expr()
		if not good then
			return false, nil
		end
		-- advance()
		good = true
	end
	return good, ast
end


-- Parsing function for nonterminal "statement"
-- Function init must be called before this function is called.
function parse_statement()
	local good, ast, ast2, old_lexstr

-- Input statements
	if matchString("input") then
		good, ast = parse_lvalue()
		return good, { INPUT_STMT, ast }

-- Call statements
	elseif matchString('call') then
		good, ast = parse_call()
		return good, ast

-- Print statements
	elseif matchString("print") then
		good, ast = parse_print_arg()
        if not good then
            return false, nil
        end

        ast2 = { PRINT_STMT, ast }

        while true do
            if not matchString(";") then
                break
			end

            good, ast = parse_print_arg()
            if not good then
                return false, nil
            end

            table.insert(ast2, ast)
		end
        return true, ast2

-- Func definitions
	elseif matchString("func") then
		local func_name
		if matchCat(lexit.ID) then
			func_name = lexstr
			advance()
		else
			return false, nil
		end
		good, ast2 = parse_stmt_list()
		if not good then
			return false, nil
		end
		good = matchString('end')
		ast = { FUNC_STMT, func_name, ast2 }
		return good, ast

-- While statements
	elseif matchString('while') then
		local expr, stmt_list
		good, expr = parse_expr()
		if not good then
			return false, nil
		end
		good, stmt_list = parse_stmt_list()
		if not good or not matchString('end') then
			return false, nil
		end
		ast = { WHILE_STMT, expr, stmt_list }
		return true, ast

-- If statements
	elseif matchString('if') then
		local expr, stmt_list
		good, expr = parse_expr()
		if not good then
			return false, nil
		end
		good, stmt_list = parse_stmt_list()
		if not good then
			return false, nil
		end
		ast = { IF_STMT, expr, stmt_list }
		while true do
			old_lexstr = lexstr
			if not matchString('elseif') then
				break
			end
			good, expr = parse_expr()
			if not good then
				return false, nil
			end
			good, stmt_list = parse_stmt_list()
			if not good then
				return false, nil
			end
			table.insert(ast, expr)
			table.insert(ast, stmt_list)
		end
		if matchString('else') then
			good, stmt_list = parse_stmt_list()
			if not good then
				return false, nil
			end
			table.insert(ast, stmt_list)
		end
		if not matchString('end') then
			return false, nil
		end
		return true, ast

	-- Handle assignments
	elseif matchCat(lexit.ID) then
		good, ast = parse_lvalue()
		if not good then
			return false, nil
		end
		if not matchString('=') then
			return false, nil
		end
		good, ast2 = parse_expr()
		if not good then
			return false, nil
		end
		ast = { ASSN_STMT, ast, ast2 }
		return true, ast

	-- Handle unknown cases
	else
		advance()
		return false, nil
	end
end

return parseit

