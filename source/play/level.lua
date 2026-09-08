if Level ~= nil then return Level end
local love = require "love"
require "source.data.levels"

require "source.graphics.palette"
require "source.graphics.anim"
require "source.graphics.particles"

require "source.play.cell"
require "source.sounds"

Level = {}

Direction = {
    Up = {},
    Down = {},
    Left = {},
    Right = {}
}

Event = {
    Move = {},
    TimerChange = {},
    Teleport = {}, -- (i think this could just be part of Move but also maybe it might be useful to separate it)
    -- future miney here: yeah it's definitely better to separate it
    OriginMove = {},
    Reset = {}
}

-- maybe move these three to a "util.lua"?
-- answer: only one goes (wee)
local function findCells(cells, x, y)
    -- stinky imperative programming   ewwww
    -- [code removed because of how horrifying it looked]

    -- functional programming lets goooooo
    return allWithPredicate(cells, function(cell)
        return cell.x == x and cell.y == y
    end)
end

local function movableWithRegion(cells, types, region)
    return allWithPredicate(cells, function(cell)
        local typeCheck, regionCheck = cell.cell ~= Cell.Origin, true
        if types then typeCheck = cell.cell:isAnyOf(types) end
        if region then regionCheck = cell.region == region end
        return typeCheck and regionCheck
    end)
end

function Level.isInBounds(level, x, y)
    return x >= 0 and y >= 0 and x < level.width and y < level.height
end

function Level.new(id, area, width, height, cells, palette, musicID, number, title, subtitle)
    -- Sort the table for extra rendering scrutiny and consistency.
    -- Maybe this shouldn't be necessary, buuut...
    table.sort(cells, function(a, b)
        if a.cell.index == b.cell.index then
            if a.x == b.x then
                return a.y < b.y
            end
            return a.x < b.x
        end
        return a.cell.index < b.cell.index
    end)

    local result = {
        id = id,
        area = area,

        x = 0,
        y = 0,

        width = width,
        height = height,
        scale = 1,

        cells = cells,
        palette = palette and require('areas.' .. string.gsub(palette, '/', '.palettes.')) or Palette.defaultList(),
        musicID = musicID or 'undefined',
        winning = false,

        eventLog = {},
        goalPlaying = false,

        number = number,
        title = title,
        subtitle = subtitle,
    }

    bindPrototype(result, Level)
    return result
end

function Level.fromData(levelData)
    local cells = {}
    for i, cell in ipairs(levelData.cells) do
        cells[i] = Cell.new(cell.x, cell.y, i, Cell[cell.type], cell.region, cell.val)
    end

    return Level.new(levelData.id, levelData.area, levelData.width, levelData.height, cells,
        levelData.palette, levelData.musicID, levelData.number, levelData.title, levelData.subtitle)
end

function Level.update(level, dt)
    for _, cell in ipairs(level.cells) do
        if cell.animTime < 1 then
            cell.animTime = math.min(1, cell.animTime + dt / DEBUG.AnimationTime)
        elseif cell.cell == Cell.Origin then
            cell.animTime = cell.animTime + dt / (DEBUG.AnimationTime * 25)
            if cell.animTime >= 2 then cell.animTime = cell.animTime - 1 end
            -- checking if >=2 here cause for some reason it becomes 10x slower if it's >=1 ??? either way this animation works modulo 1 so it doesn't matter
        end
    end
end

function Level.draw(level, layers)
    love.graphics.push()
    love.graphics.translate((state.width - level.width * level.scale) / 2,
        (state.height - level.height * level.scale) / 2)

    love.graphics.setBackgroundColor(level.palette.background())
    love.graphics.setColor(level.palette.levelStroke())
    love.graphics.setLineWidth(5)
    love.graphics.rectangle("line", 0, 0, level.scale * level.width, level.scale * level.height)
    love.graphics.setLineWidth(1)

    love.graphics.setColor(level.palette.levelFill())
    love.graphics.rectangle("fill", 0, 0, level.scale * level.width, level.scale * level.height)
    love.graphics.setColor(1, 1, 1)

    for _, cell in ipairs(level.cells) do
        cell:draw(level, layers)
    end
    love.graphics.pop()
end

-- modified so that it returns nil when out of bounds instead of saturating
local function applyDirection(level, cell, direction)
    Cell.startMoveAnim(cell)
    if direction == Direction.Up then
        if cell.y <= 0 then return nil, nil end
        return cell.x, cell.y - 1
    elseif direction == Direction.Down then
        if cell.y >= level.height - 1 then return nil, nil end
        return cell.x, cell.y + 1
    elseif direction == Direction.Left then
        if cell.x <= 0 then return nil, nil end
        return cell.x - 1, cell.y
    elseif direction == Direction.Right then
        if cell.x >= level.width - 1 then return nil, nil end
        return cell.x + 1, cell.y
    end
end

local function moveCells(level, agentTypes, agentRegion, direction)
    local pending = movableWithRegion(level.cells, agentTypes, agentRegion)
    local addedregions = { agentRegion }
    local events = {}
    local timers = {}
    local moves = {}

    while #pending ~= 0 do
        local c = table.remove(pending)

        if c.cell == Cell.Timer then
            table.insert(timers, c)
        end

        local nx, ny = applyDirection(level, c, direction)

        if not (nx and ny) then
            return {}
        end -- something moved out of bounds, abort
        local ncells = findCells(level.cells, nx, ny)
        for _, ncell in ipairs(ncells) do
            if ncell.cell == Cell.Wall then
                return {} -- something moved into a wall, abort
            elseif ncell.cell == Cell.Box or ncell.cell == Cell.Timer then
                if not elem(addedregions, ncell.region) then
                    append(pending, movableWithRegion(level.cells, nil, ncell.region))
                    table.insert(addedregions, ncell.region)
                end
            end
        end

        table.insert(moves, {
            type = Event.Move,
            from_x = c.x,
            from_y = c.y,
            to_x = nx,
            to_y = ny,
            cell = c
        })

    end

    if #moves > 0 then
        for _, timer in ipairs(timers) do
            if timer.val > 0 then
                local timer_change = {
                    type = Event.TimerChange,
                    cell = timer,
                    from_val = timer.val,
                    to_val = timer.val - 1
                }
                table.insert(events, timer_change)
            else
                local movable = true
                local origin = allWithPredicate(level.cells, function (cell)
                    return cell.cell == Cell.Origin and cell.region == timer.region
                end)[1] -- if this ever throws an index error then we quit gamedev forever

                local nx, ny = applyDirection(level, origin, direction)
                if not (nx and ny) then movable = false end
                if movable then
                    -- origin moves moved here
                    local origin_move = {
                        type = Event.OriginMove,
                        from_x = origin.x,
                        from_y = origin.y,
                        to_x = nx,
                        to_y = ny,
                        cell = origin
                    }
                    table.insert(events, origin_move)
                end
            end
        end
    end

    append(events, moves)

    return events
end

local function handleTeleports(level, direction)
    local events = {}

    local zerotimers = allWithPredicate(level.cells, function(cell)
        return cell.cell == Cell.Timer and cell.val == 0 and cell.default_val ~= 0
    end)
    for _, timer in ipairs(zerotimers) do
        -- print("here", timer.region)
        local origin = allWithPredicate(level.cells, function (cell)
            return cell.cell == Cell.Origin and cell.region == timer.region
        end)[1] -- if this ever throws an index error then we quit gamedev forever
        local boxes = allWithPredicate(level.cells, function (cell)
            return (cell.cell == Cell.Box or cell.cell == Cell.Player) and cell.region == timer.region
        end)
        local blocked = false
        for _, box in ipairs(boxes) do
            if not Level.isInBounds(level, box.x - timer.x + origin.x, box.y - timer.y + origin.y) then
                -- print("oops out of bounds")
                blocked = true
                break -- this one is my fault though
            end

            local targets = findCells(level.cells, box.x - timer.x + origin.x, box.y - timer.y + origin.y)
            local shouldBreak = false
            for _, target in ipairs(targets) do
                if target.cell == Cell.Player or target.cell == Cell.Wall or (target.cell == Cell.Box and target.region ~= timer.region) then
                    blocked = true
                    shouldBreak = true
                    break
                end
            end

            if shouldBreak then
                break
            end
        end

        if not blocked then
            for _, box in ipairs(boxes) do
                local teleport = {
                    type = Event.Teleport,
                    from_x = box.x,
                    from_y = box.y,
                    to_x = box.x - timer.x + origin.x,
                    to_y = box.y - timer.y + origin.y,
                    cell = box,
                    timer = timer
                }
                table.insert(events, teleport)
            end
            local teleport = {
                type = Event.Teleport,
                from_x = timer.x,
                from_y = timer.y,
                to_x = origin.x,
                to_y = origin.y,
                cell = timer,
                timer = timer
            }
            table.insert(events, teleport)
        else
            for _, box in ipairs(boxes) do
                Animation.start(Particle.teleFailParticle(box.x - timer.x + origin.x, box.y - timer.y + origin.y, level, box))
            end
        end
    end
	return events
end

local function secondPassEvents(level, teleports)
    local occupied = {}
    local bannedregions = {}
    for _, event in ipairs(teleports) do
        if occupied[tostring(event.to_x) .. tostring(event.to_y)] and occupied[tostring(event.to_x) .. tostring(event.to_y)] ~= event.timer.region then
            bannedregions[event.timer.region] = true
            bannedregions[occupied[tostring(event.to_x) .. tostring(event.to_y)]] = true
        else
            occupied[tostring(event.to_x) .. tostring(event.to_y)] = event.timer.region
        end
    end

    local unbannedevents = {}
    for _, event in ipairs(teleports) do
        if not bannedregions[event.timer.region] then
            table.insert(unbannedevents, event)
        else
            Animation.start(Particle.teleFailParticle(event.to_x, event.to_y, level, event.cell))
        end
    end
    return unbannedevents
end

function Level.isWinning(level)
    local winning = true
    for _, cell in ipairs(level.cells) do
        if cell.cell == Cell.Goal then
            local ncells = findCells(level.cells, cell.x, cell.y)
            local boxes = allWithPredicate(ncells, function(cell)
                return cell.cell == Cell.Box
            end)

            if #boxes == 0 then
                winning = false
                break
            end
        end
    end
    return winning
end

local function runUndo(level)
    local events = table.remove(level.eventLog)
    if events == nil then
        return
    end

    Sounds.undo:play()
    for _, event in ipairs(events) do
        if event.type == Event.Move then
            Cell.startMoveAnim(event.cell)
            event.cell.x = event.from_x
            event.cell.y = event.from_y
        elseif event.type == Event.TimerChange then
            event.cell.val = event.from_val
        elseif event.type == Event.Teleport then
            event.cell.x = event.from_x
            event.cell.y = event.from_y
            event.timer.val = 0
        elseif event.type == Event.OriginMove then
            event.cell.x = event.from_x
            event.cell.y = event.from_y
        elseif event.type == Event.Reset then
            event.cell.x = event.from_x
            event.cell.y = event.from_y
            event.cell.val = event.from_val
        end
    end

    return level.eventLog
end

local function runEvent(level, event)
    if event.type == Event.Move then
        if event.cell.cell == Cell.Player then
            Animation.start(Particle.playerParticle(event.cell.x, event.cell.y, level))
        end
        event.cell.x = event.to_x
        event.cell.y = event.to_y
    elseif event.type == Event.TimerChange then
        event.cell.val = event.to_val
    elseif event.type == Event.Teleport then
        Animation.start(Particle.teleParticle(event.cell.x, event.cell.y, level, event.cell))
        event.cell.x = event.to_x
        event.cell.y = event.to_y
        event.timer.val = event.timer.default_val
    elseif event.type == Event.OriginMove then
        Sounds.originMove:play()
        event.cell.x = event.to_x
        event.cell.y = event.to_y
    elseif event.type == Event.Reset then
        Cell.startMoveAnim(event.cell)
        event.cell.x = event.cell.initial_x
        event.cell.y = event.cell.initial_y
        event.cell.val = event.cell.default_val
    end
end

function Level.turn(level, key)
    local direction
    if key == "up"          or key == "w" then
        direction = Direction.Up
    elseif key == "down"    or key == "s" then
        direction = Direction.Down
    elseif key == "left"    or key == "a" then
        direction = Direction.Left
    elseif key == "right"   or key == "d" then
        direction = Direction.Right
    else
        if key == "z" then
            runUndo(level)
        elseif key == "r" then
            if (#level.eventLog == 0) or (level.eventLog[#level.eventLog][1].type == Event.Reset) then return end

            Sounds.levelRestart:play()
            local events = {}

            for _, cell in ipairs(level.cells) do
                local reset = {
                    type = Event.Reset,
                    cell = cell,
                    from_x = cell.x,
                    from_y = cell.y,
                    from_val = cell.val
                }

                runEvent(level, reset)
                table.insert(events, reset)
            end

            table.insert(level.eventLog, events)
        end
        return
    end

    local events = moveCells(level, Cell.Player, nil, direction)
    if #events > 0 then
        Sounds.move:play()
    else
        Sounds.moveFail:play()
    end

    for _, event in ipairs(events) do
        runEvent(level, event)
    end

    local teleports = {}
    while true do
        local teleportbatch = handleTeleports(level, direction) -- also includes origin moves
        teleportbatch = secondPassEvents(level, teleportbatch)

        if #teleportbatch == 0 then break end
        for _, teleport in ipairs(teleportbatch) do
            runEvent(level, teleport)
        end
        append(teleports, teleportbatch)
    end

    if #teleports > 0 then Sounds.teleport:play() end

    append(teleports, events) -- very important that teleports get undone before moves
    if #teleports > 0 then table.insert(level.eventLog, teleports) end
end
