local Text = require "base.text"
local Scene = require "base.scene"

local Ending = Scene:extend()

function Ending:new(win)
    Ending.super.new(self)
    self:setBackgroundImage(win and "screen_victory" or "screen_defeat")
    self.timer = 0
    self:fadeIn(.5)
    local count = G.GameManager.speechCounter
    self.speechText = self:add(Text(313, 82, count .. " speech" .. (count == 1 and "" or "es"), "pixel_tome", 16))
    self.speechText.border:set(1, 1)
end

function Ending:update(dt)
    self.timer = self.timer + dt
    if self.timer > 2 then
        if Mouse:isPressed(1) or Input:isPressed("escape", "enter") then
            self:fadeOut(.5, function()
                self.scene:toMenu()
            end)
        end
    end

    Ending.super.update(self, dt)
end

return Ending
