if Interface ~= nil then return Interface end

local love = require "love"
Interface = {}

function Interface.new()
    local interface = {
        zoom = 100,
        zoomVelocity = 0,
        zoomSensitivity = 100,
        zoomSmooth = 6,

        panX = 0,
        panY = 0,
        panXVelocity = 0,
        panYVelocity = 0,
        panSensitivity = 100,
        panSmooth = 2,

        levelWidth = 7,
        levelHeight = 5,
        cells = {},
        debug = {}
    }

    return interface
end

function Interface.update(interface, dt)
    interface.zoom = interface.zoom + interface.zoomVelocity * dt
    interface.zoomVelocity = interface.zoomVelocity -
        interface.zoomVelocity * math.min(dt * interface.zoomSensitivity / interface.zoomSmooth, 1)

    interface.panX = interface.panX + interface.panXVelocity * dt
    interface.panXVelocity = interface.panXVelocity -
        interface.panXVelocity * math.min(dt * interface.panSensitivity / interface.panSmooth, 1)

    interface.panY = interface.panY + interface.panYVelocity * dt
    interface.panYVelocity = interface.panYVelocity -
        interface.panYVelocity * math.min(dt * interface.panSensitivity / interface.panSmooth, 1)

    if love.keyboard.isDown("space") and love.mouse.isDown(1) then
        interface.isPanning = true
    else
        interface.isPanning = false
    end
end

function Interface.wheelmoved(interface, dx, dy)
    interface.zoomVelocity = interface.zoomVelocity + dy * interface.zoomSensitivity
end

function Interface.mousemoved(interface, x, y, dx, dy, istouch)
    if interface.isPanning then
        -- print(dx)
        interface.panXVelocity = interface.panXVelocity + dx * interface.panSensitivity
        interface.panYVelocity = interface.panYVelocity + dy * interface.panSensitivity
    end
end

function Interface.draw(interface)
    local cellSize = interface.zoom

    local w, h = interface.levelWidth * cellSize, interface.levelHeight * cellSize

    love.graphics.push()
    love.graphics.translate(interface.panX, interface.panY)

    love.graphics.setColor(0.5, 0.5, 0.5)
    drawCenteredRectangle("line", state.width / 2, state.height / 2, w, h)

    for y = 0, interface.levelHeight - 1 do
        for x = 0, interface.levelWidth - 1 do
            love.graphics.rectangle("line",
                (state.width - w) / 2 + x * cellSize,
                (state.height - h) / 2 + y * cellSize, cellSize, cellSize)
        end
    end

    love.graphics.setColor(1, 1, 1)
    love.graphics.pop()
end
