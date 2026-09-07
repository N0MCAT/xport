if Cell ~= nil then return Cell end

local love = require "love"
require "source.graphics.palette"
require "source.data.locale"

Cell = {
    Wall =      {},
    Player =    {},
    Box =       {},
    Timer =     {},
    Origin =    {},
    Goal =      {},

    Tree =      {},
}; enumerate(Cell)
ICell = invert(Cell)

function Cell.lineWidth(cellSize, strokeSize)
    return cellSize * strokeSize / 60
    -- return strokeSize
end

function Cell.draw(cell, level)
    local expAnimTime = easeOutExpo(cell.animTime)
    local x, y = lerp(cell.lastX, cell.x, expAnimTime), lerp(cell.lastY, cell.y, expAnimTime)
    local cellSize = level.cellSize

    local color = level.palette[cell.cell] or col(0, 0, 0)
    while color.r == nil do
        local rootColor = color
        color = color[string.byte(cell.region) - 64]
        if color == nil then
            if cell.region == 'P' then
                color = rootColor.player
            else
                color = rootColor.default
            end
        end
    end

    local r, g, b = color()
    love.graphics.setColor(r, g, b)

    local drawX, drawY = Level.drawPos(level, x + 0.5, y + 0.5)

    if cell.cell == Cell.Goal then
        love.graphics.setColor(r, g, b, 0.45)
        love.graphics.setCanvas(level.layers[1])
        love.graphics.setLineWidth(Cell.lineWidth(cellSize, 5))
        drawCenteredRectangle("line", drawX, drawY, cellSize, cellSize)

        love.graphics.setColor(r, g, b, 0.15)
        love.graphics.setCanvas(level.layers[5])
        love.graphics.setLineWidth(Cell.lineWidth(cellSize, 5))
        drawCenteredRectangle("line", drawX, drawY, cellSize, cellSize)
        love.graphics.setLineWidth(Cell.lineWidth(cellSize, 1))

    elseif cell.cell == Cell.Player then
        local w
        if cell.animTime == 1 then
            w = 1
        else
            w = cosh(1.3169578969248*(expAnimTime - 0.5)) - 0.25 -- don't worry ! that horrendous constant is just arccosh(2)
        end
        local h = 2 - w

        if cell.lastY == cell.y then h, w = w, h end

        love.graphics.setCanvas(level.layers[5])
        drawCenteredRectangle("fill", drawX, drawY, w * cellSize, h * cellSize)

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

        love.graphics.setCanvas(level.layers[3])
        if timerIsZero then
            love.graphics.setColor(r - 0.2, g - 0.2, b - 0.2) -- REALLY stupid
        end
        drawCenteredRectangle("fill", drawX, drawY, cellSize, cellSize)

        if (r ~= 0 or g ~= 0 or b ~= 0) then
            love.graphics.setCanvas(level.layers[2])
            love.graphics.setColor(r + 0.2, g + 0.2, b + 0.2) -- REALLY stupid
            love.graphics.setLineWidth(Cell.lineWidth(cellSize, 4))
            drawCenteredRectangle("line", drawX, drawY, cellSize, cellSize)
            love.graphics.setLineWidth(Cell.lineWidth(cellSize, 1))
        end

    elseif cell.cell == Cell.Timer then

        love.graphics.setCanvas(level.layers[5])
        love.graphics.setLineWidth(Cell.lineWidth(cellSize, 1))
        local timerFont, val
        if Locale.current == "sitelen_pona" then
            timerFont = globals.ponaTimerFont
            val = Locale.convertNumberToSitelenPona(cell.val)
        else
            timerFont = globals.timerFont
            val = cell.val
        end
        local fwidth = timerFont:getWidth(val)
        local fheight = timerFont:getHeight()

        love.graphics.print(val, timerFont,
            drawX - (fwidth / 2),
            drawY - (fheight / 2)
            -- drawX + (cellSize - fwidth) / 2,
            -- drawY + (cellSize - fheight * 0.8) / 2
        )

        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.setLineWidth(Cell.lineWidth(cellSize, 5))
        local origins = allWithPredicate(level.cells, function(c)
            return c.region == cell.region and c.cell == Cell.Origin
        end)

        love.graphics.setCanvas(level.layers[1])
        for _, origin in ipairs(origins) do
            love.graphics.line(drawX, drawY, Level.drawPos(level, origin.x + 0.5, origin.y + 0.5))
        end

    elseif cell.cell == Cell.Origin then
        love.graphics.setCanvas(level.layers[3])
        drawRotatedRectangle("fill", drawX, drawY, cellSize / 2, cellSize / 2, cell.animTime * 2 * math.pi)

    elseif cell.cell == Cell.Tree then
        local scale = cellSize / 150
        local w, h = globals.tree:getWidth() * scale, globals.tree:getHeight() * scale
        love.graphics.setCanvas(level.layers[5])
        love.graphics.draw(
            globals.tree,
            drawX - (w / 2),
            drawY + (cellSize * 1.5) / 2 - h,
            0,
            scale,
            scale
        )
    end
    love.graphics.setCanvas()
end

function Cell.startMoveAnim(cell)
    cell.lastX = cell.x
    cell.lastY = cell.y
    cell.animTime = 0
end

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

        draw = Cell.draw,
        animTime = 0
    }

    -- result.draw = drawFunctions[type] or drawFunctions.default

    return result
end

-- Used in save/migration functions.
function Cell.makeData(x, y, type, region, timer)
    local result = {
        x = x,
        y = y,

        type = ICell[type],
        region = region,
        val = timer
    }
    return result
end

function Cell.fromLegacyChar(x, y, character)
    if character == "#" then
        return Cell.makeData(x, y, Cell.Wall)
    elseif string.match(character, "[ABCDEF]") then
        return Cell.makeData(x, y, Cell.Box, character)
    elseif character == "P" then
        return Cell.makeData(x, y, Cell.Player)
    elseif character == "T" then
        return Cell.makeData(x, y, Cell.Tree)
    end
end

return Cell
