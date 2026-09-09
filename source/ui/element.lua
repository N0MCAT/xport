if Element ~= nil then return Element end

local love = require "love"
Element = {}

Size = {
    Fit = {},
    Fixed = { amount = 0 },
    Adapt = { amount = 0 },
    Width = { amount = 0 },
    Height = { amount = 0 },
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
    element.type = element.type or "generic"

    element.sizing = element.sizing or {}
    element.sizing.width = element.sizing.width or Size.Fit
    element.sizing.height = element.sizing.height or Size.Fit
    element.sizing.minWidth = Element.parseSize(element.sizing.minWidth) or nil

    element.padding = element.padding or {}
    if #element.padding == 1 then
        local pad = element.padding[1]
        element.padding[1] = pad
        element.padding[2] = pad
        element.padding[3] = pad
        element.padding[4] = pad
    elseif #element.padding == 2 then
        local horizontal, vertical = element.padding[1], element.padding[2]
        element.padding[1] = horizontal
        element.padding[2] = horizontal
        element.padding[3] = vertical
        element.padding[4] = vertical
    end

    element.padding.left = Element.parseSize(element.padding[1]) or 0
    element.padding.right = Element.parseSize(element.padding[2]) or 0
    element.padding.up = Element.parseSize(element.padding[3]) or 0
    element.padding.down = Element.parseSize(element.padding[4]) or 0

    element.align = element.align or {}
    element.align.x = element.align.x or AlignX.Left
    element.align.y = element.align.y or AlignY.Top

    element.spacing = Element.parseSize(element.spacing) or 0

    element.position = element.position or {}
    element.position.x = Element.parseSize(element.position.x) or 0
    element.position.y = Element.parseSize(element.position.y) or 0

    element.layoutDir = element.layoutDir or LayoutDir.LeftToRight

    element.color = element.color or { 255, 255, 255, 255 }
    element.color[4] = element.color[4] or 255
    element.hoverColor = element.hoverColor or element.color
    element.hoverColor[4] = element.hoverColor[4] or 255

    if element.hoverable == nil then element.hoverable = element.color[4] >= 127 end
    if element.selectable == nil then element.selectable = false end

    -- absolute values
    element.width = 0
    element.height = 0
    element.x = 0
    element.y = 0

    element.itemType = element.itemType or "generic"

    -- element.id = element.id or nil
    element.children = {}
end

function Element.hasChildHovered(element, exclusion)
    if element.children and #element.children > 0 then
        for _, child in ipairs(element.children) do
            if child ~= exclusion and child:hasChildHovered(exclusion) then
                return true
            end
        end
    else
        return element:isHovered()
    end
    return false
end

function Element.isSelected(element)
    return element.ctx.selected and (element.id == element.ctx.selected)
end

function Element.isHovered(element)
    if not element.hoverable then return false end
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

function Element.isKeyed(element)
    return element:isSelected() and Controls.isDown("accept")
end

function Element.isAccepted(element)
    return element:isPressed() or element:isKeyed()
end

function Element.isJustClicked(element)
    return element:isHovered() and Mouse.justDown[1]
end

function Element.isJustKeyed(element)
    return element:isSelected() and Controls.justDown("accept")
end

function Element.isJustAccepted(element)
    return element:isJustClicked() or element:isJustKeyed()
end

-- function Element.isJustHovered(element)
--     return element:isHovered() and not element:get("hovered")
-- end

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

function Element.text(ctx, config)
    local text = Element.new(ctx, config, nil, function(element)
        element.font = element.font or globals.hintFont
        element.text = element.text or "Lorem ipsum"

        -- local longestWordWidth = 0
        -- for _, word in ipairs(string.split(element.text, "%s")) do
        --     local currentWordWidth = element.font:getWidth(word)
        --     if currentWordWidth > longestWordWidth then
        --         longestWordWidth = currentWordWidth
        --     end
        -- end

        -- element.sizing.minWidth = longestWordWidth
    end)
    text.width = text.font:getWidth(text.text)
    text.height = text.font:getHeight()

    text.itemType = "text"
    return text
end

function Element.slider(ctx, config)
    local autoLayout = config.layoutDir == nil
    -- Custom validation was moved to the bottom!

    return Element.new(ctx, config, function(ctx)
        local parent = ctx.parent

        -- For sliders that don't directly modify external data,
        -- it can be omitted so that the parent itself handles the data.
        if parent.data == nil then
            parent.data = parent:get("data") or {}
        end

        parent.data[parent.key] = parent.data[parent.key] or parent.minValue
        local pWidth, pHeight = parent:get("width"), parent:get("height")

        if pWidth then
            if autoLayout then
                if pWidth < pHeight then
                    parent.layoutDir = LayoutDir.TopToBottom
                else
                    parent.layoutDir = LayoutDir.LeftToRight
                end
            end

            local isHorizontal = parent.layoutDir:is(LayoutDir.LeftToRight)
            if not isHorizontal then parent.invert = not parent.invert end

            local headSize = isHorizontal and pHeight or pWidth
            local bodySize = isHorizontal and pWidth or pHeight
            local axis = isHorizontal and "x" or "y"

            local head = Element.new(ctx, {
                sizing = {
                    width = Size.Fixed { amount = headSize },
                    height = Size.Fixed { amount = headSize },
                },
                color = parent.headColor,
                hoverColor = parent.headHoverColor,
                hoverSound = parent.headHoverSound,
                selectable = parent.selectable,
                id = parent.id .. "#head"
            })

            parent.head = head
            parent.selectable = false
            if head:isJustClicked() then
                parent:set("sliderOffset", Mouse[axis] - head:get(axis))
                parent:set("dragging", true)
            elseif parent:isJustClicked() then
                parent:set("sliderOffset", headSize * 0.5)
                parent:set("dragging", true)
            end

            if head:isSelected() and (Controls.isDown("accept") or Controls.isDown("shift")) then
                local isInc, isDec = Controls.justDown("right") or Controls.justDown("up"),
                    Controls.justDown("left") or Controls.justDown("down")

                if isInc or isDec then
                    local dir = isInc and 1 or -1
                    local value = (parent.data[parent.key] - parent.minValue) / (parent.maxValue - parent.minValue)
                    if parent.invert then value = 1 - value end

                    if parent.snapping then
                        value = math.floor((value + dir / parent.snapping) * (parent.snapping - 1) + 0.5)
                        if parent.snapping == (parent.maxValue - parent.minValue) then
                            value = value + parent.minValue
                        else
                            value = value / (parent.snapping - 1) * (parent.maxValue - parent.minValue) + parent.minValue
                        end
                    else
                        value = (value + dir / headSize) * (parent.maxValue - parent.minValue) + parent.minValue
                    end

                    value = clamp(parent.minValue, value, parent.maxValue)

                    local oldValue = parent.data[parent.key]
                    parent.data[parent.key] = value
                    if oldValue ~= value and parent.onChange then parent.onChange(value) end
                end
            end

            if Mouse.isDown[1] and parent:get("dragging") then
                local sliderOffset = parent:get("sliderOffset")
                parent.sliderOffset = sliderOffset
                parent.dragging = true

                local value = ((Mouse[axis] - parent:get(axis) - sliderOffset) / (bodySize - headSize))
                if parent.invert then value = 1 - value end

                if parent.snapping then
                    value = math.floor(value * (parent.snapping - 1) + 0.5)
                    if parent.snapping == (parent.maxValue - parent.minValue) then
                        value = value + parent.minValue
                    else
                        value = value / (parent.snapping - 1) * (parent.maxValue - parent.minValue) + parent.minValue
                    end
                else
                    value = value * (parent.maxValue - parent.minValue) + parent.minValue
                end

                value = clamp(parent.minValue, value, parent.maxValue)

                local oldValue = parent.data[parent.key]
                parent.data[parent.key] = value
                if oldValue ~= value and parent.onChange then parent.onChange(value) end
            end

            local value = (parent.data[parent.key] - parent.minValue) / (parent.maxValue - parent.minValue)
            value = parent.invert and 1 - value or value
            head.position[axis] = value * (bodySize - headSize)
        end
    end, function (element)
        element.id = element.id or element.key
        element.key = element.key or "value"
        element.itemType = "slider"

        element.minValue = element.minValue or 0
        element.maxValue = element.maxValue or ((element.snapping or 2) - 1)

        element.color = element.color or { 43, 39, 81, 255 }
        element.headColor = element.headColor or { 255, 255, 255, 255 }
        element.headHoverColor = element.headHoverColor or { 255, 193, 247, 255 }

        if element.hoverable == nil then element.hoverable = true end
    end)
end

function Element.makeContext()
    return {
        ids = {},
        parent = nil,

        navigX = 0, navigY = 0,
        navigation = nil,
        selected = nil,

        navigIndex = nil
    }
end

function Element.new(ctx, config, inner, validate)
    local self = {
        ctx = ctx,
        parent = ctx.parent,
        inner = inner or function(_) end,
    }

    bindPrototype(self, Element)

    for key, value in pairs(config) do self[key] = value end
    if validate then validate(self) end
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

function Element.parseSize(unit)
    if type(unit) == "table" then
        if unit:is("Fixed") then
            return unit.amount
        elseif unit:is("Adapt") then
            return unit.amount * state.adaptUnits
        elseif unit:is("Width") then
            return unit.amount * state.width
        elseif unit:is("Height") then
            return unit.amount * state.height
        end
    elseif type(unit) == "function" then
        return unit()
    else
        return unit -- Not a parseable unit! Ignore...
    end
end

function Element.canParseSize(unit)
    return unit:isAny("Fixed", "Adapt", "Width", "Height") or (type(unit) == "number") or (type(unit) == "function")
end

function Element.calculateFitSizes(element)
    for _, child in ipairs(element.children) do
        Element.calculateFitSizes(child)
    end

    element.width = element.width + element.padding.left + element.padding.right
    element.height = element.height + element.padding.up + element.padding.down

    if Element.canParseSize(element.sizing.width) then
        element.width = element.width + Element.parseSize(element.sizing.width)
    end

    if Element.canParseSize(element.sizing.height) then
        element.height = element.height + Element.parseSize(element.sizing.height)
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
    if element.itemType == "generic" or element.itemType == "slider" then
        love.graphics.rectangle("fill", element.x, element.y, element.width, element.height)

        for _, child in ipairs(element.children) do
            Element.draw(child)
        end
    elseif element.itemType == "text" then
        love.graphics.print(element.text, element.font, element.x, element.y)
    end
    love.graphics.setColor(1, 1, 1)
end

function Element.saveElements(element)
    if element.id ~= nil then
        element.ctx.ids[element.id] = element
    end

    for _, child in ipairs(element.children) do
        Element.saveElements(child)
    end
end

-- function Element.preActions(element)
--     element.hovered = element:isHovered()
--     element.lastHovered = element.hovered and element:get("hovered")

--     for _, child in ipairs(element.children) do
--         Element.preActions(child)
--     end
-- end

function Element.actions(element)
    if element:isHovered() or element:isSelected() then
        element.color = element.hoverColor
        -- if element.hoverSound and not element.lastHovered then
        --     element.hoverSound:play()
        -- end
    end

    for _, child in ipairs(element.children) do
        Element.actions(child)
    end
end

function Element.prepareNavigationTree(element)
    element.ctx.navigation = {}
    element.ctx.navigIndex = 1
end

function Element.blur(element)
    element.ctx.selected = nil
end

-- Selection function for keyboard navigation.
function Element.navigate(element, x, y)
    local context = element.ctx
    if not context.selected then
        context.navigX = 1
        context.navigY = 1
        context.selected = context.navigation[context.navigY][context.navigX].id
    else
        x, y = x or 0, y or 0
        depthPrint(1, " pre:", context.navigX, context.navigY, context.navigation)
        context.navigY = ((context.navigY + y - 1) % #context.navigation) + 1
        context.navigX = context.navigX + x

        local row = context.navigation[context.navigY]
        if context.navigX > #row then
            context.navigX = context.navigX - #row
            return Element.navigate(element, 0, 1)
        elseif context.navigX < 1 then
            context.navigX = context.navigX + #row
            return Element.navigate(element, 0, -1)
        end

        depthPrint(1, "post:", context.navigX, context.navigY, context.navigation)
        context.selected = row[context.navigX].id
    end

    return context.selected
end

function Element.buildNavigationTree(element)
    local context = element.ctx
    if element.selectable then
        context.navigation[context.navigIndex] = context.navigation[context.navigIndex] or {}
        table.insert(context.navigation[context.navigIndex], element)
    end

    for _, child in ipairs(element.children) do
        if element.layoutDir == LayoutDir.TopToBottom and context.navigation[context.navigIndex] then
            context.navigIndex = context.navigIndex + 1
        end
        Element.buildNavigationTree(child)
    end
end

function Element.initialize(element)
    Element.calculateFitSizes(element)
    Element.calculateGrowSizes(element)
    Element.calculatePositions(element)

    Element.saveElements(element)
    Element.actions(element)

    Element.prepareNavigationTree(element)
    Element.buildNavigationTree(element)
end

return Element
