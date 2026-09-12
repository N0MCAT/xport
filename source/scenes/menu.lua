if Menu ~= nil then return Menu end

local love = require "love"
require "source.graphics.anim"
require "source.play.level"

Menu = {}
Menu.scrollBarWidth = 0.05

function Menu.new()
    local self = {
        levelOpening = false,
        context = Element.makeContext(),

        dirty = 0,
        ui = {}
    }

    bindPrototype(self, Menu)
    self:onResize()
    self:updateUI()
    self.ui[1]:navigate()
    self.ui[1]:navigate(1)
    return self
end

function Menu.keypressed(self, key)
    if key == "tab" then
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
end

function Menu.level(self, index)
    local level = Element.new(self.context, {
        sizing = {
            width = Size.Adapt { amount = 60 },
            height = Size.Adapt { amount = 60 },
        },
        hoverColor = { 255, 193, 247 },
        hoverSound = Sounds.hoverUI,
        selectable = true,
        align = { x = AlignX.Center, y = AlignY.Center },
        spacing = Size.Adapt { amount = 10 },
        id = "levelRect#" .. tostring(index)
    }, function(ctx)
        Element.text(ctx, {
            text = tostring(index),
            color = { 0, 0, 0, 255 }
        })
    end)

    if not self.levelOpening and level:isJustAccepted() then
        Animation.start(self:levelStart("demoworld", index, level:get("x"), level:get("y"), level:get("width"), level:get("height")))
        self.levelOpening = true
        Sounds.selectUI:play()
    end
end

function Menu.updateUI(self)
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
        Element.new(self.context, {
            sizing = {
                width = Size.Fit,
                height = Size.Fit,
            },
            align = { x = AlignX.Right, y = AlignY.Center },
            color = { 0, 0, 0, 0 },
            layoutDir = LayoutDir.LeftToRight,
            spacing = Size.Adapt { amount = 20 },
            id = "root"
        }, function(ctx)
            Element.new(ctx, {
                sizing = {
                    width = Size.Adapt { amount = 200 },
                    height = Size.Fit,
                },
                color = { 0, 0, 0, 0 },
                spacing = Size.Adapt { amount = 10 },
                layoutDir = LayoutDir.TopToBottom,
                align = { x = AlignX.Center, y = AlignY.Center },
            }, function(ctx)
                local label = Element.text(ctx, {
                    text = Locale.localizeBit("menu.volume.music"),
                    color = { 0, 0, 0, 255 },
                    id = "musicLabel"
                })
                Element.slider(ctx, {
                    sizing = {
                        width = Size.Adapt { amount = 50 },
                        height = Size.Height { amount = 0.7 },
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

            Element.new(ctx, {
                color = { 0, 0, 0, 0 },
                spacing = Size.Adapt { amount = 75 },
                layoutDir = LayoutDir.TopToBottom,
                align = { x = AlignX.Center, y = AlignY.Center },
            }, function(ctx)
                Element.new(ctx, {
                    color = { 0, 0, 0, 0 },
                    spacing = Size.Adapt { amount = 20 },
                    layoutDir = LayoutDir.TopToBottom,
                    align = { x = AlignX.Center, y = AlignY.Center },
                }, function(ctx)
                    for y = 1, 4 do
                        Element.new(self.context, {
                            sizing = {
                                width = Size.Fit,
                                height = Size.Fit,
                            },
                            align = { x = AlignX.Center, y = AlignY.Center },
                            color = { 0, 0, 0, 0 },
                            layoutDir = LayoutDir.LeftToRight,
                            spacing = Size.Adapt { amount = 10 },
                            id = "root"
                        }, function(ctx)
                            for x = 1, 3 do
                                local levelIndex = x + ((y - 1) * 3)
                                if levelIndex > 10 then break end
                                self:level(levelIndex)
                            end
                        end)
                    end
                end)


                Element.new(ctx, {
                    color = { 0, 0, 0, 0 },
                    spacing = Size.Adapt { amount = 20 },
                    layoutDir = LayoutDir.TopToBottom,
                    align = { x = AlignX.Center, y = AlignY.Center },
                }, function(ctx)
                    Element.new(self.context, {
                        sizing = {
                            width = Size.Fit,
                            height = Size.Fit,
                        },
                        align = { x = AlignX.Center, y = AlignY.Center },
                        color = { 0, 0, 0, 0 },
                        layoutDir = LayoutDir.LeftToRight,
                        spacing = Size.Adapt { amount = 10 },
                        id = "root"
                    }, function(ctx)
                        for x = 1, 2 do self:level(10 + x) end
                    end)

                    Element.new(self.context, {
                        sizing = {
                            width = Size.Fit,
                            height = Size.Fit,
                        },
                        align = { x = AlignX.Center, y = AlignY.Center },
                        color = { 0, 0, 0, 0 },
                        layoutDir = LayoutDir.LeftToRight,
                        spacing = Size.Adapt { amount = 10 },
                        id = "root"
                    }, function(ctx)
                        for x = 1, 3 do self:level(12 + x) end
                    end)
                end)
            end)

            Element.new(ctx, {
                sizing = {
                    width = Size.Adapt { amount = 200 },
                    height = Size.Fit,
                },
                color = { 0, 0, 0, 0 },
                spacing = Size.Adapt { amount = 10 },
                layoutDir = LayoutDir.TopToBottom,
                align = { x = AlignX.Center, y = AlignY.Center },
            }, function(ctx)
                local label = Element.text(ctx, {
                    text = Locale.localizeBit("menu.volume.sfx"),
                    color = { 0, 0, 0, 255 },
                    id = "sfxLabel"
                })
                Element.slider(ctx, {
                    sizing = {
                        width = Size.Adapt { amount = 50 },
                        height = Size.Height { amount = 0.7 },
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

function Menu.reloadFonts(self, overrideFont)
    globals.menuFont = love.graphics.newFont(overrideFont or globals.fontFile, math.min(state.width, state.height) * 0.06)
end

function Menu.onResize(self)
    self.dirty = 4
end

function Menu.update(self, dt)
    Animation.update(dt)
    while self.dirty > 0 do
        self.dirty = self.dirty - 1
        self:updateUI()
    end
end

function Menu.draw(self)
    for _, ui in ipairs(self.ui) do ui:draw() end
    Animation.draw()
end

function Menu.mousemoved(self, x, y, dx, dy, istouch)
    self.dirty = 1
end

function Menu.mousepressed(self, x, y, button, istouch, presses)
    self.dirty = 1
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

function Menu.levelStart(menu, area, index, realX, realY, realW, realH)
    local newLevel = Level.fromData(Levels.areas[area].levels[index])
    local r, g, b = newLevel.palette.levelTransition()

    return Animation.chained(
        Animation.new(
            1.5, function(self, progress)
                progress = easeInOutCubic(progress)
                local scale =
                    math.max(state.width, state.height) * progress * 2
                local angle = progress * 2 * math.pi
                love.graphics.setColor(r, g, b)
                drawRotatedRectangle("fill",
                    realX + realW / 2, realY + realH / 2,
                    scale, scale, angle)
                love.graphics.setColor(1, 1, 1)
            end, function()
                Music.play(Music[Levels.areas[area].levels[index].musicID])
            end
        ),
        Animation.new(
            0.5, function(self, progress)
                progress = easeOutCubic(progress)
                local scale = math.max(state.width, state.height)
                love.graphics.setColor(r, g, b, 1 - progress)
                drawRotatedRectangle("fill", state.width / 2, state.height / 2, scale, scale, 0)
                love.graphics.setColor(1, 1, 1)
            end, function()
                state.levelArea = area
                state.levelIndex = index

                state.scene = PlayState.new(newLevel)

                if (state.levelIndex == 6) then globals.entered_level_six = globals.entered_level_six + 1
                else globals.entered_level_six = 0 end

                Sounds.levelStart:play()
                menu.levelOpening = false

                forceUpdateGraphics()
            end
        )
    )
end

return Menu
