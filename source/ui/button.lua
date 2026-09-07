-- if Button ~= nil then return Button end

-- local love = require "love"
-- require "source.ui.element"
-- Button = {}

-- local function validateButton(button)
--     button.onClick = button.onClick or function (self) end
--     button.onHover = button.onHover or function (self) end
-- end

-- function Button.new(ctx, config, inner)
--     local self = Element.new(ctx, config, inner)
--     validateButton(self)

--     self.action = function ()
--         if pointInRect(Mouse.x, Mouse.y, self.x, self.y, self.width, self.height) then
--             self:onHover()
--             if Mouse.justDown[1] then
--                 self:onClick()
--             end
--         end
--     end

--     return self
-- end

-- return Button
