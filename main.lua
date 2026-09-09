local love = require "love"
require "source.utils"

require "source.data.levels"
require "source.data.locale"
require "source.data.json"

require "source.graphics.anim"
require "source.play.level"

require "source.scenes.menu"
require "source.scenes.playstate"
require "source.graphics.palette"

require "source.ui.interface"
require "source.ui.element"

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

Keyboard = {
    justDown = {},
    isDown = {},
    presses = {}
}

-- TODO: Move to separate file, maybe rebindable?
Controls = {
    mappings = {
        accept = { "return", "space" },
        back = { "escape", "backspace" },
        shift = { "lshift", "rshift" },
        alt = { "lalt", "ralt" },
        up = { "w", "up" },
        down = { "s", "down" },
        left = { "a", "left" },
        right = { "d", "right" }
    }
}

function Controls.isBlank(key, blank)
    if Controls.mappings[key] then
        for _, subkey in ipairs(Controls.mappings[key]) do
            if blank[subkey] then return true end
        end
        return false
    end
    return blank[key]
end

function Controls.isDown(key) return Controls.isBlank(key, Keyboard.isDown) end
function Controls.justDown(key) return Controls.isBlank(key, Keyboard.justDown) end
function Controls.presses(key, blank)
    if Controls.mappings[key] then
        local presses = 0
        for _, subkey in ipairs(Controls.mappings[key]) do
            presses = presses + (Keyboard.presses[subkey] or 0)
        end
        return presses
    end
    return blank[key]
end

Mode = {
    Gameplay = {},
    Menu = {},
    Editor = {}
}

state = {
    width = 0,
    height = 0,

    adaptUnits = 0,

    sfxVolume = 0.5,
    musicVolume = 0.5,

    levelIndex = 1,
    levelClears = {},

    scene = nil
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
        state.adaptUnits = math.min(state.width, state.height) / 720 -- 720 is the default height... change this if that's untrue
        forceUpdateGraphics()
    end
end

function resetJustDown()
    for i, _ in ipairs(Mouse.justDown) do
        Mouse.justDown[i] = false
    end

    for k, _ in pairs(Keyboard.justDown) do
        Keyboard.justDown[k] = false
        Keyboard.presses[k] = 0
    end
end

function reloadFonts()
    -- local ponaAltFile = Locale.current == 'sitelen_pona' and globals.ponaFontFile2 or nil)
    local ponaAltFile = Locale.current == 'sitelen_pona' and globals.ponaFontFile or nil
    local ponaHintAltFile = Locale.current == 'sitelen_pona' and globals.ponaMonoFontFile or nil
    globals.hintFont = love.graphics.newFont(ponaHintAltFile or globals.levelFontFile, math.min(state.width, state.height) * 0.05)
    -- globals.titleFont = love.graphics.newFont(globals.fontFile, state.cellSize * 0.5)

    if state.scene.reloadFonts then
        state.scene:reloadFonts(ponaAltFile)
    end
end

function forceUpdateGraphics()
    if state.scene.onResize then
        state.scene:onResize()
    end

    -- if state.mode == Mode.Gameplay then
    --     Level.onResize(state.level)
    -- elseif state.mode == Mode.Menu then
    --     Menu.onResize(state.menu)
    -- end

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

    state.scene = Menu.create()

    globals.challengeLevels = { 11, 12, 13, 14, 15 }

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
    state.ui = Element.makeContext()
    updateGraphics()
end

KEYS_PRESSED = {}
REPEAT_START = 0.5
REPEAT_INTERVAL = 0.05
JUST_CLICKED = false

local pressTime = 0
local repeatTime = 0

function love.update(dt)
    Mouse.x, Mouse.y = love.mouse.getPosition()
    for i, _ in ipairs(Mouse.isDown) do
        Mouse.isDown[i] = love.mouse.isDown(i)
    end

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

    for k, _ in pairs(Keyboard.isDown) do
        Keyboard.isDown[k] = love.keyboard.isDown(k)
    end

    updateGraphics()
    if state.scene.update then
        state.scene:update(dt)
    end

    resetJustDown()
    Music.update(dt)
end

function love.draw()
    -- does this not have deltatime?
    -- japi: yeah it's kinda crazy

    if state.scene.draw then
        state.scene:draw()
    end
    -- if state.mode == Mode.Gameplay then
    --     Level.draw(state.level)
    -- elseif state.mode == Mode.Menu then
    --     Menu.draw(state.menu)
    -- elseif state.mode == Mode.Editor then
    --     Interface.draw(state.interface)
    -- end

    -- Element.draw(state.rootElement)

    love.graphics.print("FPS: " .. tostring(love.timer.getFPS()), globals.hintFont, 10, state.height - 25, 0, 0.5)
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
        -- state.mode = Mode.Editor
        state.scene = Interface.new()
        state.musicVolume = 0.0
    end
end

function pressedKey(key)
    Keyboard.isDown[key] = true
    Keyboard.justDown[key] = true
    Keyboard.presses[key] = (Keyboard.presses[key] or 0) + 1
    if state.scene.keypressed then
        state.scene:keypressed(key)
    end
    -- if state.mode == Mode.Gameplay then
    --     Level.turn(state.level, key)
    -- elseif state.mode == Mode.Menu then
    --     Menu.keypressed(state.menu, key)
    -- end
end

function love.keyreleased(key)
    keyClear(key, (#KEYS_PRESSED > 0) and (REPEAT_START * 0.5) or 0)
end

function keyClear(key, time)
    Keyboard.isDown[key] = false
    pressTime = time
    repeatTime = 0
    local index = indexOf(KEYS_PRESSED, key)
    table.remove(KEYS_PRESSED, index)
end

function love.wheelmoved(x, y)
    if state.scene.wheelmoved then
        state.scene:wheelmoved(x, y)
    end
    -- if state.mode == Mode.Editor then
    --     Interface.wheelmoved(state.interface, x, y)
    -- end
end

function love.mousemoved(x, y, dx, dy, istouch)
    Mouse.x, Mouse.y = x, y
    if state.scene.mousemoved then
        state.scene:mousemoved(x, y, dx, dy, istouch)
    end
    -- if state.mode == Mode.Editor then
    --     Interface.mousemoved(state.interface, x, y, dx, dy, istouch)
    -- end
end

function love.mousepressed(x, y, button, istouch, presses)
    Mouse.isDown[button] = true
    Mouse.justDown[button] = true
    if state.scene.mousepressed then
        state.scene:mousepressed(x, y, button, istouch, presses)
    end
end

function love.mousereleased(x, y, button, istouch, presses)
    Mouse.isDown[button] = false
    if state.scene.mousereleased then
        state.scene:mousereleased(x, y, button, istouch, presses)
    end
end
