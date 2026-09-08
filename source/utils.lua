local love = require "love"

-- CLASS-RELATED FUNCTIONS

-- Creates an enum.
function enum(name, a)
    a = a or {}

    -- Compares against a string or enum.
    local is = function(self, id)
        return self.type == id or self == id
    end

    -- Parameters of things to compare to.
    local isAny = function(self, ...)
        for _, id in ... do
            if is(self, id) then
                return true
            end
        end
        return false
    end

    -- A list of things to compare to.
    local isAnyOf = function(self, ids)
        if is(self, ids) then
            return true
        end

        for _, id in ipairs(ids) do
            if is(self, id) then
                return true
            end
        end
        return false
    end

    local empty = true
    for _, _ in pairs(a) do
        empty = false
        break
    end

    if empty then
        local result = { type = name }
        result.is = is
        result.isAny = isAny
        result.isAnyOf = isAnyOf
        return result
    else
        return function(config)
            local result = { type = name }
            for key, value in pairs(a) do result[key] = value end
            for key, value in pairs(config) do result[key] = value end
            result.is = is
            return result
        end
    end
end

-- Converts a table of enums into actual enums.
-- This is the function you should generally use when creating enums.
function enumerate(table)
    for key, value in pairs(table) do
        table[key] = enum(key, value)
    end
    return table
end

-- Alternate version of `enumerate()` which internally keeps the order.
-- Useful for Cell as we need them to be sorted by type sometimes.
function orderedEnum(table)
    for i, value in ipairs(table) do
        table[value] = enum(value)
        table[value].index = i
    end
    return table
end

-- Binds a prototype table to another table, acting as a fallback for indexing
function bindPrototype(object, prototype)
    local mt = {}
    mt.__index = function(table, key)
        return prototype[key]
    end

    setmetatable(object, mt)
end

-- BASIC UTIL FUNCTIONS

function pointInRect(x, y, rx, ry, rw, rh)
    return x >= rx and y >= ry and x <= rx + rw and y <= ry + rh
end

function elem(t, item)
    for _, i in ipairs(t) do
        if i == item then return true end
    end
    return false
end

function indexOf(t, item)
    for k, i in ipairs(t) do
        if i == item then return k end
    end
    return -1
end

function append(t1, t2)
    for _, i in ipairs(t2) do
        table.insert(t1, i)
    end
end

function invert(t1)
    local t2 = {}
    for k, v in pairs(t1) do
        t2[v] = k
    end
    -- debugPrint('[INVERT] FROM', t1, 'TO', t2)
    return t2
end

function lerp(from, to, i)
    return from + (to - from) * i
end

function shallow(value)
    if type(value) == "table" then
        local newTable = {}
        for k, v in pairs(value) do
            newTable[k] = v
        end
        return newTable
    else
        return value
    end
end

function clone(value)
    if type(value) == "table" then
        local newTable = {}
        for k, v in pairs(value) do
            newTable[k] = clone(v)
        end
        return newTable
    else
        return value
    end
end

function cloneUnitTables(value)
    if type(value) == "table" then
        local newTable = {}
        local isEmpty = true
        for k, v in pairs(value) do
            isEmpty = false
            newTable[k] = cloneUnitTables(v)
        end

        if isEmpty then
            return value
        else
            return newTable
        end
    else
        return value
    end
end

function allWithPredicate(list, predicate)
    -- imperative under the hood, but we hide it under a functional wrapper
    -- kinda neat
    local found = {}

    for _, value in ipairs(list) do
        if predicate(value) then
            table.insert(found, value)
        end
    end

    return found
end

-- borrowed from https://stackoverflow.com/questions/9168058/how-to-dump-a-table-to-console
function dump(o, depth)
    if depth == -1 then return '...' end
    if type(o) == 'table' then
        local s = '{ '
        local didsomething = false
        for k,v in pairs(o) do
            -- if type(k) ~= 'number' then k = dump(k) end
            s = s .. '['..dump(k)..'] = ' .. dump(v, depth and (depth - 1) or nil) .. ', '
            didsomething = true
        end
        return (didsomething and string.sub(s, 1, -3) or s) .. ' }'
    elseif type(o) == 'string' then
        return '"' .. o .. '"'
    elseif o == nil then
        return 'nil'
    else
        return tostring(o)
    end
end

-- Source - https://stackoverflow.com/a/25449599
-- Posted by Diego Pino, modified by community. See post 'Timeline' for change history
-- Retrieved 2026-09-04, License - CC BY-SA 3.0
-- Source - https://stackoverflow.com/a/20100401
-- Posted by Ivo
-- Retrieved 2026-09-04, License - CC BY-SA 3.0
function string.split(str, sep)
    local result = {}
    for match in (str..sep):gmatch("(.-)"..sep) do
        table.insert(result, match)
    end
    return result
end

-- GRAPHICS

-- ripped from the wiki lmao (except now it draws and rotates about the center)
function drawRotatedRectangle(mode, x, y, width, height, angle)
    love.graphics.push()
    love.graphics.translate(x, y)
    love.graphics.rotate(angle or 0)
    love.graphics.rectangle(mode, -width/2, -height/2, width, height)
    love.graphics.pop()
end

-- not ripped from the wiki lmao
function drawCenteredRectangle(mode, x, y, width, height)
    love.graphics.push()
    love.graphics.translate(x, y)
    love.graphics.rectangle(mode, -width / 2, -height / 2, width, height)
    love.graphics.pop()
end

function needsImplementation(str)
    return function()
        error("Unimplemented error! Message: " .. str)
    end
end

function cosh(x)
    return (math.exp(x) + math.exp(-x)) / 2
end

-- Because LOVE2D uses the deprecated function for some reason

if table.unpack == nil then
    table.unpack = unpack
end

if unpack == nil then
    unpack = table.unpack
end

-- DEBUGGING

function debugPrint(...)
    local string = ''

    for _, str in ipairs({ ... }) do
        if type(str) == 'string' then string = string .. str .. ' '
        else string = string .. dump(str) .. ' ' end
    end

    print(string)
end


function depthPrint(depth, ...)
    local string = ''

    for _, str in ipairs({ ... }) do
        if type(str) == 'string' then string = string .. str .. ' '
        else string = string .. dump(str, depth) .. ' ' end
    end

    print(string)
end

function clamp(min, value, max)
    return math.min(max, math.max(value, min))
end
