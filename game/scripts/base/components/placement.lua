local Input = require "base.input"
local Class = require "base.class"

local Placement = Class:extend("Placement")

function Placement:new(...)
    Placement.super.new(self, ...)
end

function Placement:update(dt)
    local x, y = self.x, self.y

    if Input:isDown("lshift") then
        if Input:isPressed("left") then
            self.x = self.x - 1
        elseif Input:isPressed("right") then
            self.x = self.x + 1
        elseif Input:isPressed("down") then
            self.y = self.y + 1
        elseif Input:isPressed("up") then
            self.y = self.y - 1
        end
    else
        if Input:isDown("left") then
            self.x = self.x - 1
        elseif Input:isDown("right") then
            self.x = self.x + 1
        elseif Input:isDown("down") then
            self.y = self.y + 1
        elseif Input:isDown("up") then
            self.y = self.y - 1
        end
    end

    if self.x ~= x or self.y ~= y then
        print(self.x, self.y)
    end
end

return Placement
