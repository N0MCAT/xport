if Menu ~= nil then return Menu end

local love = require "love"
require "source.graphics.anim"
require "source.play.level"

Menu = {}
Menu.scrollBarWidth = 0.05

function Menu.new(width, height, levelRects, scrollBars)
    local menu = {
        width = width,
        height = height,

        levelRects = levelRects,
        scrollBars = scrollBars,

        marginX = 0,
        marginY = 0,
        pixelWidth = 0,
        pixelHeight = 0,

        selectedIndex = nil,
        lastSelectedIndex = nil,
        levelOpening = false,
    }

    for i, rect in ipairs(menu.levelRects) do
        rect.scale = 1
    end

    return menu
end

function Menu.create()
    local menuLevelSize = 0.1
    return Menu.new(1, 1, {
        {
            x = 0.5 - menuLevelSize * 1.5,
            y = menuLevelSize,
            w = menuLevelSize,
            h = menuLevelSize,
            levelArea = 'demoworld',
            levelIndex = 1,
        },
        {
            x = 0.5,
            y = menuLevelSize,
            w = menuLevelSize,
            h = menuLevelSize,
            levelArea = 'demoworld',
            levelIndex = 2,
        },
        {
            x = 0.5 + menuLevelSize * 1.5,
            y = menuLevelSize,
            w = menuLevelSize,
            h = menuLevelSize,
            levelArea = 'demoworld',
            levelIndex = 3,
        },
        {
            x = 0.5 - menuLevelSize * 1.5,
            y = menuLevelSize * 2.4,
            w = menuLevelSize,
            h = menuLevelSize,
            levelArea = 'demoworld',
            levelIndex = 4,
        },
        {
            x = 0.5,
            y = menuLevelSize * 2.4,
            w = menuLevelSize,
            h = menuLevelSize,
            levelArea = 'demoworld',
            levelIndex = 5,
        },
        {
            x = 0.5 + menuLevelSize * 1.5,
            y = menuLevelSize * 2.4,
            w = menuLevelSize,
            h = menuLevelSize,
            levelArea = 'demoworld',
            levelIndex = 6,
        },
        {
            x = 0.5 - menuLevelSize * 1.5,
            y = 0.5 - menuLevelSize * 0.7,
            w = menuLevelSize,
            h = menuLevelSize,
            levelArea = 'demoworld',
            levelIndex = 7,
        },
        {
            x = 0.5,
            y = 0.5 - menuLevelSize * 0.7,
            w = menuLevelSize,
            h = menuLevelSize,
            levelArea = 'demoworld',
            levelIndex = 8,
        },
        {
            x = 0.5 + menuLevelSize * 1.5,
            y = 0.5 - menuLevelSize * 0.7,
            w = menuLevelSize,
            h = menuLevelSize,
            levelArea = 'demoworld',
            levelIndex = 9,
        },
        {
            x = 0.5,
            y = 0.5 + menuLevelSize * 0.7,
            w = menuLevelSize,
            h = menuLevelSize,
            levelArea = 'demoworld',
            levelIndex = 10,
        },
        {
            x = 0.5 - menuLevelSize * 0.75,
            y = 1 - menuLevelSize * 2.4,
            w = menuLevelSize,
            h = menuLevelSize,
            levelArea = 'demoworld',
            levelIndex = 11,
        },
        {
            x = 0.5 + menuLevelSize * 0.75,
            y = 1 - menuLevelSize * 2.4,
            w = menuLevelSize,
            h = menuLevelSize,
            levelArea = 'demoworld',
            levelIndex = 12,
        },
        {
            x = 0.5 - menuLevelSize * 1.5,
            y = 1 - menuLevelSize,
            w = menuLevelSize,
            h = menuLevelSize,
            levelArea = 'demoworld',
            levelIndex = 13,
        },
        {
            x = 0.5,
            y = 1 - menuLevelSize,
            w = menuLevelSize,
            h = menuLevelSize,
            levelArea = 'demoworld',
            levelIndex = 14,
        },
        {
            x = 0.5 + menuLevelSize * 1.5,
            y = 1 - menuLevelSize,
            w = menuLevelSize,
            h = menuLevelSize,
            levelArea = 'demoworld',
            levelIndex = 15,
        },
        -- {
        --     x = 0.5 + menuLevelSize * 1.5,
        --     y = 0,
        --     w = menuLevelSize,
        --     h = menuLevelSize,
        --     levelArea = 'demoworld',
        --     levelIndex = 16,
        -- },
    },{
        {
            x = 1/7 - Menu.scrollBarWidth / 2,
            y = 3/5,
            h = 0.3,
            value = state.sfxVolume,
            connect = function(_, value)
                if (state.sfxVolume ~= value) then
                    state.sfxVolume = value
                    Sounds.move:play()
                end
            end,
            label = "menu.volume.sfx"
        },
        {
            x = 6/7 - Menu.scrollBarWidth / 2,
            y = 3/5,
            h = 0.3,
            value = state.musicVolume,
            connect = function(_, value)
                if (state.musicVolume ~= value) then
                    state.musicVolume = value
                    Sounds.move:play(true)
                end
            end,
            label = "menu.volume.music"
        },
        {
            x = 1/7 - Menu.scrollBarWidth / 2,
            y = 1/10,
            h = 0.3,
            snapping = #Locale.languages,
            value = 0,
            connect = function(scrollbar, value)
                local newLang = Locale.languages[value + 1]
                Locale.changeLanguage(newLang)

                scrollbar.label = "menu.language." .. newLang
                return value
            end,
            -- release = function(scrollbar, value)
            --     local newLang = Locale.languages[value + 1]
            --     Locale.changeLanguage(newLang)

            --     scrollbar.label = "menu.language.label\n(menu.language." .. Locale.current .. ")"
            -- end,
            label = "menu.language.en_US"
        }
    })
end

function Menu.reloadFonts(menu, overrideFont)
    globals.menuFont = love.graphics.newFont(overrideFont or globals.fontFile, math.min(state.width, state.height) * 0.06)
end

function Menu.onResize(menu)
    -- width height
    if menu.width > menu.height then
    elseif menu.height > menu.width then
    else
        menu.pixelWidth = math.min(state.width, state.height)
        menu.pixelHeight = math.min(state.width, state.height)
        menu.marginX = (state.width - menu.pixelWidth) / 2
        menu.marginY = (state.height - menu.pixelHeight) / 2
    end
end

local function hover(menu)
    local cursor = love.mouse.getCursor()
    if cursor == nil or cursor:getType() ~= "hand" and not menu.levelOpening then
        love.mouse.setCursor(globals.mouseCursors.hand)
        Sounds.hoverUI:play()
    end

    if menu.selectedIndex ~= nil then
        menu.lastSelectedIndex = menu.selectedIndex
        menu.selectedIndex = nil
    end
end

local function noHover(menu)
    local cursor = love.mouse.getCursor()
    if cursor == nil or cursor:getType() ~= "arrow" then
        love.mouse.setCursor(globals.mouseCursors.arrow)
    end

    if menu.selectedIndex == nil then
        menu.selectedIndex = menu.lastSelectedIndex
    end
end

function Menu.update(menu, dt)
    local mx, my = love.mouse.getPosition()
    -- for _, scrollBar in menu.scrollBars do

    -- end
    local hovering = false

    local alreadySliding = false
    local alreadyHovering = false

    for _, scrollBar in ipairs(menu.scrollBars) do
        local realX = menu.marginX + (scrollBar.x / menu.width) * menu.pixelWidth
        local realY = menu.marginY + (scrollBar.y / menu.height) * menu.pixelHeight
        local realW = (Menu.scrollBarWidth / menu.width) * menu.pixelWidth
        local realH = (scrollBar.h / menu.height) * menu.pixelHeight

        if scrollBar.sliding then
            alreadySliding = true
        end
        if pointInRect(mx, my, realX, realY, realW, realH) then
            alreadyHovering = true
        end
    end

    for i, scrollBar in ipairs(menu.scrollBars) do
        if not love.mouse.isDown(1) then
            if scrollBar.sliding then
                if scrollBar.release then scrollBar.release(scrollBar, scrollBar.value) end
                scrollBar.sliding = false
            end
        end

        local realX = menu.marginX + (scrollBar.x / menu.width) * menu.pixelWidth
        local realY = menu.marginY + (scrollBar.y / menu.height) * menu.pixelHeight
        local realW = (Menu.scrollBarWidth / menu.width) * menu.pixelWidth
        local realH = (scrollBar.h / menu.height) * menu.pixelHeight

        if pointInRect(mx, my, realX, realY, realW, realH) then
            if not alreadyHovering then
                hover(menu)
            end
            if love.mouse.isDown(1) then
                if not alreadySliding then
                    scrollBar.sliding = true
                end
            end
        end

        if scrollBar.sliding then
            local value = 1 - math.max(math.min((my - realY) / realH, 1), 0)

            if scrollBar.snapping then
                scrollBar.value = math.floor(value * (scrollBar.snapping - 1) + 0.5)
                if scrollBar.scale then
                    scrollBar.value = (scrollBar.value / (scrollBar.snapping - 1)) * scrollBar.scale
                end
            else
                scrollBar.value = value * (scrollBar.scale or 1)
            end

            hovering = true
            scrollBar.value = scrollBar.connect(scrollBar, scrollBar.value) or scrollBar.value
        else
            hovering = false
        end
    end

    for _, rect in ipairs(menu.levelRects) do
        local realX = menu.marginX + (rect.x / menu.width) * menu.pixelWidth
        local realY = menu.marginY + (rect.y / menu.height) * menu.pixelHeight
        local realW = ((rect.w * rect.scale) / menu.width) * menu.pixelWidth
        local realH = ((rect.h * rect.scale) / menu.height) * menu.pixelHeight

        if pointInRect(mx, my, realX - realW / 2, realY - realH / 2, realW, realH) then
            if not rect.hovering then
                local scaleRect = Menu.rectScaleAnim(rect)
                Animation.start(scaleRect)
                rect.anim = scaleRect
            end

            hover(menu)
            hovering = true
            rect.hovering = true

            if love.mouse.isDown(1) and not rect.clicked and not menu.levelOpening and not alreadySliding then
                rect.clicked = true
                Animation.start(Menu.levelStart(menu, rect, realX, realY, realW, realH))
                menu.levelOpening = true
                Sounds.selectUI:play()
                break
            end
        else
            if rect.hovering then
                local scaleRect = Menu.rectUnscaleAnim(rect)
                Animation.delayedStart(0.01, scaleRect)
            end
            rect.hovering = false
        end
    end

    if not hovering then noHover(menu) end
end


function Menu.keypressed(menu, key)
    if (key == "tab" or key == "right" or key == "d") and not menu.levelOpening then
        Sounds.hoverUI:play()
        if not menu.selectedIndex or menu.selectedIndex >= #menu.scrollBars + #menu.levelRects then
            menu.selectedIndex = 1
        else
            menu.selectedIndex = menu.selectedIndex + 1
        end
    elseif (key == "left" or key == "a") and not menu.levelOpening then
        Sounds.hoverUI:play()
        if not menu.selectedIndex or menu.selectedIndex <= 1 then
            menu.selectedIndex = #menu.scrollBars + #menu.levelRects
        else
            menu.selectedIndex = menu.selectedIndex - 1
        end
    elseif menu.selectedIndex ~= nil and not menu.levelOpening then
    	if key == "space" or key == "return" then
            if menu.selectedIndex <= #menu.levelRects then
                local rect = menu.levelRects[menu.selectedIndex]
                local realX = menu.marginX + (rect.x / menu.width) * menu.pixelWidth
                local realY = menu.marginY + (rect.y / menu.height) * menu.pixelHeight
                local realW = ((rect.w * rect.scale) / menu.width) * menu.pixelWidth
                local realH = ((rect.h * rect.scale) / menu.height) * menu.pixelHeight

                Sounds.selectUI:play()
                rect.clicked = true
                Animation.start(Menu.levelStart(menu, rect, realX, realY, realW, realH))
                menu.levelOpening = true
            end
        elseif key == "up" or key == "w" then
            if menu.selectedIndex > #menu.levelRects then
                local scrollBar = menu.scrollBars[menu.selectedIndex - #menu.levelRects]

                if scrollBar.snapping then
                    if scrollBar.scale then
                        scrollBar.value = math.min(scrollBar.scale, (scrollBar.value + 1) / scrollBar.snapping * scrollBar.scale)
                    else
                        scrollBar.value = math.min(scrollBar.snapping - 1, scrollBar.value + 1)
                    end
                else
                    scrollBar.value = math.min(scrollBar.scale, scrollBar.value + 0.1 * (scrollBar.scale or 1))
                end

                scrollBar.value = scrollBar.connect(scrollBar, scrollBar.value) or scrollBar.value
                if scrollBar.release then scrollBar.release(scrollBar, scrollBar.value) end
            end
        elseif key == "down" or key == "s" then
            if menu.selectedIndex > #menu.levelRects then
                local scrollBar = menu.scrollBars[menu.selectedIndex - #menu.levelRects]

                if scrollBar.snapping then
                    if scrollBar.scale then
                        scrollBar.value = math.max(0, (scrollBar.value - 1) / scrollBar.snapping * scrollBar.scale)
                    else
                        scrollBar.value = math.max(0, scrollBar.value - 1)
                    end
                else
                    scrollBar.value = math.max(0, scrollBar.value - 0.1 * (scrollBar.scale or 1))
                end

                scrollBar.value = scrollBar.connect(scrollBar, scrollBar.value) or scrollBar.value
                if scrollBar.release then scrollBar.release(scrollBar, scrollBar.value) end
            end
        end
    end
end

function Menu.draw(menu)
    love.graphics.setBackgroundColor(0, 0, 0)
    -- love.graphics.setColor(0.2, 0.2, 0.2)
    -- love.graphics.rectangle("fill",
        -- menu.borderX, menu.borderY, state.width - menu.borderX * 2, state.height - menu.borderY * 2)
    -- love.graphics.rectangle("fill",
    --     menu.marginX, menu.marginY, state.width - menu.marginX * 2, state.height - menu.marginY * 2)

    local randCellSize = math.min(state.width, state.height) * 0.2
    local randCellsWidth = state.width / randCellSize
    local randCellsHeight = state.height / randCellSize

    -- x / (randCellsWidth + 1)

    for x = 0, randCellsWidth + 1 do
        for y = 0, randCellsHeight + 1 do
            if (x + y) % 2 == 0 then
                love.graphics.setColor(love.math.colorFromBytes(121, 26, 94))
            else
                love.graphics.setColor(love.math.colorFromBytes(87, 17, 84))
            end
            love.graphics.rectangle(
                "fill",
                -(state.width % randCellSize) / 2 + x * randCellSize,
                -(state.height % randCellSize) / 2 + y * randCellSize,
                randCellSize, randCellSize
            )
        end
    end

    for i, rect in ipairs(menu.levelRects) do
        local realX = menu.marginX + (rect.x / menu.width) * menu.pixelWidth
        local realY = menu.marginY + (rect.y / menu.height) * menu.pixelHeight
        local realW = ((rect.w * rect.scale) / menu.width) * menu.pixelWidth
        local realH = ((rect.h * rect.scale) / menu.height) * menu.pixelHeight

        -- if (rect.hovering or menu.selectedIndex == i) and state.levelClears[rect.levelIndex] and not menu.levelOpening then
        --     love.graphics.setColor(love.math.colorFromBytes(87, 17, 84))
        -- elseif (rect.hovering or menu.selectedIndex == i) and not menu.levelOpening then
        --     love.graphics.setColor(love.math.colorFromBytes(121, 26, 94))
        -- elseif state.levelClears[rect.levelIndex] then
        --     love.graphics.setColor(love.math.colorFromBytes(43, 39, 81))
        -- else
        --     love.graphics.setColor(love.math.colorFromBytes(153, 16, 128))
        -- end

        love.graphics.setColor(0, 0, 0)
        love.graphics.rectangle("fill", realX - realW / 2 + realW / 6, realY - realH / 2 + realH / 6, realW, realH)

        if (rect.hovering or menu.selectedIndex == i) and not menu.levelOpening then
            love.graphics.setColor(love.math.colorFromBytes(121, 26, 94))
        else
            love.graphics.setColor(love.math.colorFromBytes(153, 16, 128))
        end

        love.graphics.rectangle("fill", realX - realW / 2, realY - realH / 2, realW, realH)

        love.graphics.setLineWidth(5)
        if Levels.clears[rect.levelArea .. '/' .. Levels.areas[rect.levelArea].levels[rect.levelIndex].id] then
            love.graphics.setColor(love.math.colorFromBytes(81, 14, 78))
        else
            love.graphics.setColor(love.math.colorFromBytes(121, 26, 94))
        end

        love.graphics.rectangle("line", realX - realW / 2, realY - realH / 2, realW, realH)
        love.graphics.setLineWidth(1)

        love.graphics.setColor(love.math.colorFromBytes(255, 193, 247))
    end

    for i, rect in ipairs(menu.levelRects) do
        local realX = menu.marginX + (rect.x / menu.width) * menu.pixelWidth
        local realY = menu.marginY + (rect.y / menu.height) * menu.pixelHeight
        local realW = ((rect.w * rect.scale) / menu.width) * menu.pixelWidth
        local realH = ((rect.h * rect.scale) / menu.height) * menu.pixelHeight

        local fontWidth = globals.menuFont:getWidth(rect.levelIndex)
        local fontHeight = globals.menuFont:getHeight()

        local text
        local challenge = indexOf(globals.challengeLevels, rect.levelIndex)
        if challenge ~= -1 then
            text = Locale.current == "sitelen_pona" and Locale.convertNumberToSitelenPona(-challenge)
                or "C" .. tostring(challenge)
        else
            text = Locale.current == "sitelen_pona" and Locale.convertNumberToSitelenPona(rect.levelIndex)
                or tostring(rect.levelIndex)
        end

        love.graphics.setColor(love.math.colorFromBytes(255, 255, 255))
        love.graphics.print(text, globals.menuFont,
            realX - fontWidth / 2 + realW / 2, realY - fontHeight / 2 + realH / 2)
    end
    love.graphics.setColor(1, 1, 1)

    -- local padding = menu.pixelSize / 50
    -- local fontHeight = globals.titleFont:getHeight()
    -- love.graphics.print("XPORT by TEAM NOMCAT", globals.titleFont,
    --     padding + menu.marginX, state.height - padding + menu.marginY - fontHeight / 2)

    for i, scrollBar in ipairs(menu.scrollBars) do
        local realX = menu.marginX + (scrollBar.x / menu.width) * menu.pixelWidth
        local realY = menu.marginY + (scrollBar.y / menu.height) * menu.pixelHeight
        local realW = (Menu.scrollBarWidth / menu.width) * menu.pixelWidth
        local realH = (scrollBar.h / menu.height) * menu.pixelHeight

        love.graphics.setColor(0, 0, 0)
        love.graphics.rectangle("fill", realX + realW / 3, realY + realH / 8, realW, realH)

        love.graphics.setColor(love.math.colorFromBytes(43, 39, 81))
        love.graphics.rectangle("fill", realX, realY, realW, realH)

        if i + #menu.levelRects == menu.selectedIndex or scrollBar.sliding then
            love.graphics.setColor(love.math.colorFromBytes(255, 193, 247))
        else
            love.graphics.setColor(love.math.colorFromBytes(255, 255, 255))
        end
        love.graphics.rectangle("fill", realX, realY + (1 - (scrollBar.value / ((scrollBar.scale or scrollBar.snapping or 2) - 1)))  * (realH - realW), realW, realW)

        local font = globals.hintFont
        local transLabel = Locale.localizeText(scrollBar.label)
        local fontWidth = font:getWidth(transLabel)
        local fontHeight = font:getHeight()

        -- love.graphics.setColor(0, 0, 0)
        -- love.graphics.print(transLabel, globals.hintFont,
            -- realX - fontWidth / 2 + realW / 2 + fontWidth / 9, realY + realH + fontHeight / 2 + fontHeight / 9)

        love.graphics.setColor(love.math.colorFromBytes(255, 255, 255))
        love.graphics.print(transLabel, font,
            realX - fontWidth / 2 + realW / 2 + realW / 6, realY + realH + fontHeight / 2)
    end
    love.graphics.setColor(1, 1, 1)
end

function Menu.rectScaleAnim(rect)
    return Animation.new(
        0.2, function(self, progress)
            local progress = easeOutCubic(progress)
            rect.scale = 1 + progress * 0.2
        end
    )
end

function Menu.rectUnscaleAnim(rect)
    return Animation.new(
        0.2, function(self, progress)
            local progress = easeOutCubic(progress)
            rect.scale =  1 + (1 - progress) * 0.2
        end, function()
            if rect.anim then
                rect.anim.stop = true
                rect.anim = nil
            end
        end
    )
end

function Menu.levelStart(menu, rect, realX, realY, realW, realH)
    local newLevel = Level.fromData(Levels.areas[rect.levelArea].levels[rect.levelIndex])
    local r, g, b = newLevel.palette.levelTransition()

    return Animation.chained(
        Animation.new(
            1.5, function(self, progress)
                local progress = easeInOutCubic(progress)
                local scale =
                    math.max(state.width, state.height) * progress * 2
                local angle = progress * 2 * math.pi
                love.graphics.setColor(r, g, b)
                drawRotatedRectangle("fill",
                    realX + realW / 2, realY + realH / 2,
                    scale, scale, angle)
                love.graphics.setColor(1, 1, 1)
            end, function()
                Music.play(Music[Levels.areas[rect.levelArea].levels[rect.levelIndex].musicID])
            end
        ),
        Animation.new(
            0.5, function(self, progress)
                local progress = easeOutCubic(progress)
                local scale = math.max(state.width, state.height)
                love.graphics.setColor(r, g, b, 1 - progress)
                drawRotatedRectangle("fill", state.width / 2, state.height / 2, scale, scale, 0)
                love.graphics.setColor(1, 1, 1)
            end, function()
                noHover(menu)
                state.levelArea = rect.levelArea
                state.levelIndex = rect.levelIndex

                state.level = newLevel

                if (state.levelIndex == 6) then globals.entered_level_six = globals.entered_level_six + 1
                else globals.entered_level_six = 0 end

                Sounds.levelStart:play()
                state.mode = Mode.Gameplay

                rect.clicked = false
                rect.hovering = false
                rect.scale = 1
                menu.levelOpening = false
                forceUpdateGraphics()
            end
        )
    )
end

return Menu
