local Sprite = require "base.sprite"

local Gate = Sprite:extend()

function Gate:new(...)
    Gate.super.new(self, 434, 164)
    self:setImage("town_gate")

    self.z = -10000
end

return Gate
