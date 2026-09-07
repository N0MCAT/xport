if Levels ~= nil then return Levels end

local love = require "love"
require "source.data.json"
require "source.data.saves"
require "source.data.locale"
require "source.play.cell"

Levels = {
    order = {}, -- Levels flattened in order (globals.levels)
    plain = {}, -- Levels flattened e.g. 'demoworld/1-dejavu'
    areas = {}, -- Levels organized by areas e.g. 'demoworld.levels['1-dejavu']'

    clears = {}
}

function Levels.getDimensionFromGrid(grid)
    local yesyes = string.split(grid, '\n')
    return #(yesyes[1]), #yesyes
end

local function validateLevel(result)
    if type(result) ~= "table" then return false end
    if type(result.cells) ~= "table" then return false end

    if type(result.width) ~= "number" or type(result.height) ~= "number" then
        return false
    end

    return true
end

function Levels.encodeLevelFromFile(area, id, content)
    local result, success = JSONParser.parse(content)
    result = result or {} -- calm down zed...???

    if not success or not validateLevel(result) then
        debugPrint("[LEVELS] Couldn't encode", area .. "/" .. id .. ", trying legacy format...")
        result = Levels.convertLegacyData(area, id, content)
        if result == nil or not validateLevel(result) then
            debugPrint("[LEVELS] Failed to validate", area .. "/" .. id .. ", so we ignore it")
            return nil
        end
    end

    result.area = area
    result.id = id

    local start, finish = string.find(result.title, " %- ")
    if start == nil then start, finish = 0, 0 end
    result.number = string.sub(result.title, 1, start - 1)
    result.title = string.sub(result.title, finish + 1)

    return result
end

function Levels.convertLegacyData(area, id, content)
    if type(content) ~= "string" then return nil end
    content = string.gsub(content, "\r\n", "\n")
    local rawData = string.split(content, '\n\n')
    local thingy = string.find(rawData[1], '\n') -- well-named variable

    if #rawData < 2 then
        debugPrint("[LEVELS] Couldn't encode legacy", area .. "/" .. id .. ", so we ignore it")
        return nil
    end

    local title = string.sub(rawData[1], 0, thingy and (thingy - 1) or #rawData[1])
    local start, finish = string.find(title, " %- ")
    if start == nil or finish == nil then
        start = 0
        finish = 0
    end

    local result = {
        title = title or '',
        subtitle = thingy and string.sub(rawData[1], thingy + 1) or '',
        cells = {}
    }

    local curIndex = 3
    local grid = { rawData[2] }
    result.width, result.height = Levels.getDimensionFromGrid(rawData[2])
    -- debugPrint("[LEVELS] Grid dimensions:", cX, cY)

    while true do
        if (curIndex) > #rawData then break end
        local gridCheck = rawData[curIndex]
        -- debugPrint("[LEVELS] Checking grid", curIndex)

        local x, y = Levels.getDimensionFromGrid(gridCheck)
        -- debugPrint("[LEVELS] Comparing grid dimensions:", cX2, cY2)
        if result.width ~= x or result.height ~= y or #rawData[2] ~= #gridCheck then break end

        grid[#grid + 1] = gridCheck
        curIndex = curIndex + 1
    end

    local x, y = 0, 0
    for line in string.gmatch(grid[1], "[^\n]+") do
        local trimmedLine = string.gsub(line, "%s+", "")
        if trimmedLine == "" then
            break
        end
        x = 0
        for character in string.gmatch(trimmedLine, ".") do
            if character ~= "." then
                table.insert(result.cells, Cell.fromLegacyChar(x, y, character))
            end
            x = x + 1
        end
        y = y + 1
    end

    local findCells = function (cells, x, y)
        return allWithPredicate(cells, function(cell)
            return cell.x == x and cell.y == y
        end)
    end

    y = 0
    for line in string.gmatch(grid[2], "[^\n]+") do
        local trimmedLine = string.gsub(line, "%s+", "")
        if trimmedLine == "" then
            break
        end
        x = 0
        for character in string.gmatch(trimmedLine, ".") do
            if string.match(character, "[#.]") then
            elseif string.match(character, "%d") then
                local r
                for _, cell in ipairs(findCells(result.cells, x, y)) do
                    if cell.region ~= nil then
                        r = cell.region
                    end
                end
                table.insert(result.cells, Cell.makeData(x, y, Cell.Origin, r))
                table.insert(result.cells, Cell.makeData(x, y, Cell.Timer, r, tonumber(character)))
            end
            x = x + 1
        end
        y = y + 1
    end

    y = 0
    for line in string.gmatch(grid[3], "[^\n]+") do
        local trimmedLine = string.gsub(line, "%s+", "")
        if trimmedLine == "" then
            break
        end
        x = 0
        for character in string.gmatch(trimmedLine, ".") do
            if string.match(character, "[#.]") then
            elseif string.match(character, "G") then
                table.insert(result.cells, Cell.makeData(x, y, Cell.Goal))
            end
            x = x + 1
        end
        y = y + 1
    end

    if rawData[curIndex] ~= nil then
        local thingy2 = string.find(rawData[curIndex], '\n') -- well-named variable 2
        result.palette = string.sub(rawData[curIndex], 0, thingy2 - 1)
        result.musicID = string.sub(rawData[curIndex], thingy2 + 1)
    else
        result.musicID = 'undefined'
    end

    local jsonencode = JSONEncoder.encode(result, '  ', ICell, {
        {"title", "subtitle", "palette", "musicID", "cells"}
    })
    love.filesystem.write(id .. '.xjson', jsonencode)

    -- debugPrint("[LEVELS] Decoding legacy, with resultant: ", result)
    return result
end

function Levels.loadData()
    globals.levels = {}
    Levels.order = globals.levels
    local levelClears = Save.readFile('levelClears.xjson', {}) or {} -- the or isnt necessary but zed doesnt realize that
    debugPrint(levelClears)

    for k, _ in pairs(Levels.order) do Levels.order[k] = nil end
    for k, _ in pairs(Levels.plain) do Levels.plain[k] = nil end
    for k, _ in pairs(Levels.areas) do Levels.areas[k] = nil end

    local areaFolders = love.filesystem.getDirectoryItems("areas")
    debugPrint("[LEVELS]", areaFolders)

    for _, areakey in ipairs(areaFolders) do
        local areadir = "areas/" .. areakey
        -- debugPrint('[LEVELS] Parsing lobby "' .. areakey .. '/lobby",', levelClears[areakey .. '/lobby'])
        Levels.clears[areakey .. '/lobby'] = levelClears[areakey .. '/lobby'] or false
        Levels.areas[areakey] = {
            lobby = Levels.encodeLevelFromFile(areakey, 'lobby', love.filesystem.read(areadir .. '/lobby.xjson') or love.filesystem.read(areadir .. '/lobby.xlvl')),
            levels = {}
        }

        local levelfiles = love.filesystem.getDirectoryItems(areadir .. '/levels')
        table.sort(levelfiles, function(a, b)
            local numIndex1 = string.find(a, "([0-9]+)")
            local numIndex2 = string.find(b, "([0-9]+)")

            if numIndex1 ~= nil and numIndex2 ~= nil and numIndex1 ~= numIndex2 then
                return numIndex1 < numIndex2
            end

            local isNum1, isNum2 = tonumber(string.match(a, "([0-9]+)")), tonumber(string.match(b, "([0-9]+)"))
            if isNum1 ~= nil and isNum2 == nil then return true end
            if isNum2 ~= nil and isNum1 == nil then return false end
            if isNum1 ~= isNum2 then
                return isNum1 < isNum2
            end

            return a < b
        end)

        for _, levelfile in ipairs(levelfiles) do
            local levelID = string.gsub(string.gsub(levelfile, ".xjson", ""), ".xlvl", "")
            local fileContents = love.filesystem.read(areadir .. '/levels/' .. levelfile)

            -- debugPrint('[LEVELS] Parsing level "'.. areakey .. '/' .. levelID .. '",', levelClears[areakey .. '/' .. levelID])
            local resultLevel = Levels.encodeLevelFromFile(areakey, levelID, fileContents)

            Levels.clears[areakey .. '/' .. levelID] = levelClears[areakey .. '/' .. levelID] or false

            Levels.order[#Levels.order + 1] = resultLevel
            Levels.plain[areakey .. '/' .. levelID] = resultLevel
            Levels.areas[areakey].levels[levelID] = resultLevel
            Levels.areas[areakey].levels[#Levels.areas[areakey].levels + 1] = resultLevel

            -- depthPrint(2, '[LEVELS] Result:', Levels.areas)
        end
    end
end

function Levels.localizeText(text)
end

return Levels
