if PauseMenu ~= nil then return PauseMenu end

local love = require "love"
require "source.graphics.anim"
require "source.play.level"

PauseMenu = {
    EXIT_TIMER = 0.2,
    ENTER_TIMER = 0.1
}

function PauseMenu.new(playstate)
    local self = {
        scene = playstate,
        context = Element.makeContext(),
        lang = { langIndex = Locale.ilanguages[Locale.current] - 1 },
        dirty = 0,
        resuming = false,
        fadeTimer = 0,
        canvas = nil,
        ui = {}
    }

    bindPrototype(self, PauseMenu)
    self:onResize()
    self:updateUI()
    self.ui[1]:navigate()
    return self
end

function PauseMenu.keypressed(self, key)
    if not self.resuming then
        if key == "escape" or key == "backspace" then
            -- if self.ui[1].ctx.selected then
            --     self.ui[1]:blur()
            -- else
                self.resuming = true
            -- end
        elseif key == "tab" then
            self.ui[1]:navigate((Keyboard.isDown.lshift or Keyboard.isDown.rshift) and -1 or 1, 0)
        elseif not (Keyboard.isDown.lshift or Keyboard.isDown.rshift) and not (Keyboard.isDown.enter or Keyboard.isDown.space) then
            if key == "w" or key == "up" then
                self.ui[1]:navigate(0, -1)
            elseif key == "a" or key == "left" then
                self.ui[1]:navigate(-1, 0)
            elseif key == "s" or key == "down" then
                self.ui[1]:navigate(0, 1)
            elseif key == "d" or key == "right" then
                self.ui[1]:navigate(1, 0)
            end
        end
        self.dirty = 1
    elseif self.scene.keypressed then
        self.scene:keypressed(key)
    end
end

function PauseMenu.updateUI(self)
    self.ui[1] = Element.new(self.context, {
        sizing = {
            width = Size.Fixed { amount = state.width },
            height = Size.Fixed { amount = state.height },
        },
        align = { x = AlignX.Center, y = AlignY.Center },
        color = { 255, 255, 255, 127 },
        layoutDir = LayoutDir.TopToBottom,
        spacing = Size.Adapt { amount = 10 },
        id = "root"
    }, function(ctx)
        local resume = Element.new(ctx, {
            -- sizing = {
            --     width = Size.Adapt { amount = 250 },
            --     height = Size.Adapt { amount = 50 },
            -- },
            padding = { Size.Adapt { amount = 20 }, Size.Adapt { amount = 10 } },
            color = { 255, 255, 255 },
            selectable = true,
            hoverColor = { 255, 193, 247 },
            hoverSound = Sounds.hoverUI,
            id = "resumeButton"
        }, function()
            Element.text(ctx, {
                text = Locale.localizeBit("menu.resume"),
                color = { 0, 0, 0, 255 },
                id = "resumeLabel"
            })
        end)

        if not self.resuming then
            if resume:isJustAccepted() then
                self.resuming = true
            end
        end

        local quit = Element.new(ctx, {
            -- sizing = {
            --     width = Size.Adapt { amount = 250 },
            --     height = Size.Adapt { amount = 50 },
            -- },
            padding = { Size.Adapt { amount = 20 }, Size.Adapt { amount = 10 } },
            color = { 255, 255, 255 },
            selectable = true,
            hoverColor = { 255, 193, 247 },
            hoverSound = Sounds.hoverUI,
            id = "quitButton"
        }, function()
            Element.text(ctx, {
                text = Locale.localizeBit(self.scene.config.quitText),
                color = { 0, 0, 0, 255 },
                id = "quitLabel"
            })
        end)

        if not self.resuming then
            if quit:isJustAccepted() then
                state.scene = self.scene
                if self.scene.exitLevel then
                    self.scene:exitLevel()
                end
            end
        end

        Element.new(self.context, {
            sizing = {
                width = Size.Fit,
                height = Size.Fit,
            },
            align = { x = AlignX.Right, y = AlignY.Center },
            color = { 0, 0, 0, 0 },
            layoutDir = LayoutDir.TopToBottom,
            spacing = Size.Adapt { amount = 10 },
            id = "root"
        }, function(ctx)
            Element.new(ctx, { color = { 0, 0, 0, 0 }, spacing = Size.Adapt { amount = 10 } }, function(ctx)
                local label = Element.text(ctx, {
                    text = Locale.localizeBit("menu.volume.music"),
                    color = { 0, 0, 0, 255 },
                    id = "musicLabel"
                })
                Element.slider(ctx, {
                    sizing = {
                        width = Size.Width { amount = 0.7 },
                        height = Size.Fixed { amount = label:get("height") },
                    },
                    data = state,
                    key = "musicVolume",
                    id = "musicSlider",
                    selectable = true,
                    headHoverSound = Sounds.hoverUI,
                    onChange = function(value)
                        Sounds.move:play(true)
                    end
                })
            end)

            Element.new(ctx, { color = { 0, 0, 0, 0 }, spacing = Size.Adapt { amount = 10 } }, function(ctx)
                local label = Element.text(ctx, {
                    text = Locale.localizeBit("menu.volume.sfx"),
                    color = { 0, 0, 0, 255 },
                    id = "sfxLabel"
                })
                Element.slider(ctx, {
                    sizing = {
                        width = Size.Width { amount = 0.7 },
                        height = Size.Fixed { amount = label:get("height") },
                    },
                    data = state,
                    key = "sfxVolume",
                    id = "sfxSlider",
                    selectable = true,
                    headHoverSound = Sounds.hoverUI,
                    onChange = function(value)
                        Sounds.move:play()
                    end
                })
            end)
        end)

        Element.text(ctx, {
            text = Locale.localizeBit("menu.language"),
            color = { 0, 0, 0, 255 },
            id = "languageLabel"
        })
        Element.slider(ctx, {
            sizing = {
                width = Size.Adapt { amount = 200 },
                height = Size.Adapt { amount = 42 },
            },
            data = self.lang,
            key = "langIndex",
            id = "localeSlider",
            selectable = true,
            headHoverSound = Sounds.hoverUI,
            snapping = #Locale.languages,
            onChange = function(value)
                local newLang = Locale.languages[value + 1]
                Locale.changeLanguage(newLang)
                self.dirty = 3
                return value
            end
        })
    end)

    for _, ui in ipairs(self.ui) do
        ui:initialize()
    end

    resetJustDown()
end

function PauseMenu.mousemoved(self, x, y, dx, dy, istouch)
    self.dirty = 1
end

function PauseMenu.mousepressed(self, x, y, button, istouch, presses)
    self.dirty = 1
end

function PauseMenu.onResize(self)
    if self.scene.onResize then self.scene:onResize() end
    if self.canvas ~= nil then self.canvas:release() end
    self.canvas = love.graphics.newCanvas()
    self.dirty = 4
end

function PauseMenu.reloadFonts(self, overrideFont)
    if self.scene.reloadFonts then self.scene:reloadFonts(overrideFont) end
end

function PauseMenu.update(self, dt)
    while self.dirty > 0 do
        self.dirty = self.dirty - 1
        self:updateUI()
    end

    if self.resuming then
        self.fadeTimer = self.fadeTimer - (dt / PauseMenu.EXIT_TIMER)
        if self.fadeTimer <= 0 then
            state.scene = self.scene
        end
    else
        if self.fadeTimer > 1 then
            self.fadeTimer = 1
        elseif self.fadeTimer < 1 then
            self.fadeTimer = self.fadeTimer + (dt / PauseMenu.ENTER_TIMER)
        end
    end
end

function PauseMenu.draw(self)
    if self.scene.draw then self.scene:draw() end
    love.graphics.setCanvas(self.canvas)

    love.graphics.setCanvas(self.canvas)
    for _, ui in ipairs(self.ui) do ui:draw() end

    love.graphics.setCanvas()
    love.graphics.setBlendMode("alpha", "premultiplied")

    local alpha = self.fadeTimer
    love.graphics.setColor(alpha, alpha, alpha, alpha)
    love.graphics.draw(self.canvas)

    love.graphics.setCanvas(self.canvas)
    love.graphics.clear()
    love.graphics.setCanvas()

    love.graphics.setBlendMode("alpha")
    love.graphics.setColor(1, 1, 1)
end

return PauseMenu
