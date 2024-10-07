local Sprite = require "base.sprite"

local Blood = Sprite:extend()

function Blood:new(...)
    Blood.super.new(self, ...)
    self:setImage("blood")
    self.anim:set(tostring(random(1, 5, true)))
    self:tween(1, { alpha = 0 })
        :oncomplete(function() self:destroy() end)
        :delay(random(8, 10))
    self.z = 100
end

return Blood
