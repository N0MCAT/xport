if PlayState ~= nil then return PlayState end

local love = require "love"
require "source.scenes.pause"
require "source.graphics.anim"
require "source.play.level"
require "source.data.locale"

PlayState = {}

function PlayState.new(level, config)
    local self = {
        levelStack = {},
        cellSize = 0,
        goalPlaying = false,
        config = config or {},
        layers = {}
    }

    self.config.isEditor = not not self.config.isEditor
    self.config.quitText = self.config.quitText or 'menu.quit'
    -- self.config.quitCallback = self.config.quitCallback or nil

    bindPrototype(self, PlayState)
    self:addLevel(level)

    return self
end

function PlayState.getLevel(self, depth)
    return self.levelStack[#self.levelStack - (depth or 0)]
end

function PlayState.popLevel(self)
    local level = self.levelStack[#self.levelStack];
    self.levelStack[#self.levelStack] = nil
    return level
end

-- @return backToMenu
function PlayState.exitLevel(self, doAnim)
    if doAnim == nil then doAnim = true end
    self.goalPlaying = false
    if #self.levelStack <= 1 then
        if self.config.quitCallback then self.config.quitCallback(self) end
        if not self.config.isEditor then
            state.scene = Menu.new()
            forceUpdateGraphics()

            if doAnim then
                Animation.start(PlayState.fadeFromBlack(2))
            end

            Music.play(Music.menu, 0.5)
        end
        return true
    else
        self:popLevel()
        return false
    end
end

function PlayState.setLevel(self, level, depth)
    self.levelStack[#self.levelStack - (depth or 0)] = level
end

function PlayState.addLevel(self, level)
    self.levelStack[#self.levelStack + 1] = level
end

function PlayState.keypressed(self, key)
    if self.goalPlaying then return end
    if key == "escape" or key == "backspace" then
        if (globals.entered_level_six ~= 6) then
            state.scene = PauseMenu.new(self)
        else
            globals.entered_level_six = 6.66
            self:setLevel(Level.fromData(Levels.areas.man.lobby))
            Animation.start(PlayState.fadeFromBlack(1))
            Music.play(Music[Levels.areas.man.lobby.musicID], 1)
        end
        Sounds.levelRestart:play()
        forceUpdateGraphics()
        return
    end

    local level = self:getLevel()
    level:turn(key)

    if level:isWinning(level) then
        Sounds.levelComplete:play()
        Levels.clears[level.area .. '/' .. level.id] = true
        Save.writeFile(Levels.clears, 'levelClears.xjson')

        local goals = allWithPredicate(level.cells, function(cell)
            return cell.cell == Cell.Goal
        end)

        local startDelay = 0.5
        local goalAnimTime = 2.0
        local endAnimTime = 1.0

        for _, goal in ipairs(goals) do Animation.delayedStart(startDelay, self:levelClearAnim(goalAnimTime, goal)) end
        Animation.delayedStart(startDelay + goalAnimTime, self:levelEndAnim(endAnimTime))

        self.goalPlaying = true
    end
end

function PlayState.onResize(self)
    local level = self:getLevel()
    self.cellSize = math.min(state.width / level.width, state.height / level.height) * 0.65
    level.scale = self.cellSize

    for i = 1, 5 do
        if self.layers[i] ~= nil then self.layers[i]:release() end
        self.layers[i] = love.graphics.newCanvas()
    end
end

function PlayState.reloadFonts(self, overrideFont)
    globals.levelFont = love.graphics.newFont(overrideFont or globals.levelFontFile, math.min(state.width, state.height) * 0.067)
    globals.timerFont = love.graphics.newFont(globals.fontFile, self.cellSize * 0.9)
    globals.ponaTimerFont = love.graphics.newFont(globals.ponaTimerFontFile, self.cellSize * 0.45)
end

function PlayState.update(self, dt)
    Animation.update(dt)
    self:getLevel():update(dt)
end

function PlayState.draw(self)
    local level = self:getLevel()

    -- TODO: Generalize 'layers'
    level:draw(self.layers)

    love.graphics.setCanvas()
    love.graphics.setBlendMode("alpha", "premultiplied")

    for _, layer in ipairs(self.layers) do
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(layer)

        love.graphics.setCanvas(layer)
        love.graphics.clear()
        love.graphics.setCanvas()
    end

    love.graphics.setBlendMode("alpha") -- Default blend mode.

    if level.number ~= "" and level.title ~= "" then
        local padding = self.cellSize / 2
        local header = Locale.localizeText(level.number) .. " - "
        local footer = ""

        if Locale.current == "sitelen_pona" then
            header = "󱤽" .. Locale.levelNumberSitelenPona(level.number) .. "󱤡 「 "
            footer = " 」"
        end

        love.graphics.print(header.. Locale.localizeText(level.title) .. footer, globals.levelFont, padding, padding)
    end

    if level.subtitle then
        local padding = self.cellSize / 2
        local _, fontWrapped = globals.hintFont:getWrap(Locale.localizeText(level.subtitle), state.width - padding)
        local fontHeight = globals.hintFont:getHeight()

        -- all our homies hate printf. i think
        -- love.graphics.printf(subtitle, globals.hintFont, 0, state.height - padding - fontHeight, state.width - padding, "center")

        for i, text in ipairs(fontWrapped) do
            local fontWidth = globals.hintFont:getWidth(text)
            love.graphics.print(text, globals.hintFont, (state.width - fontWidth) / 2,
                state.height - padding - fontHeight * (#fontWrapped - i + 1))
        end
    end

    Animation.draw()
end

function PlayState.levelClearAnim(self, duration, goal)
    local level = self:getLevel()
    local r, g, b = level.palette.levelTransition()
    return Animation.new(duration, function(self, progress)
        progress = easeInOutCubic(progress)
        local scale =
            math.max(state.width, state.height) * progress * 2
        local angle = progress * 2 * math.pi
        love.graphics.setColor(r, g, b)
        drawRotatedRectangle("fill",
            (goal.x + 0.5) * level.scale + (state.width - level.width * level.scale) / 2,
            (goal.y + 0.5) * level.scale + (state.height - level.height * level.scale) / 2,
            scale, scale, angle)
        love.graphics.setColor(1, 1, 1)
    end)
end

function PlayState.levelEndAnim(self, duration)
    local level = self:getLevel()
    local r, g, b = level.palette.levelTransition()
    return Animation.new(duration, function(self, progress)
        progress = easeOutCubic(progress)
        local scale = math.max(state.width, state.height)
        love.graphics.setColor(r, g, b, 1 - progress)
        drawRotatedRectangle("fill", state.width / 2, state.height / 2, scale, scale, 0)
        love.graphics.setColor(1, 1, 1)
    end, function()
        self:exitLevel(false)
    end)
end

function PlayState.fadeFromBlack(duration)
    return Animation.new(duration, function(self, progress)
        love.graphics.setColor(0, 0, 0, 1 - easeOutExpo(progress))
        drawRotatedRectangle("fill", state.width / 2, state.height / 2, state.width, state.height, 0)
        love.graphics.setColor(1, 1, 1)
    end)
end


return PlayState
