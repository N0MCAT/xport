if Element ~= nil then return Element end

local love = require "love"
Element = {}

local function enum(name, a)
    a = a or {}

    local is = function(self, id)
        return self.type == id
    end

    local empty = true
    for _, _ in pairs(a) do
        empty = false
        break
    end

    if empty then
        local result = { type = name }
        result.is = is
        return result
    else
        return function(config)
            local result = { type = name }
            for key, value in pairs(a)      do result[key] = value end
            for key, value in pairs(config) do result[key] = value end
            result.is = is
            return result
        end
    end
end

Size = {
    Fit = enum("Fit"),
    Fixed = enum("Fixed", { amount = 0 }),
    Grow = enum("Grow"),
}

AlignX = {
    Left = enum("Left"),
    Center = enum("Center"),
    Right = enum("Right"),
}

AlignY = {
    Top = enum("Top"),
    Center = enum("Center"),
    Bottom = enum("Bottom"),
}

LayoutDir = {
    LeftToRight = enum("LeftToRight"),
    TopToBottom = enum("TopToBottom"),
}

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

    -- absolute values
    element.width = 0
    element.height = 0
    element.x = 0
    element.y = 0

    element.children = {}
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

function Element.initialize(element)
    Element.calculateFitSizes(element)
    Element.calculateGrowSizes(element)
    Element.calculatePositions(element)
end
