if JSONParser ~= nil then return JSONParser end
local utf8 = require "utf8"
local love = require "love"
JSONParser, JSONEncoder = {}, {}

local ESCAPES = {
    ["n"] = "\n",
    ["t"] = "\t",
    ["\\"] = "\\",
    ["\""] = "\"",
    ["\'"] = "\'",
}

function JSONParser.new(source, replacement)
    return {
        source = source,
        byte = 1,
        error = "",
        replacement = replacement or {}
    }
end

function JSONParser.char(parser)
    if parser.byte <= #parser.source then
        local rest = string.sub(parser.source, parser.byte)
        local offset = utf8.offset(rest, 2) - 1
        local character = string.sub(parser.source, parser.byte, parser.byte + offset - 1)
        return character, offset
    end
end

function JSONParser.next(parser)
    local c, offset = JSONParser.char(parser)
    if c == nil then return nil end

    parser.byte = parser.byte + offset
    return c
end

function JSONParser.skipWhitespace(parser)
    while (JSONParser.char(parser)) ~= nil and string.match((JSONParser.char(parser)), "%s") do
        JSONParser.next(parser)
    end

    while string.sub(parser.source, parser.byte, parser.byte + 1) == "//" do
        JSONParser.next(parser)
        JSONParser.next(parser)
        while (JSONParser.char(parser)) ~= nil and (JSONParser.char(parser)) ~= "\n" do
            JSONParser.next(parser)
        end
        while (JSONParser.char(parser)) ~= nil and string.match((JSONParser.char(parser)), "%s") do
            JSONParser.next(parser)
        end
    end
end

function JSONParser.error(parser, message)
    local line = 1
    local column = 1
    local pos = 1
    while pos < parser.byte do
        if string.sub(parser.source, pos, pos) == "\n" then
            line = line + 1
            column = 0
        end
        column = column + 1
        pos = pos + 1
    end
    parser.error = "[error at line " .. tostring(line) .. ", column " .. tostring(column) .. "]: " .. message
end

function JSONParser.peek(parser)
    JSONParser.skipWhitespace(parser)
    return JSONParser.char(parser)
end

function JSONParser.advance(parser)
    JSONParser.skipWhitespace(parser)
    return JSONParser.next(parser)
end

function JSONParser.onlyAdvanceIf(parser, c)
    local found = JSONParser.peek(parser)
    if found == nil then
        JSONParser.error(parser, "found end of file")
        return false
    end
    if found == c then
        JSONParser.next(parser)
        return true, true
    else
        return true, false
    end
end

function JSONParser.expectCharacter(parser, expect)
    local c = JSONParser.advance(parser)
    if c == expect then
        return true
    else
        local found = c or "end of file"
        JSONParser.error(parser, "expected " .. expect .. ", but found " .. found)
        return false
    end
end

function JSONParser.parse(source, replacement)
    if type(source) ~= "string" then
        return '[did not pass a string to the parser]', false
    end

    local parser = JSONParser.new(source, replacement)
    local success, value = JSONParser.parseValue(parser)
    if success == false then
        value = parser.error
    end
    return value, success
end

function JSONParser.parseValue(parser)
    local c = JSONParser.advance(parser)
    if c == nil then
        JSONParser.error(parser, "expected value, but found end of file")
        return false
    end

    if string.match(c, "%a") then
        local success, value = JSONParser.parseAlphabeticLiteral(parser, c)
        return success, value
    elseif string.match(c, "[%d%.]") then
        local success, value = JSONParser.parseNumber(parser, c)
        return success, value
    elseif c == "\"" then
        local success, value = JSONParser.parseString(parser)
        return success, value
    elseif c == "{" then
        local success, value = JSONParser.parseObject(parser)
        return success, value
    elseif c == "[" then
        local success, value = JSONParser.parseArray(parser)
        return success, value
    end

    JSONParser.error(parser, "expected value, but found " .. c)
    return false
end

function JSONParser.parseNumber(parser, start)
    local s = start == "." and "0." or start

    while (JSONParser.char(parser)) ~= nil and string.match((JSONParser.char(parser)), "%d") do
        local c = JSONParser.next(parser)
        s = s .. c
    end

    local _, dot = JSONParser.onlyAdvanceIf(parser, ".")

    if dot then
        s = s .. "."
        while (JSONParser.char(parser)) ~= nil and string.match((JSONParser.char(parser)), "%d") do
            local c = JSONParser.next(parser)
            s = s .. c
        end
        if string.sub(s, #s, #s) == "." then
            s = s .. "0"
        end
    end

    return true, tonumber(s)
end

function JSONParser.parseAlphabeticLiteral(parser, start)
    local s = start

    while(JSONParser.char(parser)) ~= nil and string.match((JSONParser.char(parser)), "%a") do
        local c = JSONParser.next(parser)
        s = s .. c
    end

    if s == "null" then
        return true, nil
    elseif s == "true" then
        return true, true
    elseif s == "false" then
        return true, false
    elseif parser.replacement[s] then
        return true, parser.replacement[s]
    end

    JSONParser.error(parser, "invalid alphabetic literal `" .. s .. "`")
    return false
end

function JSONParser.parseString(parser)
    local s = ""

    while (JSONParser.char(parser)) ~= nil and (JSONParser.char(parser)) ~= "\"" do
        local c = JSONParser.next(parser)
        if c == "\\" then
            local escape = JSONParser.next(parser)
            if escape == nil then
                JSONParser.error(parser, "no escape character")
                return false
            end

            c = ESCAPES[escape]
        end
        s = s .. c
    end

    JSONParser.next(parser)
    return true, s
end

function JSONParser.parseArray(parser)
    local array = {}
    local position = 1

    while true do
        local success, final = JSONParser.onlyAdvanceIf(parser, "]")
        if success == false then
            JSONParser.error(parser, "unclosed array")
            return false
        end
        if final then break end

        local success, value = JSONParser.parseValue(parser)
        if success == false then return false end

        if value ~= nil then
            array[position] = value
        end
        position = position + 1

        local success, comma = JSONParser.onlyAdvanceIf(parser, ",")
        if not comma then
            local success = JSONParser.expectCharacter(parser, "]")
            if success == false then
                JSONParser.error(parser, "unclosed array")
                return false
            end
            break
        end
    end
    return true, array
end

function JSONParser.parseObject(parser)
    local dict = {}

    while true do
        local success, finalBrace = JSONParser.onlyAdvanceIf(parser, "}")
        if success == false then
            JSONParser.error(parser, "unclosed object")
            return false
        end
        if finalBrace then break end

        local success, key = JSONParser.parseValue(parser)
        if success == false then return false end

        local success = JSONParser.expectCharacter(parser, ":")
        if success == false then return false end

        local success, value = JSONParser.parseValue(parser)
        if success == false then return false end

        if key ~= nil then
            dict[key] = value
        else
            JSONParser.error(parser, "attempt to use `null` as a object key")
            return false
        end

        local success, comma = JSONParser.onlyAdvanceIf(parser, ",")
        if not comma then
            local success = JSONParser.expectCharacter(parser, "}")
            if success == false then
                JSONParser.error(parser, "unclosed object")
                return false
            end
            break
        end
    end
    return true, dict
end

function JSONEncoder.new(tab, replacement, sort --[[, objectByDefault]])
    if tab == nil then tab = '\t' end
    local comma, newline, space = ',\n', '\n', ' '

    if not tab then
        comma = ','
        space = ''
        newline = ''
    elseif love.system.getOS() == "Windows" then
        comma = ',\r\n'
        newline = '\r\n'
    end

    local keySort = {}
    for i, sortTable in ipairs(sort or {}) do
        local subsort = {}
        for i, v in ipairs(sortTable or {}) do
            subsort[v] = i
        end
        keySort[i] = subsort
    end

    return {
        tab = tab,
        comma = comma,
        space = space,
        newline = newline,
        replacement = replacement or {},
        sort = keySort,
        depth = 1
    }
end

function JSONEncoder.encode(obj, tab, replacement, sort)
    local encoder = JSONEncoder.new(tab, replacement, sort)
    local json = JSONEncoder.encodeValues(encoder, obj)
    return json
end

-- borrowed from https://stackoverflow.com/questions/9168058/how-to-dump-a-table-to-console
function JSONEncoder.encodeValues(encoder, obj)
    if obj == nil then
        return 'null'
    elseif encoder.replacement[obj] ~= nil then
        return JSONEncoder.encodeValues(encoder, encoder.replacement[obj])
    elseif type(obj) == 'table' then
        local stringifiedObj = {}
        local stringifiedArr = {}

        local tab = string.rep(encoder.tab, encoder.depth)
        local tabLower = string.rep(encoder.tab, encoder.depth - 1)
        encoder.depth = encoder.depth + 1

        local isObj = false
        local elements = 0
        for key, value in pairs(obj) do
            if type(key) ~= "number" then
                isObj = true
            end

            elements = elements + 1 -- doesn't need to be set in array case but oh well

            local encoded = JSONEncoder.encodeValues(encoder, value)
            stringifiedArr[key] = encoded
            table.insert(stringifiedObj,
                {
                    key = key,
                    value = encoded
                }
            )
            -- debugPrint('[JSON] encoding', key .. ':', stringified[key])
        end

        encoder.depth = encoder.depth - 1
        if isObj then
            local s = '{' .. encoder.newline .. tab
            local sortTable = encoder.sort[encoder.depth] or {}
            table.sort(stringifiedObj, function(a1, b1)
                local a2, b2 = a1.key, b1.key
                if sortTable[a2] and sortTable[b2] then
                    return sortTable[a2] < sortTable[b2]
                elseif sortTable[a2] then
                    return false  -- a < b
                elseif sortTable[b2] then
                    return true -- a > b
                end
                return a2 > b2
            end)

            local i = 0;
            for _, v in ipairs(stringifiedObj) do
                i = i + 1
                s = s .. JSONEncoder.encodeValues(encoder, v.key) .. ":" .. encoder.space .. v.value

                if i ~= elements then
                    s = s .. encoder.comma .. tab
                end
            end

            return s .. encoder.newline .. tabLower .. '}'
        else
            return '[' .. encoder.newline .. tab .. table.concat(stringifiedArr, encoder.comma .. tab) .. encoder.newline .. tabLower .. ']'
        end
    elseif type(obj) == 'string' then
        local s = obj
        for raw, real in pairs(ESCAPES) do
            s = string.gsub(s, real, "\\" .. raw)
        end
        return '"' .. s .. '"'
    else
        return tostring(obj)
    end
end

return JSONParser, JSONEncoder
