if Element ~= nil then return Element end

local love = require "love"
Element = {}

Size = {
    Fit = {},
    Fixed = { amount = 0 },
    Grow = {},
} enumerate(Size)

AlignX = {
    Left = {},
    Center = {},
    Right = {},
} enumerate(AlignX)

AlignY = {
    Top = {},
    Center = {},
    Bottom = {},
} enumerate(AlignY)

LayoutDir = {
    LeftToRight = {},
    TopToBottom = {},
} enumerate(LayoutDir)

local function validateElement(element)
    element.sizing = element.sizing or {}
    element.sizing.width = element.sizing.width or Size.Fit
    element.sizing.height = element.sizing.height or Size.Fit

    element.padding = element.padding or {}
    element.padding.left = element.padding[1] or 0
    element.padding.right = element.padding[2] or 0
    element.padding.up = element.padding[3] or 0
    element.padding.down = element.padding[4] or 0

    element.align = element.align or {}
    element.align.x = element.align.x or AlignX.Left
    element.align.y = element.align.y or AlignY.Top

    element.spacing = element.spacing or 0

    element.position = element.position or {}
    element.position.x = element.position.x or 0
    element.position.y = element.position.y or 0

    element.layoutDir = element.layoutDir or LayoutDir.LeftToRight

    element.color = element.color or { 255, 255, 255, 255 }
    element.color[4] = element.color[4] or 255
    element.hoverColor = element.hoverColor or element.color
    element.hoverColor[4] = element.hoverColor[4] or 255

    -- absolute values
    element.width = 0
    element.height = 0
    element.x = 0
    element.y = 0

    -- element.id = element.id or nil
    element.children = {}

    local metatable = {
        __index = function(self, index)
            return Element[index]
        end
    }

    setmetatable(element, metatable)
end

function Element.test()
    state.rootElement = Element.new(state.ui, {
        sizing = {
            width = Size.Fixed { amount = state.width },
            height = Size.Fixed { amount = state.height },
        },
        align = { x = AlignX.Center, y = AlignY.Center },
        color = { 255, 255, 255, 50 },
        layoutDir = LayoutDir.TopToBottom,
        spacing = state.height * 0.1,
        id = "root"
    }, function(ctx)
        Element.slider(ctx, {
            sizing = {
                width = Size.Fixed { amount = state.width * 0.7 },
                height = Size.Fixed { amount = state.height * 0.05 },
            },
            data = state,
            key = "musicVolume",
            id = "musicSlider",
            connect = function(value)
                Sounds.move:play(true)
            end
        })
        Element.slider(ctx, {
            sizing = {
                width = Size.Fixed { amount = state.width * 0.5 },
                height = Size.Fixed { amount = state.height * 0.1 },
            },
            snapping = #Locale.languages,
            id = "localeSlider",
            connect = function(value)
                local newLang = Locale.languages[value + 1]
                Locale.changeLanguage(newLang)
                return value
            end
        })
    end)
    Element.initialize(state.rootElement)
end

function Element.isHovered(element)
    if element.id then
        local savedElement = element.ctx.ids[element.id]
        if savedElement then
            if pointInRect(Mouse.x, Mouse.y,
                savedElement.x, savedElement.y, savedElement.width, savedElement.height) then
                return true
            end
        end
    end
    return false
end

function Element.isPressed(element)
    return element:isHovered() and Mouse.isDown[1]
end

function Element.isJustClicked(element)
    return element:isHovered() and Mouse.justDown[1]
end

function Element.get(element, key)
    if element.id then
        local savedElement = element.ctx.ids[element.id]
        if savedElement then
            return savedElement[key]
        end
    end
end

function Element.set(element, key, value)
    if element.id then
        local savedElement = element.ctx.ids[element.id]
        if savedElement then
            savedElement[key] = value
        end
    end
end

function Element.slider(ctx, config)
    config.minValue = config.minValue or 0
    config.maxValue = config.maxValue or ((config.snapping or 2) - 1)
    config.id = config.id or config.key
    config.key = config.key or "value"

    config.color = config.color or { 43, 39, 81, 255 }
    config.headColor = config.headColor or { 255, 255, 255, 255 }
    config.headHoverColor = config.headHoverColor or { 255, 193, 247, 255 }

    Element.new(ctx, config, function(ctx)
        -- For sliders that don't directly modify external data,
        -- it can be omitted so that the parent itself handles the data.
        if config.data == nil then
            ctx.parent.sliderData = ctx.parent:get("sliderData") or {}
            config.data = ctx.parent.sliderData
        end

        config.data[config.key] = config.data[config.key] or config.minValue

        local pWidth, pHeight = ctx.parent:get("width"), ctx.parent:get("height")
        local head = Element.new(ctx, {
            sizing = {
                width = Size.Fixed { amount = pHeight },
                height = Size.Fixed { amount = pHeight },
            },
            color = config.headColor,
            hoverColor = config.headHoverColor,
            id = config.id .. "#head"
        })

        if pWidth then
            local headSize = pHeight

            if head:isJustClicked() then
                ctx.parent:set("sliderOffset", Mouse.x - head:get("x"))
                ctx.parent:set("dragging", true)
            elseif ctx.parent:isJustClicked() then
                ctx.parent:set("sliderOffset", headSize * 0.5)
                ctx.parent:set("dragging", true)
            end

            if Mouse.isDown[1] and ctx.parent:get("dragging") then
                local sliderOffset = ctx.parent:get("sliderOffset")
                ctx.parent.sliderOffset = sliderOffset
                ctx.parent.dragging = true

                local value = ((Mouse.x - ctx.parent:get("x") - sliderOffset) / (pWidth - headSize))

                if config.snapping then
                    value = math.floor(value * (config.snapping - 1) + 0.5)
                    if config.snapping == (config.maxValue - config.minValue) then
                        value = value + config.minValue
                    else
                        value = value / (config.snapping - 1) * (config.maxValue - config.minValue) + config.minValue
                    end
                else
                    value = value * (config.maxValue - config.minValue) + config.minValue
                end

                value = clamp(config.minValue, value, config.maxValue)

                local oldValue = config.data[config.key]
                config.data[config.key] = value
                if oldValue ~= value and config.connect then config.connect(value) end
            end
            head.position.x = (config.data[config.key] - config.minValue) / (config.maxValue - config.minValue) * (pWidth - headSize)
            print(config.data[config.key])
        end
    end)
end

function Element.makeContext()
    return {
        ids = {},
        parent = nil,
    }
end

function Element.new(ctx, config, inner)
    local self = {
        ctx = ctx,
        inner = inner or function(_) end,
    }

    for key, value in pairs(config) do self[key] = value end
    validateElement(self)

    local previousParent = ctx.parent
    ctx.parent = self
    self.inner(ctx)

    ctx.parent = previousParent
    if ctx.parent then
        table.insert(ctx.parent.children, self)
        self.parent = ctx.parent
    end

    return self
end

function Element.calculateFitSizes(element)
    for _, child in ipairs(element.children) do
        Element.calculateFitSizes(child)
    end

    element.width = element.width + element.padding.left + element.padding.right
    element.height = element.height + element.padding.up + element.padding.down

    if element.sizing.width:is("Fixed") then
        element.width = element.width + element.sizing.width.amount
    end

    if element.sizing.height:is("Fixed") then
        element.height = element.height + element.sizing.height.amount
    end

    if element.sizing.width:is("Fit") then
        if element.layoutDir:is("LeftToRight") then
            local widths = 0
            for _, child in ipairs(element.children) do
                widths = widths + child.width
            end
            element.width = element.width + widths + element.spacing * (#element.children - 1)
        else
            local maxWidth = 0
            for _, child in ipairs(element.children) do
                if child.width > maxWidth then
                    maxWidth = child.width
                end
            end
            element.width = element.width + maxWidth
        end
    end

    if element.sizing.height:is("Fit") then
        if element.layoutDir:is("LeftToRight") then
            local maxHeight = 0
            for _, child in ipairs(element.children) do
                if child.height > maxHeight then
                    maxHeight = child.height
                end
            end
            element.height = element.height + maxHeight
        else
            local heights = 0
            for _, child in ipairs(element.children) do
                heights = heights + child.height
            end
            element.height = element.height + heights + element.spacing * (#element.children - 1)
        end
    end
end

function Element.calculateGrowSizes(element)
    if element.layoutDir:is("LeftToRight") then
        local widths = 0
        for _, child in ipairs(element.children) do
            widths = widths + child.width
        end

        local remainingWidth = element.width - widths - element.spacing * (#element.children - 1) - element.padding
            .right - element.padding.left

        local growables = {}
        for _, child in ipairs(element.children) do
            if child.sizing.width:is("Grow") then
                table.insert(growables, child)
            end
        end

        while #growables > 0 and remainingWidth > 1 do
            local smallest = growables[1]
            local secondSmallest
            local addingWidth = remainingWidth
            for _, growable in ipairs(growables) do
                if growable.width < smallest.width then
                    secondSmallest = smallest
                    smallest = growable
                end
                if growable.width > smallest.width then
                    if growable.width < secondSmallest.width then
                        secondSmallest = growable
                    end
                    addingWidth = secondSmallest.width - smallest.width
                end
            end

            addingWidth = math.min(addingWidth, remainingWidth / #growables)

            for _, child in ipairs(growables) do
                if child.width == smallest.width then
                    child.width = child.width + addingWidth
                    remainingWidth = remainingWidth - addingWidth
                end
            end
        end

        for _, child in ipairs(element.children) do
            if child.sizing.height:is("Grow") then
                local remainingHeight = element.height - child.height - element.padding.up - element.padding.down
                child.height = child.height + remainingHeight
            end
        end
    elseif element.layoutDir:is("TopToBottom") then
        local heights = 0
        for _, child in ipairs(element.children) do
            heights = heights + child.height
        end

        local remainingHeight = element.height - heights - element.spacing * (#element.children - 1) - element.padding
            .down - element.padding.up

        local growables = {}
        for _, child in ipairs(element.children) do
            if child.sizing.height:is("Grow") then
                table.insert(growables, child)
            end
        end

        while #growables > 0 and remainingHeight > 1 do
            local smallest = growables[1]
            local secondSmallest
            local addingHeight = remainingHeight
            for _, growable in ipairs(growables) do
                if growable.height < smallest.height then
                    secondSmallest = smallest
                    smallest = growable
                end
                if growable.height > smallest.height then
                    if growable.height < secondSmallest.height then
                        secondSmallest = growable
                    end
                    addingHeight = secondSmallest.height - smallest.height
                end
            end

            addingHeight = math.min(addingHeight, remainingHeight / #growables)

            for _, child in ipairs(growables) do
                if child.height == smallest.height then
                    child.height = child.height + addingHeight
                    remainingHeight = remainingHeight - addingHeight
                end
            end
        end

        for _, child in ipairs(element.children) do
            if child.sizing.width:is("Grow") then
                local remainingWidth = element.width - child.width - element.padding.left - element.padding.right
                child.width = child.width + remainingWidth
            end
        end
    end

    for _, child in ipairs(element.children) do
        Element.calculateGrowSizes(child)
    end
end

function Element.calculatePositions(element)
    element.x = element.x + element.position.x
    element.y = element.y + element.position.y

    if element.layoutDir:is("LeftToRight") then
        local widths = 0
        for _, child in ipairs(element.children) do
            widths = widths + child.width
        end

        local remainingWidth = element.width - widths - element.spacing * (#element.children - 1)
        local leftPad = element.x

        if element.align.x:is("Left") then
            leftPad = leftPad + element.padding.left
        elseif element.align.x:is("Center") then
            leftPad = leftPad + remainingWidth / 2
        elseif element.align.x:is("Right") then
            leftPad = leftPad + remainingWidth - element.padding.right
        end


        for _, child in ipairs(element.children) do
            child.x = child.x + leftPad
            local remainingHeight = element.height - child.height

            local upPad = element.y
            if element.align.y:is("Top") then
                upPad = upPad + element.padding.up
            elseif element.align.y:is("Center") then
                upPad = upPad + remainingHeight / 2
            elseif element.align.y:is("Bottom") then
                upPad = upPad + remainingHeight - element.padding.down
            end

            child.y = child.y + upPad
            leftPad = leftPad + element.spacing + child.width
            Element.calculatePositions(child)
        end
    else
        local heights = 0
        for _, child in ipairs(element.children) do
            heights = heights + child.height
        end

        local remainingHeight = element.height - heights - element.spacing * (#element.children - 1)
        local upPad = element.y

        if element.align.y:is("Top") then
            upPad = upPad + element.padding.up
        elseif element.align.y:is("Center") then
            upPad = upPad + remainingHeight / 2
        elseif element.align.y:is("Bottom") then
            upPad = upPad + remainingHeight - element.padding.down
        end

        for _, child in ipairs(element.children) do
            child.y = child.y + upPad
            local remainingWidth = element.width - child.width

            local leftPad = element.x
            if element.align.x:is("Left") then
                leftPad = leftPad + element.padding.left
            elseif element.align.x:is("Center") then
                leftPad = leftPad + remainingWidth / 2
            elseif element.align.x:is("Right") then
                leftPad = leftPad + remainingWidth - element.padding.right
            end

            child.x = child.x + leftPad
            upPad = upPad + element.spacing + child.height
            Element.calculatePositions(child)
        end
    end
end

function Element.draw(element)
    love.graphics.setColor(element.color[1] / 255, element.color[2] / 255, element.color[3] / 255, element.color[4] / 255)
    love.graphics.rectangle("fill", element.x, element.y, element.width, element.height)
    love.graphics.setColor(1, 1, 1)

    for _, child in ipairs(element.children) do
        Element.draw(child)
    end
end

-- function Element.startAction(element)
--     if element.action then element.action() end
--     for _, child in ipairs(element.children) do
--         Element.startAction(child)
--     end
-- end

function Element.saveElements(element)
    if element.id ~= nil then
        element.ctx.ids[element.id] = element
    end

    for _, child in ipairs(element.children) do
        Element.saveElements(child)
    end
end

function Element.actions(element)
    if element:isHovered() then
        element.color = element.hoverColor
    end

    for _, child in ipairs(element.children) do
        Element.actions(child)
    end
end

function Element.initialize(element)
    Element.calculateFitSizes(element)
    Element.calculateGrowSizes(element)
    Element.calculatePositions(element)
    Element.saveElements(element)
    Element.actions(element)
    -- Element.startAction(element)
end

return Element
