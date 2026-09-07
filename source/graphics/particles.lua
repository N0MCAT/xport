if Particle ~= nil then return Particle end

local love = require "love"
require "source.graphics.anim"

Particle = {}

function Particle.playerParticle(x, y, level)
    local cellSize = level.cellSize
    return Animation.new(
        1.5, function(self, progress)
            local progress = easeOutCubic(progress)
            local scale = (1 - progress) * 0.5
            love.graphics.setColor(1, 1, 1, 0.1)
            drawRotatedRectangle("fill", (x + 0.5) * cellSize + (state.width - level.width * cellSize) / 2,
                (y + 0.5) * cellSize + (state.height - level.height * cellSize) / 2, cellSize * scale, cellSize * scale, 0)
        end
    )
end

function Particle.teleParticle(x, y, level, cell)
    local color = level.palette[cell.cell]
    while color.r == nil do
        local rootColor = color
        color = color[cell.region]
        if color == nil then
            if cell.region == 'P' then
                color = rootColor.player
            else
                color = rootColor.default
            end
        end
    end
    -- help . how do i change the alpha

    local cellSize = level.cellSize
    local yrand = math.random() + 5.5
    local xrand = (math.random() - 0.5) * 2
    local rrand = (math.random() - 0.5) * 5
    local scalemul = 1
    if cell.cell == Cell.Timer then scalemul = 0.5 end
    return Animation.new(
        3, function(self, progress)
            local progress = easeOutCubic(progress)
            local y_offset = yrand * progress
            local x_offset = xrand * progress
            local scale = (1 - progress) * scalemul
            local rotation = rrand * progress
            local r, g, b = color()
            love.graphics.setColor(r, g, b, 0.5)
            drawRotatedRectangle("fill", (x + x_offset + 0.5) * cellSize + (state.width - level.width * cellSize) / 2,
                (y - y_offset + 0.5) * cellSize + (state.height - level.height * cellSize) / 2, cellSize * scale, cellSize * scale, rotation)
        end
    )
end


function Particle.teleFailParticle(x, y, level, cell)

    local cellSize = level.cellSize
    local scalemul = 1
    if cell.cell == Cell.Timer then scalemul = 0 end
    return Animation.new(
        1, function(self, progress)
            local progress = easeOutCubic(progress)
            local scale = scalemul
            love.graphics.setColor(1, 0, 0, (1 - progress) / 4)
            drawRotatedRectangle("fill", (x + 0.5) * cellSize + (state.width - level.width * cellSize) / 2,
                (y + 0.5) * cellSize + (state.height - level.height * cellSize) / 2, cellSize * scale, cellSize * scale, 0)
        end
    )
end



return Particle
