local Sprite = require "base.sprite"
local Scene = require "base.scene"

local King = Scene:extend()

function King:new(...)
    King.super.new(self, -200, 0, 2000, 2000)
    self.balustrade = self:add(Sprite(0, 0, "balustrade"))
    self.hands = self:add(Sprite(0, 0, "hands"))
    self.balustrade:centerX(WIDTH / 2 + 200)
    self.balustrade:bottom(HEIGHT)
    self.hands:centerX(WIDTH / 2 + 200)
    self.hands:bottom(HEIGHT)

    self.y = 37
    self:setStart()
end

function King:update(dt)
    King.super.update(self, dt)
    self:handleCamera()
end

function King:handleCamera()
    local x = Mouse.x - WIDTH / 2
    local y = Mouse.y - HEIGHT / 2
    self.x = self.start.x - x * .1
    self.y = self.start.y - y * .1
end

return King
