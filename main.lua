local love = require "love"
require "source.utils"

require "source.data.levels"
require "source.data.locale"
require "source.data.json"

require "source.graphics.anim"
require "source.play.level"

require "source.scenes.menu"
require "source.graphics.palette"

require "source.ui.interface"
require "source.ui.element"
require "source.ui.button"

--[[

TODO:
- Fix bug with fullscreen enter also working as entering a level
- Fix particles still appearing on the menu after closing a level
- Make the menu look nicer

]]

DEBUG = {
    AnimationTime = 0.16 -- default: 0.16
}

Mouse = {
    x = 0, y = 0,
    justDown = {false, false},
    isDown = {false, false}
}

Mode = {
    Gameplay = {},
    Menu = {},
    Editor = {}
}

state = {
    width = 0,
    height = 0,

    sfxVolume = 0.5,
    musicVolume = 0.5,

    levelIndex = 1,
    levelClears = {},

    mode = Mode.Menu
}

globals = {
    font = {},
    levelFont = {},
    hintFont = {},

    fontFile = "fonts/intrebol.ttf", -- NOT a placeholder
    levelFontFile = "fonts/Comfortaa-Regular.ttf", -- *REALLY* NOT a placeholder,
    ponaFontFile = "fonts/sitelenselikiwenjuniko.ttf", -- toki pona :D
    ponaMonoFontFile = "fonts/sitelenselikiwenmonojuniko.ttf", -- toki pona :D
    ponaTimerFontFile = "fonts/linja-pimeja-pona.otf", -- toki pona :D

    levels = {},
    entered_level_six = 0,
    tree = love.graphics.newImage("tree.png")
}

local lastWidth = 0
local lastHeight = 0

function updateGraphics()
    lastWidth = state.width
    lastHeight = state.height
    state.width = love.graphics.getWidth()
    state.height = love.graphics.getHeight()

    if lastWidth ~= state.width or lastHeight ~= state.height then
        forceUpdateGraphics()
    end
end

function reloadFonts()
    -- local ponaAltFile = Locale.current == 'sitelen_pona' and globals.ponaFontFile2 or nil)
    local ponaAltFile = Locale.current == 'sitelen_pona' and globals.ponaFontFile or nil
    local ponaHintAltFile = Locale.current == 'sitelen_pona' and globals.ponaMonoFontFile or nil
    globals.hintFont = love.graphics.newFont(ponaHintAltFile or globals.levelFontFile, math.min(state.width, state.height) * 0.05)
    -- globals.titleFont = love.graphics.newFont(globals.fontFile, state.cellSize * 0.5)

    if state.mode == Mode.Gameplay then
        Level.reloadFonts(state.level, ponaAltFile)
    elseif state.mode == Mode.Menu then
        Menu.reloadFonts(state.menu, ponaAltFile)
    end
end

function forceUpdateGraphics()
    if state.mode == Mode.Gameplay then
        Level.onResize(state.level)
    elseif state.mode == Mode.Menu then
        Menu.onResize(state.menu)
    end

    reloadFonts()
end

function love.load()
    Locale.loadMappings()
    Levels.loadData()
    -- state.level = Level.fromData(globals.levels[state.levelIndex])

    -- local json = love.filesystem.read('jsontest.jsonc')
    -- local jsontest = JSONParser.parse(json)
    -- debugPrint(" [JSONPARSER] Test:", jsontest, '\n' .. json)

    -- local jsonencode = JSONEncoder.encode(jsontest, '  ')
    -- debugPrint("[JSONEncoder] Test:", jsontest, '\n' .. jsonencode)

    -- love.filesystem.write('jsontest2.jsonc', jsonencode)

    state.menu = Menu.create()

    globals.challengeLevels = { 11, 12, 13, 14, 15 }

    state.mode = Mode.Menu
    state.musicVolume = 0.5
    state.fullscreen = false

    local iconImageData = {}
    local iconAnimCount = 12
    -- local iconAnims = {}
    for i=1,iconAnimCount do
        local imageData = love.image.newImageData("icons/square" .. tostring(i) .. ".png")
        table.insert(iconImageData, imageData)

        -- local anim = Animation.new(1 / iconAnimCount, nil, function()
        --     love.window.setIcon(iconImageData[i])
        -- end)
        -- table.insert(iconAnims, anim)
    end
    -- local iconAnimation = Animation.chainArrayLoop(iconAnims)
    -- Animation.start(iconAnimation)
    love.window.setIcon(iconImageData[7])

    globals.mouseCursors = {
        ["hand"] = love.mouse.getSystemCursor("hand"),
        ["arrow"] = love.mouse.getSystemCursor("arrow"),
    }

    Music.play(Music.menu)
    state.interface = Interface.new()

    -- state.rootElement = Element.new(ctx, {
    --     color = { 255, 0, 0 },
    --     padding = { 25, 25, 25, 25 },
    --     spacing = 25
    -- }, function(_)
    --     Element.new(ctx, {
    --         sizing = {
    --             width = Size.Fixed { amount = love.graphics.getWidth() / 4 },
    --             height = Size.Fixed { amount = love.graphics.getHeight() / 4 },
    --         },
    --         color = { 0, 255, 0 }
    --     })
    --     Element.new(ctx, {
    --         sizing = {
    --             width = Size.Fixed { amount = love.graphics.getWidth() / 7 },
    --             height = Size.Fixed { amount = love.graphics.getHeight() / 7 },
    --         },
    --         color = { 0, 255, 0 }
    --     })
    -- end)

    -- local ctx = {}
    -- state.rootElement = Element.new(ctx, {
    --     color = { 32, 32, 50, 200 },
    --     padding = { 10, 10, 10, 10 },
    --     spacing = 10,
    --     sizing = {
    --         width = Size.Fixed { amount = love.graphics.getWidth() - 20 },
    --         height = Size.Fixed { amount = love.graphics.getHeight() - 20 }
    --     },
    --     align = { y = AlignY.Center }
    -- }, function(_)
    --     Button.new(ctx, {
    --         color = { 50, 70, 70, 200 },
    --         sizing = { width = Size.Grow, height = Size.Grow },
    --         spacing = 10,
    --         padding = { 10, 10, 10, 10 },
    --         layoutDir = LayoutDir.TopToBottom
    --     }, function(_)
    --         for i=1,10 do
    --             Element.new(ctx, {
    --                 color = { i * 50, 70, 70, 200 },
    --                 sizing = { width = Size.Grow, height = Size.Grow }
    --             })
    --         end
    --     end)
    --     Element.new(ctx, {
    --         color = { 50, 70, 70, 200 },
    --         sizing = { width = Size.Percent { amount = 0.2 }, height = Size.Percent { amount = love.graphics.getWidth() / 5 } }
    --     })
    -- end)

    -- Element.initialize(state.rootElement)

    updateGraphics()
end

KEYS_PRESSED = {}
REPEAT_START = 0.5
REPEAT_INTERVAL = 0.05
JUST_CLICKED = false

local pressTime = 0
local repeatTime = 0

function love.update(dt)
    Animation.update(dt)
    Mouse.x, Mouse.y = love.mouse.getPosition()
    for i, _ in ipairs(Mouse.justDown) do
        Mouse.isDown[i] = love.mouse.isDown(i)
    end

    updateGraphics()

    local currentKey = KEYS_PRESSED[#KEYS_PRESSED]
    if currentKey ~= nil then
        pressTime = pressTime + dt

        if pressTime > REPEAT_START then
            repeatTime = repeatTime + dt
            if repeatTime > REPEAT_INTERVAL then
                repeatTime = 0
                pressedKey(currentKey)
            end
        end
    end

    if state.mode == Mode.Gameplay then
        Level.update(state.level, dt)
    elseif state.mode == Mode.Menu then
        Menu.update(state.menu, dt)
    elseif state.mode == Mode.Editor then
        Interface.update(state.interface, dt)
    end

    for i, _ in ipairs(Mouse.justDown) do
        Mouse.justDown[i] = false
    end
    Music.update(dt)
end

function love.draw()
    -- does this not have deltatime?
    -- japi: yeah it's kinda crazy
    if state.mode == Mode.Gameplay then
        Level.draw(state.level)
    elseif state.mode == Mode.Menu then
        Menu.draw(state.menu)
    elseif state.mode == Mode.Editor then
        Interface.draw(state.interface)
    end
    Animation.draw()
    -- Element.draw(state.rootElement)

    love.graphics.print("Current FPS: " .. tostring(love.timer.getFPS()), globals.hintFont, 10, 10)
end

function love.keypressed(key)
    pressedKey(key)
    keyClear(key, 0)
    KEYS_PRESSED[#KEYS_PRESSED+1] = key

    if (key == "return" and (love.keyboard.isDown("lalt") or love.keyboard.isDown("ralt")))
       or key == "f11" then
       state.fullscreen = not state.fullscreen
       love.window.setFullscreen(state.fullscreen)
    elseif key == "e" then
        state.mode = Mode.Editor
        state.musicVolume = 0.0
    end
end

function pressedKey(key)
    if state.mode == Mode.Gameplay then
        Level.turn(state.level, key)
    elseif state.mode == Mode.Menu then
        Menu.keypressed(state.menu, key)
    end
end

function love.keyreleased(key)
    keyClear(key, (#KEYS_PRESSED > 0) and (REPEAT_START * 0.5) or 0)
end

function keyClear(key, time)
    pressTime = time
    repeatTime = 0
    local index = indexOf(KEYS_PRESSED, key)
    table.remove(KEYS_PRESSED, index)
end

function love.wheelmoved(x, y)
    if state.mode == Mode.Editor then
        Interface.wheelmoved(state.interface, x, y)
    end
end

function love.mousemoved(x, y, dx, dy, istouch)
    if state.mode == Mode.Editor then
        Interface.mousemoved(state.interface, x, y, dx, dy, istouch)
    end
end

function love.mousepressed(x, y, button, istouch, presses)
    Mouse.justDown[button] = true
end
