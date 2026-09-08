if PauseMenu ~= nil then return PauseMenu end

local love = require "love"
require "source.graphics.anim"
require "source.play.level"

PauseMenu = {
    EXIT_TIMER = 0.2
}

function PauseMenu.new(playstate)
    local self = {
        scene = playstate,
        context = Element.makeContext(),
        resuming = false,
        exitTimer = PauseMenu.EXIT_TIMER,
        canvas = nil,
        ui = {}
    }

    bindPrototype(self, PauseMenu)
    self:onResize()
    return self
end

function PauseMenu.keypressed(self, key)
    if not self.resuming then
        if key == "escape" or key == "backspace" then
            self.resuming = true
        end
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
            sizing = {
                width = Size.Adapt { amount = 250 },
                height = Size.Adapt { amount = 50 },
            },
            color = { 255, 255, 255 },
            hoverColor = { 255, 193, 247 },
            id = "resumeButton"
        })

        if not self.resuming then
            if resume:isJustClicked() then
                self.resuming = true
            end
        end

        local quit = Element.new(ctx, {
            sizing = {
                width = Size.Adapt { amount = 250 },
                height = Size.Adapt { amount = 50 },
            },
            color = { 255, 255, 255 },
            hoverColor = { 255, 193, 247 },
            id = "quitButton"
        })

        if not self.resuming then
            if quit:isJustClicked() then
                state.scene = self.scene
                if self.scene.exitLevel then
                    self.scene:exitLevel()
                end
            end
        end

        Element.slider(ctx, {
            sizing = {
                width = Size.Width { amount = 0.7 },
                height = Size.Adapt { amount = 36 },
            },
            data = state,
            key = "musicVolume",
            id = "musicSlider",
            onChange = function(value)
                Sounds.move:play(true)
            end
        })

        Element.slider(ctx, {
            sizing = {
                width = Size.Width { amount = 0.7 },
                height = Size.Adapt { amount = 36 },
            },
            data = state,
            key = "sfxVolume",
            id = "sfxSlider",
            onChange = function(value)
                Sounds.move:play()
            end
        })

        -- Locale can't be changed mid-game, unfortunately...
        -- Element.slider(ctx, {
        --     sizing = {
        --         width = Size.Fixed { amount = state.width * 0.1 },
        --         height = Size.Fixed { amount = state.height * 0.5 },
        --     },
        --     snapping = #Locale.languages,
        --     id = "localeSlider",
        --     onChange = function(value)
        --         local newLang = Locale.languages[value + 1]
        --         Locale.changeLanguage(newLang)
        --         return value
        --     end
        -- })
    end)

    for _, ui in ipairs(self.ui) do
        ui:initialize()
    end
end

function PauseMenu.mousemoved(self, x, y, dx, dy, istouch)
    self:updateUI()
end

function PauseMenu.mousepressed(self, x, y, button, istouch, presses)
    self:updateUI()
end

function PauseMenu.onResize(self)
    if self.scene.onResize then self.scene:onResize() end
    if self.canvas ~= nil then self.canvas:release() end
    self.canvas = love.graphics.newCanvas()
    self:updateUI()
end

function PauseMenu.reloadFonts(self, overrideFont)
end

function PauseMenu.update(self, dt)
    -- self:updateUI()
    if self.resuming then
        self.exitTimer = self.exitTimer - dt
        if self.exitTimer <= 0 then
            state.scene = self.scene
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

    local alpha = self.exitTimer / PauseMenu.EXIT_TIMER
    love.graphics.setColor(alpha, alpha, alpha, alpha)
    love.graphics.draw(self.canvas)

    love.graphics.setCanvas(self.canvas)
    love.graphics.clear()
    love.graphics.setCanvas()

    love.graphics.setBlendMode("alpha")
    love.graphics.setColor(1, 1, 1)
end

return PauseMenu
