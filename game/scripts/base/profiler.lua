local Class = require "base.class"
local Profiler = Class:extend()

function Profiler:new()
    self.profiler = require "libs.profile"
    self.profiler.start()
    -- self.profiler.hookall("Lua")
    self.frame = 0
    self.report = ""
    -- self.font = Asset.font("consolas", 14)
end

function Profiler:update()
    self.frame = self.frame + 1
    if self.frame % 100 == 0 then
        self.report = self.profiler.report(50)
        self.profiler.reset()
    end
end

function Profiler:draw()
    love.graphics.origin()
    love.graphics.setColor(0, 0, 0, .8)
    love.graphics.rectangle("fill", 0, 0, 810, 400)
    love.graphics.setColor(1, 1, 1)
    -- love.graphics.setFont(self.font)
    love.graphics.print(self.report or "Please wait...")
end

return Profiler
