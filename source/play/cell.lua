if Cell ~= nil then return Cell end

local love = require "love"
require "source.graphics.palette"
require "source.data.locale"

Cell = orderedEnum({
    "Wall",
    "Player",
    "Box",

    "Timer",
    "Origin",
    "Goal",

    "Tree",
})
ICell = invert(Cell)

-- This means EditorCell.
ECell = invert(Cell, "Cell.")

function Cell.new(x, y, id, type, region, timer)
    local result = {
        x = x,
        y = y,
        id = id,

        lastX = x,
        lastY = y,

        cell = type,
        region = region,
        val = timer,

        initial_x = x,
        initial_y = y,
        default_val = timer,

        animTime = 0
    }

    bindPrototype(result, Cell)
    return result
end

function Cell.lineWidth(cellSize, strokeSize)
    return cellSize * strokeSize / 60
    -- return strokeSize
end

function Cell.drawPos(scale, x, y)
    return x * scale, y * scale
end

function Cell.getColor(palette, type, region)
    local color = palette[type] or col(0, 0, 0)
    while color.r == nil do
        local rootColor = color
        color = color[region]
        if color == nil then
            if type == Cell.Player then
                color = rootColor.player
            else
                color = rootColor.default
            end
        end
    end
    return color
end

-- Draw the cell unto the screen. Requires an accompanying level.
function Cell.draw(cell, level, layers)
    local expAnimTime = easeOutExpo(cell.animTime)
    local x, y = lerp(cell.lastX or cell.x, cell.x, expAnimTime), lerp(cell.lastY or cell.y, cell.y, expAnimTime)
    local drawX, drawY = Cell.drawPos(level.scale, x + 0.5, y + 0.5)

    local color = Cell.getColor(level.palette, cell.cell, cell.region)

    if cell.cell == Cell.Goal then
        Cell.drawGoal(drawX, drawY, level.scale, color, layers)
    elseif cell.cell == Cell.Player then
        Cell.drawPlayer(drawX, drawY, level.scale, expAnimTime, cell.lastY == cell.y, color, layers)
    elseif cell.cell == Cell.Wall or cell.cell == Cell.Box then
        local timerIsZero = false
        if cell.cell == Cell.Box then
            local timers = allWithPredicate(level.cells, function(c)
                return c.cell == Cell.Timer and c.region == cell.region and c.val == 0
            end)
            if #timers > 0 then
                timerIsZero = true
            end
        end

        Cell.drawBox(drawX, drawY, level.scale, timerIsZero, color, layers)
    elseif cell.cell == Cell.Timer then
        local origins = allWithPredicate(level.cells, function(c)
            return c.region == cell.region and c.cell == Cell.Origin
        end)

        Cell.drawTimer(drawX, drawY, level.scale, cell.val, color, layers)

        love.graphics.setCanvas(layers[1])
        for _, origin in ipairs(origins) do
            local expAnimTime2 = easeOutExpo(cell.animTime)
            local x2, y2 = lerp(origin.lastX or origin.x, origin.x, expAnimTime2),
                lerp(origin.lastY or origin.y, origin.y, expAnimTime2)
            local drawX2, drawY2 = Cell.drawPos(level.scale, x2 + 0.5, y2 + 0.5)

            Cell.drawTimerLine(drawX, drawY, drawX2, drawY2, level.scale)
        end
    elseif cell.cell == Cell.Origin then
        Cell.drawOrigin(drawX, drawY, level.scale, cell.animTime, color, layers)
    elseif cell.cell == Cell.Tree then
        Cell.drawTree(drawX, drawY, level.scale, layers)
    end

    love.graphics.setCanvas()
end

-- Same as `Cell.draw()` requiring a level, but does not bother with `expAnimTime`, `lastX`, or `lastY`.
function Cell.drawEditor(cell, level, layers)
    local drawX, drawY = Cell.drawPos(level.scale, cell.x + 0.5, cell.y + 0.5)
    local color = Cell.getColor(level.palette, cell.cell, cell.region)

    if cell.cell == Cell.Goal then
        Cell.drawGoal(drawX, drawY, level.scale, color, layers)
    elseif cell.cell == Cell.Player then
        Cell.drawPlayer(drawX, drawY, level.scale, 1, false, color, layers)
    elseif cell.cell == Cell.Wall or cell.cell == Cell.Box then
        local timerIsZero = false
        if cell.cell == Cell.Box then
            local timers = allWithPredicate(level.cells, function(c)
                return c.cell == Cell.Timer and c.region == cell.region and c.val == 0
            end)
            if #timers > 0 then
                timerIsZero = true
            end
        end

        Cell.drawBox(drawX, drawY, level.scale, timerIsZero, color, layers)
    elseif cell.cell == Cell.Timer then
        local origins = allWithPredicate(level.cells, function(c)
            return c.region == cell.region and c.cell == Cell.Origin
        end)

        Cell.drawTimer(drawX, drawY, level.scale, cell.val, color, layers)

        love.graphics.setCanvas(layers[1])
        for _, origin in ipairs(origins) do
            local drawX2, drawY2 = Cell.drawPos(level.scale, origin.x + 0.5, origin.y + 0.5)
            Cell.drawTimerLine(drawX, drawY, drawX2, drawY2, level.scale)
        end
    elseif cell.cell == Cell.Origin then
        Cell.drawOrigin(drawX, drawY, level.scale, cell.animTime, color, layers)
    elseif cell.cell == Cell.Tree then
        Cell.drawTree(drawX, drawY, level.scale, layers)
    end

    love.graphics.setCanvas()
end

function Cell.drawGoal(x, y, scale, color, layers)
    local r, g, b = color()

    love.graphics.setColor(r, g, b, 0.45)
    love.graphics.setCanvas(layers[1])
    love.graphics.setLineWidth(Cell.lineWidth(scale, 5))
    drawCenteredRectangle("line", x, y, scale, scale)

    love.graphics.setColor(r, g, b, 0.15)
    love.graphics.setCanvas(layers[5])
    love.graphics.setLineWidth(Cell.lineWidth(scale, 5))
    drawCenteredRectangle("line", x, y, scale, scale)
    love.graphics.setLineWidth(Cell.lineWidth(scale, 1))
end

function Cell.drawPlayer(x, y, scale, expAnimTime, horizontal, color, layers)
    love.graphics.setColor(color())

    local w
    if expAnimTime == 1 then
        w = 1
    else
        w = cosh(1.3169578969248 * (expAnimTime - 0.5)) -
            0.25 -- don't worry ! that horrendous constant is just arccosh(2)
    end
    local h = 2 - w

    if horizontal then h, w = w, h end

    love.graphics.setCanvas(layers[5])
    drawCenteredRectangle("fill", x, y, w * scale, h * scale)
end

function Cell.drawBox(x, y, scale, timerIsZero, color, layers)
    local r, g, b = color()
    love.graphics.setCanvas(layers[3])
    if timerIsZero then
        love.graphics.setColor(r - 0.2, g - 0.2, b - 0.2) -- REALLY stupid
    else
        love.graphics.setColor(r, g, b)
    end
    drawCenteredRectangle("fill", x, y, scale, scale)

    if (r ~= 0 or g ~= 0 or b ~= 0) then
        love.graphics.setCanvas(layers[2])
        love.graphics.setColor(r + 0.2, g + 0.2, b + 0.2) -- REALLY stupid
        love.graphics.setLineWidth(Cell.lineWidth(scale, 4))
        drawCenteredRectangle("line", x, y, scale, scale)
        love.graphics.setLineWidth(Cell.lineWidth(scale, 1))
    end
end

function Cell.drawTimer(x, y, scale, value, color, layers)
    love.graphics.setColor(color())

    love.graphics.setCanvas(layers[5])
    love.graphics.setLineWidth(Cell.lineWidth(scale, 1))
    local timerFont, val
    if Locale.current == "sitelen_pona" then
        timerFont = globals.ponaTimerFont
        val = Locale.convertNumberToSitelenPona(value)
    else
        timerFont = globals.timerFont
        val = value
    end
    local fwidth = timerFont:getWidth(val)
    local fheight = timerFont:getHeight()

    love.graphics.print(val, timerFont,
        x - (fwidth / 2),
        y - (fheight / 2)
    -- drawX + (cellSize - fwidth) / 2,
    -- drawY + (cellSize - fheight * 0.8) / 2
    )
end

function Cell.drawTimerLine(x1, y1, x2, y2, scale)
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.setLineWidth(Cell.lineWidth(scale, 5))
    love.graphics.line(x1, y1, x2, y2)
end

function Cell.drawOrigin(x, y, scale, animTime, color, layers)
    love.graphics.setColor(color())
    love.graphics.setCanvas(layers[3])
    drawRotatedRectangle("fill", x, y, scale / 2, scale / 2, animTime * 2 * math.pi)
end

function Cell.drawTree(x, y, scale, layers)
    love.graphics.setColor(1, 1, 1)
    local scale2 = scale / 150
    local w, h = globals.tree:getWidth() * scale2, globals.tree:getHeight() * scale2
    love.graphics.setCanvas(layers[5])
    love.graphics.draw(
        globals.tree,
        x - (w / 2),
        y + (scale * 1.5) / 2 - h,
        0,
        scale2,
        scale2
    )
end

function Cell.startMoveAnim(cell)
    cell.lastX = cell.x
    cell.lastY = cell.y
    cell.animTime = 0
end

-- Used in save/migration functions.
function Cell.makeData(x, y, type, region, value)
    local result = {
        x = x,
        y = y,

        type = ICell[type],
        region = region,
        val = value
    }
    return result
end

-- Used for the editor.
function Cell.makeEditor(x, y, type, region, value)
    local result = Cell.makeData(x, y, type, region, value)
    result.animTime = 0

    bindPrototype(result, Cell)
    return result
end

function Cell.fromLegacyChar(x, y, character)
    if character == "#" then
        return Cell.makeData(x, y, Cell.Wall)
    elseif string.match(character, "[ABCDEF]") then
        return Cell.makeData(x, y, Cell.Box, string.byte(character) - 64)
    elseif character == "P" then
        return Cell.makeData(x, y, Cell.Player)
    elseif character == "T" then
        return Cell.makeData(x, y, Cell.Tree)
    end
end

return Cell
